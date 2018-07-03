os_filename = os.bat

.PHONY: all
all: $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm .gitignore Makefile

../deploy-screenshots: Makefile
	mkdir $@

$(os_filename): os.asm ../deploy-screenshots Makefile
	nasm -o $@ $<
	chmod a+x $@

os.ndisasm.disasm: $(os_filename) Makefile
	../utils/compact-ndisasm.sh $< $@

os.reasm.asm: os.ndisasm.disasm Makefile
	sed -r -e 's/^[^ ]+ +[^ ]+ +//' $< > $@

os.reasm: os.reasm.asm $(os_filename) Makefile
	nasm $< -o $@
	@echo "diff $@ $(os_filename)"
	@diff $@ $(os_filename) \
         && echo "[1;32mRe-assembled file is identical to $(os_filename)[m" \
         || (../utils/compact-ndisasm.sh $@ os.reasm.disasm; \
	     echo "[0;33mRe-assembled file is different from $(os_filename). Use meld os.ndisasm.disasm os.reasm.disasm to see differences.[m"; \
	     exit 1)

.PHONY: clean
clean: Makefile
	rm -f $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm

.gitignore: Makefile
	echo /$(os_filename)    >  $@
	echo /os.ndisasm.disasm >> $@
	echo /os.reasm.asm      >> $@
	echo /os.reasm          >> $@
	echo /os.reasm.disasm   >> $@

.PHONY: test
test: test-qemu-system-i386 test-qemu-system-arm test-virtualbox test-bochs Makefile

.PHONY: test-qemu-system-i386
test-qemu-system-i386: $(os_filename) ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/qemu-system-i386.sh)

.PHONY: test-qemu-system-arm
test-qemu-system-arm: $(os_filename) ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/qemu-system-arm.sh)

.PHONY: test-virtualbox
test-virtualbox: $(os_filename) ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/virtualbox.sh)

.PHONY: test-bochs
test-bochs: $(os_filename) ../deploy-screenshots Makefile
	(cd .. && ./utils/gui-wrapper.sh 800x600x24 ./test/bochs.sh)
