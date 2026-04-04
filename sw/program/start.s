.section .text
.global _start

_start:
    li sp, 0xF000FA00   # DRAM uncached alias top (16000 words * 4 bytes)
        # Continuous 64-image classification flow
        # DRAM image region:   0x10000000 .. 0x1000C3FF   (64 * 784 bytes)
        # DRAM result region:  0xF000C400 .. 0xF000C4FF   (64 * 4 bytes)
        li t0, 0xF2000000      # DNN control base (uncached alias)
        li t1, 0xF3000000      # DMA control base (uncached alias)
        li t2, 0x10000000      # current DMA source address (physical DRAM base)
        li t3, 0xF000C400      # result buffer base (uncached DRAM alias)
        li t4, 64              # number of images in current subset

        # DNN length = 784 bytes per image
        li t5, 0x310
        sw t5, 8(t0)

        # DMA reset once
        li t5, 0x4
        sw t5, 0(t1)
        li t6, 64
    delay_reset_loop:
        addi t6, t6, -1
        bnez t6, delay_reset_loop

        # DMA run once
        li t5, 0x1
        sw t5, 0(t1)
        li t6, 64
    delay_run_loop:
        addi t6, t6, -1
        bnez t6, delay_run_loop

    classify_next_image:
        beqz t4, loop

        # clear previous done flag before starting a new sample
        li t5, 0x1
        sw t5, 12(t0)

        # set DMA source address to current image base
        sw t2, 24(t1)

        # pulse DNN start first
        sw t5, 0(t0)
        sw zero, 0(t0)

        # keep start ahead of DMA payload for several cycles
        li t6, 32
    delay_start_to_dma_loop:
        addi t6, t6, -1
        bnez t6, delay_start_to_dma_loop

        # trigger DMA transfer of one image
        li t5, 0x310
        sw t5, 40(t1)

    wait_done_loop:
        lw t5, 12(t0)
        andi t5, t5, 0x1
        beqz t5, wait_done_loop

        # store classification result[0] as one 32-bit word
        lw t5, 16(t0)
        sw t5, 0(t3)

        # Hold each final result on the LCD long enough to observe on hardware.
        # At 100 MHz, 20,000,000 cycles is about 200 ms per sample.
        li t6, 20000000
    delay_between_samples_loop:
        addi t6, t6, -1
        bnez t6, delay_between_samples_loop

        # advance to next image/result slot
        addi t2, t2, 0x310
        addi t3, t3, 4
        addi t4, t4, -1
        j classify_next_image

loop:
    j loop
    