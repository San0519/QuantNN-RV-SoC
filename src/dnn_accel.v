`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 21:40:12
// Design Name: 
// Module Name: dnn_accel
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

module dnn_accel(
    input           ap_clk,
    input           ap_rst_n,
    output [7:0]    m_axis_0_tdata,
    input           m_axis_0_tready,
    output          m_axis_0_tvalid,
    input  [7:0]    s_axis_0_tdata,
    output          s_axis_0_tready,
    input           s_axis_0_tvalid,
    output          done,
    output          busy,
    input           start   //NOTE: start should be triggered few(>=5) cycles before feeding data to the finn IP
);

    parameter OUT_NUM = 1; //finn IP outputs one 10-class result
    parameter IN_NUM = 784;

    localparam IDLE = 2'd0;
    localparam RUN  = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state, next_state;
    reg [15:0] out_cnt;
    reg [15:0] in_cnt;
    reg done_reg;
    reg done_reg_d;
    reg start_latched;
    wire finn_s_axis_0_tready;
    wire input_stream_enable;
    wire s_axis_0_tvalid_to_ip;

    always @(posedge ap_clk or negedge ap_rst_n) begin
        if (!ap_rst_n)
            state <= IDLE;
        else
            state <= next_state;
end

    always @(*) begin
        next_state = IDLE;
        case (state)
            IDLE:  next_state = start_latched ? RUN : IDLE;
            //IDLE:  next_state = start ? RUN : IDLE;
            RUN: next_state = (out_cnt == OUT_NUM - 1) &&   //sync design
                  m_axis_0_tvalid && m_axis_0_tready
                  ? DONE : RUN;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
end

    always @(posedge ap_clk or negedge ap_rst_n) begin
        if (!ap_rst_n)
            out_cnt <= 0;
        else if (state == RUN) begin
            if (m_axis_0_tvalid && m_axis_0_tready)
                out_cnt <= out_cnt + 1;
        end else
            out_cnt <= 0;
end

    always @(posedge ap_clk or negedge ap_rst_n) begin
        if (!ap_rst_n)
            done_reg <= 0;
        else if (state == DONE)
            done_reg <= 1;
        else if (start && state==IDLE)
            done_reg <= 0;
end

    always @(posedge ap_clk or negedge ap_rst_n) begin
            if (!ap_rst_n)
                done_reg_d <= 0;
            else done_reg_d <= done_reg;
end

    always @(posedge ap_clk or negedge ap_rst_n) begin
        if (!ap_rst_n)
            start_latched <= 0;
        else if (start && state==IDLE)  //ignore new start if not IDLE
            start_latched <= 1;   // capture start
        else if (state == RUN)
            start_latched <= 0;   // clear once in RUN state
end

    always @(posedge ap_clk or negedge ap_rst_n) begin
        if (!ap_rst_n)
            in_cnt <= 0;
        else if (state == RUN && (s_axis_0_tvalid && s_axis_0_tready)) begin
            in_cnt <= in_cnt + 1;
        end else if(m_axis_0_tvalid)
            in_cnt <= 0;
end

    assign busy = (state == RUN) ? 1'b1 : 1'b0;
    assign done = done_reg & ~done_reg_d;
    assign input_stream_enable = (state == RUN && in_cnt < IN_NUM);
    assign s_axis_0_tvalid_to_ip = input_stream_enable ? s_axis_0_tvalid : 1'b0;
    assign s_axis_0_tready = input_stream_enable ? finn_s_axis_0_tready : 1'b0;

    finn_design_wrapper finn_design_wrapper_inst(
    .ap_clk          (ap_clk                ),
    .ap_rst_n        (ap_rst_n              ),
    .m_axis_0_tdata  (m_axis_0_tdata        ),
    .m_axis_0_tready (m_axis_0_tready       ),
    .m_axis_0_tvalid (m_axis_0_tvalid       ),
    .s_axis_0_tdata  (s_axis_0_tdata        ),
    .s_axis_0_tready (finn_s_axis_0_tready  ),
    .s_axis_0_tvalid (s_axis_0_tvalid_to_ip )
);
endmodule
