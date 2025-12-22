include config.mk
include build/$(ARCH).mk

.PHONY: all run install-headers boot kernel libc libs clean

# Compiler
CC = ${TARGET}-gcc
AS = ${TARGET}-as

# Objects
BOOTLOADER_SRCS = $(wildcard boot/src/*.c)
BOOTLOADER_OBJS = $(patsubst %.c,%.k.o,$(BOOTLOADER_SRCS))

KERNEL_SRCS = $(wildcard kernel/src/*.c)
KERNEL_SRCS += $(wildcard kernel/src/*/*.c)
KERNEL_SRCS += $(wildcard kernel/src/arch/$(ARCH)/*.c)

KERNEL_OBJS = $(patsubst %.c,%.k.o,$(KERNEL_SRCS))

LIBC_SRCS = $(wildcard libc/src/*.c)
LIBC_SRCS += $(wildcard libc/src/*/*.c)

LIBC_OBJS = $(patsubst %.c,%.o,$(LIBC_SRCS))

LIBK_OBJS = $(patsubst %.c,%.k.o,$(LIBC_SRCS))

KERNEL_CFLAGS  = -ffreestanding -O2 -std=gnu11 -g -static -isystem root/usr/include
KERNEL_CFLAGS += -Wall -Wextra -Wno-unused-function -Wno-unused-parameter -Wstrict-prototypes
KERNEL_CFLAGS += -pedantic -Wwrite-strings $(ARCH_KERNEL_CFLAGS)
KERNEL_CFLAGS += -D__KERNEL -DKERNEL_ARCH=$(ARCH)

all: boot kernel libc libs

boot: install-headers $(BOOTLOADER_OBJS)
	@echo 'Building bootloader...'

kernel: boot libk $(KERNEL_OBJS)
	@echo 'Building kernel...'

libc: install-headers# $(LIBC_OBJS)
	@echo 'Building libc...'

libk: install-headers $(LIBK_OBJS)
	@echo 'Building libk...'

%.k.o: %.c
	@$(CC) -c $(KERNEL_CFLAGS) $< -o $@

libs: libc kernel
	@echo 'Building libs...'

install-headers:
	@echo 'Installing headers to root...'

	@mkdir -p root/usr/include

	@rsync -a --delete ./libc/include/ ./root/usr/include/
	@rsync -a --delete ./boot/include/ ./root/usr/include/boot/  
	@rsync -a --delete ./kernel/include/ ./root/usr/include/kernel/

clean:
	@echo 'Cleaning...'
	-@rm -rf $(BOOTLOADER_OBJS)
	-@rm -rf $(KERNEL_OBJS)
	-@rm -rf $(LIBK_OBJS)
	-@rm -rf $(LIBC_OBJS)

run: kernel
	@echo 'Running...'
