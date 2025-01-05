# Makefile for bootable application

# Directories and files
BUILD_DIR = build
KERNEL_SRC = kernel.asm
BOOT_SRC = boot.asm
LINKER_SCRIPT = linkder.ld
OUTPUT_BIN = tic-toc-toe.bin

# Tools
NASM = nasm
GCC = i686-elf-gcc
QEMU = qemu-system-i386
VERIFY_SCRIPT = sh verify-grub.sh

# Compiler and linker options
NASM_FLAGS = -f elf32
GCC_FLAGS = -T $(LINKER_SCRIPT) -o $(OUTPUT_BIN) -ffreestanding -O2 -nostdlib
GCC_LIBS = -lgcc

all: compile link

compile:
	$(NASM) $(NASM_FLAGS) $(KERNEL_SRC) -o $(BUILD_DIR)/kernel.o
	$(NASM) $(NASM_FLAGS) $(BOOT_SRC) -o $(BUILD_DIR)/boot.o

link:
	$(GCC) $(GCC_FLAGS) $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(GCC_LIBS)

direct-test:
	$(QEMU) -kernel $(OUTPUT_BIN)

medium-test:
	$(QEMU) -cdrom $(OUTPUT_BIN)

verify:
	$(VERIFY_SCRIPT)

clean:
	rm -f $(BUILD_DIR)/*.o $(OUTPUT_BIN)
