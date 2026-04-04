`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: 
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


module accel_ctrl_regs(
    input  wire         clk,
    input  wire         rst_n,

    // AXI-Lite interface
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,

    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,

    output reg  [1:0]   s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,

    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,

    output reg  [31:0]  s_axi_rdata,
    output reg  [1:0]   s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,

    // to accelerator
    output wire         start,
    output reg [31:0]   input_addr,
    output reg [31:0]   length,

    // from accelerator
    input  wire         done,
    input  wire [7:0]   result_data,
    input  wire         result_valid
);
    parameter RSLT_NUM = 10; // number of result registers to store

    reg        start_reg;
    reg [31:0] input_addr_reg;
    reg [31:0] length_reg;
    reg        done_reg;
    reg [7:0]  result_regs [0:RSLT_NUM-1]; // array of registers to store results
    reg [3:0]  result_counter;

    //define the internal state machine
    typedef enum reg {
        IDLE = 1'b0,
        RUN = 1'b1
    } state_t;
    state_t c_state, n_state;
    wire start_cmd_write_hit;
    reg  start_cmd_pulse_reg;

    wire busy = (c_state == RUN);
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            c_state <= IDLE;
        end else begin
            c_state <= n_state;
        end
end

    // generate a start pulse
    reg start_reg_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_reg_d <= 0;
        else
            start_reg_d <= start_reg;
    end
    wire start_pulse = start_reg & ~start_reg_d;
    assign start = (c_state == IDLE) & start_cmd_pulse_reg; // hold start for one full cycle after CTRL write-1 commits

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_cmd_pulse_reg <= 0;
        else
            start_cmd_pulse_reg <= start_cmd_write_hit;
    end

    always @(*) begin
        case(c_state)
            IDLE: begin
                if(start_cmd_pulse_reg) begin
                    n_state = RUN;
                end else begin
                    n_state = IDLE;
                end
            end
            RUN: begin
                if(done) begin
                    n_state = IDLE;
                end else begin
                    n_state = RUN;
                end
            end
            default: n_state = IDLE;
        endcase
end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            input_addr <= 0;
            length <= 0;
            result_counter <= 0;
            for (int i = 0; i < RSLT_NUM; i = i + 1) begin
                result_regs[i] <= 0;
            end
        end else begin
            case(c_state)
                IDLE: begin
                    if(start_cmd_pulse_reg) begin
                        input_addr <= input_addr_reg;
                        length <= length_reg;
                        result_counter <= 0; // reset counter for next run
                    end
                end
                RUN: begin
                    if(result_valid && result_counter < RSLT_NUM) begin
                        result_regs[result_counter] <= result_data;
                        result_counter <= result_counter + 1;
                    end
                end
            endcase
        end
end

    //axi
    reg         axi_awready;
    reg         axi_wready;
    reg         axi_bvalid;
    reg [1:0]   axi_bresp;
    reg [31:0]  axi_awaddr;
    reg [31:0]  axi_wdata_reg;
    reg [3:0]   axi_wstrb_reg;
    reg         aw_captured;
    reg         w_captured;

    wire axi_aw_accept;
    wire axi_w_accept;
    wire slv_reg_wren;

    assign axi_aw_accept = (!aw_captured && !axi_bvalid && s_axi_awvalid);
    assign axi_w_accept  = (!w_captured && !axi_bvalid && s_axi_wvalid);
    assign slv_reg_wren  = (aw_captured && w_captured && !axi_bvalid);
    assign start_cmd_write_hit = slv_reg_wren && (axi_awaddr[7:0] == 8'h00) && axi_wstrb_reg[0] && axi_wdata_reg[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awready <= 0;
            axi_awaddr <= 0;
            aw_captured <= 0;
        end else begin
            axi_awready <= axi_aw_accept;
            if (axi_aw_accept) begin
                axi_awaddr <= s_axi_awaddr;
                aw_captured <= 1;
            end else if (slv_reg_wren) begin
                aw_captured <= 0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_wready <= 0;
            axi_wdata_reg <= 0;
            axi_wstrb_reg <= 0;
            w_captured <= 0;
        end else begin
            axi_wready <= axi_w_accept;
            if (axi_w_accept) begin
                axi_wdata_reg <= s_axi_wdata;
                axi_wstrb_reg <= s_axi_wstrb;
                w_captured <= 1;
            end else if (slv_reg_wren) begin
                w_captured <= 0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_reg <= 0;
            input_addr_reg <= 0;
            length_reg <= 0;
            done_reg <= 0;
        end
        else if (done) begin
            done_reg <= 1; // set done bit when accelerator signals done
        end
        else if (slv_reg_wren) begin
            case (axi_awaddr[7:0])
                8'h00: begin 
                    if(start_pulse) start_reg <= 0; // clear start bit on new write
                    else if(axi_wstrb_reg[0]) start_reg <= axi_wdata_reg[0];
                end
                //8'h04: input_addr_reg <= s_axi_wdata;
                8'h04: begin
                    if(axi_wstrb_reg[0]) input_addr_reg[7:0] <= axi_wdata_reg[7:0];
                    if(axi_wstrb_reg[1]) input_addr_reg[15:8] <= axi_wdata_reg[15:8];
                    if(axi_wstrb_reg[2]) input_addr_reg[23:16] <= axi_wdata_reg[23:16];
                    if(axi_wstrb_reg[3]) input_addr_reg[31:24] <= axi_wdata_reg[31:24];
                end
                //8'h08: length_reg <= s_axi_wdata;
                8'h08: begin
                    if(axi_wstrb_reg[0]) length_reg[7:0] <= axi_wdata_reg[7:0];
                    if(axi_wstrb_reg[1]) length_reg[15:8] <= axi_wdata_reg[15:8];
                    if(axi_wstrb_reg[2]) length_reg[23:16] <= axi_wdata_reg[23:16];
                    if(axi_wstrb_reg[3]) length_reg[31:24] <= axi_wdata_reg[31:24];
                end
                //8'h0C: if(s_axi_wdata[0]) done_reg <= 0; // clear done bit on new write
                8'h0C: if(axi_wstrb_reg[0] && axi_wdata_reg[0]) done_reg <= 0; // clear done bit on new write
                default: ;
            endcase
        end
end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_bvalid <= 0;
            axi_bresp <= 2'b00;
        end
        else if (slv_reg_wren) begin
            axi_bvalid <= 1;
            axi_bresp <= 2'b00; // OKAY
        end
        else if (s_axi_bready && axi_bvalid) begin
            axi_bvalid <= 0;
        end
    end

    reg axi_arready;
    reg axi_rvalid;
    reg [1:0] axi_rresp;
    reg [31:0] axi_rdata;
    reg [31:0] axi_araddr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_arready <= 0;
        else if (!axi_arready && s_axi_arvalid)
            axi_arready <= 1;
        else
            axi_arready <= 0;
end

    always @(posedge clk) begin
        if (!rst_n)
            axi_araddr <= 0;
        else if (!axi_arready && s_axi_arvalid)
            axi_araddr <= s_axi_araddr;
end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_rvalid <= 0;
            axi_rresp <= 2'b00;
        end
        else if (axi_arready && s_axi_arvalid && !axi_rvalid) begin
            axi_rvalid <= 1;
            axi_rresp <= 2'b00;
        end
        else if (axi_rvalid && s_axi_rready) begin
            axi_rvalid <= 0;
        end
end

    always @(posedge clk) begin
        if(axi_arready && s_axi_arvalid) begin
            // Original read-data decode kept as a comment per editing rule:
            //case (axi_araddr[7:0])
            case (s_axi_araddr[7:0])
                8'h00: axi_rdata <= {31'b0, start_reg};
                8'h04: axi_rdata <= input_addr_reg;
                8'h08: axi_rdata <= length_reg;
                8'h0C: axi_rdata <= {30'b0, busy, done_reg};
                8'h10: axi_rdata <= {24'b0, result_regs[0]};
                8'h14: axi_rdata <= {24'b0, result_regs[1]};
                8'h18: axi_rdata <= {24'b0, result_regs[2]};
                8'h1C: axi_rdata <= {24'b0, result_regs[3]};
                8'h20: axi_rdata <= {24'b0, result_regs[4]};
                8'h24: axi_rdata <= {24'b0, result_regs[5]};
                8'h28: axi_rdata <= {24'b0, result_regs[6]};
                8'h2C: axi_rdata <= {24'b0, result_regs[7]};
                8'h30: axi_rdata <= {24'b0, result_regs[8]};
                8'h34: axi_rdata <= {24'b0, result_regs[9]};
                default: axi_rdata <= 32'b0;
            endcase
        end
end

    assign s_axi_awready = axi_awready;
    assign s_axi_wready = axi_wready;
    assign s_axi_bvalid = axi_bvalid;
    assign s_axi_bresp = axi_bresp;
    assign s_axi_arready = axi_arready;
    assign s_axi_rvalid = axi_rvalid;
    assign s_axi_rresp = axi_rresp;
    assign s_axi_rdata = axi_rdata;
    
endmodule