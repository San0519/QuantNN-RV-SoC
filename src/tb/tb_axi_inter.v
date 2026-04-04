`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2026 10:07:48 PM
// Design Name: 
// Module Name: tb_axi_inter
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


module tb_axi_inter;

    reg clk;
    reg rst;

    reg m_awvalid   ;
    wire m_awready   ;
    reg [31:0] m_awaddr    ;
    reg m_wvalid    ;
    wire m_wready    ;
    reg [31:0] m_wdata     ;
    reg [3:0] m_wstrb     ;
    wire m_bvalid    ;
    reg m_bready    ;
    wire [1:0] m_bresp     ;
    reg m_arvalid   ;
    wire m_arready   ;
    reg [31:0] m_araddr    ;
    wire m_rvalid    ;
    wire m_rlast     ;
    reg m_rready    ;
    wire [31:0] m_rdata     ;
    wire [1:0] m_rresp     ;
    wire dram_awvalid;
    reg dram_awready;
    wire [31:0] dram_awaddr ;
    wire dram_wvalid ;
    reg dram_wready ;
    wire [31:0] dram_wdata  ;
    wire [3:0] dram_wstrb  ;
    reg dram_bvalid ;
    wire dram_bready ;
    reg [1:0] dram_bresp  ;
    wire dram_arvalid;
    reg dram_arready;
    wire [31:0] dram_araddr ;
    reg dram_rvalid ;
    wire dram_rready ;
    reg [31:0] dram_rdata  ;
    reg [1:0] dram_rresp  ;
    wire dnn_awvalid ;
    reg dnn_awready ;
    wire [31:0] dnn_awaddr  ;
    wire dnn_wvalid  ;
    reg dnn_wready  ;
    wire [31:0] dnn_wdata   ;
    wire [3:0] dnn_wstrb   ;
    reg dnn_bvalid  ;
    wire dnn_bready  ;
    reg [1:0] dnn_bresp   ;
    wire dnn_arvalid ;
    reg dnn_arready ;
    wire [31:0] dnn_araddr  ;
    reg dnn_rvalid  ;
    wire dnn_rready  ;
    reg [31:0] dnn_rdata   ;
    reg [1:0] dnn_rresp   ;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100MHz
    end

    initial begin
        rst = 1;
        #100;
        rst = 0;
    end
    
    initial begin
        // write dram
        #500;
        m_awaddr = 32'h10000000;
        m_awvalid = 1;
        #100;
        dram_awready = 1;
        wait(m_awready);
        //m_awvalid = 0; //TODO: check axi 

        m_wdata = 32'h12345678;
        m_wvalid = 1;
        #100;
        dram_wready = 1;
        wait(m_wready);
        m_wvalid = 0;

        m_bready = 1;
        dram_bvalid = 1;
        #100;
        wait(m_bvalid);
        dram_bvalid = 0;

        //read dram
        m_araddr = 32'h10000000;
        dram_arready = 1;
        #100;
        m_arvalid = 1;
        wait(m_arready);
        m_arvalid = 0;

        m_rready = 1;
        dram_rvalid = 1;
        dram_rdata = 32'h12345678;
        wait(m_rvalid);
        $display("read data %b from address %h", m_rdata, m_araddr);
    end

    axi_inter u_axi_inter(
        .clk          ( clk          ),
        .rst          ( rst          ),
        .m_awvalid    ( m_awvalid    ),
        .m_awready    ( m_awready    ),
        .m_awaddr     ( m_awaddr     ),
        .m_wvalid     ( m_wvalid     ),
        .m_wready     ( m_wready     ),
        .m_wdata      ( m_wdata      ),
        .m_wstrb      ( m_wstrb      ),
        .m_bvalid     ( m_bvalid     ),
        .m_bready     ( m_bready     ),
        .m_bresp      ( m_bresp      ),
        .m_arvalid    ( m_arvalid    ),
        .m_arready    ( m_arready    ),
        .m_araddr     ( m_araddr     ),
        .m_rvalid     ( m_rvalid     ),
        .m_rlast      ( m_rlast      ),
        .m_rready     ( m_rready     ),
        .m_rdata      ( m_rdata      ),
        .m_rresp      ( m_rresp      ),
        .dram_awvalid ( dram_awvalid ),
        .dram_awready ( dram_awready ),
        .dram_awaddr  ( dram_awaddr  ),
        .dram_wvalid  ( dram_wvalid  ),
        .dram_wready  ( dram_wready  ),
        .dram_wdata   ( dram_wdata   ),
        .dram_wstrb   ( dram_wstrb   ),
        .dram_bvalid  ( dram_bvalid  ),
        .dram_bready  ( dram_bready  ),
        .dram_bresp   ( dram_bresp   ),
        .dram_arvalid ( dram_arvalid ),
        .dram_arready ( dram_arready ),
        .dram_araddr  ( dram_araddr  ),
        .dram_rvalid  ( dram_rvalid  ),
        .dram_rready  ( dram_rready  ),
        .dram_rdata   ( dram_rdata   ),
        .dram_rresp   ( dram_rresp   ),
        .dnn_awvalid  ( dnn_awvalid  ),
        .dnn_awready  ( dnn_awready  ),
        .dnn_awaddr   ( dnn_awaddr   ),
        .dnn_wvalid   ( dnn_wvalid   ),
        .dnn_wready   ( dnn_wready   ),
        .dnn_wdata    ( dnn_wdata    ),
        .dnn_wstrb    ( dnn_wstrb    ),
        .dnn_bvalid   ( dnn_bvalid   ),
        .dnn_bready   ( dnn_bready   ),
        .dnn_bresp    ( dnn_bresp    ),
        .dnn_arvalid  ( dnn_arvalid  ),
        .dnn_arready  ( dnn_arready  ),
        .dnn_araddr   ( dnn_araddr   ),
        .dnn_rvalid   ( dnn_rvalid   ),
        .dnn_rready   ( dnn_rready   ),
        .dnn_rdata    ( dnn_rdata    ),
        .dnn_rresp    ( dnn_rresp    )
);

    initial begin
        #1000000;
        $finish;
    end

endmodule
