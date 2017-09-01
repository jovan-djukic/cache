VLOG				 = vlog
SRC					 = src
UVM_HOME		 = ./$(SRC)/uvm-1.1d
INCLUDES		 = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv
FLAGS				 = +define+UVM_NO_DPI
UVM_COMMAND  = $(VLOG) $(FLAGS) $(INCLUDES)

#command for verificaton
MODELSIM_VERIFICATION_COMMAND   = vsim -c bachelorThesis.TestBench -do "run -all"

#uvm test packages
UVM_BASE_TEST_PACKAGES_SOURCE_DIRECTORY = $(SRC)/uvmBaseTestPackages

#basic uvm test package
UVM_BASIC_TEST_PACKAGE_SOURCE_DIRECTORY = $(UVM_BASE_TEST_PACKAGES_SOURCE_DIRECTORY)/basicTestPackage
UVM_BASIC_TEST_PACKAGE = $(UVM_BASIC_TEST_PACKAGE_SOURCE_DIRECTORY)/basicTestPackage.sv

uvm_basic_test_package : $(UVM_BASIC_TEST_PACKAGE)
	$(UVM_COMMAND) $? 

#basic circuits
BASIC_CIRCUITS_SOURCE_DIRECTORY	= $(SRC)/basicCircuits
BASIC_CIRCUITS_IMPLEMENTATION		= $(BASIC_CIRCUITS_SOURCE_DIRECTORY)/*.sv

basic_circuits : $(BASIC_CIRCUITS_IMPLEMENTATION)
	$(VLOG) $(BASIC_CIRCUITS_IMPLEMENTATION)

#arbiter
ARBITER_SOURCE_DIRECTORY = $(SRC)/arbiter
ARBITER_INCLUDES         = $(ARBITER_SOURCE_DIRECTORY)/*.sv

#simple arbiter
SIMPLE_ARBITER_SOURCE_DIRECTORY = $(ARBITER_SOURCE_DIRECTORY)/simpleArbiter
SIMPLE_ARBITER_IMPLEMENTATION   = $(SIMPLE_ARBITER_SOURCE_DIRECTORY)/*.sv
SIMPLE_ARBITER_INCLUDES         = $(ARBITER_INCLUDES)

simple_arbiter_implementation : $(SIMPLE_ARBITER_INCLUDES) $(SIMPLE_ARBITER_IMPLEMENTATION)
	$(VLOG) $?

#memory
MEMORY_SOURCE_DIRECTORY = $(SRC)/memory
MEMORY_INCLUDES         = $(MEMORY_SOURCE_DIRECTORY)/*.sv

#ram
RAM_SOURCE_DIRECTORY = $(MEMORY_SOURCE_DIRECTORY)/ram
RAM_IMPLEMENTATION   = $(RAM_SOURCE_DIRECTORY)/implementation/*.sv
RAM_VERIFICATION     = $(RAM_SOURCE_DIRECTORY)/verification/testInterface.sv \
											 $(RAM_SOURCE_DIRECTORY)/verification/testPackage.sv \
											 $(RAM_SOURCE_DIRECTORY)/verification/testBench.sv

ram_implementation : $(MEMORY_INCLUDES) $(RAM_IMPLEMENTATION)
	$(VLOG) $?
	
ram_verification : $(MEMORY_INCLUDES) $(RAM_IMPLEMENTATION) $(UVM_BASIC_TEST_PACKAGE) $(RAM_VERIFICATION)
	$(UVM_COMMAND) $? && $(MODELSIM_VERIFICATION_COMMAND)

#width adapter
WIDTH_ADAPTER_SOURCE_DIRECTORY = $(MEMORY_SOURCE_DIRECTORY)/widthAdapter
WIDTH_ADAPTER_IMPLEMENTATION   = $(WIDTH_ADAPTER_SOURCE_DIRECTORY)/*.sv

width_adapter_implementation : $(MEMORY_INCLUDES) $(WIDTH_ADAPTER_IMPLEMENTATION)
	$(VLOG) $?

#snoopy cache
SNOOPY_SOURCE_DIRECTORY = $(MEMORY_SOURCE_DIRECTORY)/snoopyCache

#snoopy cache invalidate protocol 
SNOOPY_INVALIDATE_SOURCE_DIRECTORY = $(SNOOPY_SOURCE_DIRECTORY)/invalidateProtocol

#invalidate protocol operating unit
SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/cacheUnit
SNOOPY_INVALIDATE_CACHE_UNIT_INCLUDES         = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/*.sv

#Replacement algorithm implementation
INVALIDATE_REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/replacementAlgorithm
INVALIDATE_REPLACEMENT_ALGORITHM_INCLUDES         = $(INVALIDATE_REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/*.sv

#lru
INVALIDATE_LRU_SOURCE_DIRECTORY     = $(INVALIDATE_REPLACEMENT_ALGORITHM_SOURCE_DIRECTORY)/lru
INVALIDATE_LRU_INCLUDES							= $(INVALIDATE_REPLACEMENT_ALGORITHM_INCLUDES)
INVALIDATE_LRU_IMPLEMENTATION       = $(INVALIDATE_LRU_SOURCE_DIRECTORY)/implementation/*.sv
INVALIDATE_LRU_CLASS_IMPLEMENTATION = $(INVALIDATE_LRU_SOURCE_DIRECTORY)/classImplementation/*.sv
INVALIDATE_LRU_VERIFICATION         = $(INVALIDATE_LRU_SOURCE_DIRECTORY)/verification/testInterface.sv \
																			$(INVALIDATE_LRU_SOURCE_DIRECTORY)/verification/testPackage.sv \
																			$(INVALIDATE_LRU_SOURCE_DIRECTORY)/verification/testBench.sv 

invalidate_lru_implementation	: $(INVALIDATE_LRU_INCLUDES) $(INVALIDATE_LRU_IMPLEMENTATION)
	$(VLOG) $?

invalidate_lru_verification		: $(INVALIDATE_LRU_INCLUDES) \
																$(INVALIDATE_LRU_IMPLEMENTATION) \
																$(UVM_BASIC_TEST_PACKAGE) \
																$(INVALIDATE_LRU_CLASS_IMPLEMENTATION) \
																$(INVALIDATE_LRU_VERIFICATION)
	$(UVM_COMMAND) $? && $(MODELSIM_VERIFICATION_COMMAND)

#snoopy direct mapping cache unit
SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/directMappingCacheUnit
SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_INCLUDES			   = $(SNOOPY_INVALIDATE_CACHE_UNIT_INCLUDES)
SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_IMPLEMENTATION   = $(SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_direct_mapping_cache_unit_implementation : $(SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_INCLUDES) \
																														 $(SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_IMPLEMENTATION)
	$(VLOG) $?

#snoopy set associative cache
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY 		 = $(SNOOPY_INVALIDATE_CACHE_UNIT_SOURCE_DIRECTORY)/setAssociativeCacheUnit
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_INCLUDES						 = $(SNOOPY_INVALIDATE_CACHE_UNIT_INCLUDES) \
																															 $(SNOOPY_INVALIDATE_DIRECT_MAPPING_CACHE_UNIT_IMPLEMENTATION) \
																															 $(INVALIDATE_REPLACEMENT_ALGORITHM_INCLUDES) \
																						 								   $(INVALIDATE_LRU_IMPLEMENTATION) 
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_IMPLEMENTATION 			 = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/implementation/*.sv
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_CLASS_INCLUDES			 = $(INVALIDATE_LRU_CLASS_IMPLEMENTATION)
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_CLASS_IMPLEMENTATION = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/classImplementation/*.sv
SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_VERIFICATION 				 = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/verification/testInterface.sv \
																															 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/verification/testPackage.sv \
																															 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_SOURCE_DIRECTORY)/verification/testBench.sv

snoopy_invalidate_set_associative_cache_implementation : $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_INCLUDES) \
																												 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_IMPLEMENTATION)
	$(VLOG) $?

snoopy_invalidate_set_associative_cache_verification : $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_INCLUDES) \
																											 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_IMPLEMENTATION) \
																											 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_CLASS_INCLUDES) \
																											 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_CLASS_IMPLEMENTATION) \
																											 $(UVM_BASIC_TEST_PACKAGE) \
																											 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_VERIFICATION)
	$(UVM_COMMAND) $? && $(MODELSIM_VERIFICATION_COMMAND)

#snoopy invalidate bus
SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/bus
SNOOPY_INVALIDATE_BUS_INCLUDES				 = $(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/busCommands.sv \
																				 $(SNOOPY_INVALIDATE_BUS_SOURCE_DIRECTORY)/busInterface.sv

#snoppy invalidate protocol
SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/protocol
SNOOPY_INVALIDATE_PROTOCOL_INCLUDES					= $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/*.sv

#snoopy invalidate cache controller
SNOOPY_INVALIDATE_CACHE_CONTROLLER_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_SOURCE_DIRECTORY)/cacheController
SNOOPY_INVALIDATE_CACHE_CONTROLLER_INCLUDES					= $(MEMORY_INCLUDES) \
																											$(SNOOPY_INVALIDATE_CACHE_UNIT_INCLUDES) \
																											$(SNOOPY_INVALIDATE_BUS_INCLUDES) \
																											$(SNOOPY_INVALIDATE_PROTOCOL_INCLUDES) \
																											$(ARBITER_INCLUDES) 
SNOOPY_INVALIDATE_CACHE_CONTROLLER_IMPLEMENTATION   = $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_SOURCE_DIRECTORY)/implementation/*.sv

snoopy_invalidate_cache_controller_implementation : $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_INCLUDES) $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_IMPLEMENTATION)
	$(VLOG) $?

#there are multiple tests for the controller
#controller verification
SNOOPY_INVALIDATE_CACHE_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_SOURCE_DIRECTORY)/verification
SNOOPY_INVALIDATE_CACHE_CONTROLLER_VERIFICATION_INCLUDES				 = $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_INCLUDES) \
																																	 $(SNOOPY_INVALIDATE_SET_ASSOCIATIVE_CACHE_IMPLEMENTATION) \
																																	 $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_INCLUDES) \
																																	 $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_IMPLEMENTATION) \
																																	 $(UVM_BASIC_TEST_PACKAGE) 

#read test
SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY)/readTest
SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_INCLUDES					= $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_VERIFICATION_INCLUDES)
SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_IMPLEMENTATION   = $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_SOURCE_DIRECTORY)/testInterface.sv \
																																$(SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_SOURCE_DIRECTORY)/testPackage.sv \
																																$(SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_SOURCE_DIRECTORY)/testBench.sv
	
snoopy_invalidate_cache_controller_read_test : $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_INCLUDES) \
																							 $(SNOOPY_INVALIDATE_CACHE_CONTROLLER_READ_TEST_IMPLEMENTATION)
	$(UVM_COMMAND) $? && $(MODELSIM_VERIFICATION_COMMAND)
#==========================================================================================================================================================
#moesif
SNOOPY_INVALIDATE_MOESIF_SOURCE_DIRECTORY         = $(SNOOPY_INVALIDATE_PROTOCOL_SOURCE_DIRECTORY)/moesif
SNOOPY_INVALIDATE_MOESIF_IMPLEMENTATION_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_SOURCE_DIRECTORY)/implementation
SNOOPY_INVALIDATE_MOESIF_INCLUDES		              = $(SNOOPY_INVALIDATE_MOESIF_IMPLEMENTATION_DIRECTORY)/*.sv

#moesif bus
SNOOPY_INVALIDATE_MOESIF_BUS_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_IMPLEMENTATION_DIRECTORY)/bus
SNOOPY_INVALIDATE_MOESIF_BUS_INCLUDES         = $(SNOOPY_INVALIDATE_MOESIF_BUS_SOURCE_DIRECTORY)/*.sv

#moesif simple bus
SNOOPY_INVALIDATE_MOESIF_SIMPLE_BUS_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_BUS_SOURCE_DIRECTORY)/simpleBus
SNOOPY_INVALIDATE_MOESIF_SIMPLE_BUS_INCLUDES         = $(SNOOPY_INVALIDATE_MOESIF_BUS_INCLUDES)
SNOOPY_INVALIDATE_MOESIF_SIMPLE_BUS_IMPLEMENTATION   = $(SNOOPY_INVALIDATE_MOESIF_SIMPLE_BUS_SOURCE_DIRECTORY)/*.sv

snoopy_invalidate_moesif_simple_bus_implementation : $(SNOOPY_INVALIDATE_MOESIF_INCLUDES) \
																										 $(SNOOPY_INVALIDATE_MOESIF_SIMPLE_BUS_INCLUDES) \
																										 $(SNOOPY_INVALIDATE_MOESIF_SIMPLE_BUS_IMPLEMENTATION)
	$(VLOG) $?

#moesif cache controller
#implementation
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_IMPLEMENTATION_DIRECTORY)/controller
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_INCLUDES				 = $(MEMORY_INCLUDES) \
																											 $(ARBITER_INCLUDES) \
																											 $(SNOOPY_INVALIDATE_CACHE_UNIT_INCLUDES) \
																											 $(SNOOPY_INVALIDATE_MOESIF_INCLUDES) \
																											 $(SNOOPY_INVALIDATE_MOESIF_BUS_INCLUDES)
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_IMPLEMENTATION   = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SOURCE_DIRECTORY)/*.sv	

snoopy_invalidate_moesif_controller_implementation : $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_INCLUDES) $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_IMPLEMENTATION)
	$(VLOG) $?

#verification
#these are base .sv files we need for each test
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_SOURCE_DIRECTORY)/verification
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_INCLUDES				  = $(MEMORY_INCLUDES) \
																																 	 	$(ARBITER_INCLUDES) \
																																 	 	$(SNOOPY_INVALIDATE_CACHE_UNIT_INCLUDES) \
																																 	 	$(SNOOPY_INVALIDATE_MOESIF_INCLUDES) \
																																		$(SNOOPY_INVALIDATE_MOESIF_BUS_INCLUDES) 
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_BASE 						= $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY)/*.sv

#there are multiple test for controller, so we have multiple targets, one for each test

#simple read test
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY)/simpleReadTest
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_INCLUDES				  = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_INCLUDES) \
																																				$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_IMPLEMENTATION) \
																																				$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_BASE)
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_PACKAGE = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_SOURCE_DIRECTORY)/simpleReadTestPackage.sv
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_BENCH = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_SOURCE_DIRECTORY)/testBench.sv

snoopy_invalidate_moesif_controller_simple_read_test : $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_INCLUDES) \
																											 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_PACKAGE) \
																											 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_BENCH) 
	$(UVM_COMMAND) $?  && $(MODELSIM_VERIFICATION_COMMAND)

#simple supply test
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY)/simpleCacheSupplyTest
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_INCLUDES				  = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_INCLUDES) \
																																					$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_IMPLEMENTATION) \
																																					$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_BASE) \
																																					$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_READ_TEST_PACKAGE) 
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_PACKAGE = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_SOURCE_DIRECTORY)/simpleCacheSupplyTestPackage.sv
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_BENCH = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_SOURCE_DIRECTORY)/testBench.sv

snoopy_invalidate_moesif_controller_simple_supply_test : $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_INCLUDES) \
																											 	 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_PACKAGE) \
																											 	 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_SUPPLY_TEST_BENCH) 
	$(UVM_COMMAND) $?  && $(MODELSIM_VERIFICATION_COMMAND)

#simple write test
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY)/simpleWriteTest
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_INCLUDES         = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_INCLUDES) \
																																				 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_IMPLEMENTATION) \
																																				 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_BASE)
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_PACKAGE = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_SOURCE_DIRECTORY)/simpleWriteTestPackage.sv
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_BENCH   = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_SOURCE_DIRECTORY)/testBench.sv

snoopy_invalidate_moesif_controller_simple_write_test : $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_INCLUDES) \
																											 	$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_PACKAGE) \
																											 	$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_TEST_BENCH) 
	$(UVM_COMMAND) $?  && $(MODELSIM_VERIFICATION_COMMAND)

#simple write back test
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_SOURCE_DIRECTORY = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_SOURCE_DIRECTORY)/simpleWriteBackTest
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_INCLUDES         = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_INCLUDES) \
																																				 			$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_IMPLEMENTATION) \
																																				 			$(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_VERIFICATION_BASE)
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_PACKAGE = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_SOURCE_DIRECTORY)/simpleWriteBackTestPackage.sv
SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_BENCH   = $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_SOURCE_DIRECTORY)/testBench.sv

snoopy_invalidate_moesif_controller_simple_write_back_test : $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_INCLUDES) \
																											 			 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_PACKAGE) \
																											 			 $(SNOOPY_INVALIDATE_MOESIF_CONTROLLER_SIMPLE_WRITE_BACK_TEST_BENCH) 
	$(UVM_COMMAND) $?  && $(MODELSIM_VERIFICATION_COMMAND)
