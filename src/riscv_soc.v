`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 21:37:06
// Design Name: 
// Module Name: riscv_soc
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


module riscv_soc(
    input                   clk,
    input                   rst,                    //active high reset
    input   wire            externalInterrupt,      //sync for external interrupt if not same clock region
    input   wire            timerInterrupt,
    input   wire            softwareInterrupt,
    output  wire            start       ,
    output  wire  [31:0]    input_addr  ,
    output  wire  [31:0]    length      ,
    input   wire            done        ,
    input   wire  [ 7:0]    result_data ,
    input   wire            result_valid,
    output  wire  [ 7:0]    m_axis_mm2s_tdata,
    output  wire            m_axis_mm2s_tvalid,
    input   wire            m_axis_mm2s_tready
);

    parameter DRAM_DATAWIDTH = 32;
    parameter DRAM_ADDRWIDTH = 32;

    //irom wires
    wire            i_bram_rst;   
    wire            i_bram_clk;
    wire            i_bram_en;
    //wire [3 : 0]    i_bram_we; //irom not to be written
    wire [31 : 0]   i_bram_addr;
    wire [15 : 0]   i_bram_addr_lo;
    //wire [31 : 0]   i_bram_wrdata; //irom not to be written
    wire [31 : 0]   i_bram_rddata;
    wire            i_rsta_busy;

    //wire            i_s_axi_aresetn;
    //wire [15 : 0]   i_s_axi_awaddr;   //not used
    //wire [7 : 0]    i_s_axi_awlen;
    //wire [2 : 0]    i_s_axi_awsize;
    //wire [1 : 0]    i_s_axi_awburst;
    //wire            i_s_axi_awlock;
    //wire [3 : 0]    i_s_axi_awcache;
    //wire [2 : 0]    i_s_axi_awprot;
    //wire            i_s_axi_awvalid;
    wire            i_s_axi_awready;
    //wire [31 : 0]   i_s_axi_wdata;
    //wire [3 : 0]    i_s_axi_wstrb;
    //wire            i_s_axi_wlast;
    //wire            i_s_axi_wvalid;
    wire            i_s_axi_wready;
    wire [1 : 0]    i_s_axi_bresp;
    wire            i_s_axi_bvalid;
    //wire            i_s_axi_bready;   //always high
    wire [15 : 0]   i_s_axi_araddr;
    wire [7 : 0]    i_s_axi_arlen;
    wire [2 : 0]    i_s_axi_arsize;
    wire [1 : 0]    i_s_axi_arburst;
    wire            i_s_axi_arlock;
    wire [3 : 0]    i_s_axi_arcache;
    wire [2 : 0]    i_s_axi_arprot;
    wire            i_s_axi_arvalid;
    wire            i_s_axi_arready;
    wire [31 : 0]   i_s_axi_rdata;
    wire [1 : 0]    i_s_axi_rresp;
    wire            i_s_axi_rlast;
    wire            i_s_axi_rvalid;
    wire            i_s_axi_rready;

    wire [31 : 0]   i_cpu_araddr;
    assign i_s_axi_araddr = i_cpu_araddr[15:0]; //address trunction for 64KB bram

    //dram wires
    //wire            d_bram_rst;   
    //wire            d_bram_clk;
    //wire            d_bram_en;
    //wire [3 : 0]    d_bram_we;
    //wire [15 : 0]   d_bram_addr;
    //wire [31 : 0]   d_bram_wrdata; 
    //wire [31 : 0]   d_bram_rddata;
    //wire            d_rsta_busy;
    //wire            d_s_axi_aresetn;
    //wire [15 : 0]   d_s_axi_awaddr;
    wire [7 : 0]    d_s_axi_awlen;
    wire [2 : 0]    d_s_axi_awsize;
    wire [1 : 0]    d_s_axi_awburst;
    wire            d_s_axi_awlock;
    wire [3 : 0]    d_s_axi_awcache;
    wire [2 : 0]    d_s_axi_awprot;
    wire            d_s_axi_awvalid;
    wire            d_s_axi_awready;
    wire [31 : 0]   d_s_axi_wdata;
    wire [3 : 0]    d_s_axi_wstrb;
    //wire            d_s_axi_wlast;
    wire            d_s_axi_wvalid;
    wire            d_s_axi_wready;
    wire [1 : 0]    d_s_axi_bresp;
    wire            d_s_axi_bvalid;
    wire            d_s_axi_bready;
    wire [15 : 0]   d_s_axi_araddr;
    wire [7 : 0]    d_s_axi_arlen;
    wire [2 : 0]    d_s_axi_arsize;
    wire [1 : 0]    d_s_axi_arburst;
    wire            d_s_axi_arlock;
    wire [3 : 0]    d_s_axi_arcache;
    wire [2 : 0]    d_s_axi_arprot;
    wire            d_s_axi_arvalid;
    wire            d_s_axi_arready;
    wire [31 : 0]   d_s_axi_rdata;
    wire [1 : 0]    d_s_axi_rresp;
    wire            d_s_axi_rlast;
    wire            d_s_axi_rvalid;
    wire            d_s_axi_rready;
    wire            dnn_awready;
    wire            dnn_wready;
    wire            dnn_bvalid;
    wire [1:0]      dnn_bresp;
    wire            dnn_arready;
    wire            dnn_rvalid;
    wire [1:0]      dnn_rresp;
    wire [31:0]     dnn_rdata;

    // CPU AXI wires (to axi_inter)
    wire            m_awvalid;
    wire            m_awready;
    wire [31:0]     m_awaddr;
    wire            m_wvalid;
    wire            m_wready;
    wire [31:0]     m_wdata;
    wire [3:0]      m_wstrb;
    wire            m_bvalid;
    wire            m_bready;
    wire [1:0]      m_bresp;
    wire            m_arvalid;
    wire            m_arready;
    wire [31:0]     m_araddr;
    wire            m_rvalid;
    wire            m_rready;
    wire [31:0]     m_rdata;
    wire [1:0]      m_rresp;
    wire            m_wlast;
    wire            m_rlast;

    wire [31:0]     dram_awaddr;
    wire [31:0]     dram_araddr;

    // dram interface from axi_inter
    wire            dram_awvalid;
    wire            dram_wvalid;
    wire            dram_arvalid;
    wire            dram_wready;
    wire            dram_bready;
    wire            dram_arready;
    wire            dram_rready;
    // dnn interface from axi_inter
    wire [31:0]     dnn_awaddr;
    wire            dnn_awvalid;
    wire [31:0]     dnn_wdata;
    wire [3:0]      dnn_wstrb;
    wire            dnn_wvalid;
    wire            dnn_bready;
    wire [31:0]     dnn_araddr;
    wire            dnn_arvalid;
    wire            dnn_rready;

    wire [31:0]     dma_awaddr;
    wire [9:0]      dma_awaddr_trunc;
    wire            dma_awvalid;
    wire            dma_awready;
    wire [31:0]     dma_wdata;
    wire            dma_wvalid;
    wire            dma_wready;
    wire [1:0]      dma_bresp;
    wire            dma_bvalid;
    wire            dma_bready;
    wire [31:0]     dma_araddr;
    wire [9:0]      dma_araddr_trunc;
    wire            dma_arvalid;
    wire            dma_arready;
    wire [31:0]     dma_rdata;
    wire [1:0]      dma_rresp;
    wire            dma_rvalid;
    wire            dma_rready;

    wire [31:0]     dma_m_araddr;
    wire [7:0]      dma_m_arlen;
    wire [2:0]      dma_m_arsize;
    wire [1:0]      dma_m_arburst;
    wire [2:0]      dma_m_arprot;
    wire [3:0]      dma_m_arcache;
    wire            dma_m_arvalid;
    wire            dma_m_arready;
    wire [31:0]     dma_m_rdata;
    wire [1:0]      dma_m_rresp;
    wire            dma_m_rlast;
    wire            dma_m_rvalid;
    wire            dma_m_rready;

    wire            bram_rst_a;
    wire            bram_clk_a;
    wire            bram_en_a;
    wire [3:0]      bram_we_a;
    wire [31:0]     bram_addr_a;
    wire [15:0]     bram_addr_a_lo;
    wire [31:0]     bram_wrdata_a;
    wire [31:0]     bram_rddata_a;
    wire            bram_rst_b;
    wire            bram_clk_b;
    wire            bram_en_b;
    wire [3:0]      bram_we_b;
    wire [31:0]     bram_addr_b;
    wire [15:0]     bram_addr_b_lo;
    wire [31:0]     bram_wrdata_b;
    wire [31:0]     bram_rddata_b;

    wire            dma_bram_awready;
    wire            dma_bram_wready;
    wire [1:0]      dma_bram_bresp;
    wire            dma_bram_bvalid;
    wire            dma_bram_arready;
    wire [31:0]     dma_bram_rdata;
    wire [1:0]      dma_bram_rresp;
    wire            dma_bram_rlast;
    wire            dma_bram_rvalid;
    
    // tie-offs
    wire [0:0]  const_id   = 1'b0;
    wire [3:0]  const_qos  = 4'b0;
    wire [3:0]  const_region = 4'b0;
    wire [7:0]  const_len  = 8'd0;
    wire [2:0]  const_size = 3'b010; // 4 bytes
    wire [1:0]  const_burst = 2'b01; // INCR burst
    wire [0:0]  const_wlast = 1'b1;
    wire [0:0]  const_ready_low = 1'b0;
    wire [0:0]  const_ready_high = 1'b1;
    wire [1:0]  const_resp = 2'b0;
    wire [31:0] const_data = 32'b0;
    wire [1:0]  const_keep = 2'b11;
    wire [0:0]  const_valid = 1'b0;
    wire [0:0]  const_last_low = 1'b0;
    wire [0:0]  const_last_high = 1'b1;
    wire [15:0] const_addr = 16'b0;
    wire [0:0]  const_lock = 1'b0;
    wire [3:0]  const_cache = 4'b0;
    wire [2:0]  const_prot = 3'b0;
    wire [3:0]  const_strb = 4'b0;

    assign i_bram_addr = {16'b0, i_bram_addr_lo};
    assign bram_addr_a = {16'b0, bram_addr_a_lo};
    assign bram_addr_b = {16'b0, bram_addr_b_lo};

    assign dma_awaddr_trunc = dma_awaddr[9:0];
    assign dma_araddr_trunc = dma_araddr[9:0];

    // address map
    // 0x80000000 - 0x8000FFFF   IROM  (64 KB)
    // 0x10000000 - 0x1000FFFF   DRAM  (64 KB)
    // 0x20000000 - 0x20000FFF   DNN accelerator

    // DNN peripheral address map (offset from 0x20000000)
    // 0x20000000: CTRL    - control register (start, reset)
    // 0x20000004: STATUS  - status register (busy, done)
    // 0x20000008: CLASS   - result class id

blk_mem_gen_dram dual_dram (
  .clka(bram_clk_a),    // input wire clka
  .wea(bram_we_a),      // input wire [3 : 0] wea
  .addra(bram_addr_a),  // input wire [31 : 0] addra
  .dina(bram_wrdata_a),    // input wire [31 : 0] dina
  .douta(bram_rddata_a),  // output wire [31 : 0] douta
  .clkb(bram_clk_b),    // input wire clkb
  .web(bram_we_b),      // input wire [3 : 0] web
  .addrb(bram_addr_b),  // input wire [31 : 0] addrb
  .dinb(bram_wrdata_b),    // input wire [31 : 0] dinb
  .doutb(bram_rddata_b)  // output wire [31 : 0] doutb
);

axi_bram_ctrl_1 dma_ctrl (
  .s_axi_aclk(clk),        // input wire s_axi_aclk
  .s_axi_aresetn(~rst),  // input wire s_axi_aresetn
  .s_axi_awaddr(const_addr),    // input wire [15 : 0] s_axi_awaddr
  .s_axi_awlen(const_len),      // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(const_size),    // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(const_burst),  // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(const_lock),    // input wire s_axi_awlock
  .s_axi_awcache(const_cache),  // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(const_prot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(const_valid),  // input wire s_axi_awvalid
  .s_axi_awready(dma_bram_awready),  // output wire s_axi_awready
  .s_axi_wdata(const_data),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(const_strb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(const_last_high),      // input wire s_axi_wlast
  .s_axi_wvalid(const_valid),    // input wire s_axi_wvalid
  .s_axi_wready(dma_bram_wready),    // output wire s_axi_wready
  .s_axi_bresp(dma_bram_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(dma_bram_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(const_ready_high),    // input wire s_axi_bready
  .s_axi_araddr(dma_m_araddr[15:0]),    // input wire [15 : 0] s_axi_araddr
  .s_axi_arlen(dma_m_arlen),      // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(dma_m_arsize),    // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(dma_m_arburst),  // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(const_lock),    // input wire s_axi_arlock
  .s_axi_arcache(dma_m_arcache),  // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(dma_m_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(dma_m_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(dma_m_arready),  // output wire s_axi_arready
  .s_axi_rdata(dma_m_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(dma_m_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(dma_m_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(dma_m_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(dma_m_rready),    // input wire s_axi_rready
  .bram_rst_a(bram_rst_b),        // output wire bram_rst_a
  .bram_clk_a(bram_clk_b),        // output wire bram_clk_a
  .bram_en_a(bram_en_b),          // output wire bram_en_a
  .bram_we_a(bram_we_b),          // output wire [3 : 0] bram_we_a
  .bram_addr_a(bram_addr_b_lo),      // output wire [15 : 0] bram_addr_a
  .bram_wrdata_a(bram_wrdata_b),  // output wire [31 : 0] bram_wrdata_a
  .bram_rddata_a(bram_rddata_b)  // input wire [31 : 0] bram_rddata_a
);

axi_bram_ctrl_1 cpu_ctrl (
  .s_axi_aclk(clk),        // input wire s_axi_aclk
  .s_axi_aresetn(~rst),  // input wire s_axi_aresetn
  .s_axi_awaddr(dram_awaddr[15:0]),    // input wire [15 : 0] s_axi_awaddr
  .s_axi_awlen(d_s_axi_awlen),      // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(d_s_axi_awsize),    // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(d_s_axi_awburst),  // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(d_s_axi_awlock),    // input wire s_axi_awlock
  .s_axi_awcache(d_s_axi_awcache),  // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(d_s_axi_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(dram_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(d_s_axi_awready),  // output wire s_axi_awready
  .s_axi_wdata(d_s_axi_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(d_s_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(const_wlast),      // input wire s_axi_wlast
  .s_axi_wvalid(dram_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready(d_s_axi_wready),    // output wire s_axi_wready
  .s_axi_bresp(d_s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(d_s_axi_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(d_s_axi_bready),    // input wire s_axi_bready
  .s_axi_araddr(dram_araddr[15:0]),    // input wire [15 : 0] s_axi_araddr
  .s_axi_arlen(d_s_axi_arlen),      // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(d_s_axi_arsize),    // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(d_s_axi_arburst),  // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(d_s_axi_arlock),    // input wire s_axi_arlock
  .s_axi_arcache(d_s_axi_arcache),  // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(d_s_axi_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(dram_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(d_s_axi_arready),  // output wire s_axi_arready
  .s_axi_rdata(d_s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(d_s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(d_s_axi_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(d_s_axi_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(d_s_axi_rready),    // input wire s_axi_rready
  .bram_rst_a(bram_rst_a),        // output wire bram_rst_a
  .bram_clk_a(bram_clk_a),        // output wire bram_clk_a
  .bram_en_a(bram_en_a),          // output wire bram_en_a
  .bram_we_a(bram_we_a),          // output wire [3 : 0] bram_we_a
  .bram_addr_a(bram_addr_a_lo),      // output wire [15 : 0] bram_addr_a
  .bram_wrdata_a(bram_wrdata_a),  // output wire [31 : 0] bram_wrdata_a
  .bram_rddata_a(bram_rddata_a)  // input wire [31 : 0] bram_rddata_a
);


blk_mem_gen_irom irom_bram (
    .clka       (i_bram_clk),            // input wire clka
    .rsta       (i_bram_rst),            // input wire rsta
    .ena        (i_bram_en),              // input wire ena
    .wea        (4'b0),                     // input wire [3 : 0] wea
    .addra      (i_bram_addr),          // input wire [31 : 0] addra
    .dina       (32'b0),                     // input wire [31 : 0] dina
    .douta      (i_bram_rddata),          // output wire [31 : 0] douta
    .rsta_busy  (i_rsta_busy)             // output wire rsta_busy
);

axi_bram_ctrl_0 irom_ctrl(
    .s_axi_aclk     (clk),               // input wire s_axi_aclk
    .s_axi_aresetn  (~rst),             // input wire s_axi_aresetn
    .s_axi_awaddr   (16'b0),            // input wire [15 : 0] s_axi_awaddr
    .s_axi_awlen    (8'b0),              // input wire [7 : 0] s_axi_awlen
    .s_axi_awsize   (3'b0),             // input wire [2 : 0] s_axi_awsize
    .s_axi_awburst  (2'b0),             // input wire [1 : 0] s_axi_awburst
    .s_axi_awlock   (1'b0),             // input wire s_axi_awlock
    .s_axi_awcache  (4'b0),             // input wire [3 : 0] s_axi_awcache
    .s_axi_awprot   (3'b0),             // input wire [2 : 0] s_axi_awprot
    .s_axi_awvalid  (1'b0),             // input wire s_axi_awvalid
    .s_axi_awready  (i_s_axi_awready),  // output wire s_axi_awready
    .s_axi_wdata    (32'b0),             // input wire [31 : 0] s_axi_wdata
    .s_axi_wstrb    (4'b0),             // input wire [3 : 0] s_axi_wstrb
    .s_axi_wlast    (1'b0),             // input wire s_axi_wlast
    .s_axi_wvalid   (1'b0),                 // input wire s_axi_wvalid
    .s_axi_wready   (i_s_axi_wready),    // output wire s_axi_wready
    .s_axi_bresp    (i_s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid   (i_s_axi_bvalid),    // output wire s_axi_bvalid
    .s_axi_bready   (1'b1),             // input wire s_axi_bready, always ready to accept
    .s_axi_araddr   (i_s_axi_araddr),    // input wire [15 : 0] s_axi_araddr
    .s_axi_arlen    (i_s_axi_arlen),      // input wire [7 : 0] s_axi_arlen
    .s_axi_arsize   (i_s_axi_arsize),    // input wire [2 : 0] s_axi_arsize
    .s_axi_arburst  (i_s_axi_arburst),  // input wire [1 : 0] s_axi_arburst
    .s_axi_arlock   (i_s_axi_arlock),    // input wire s_axi_arlock
    .s_axi_arcache  (i_s_axi_arcache),  // input wire [3 : 0] s_axi_arcache
    .s_axi_arprot   (i_s_axi_arprot),    // input wire [2 : 0] s_axi_arprot
    .s_axi_arvalid  (i_s_axi_arvalid),  // input wire s_axi_arvalid
    .s_axi_arready  (i_s_axi_arready),  // output wire s_axi_arready
    .s_axi_rdata    (i_s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
    .s_axi_rresp    (i_s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast    (i_s_axi_rlast),      // output wire s_axi_rlast
    .s_axi_rvalid   (i_s_axi_rvalid),    // output wire s_axi_rvalid
    .s_axi_rready   (i_s_axi_rready),    // input wire s_axi_rready
    .bram_rst_a     (i_bram_rst),        // output wire bram_rst_a
    .bram_clk_a     (i_bram_clk),        // output wire bram_clk_a
    .bram_en_a      (i_bram_en),          // output wire bram_en_a
    .bram_we_a      (),                   // output wire [3 : 0] bram_we_a
    .bram_addr_a    (i_bram_addr_lo),      // output wire [15 : 0] bram_addr_a
    .bram_wrdata_a  (),               // output wire [31 : 0] bram_wrdata_a
    .bram_rddata_a  (i_bram_rddata)   // input wire [31 : 0] bram_rddata_a
);

axi_dma_0 u_axi_dma (
  .s_axi_lite_aclk(clk),                // input wire s_axi_lite_aclk
  .m_axi_mm2s_aclk(clk),                // input wire m_axi_mm2s_aclk
  .axi_resetn(~rst),                          // input wire axi_resetn
  .s_axi_lite_awvalid(dma_awvalid),          // input wire s_axi_lite_awvalid
  .s_axi_lite_awready(dma_awready),          // output wire s_axi_lite_awready
  .s_axi_lite_awaddr(dma_awaddr_trunc),            // input wire [9 : 0] s_axi_lite_awaddr
  .s_axi_lite_wvalid(dma_wvalid),            // input wire s_axi_lite_wvalid
  .s_axi_lite_wready(dma_wready),            // output wire s_axi_lite_wready
  .s_axi_lite_wdata(dma_wdata),              // input wire [31 : 0] s_axi_lite_wdata
  //.s_axi_lite_wstrb(dma_wstrb),              // input wire [3 : 0] s_axi_lite_wstrb
  .s_axi_lite_bresp(dma_bresp),              // output wire [1 : 0] s_axi_lite_bresp
  .s_axi_lite_bvalid(dma_bvalid),            // output wire s_axi_lite_bvalid
  .s_axi_lite_bready(dma_bready),            // input wire s_axi_lite_bready
  .s_axi_lite_arvalid(dma_arvalid),          // input wire s_axi_lite_arvalid
  .s_axi_lite_arready(dma_arready),          // output wire s_axi_lite_arready
  .s_axi_lite_araddr(dma_araddr_trunc),            // input wire [9 : 0] s_axi_lite_araddr
  .s_axi_lite_rvalid(dma_rvalid),            // output wire s_axi_lite_rvalid
  .s_axi_lite_rready(dma_rready),            // input wire s_axi_lite_rready
  .s_axi_lite_rdata(dma_rdata),              // output wire [31 : 0] s_axi_lite_rdata
  .s_axi_lite_rresp(dma_rresp),              // output wire [1 : 0] s_axi_lite_rresp
  .m_axi_mm2s_araddr(dma_m_araddr),            // output wire [31 : 0] m_axi_mm2s_araddr
  .m_axi_mm2s_arlen(dma_m_arlen),              // output wire [7 : 0] m_axi_mm2s_arlen
  .m_axi_mm2s_arsize(dma_m_arsize),            // output wire [2 : 0] m_axi_mm2s_arsize
  .m_axi_mm2s_arburst(dma_m_arburst),          // output wire [1 : 0] m_axi_mm2s_arburst
  .m_axi_mm2s_arprot(dma_m_arprot),            // output wire [2 : 0] m_axi_mm2s_arprot
  .m_axi_mm2s_arcache(dma_m_arcache),          // output wire [3 : 0] m_axi_mm2s_arcache
  .m_axi_mm2s_arvalid(dma_m_arvalid),          // output wire m_axi_mm2s_arvalid
  .m_axi_mm2s_arready(dma_m_arready),          // input wire m_axi_mm2s_arready
  .m_axi_mm2s_rdata(dma_m_rdata),              // input wire [31 : 0] m_axi_mm2s_rdata
  .m_axi_mm2s_rresp(dma_m_rresp),              // input wire [1 : 0] m_axi_mm2s_rresp
  .m_axi_mm2s_rlast(dma_m_rlast),              // input wire m_axi_mm2s_rlast
  .m_axi_mm2s_rvalid(dma_m_rvalid),            // input wire m_axi_mm2s_rvalid
  .m_axi_mm2s_rready(dma_m_rready),            // output wire m_axi_mm2s_rready
  .mm2s_prmry_reset_out_n(),  // output wire mm2s_prmry_reset_out_n
  .m_axis_mm2s_tdata(m_axis_mm2s_tdata),            // output wire [7 : 0] m_axis_mm2s_tdata
  .m_axis_mm2s_tkeep(),            // output wire [0 : 0] m_axis_mm2s_tkeep
  .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),          // output wire m_axis_mm2s_tvalid
  .m_axis_mm2s_tready(m_axis_mm2s_tready),          // input wire m_axis_mm2s_tready
  .m_axis_mm2s_tlast(),            // output wire m_axis_mm2s_tlast
  .mm2s_introut(),                      // output wire mm2s_introut
  .axi_dma_tstvec()                  // output wire [31 : 0] axi_dma_tstvec
);

axi_inter u_axi_inter(
    .clk            (clk),
    .rst            (rst),

    // CPU master
    .m_awvalid      (m_awvalid),
    .m_awready      (m_awready),
    .m_awaddr       (m_awaddr),
    .m_wvalid       (m_wvalid),
    .m_wready       (m_wready),
    .m_wdata        (m_wdata),
    .m_wstrb        (m_wstrb),
    .m_bvalid       (m_bvalid),
    .m_bready       (m_bready),
    .m_bresp        (m_bresp),
    .m_arvalid      (m_arvalid),
    .m_arready      (m_arready),
    .m_araddr       (m_araddr),
    .m_rvalid       (m_rvalid),
    .m_rlast        (m_rlast),
    .m_rready       (m_rready),
    .m_rdata        (m_rdata),
    .m_rresp        (m_rresp),

    // DRAM
    .dram_awvalid   (dram_awvalid),
    .dram_awready   (d_s_axi_awready),
    .dram_awaddr    (dram_awaddr),
    .dram_wvalid    (dram_wvalid),
    .dram_wready    (d_s_axi_wready),
    .dram_wdata     (d_s_axi_wdata),
    .dram_wstrb     (d_s_axi_wstrb),
    .dram_bvalid    (d_s_axi_bvalid),
    .dram_bready    (d_s_axi_bready),
    .dram_bresp     (d_s_axi_bresp),
    .dram_arvalid   (dram_arvalid),
    .dram_arready   (d_s_axi_arready),
    .dram_araddr    (dram_araddr),
    .dram_rvalid    (d_s_axi_rvalid),
    .dram_rlast     (d_s_axi_rlast),
    .dram_rready    (d_s_axi_rready),
    .dram_rdata     (d_s_axi_rdata),
    .dram_rresp     (d_s_axi_rresp),

    // DNN
    .dnn_awvalid    (dnn_awvalid),
    .dnn_awready    (dnn_awready),
    .dnn_awaddr     (dnn_awaddr),
    .dnn_wvalid     (dnn_wvalid),
    .dnn_wready     (dnn_wready),
    .dnn_wdata      (dnn_wdata),
    .dnn_wstrb      (dnn_wstrb),
    .dnn_bvalid     (dnn_bvalid),
    .dnn_bready     (dnn_bready),
    .dnn_bresp      (dnn_bresp),
    .dnn_arvalid    (dnn_arvalid),
    .dnn_arready    (dnn_arready),
    .dnn_araddr     (dnn_araddr),
    .dnn_rvalid     (dnn_rvalid),
    .dnn_rready     (dnn_rready),
    .dnn_rdata      (dnn_rdata),
    .dnn_rresp      (dnn_rresp),

    // DMA
    .dma_awvalid    (dma_awvalid),    
    .dma_awready    (dma_awready),
    .dma_awaddr     (dma_awaddr),
    .dma_wvalid     (dma_wvalid),
    .dma_wready     (dma_wready),
    .dma_wdata      (dma_wdata),
    //.dma_wstrb      (dma_wstrb),
    .dma_bvalid     (dma_bvalid),
    .dma_bready     (dma_bready),
    .dma_bresp      (dma_bresp),
    .dma_arvalid    (dma_arvalid),
    .dma_arready    (dma_arready),
    .dma_araddr     (dma_araddr),
    .dma_rvalid     (dma_rvalid),
    .dma_rready     (dma_rready),
    .dma_rdata      (dma_rdata),
    .dma_rresp      (dma_rresp)
);


accel_ctrl_regs dnn_regs(
    .clk            (clk),
    .rst_n          (~rst),

    .s_axi_awaddr   (dnn_awaddr),
    .s_axi_awvalid  (dnn_awvalid),
    .s_axi_awready  (dnn_awready),

    .s_axi_wdata    (dnn_wdata),
    .s_axi_wstrb    (dnn_wstrb),
    .s_axi_wvalid   (dnn_wvalid),
    .s_axi_wready   (dnn_wready),

    .s_axi_bresp    (dnn_bresp),
    .s_axi_bvalid   (dnn_bvalid),
    .s_axi_bready   (dnn_bready),

    .s_axi_araddr   (dnn_araddr),
    .s_axi_arvalid  (dnn_arvalid),
    .s_axi_arready  (dnn_arready),

    .s_axi_rdata    (dnn_rdata),
    .s_axi_rresp    (dnn_rresp),
    .s_axi_rvalid   (dnn_rvalid),
    .s_axi_rready   (dnn_rready),

    .start          (start       ),
    .input_addr     (input_addr  ),
    .length         (length      ),
    .done           (done        ),
    .result_data    (result_data ),
    .result_valid   (result_valid)
);

VexRiscvAxi4 riscv_core(
    .debug_resetOut             (),
    .timerInterrupt             (timerInterrupt),
    .externalInterrupt          (externalInterrupt),
    .softwareInterrupt          (softwareInterrupt),
    .iBusAxi_ar_valid           (i_s_axi_arvalid),
    .iBusAxi_ar_ready           (i_s_axi_arready),
    .iBusAxi_ar_payload_addr    (i_cpu_araddr),
    .iBusAxi_ar_payload_id      (const_id),
    .iBusAxi_ar_payload_region  (const_region),
    .iBusAxi_ar_payload_len     (i_s_axi_arlen),
    .iBusAxi_ar_payload_size    (i_s_axi_arsize),
    //.iBusAxi_ar_payload_size    (const_size),
    .iBusAxi_ar_payload_burst   (i_s_axi_arburst),
    .iBusAxi_ar_payload_lock    (i_s_axi_arlock),
    .iBusAxi_ar_payload_cache   (i_s_axi_arcache),
    .iBusAxi_ar_payload_qos     (const_qos),
    .iBusAxi_ar_payload_prot    (i_s_axi_arprot),
    .iBusAxi_r_valid            (i_s_axi_rvalid),
    .iBusAxi_r_ready            (i_s_axi_rready),
    .iBusAxi_r_payload_data     (i_s_axi_rdata),
    .iBusAxi_r_payload_id       (const_id),
    .iBusAxi_r_payload_resp     (i_s_axi_rresp),
    .iBusAxi_r_payload_last     (i_s_axi_rlast),
    .dBusAxi_aw_valid           (m_awvalid),
    .dBusAxi_aw_ready           (m_awready),
    .dBusAxi_aw_payload_addr    (m_awaddr),
    .dBusAxi_aw_payload_id      (const_id),
    .dBusAxi_aw_payload_region  (const_region),
    .dBusAxi_aw_payload_len     (d_s_axi_awlen),
    .dBusAxi_aw_payload_size    (d_s_axi_awsize),
    .dBusAxi_aw_payload_burst   (d_s_axi_awburst),
    .dBusAxi_aw_payload_lock    (d_s_axi_awlock),
    .dBusAxi_aw_payload_cache   (d_s_axi_awcache),
    .dBusAxi_aw_payload_qos     (const_qos),
    .dBusAxi_aw_payload_prot    (d_s_axi_awprot),
    .dBusAxi_w_valid            (m_wvalid),
    .dBusAxi_w_ready            (m_wready),
    .dBusAxi_w_payload_data     (m_wdata),
    .dBusAxi_w_payload_strb     (m_wstrb),
    .dBusAxi_w_payload_last     (m_wlast),
    .dBusAxi_b_valid            (m_bvalid),
    .dBusAxi_b_ready            (m_bready),
    .dBusAxi_b_payload_id       (const_id),
    .dBusAxi_b_payload_resp     (m_bresp),
    .dBusAxi_ar_valid           (m_arvalid),
    .dBusAxi_ar_ready           (m_arready),
    .dBusAxi_ar_payload_addr    (m_araddr),
    .dBusAxi_ar_payload_id      (const_id),
    .dBusAxi_ar_payload_region  (const_region),
    .dBusAxi_ar_payload_len     (d_s_axi_arlen),
    .dBusAxi_ar_payload_size    (d_s_axi_arsize),
    .dBusAxi_ar_payload_burst   (d_s_axi_arburst),
    .dBusAxi_ar_payload_lock    (d_s_axi_arlock),
    .dBusAxi_ar_payload_cache   (d_s_axi_arcache),
    .dBusAxi_ar_payload_qos     (const_qos),
    .dBusAxi_ar_payload_prot    (d_s_axi_arprot),
    .dBusAxi_r_valid            (m_rvalid),
    .dBusAxi_r_ready            (m_rready),
    .dBusAxi_r_payload_data     (m_rdata),
    .dBusAxi_r_payload_id       (const_id),
    .dBusAxi_r_payload_resp     (m_rresp),
    .dBusAxi_r_payload_last     (m_rlast),
    .jtag_tms                   (),
    .jtag_tdi                   (),
    .jtag_tdo                   (),
    .jtag_tck                   (),
    .clk                        (clk),
    .reset                      (rst), //active high reset
    .debugReset                 ()
);

endmodule 