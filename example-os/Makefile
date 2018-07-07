os_filename = os.bat
tests = test/qemu-system-i386 test/qemu-system-arm test/virtualbox test/bochs test/gui-sh test/dosbox

.PHONY: all
# all: os.arm.disasm
all: $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm os.file .gitignore Makefile

../deploy-screenshots: Makefile
	mkdir -p $@
	touch $@

$(os_filename): os.asm ../deploy-screenshots Makefile
	rm -f $@
	nasm -o $@ $<
	chmod a+x-w $@

os.file: $(os_filename) Makefile
	file -kr $< > $@

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

#os.arm.disasm: $(os_filename) Makefile
#	arm-none-eabi-objdump --endian=little -marm -b binary -D --adjust-vma=0x8000 $< > $@

.PHONY: clean
clean: Makefile
	rm -f $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm os.file os.arm.disasm

.gitignore: Makefile
	echo /$(os_filename)    >  $@
	echo /os.ndisasm.disasm >> $@
	echo /os.reasm.asm      >> $@
	echo /os.reasm          >> $@
	echo /os.reasm.disasm   >> $@
	echo /os.file           >> $@
	echo /os.arm.disasm     >> $@

.PHONY: test
test: $(tests) all Makefile

.PHONY: $(tests)
$(tests): $(os_filename) ../deploy-screenshots Makefile
	cd .. && ./utils/gui-wrapper.sh 800x600x24 ./$@.sh example-os/$<
