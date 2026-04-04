//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2026 04:17:15 PM
// Design Name: 
// Module Name: tb_dnn_accel
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

`define INPUT_HEXFILE "/workspace/fyp/fyp/input.dat"
`define EXPECTED_OUTPUT_HEXFILE "/workspace/fyp/fyp/expected_output.dat"

// general FINN testbench parameters
parameter N_SAMPLES = 1;
parameter IN_STREAM_BITWIDTH = 8;
parameter OUT_STREAM_BITWIDTH = 8;
parameter IN_BEATS_PER_SAMPLE = 784;
parameter OUT_BEATS_PER_SAMPLE = 1;
parameter TIMEOUT_CYCLES = 1000;

parameter IN_SAMPLE_BITWIDTH = IN_STREAM_BITWIDTH * IN_BEATS_PER_SAMPLE;
parameter OUT_SAMPLE_BITWIDTH = OUT_STREAM_BITWIDTH * OUT_BEATS_PER_SAMPLE;

module tb_dnn_accel ();


logic [IN_STREAM_BITWIDTH-1:0] input_data [N_SAMPLES*IN_BEATS_PER_SAMPLE];
logic [OUT_STREAM_BITWIDTH-1:0] exp_output_data [N_SAMPLES*OUT_BEATS_PER_SAMPLE];
logic [IN_STREAM_BITWIDTH-1:0] current_input [IN_BEATS_PER_SAMPLE];
logic [$clog2(N_SAMPLES*OUT_BEATS_PER_SAMPLE):0] rd_ptr=0;
logic [$clog2(N_SAMPLES*OUT_BEATS_PER_SAMPLE):0] wr_ptr=0;
int err_count=0;
int data_count=0;
int i,j,cnt;
logic [31:0] input_file_lines;
logic [31:0] exp_output_file_lines;

logic ap_clk = 0;
logic ap_rst_n = 0;

logic [OUT_STREAM_BITWIDTH-1:0] dout_tdata;
logic dout_tlast;
logic dout_tready;
logic dout_tvalid;

logic [IN_STREAM_BITWIDTH-1:0] din_tdata;
logic din_tready;
logic din_tvalid;
logic start;
logic done;



dnn_accel dnn_accel_dut (
  .ap_clk                (ap_clk               ),
  .ap_rst_n              (ap_rst_n             ),
  // output stream
  .m_axis_0_tdata        (dout_tdata           ),
  .m_axis_0_tready       (dout_tready          ),
  .m_axis_0_tvalid       (dout_tvalid          ),
  // input stream
  .s_axis_0_tdata        (din_tdata           ),
  .s_axis_0_tready       (din_tready          ),
  .s_axis_0_tvalid       (din_tvalid          ),
  .start                 (start               ),
  .done                  (done                )
);

//finn_design_wrapper finn_design_wrapper_dut (
//  .ap_clk                (ap_clk               ),
//  .ap_rst_n              (ap_rst_n             ),
//  // output stream
//  .m_axis_0_tdata        (dout_tdata           ),
//  .m_axis_0_tready       (dout_tready          ),
//  .m_axis_0_tvalid       (dout_tvalid          ),
//  // input stream
//  .s_axis_0_tdata        (din_tdata           ),
//  .s_axis_0_tready       (din_tready          ),
//  .s_axis_0_tvalid       (din_tvalid          )
//);

always #5ns ap_clk = !ap_clk;

initial begin
    // read input hexfile
    $readmemh(`INPUT_HEXFILE, input_data);
    for (i=0; i<N_SAMPLES*IN_BEATS_PER_SAMPLE; i+=1)  if (input_data[i][0] !== 1'bx) input_file_lines = i;
    if (input_file_lines[0] === {1'bx}) begin
        $display("ERROR:  Unable to read dat file: %s",`INPUT_HEXFILE);
        $finish;
    end
    // read expected output hexfile
    $readmemh(`EXPECTED_OUTPUT_HEXFILE, exp_output_data);
    for (i=0; i<N_SAMPLES*OUT_BEATS_PER_SAMPLE; i+=1)  if (exp_output_data[i][0] !== 1'bx) exp_output_file_lines = i;
    if (exp_output_file_lines[0] === {1'bx}) begin
        $display("ERROR:  Unable to read dat file: %s",`EXPECTED_OUTPUT_HEXFILE);
        $finish;
    end

    din_tvalid = 0;
    din_tdata = 0;
    dout_tready = 1;

    // perform reset
    repeat (100)  @(negedge ap_clk);
    ap_rst_n = 1;
    repeat (100)  @(negedge ap_clk);
    dout_tready = 1;

    repeat (10)  @(negedge ap_clk);
    @(negedge ap_clk);
    @(negedge ap_clk);

    repeat (5) @(negedge ap_clk)
    @(posedge ap_clk); start = 1;
    @(posedge ap_clk); start = 0;

    repeat (10) @(negedge ap_clk);

    // feed all inputs
    for (j=0; j<N_SAMPLES; j+=1) begin
        // get current input and expected output samples from batch data
        for (i=0; i<IN_BEATS_PER_SAMPLE; i+=1) begin
            current_input[i] = input_data[j*IN_BEATS_PER_SAMPLE+i];
        end
        // put corresponding expected output into queue
        // data is already in exp_output_data
        for (i=0; i<OUT_BEATS_PER_SAMPLE; i+=1) begin
            wr_ptr++;
        end
        // feed current input
        for (i=0; i<IN_BEATS_PER_SAMPLE; i+=1) begin
            din_tvalid = 1;
            din_tdata = current_input[i];
            @(negedge ap_clk);
            // TODO add timeout on input backpressure
            while (~din_tready)  @(negedge ap_clk);
            din_tvalid = 0;
        end
    end

    for (cnt=0; din_tvalid && din_tready; cnt+=1) 
        $display("IN %d: %h", cnt, din_tdata);

    din_tdata = 0;
    din_tvalid = 0;

    repeat (TIMEOUT_CYCLES)  @(negedge ap_clk);
    din_tdata = 0;
    if (wr_ptr != rd_ptr) begin
        $display("ERR: End-sim check: rd_ptr %h != %h wr_ptr",rd_ptr, wr_ptr);
        err_count++;
    end

    $display("\n************************************************************ ");
    $display("  SIM COMPLETE");
    $display("  Validated %0d data points ",data_count);
    $display("  Total error count: ====>  %0d  <====\n",err_count);
    $finish;
end


// Check the result at each valid output from the model
always @(posedge ap_clk) begin
  if (dout_tvalid && ap_rst_n) begin
    // TODO implement output folding - current code assumes OUT_BEATS_PER_SAMPLE=1
    if (dout_tdata !== exp_output_data[rd_ptr]) begin
      $display("ERR: Data mismatch %h != %h ",dout_tdata, exp_output_data[rd_ptr]);
      err_count++;
    end else begin
      $display("CHK: Data    match %h == %h   --> %0d",dout_tdata, exp_output_data[rd_ptr], data_count);
    end
    rd_ptr++;
    data_count++;
  end
end

endmodule
