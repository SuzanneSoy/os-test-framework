.PHONY: all
all: os.sh

../deploy-screenshots:
	mkdir $@

os.sh: os.asm ../deploy-screenshots Makefile
	nasm -o $@ $<
	chmod a+x $@

.PHONY: test
test: test-qemu-system-i386 test-qemu-system-arm test-virtualbox test-bochs Makefile

.PHONY: test-qemu-system-i386
test-qemu-system-i386: os.sh ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/qemu-system-i386.sh)

.PHONY: test-qemu-system-arm
test-qemu-system-arm: os.sh ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/qemu-system-arm.sh)

.PHONY: test-virtualbox
test-virtualbox: os.sh ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/virtualbox.sh)

.PHONY: test-bochs
test-bochs: os.sh ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/bochs.sh)
