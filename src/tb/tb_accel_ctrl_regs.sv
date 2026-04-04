`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2026 02:04:04 PM
// Design Name: 
// Module Name: tb_accel_ctrl_regs
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

module tb_accel_ctrl_regs;

    // Clock & Reset
    reg clk;
    reg rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // AXI-Lite Signals
    reg  [31:0] s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;

    reg  [31:0] s_axi_wdata;
    reg  [3:0]  s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;

    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;

    reg  [31:0] s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;

    // DUT side signals
    wire        start;
    wire [31:0] input_addr;
    wire [31:0] length;

    reg         done;
    reg  [7:0]  result_data;
    reg         result_valid;

    // Instantiate DUT
    accel_ctrl_regs dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .start(start),
        .input_addr(input_addr),
        .length(length),

        .done(done),
        .result_data(result_data),
        .result_valid(result_valid)
    );

    // AXI Write Task
    task axi_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1;
        s_axi_wdata   <= data;
        s_axi_wvalid  <= 1;
        s_axi_wstrb   <= 4'b1111;
        s_axi_bready  <= 1;

        wait(s_axi_awready && s_axi_wready);
        @(posedge clk);

        s_axi_awvalid <= 0;
        s_axi_wvalid  <= 0;

        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 0;
    end
    endtask

    // AXI Read Task
    task axi_read(input [31:0] addr, output [31:0] data);
    begin
        @(posedge clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1;
        s_axi_rready  <= 1;

        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 0;

        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 0;
    end
    endtask

    initial begin
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wvalid  = 0;
        s_axi_wstrb   = 0;
        s_axi_bready  = 0;

        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        done          = 0;
        result_data   = 0;
        result_valid  = 0;
    end

    reg [31:0] rdata;

    initial begin
        wait(rst_n);

        // Configure accelerator
        axi_write(32'h04, 32'hA000_0000); // input_addr
        axi_write(32'h08, 32'd16);        // length

        // Trigger start
        axi_write(32'h00, 32'h1);
        $display("Set High to START_REG");
        axi_write(32'h00, 32'h0);
        $display("Set Low to START_REG");

        // Check start pulse
        @(posedge clk);
        if (start !== 1)
            $error("START pulse NOT generated!");

        // Simulate accelerator output
        repeat (10) begin
            @(posedge clk);
            result_valid <= 1;
            result_data  <= $random;
        end

        @(posedge clk);
        result_valid <= 0;


        // Trigger done
        @(posedge clk);
        done <= 1;
        @(posedge clk);
        done <= 0;

        // Read status register
        axi_read(32'h0C, rdata);
        $display("STATUS = %h", rdata);

        if (rdata[0] != 1)
            $error("DONE bit not set!");

        // Read result registers
        for (int i = 0; i < 10; i++) begin
            axi_read(32'h10 + i*4, rdata);
            $display("RESULT[%0d] = %h", i, rdata);
        end

        // Clear done
        axi_write(32'h0C, 32'h1);

        axi_read(32'h0C, rdata);
        if (rdata[0] != 0)
            $error("DONE clear failed!");

        $display("TEST PASSED");
        #100;
        $finish;
    end

endmodule
