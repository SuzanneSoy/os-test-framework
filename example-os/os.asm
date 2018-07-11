[BITS 16]
[ORG 0x7c00]

db "#!/usr/bin/env sh", 0x0a
db ": <<'EOF'", 0x0a
db "GOTO msdos", 0x0a

;;; The #!… above is interpreted as … jnz short 0x7c78 in x86 assembly.
times 0x7c78-0x7c00-($-$$) db 0

;;; Switch to 320x200x256 VGA mode
mov ax, 0x0013
int 10h

;;; Framebuffer address is 0xa000, store it into the fs register (the segment base, in multiples of 16)
push 0xa000
pop fs

;;; Set pixel value (0, then increase at each step below)
xor bl, bl

;;; set register di to 0
xor di,di

;;; Store pixels, display something flashy.
pixel_loop:
	mov byte [fs:di], bl
	inc bl
	inc di
	cmp bl, 255
	je endline
	jmp pixel_loop

endline:
	add di, 65
	xor bl, bl
	mov ax, di
	cmp ax, (320*200)
	je infinite_loop
	jmp pixel_loop

;;; For now, hang until the computer is rebooted.
infinite_loop:
	jmp infinite_loop

;;; Fill the remaining bytes with 0 and write a partition table
times 0x1b8-($-$$) db 0
db "ExOSxx"        ;; 0x1b8 unique disk ID (4-6 bytes? Can be any value)
;;; Partition table entries follow this format:
;;; 1 byte  Bootable flag (0x00 = no, 0x80 = yes)
;;; 3 bytes Start Head Sector Cylinder (8 bits + 6 bits + 10 bits)
;;; 1 byte  Partition type (0x01 = FAT12)
;;; 3 bytes End Head Sector Cylinder (8 bits + 6 bits + 10 bits)
;;; 4 bytes LBA offset
;;; 4 bytes LBA length
;;;0x1be             0x1c1  0x1c2             0x1c5  0x1c6             0x1c9  0x1ca             0x1cd
;;; This is filled with dummy values, and later patched with fdisk.
db 0x80, 0x00, 0x00, 0x00,  0x01, 0x00, 0x00, 0x00,  0xa0, 0x05, 0x00, 0x00,  0x9b, 0x05, 0x00, 0x00 ;; 0x1be p1
db 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00 ;; 0x1ce p2
db 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00 ;; 0x1de p3
db 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00 ;; 0x1ee p4
db 0x55, 0xaa  ;; 0x1fe End the bootsector with 55 AA, which is the MBR signature.

;;; This is the end of the first 512 bytes (the bootsector).

;;; Leave some space for the GPT header and partition table entries (LBA0 = MBR, LBA1 = header, LBA2..33 = GPT partition tables)
times (34*512)-($-$$) db 0

;;; After the bootsector, close the sh here-document skipped via : <<'EOF'
db 0x0a
db "EOF", 0x0a
db "echo Hello world by the OS, from sh!", 0x0a
db "while sleep 10; do :; done", 0x0a
db "exit", 0x0a
;;; for good measure: go into an infinite loop if the exit did not happen.
db "while :; do sleep 1; done", 0x0a

;;; end of the SH section, everything until this point is skipped by MS-DOS batch due to the GOTO'
db ":msdos", 0x0a
db "@cls", 0x0a
db "@echo Hello world by the OS, from MS-DOS!", 0x0a
db "command.com", 0x0a
db "exit", 0x0a
;;; for good measure: go into an infinite loop if the exit did not happen.
db ":loop", 0x0a
db "GOTO loop", 0x0a

;;; Fill up to 32k with 0. This constitutes the reserved first 32k at the beginning of an ISO9660 image.
times (32*1024)-($-$$) db 0
