boot: install-boot

hatch.efi: headers
	$(MAKE) -C boot

install-boot: hatch.efi
	@mkdir -p $(SYSROOT)/boot/EFI/BOOT
	@cp boot/hatch.efi $(SYSROOT)/boot/EFI/BOOT/BOOTX64.EFI

clean-boot:
	$(MAKE) -C boot clean
