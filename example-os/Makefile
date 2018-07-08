os_filename = os.bat
tests = test/qemu-system-i386 test/qemu-system-arm test/virtualbox test/bochs test/gui-sh test/dosbox

os_image_size_kb = 1440
os_partition_start_sectors = 3
os_partition_size_sectors = 717 # 720 - start
# CHS parameters for 1.44 MB floppy disk
os_floppy_chs_h = 2
os_floppy_chs_s = 9

.PHONY: all
# all: os.arm.disasm
all: $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm os.file os.fdisk .gitignore Makefile

../deploy-screenshots: Makefile
	mkdir -p $@
	touch $@

$(os_filename): os.asm ../deploy-screenshots Makefile
	rm -f $@
	nasm -o $@ $<
	mformat -v "Example OS" \
	 -T $$(($(os_partition_size_sectors))) \
	 -h $(os_floppy_chs_h) \
	 -s $(os_floppy_chs_s) \
	 -i "$@@@$$(($(os_partition_start_sectors)*512))"
#	mcopy … "$@@@$$(($(os_partition_start_sectors)*512))"
	zip os.zip $@
	dd seek=$$(($(os_image_size_kb)*1024-$$(wc -c os.zip | cut -d ' ' -f 1))) bs=1 if=os.zip of=$@
	zip --adjust-sfx $@
	chmod a+x-w $@

os.file: $(os_filename) Makefile
	file -kr $< > $@

os.fdisk: $(os_filename) Makefile
	fdisk -l $< > $@

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
	rm -f $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm os.file os.arm.disasm os.zip

.gitignore: Makefile
	echo /$(os_filename)    >  $@
	echo /os.ndisasm.disasm >> $@
	echo /os.reasm.asm      >> $@
	echo /os.reasm          >> $@
	echo /os.reasm.disasm   >> $@
	echo /os.file           >> $@
	echo /os.fdisk          >> $@
	echo /os.arm.disasm     >> $@
	echo /os.zip            >> $@

.PHONY: test
test: $(tests) test/zip all Makefile

.PHONY: $(tests)
$(tests): $(os_filename) ../deploy-screenshots Makefile
	cd .. && ./utils/gui-wrapper.sh 800x600x24 ./$@.sh example-os/$<

.PHONY: test/zip
test/zip:
	unzip -t os.zip
