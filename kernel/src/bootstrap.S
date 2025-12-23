.extern kmain
.type kmain, @function

.code32
.align 4

.global _start
.type _start, @function
_start:
    call kernel_main
