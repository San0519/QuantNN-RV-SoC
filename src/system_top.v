`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/07 15:17:41
// Design Name: 
// Module Name: system_top
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


module system_top (
    // system clock and reset
    input  wire        sys_clk,      // main clock
    input  wire        sys_rst_n,    // active low reset

    output wire        LCD_CLK,
    output wire        LCD_HSYNC,
    output wire        LCD_VSYNC,
    output wire        LCD_DE,
    output wire        LCD_BL,
    output wire        LCD_RST,
    output wire [7:0]  LCD_R,
    output wire [7:0]  LCD_G,
    output wire [7:0]  LCD_B,

    // image input interface
    //input  wire [7:0]  img_data,     // 8-bit grayscale pixel
    //input  wire        img_valid,    // valid signal
    //input  wire        img_last,     // last signal

    // control signal
    //input  wire        start,        // start signal
    output wire        busy,         // processing signal
    output wire        done,         // done signal

    // result output interface
    output wire [7:0]  class_id,     // 7-bit class id
    output wire        result_valid // valid signal
);


    wire clk_100m;
    wire rst_n;

    //wire [7:0]  m_axis_0_tdata ;
    wire        m_axis_0_tready;
    //wire        m_axis_0_tvalid;
    //wire [7:0]  s_axis_0_tdata ;
    //wire        s_axis_0_tready;
    //wire        s_axis_0_tvalid;

    wire         externalInterrupt;
    wire         timerInterrupt   ;
    wire         softwareInterrupt;
    wire         start            ;
    wire [31:0]  input_addr       ;
    wire [31:0]  length           ;
    wire         done             ;
    //wire [ 7:0]  result_data      ;
    //wire         result_valid     ;

    wire [ 7:0]  mm2s_tdata ;
    wire         mm2s_tvalid;
    wire         mm2s_tready;


    //tie-offs
    //assign result_data = m_axis_0_tdata;
    //assign result_valid = m_axis_0_tvalid;
    assign m_axis_0_tready = 1'b1;
    assign externalInterrupt = 1'b0;
    assign timerInterrupt = 1'b0;
    assign softwareInterrupt = 1'b0;
    

    clk_rst_gen u_clk_rst_gen(
    .sys_clk   ( sys_clk    ),
    .sys_rst_n ( ~sys_rst_n ),  //high active reset for clk_gen
    .clk_100m  ( clk_100m   ),
    .rst_n     ( rst_n      )
);

    riscv_soc u_riscv_soc(
    .clk                ( clk_100m           ),
    .rst                ( ~rst_n             ),
    .externalInterrupt  ( externalInterrupt  ),
    .timerInterrupt     ( timerInterrupt     ),
    .softwareInterrupt  ( softwareInterrupt  ),
    .start              ( start              ),
    .input_addr         ( input_addr         ),
    .length             ( length             ),
    .done               ( done               ),
    //.result_data        ( result_data        ), //leave open, do not write back
    .result_data        (                    ),
    //.result_valid       ( result_valid       ),
    .result_valid       (                    ),
    .m_axis_mm2s_tdata  ( mm2s_tdata         ),
    .m_axis_mm2s_tvalid ( mm2s_tvalid        ),
    .m_axis_mm2s_tready ( mm2s_tready        )
);


    dnn_accel u_dnn_accel(
    .ap_clk          ( clk_100m        ),
    .ap_rst_n        ( rst_n           ),
    .m_axis_0_tdata  ( class_id        ),
    .m_axis_0_tready ( m_axis_0_tready ),
    .m_axis_0_tvalid ( result_valid    ),
    .s_axis_0_tdata  ( mm2s_tdata      ),
    .s_axis_0_tready ( mm2s_tready     ),
    .s_axis_0_tvalid ( mm2s_tvalid     ),
    .done            ( done            ),
    .busy            ( busy            ),
    .start           ( start           )
);

    out_ctrl u_out_ctrl(
    .clk         ( clk_100m     ),
    .rst_n       ( rst_n        ),
    .busy        ( busy         ),
    .done        ( done         ),
    .result_valid( result_valid ),
    .class_id    ( class_id     ),
    .lcd_clk     ( LCD_CLK      ),
    .lcd_hsync   ( LCD_HSYNC    ),
    .lcd_vsync   ( LCD_VSYNC    ),
    .lcd_de      ( LCD_DE       ),
    .lcd_r       ( LCD_R        ),
    .lcd_g       ( LCD_G        ),
    .lcd_b       ( LCD_B        ),
    .lcd_bl      ( LCD_BL       ),
    .lcd_rst     ( LCD_RST      )
);





endmodule
