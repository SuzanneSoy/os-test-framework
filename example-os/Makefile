all: os.sh

os.sh: os.asm Makefile
	nasm -o $@ $<
	chmod a+x $@
