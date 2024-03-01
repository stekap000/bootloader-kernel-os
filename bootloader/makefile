BUILD_DIR = ../build

all: bootloader.bin

bootloader.bin:
	fasm bootloader.asm bootloader.bin
	mv bootloader.bin $(BUILD_DIR)/bootloader.bin

clean:
	rm -f $(BUILD_DIR)/bootloader.asm

