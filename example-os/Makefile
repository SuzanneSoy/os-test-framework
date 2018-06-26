.PHONY: all
all: os.sh

os.sh: os.asm Makefile
	nasm -o $@ $<
	chmod a+x $@

.PHONY: test
test: test-qemu-system-i386 test-qemu-system-arm test-virtualbox test-bochs

.PHONY: test-qemu-system-i386
test-qemu-system-i386:
	(cd .. && xvfb-run -a ./test/qemu-system-i386.sh)

.PHONY: test-qemu-system-arm
test-qemu-system-arm:
	(cd .. && xvfb-run -a ./test/qemu-system-arm.sh)

.PHONY: test-virtualbox
test-virtualbox:
	(cd .. && xvfb-run -a ./test/virtualbox.sh)

.PHONY: test-bochs
	(cd .. && xvfb-run -a ./test/bochs.sh)
