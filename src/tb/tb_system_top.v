`timescale 1ns / 1ps
// Original single-sample checker inputs kept as comments per editing rule:
//`define INPUT_HEXFILE "/workspace/fyp/fyp/input.dat"
//`define EXPECTED_OUTPUT_HEXFILE "/workspace/fyp/fyp/expected_output.dat"
`define INPUT_HEXFILE "/workspace/fyp/sw/mnist_t10k.dat"
`define EXPECTED_OUTPUT_HEXFILE "/workspace/fyp/sw/mnist_t10k_labels.dat"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2026 01:00:46 PM
// Design Name: 
// Module Name: tb_system_top
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


module tb_system_top;

    localparam N_SAMPLES = 64;
    localparam IN_BEATS_PER_SAMPLE = 784;
    localparam TOTAL_INPUT_BYTES = N_SAMPLES * IN_BEATS_PER_SAMPLE;

    reg clk;
    reg rst_n;

    integer i;
    integer input_file_lines;
    integer exp_output_file_lines;
    integer input_mismatch_count;
    integer observed_input_count;
    integer observed_output_count;
    integer timeout_cycles;

    reg [7:0] expected_input [0:TOTAL_INPUT_BYTES-1];
    reg [7:0] expected_output [0:N_SAMPLES-1];

    wire busy;
    wire done;
    wire [7:0] class_id;
    wire result_valid;

    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz input for clk_gen_0, which generates 100MHz internally
    end

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    initial begin
        input_file_lines = -1;
        exp_output_file_lines = -1;
        input_mismatch_count = 0;
        observed_input_count = 0;
        observed_output_count = 0;
        timeout_cycles = 0;

        $readmemh(`INPUT_HEXFILE, expected_input);
        for (i = 0; i < TOTAL_INPUT_BYTES; i = i + 1) begin
            if (expected_input[i][0] !== 1'bx)
                input_file_lines = i;
        end

        $readmemh(`EXPECTED_OUTPUT_HEXFILE, expected_output);
        for (i = 0; i < N_SAMPLES; i = i + 1) begin
            if (expected_output[i][0] !== 1'bx)
                exp_output_file_lines = i;
        end

        if (input_file_lines < 0) begin
            $display("ERROR: Unable to read input file: %s", `INPUT_HEXFILE);
            $finish;
        end

        if (exp_output_file_lines < 0) begin
            $display("ERROR: Unable to read expected output file: %s", `EXPECTED_OUTPUT_HEXFILE);
            $finish;
        end
    end

    system_top dut(
    .sys_clk   ( clk   ),
    .sys_rst_n ( rst_n ),
    .busy      ( busy      ),
    .done      ( done      ),
    .class_id  ( class_id  ),
    .result_valid  ( result_valid  )
    );

    always @(posedge dut.clk_100m) begin
        if (!dut.rst_n) begin
            observed_input_count <= 0;
            input_mismatch_count <= 0;
            observed_output_count <= 0;
            timeout_cycles <= 0;
        end else begin
            timeout_cycles <= timeout_cycles + 1;

            if (dut.u_dnn_accel.s_axis_0_tvalid && dut.u_dnn_accel.s_axis_0_tready) begin
                if (observed_input_count < TOTAL_INPUT_BYTES) begin
                    if (dut.u_dnn_accel.s_axis_0_tdata !== expected_input[observed_input_count]) begin
                        input_mismatch_count <= input_mismatch_count + 1;
                        $display("INPUT_MISMATCH idx=%0d got=%02h exp=%02h time=%0t", observed_input_count, dut.u_dnn_accel.s_axis_0_tdata, expected_input[observed_input_count], $time);
                    end
                end else begin
                    input_mismatch_count <= input_mismatch_count + 1;
                    $display("INPUT_OVERFLOW idx=%0d got=%02h time=%0t", observed_input_count, dut.u_dnn_accel.s_axis_0_tdata, $time);
                end
                observed_input_count <= observed_input_count + 1;
            end

            if (result_valid) begin
                if (observed_output_count < N_SAMPLES && class_id !== expected_output[observed_output_count]) begin
                    $display("OUTPUT_MISMATCH idx=%0d got=%02h exp=%02h time=%0t", observed_output_count, class_id, expected_output[observed_output_count], $time);
                end else begin
                    $display("OUTPUT_MATCH idx=%0d val=%02h time=%0t", observed_output_count, class_id, $time);
                end
                observed_output_count <= observed_output_count + 1;
            end

            if (done) begin
                $display("TOP_DONE inputs=%0d mismatches=%0d outputs=%0d class=%02h time=%0t", observed_input_count, input_mismatch_count, observed_output_count, class_id, $time);
            end

            if (timeout_cycles == 1200000) begin
                $display("TOP_TIMEOUT inputs=%0d mismatches=%0d outputs=%0d class=%02h time=%0t", observed_input_count, input_mismatch_count, observed_output_count, class_id, $time);
                $finish;
            end
        end
    end


endmodule
