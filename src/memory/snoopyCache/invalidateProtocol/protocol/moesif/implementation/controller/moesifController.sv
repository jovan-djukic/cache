module MOESIFController#(
	int CACHE_ID = 0
)(
	MemoryInterface.slave cpuSlaveInterface,
	MemoryInterface.master cpuMasterInterface,
	ReadMemoryInterface.slave snoopySlaveInterface,
	CacheInterface.controller cacheInterface,
	BusInterface.controller busInterface,
	ArbiterInterface.device cpuArbiterInterface,
	ArbiterInterface.device snoopyArbiterInterface,
	output logic accessEnable, invalidateEnable,
	input logic clock, reset
);

	import types::*;

	//CPU_CONTROLLER_BEGIN
	//cpu controller states
	typedef enum logic[2 : 0] {
		WAITING_FOR_REQUEST,
		WRITING_BACK,
		READING_BLOCK,
		WRITING_BUS_INVALIDATE,
		WRITE_DELAY,
		SERVE_REQUEST_FINISH
	} CpuControllerState;

	CpuControllerState cpuControllerState;
	logic[cacheInterface.OFFSET_WIDTH - 1 : 0] wordCounter;
	logic[cacheInterface.TAG_WIDTH - 1    : 0] masterTag;

	assign cpuArbiterInterface.request = busInterface.cpuCommandOut != NONE ? 1 : 0;

	//tag is different, if we need to write back (OWNED or MODIFIED) then it is tagOut otherwise it is tagIn
	assign masterTag = cacheInterface.cpuStateOut == OWNED || cacheInterface.cpuStateOut == MODIFIED ? cacheInterface.cpuTagOut : cacheInterface.cpuTagIn;

	assign cpuSlaveInterface.dataIn   = cacheInterface.cpuDataOut;
	assign cpuMasterInterface.address = {masterTag , cacheInterface.cpuIndex, wordCounter};
	assign cpuMasterInterface.dataOut = cacheInterface.cpuDataOut;

	assign cacheInterface.cpuTagIn  = cpuSlaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.cpuIndex  = cpuSlaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.cpuOffset = cacheInterface.cpuHit == 1 ? cpuSlaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0] : wordCounter;
	assign cacheInterface.cpuDataIn = cacheInterface.cpuHit == 1 ? cpuSlaveInterface.dataOut : cpuMasterInterface.dataIn;

	//read block task
	typedef enum logic[2 : 0] {
		READ_BUS_GRANT_WAIT,
		READ_WAITING_FOR_FUNCTION_COMPLETE,
		READ_WRITING_DATA_TO_CACHE,
		READ_WRITING_TAG_AND_STATE_TO_CACHE
	} ReadingBlockState;
	ReadingBlockState readingBlockState;
	 
	task readBlock();
		case (readingBlockState)
			READ_BUS_GRANT_WAIT: begin
				if (cpuArbiterInterface.grant == 1) begin
					cpuMasterInterface.readEnabled <= 1;
					readingBlockState              <= READ_WAITING_FOR_FUNCTION_COMPLETE;
				end
			end	
			
			READ_WAITING_FOR_FUNCTION_COMPLETE: begin
				if (cpuMasterInterface.functionComplete == 1) begin
					cacheInterface.cpuWriteData    <= 1;
					readingBlockState              <= READ_WRITING_DATA_TO_CACHE;
				end
			end

			READ_WRITING_DATA_TO_CACHE: begin
				cacheInterface.cpuWriteData    <= 0;
				cpuMasterInterface.readEnabled <= 0;
				wordCounter                    <= wordCounter + 1;

				if ((& wordCounter) == 1) begin
					if (busInterface.sharedIn == 1) begin
						cacheInterface.cpuStateIn <= FORWARD;
					end else begin
						cacheInterface.cpuStateIn <= EXCLUSIVE;
					end

					cacheInterface.cpuWriteTag   <= 1;
					cacheInterface.cpuWriteState <= 1;

					readingBlockState <= READ_WRITING_TAG_AND_STATE_TO_CACHE;
				end else begin
					readingBlockState <= READ_BUS_GRANT_WAIT;
				end
			end

			READ_WRITING_TAG_AND_STATE_TO_CACHE: begin
				cacheInterface.cpuWriteTag   <= 0;
				cacheInterface.cpuWriteState <= 0;

				readingBlockState  <= READ_BUS_GRANT_WAIT;
				cpuControllerState <= WAITING_FOR_REQUEST;
			end
		endcase	
	endtask : readBlock;

	//bus invalidate task
	logic[busInterface.NUMBER_OF_CACHES - 1 : 0] invalidated;
	typedef enum logic {
		WAITING_FOR_INVALIDATES,
		WRITING_MODIFIED_STATE
	} BusInvalidateState;
	BusInvalidateState busInvalidateState;

	task busInvalidate();
		case (busInvalidateState)
			WAITING_FOR_INVALIDATES: begin
				if (cpuArbiterInterface.grant == 1) begin
					if (busInterface.cpuCommandIn == BUS_INVALIDATE) begin
						invalidated[busInterface.cacheNumberIn] <= 1;
					end
				end

				if ((& invalidated) == 1) begin
					cacheInterface.cpuStateIn    <= MODIFIED;
					cacheInterface.cpuWriteState <= 1;
					busInvalidateState           <= WRITING_MODIFIED_STATE;
				end
			end

			WRITING_MODIFIED_STATE: begin
				invalidated                  <= 1 << CACHE_ID;
				cacheInterface.cpuWriteState <= 0;
				busInvalidateState           <= WAITING_FOR_INVALIDATES;
				cpuControllerState           <= WAITING_FOR_REQUEST;
			end
		endcase
	endtask : busInvalidate

	//write back task
	typedef enum logic[1 : 0] {
		WRITE_BACK_BUS_GRANT_WAIT,
		WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE,
		WRITE_BACK_WRITING_STATE_TO_CACHE
	} WriteBackState;
	WriteBackState writeBackState;

	task writeBack();
		case (writeBackState)
			WRITE_BACK_BUS_GRANT_WAIT: begin
				if (cpuArbiterInterface.grant == 1) begin
					cpuMasterInterface.writeEnabled <= 1;
					writeBackState                  <= WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE;
				end
			end	
			
			WRITE_BACK_WAITING_FOR_FUNCTION_COMPLETE: begin
				if (cpuMasterInterface.functionComplete == 1) begin
					cpuMasterInterface.writeEnabled <= 0;
					wordCounter                     <= wordCounter + 1;

					if ((& wordCounter) == 1) begin
						cacheInterface.cpuStateIn    <= INVALID;
						cacheInterface.cpuWriteState <= 1;

						writeBackState <= WRITE_BACK_WRITING_STATE_TO_CACHE;
					end else begin
						writeBackState <= WRITE_BACK_BUS_GRANT_WAIT;
					end
				end
			end

			WRITE_BACK_WRITING_STATE_TO_CACHE: begin
				cacheInterface.cpuWriteState <= 0;

				writeBackState     <= WRITE_BACK_BUS_GRANT_WAIT;
				cpuControllerState <= WAITING_FOR_REQUEST;
			end
		endcase	
	endtask : writeBack;

	//reset task
	task cpuControllerReset();
			cpuControllerState         <= WAITING_FOR_REQUEST;
			busInterface.cpuCommandOut <= NONE;
			readingBlockState          <= READ_BUS_GRANT_WAIT;
			wordCounter                <= 0;
			invalidated                <= 1 << CACHE_ID;
			busInvalidateState         <= WAITING_FOR_INVALIDATES;
			writeBackState             <= WRITE_BACK_BUS_GRANT_WAIT;
	endtask : cpuControllerReset

	//cpu controller 
	always_ff @(posedge clock, reset) begin
		if (reset == 1) begin
			cpuControllerReset();
		end else begin
			case (cpuControllerState)
				//waiting for read or write request
				WAITING_FOR_REQUEST: begin
					busInterface.cpuCommandOut <= NONE;
					//if request present
					if (cpuSlaveInterface.readEnabled == 1 || cpuSlaveInterface.writeEnabled == 1) begin
						//if hit serve request, else read block
						if (cacheInterface.cpuHit == 1) begin
							if (cpuSlaveInterface.writeEnabled == 1) begin
								if (cacheInterface.cpuStateOut != EXCLUSIVE && cacheInterface.cpuStateOut != MODIFIED) begin
									//invalidate on the bus
									cpuControllerState         <= WRITING_BUS_INVALIDATE;
									busInterface.cpuCommandOut <= BUS_INVALIDATE;
								end else begin
									//write MODIFIED even if it is MODIFIED already, no harm
									cacheInterface.cpuStateIn          <= MODIFIED;
									cacheInterface.cpuWriteState       <= 1;
									cacheInterface.cpuWriteData        <= 1;
									cpuControllerState                 <= WRITE_DELAY;
								end	
							end	else begin
								cpuSlaveInterface.functionComplete <= 1;
								cpuControllerState                 <= SERVE_REQUEST_FINISH;
								accessEnable                       <= 1;
							end
						end else begin
							if (cacheInterface.cpuStateOut == MODIFIED || cacheInterface.cpuStateOut == OWNED) begin
								cpuControllerState         <= WRITING_BACK;
								busInterface.cpuCommandOut <= BUS_WRITEBACK;
							end else begin
								cpuControllerState         <= READING_BLOCK;
								busInterface.cpuCommandOut <= BUS_READ;
							end
						end
					end	
				end
				
				WRITING_BACK: begin
					writeBack();
				end

				//reading block if not hit
				READING_BLOCK: begin
					readBlock();
				end	

				//invalidating block if state is not EXCLUSIVE or MODIFIED
				WRITING_BUS_INVALIDATE: begin
					busInvalidate();
				end

				WRITE_DELAY: begin
					cpuSlaveInterface.functionComplete <= 1;
					accessEnable                       <= 1;
					cacheInterface.cpuWriteState       <= 0;
					cacheInterface.cpuWriteData        <= 0;
					cpuControllerState 								 <= SERVE_REQUEST_FINISH;
				end

				SERVE_REQUEST_FINISH: begin
					//disable these always
					cpuSlaveInterface.functionComplete <= 0;
					accessEnable                       <= 0;
					cpuControllerState                 <= WAITING_FOR_REQUEST;
				end
			endcase
		end
	end
	//CPU_CONTROLLER_END

	//SNOPY_CONTROLLER_BEGIN
	assign busInterface.sharedOut          =  cacheInterface.snoopyStateOut != INVALID && busInterface.snoopyCommandIn != NONE ? 1 : 0;
	assign busInterface.forwardOut         =  cacheInterface.snoopyStateOut == FORWARD && busInterface.snoopyCommandIn != NONE ? 1 : 0;
	assign snoopyArbiterInterface.request  =  busInterface.sharedOut;
	assign snoopySlaveInterface.dataIn     =  cacheInterface.snoopyDataOut;
		
	assign cacheInterface.snoopyTagIn  = snoopySlaveInterface.address[(cacheInterface.OFFSET_WIDTH + cacheInterface.INDEX_WIDTH) +: cacheInterface.TAG_WIDTH];
	assign cacheInterface.snoopyIndex  = snoopySlaveInterface.address[cacheInterface.OFFSET_WIDTH +: cacheInterface.INDEX_WIDTH];
	assign cacheInterface.snoopyOffset = snoopySlaveInterface.address[cacheInterface.OFFSET_WIDTH - 1 : 0];
	//snoopy controler
	always_ff @(posedge clock, reset) begin
		case (busInterface.snoopyCommandIn) 
			BUS_READ: begin
				if (cacheInterface.snoopyHit == 1) begin
					cacheInterface.snoopyWriteState <= 0;
					if (cacheInterface.snoopyStateOut != SHARED) begin
						cacheInterface.snoopyStateIn    <= SHARED;
						cacheInterface.snoopyWriteState <= 1;
					end					

					if (snoopyArbiterInterface.grant == 1) begin
						if (snoopySlaveInterface.readEnabled == 1) begin
							snoopySlaveInterface.functionComplete <= 1;
						end else begin
							snoopySlaveInterface.functionComplete <= 0;
						end
					end
				end
			end
		endcase
	end
	//SNOPY_CONTROLLER_END
endmodule : MOESIFController
