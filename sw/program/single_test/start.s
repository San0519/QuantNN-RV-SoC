.section .text
.global _start

_start:
    # Original stack pointer kept as a comment per editing rule:
    #li sp, 0x10010000   # DRAM 顶部
    li sp, 0xF000FA00   # DRAM uncached alias top (16000 words * 4 bytes)

        # Original C entry kept as a comment per editing rule:
        #call main

        # DNN length = 784
        li t0, 0xF2000000
        li t1, 0x310
        sw t1, 8(t0)

        # DMA reset
        li t0, 0xF3000000
        li t1, 0x4
        sw t1, 0(t0)

        # simple fixed delay without stack activity
        li t2, 64
    delay_reset:
        addi t2, t2, -1
        bnez t2, delay_reset

        # DMA run
        li t1, 0x1
        sw t1, 0(t0)

        li t2, 64
    delay_run:
        addi t2, t2, -1
        bnez t2, delay_run

        # DMA source address = DRAM_BASE
        li t1, 0x10000000
        sw t1, 24(t0)

        # DNN start pulse
        li t0, 0xF2000000
        li t1, 0x1
        sw t1, 0(t0)
        sw zero, 0(t0)

        # Keep start ahead of incoming data for several cycles
        li t2, 32
    delay_start_to_dma:
        addi t2, t2, -1
        bnez t2, delay_start_to_dma

        # DMA length = 784, triggers transfer
        li t0, 0xF3000000
        li t1, 0x310
        sw t1, 40(t0)

loop:
    j loop
    