`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 21:41:05
// Design Name: 
// Module Name: clk_rst_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_rst_gen(
    input   wire    sys_clk,
    input   wire    sys_rst_n,

    output  wire    clk_100m,
    output  reg     rst_n
    );

    reg [7:0] rst_counter = 8'd0;  // reset counter
    wire locked;

    clk_gen_0 clk_gen_inst
   (
    // Clock out ports
    .clk_out1(clk_100m),     // output clk_100m
    // Status and control signals
    .reset(sys_rst_n), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(sys_clk)      // input sys_clk
    );

    always @(posedge clk_100m or negedge locked) begin
        if (!locked) begin
            rst_counter <= 8'd0;
            rst_n <= 1'b0;      // maintain reset when not locked
        end else begin
            if (rst_counter != 8'hFF) begin
                rst_counter <= rst_counter + 8'd1;
                rst_n <= 1'b0;  // maintain reset during counting
            end else begin
                rst_n <= 1'b1;  // release reset after counting
            end
        end
    end
    
endmodule
