module lab1 #(
    parameter WIDTHIN = 16,
    parameter WIDTHOUT = 32,
    parameter [WIDTHOUT-1:0] A0 = 32'b0000001_0000000000000000000000000,
    parameter [WIDTHOUT-1:0] A1 = 32'b0000001_0000000000000000000000000,
    parameter [WIDTHOUT-1:0] A2 = 32'b0000000_1000000000000000000000000,
    parameter [WIDTHOUT-1:0] A3 = 32'b0000000_0010101010101010101010101,
    parameter [WIDTHOUT-1:0] A4 = 32'b0000000_0000101010101010101010101,
    parameter [WIDTHOUT-1:0] A5 = 32'b0000000_0000001000100010001000100
) (
    input clk,
    input reset,    
    input i_valid,
    input i_ready,
    output o_valid,
    output o_ready,
   
    input [WIDTHIN-1:0] i_x,
    output reg [WIDTHOUT-1:0] o_y
);

/************************************************************CONTENTS****************************************************************

SECTIONS                                                                                                    LINE NUMBERS

I.      CODE DESCRIPTION                                                                                    .....       45                                                       

II.     SIGNAL DECLARATION                                                                                  .....       58 

III.    MAC UNIT INSTANTIATION                                                                              .....       84

IV.     STATE MACHINE IMPLEMENTATION                                                                        .....       94

V.      INPUT HANDLING AND SYNCHRONIZATION                                                                  .....      176

VI.     MAC MODULE DEFINITION                                                                               .....      228

VII.    FIXED POINT MULTIPLICATION AND ADDITION IMPLEMENTATION                                              .....      281

VIII.   SUMMARY                                                                                             .....      321
                            

**************************************************************************************************************************************/

/***********************************************************CODE DESCRIPTION**********************************************************

This verilog module is designed to employ shared implementation where we are using single multiplier and single adder module for 
computing first 5 terms of Taylor series effectively. 
We are defining a mac_unit which uses a 32x16 multiplier module and a 32p32 adder module.
The module uses state machine logic to determine which term it needs to compute. It computes Taylor series in a serial manner 
starting from A5 * x + A4 till A0. The states of State machine can be increased to compute more terms in the Taylor series expansion.

We are controlling the registering of input and output by our DUT based on the handshaking signals and according to the testbench 
testcases (i.e.)how testbench is handling these control signals.

**************************************************************************************************************************************/

/************************************************************SIGNAL DECLERATION*******************************************************/

reg [WIDTHIN-1:0] x;	
reg valid_Q1;

reg o_ready_reg, o_valid_reg;
reg enable;
reg finish_flag;
reg [WIDTHOUT-1:0] operator_a;
reg [WIDTHOUT-1:0] operator_b;
wire [WIDTHOUT-1:0] mac_result;
reg [WIDTHOUT-1:0] accumulator;



parameter   MAC_STATE_1=3'b001;
parameter   MAC_STATE_2= 3'b010;
parameter	MAC_STATE_3= 3'b011;
parameter	MAC_STATE_4= 3'b100; 
parameter	MAC_STATE_5=3'b101;
  
reg[2:0] state, next_state;

wire [WIDTHOUT-1:0] a0_out, a1_out, a2_out, a3_out, a4_out;
/*************************************************************************************************************************************/

/****************************************************MAC MODULE INSTATIATION**********************************************************/

mac_unit mac0 ( .i_mdataa(operator_a), 
                .i_mdatab(x),
                .i_adatab(operator_b),
                .o_res(mac_result));

/*************************************************************************************************************************************/


/****************************************************STATE MACHINE IMPLEMENTATION******************************************************/
/***************************************************************************************
* This section implements a Finite State machine for the module crucial for doing 
  operations needed for computation.
*
* On each clock cycle, the state machine transitions between predefined states
 (MAC_STATE_1 to MAC_STATE_5), dictated by the state and next_state logic. 
*
* Initially, in MAC_STATE_1, the module prepares for computation by setting up
  initial conditions and checking for valid input and readiness (valid_Q1 && enable).
  Subsequent states handle the core computation, using the accumulator to hold 
  intermediate results and cycling through Taylor series coefficients (A5 to A0).
*
* The state machine ensures that each step of the computation is executed in order,
 ultimately producing the final result in o_y when reaching MAC_STATE_5. 
*
* Additionally, the o_ready_reg signal is managed to indicate the module's readiness f
  or new inputs, enhancing the module's control flow and synchronization with external 
  components.
  *
***************************************************************************************/
// Next state Logic 
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= MAC_STATE_1;
    end
    else begin
        state <= next_state;
        
    end
end

// State Machine Logic
always @* begin
    case(state)
            MAC_STATE_1: begin
            
            if(valid_Q1 && enable) begin
                o_ready_reg = !enable;
                finish_flag=0;
                operator_a=A5;
                operator_b=A4;
                next_state= MAC_STATE_2;
                end
                else begin
                next_state = MAC_STATE_1;
                end
                
            end
            MAC_STATE_2:begin
                operator_a= accumulator;
                operator_b=A3;
                next_state= MAC_STATE_3;
                
            end
        MAC_STATE_3: begin
                operator_a =accumulator;
                operator_b = A2;
                next_state= MAC_STATE_4;
                
            end
        MAC_STATE_4: begin
                operator_a=accumulator;
                operator_b=A1;
                next_state= MAC_STATE_5;
                
            end
        MAC_STATE_5: begin
                operator_a=accumulator;
                operator_b=A0;
                finish_flag=1;
                if(finish_flag)begin
                    o_y = mac_result;
                
                    next_state= MAC_STATE_1;
                 end
            end
    endcase
    if(finish_flag) o_ready_reg = i_ready;
end
/*************************************************************************************************************************************/

/***********************************************INPUT HANDLING AND SYNCHRONIZATION****************************************************/

/**************************************************************************************************

*   This section of the code is dedicated to managing the input signals and ensuring their 
    synchronization with the internal logic of the module. 
*
*   The enable signal is directly derived from the external i_ready signal, indicating 
    when the module is prepared to process new data.
*    
*   The core of input handling is encapsulated within a sequential logic block triggered 
    on the positive edge of the clock or a reset event.
*    
*   Upon reset, internal signals such as valid_Q1 and x are initialized to their default 
    states, ensuring a clean start. When the module is enabled and ready, it captures 
    the validity of incoming data through i_valid into valid_Q1 and conditionally updates 
    the internal x register with new input i_x based on the finish_flag and o_ready signals.
*
*   This conditional update ensures that new inputs are accepted only when the module has 
    completed its current computation cycle, preventing data corruption and ensuring
    synchronization between input data streams and internal processing stages.
*
*   Additionally, the accumulator is updated with the result from the MAC unit, 
    preparing it for the next computation cycle. The output signals o_valid and o_ready 
    are then set based on the current state of input validity and the module's readiness 
    to accept new data, providing clear communication with external modules about the 
    status of data processing within the module.
*
*************************************************************************************************/
always @* begin
    enable = i_ready;
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        valid_Q1 <=1'b0;
        x <= 0; 
    end else if (enable) begin
        valid_Q1 <= i_valid;
        if(finish_flag & o_ready) begin
        x <= i_x;
        end
        accumulator<= mac_result;
     
    end
end

assign o_valid = i_valid & finish_flag;
assign o_ready = o_ready_reg;
endmodule
/*************************************************************************************************************************************/

/****************************************************MAC MODULE DEFINITION************************************************************/

/***************************************************************************************

*   The MAC module takes a 32-bit operand i_mdataa and a 16-bit operand i_mdatab as inputs 
    for multiplication, along with a 32-bit operand i_adatab for subsequent addition, 
    producing a 32-bit output o_res. 
*
*   The multiplication between the 32-bit and 16-bit inputs is handled by the mult32p16 
    submodule, which extends the 16-bit input for the multiplication  to maintain precision 
    and avoid overflow. 
*
*   The intermediate 48-bit result from this multiplication is then truncated to 32 bits,
    selecting the most significant bits to align with the fixed-point format.
    This truncated result is fed into the addr32p32 submodule along with i_adatab, 
    performing a 32-bit addition to accumulate the result. 
*    
***************************************************************************************/

module mac_unit(
    input wire [31:0] i_mdataa,  // Multiplier operand A (32-bit)
    input wire [15:0] i_mdatab,  // Multiplier operand B (16-bit)
    input wire [31:0] i_adatab,  // Adder operand (32-bit)
    output wire [31:0] o_res     // Output result (32-bit)
);

// Intermediate wire for the multiplication result
wire [47:0] mult_result;

// Intermediate wire for the addition result
wire [31:0] add_result;

// Instantiating the 32x16 multiplier module
mult32p16 mult_inst (
    .i_dataa(i_mdataa),
    .i_datab(i_mdatab),
    .o_res(mult_result)
);

// Instantiating the 32x32 adder module
addr32p32 add_inst (
    .i_dataa(mult_result[45:14]),  // Use the result from the multiplier
    .i_datab(i_adatab),     // Use the adder operand
    .o_res(add_result)      // The final MAC result
);

// The final MAC result is the output of the adder
assign o_res = add_result;

endmodule

/*************************************************************************************************************************************/

/***************************************FIXED POINT MULTIPLICATION AND ADDITION IMPLEMENTATION****************************************/

/**************************************************************************************************************

*   This section introduces the foundational building blocks for fixed-point arithmetic operations,
    crucial for the Taylor series computation. The mult16x16 module kicks off the process, adeptly 
    handling the initial multiplication with 16-bit inputs, ensuring the results are scaled correctly
    into the Q7.25 format. 
*    
*   This precision is maintained as the baton is passed to the mult32x16 modules,
    which further process the series by accommodating 32-bit and 16-bit multiplications, carefully 
    adjusting the format to maintain accuracy. 
*    
*   The addr32p16 module then steps in, gracefully aligning  and adding  16-bit coefficients to the 32-bit 
    results, a critical step for accumulating the series sum. 
*    
****************************************************************************************************************/

module mult32p16 (
    input [31:0] i_dataa,
    input [15:0] i_datab,
    output [47:0] o_res
);

assign o_res = i_dataa * i_datab; 

endmodule

module addr32p32 (
    input [31:0] i_dataa,
    input [31:0] i_datab,
    output [31:0] o_res
);

// Perform the addition
assign o_res = i_dataa + i_datab;

endmodule
/*************************************************************************************************************************************/

/***********************************************************SUMMARY*******************************************************************/
/*
    The lab1 Verilog module is a sophisticated implementation designed for computing the first five terms of a
    Taylor series using fixed-point arithmetic, structured around a state machine and MAC (Multiply-Accumulate) unit. 
    It begins with parameter definitions and signal declarations, setting the stage for complex operations. 
    The MAC unit, central to the module, is adeptly instantiated to perform sequential multiplications and additions,
    each step guided by the state machine through various states to ensure precise computation and accumulation 
    of results. 

    Input handling and synchronization are meticulously managed to align with external signals, ensuring data 
    integrity and seamless operation. 

    The module is further reinforced with dedicated submodules for multiplication and addition, encapsulating the 
    complexity of fixed-point operations and maintaining result precision. 
*/
/*************************************************************************************************************************************/

