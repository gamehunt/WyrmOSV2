BOOTLOADER_ASM_SRCS = $(wildcard boot/src/*.S)
BOOTLOADER_SRCS = $(wildcard boot/src/*.c)
BOOTLOADER_ASM_OBJS = $(patsubst %.S,%.b.o,$(BOOTLOADER_ASM_SRCS))
BOOTLOADER_OBJS = $(patsubst %.c,%.b.o,$(BOOTLOADER_SRCS)) $(BOOTLOADER_ASM_OBJS)
BOOTLOADER_LINK_SCRIPT = boot/src/link.ld

%.b.o: %.c
	@$(CC) -c $< -o $@

%.b.o: %.S
	@$(CC) -c $< -o $@

boot: hatch.bin
hatch.bin: install-headers $(BOOTLOADER_OBJS) $(BOOTLOADER_LINK_SCRIPT)
	@echo 'Building bootloader...'

clean-boot:
	-@rm -rf $(BOOTLOADER_OBJS)
	-@rm -rf boot/hatch.bin
