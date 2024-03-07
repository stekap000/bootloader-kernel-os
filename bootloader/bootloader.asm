	org 0x7c00
	use16

;	Offset	Size	Description
; 0	1	size of packet (16 bytes)
; 1	1	always 0
; 2	2	number of sectors to transfer (max 127 on some BIOSes)
; 4	4	transfer buffer (16 bit segment:16 bit offset) (see note #1)
; 8	4	lower 32-bits of 48-bit starting LBA
;12	4	upper 16-bits of 48-bit starting LBA

	;; LBA packet
	lba_packet equ 0x7e00
	virtual at lba_packet
	lba_packet.size		: dw ?
	lba_packet.count	: dw ?
	lba_packet.offset	: dw ?
	lba_packet.segment	: dw ?
	lba_packet.sector0	: dw ?
	lba_packet.sector1	: dw ?
	lba_packet.sector2	: dw ?
	lba_packet.sector3	: dw ?
	end virtual

	macro print str {
		if ~ str eq si
		push si
		mov si, str
		end if
	
		call _print
	
		if ~str eq si
		pop si
		end if
	}

	;; =====================================================

	.start:

	;; clear interrupt and direction flags since there is no guarantee that they are cleared
	cli
	cld
	xor ax, ax
	mov es, ax
	;; setup stack for real mode
	mov ss, ax
	mov sp, 0600h
	mov bp, 0600h
	push cs
	pop ds
	
	;; BIOS fills dl with boot drive number before loading bootloader at 0x7c00
	mov byte [boot_drive_bios_id], dl
	;; numbers for disk drives start with 0x80
	cmp dl, byte 080h
	jl .hdd_boot_drive_not_found

	.hdd_boot_drive_found:

	;; check if disk functionality extensions are present (for example, extension for LBA besides CHS addressing)
	;; this interrupt is part of extended BIOS
	mov ah, byte 041h
	mov bx, word [boot_signature]
	int 013h

	;; carry flag is set if there are no extensions
	jc .hdd_extensions_not_available
	;; if there is no error, bx is set to inverted boot signature
	cmp bx, word 055AAh
	jne .hdd_extensions_not_available
	;; test will do bitwise AND and set corresponding flags
	;; test if LBA is available (packet structure)
	test cl, byte 1
	jnz .hdd_extensions_available

	.hdd_extensions_not_available:
	mov si, hdd_no_ext_error
	jmp _panic
	
	.hdd_boot_drive_not_found:
	mov si, hdd_not_found_error
	jmp _panic

	.hdd_extensions_available:
	mov word [lba_packet.size], 16
	mov word [lba_packet.count], 1
	mov word [lba_packet.segment], 080h
	mov word [lba_packet.offset], 0
	mov word [lba_packet.sector0], 0
	mov word [lba_packet.sector1], 2
	mov word [lba_packet.sector2], 0
	mov word [lba_packet.sector3], 0

	;; extended read allows usage of LBA
	mov ah, 042h
	mov si, lba_packet
	int 013h
	jnc .read_success
	mov si, sector_read_error
	jmp _panic

	.read_success:
	;; we need to validate that what we read is the second stage bootloader
	mov bx, [magic_bytes]
	mov cx, word [0800h]
	cmp cx, bx
	jne .bad_magic
	mov ax, 0802h
	jmp ax

	.bad_magic:
	mov si, invalid_magic_error
	jmp _panic

	;; =====================================================
	
black_hole:
	jmp black_hole

;; expects address in si, called with jmp
_panic:
	print panic_header
	print si
	;; wait for keyboard input
	xor ax, ax
	int 016h
	;; jump to cpu reset vector
	;; because of real mode addresing, these two are equivalent
	;; BIOS code is also mapped somewhere in the last segment, so this will also reload BIOS
	;; which will then look for bootable disk and load our program at 0x7c00, and cycle continues
	jmp far 0ffffh:0
	;; jmp far 0f000h:0fff0h

;; expects string address in si
_print:
	lodsb
	or al, al
	jz .end
	mov ah, byte 0Eh
	mov bx, word 03h
	int 010h
	jmp _print
	.end:
	ret

;; this will hold boot drive number that BIOS loads into dl before loading bootloader
boot_drive_bios_id:	 db 0
magic_bytes:	     dw 05441h
	
panic_header:		 db "PANIC: ", 0
hdd_no_ext_error:	 db "ERROR::HDD::EXT::NOT_AVAILABLE", 0
hdd_not_found_error: db "ERROR::HDD::NOT_FOUND", 0
sector_read_error:	 db "ERROR::HDD::SECTOR::READ", 0
invalid_magic_error: db "ERROR::BOOT2::MAGIC", 0
	
empty_padding:		 db 510 - ($ - $$) dup 0
boot_signature:	     db 055h, 0AAh
	
