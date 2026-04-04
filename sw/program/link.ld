ENTRY(_start)

MEMORY
{
    IROM (rx) : ORIGIN = 0x80000000, LENGTH = 64K
    DRAM (rw) : ORIGIN = 0x10000000, LENGTH = 0xFA00
}

SECTIONS
{
    .text : {
        *(.text*)
    } > IROM

    .rodata : {
        *(.rodata*)
    } > IROM

    .data : {
        *(.data*)
    } > DRAM

    .bss : {
        *(.bss*)
        *(COMMON)
    } > DRAM
}