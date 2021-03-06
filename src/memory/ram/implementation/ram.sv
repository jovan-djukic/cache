module RAM#(
	int DATA_WIDTH,
	int SIZE_IN_WORDS,
	int DELAY          = 4,
	int COUNTER_WIDTH  = $clog2(DELAY),
	string	INIT_FILE  = "",
	int IS_TEST        = 0
)(
	MemoryInterface.slave memoryInterface,
	input logic clock
);

	logic [DATA_WIDTH - 1	: 0] memory[SIZE_IN_WORDS];

	//delay
	logic [COUNTER_WIDTH - 1 : 0] 					   counter;
	
	initial begin
		if (INIT_FILE != "") begin
			$readmemh(INIT_FILE, memory);
		end else if (IS_TEST == 1) begin
			for (int i = 0; i < SIZE_IN_WORDS; i++) begin
				memory[i] = 0;
			end
		end
	end

	assign memoryInterface.functionComplete = counter == 0 ? 1 : 0;
	
	always_ff@(posedge clock) begin
		counter	<= DELAY - 1;
		if (memoryInterface.address < SIZE_IN_WORDS) begin
			if (memoryInterface.writeEnabled == 1) begin
				memory[memoryInterface.address] <= memoryInterface.dataOut;	
				if (counter != 0) begin
					counter <= counter - 1;
				end else begin
					counter <= 0;
				end
			end else if (memoryInterface.readEnabled  == 1) begin
				memoryInterface.dataIn <= memory[memoryInterface.address];		
				if (counter != 0) begin
					counter <= counter - 1;
				end else begin 
					counter <= 0;
				end 
			end
		end		
	end 

endmodule
