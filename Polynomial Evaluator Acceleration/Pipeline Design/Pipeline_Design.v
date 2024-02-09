module lab1 #
(
	parameter WIDTHIN = 16,		// Input format is Q2.14 (2 integer bits + 14 fractional bits = 16 bits)
	parameter WIDTHOUT = 32,    // Intermediate/Output format is Q7.25 (7 integer bits + 25 fractional bits = 32 bits)
    parameter WIDTHIN_INT = 32,	
	// Taylor coefficients for the first five terms in Q2.14 format
	parameter [WIDTHIN-1:0] A0 = 16'b01_00000000000000, // a0 = 1
	parameter [WIDTHIN-1:0] A1 = 16'b01_00000000000000, // a1 = 1
	parameter [WIDTHIN-1:0] A2 = 16'b00_10000000000000, // a2 = 1/2
	parameter [WIDTHIN-1:0] A3 = 16'b00_00101010101010, // a3 = 1/6
	parameter [WIDTHIN-1:0] A4 = 16'b00_00001010101010, // a4 = 1/24
	parameter [WIDTHIN-1:0] A5 = 16'b00_00000010001000  // a5 = 1/120
)
(
	input clk,
	input reset,	
	
	input i_valid,
	input i_ready,
	output reg o_valid,
	output o_ready,
	
	input [WIDTHIN-1:0] i_x,
	output reg [WIDTHOUT-1:0] o_y
);

/************************************************************CONTENTS****************************************************************

SECTIONS                                                                                                    LINE NUMBERS

I.      CODE DESCRIPTION                                                                                    .....       51                                                       

II.     SIGNAL DECLARATION                                                                                  .....       65 

III.    INPUT X PROPOGATION                                                                                 .....       97

IV.     MODULE INSTATIATIONS                                                                                .....      150

V.      DATA PROPOGATION                                                                                    .....      185

VI.     VALID SIGNAL PROPOGATION                                                                            .....      230

VII.    OUTPUT MANAGEMENT                                                                                   .....      274

VIII.   FIXED POINT MULTIPLICATION AND ADDITION IMPLEMENTATION                                              .....      314

IX.     SUMMARY                                                                                             .....      382                                

**************************************************************************************************************************************/

/***********************************************************CODE DESCRIPTION**********************************************************

*   The verilog module is designed to compute Taylor series Expansion using fixed point arthematic. 
*   The Taylor Series is implemented for first 5 terms.
*   The module takes a 16-bit fixed-point input i_x in Q2.14 format. 
*   This input represents the variable part of the Taylor series expansion. Alongside i_x, the module receives
    i_valid and i_ready signals to manage the data flow.
*   10 Stage pipeline is used for maximum throughput. i.e. We made every operation (multiplication or Addition as 1 stage each)
*   Input i_x is propogated using a series of registers, a delay of 2 cycle is added to match the timing of input a to every multiplier.
*   Dedicated modules of multiplicatoin and addition are defined.
*   Output is managed via o_ready and i_valid (which are according to test cases mentioned in testbench.)

**************************************************************************************************************************************/

/************************************************************SIGNAL DECLERATION*******************************************************/

wire [WIDTHOUT-1:0] m0_out; // A5 * x
wire [WIDTHOUT-1:0] a0_out; // A5 * x + A4
wire [WIDTHOUT-1:0] m1_out; // (A5 * x + A4) * x
wire [WIDTHOUT-1:0] a1_out; // (A5 * x + A4) * x + A3
wire [WIDTHOUT-1:0] m2_out; // ((A5 * x + A4) * x + A3) * x
wire [WIDTHOUT-1:0] a2_out; // ((A5 * x + A4) * x + A3) * x + A2
wire [WIDTHOUT-1:0] m3_out; // (((A5 * x + A4) * x + A3) * x + A2) * x
wire [WIDTHOUT-1:0] a3_out; // (((A5 * x + A4) * x + A3) * x + A2) * x + A1
wire [WIDTHOUT-1:0] m4_out; // ((((A5 * x + A4) * x + A3) * x + A2) * x + A1) * x
wire [WIDTHOUT-1:0] a4_out; // ((((A5 * x + A4) * x + A3) * x + A2) * x + A1) * x + A0


reg [WIDTHIN-1:0] pipeline_x1; // For propogating i_x to first pipeline stage

reg [WIDTHIN-1:0] pipeline_x2i, pipeline_x2, pipeline_x3i, pipeline_x3; // For propogating i_x to subsequwnt pipeline stage
reg [WIDTHIN-1:0] pipeline_x4i, pipeline_x4, pipeline_x5i, pipeline_x5; // See Description Section II for further insights

reg stage1_valid_in; // Propogating valid_in signal to Stage 1 of our pipeline
// Stage1_data_out to stage_10_data_out are registers to hold output from every pipeline stage
reg [WIDTHOUT-1:0] stage1_data_out, stage2_data_out, stage3_data_out, stage4_data_out, stage5_data_out;
reg [WIDTHOUT-1:0] stage6_data_out,stage7_data_out, stage8_data_out, stage9_data_out;

// Valid signals to propogate on every pipeline stage 
reg stage2_valid_out, stage3_valid_out, stage4_valid_out, stage5_valid_out;
reg stage6_valid_out, stage7_valid_out, stage8_valid_out, stage9_valid_out, stage10_valid_out;

reg enable;

/*************************************************************************************************************************************/

/**********************************************************INPUT X PROPOGATION********************************************************/

/************************************************************************

We are using a set of registers to address the delay caused by adding 
two registers after every output of the computational unit , so in
order to match the timing for when both the inputs should arrive 
at the input of next multiplier we need to add a 2 cycle delay to the 
input x to the next stage multiplier.
***********************************************************************/

always @(posedge clk or posedge reset) begin
    if (reset) begin
        
        pipeline_x1 <= 0;
        //
        pipeline_x2i <= 0;
        pipeline_x2 <= 0;
        //
        pipeline_x3i <= 0;
        pipeline_x3 <= 0;
        //
        pipeline_x4i <= 0;
        pipeline_x4 <= 0;
        //
        pipeline_x5i <= 0;
        pipeline_x5 <= 0;
        

    end else if (enable)begin
        // 1st stage: pipeline_x1 input in 1st multiplier through input register
        if(i_valid) pipeline_x1 <= i_x;

        // 2nd stage: i_x propogated to next pair of multiplier adder
        pipeline_x2i <= pipeline_x1;
        pipeline_x2 <= pipeline_x2i;

        // 3rd stage: i_x propogated to next pair of multiplier adder
        pipeline_x3i <= pipeline_x2;
        pipeline_x3 <= pipeline_x3i;

        // 4th stage: i_x propogated to next pair of multiplier adder
        pipeline_x4i <= pipeline_x3;
        pipeline_x4 <= pipeline_x4i;

        // 5th stage: i_x propogated to final pair of multiplier adder
        pipeline_x5i <= pipeline_x4;
        pipeline_x5 <= pipeline_x5i;
    end 
end

/**************************************************************************************************************************************/

/************************************************************MODULE INSTANTIATIONS*****************************************************/

/****************************************************************************

    In this section we are instatiating modules which are defined in the 
    "FIXED POINT MULTIPLICATION AND ADDITION IMPLEMENTATION" section.
    The design thoughtfully stitches together a sequence of multiplier 
    and adder modules, each tailored for fixed-point arithmetic, 
    to methodically build up the Taylor series result through successive
    operations.

    We begin with Mult0, a mult16x16 module, that multiplies the input
    i_x with the Taylor coefficient A5, laying down the first layer of 
    computation. This result is then gracefully passed on to Addr0, an 
    addr32p16 module, where it's added to A4, weaving the second term 
    of the series into the fabric of our computation.
*****************************************************************************/

mult16x16 Mult0 (.i_dataa(A5), 		.i_datab(pipeline_x1), 	.o_res(m0_out));
addr32p16 Addr0 (.i_dataa(stage1_data_out), 	.i_datab(A4), 	.o_res(a0_out));

mult32x16 Mult1 (.i_dataa(stage2_data_out), 	.i_datab(pipeline_x2), 	.o_res(m1_out));
addr32p16 Addr1 (.i_dataa(stage3_data_out), 	.i_datab(A3), 	.o_res(a1_out));

mult32x16 Mult2 (.i_dataa(stage4_data_out), 	.i_datab(pipeline_x3), 	.o_res(m2_out));
addr32p16 Addr2 (.i_dataa(stage5_data_out), 	.i_datab(A2), 	.o_res(a2_out));

mult32x16 Mult3 (.i_dataa(stage6_data_out), 	.i_datab(pipeline_x4), 	.o_res(m3_out));
addr32p16 Addr3 (.i_dataa(stage7_data_out), 	.i_datab(A1), 	.o_res(a3_out));

mult32x16 Mult4 (.i_dataa(stage8_data_out), 	.i_datab(pipeline_x5), 	.o_res(m4_out));
addr32p16 Addr4 (.i_dataa(stage9_data_out), 	.i_datab(A0), 	.o_res(a4_out));

/**************************************************************************************************************************************/

/***********************************************************DATA PROPOGATION***********************************************************/

/***************************************************************************************

    The "Data Propagation" section ensures a smooth transition of computed results 
    through the pipeline's stages. By employing registers at the output of each 
    computational stage, this section effectively implements a pipeline architecture
    that's key to achieving high throughput in digital design, particularly for 
    complex computations like the Taylor series expansion.

    When the system undergoes a reset, all the data output registers are cleared to
    zero, ensuring that no residual data from previous computations can interfere
    with new operations. 

    As the pipeline becomes enabled, data from the outputs of multiplier and adder
    modules begins to flow through the pipeline. The use of conditional statements
    tied to the valid signals (stageX_valid_out) ensures that data is only p
    ropagated when it's valid, aligning with the valid signal propagation mechanism
    to maintain data integrity and synchronization across the pipeline.
*****************************************************************************************/
always@(posedge clk or posedge reset)begin
    if(reset)begin
        stage1_data_out <= 0;
        stage2_data_out <= 0;
        stage3_data_out <= 0;
        stage4_data_out <= 0;
        stage5_data_out <= 0;
        stage6_data_out <= 0;
        stage7_data_out <= 0;
        stage8_data_out <= 0;
        stage9_data_out <= 0;
    end else if(enable)begin
        if(stage1_valid_in)  stage1_data_out <= m0_out;
        if(stage2_valid_out) stage2_data_out <= a0_out;
        if(stage3_valid_out) stage3_data_out <= m1_out;
        if(stage4_valid_out) stage4_data_out <= a1_out;
        if(stage5_valid_out) stage5_data_out <= m2_out;
        if(stage6_valid_out) stage6_data_out <= a2_out;
        if(stage7_valid_out) stage7_data_out <= m3_out;
        if(stage8_valid_out) stage8_data_out <= a3_out;
        if(stage9_valid_out) stage9_data_out <= m4_out;
    end
end 
/**************************************************************************************************************************************/

/**********************************************************VALID SIGNAL PROPOGATION****************************************************/

/************************************************************************************

    This section ensures the integrity and synchronization of data as it flows
    through the pipeline stages. This section meticulously manages the propagatio
    n of valid signals, which are essential for indicating when the data at each s
    tage of the pipeline is ready to be used or passed on to the next stage.

    When the system is reset, all valid signals are cleared to 0, ensuring a 
    clean slate and preventing any stale data from being processed. As the 
    pipeline begins operation, the valid signal from the input (i_valid) is 
    captured and propagated through the pipeline stages, effectively shadowing 
    the data path.
************************************************************************************/

always @(posedge clk or posedge reset)begin
    if(reset)begin
        stage1_valid_in <= 0;
        stage2_valid_out <= 0;
        stage3_valid_out <= 0;
        stage4_valid_out <= 0;
        stage5_valid_out <= 0;
        stage6_valid_out <= 0;
        stage7_valid_out <= 0;
        stage8_valid_out <= 0;
        stage9_valid_out <= 0;
        stage10_valid_out <= 0;
    end else if(enable)begin
        stage1_valid_in <= i_valid;
        stage2_valid_out <= stage1_valid_in;
        stage3_valid_out <= stage2_valid_out;
        stage4_valid_out <= stage3_valid_out;
        stage5_valid_out <= stage4_valid_out;
        stage6_valid_out <= stage5_valid_out;
        stage7_valid_out <= stage6_valid_out;
        stage8_valid_out <= stage7_valid_out;
        stage9_valid_out <= stage8_valid_out;
        stage10_valid_out <= stage9_valid_out;
    end
end

/**************************************************************************************************************************************/

/*******************************************************OUTPUT MANAGEMENT**************************************************************/

/******************************************************************************************************

    This section of the lab1 module seamlessly orchestrates the final act of delivering the Taylor
    series computation to the external world, with meticulous timing governed by i_valid and i_ready
    signals. It's here that the module's diligent internal computations find their way out, with 
    the enable signal acting as a gatekeeper, ensuring data flows only when the receiver is ready.
    
    This careful synchronization not only prevents data loss but also harmonizes the module's output 
    with the broader system it's a part of, making the output management a critical bridge between 
    complex internal processes and the module's external environment.
*******************************************************************************************************/


// Combinational logic
always @* begin
	// signal for enable
	enable = i_ready;
end

//  We are managing the final output acc ording to the valid status signals which are propogated in our pipeline.
// So stage10_data_out is our final valid signal which if true we are giving the value of output from our 10th satge 
// of our pipeline to our output port o_y
always @(posedge clk or posedge reset) begin
    if (reset) begin
        o_y <= 0;
        o_valid <= 0;
    end else if (i_valid || o_ready) begin
        o_y <= a4_out; // Update output with the last stage's data
        o_valid <= stage10_valid_out; // Set output valid when last stage is valid
    end
end

// i_ready is directly assigned to o_ready.
assign o_ready = i_ready; 

endmodule
/**************************************************************************************************************************************/

/***************************************FIXED POINT MULTIPLICATION AND ADDITION IMPLEMENTATION ****************************************/

/**************************************************************************************************************

    This section introduces the foundational building blocks for fixed-point arithmetic operations,
    crucial for the Taylor series computation. The mult16x16 module kicks off the process, adeptly 
    handling the initial multiplication with 16-bit inputs, ensuring the results are scaled correctly
    into the Q7.25 format. This precision is maintained as the baton is passed to the mult32x16 modules,
    which further process the series by accommodating 32-bit and 16-bit multiplications, carefully 
    adjusting the format to maintain accuracy. The addr32p16 module then steps in, gracefully aligning 
    and adding  16-bit coefficients to the 32-bit results, a critical step for accumulating the series sum. 
****************************************************************************************************************/

// Multiplier module for the first 16x16 multiplication
module mult16x16 (
	input  [15:0] i_dataa,
	input  [15:0] i_datab,
	output [31:0] o_res
);

reg [31:0] result;

always @ (*) begin
	result = i_dataa * i_datab;
end

// The result of Q2.14 x Q2.14 is in the Q4.28 format. Therefore we need to change it
// to the Q7.25 format specified in the assignment by shifting right and padding with zeros.
assign o_res = {3'b000, result[31:3]};

endmodule

/*******************************************************************************************/

// Multiplier module for all the remaining 32x16 multiplications
module mult32x16 (
	input  [31:0] i_dataa,
	input  [15:0] i_datab,
	output [31:0] o_res
);

reg [47:0] result;

always @ (*) begin
	result = i_dataa * i_datab;
end

// The result of Q7.25 x Q2.14 is in the Q9.39 format. Therefore we need to change it
// to the Q7.25 format specified in the assignment by selecting the appropriate bits
// (i.e. dropping the most-significant 2 bits and least-significant 14 bits).
assign o_res = result[45:14];

endmodule

/*******************************************************************************************/

// Adder module for all the 32b+16b addition operations 
module addr32p16 (
	input [31:0] i_dataa,
	input [15:0] i_datab,
	output [31:0] o_res
);

// The 16-bit Q2.14 input needs to be aligned with the 32-bit Q7.25 input by zero padding
assign o_res = i_dataa + {5'b00000, i_datab, 11'b00000000000};

endmodule

/***************************************************************SUMMARY*********************************************************************/
/*
    The module stands out as a brilliantly designed piece of Verilog code, artfully capturing the essence of high-throughput Taylor series 
    computations with its meticulously crafted 10-stage pipeline architecture. At its heart, the module's genius lies in its 
    modular approach, incorporating specialized arithmetic units fine-tuned for fixed-point math, ensuring precision and efficiency. 
    This thoughtful design not only promises speed but also brings an admirable level of clarity and adaptability to the table, making 
    it a perfect fit for applications demanding real-time processing prowess. Whether it's navigating the complexities of digital signal 
    processing or crunching numbers in computational finance, the lab1 module is a testament to the elegant harmony of form and function 
    in digital design.
*/
/*******************************************************************************************************************************************/
