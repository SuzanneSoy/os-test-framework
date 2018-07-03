[BITS 16]
[ORG 0x7c00]

db `#!/usr/bin/env sh\n`
db `: <<'EOF'\n`
db `GOTO msdos\n`

times 0x7c78-0x7c00-($-$$) db 0
        
;; Switch to 320x200x256 VGA mode
mov ax, 0x0013
int 10h

;; Framebuffer address is 0xa000, store it into the fs register (the segment base, in multiples of 16)
push 0xa000
pop fs

;; Set pixel value (0, then increase at each step below)
xor bl, bl

;; set register di to 0
xor di,di

;; Store pixels, display something flashy.
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

;; Infinite loop
end:
	jmp end

;; Fill the remaining bytes with 0 and end with 55 AA
times 512-2-($-$$) db 0
db 0x55
db 0xaa

;; end of the bootsector, close the sh here-document skipped via : <<'EOF'
db `\n`
db `EOF\n`
db `echo Hello world from sh!\n`
db `while sleep 10; do :; done\n`
db `exit\n`

;; end of the SH section, everything until this point is skipped by MS-DOS batch due to the GOTO'
db `:msdos\n`
db `@cls\n`
db `@echo "hello world" from MS-DOS\n`
db `:loop\n`
db `GOTO loop\n`

;; Fill up to 1.44M with 0
times (1440*1024)-($-$$) db 0
