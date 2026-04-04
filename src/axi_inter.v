`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 21:41:05
// Design Name: 
// Module Name: axi_inter
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


module axi_inter(
    input clk,
    input rst,

    // CPU master
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_awaddr,

    input  wire        m_wvalid,
    output wire        m_wready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,

    output wire        m_bvalid,
    input  wire        m_bready,
    output wire [1:0]  m_bresp,

    input  wire        m_arvalid,
    output wire        m_arready,
    input  wire [31:0] m_araddr,

    output wire        m_rvalid,
    output wire        m_rlast,
    input  wire        m_rready,
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,

    // DRAM
    output wire        dram_awvalid,
    input  wire        dram_awready,
    output wire [31:0] dram_awaddr,

    output wire        dram_wvalid,
    input  wire        dram_wready,
    output wire [31:0] dram_wdata,
    output wire [3:0]  dram_wstrb,

    input  wire        dram_bvalid,
    output wire        dram_bready,
    input  wire [1:0]  dram_bresp,

    output wire        dram_arvalid,
    input  wire        dram_arready,
    output wire [31:0] dram_araddr,

    input  wire        dram_rvalid,
    input  wire        dram_rlast,
    output wire        dram_rready,
    input  wire [31:0] dram_rdata,
    input  wire [1:0]  dram_rresp,

    // DNN
    output wire        dnn_awvalid,
    input  wire        dnn_awready,
    output wire [31:0] dnn_awaddr,

    output wire        dnn_wvalid,
    input  wire        dnn_wready,
    output wire [31:0] dnn_wdata,
    output wire [3:0]  dnn_wstrb,

    input  wire        dnn_bvalid,
    output wire        dnn_bready,
    input  wire [1:0]  dnn_bresp,

    output wire        dnn_arvalid,
    input  wire        dnn_arready,
    output wire [31:0] dnn_araddr,

    input  wire        dnn_rvalid,
    output wire        dnn_rready,
    input  wire [31:0] dnn_rdata,
    input  wire [1:0]  dnn_rresp,

    // DMA
    output wire        dma_awvalid,
    input  wire        dma_awready,
    output wire [31:0] dma_awaddr,

    output wire        dma_wvalid,
    input  wire        dma_wready,
    output wire [31:0] dma_wdata,
    //output wire [3:0]  dma_wstrb,

    input  wire        dma_bvalid,
    output wire        dma_bready,
    input  wire [1:0]  dma_bresp,

    output wire        dma_arvalid,
    input  wire        dma_arready,
    output wire [31:0] dma_araddr,

    input  wire        dma_rvalid,
    output wire        dma_rready,
    input  wire [31:0] dma_rdata,
    input  wire [1:0]  dma_rresp
);

// address decode
//wire dram_aw_sel = (m_awaddr[31:16] == 16'h1000);
//wire dram_ar_sel = (m_araddr[31:16] == 16'h1000);

// Address decode
// 0x10000000 -> DRAM
// 0x20000000 -> DNN
// 0x30000000 -> DMA
localparam DRAM_BASE = 16'h1000;
localparam DNN_BASE  = 16'h2000;
localparam DMA_BASE  = 16'h3000;
// IO alias decode for VexRiscv uncached accesses (top nibble 0xF)
localparam DRAM_IO_BASE = 16'hF000;
localparam DNN_IO_BASE = 16'hF200;
localparam DMA_IO_BASE = 16'hF300;


wire dram_aw_sel = (m_awaddr[31:16] == DRAM_BASE) || (m_awaddr[31:16] == DRAM_IO_BASE);
wire dnn_aw_sel  = (m_awaddr[31:16] == DNN_BASE) || (m_awaddr[31:16] == DNN_IO_BASE);
wire dma_aw_sel  = (m_awaddr[31:16] == DMA_BASE) || (m_awaddr[31:16] == DMA_IO_BASE);

wire dram_ar_sel = (m_araddr[31:16] == DRAM_BASE) || (m_araddr[31:16] == DRAM_IO_BASE);
wire dnn_ar_sel  = (m_araddr[31:16] == DNN_BASE) || (m_araddr[31:16] == DNN_IO_BASE);
wire dma_ar_sel  = (m_araddr[31:16] == DMA_BASE) || (m_araddr[31:16] == DMA_IO_BASE);

reg [1:0] write_sel;
reg [1:0] read_sel;
reg       write_sel_valid;
reg       read_sel_valid;

wire aw_handshake = m_awvalid && m_awready;
wire ar_handshake = m_arvalid && m_arready;
wire b_handshake  = m_bvalid && m_bready;
wire r_handshake  = m_rvalid && m_rready;
wire r_last_handshake = m_rvalid && m_rready && m_rlast;

wire [1:0] aw_sel_dec = dram_aw_sel ? 2'b00 :
                        dnn_aw_sel  ? 2'b01 : 2'b10;
wire [1:0] ar_sel_dec = dram_ar_sel ? 2'b00 :
                        dnn_ar_sel  ? 2'b01 : 2'b10;

wire       write_path_valid = write_sel_valid || m_awvalid;
wire [1:0] write_path_sel   = write_sel_valid ? write_sel : aw_sel_dec;

reg [1:0]  write_buf_sel;
reg [31:0] write_buf_addr;
reg [31:0] write_buf_data;
reg [3:0]  write_buf_strb;
reg        write_addr_buf_valid;
reg        write_data_buf_valid;
reg        write_aw_sent;
reg        write_w_sent;

wire write_slave_valid = write_addr_buf_valid && write_data_buf_valid;
wire write_resp_pending = write_slave_valid && write_aw_sent && write_w_sent;
wire write_accept_aw = m_awvalid && m_awready;
wire write_accept_w  = m_wvalid && m_wready;
wire write_buf_awvalid = write_slave_valid && !write_aw_sent;
wire write_buf_wvalid  = write_slave_valid && !write_w_sent;
wire write_buf_awready = (write_buf_sel == 2'b00) ? dram_awready :
                         (write_buf_sel == 2'b01) ? dnn_awready  :
                                                  dma_awready;
wire write_buf_wready = (write_buf_sel == 2'b00) ? dram_wready :
                        (write_buf_sel == 2'b01) ? dnn_wready  :
                                                 dma_wready;
wire write_slave_aw_fire = write_buf_awvalid && write_buf_awready;
wire write_slave_w_fire  = write_buf_wvalid && write_buf_wready;

always @(posedge clk) begin
    if (rst) begin
        write_buf_sel <= 2'b00;
        write_buf_addr <= 32'b0;
        write_buf_data <= 32'b0;
        write_buf_strb <= 4'b0;
        write_addr_buf_valid <= 1'b0;
        write_data_buf_valid <= 1'b0;
        write_aw_sent <= 1'b0;
        write_w_sent <= 1'b0;
    end else if (b_handshake) begin
        write_addr_buf_valid <= 1'b0;
        write_data_buf_valid <= 1'b0;
        write_aw_sent <= 1'b0;
        write_w_sent <= 1'b0;
    end else begin
        if (write_accept_aw) begin
            write_buf_sel <= aw_sel_dec;
            write_buf_addr <= m_awaddr;
            write_addr_buf_valid <= 1'b1;
        end
        if (write_accept_w) begin
            write_buf_data <= m_wdata;
            write_buf_strb <= m_wstrb;
            write_data_buf_valid <= 1'b1;
        end
        if (write_slave_aw_fire)
            write_aw_sent <= 1'b1;
        if (write_slave_w_fire)
            write_w_sent <= 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        write_sel <= 2'b00;
        write_sel_valid <= 1'b0;
    end else begin
        if (aw_handshake) begin
            write_sel <= aw_sel_dec;
            write_sel_valid <= 1'b1;
        end else if (b_handshake) begin
            write_sel_valid <= 1'b0;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        read_sel <= 2'b00;
        read_sel_valid <= 1'b0;
    end else begin
        if (ar_handshake) begin
            read_sel <= ar_sel_dec;
            read_sel_valid <= 1'b1;
        end else if (r_last_handshake) begin
            read_sel_valid <= 1'b0;
        end
    end
end

// Write address channel
assign dram_awvalid = write_buf_awvalid && (write_buf_sel == 2'b00);
assign dnn_awvalid  = write_buf_awvalid && (write_buf_sel == 2'b01);
assign dma_awvalid  = write_buf_awvalid && (write_buf_sel == 2'b10);

assign dram_awaddr  = write_buf_addr;
assign dnn_awaddr   = write_buf_addr;
assign dma_awaddr   = write_buf_addr;

assign m_awready = !write_addr_buf_valid && !write_resp_pending;

// Write data channel
assign dram_wvalid = write_buf_wvalid && (write_buf_sel == 2'b00);
assign dnn_wvalid  = write_buf_wvalid && (write_buf_sel == 2'b01);
assign dma_wvalid  = write_buf_wvalid && (write_buf_sel == 2'b10);

assign dram_wdata  = write_buf_data;  assign dram_wstrb = write_buf_strb;
assign dnn_wdata   = write_buf_data;  assign dnn_wstrb  = write_buf_strb;
assign dma_wdata   = write_buf_data;  //assign dma_wstrb  = write_buf_strb;

assign m_wready = !write_data_buf_valid && !write_resp_pending;

// Write response channel
assign m_bvalid = !write_resp_pending ? 1'b0 :
                  (write_buf_sel == 2'b00) ? dram_bvalid :
                  (write_buf_sel == 2'b01) ? dnn_bvalid  :
                                             dma_bvalid;
assign m_bresp  = !write_resp_pending ? 2'b00 :
                  (write_buf_sel == 2'b00) ? dram_bresp :
                  (write_buf_sel == 2'b01) ? dnn_bresp  :
                                             dma_bresp;

assign dram_bready = (write_resp_pending && (write_buf_sel == 2'b00)) ? m_bready : 1'b0;
assign dnn_bready  = (write_resp_pending && (write_buf_sel == 2'b01)) ? m_bready : 1'b0;
assign dma_bready  = (write_resp_pending && (write_buf_sel == 2'b10)) ? m_bready : 1'b0;

// Read address channel
assign dram_arvalid = m_arvalid && dram_ar_sel;
assign dnn_arvalid  = m_arvalid && dnn_ar_sel;
assign dma_arvalid  = m_arvalid && dma_ar_sel;

assign dram_araddr  = m_araddr;
assign dnn_araddr   = m_araddr;
assign dma_araddr   = m_araddr;

assign m_arready = dram_ar_sel ? dram_arready :
                   dnn_ar_sel  ? dnn_arready  :
                                 dma_arready;

// Read data channel
assign m_rvalid = !read_sel_valid ? 1'b0 :
                  (read_sel == 2'b00) ? dram_rvalid :
                  (read_sel == 2'b01) ? dnn_rvalid  :
                                        dma_rvalid;
assign m_rdata  = !read_sel_valid ? 32'b0 :
                  (read_sel == 2'b00) ? dram_rdata :
                  (read_sel == 2'b01) ? dnn_rdata  :
                                        dma_rdata;
assign m_rresp  = !read_sel_valid ? 2'b00 :
                  (read_sel == 2'b00) ? dram_rresp :
                  (read_sel == 2'b01) ? dnn_rresp  :
                                        dma_rresp;
assign m_rlast  = !read_sel_valid ? 1'b0 :
                  (read_sel == 2'b00) ? dram_rlast :
                                        m_rvalid;

assign dram_rready = (read_sel_valid && (read_sel == 2'b00)) ? m_rready : 1'b0;
assign dnn_rready  = (read_sel_valid && (read_sel == 2'b01)) ? m_rready : 1'b0;
assign dma_rready  = (read_sel_valid && (read_sel == 2'b10)) ? m_rready : 1'b0;

endmodule
