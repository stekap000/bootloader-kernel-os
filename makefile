bootloader:
	make -C bootloader all

util:
	make -C util utils

build:
	make -C build image

all: bootloader util build

clean:
	make -C bootloader clean
	make -C util clean
	make -C build clean
