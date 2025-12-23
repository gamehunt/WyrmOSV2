KERNEL_SRCS = $(wildcard kernel/src/*.c)
KERNEL_SRCS += $(wildcard kernel/src/*/*.c)
KERNEL_SRCS += $(wildcard kernel/src/arch/$(ARCH)/*.c)

KERNEL_ASM_SRCS += $(wildcard kernel/src/*.S)
KERNEL_ASM_SRCS += $(wildcard kernel/src/*/*.S)
KERNEL_ASM_SRCS += $(wildcard kernel/src/arch/$(ARCH)/*.S)

KERNEL_ASM_OBJS = $(patsubst %.S,%.k.o,$(KERNEL_ASM_SRCS))
KERNEL_OBJS = $(patsubst %.c,%.k.o,$(KERNEL_SRCS)) $(KERNEL_ASM_OBJS)
KERNEL_LINK_SCRIPT = kernel/src/arch/$(ARCH)/link.ld

KERNEL_CFLAGS  = -ffreestanding -O2 -std=gnu11 -g -static 
KERNEL_CFLAGS += -Wall -Wextra -Wno-unused-function -Wno-unused-parameter -Wstrict-prototypes
KERNEL_CFLAGS += -pedantic -Wwrite-strings $(ARCH_KERNEL_CFLAGS)
KERNEL_CFLAGS += -D__KERNEL -DKERNEL_ARCH=$(ARCH)

kernel: install-kernel
wyrm.bin: boot libk $(KERNEL_OBJS) $(KERNEL_LINK_SCRIPT)
	@echo 'Building kernel...'
	@$(CC) -T $(KERNEL_LINK_SCRIPT) -o kernel/$@ $(KERNEL_CFLAGS) $(KERNEL_OBJS) -nostdlib -lk -lgcc

%.k.o: %.c
	@$(CC) -c $(KERNEL_CFLAGS) $< -o $@

%.k.o: %.S
	@$(CC) -c $< -o $@

install-kernel: wyrm.bin
	@mkdir -p $(SYSROOT)/boot
	@cp kernel/wyrm.bin $(SYSROOT)/boot

clean-kernel:
	-@rm -rf $(KERNEL_OBJS)
	-@rm -rf kernel/wyrm.bin
