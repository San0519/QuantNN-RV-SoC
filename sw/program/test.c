//#define DRAM_BASE ((volatile int*)0x10000000)
//#define DNN_BASE  ((volatile int*)0x20000000)
//#define DMA_BASE  ((volatile int*)0x30000000)
//#define IROM_BASE ((volatile int*)0x80000000)
#define DRAM_BASE 0x10000000u
// Original cacheable MMIO base definitions kept as comments per editing rule:
//#define DNN_BASE  0x20000000u
//#define DMA_BASE  0x30000000u
#define DNN_BASE  0xF2000000u
#define DMA_BASE  0xF3000000u
#define IROM_BASE 0x80000000u

#define REG32(addr) (*(volatile unsigned int *)(addr))

// DNN regs
//#define REG_START   (*(volatile int*)(DNN_BASE + 0x00))
////#define REG_IN_ADDR (*(volatile int*)(DNN_BASE + 0x04))
//#define REG_LENGTH  (*(volatile int*)(DNN_BASE + 0x08))
//#define REG_DONE    (*(volatile int*)(DNN_BASE + 0x0C))
#define REG_START   REG32(DNN_BASE + 0x00u)
#define REG_LENGTH  REG32(DNN_BASE + 0x08u)
#define REG_STATUS  REG32(DNN_BASE + 0x0Cu)

#define REG_STATUS_DONE_MASK 0x1u
#define REG_STATUS_BUSY_MASK 0x2u

// DMA regs
//#define MM2S_DMACR   (*(volatile int*)(DMA_BASE + 0x00))
//#define MM2S_DMASR   (*(volatile int*)(DMA_BASE + 0x04))
//#define MM2S_SA      (*(volatile int*)(DMA_BASE + 0x18))
//#define MM2S_LENGTH  (*(volatile int*)(DMA_BASE + 0x28))
#define MM2S_DMACR  REG32(DMA_BASE + 0x00u)
#define MM2S_DMASR  REG32(DMA_BASE + 0x04u)
#define MM2S_SA     REG32(DMA_BASE + 0x18u)
#define MM2S_LENGTH REG32(DMA_BASE + 0x28u)

#define MM2S_DMACR_RS_MASK       0x00000001u
#define MM2S_DMACR_RESET_MASK    0x00000004u
#define MM2S_DMASR_HALTED_MASK   0x00000001u

static void delay_cycles(unsigned int cycles) {
    volatile unsigned int count = cycles;

    while (count-- != 0u) {
    }
}

int main() {

    
    REG_LENGTH = 784;   // MNIST size

    // Original DMA start sequence kept as comments per editing rule:
    //MM2S_DMACR = 0x4;   // reset
    //MM2S_DMACR = 0x1;   // run
    //
    //MM2S_SA = DRAM_BASE;  // DRAM中MNIST地址
    //MM2S_LENGTH = 784;     // 触发传输
    //
    //REG_START = 1;
    //REG_START = 0;
    MM2S_DMACR = MM2S_DMACR_RESET_MASK;   // reset
    // Original reset polling kept as a comment per editing rule:
    //while ((MM2S_DMACR & MM2S_DMACR_RESET_MASK) != 0u);
    delay_cycles(64u);

    MM2S_DMACR = MM2S_DMACR_RS_MASK;      // run
    // Original halted polling kept as a comment per editing rule:
    //while ((MM2S_DMASR & MM2S_DMASR_HALTED_MASK) != 0u);
    delay_cycles(64u);

    MM2S_SA = DRAM_BASE;                  // DRAM中MNIST地址

    REG_START = 1;
    REG_START = 0;

    MM2S_LENGTH = 784;                    // 最后写长度，触发传输

    //while (REG_DONE == 0);
    while ((REG_STATUS & REG_STATUS_DONE_MASK) == 0u);

    while (1);

    return 0;
}
//export PATH=/opt/riscv32/bin:$PATH
//riscv32-unknown-elf-gcc     -march=rv32im -mabi=ilp32     -T link.ld     start.s test.c     -nostdlib -nostartfiles     -o test.elf
//riscv32-unknown-elf-objcopy -O binary test.elf test.bin

//usbipd bind -b 1-3
//usbipd attach --wsl -b 1-3