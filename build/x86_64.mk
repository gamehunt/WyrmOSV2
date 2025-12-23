TARGET=x86_64-elf

ARCH_KERNEL_CFLAGS  = -mno-red-zone -fno-omit-frame-pointer -mfsgsbase -fPIE
ARCH_KERNEL_CFLAGS += -mgeneral-regs-only -z max-page-size=0x1000 -nostdlib

image: system
	sudo bash util/sync_image.sh

run: image
	@echo 'Running...'
	@qemu-system-x86_64 \
		-m 4G \
		-bios /usr/share/ovmf/x64/OVMF.4m.fd \
		-drive format=raw,file=disk.img \
		-display gtk
