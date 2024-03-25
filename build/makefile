LOOP_DEVICE := $(shell losetup -f)

image:
# Create empty disk image
	dd if=/dev/zero of=disk.img bs=1048576 count=10
# Define GPT and one EFI partition
	printf "g\nn\n\n\n+8M\ni\nt\n1\nw\n" | fdisk disk.img

	losetup -D
	losetup -o 512 -f disk.img
	mkfs.vfat -F 16 -v -n "EFI" ${LOOP_DEVICE}
	mkdir image
	mount -t vfat,fat=16 ${LOOP_DEVICE} image
	mkdir -p image/bios/boot/
	cp second.bin image/bios/boot/
	umount image
	rm -r image
	losetup -D

# Inject first stage bootloader into disk image
#	./inject_bootloader disk.img bootloader.bin
#	mv disk.img ../dist/disk.img

clean:
	losetup -D
	rm -f ../dist/disk.img
# This is for the case that bootloader injection fails and thus 'mv' command does not get executed
	rm -f disk.img
