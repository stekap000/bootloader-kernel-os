#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define SECTOR_SIZE 512
#define EXPECTED_NUMBER_OF_ARGS 3
#define BL1_SIZE_WITHOUT_GPT 0x1c0
#define BL2_LOWER_MAGIC_BYTE 0x41
#define BL2_HIGHER_MAGIC_BYTE 0x54

#define OPEN_ERROR -1
#define READ_ERROR -2
#define WRITE_ERROR -3

#define DEFER_RETURN(v) do { DEFER_VALUE=v; goto DEFER; } while(0)

int main(int argc, char **argv) {
	int DEFER_VALUE = 0;

	unsigned char data[SECTOR_SIZE] = {0};
	int bl2_sector_number = 0;
	
	if(argc < EXPECTED_NUMBER_OF_ARGS) {
		printf("Format <disk> <bootloader>.\n");
		return -1;
	}

	char *disk_file = argv[1];
	char *boot_file = argv[2];
	
	int disk_fd = open(disk_file, O_RDONLY);
	if(disk_fd == -1) {
		printf("Can't open disk image.\n");
		return OPEN_ERROR;
	}
	
	//if(read(disk_fd, data, SECTOR_SIZE) == -1) {
	//	printf("Can't read disk image.\n");
	//	DEFER_RETURN(READ_ERROR);
	//}

	int read_return = 0;
	for(int sector = 0; /*INFINITY*/; ++sector) {
		printf("Checking sector %d.\n", sector);

		read_return = read(disk_fd, data, SECTOR_SIZE);

		if(read_return == -1) {
			printf("Can't read disk data.\n");
			DEFER_RETURN(READ_ERROR);
		}

		// This happens in the case of EOF
		if(read_return == 0) {
			printf("Can't find magic bytes for second stage bootloader.\n");
			DEFER_RETURN(READ_ERROR);
		}

		// These correspond to magic bytes used in bootloader to mark
		// second stage bootloader.
		if(data[0] == BL2_LOWER_MAGIC_BYTE && data[1] == BL2_HIGHER_MAGIC_BYTE) {
			printf("Found magic bytes at sector %d.\n", sector);
			bl2_sector_number = sector;
			break;
		}
	}
	close(disk_fd);

	int boot_fd = open(boot_file, O_RDONLY);
	if(disk_fd == -1) {
		printf("Can't open bootloader.\n");
		return OPEN_ERROR;
	}
	
	// Read first stage bootloader + partition scheme
	if(read(boot_fd, data, SECTOR_SIZE) == -1) {
		printf("Can't read first stage bootloader.\n");
		DEFER_RETURN(READ_ERROR);
	}

	// TODO: Write start address of second stage bootloader to bootloader.

	// Write first stage bootloader to disk (448 (0x1c0) bytes since the rest are for partition
	// scheme, either MBR, or in the case of GPT, portion for backward compatibility).

	disk_fd = open(disk_file, O_WRONLY);
	if(disk_fd == -1) {
		printf("Can't open .\n");
		return OPEN_ERROR;
	}

	if(write(disk_fd, data, BL1_SIZE_WITHOUT_GPT) < BL1_SIZE_WITHOUT_GPT) {
		printf("Couldn't write first stage bootloader to disk.\n");
		DEFER_RETURN(WRITE_ERROR);
	}

	printf("Second stage bootloader starts at sector %d.\n", bl2_sector_number);
	
 DEFER:
	close(disk_fd);
	close(boot_fd);
	return DEFER_VALUE;
}

