`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 21:41:05
// Design Name: 
// Module Name: out_ctrl
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


module out_ctrl(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        busy,
    input  wire        done,
    input  wire        result_valid,
    input  wire [7:0]  class_id,
    output wire        lcd_clk,
    output wire        lcd_hsync,
    output wire        lcd_vsync,
    output wire        lcd_de,
    output wire [7:0]  lcd_r,
    output wire [7:0]  lcd_g,
    output wire [7:0]  lcd_b,
    output wire        lcd_bl,
    output wire        lcd_rst
    );

    localparam H_SYNC   = 11'd1;
    localparam H_BACK   = 11'd43;
    localparam H_ACTIVE = 11'd480;
    localparam H_FRONT  = 11'd8;
    localparam H_TOTAL  = H_SYNC + H_BACK + H_ACTIVE + H_FRONT;

    localparam V_SYNC   = 10'd1;
    localparam V_BACK   = 10'd12;
    localparam V_ACTIVE = 10'd272;
    localparam V_FRONT  = 10'd4;
    localparam V_TOTAL  = V_SYNC + V_BACK + V_ACTIVE + V_FRONT;

    localparam DIGIT_X0 = 11'd170;
    localparam DIGIT_Y0 = 10'd36;
    localparam DIGIT_W  = 11'd140;
    localparam DIGIT_H  = 10'd152;
    localparam SEG_T    = 11'd16;
    localparam SEG_VH   = 10'd52;
    localparam BAR_X    = 11'd32;
    localparam BAR_Y    = 10'd228;
    localparam BAR_W    = 11'd416;
    localparam BAR_H    = 10'd20;

    reg [3:0]  pix_div;
    reg [10:0] h_cnt;
    reg [9:0]  v_cnt;
    reg [7:0]  latched_class;
    reg        latched_valid;
    reg [6:0]  result_count;
    reg [22:0] flash_cnt;
    reg [7:0]  pixel_r;
    reg [7:0]  pixel_g;
    reg [7:0]  pixel_b;

    wire pixel_tick;
    wire active_area;
    wire [10:0] act_x;
    wire [9:0]  act_y;
    wire [6:0]  digit_seg;
    wire        seg_a;
    wire        seg_b;
    wire        seg_c;
    wire        seg_d;
    wire        seg_e;
    wire        seg_f;
    wire        seg_g;
    wire        digit_on;
    wire        progress_on;
    wire        progress_fill;
    wire        border_on;

    function [6:0] seven_seg;
        input [3:0] value;
        begin
            case (value)
                4'h0: seven_seg = 7'b1111110;
                4'h1: seven_seg = 7'b0110000;
                4'h2: seven_seg = 7'b1101101;
                4'h3: seven_seg = 7'b1111001;
                4'h4: seven_seg = 7'b0110011;
                4'h5: seven_seg = 7'b1011011;
                4'h6: seven_seg = 7'b1011111;
                4'h7: seven_seg = 7'b1110000;
                4'h8: seven_seg = 7'b1111111;
                4'h9: seven_seg = 7'b1111011;
                4'hA: seven_seg = 7'b1110111;
                4'hB: seven_seg = 7'b0011111;
                4'hC: seven_seg = 7'b1001110;
                4'hD: seven_seg = 7'b0111101;
                4'hE: seven_seg = 7'b1001111;
                default: seven_seg = 7'b1000111;
            endcase
        end
    endfunction

    assign pixel_tick = (pix_div == 4'd9);
    assign lcd_clk = (pix_div >= 4'd5);

    assign lcd_hsync = (h_cnt < H_SYNC) ? 1'b0 : 1'b1;
    assign lcd_vsync = (v_cnt < V_SYNC) ? 1'b0 : 1'b1;
    assign active_area = (h_cnt >= (H_SYNC + H_BACK)) &&
                         (h_cnt <  (H_SYNC + H_BACK + H_ACTIVE)) &&
                         (v_cnt >= (V_SYNC + V_BACK)) &&
                         (v_cnt <  (V_SYNC + V_BACK + V_ACTIVE));
    assign lcd_de = active_area;
    assign act_x = h_cnt - (H_SYNC + H_BACK);
    assign act_y = v_cnt - (V_SYNC + V_BACK);

    assign digit_seg = seven_seg(latched_class[3:0]);
    assign seg_a = digit_seg[6] &&
                   (act_x >= (DIGIT_X0 + SEG_T)) && (act_x < (DIGIT_X0 + DIGIT_W - SEG_T)) &&
                   (act_y >= DIGIT_Y0) && (act_y < (DIGIT_Y0 + SEG_T));
    assign seg_b = digit_seg[5] &&
                   (act_x >= (DIGIT_X0 + DIGIT_W - SEG_T)) && (act_x < (DIGIT_X0 + DIGIT_W)) &&
                   (act_y >= (DIGIT_Y0 + SEG_T)) && (act_y < (DIGIT_Y0 + SEG_T + SEG_VH));
    assign seg_c = digit_seg[4] &&
                   (act_x >= (DIGIT_X0 + DIGIT_W - SEG_T)) && (act_x < (DIGIT_X0 + DIGIT_W)) &&
                   (act_y >= (DIGIT_Y0 + DIGIT_H - SEG_T - SEG_VH)) && (act_y < (DIGIT_Y0 + DIGIT_H - SEG_T));
    assign seg_d = digit_seg[3] &&
                   (act_x >= (DIGIT_X0 + SEG_T)) && (act_x < (DIGIT_X0 + DIGIT_W - SEG_T)) &&
                   (act_y >= (DIGIT_Y0 + DIGIT_H - SEG_T)) && (act_y < (DIGIT_Y0 + DIGIT_H));
    assign seg_e = digit_seg[2] &&
                   (act_x >= DIGIT_X0) && (act_x < (DIGIT_X0 + SEG_T)) &&
                   (act_y >= (DIGIT_Y0 + DIGIT_H - SEG_T - SEG_VH)) && (act_y < (DIGIT_Y0 + DIGIT_H - SEG_T));
    assign seg_f = digit_seg[1] &&
                   (act_x >= DIGIT_X0) && (act_x < (DIGIT_X0 + SEG_T)) &&
                   (act_y >= (DIGIT_Y0 + SEG_T)) && (act_y < (DIGIT_Y0 + SEG_T + SEG_VH));
    assign seg_g = digit_seg[0] &&
                   (act_x >= (DIGIT_X0 + SEG_T)) && (act_x < (DIGIT_X0 + DIGIT_W - SEG_T)) &&
                   (act_y >= (DIGIT_Y0 + (DIGIT_H >> 1) - (SEG_T >> 1))) && (act_y < (DIGIT_Y0 + (DIGIT_H >> 1) + (SEG_T >> 1)));

    assign digit_on = seg_a || seg_b || seg_c || seg_d || seg_e || seg_f || seg_g;
    assign progress_on = (act_x >= BAR_X) && (act_x < (BAR_X + BAR_W)) &&
                         (act_y >= BAR_Y) && (act_y < (BAR_Y + BAR_H));
    assign progress_fill = (((act_x - BAR_X) << 6) < (result_count * BAR_W));
    assign border_on = ((act_x >= 11'd20) && (act_x < 11'd460) && (act_y >= 10'd20) && (act_y < 10'd200)) &&
                       (((act_x < 11'd24) || (act_x >= 11'd456)) || ((act_y < 10'd24) || (act_y >= 10'd196)));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pix_div <= 4'd0;
        end else if (pix_div == 4'd9) begin
            pix_div <= 4'd0;
        end else begin
            pix_div <= pix_div + 4'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 11'd0;
            v_cnt <= 10'd0;
        end else if (pixel_tick) begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 11'd0;
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= 10'd0;
                else
                    v_cnt <= v_cnt + 10'd1;
            end else begin
                h_cnt <= h_cnt + 11'd1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched_class <= 8'd0;
            latched_valid <= 1'b0;
            result_count <= 7'd0;
            flash_cnt <= 23'd0;
        end else begin
            if (result_valid) begin
                latched_class <= class_id;
                latched_valid <= 1'b1;
                if (result_count != 7'd64)
                    result_count <= result_count + 7'd1;
                // Original short highlight kept as a comment per editing rule:
                //flash_cnt <= 23'd5_000_000;
                flash_cnt <= 23'd20_000_000;
            end else if (flash_cnt != 23'd0) begin
                flash_cnt <= flash_cnt - 23'd1;
            end
        end
    end

    always @(*) begin
        pixel_r = 8'h00;
        pixel_g = 8'h00;
        pixel_b = 8'h00;

        if (active_area) begin
            if (!latched_valid) begin
                pixel_r = 8'h10;
                pixel_g = 8'h10;
                pixel_b = 8'h18;
            end else if (flash_cnt != 23'd0) begin
                pixel_r = 8'h10;
                pixel_g = 8'h34;
                pixel_b = 8'h10;
            end else if (busy) begin
                pixel_r = 8'h08;
                pixel_g = 8'h10;
                pixel_b = 8'h30;
            end else if (done) begin
                pixel_r = 8'h08;
                pixel_g = 8'h18;
                pixel_b = 8'h08;
            end else begin
                pixel_r = 8'h12;
                pixel_g = 8'h12;
                pixel_b = 8'h12;
            end

            if (border_on) begin
                pixel_r = 8'h20;
                pixel_g = 8'h20;
                pixel_b = 8'h20;
            end

            if (digit_on && latched_valid) begin
                pixel_r = 8'hff;
                pixel_g = 8'hd0;
                pixel_b = 8'h30;
            end

            if (progress_on) begin
                if (progress_fill) begin
                    pixel_r = 8'h30;
                    pixel_g = 8'hd8;
                    pixel_b = 8'h60;
                end else begin
                    pixel_r = 8'h20;
                    pixel_g = 8'h20;
                    pixel_b = 8'h24;
                end
            end
        end
    end

    assign lcd_r = active_area ? pixel_r : 8'h00;
    assign lcd_g = active_area ? pixel_g : 8'h00;
    assign lcd_b = active_area ? pixel_b : 8'h00;
    assign lcd_bl = 1'b1;
    assign lcd_rst = rst_n;
endmodule
