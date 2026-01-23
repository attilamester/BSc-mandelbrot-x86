#!/usr/bin/bash

SRC_DIR="./src"
ASM_DIR="$SRC_DIR/asm"
INC_DIR="$SRC_DIR/include"
C_DIR="$SRC_DIR/c"
SHIM_DIR="$SRC_DIR/shims"
BUILD_DIR="./build"
BIN_DIR="./bin"

export PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig
CFLAGS="-m32 -O2 -g -fno-omit-frame-pointer -mstackrealign"

mkdir -p "$BUILD_DIR" "$BIN_DIR"

nasm -f elf32 -g -F dwarf "$ASM_DIR/mandelbrot.asm" -I"$INC_DIR" -o "$BUILD_DIR/mandelbrot.o"

nasm -f elf32 -g -F dwarf "$SHIM_DIR/io_shim.asm" -o "$BUILD_DIR/io_shim.o"
gcc $CFLAGS -c "$C_DIR/io.c" -o "$BUILD_DIR/io.o"
ar rcs "$BUILD_DIR/libio.a" "$BUILD_DIR/io_shim.o" "$BUILD_DIR/io.o"

nasm -f elf32 -g -F dwarf "$SHIM_DIR/gfx_shim.asm" -o "$BUILD_DIR/gfx_shim.o"
gcc $CFLAGS -c "$C_DIR/gfx.c" -o "$BUILD_DIR/gfx.o" $(pkg-config --cflags sdl2)
ar rcs "$BUILD_DIR/libgfx.a" "$BUILD_DIR/gfx_shim.o" "$BUILD_DIR/gfx.o"

nasm -f elf32 -g -F dwarf "$SHIM_DIR/util_shim.asm" -o "$BUILD_DIR/util_shim.o"
gcc $CFLAGS -c "$C_DIR/util.c" -o "$BUILD_DIR/util.o"
ar rcs "$BUILD_DIR/libutil.a" "$BUILD_DIR/util_shim.o" "$BUILD_DIR/util.o"

gcc -m32 "$BUILD_DIR/mandelbrot.o" -L"$BUILD_DIR" -lio -lgfx -lutil $(pkg-config --libs sdl2) -o "$BIN_DIR/mandelbrot"