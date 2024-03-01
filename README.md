# bootloader-kernel-os
Attempt at writing bootloader, kernel and os, after having written simple bootloader and kernel previously.
Bootloader will first be written by relying on BIOS interrupts (later, UEFI might be considered).
Bochs is used in initial stages as emulator where code is mounter on emulated 1.44MB floppy disk since it
does not require any additional setup (like partitioning).