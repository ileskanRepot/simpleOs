org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A


; FAT12 header
jmp short start
nop

bdb_oem:										db 'MSWIN4.1' 				; 8 bytes
bdb_bytes_per_sector:				dw 512
bdb_sectors_per_cluster:		db 1
bdb_reserved_sectors:				dw 1
bdb_fat_count:							db 2
bdb_dir_entries_count:			dw 0E0h
bdb_total_sectors:					dw 2880								; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:	db 0F0h								; F0 = 3.5" floppy disk
bdb_secrots_per_fat:				dw 9
bdb_secrots_per_track:			dw 18
bdb_heads:									dw 2
bdb_hidden_sectors:					dd 0
bdb_large_sector_count:			dd 0

; extended boot record
ebr_drive_number:						db 0									; 0x00 = floppy, 0x80 hdd
														db 0									; reserved
ebr_signature:							db 29h
ebr_volume_id:							db 12h, 34h, 56h, 78h	; Serial number, value doesn't matter
ebr_volume_label:						db '           '			; 11 bytes, padded with spaces
ebr_system_id:							db 'FAT12   '					; 8 bytes


; Code goes here


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

	; DO SOMETHING
	; read somethong from floppy disk
	; BIOS should set DL to drive number
	mov [ebr_drive_number], dl

	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read


	; Print message
	mov si, msg_hello
	call puts

	cli
	hlt

; Error handleres
floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 16h																	; Wait for keypress
	jmp 0FFFFh:0														; Jump to beginning of BIOS, should reboot

.halt:
	cli
	jmp .halt


; Disk routines
; Converts LBA address to a CHS address
; Parameters:
;		- ax: LBA address
; Returns:
;		- cx [bits 0-5]: sector number
;		- cx [bits 6-15]: cylinder
;		- dh: head
lba_to_ths:
	push ax
	push dx

	xor dx, dx															; dx = 0
	div word [bdb_secrots_per_track]				; ax = LBA / SectorsPerTrack
																					; dx = LBA % SectorsPerTrack
	inc dx																	; dx = (LBA % SectorsPerTrack + 1) = sector
	mov cx, dx															; cx - sector

	xor dx, dx															; dx = 0
	div word [bdb_heads]										; ax = (LBA / SectorsPerTrack) / Heads = cylinder
																					; dx = (LBA / SectorsPerTrack) % Heads = head
	mov dh, dl															; dl = head
	mov ch, al															; ch = cylinder (lower 8 bits)
	shl ah, 6
	or cl, ah																; put upper 2 bits of cylinder in CL

	pop ax
	pop ax
	mov dl, al
	mov dl, al

	ret


; Reads sectors from a disk
; Parameters:
;		- ax: LBA address
;		- cl: number of sectors rto read (up to 128)
;		- dl: drive number
;		- es:bx: memory address where to store read data
disk_read:
	push ax
	push bx
	push cx
	push dx
	push di

	push cx																	; Temporarily save CX (number of sectors to read)
	call lba_to_ths													; compute chs
	pop cx																	; AL = number of sectors to read

	mov ch, 02h
	mov di, 3

.retry:
	pusha 																	; Save all registers, we don't know what bios modifies
	stc 																		; Set carry flag, some BIOS'es don't set it
	int 13h																	; Carry flag cleared = success
	jmp .done

	popa
	call disk_reset
	dec di
	test di, di
	jnz .retry

.fail:
	; all attemps are exhausted
	jmp floppy_error

.done:
	popa

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret


; Reset disk controller
; Parameters:
;		- dl: drive number
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret


msg_hello: 				db "Hello World!", ENDL, 0
msg_read_failed: 	db "Read From Disk Failed", ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
