include config.mk

.PHONY: all run install-headers boot kernel libc libs clean

SYSROOT = ./root

# Compiler
CC = ${TARGET}-gcc --sysroot=$(SYSROOT) -isystem $(SYSROOT)/usr/include
AS = ${TARGET}-as
AR = ${TARGET}-ar

all: boot kernel #libc

# Provides arch-specific stuff
include build/$(ARCH).mk

# Provides boot target
include boot/bootloader.mk

# Provides libc and libk targets
include libc/libc.mk

# Provides kernel target
include kernel/kernel.mk

# Installs all target headers to sysroot
install-headers:
	@echo 'Installing headers to root...'

	@mkdir -p root/usr/include

	@rsync -a --delete ./libc/include/ $(SYSROOT)/usr/include/
	@rsync -a --delete ./boot/include/ $(SYSROOT)/usr/include/boot/  
	@rsync -a --delete ./kernel/include/ $(SYSROOT)/usr/include/kernel/

clean: clean-boot clean-kernel clean-libc

run: kernel
	@echo 'Running...'
