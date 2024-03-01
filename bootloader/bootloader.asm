	use16

	mov ah, 0Eh
	mov al, 'T'
	mov bx, 02h
	int 10h
	
black_hole:
	jmp black_hole

dummy:  	db 510 - ($ - $$) dup 0
boot_flag:	db 55h, 0AAh
	
