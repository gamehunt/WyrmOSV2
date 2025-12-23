OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start)

SECTIONS
{
    . = 1M;

    kernel_start = .;

	.text BLOCK(4K) : ALIGN(4K) {
        *(.text .text.*)
    }

    .rodata : {
        *(.rodata .rodata.*)
    }

    .data BLOCK(4K) : ALIGN(4K) {
        *(.data .data.*)
    }

    .bss BLOCK(4K) : ALIGN(4K) {
        *(.bss .bss.*)
        *(COMMON)
    }

    /DISCARD/ : {
        *(.eh_frame*)
        *(.note .note.*)
        *(.interp)
    }

    kernel_end = .;
}
