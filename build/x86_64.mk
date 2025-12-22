TARGET=x86_64-elf

ARCH_KERNEL_CFLAGS  = -mno-red-zone -fno-omit-frame-pointer -mfsgsbase -fPIE
ARCH_KERNEL_CFLAGS += -mgeneral-regs-only -z max-page-size=0x1000 -nostdlib

