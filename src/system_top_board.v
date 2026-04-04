`timescale 1ns / 1ps

module system_top_board (
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    output wire        LCD_CLK,
    output wire        LCD_HSYNC,
    output wire        LCD_VSYNC,
    output wire        LCD_DE,
    output wire        LCD_BL,
    output wire        LCD_RST,
    output wire [7:0]  LCD_R,
    output wire [7:0]  LCD_G,
    output wire [7:0]  LCD_B
);

    wire       busy_unused;
    wire       done_unused;
    wire [7:0] class_id_unused;
    wire       result_valid_unused;
    wire       sys_rst_n;

    system_top u_system_top (
        .sys_clk      ( sys_clk           ),
        .sys_rst_n    ( ~sys_rst_n         ),
        .LCD_CLK      ( LCD_CLK           ),
        .LCD_HSYNC    ( LCD_HSYNC         ),
        .LCD_VSYNC    ( LCD_VSYNC         ),
        .LCD_DE       ( LCD_DE            ),
        .LCD_BL       ( LCD_BL            ),
        .LCD_RST      ( LCD_RST           ),
        .LCD_R        ( LCD_R             ),
        .LCD_G        ( LCD_G             ),
        .LCD_B        ( LCD_B             ),
        .busy         ( busy_unused       ),
        .done         ( done_unused       ),
        .class_id     ( class_id_unused   ),
        .result_valid ( result_valid_unused )
    );

endmodule