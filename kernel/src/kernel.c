#include <boot/boot.h>

void kmain(boot_info* bp) {
    asm volatile("mov $0xAABBCCDD, %eax");

    while(1); 
}
