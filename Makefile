include config.mk
include build/$(ARCH).mk

.PHONY: all run install-headers boot kernel libc libs clean

SYSROOT = ./root

# Compiler
CC = ${TARGET}-gcc --sysroot=$(SYSROOT) -isystem $(SYSROOT)/usr/include
AS = ${TARGET}-as
AR = ${TARGET}-ar

# Objects
BOOTLOADER_SRCS = $(wildcard boot/src/*.c)
BOOTLOADER_OBJS = $(patsubst %.c,%.k.o,$(BOOTLOADER_SRCS))

KERNEL_SRCS = $(wildcard kernel/src/*.c)
KERNEL_SRCS += $(wildcard kernel/src/*/*.c)
KERNEL_SRCS += $(wildcard kernel/src/arch/$(ARCH)/*.c)

KERNEL_OBJS = $(patsubst %.c,%.k.o,$(KERNEL_SRCS))
KERNEL_LINK_SCRIPT = kernel/src/arch/$(ARCH)/link.ld

LIBC_SRCS = $(wildcard libc/src/*.c)
LIBC_SRCS += $(wildcard libc/src/*/*.c)

LIBC_OBJS = $(patsubst %.c,%.o,$(LIBC_SRCS))

LIBK_OBJS = $(patsubst %.c,%.k.o,$(LIBC_SRCS))

KERNEL_CFLAGS  = -ffreestanding -O2 -std=gnu11 -g -static 
KERNEL_CFLAGS += -Wall -Wextra -Wno-unused-function -Wno-unused-parameter -Wstrict-prototypes
KERNEL_CFLAGS += -pedantic -Wwrite-strings $(ARCH_KERNEL_CFLAGS)
KERNEL_CFLAGS += -D__KERNEL -DKERNEL_ARCH=$(ARCH)

all: boot kernel libc libs

boot: install-headers $(BOOTLOADER_OBJS)
	@echo 'Building bootloader...'

kernel: wyrm.bin

wyrm.bin: boot install-libk $(KERNEL_OBJS) $(KERNEL_LINK_SCRIPT)
	@echo 'Building kernel...'
	@$(CC) -T $(KERNEL_LINK_SCRIPT) -o kernel/$@ $(KERNEL_CFLAGS) $(KERNEL_OBJS) -nostdlib -lk -lgcc

libc: install-headers# $(LIBC_OBJS)
	@echo 'Building libc...'

libk: libk.a
libk.a: install-headers $(LIBK_OBJS)
	@echo 'Building libk...'
	@$(AR) rcs libc/$@ $(LIBK_OBJS)

install-libk: libk
	@echo 'Installing libk...'

	@mkdir -p root/usr/lib
	@cp libc/libk.a ./root/usr/lib

%.k.o: %.c
	@$(CC) -c $(KERNEL_CFLAGS) $< -o $@

libs: libc
	@echo 'Building libs...'

install-headers:
	@echo 'Installing headers to root...'

	@mkdir -p root/usr/include

	@rsync -a --delete ./libc/include/ $(SYSROOT)/usr/include/
	@rsync -a --delete ./boot/include/ $(SYSROOT)/usr/include/boot/  
	@rsync -a --delete ./kernel/include/ $(SYSROOT)/usr/include/kernel/

install-libs: install-libk

clean:
	@echo 'Cleaning...'
	-@rm -rf $(BOOTLOADER_OBJS)
	-@rm -rf $(KERNEL_OBJS)
	-@rm -rf $(LIBK_OBJS)
	-@rm -rf $(LIBC_OBJS)
	-@rm -rf libc/libk.a
	-@rm -rf libc/libc.a
	-@rm -rf kernel/wyrm.bin

run: kernel
	@echo 'Running...'
