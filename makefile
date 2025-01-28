# Makefile for bootable application with ISO generation

# Directories and files
BUILD_DIR = build
ISO_DIR = isodir
GRUB_DIR = $(ISO_DIR)/boot/grub
KERNEL_SRC = kernel.asm
BOOT_SRC = boot.asm
LINKER_SCRIPT = linker.ld
OUTPUT_BIN = $(BUILD_DIR)/tic-toc-toe.bin
ISOBIN = $(ISO_DIR)/boot/tic-toc-toe.bin
ISO_OUTPUT = $(BUILD_DIR)/tic-toc-toe.iso
GRUB_CFG = grub.cfg

# Tools
NASM = nasm
GCC = i686-elf-gcc
QEMU = qemu-system-i386
VERIFY_SCRIPT = sh verify-grub.sh
MKRESCUE = grub-mkrescue

# Compiler and linker options
NASM_FLAGS = -f elf32
GCC_FLAGS = -T $(LINKER_SCRIPT) -o $(OUTPUT_BIN) -ffreestanding -O2 -nostdlib 
GCC_LIBS = -lgcc

all: compile link iso

compile:
	@echo "Compiling kernel and bootloader..."
	mkdir -p $(BUILD_DIR)
	$(NASM) $(NASM_FLAGS) $(KERNEL_SRC) -o $(BUILD_DIR)/kernel.o
	$(NASM) $(NASM_FLAGS) $(BOOT_SRC) -o $(BUILD_DIR)/boot.o

link:
	@echo "Linking kernel and bootloader..."
	$(GCC) $(GCC_FLAGS) $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(GCC_LIBS)

iso: link
	@echo "Creating bootable ISO..."
	mkdir -p $(GRUB_DIR)
	cp $(OUTPUT_BIN) $(ISOBIN)
	cp $(GRUB_CFG) $(GRUB_DIR)/grub.cfg
	$(MKRESCUE) -o $(ISO_OUTPUT) $(ISO_DIR)

direct-test:
	@echo "Running direct test with QEMU..."
	$(QEMU) -kernel $(OUTPUT_BIN)

medium-test:
	@echo "Running medium test with QEMU (ISO)..."
	$(QEMU) -cdrom $(ISO_OUTPUT) -vga std

grub-test:
	@echo "Testing with GRUB boot method..."
	$(QEMU) -drive format=raw,file=$(ISO_OUTPUT)

verify:
	@echo "Verifying bootloader with GRUB verification script..."
	$(VERIFY_SCRIPT)

clean:
	@echo "Cleaning build and ISO files..."
	rm -rf $(BUILD_DIR) $(ISO_DIR)
