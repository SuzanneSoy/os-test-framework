[BITS 16]
[ORG 0x7c00]

db `#!/usr/bin/env sh\n`
db `: <<'EOF'\n`
db `GOTO msdos\n`

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
loop:
	mov byte [fs:di], bl
	inc bl
	inc di
	cmp bl, 255
	je endline
	jmp loop

endline:
	add di, 65
	xor bl, bl
	mov ax, di
	cmp ax, (320*200)
	je end
	jmp loop

;;; Infinite loop
end:
	jmp end

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

;;; After the bootsector, close the sh here-document skipped via : <<'EOF'
db `\n`
db `EOF\n`
db `echo Hello world by the OS, from sh!\n`
db `while sleep 10; do :; done\n`
db `exit\n`
;;; for good measure: go into an infinite loop if the exit did not happen.
db `while :; do sleep 1; done\n`

;;; end of the SH section, everything until this point is skipped by MS-DOS batch due to the GOTO'
db `:msdos\n`
db `@cls\n`
db `@echo Hello world by the OS, from MS-DOS!\n`
db `command.com\n`
db `exit\n`
;;; for good measure: go into an infinite loop if the exit did not happen.
db `:loop\n`
db `GOTO loop\n`

;;; Fill up to 32k with 0. This constitutes the first 32k of the ISO image.
times (32*1024)-($-$$) db 0
