
LIBC_SRCS = $(wildcard libc/src/*.c)
LIBC_SRCS += $(wildcard libc/src/*/*.c)
LIBC_OBJS = $(patsubst %.c,%.o,$(LIBC_SRCS))
LIBK_OBJS = $(patsubst %.c,%.libk.o,$(LIBC_SRCS))

LIBK_CFLAGS  = -ffreestanding -O2 -std=gnu11 -g -static 
LIBK_CFLAGS += -Wall -Wextra -Wno-unused-function -Wno-unused-parameter -Wstrict-prototypes
LIBK_CFLAGS += -pedantic -Wwrite-strings $(ARCH_KERNEL_CFLAGS)
LIBK_CFLAGS += -D__KERNEL -DKERNEL_ARCH=$(ARCH)

libc: install-headers# $(LIBC_OBJS)
	@echo 'Building libc...'

libk: libk.a install-libk

libk.a: install-headers $(LIBK_OBJS)
	@echo 'Building libk...'
	@$(AR) rcs libc/$@ $(LIBK_OBJS)

install-libk: libk.a
	@echo 'Installing libk...'

	@mkdir -p $(SYSROOT)/usr/lib
	@cp libc/libk.a $(SYSROOT)/usr/lib

%.libk.o: %.c
	@$(CC) -c $(LIBK_CFLAGS) $< -o $@

%.libk.o: %.S
	@$(CC) -c $< -o $@

clean-libc:
	-@rm -rf $(LIBK_OBJS)
	-@rm -rf $(LIBC_OBJS)
	-@rm -rf libc/libk.a
	-@rm -rf libc/libc.a
