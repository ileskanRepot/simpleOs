org 0x7C00
bits 16

%define ENDL 0x00, 0x0A

start:
	jmp main

; Print character to screen
; Params:
;		ds:si points to string
;
puts:
	; Save registers we will modify
	push si
	push ax
	push bx

.loop:
	lodsb 					; Loads next character in al
	or al, al 			; verify if al next charactes is null?
	jz .done
	
	mov ah, 0x0E		; Call bios interrupt
	mov bh, 0
	int 0x10
	
	jmp .loop

.done:
	pop bx
	pop ax
	pop si
	ret

main:
	; Setup data segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; Setup stack
	mov ss, ax
	mov sp, 0x7C00

	; Print message
	mov si, msg_hello
	call puts

	hlt

.halt:
	jmp .halt

msg_hello: db 'Hello World!' , ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
