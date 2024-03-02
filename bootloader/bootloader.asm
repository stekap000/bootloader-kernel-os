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

	mov si, test_string
	call _panic
	
;; =====================================================
	
black_hole:
	jmp black_hole

_panic:
	print panic_msg
	print si
	xor ax, ax
	int 16h
	;; jump to cpu reset vector
	;; because of real mode addresing, these two are equivalent
	;; BIOS code is also mapped somewhere in the last segment, so this will also reload BIOS
	;; which will then look for bootable disk and load our program at 0x7c00, and cycle continues
	jmp far 0ffffh:0
	;; jmp far 0f000h:0fff0h

;; expects present address in si
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

test_string: db "lkjasd lkajsd", 0
panic_msg:	 db "PANIC:", 0
	
boot_drive:	 db 0
	
dummy:  	db 510 - ($ - $$) dup 0
boot_mark:	db 55h, 0AAh
	
