.PHONY: all
all: os.sh os.ndisasm.disasm os.reasm.asm os.reasm

../deploy-screenshots:
	mkdir $@

os.sh: os.asm ../deploy-screenshots Makefile
	nasm -o $@ $<
	chmod a+x $@

os.ndisasm.disasm: os.sh Makefile
	../utils/compact-ndisasm.sh $< $@

os.reasm.asm: os.ndisasm.disasm Makefile
	sed -r -e 's/^[^ ]+ +[^ ]+ +//' $< > $@

os.reasm: os.reasm.asm os.sh Makefile
	nasm $< -o $@
	@echo "diff $@ os.sh"
	@diff $@ os.sh \
         && echo "[1;32mRe-assembled file is identical to os.sh[m" \
         || (../utils/compact-ndisasm.sh $@ os.reasm.disasm; \
	     echo "[0;33mRe-assembled file is different from os.sh. Use meld os.ndisasm.disasm os.reasm.disasm to see differences.[m"; \
	     exit 1)

.PHONY: clean Makefile
clean:
	rm -f os.sh os.ndisasm.disasm os.reasm.asm os.reasm

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
