	org 0x7c00
	use16

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
	
	;; BIOS fills dl with boot drive number before loading bootloader at 0x7c00
	mov byte [boot_drive_bios_id], dl
	;; numbers for disk drives start with 0x80
	cmp dl, byte 080h
	jl .hdd_boot_drive_not_located

	.hdd_boot_drive_located:

	;; check if disk functionality extensions are present (for example, extension for LBA besides CHS addressing)
	mov ah, byte 041h
	mov bx, word [boot_signature]
	int 013h

	;; carry flag is set if there are no extensions
	jc .hdd_extensions_not_available:
	;; if there is no error, bx is set to inverted boot signature
	cmp bx, word 055AAh
	jne .hdd_extensions_not_available:
	;; test will do bitwise AND and set correspondin flags
	test cl, byte 1
	jnz .hdd_extensions_available

	.hdd_extensions_not_available:
	.hdd_boot_drive_not_located:

	.hdd_extensions_available:

	mov si, test_string
	call _panic
	
	;; =====================================================
	
black_hole:
	jmp black_hole

_panic:
	print panic_msg
	print si
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

test_string: db "lkjasd lkajsd", 0
panic_msg:	 db "PANIC:", 0
	
empty_padding:  db 510 - ($ - $$) dup 0
boot_signature:	db 055h, 0AAh
	
