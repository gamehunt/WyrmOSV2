#!/bin/bash

TARGET=x86_64-elf
BINUTILS=2.42
GCC=14.1.0
PREFIX=$(realpath "./prefix")
PATH=${PREFIX}/bin:${PATH}

function setup_binutils {
	if hash $TARGET-as >/dev/null 2>&1  
	then
		echo "Skipping binutils, already built"
		return
	fi

	mkdir -p binutils/build
	cd binutils
	
	if [ ! -f binutils-${BINUTILS}.tar.xz ]; then
		wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS}.tar.xz
		tar xf binutils-${BINUTILS}.tar.xz
	fi

	cd build
	../binutils-${BINUTILS}/configure --target=$TARGET --prefix=${PREFIX} --with-sysroot --disable-nls --disable-werror
	make
	make install
	cd ../..
}

function setup_gcc {
	if hash $TARGET-gcc >/dev/null 2>&1 
	then
		echo "Skipping gcc, already built"
		return
	fi

	mkdir -p gcc/build
	cd gcc
	
	if [ ! -f gcc-${GCC}.tar.xz ]; then
		wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC}/gcc-${GCC}.tar.xz
		tar xf gcc-${GCC}.tar.xz
	fi

	#compile libgcc without red zone
	if [ ! -f gcc-${GCC}/gcc/config/i386/t-x86_64-elf ]; then
		cp ../../t-x86_64-elf gcc-${GCC}/gcc/config/i386/
		sed -i '/x86_64-\*-elf\*)/a\'$'\n\t''tmake_file="${tmake_file} i386/t-x86_64-elf"' gcc-${GCC}/gcc/config.gcc
	fi

	cd build
	../gcc-${GCC}/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx
	make -j 8 all-gcc
	make all-target-libgcc
    make all-target-libstdc++-v3
	make install-gcc
	make install-target-libgcc
    make install-target-libstdc++-v3
	cd ../..
}

mkdir -p prefix

setup_binutils
setup_gcc
