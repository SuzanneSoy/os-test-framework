os_filename = os.bat
tests = test/qemu-system-i386-floppy test/qemu-system-i386-cdrom test/qemu-system-arm test/virtualbox test/bochs test/gui-sh test/dosbox
built_files = $(os_filename) os.ndisasm.disasm os.reasm.asm os.reasm os.reasm.disasm os.file os.fdisk os.arm.disasm os.zip os.zip.adjusted os.iso os.32k os.fat12 os.offsets iso_files/os.zip iso_files/boot/iso_boot.sys
built_directories = iso_files/boot iso_files

os_image_size_kb = 1440
os_partition_start_sectors = 3
os_partition_size_sectors = 717 # 720 - start
# CHS parameters for 1.44 MB floppy disk
os_floppy_chs_h = 2
os_floppy_chs_s = 9

.PHONY: all
# all: os.arm.disasm
all: $(os_filename) os.ndisasm.disasm os.reasm.asm os.file os.fdisk os.offsets .gitignore Makefile

../deploy-screenshots: Makefile
	mkdir -p $@
	touch $@

# 32k header of the ISO9660 image
os.32k: os.asm Makefile
	nasm -o $@ $<

os.iso: iso_files/os.zip iso_files/boot/iso_boot.sys Makefile
	mkisofs \
	 --input-charset utf-8 \
	 -rock \
	 -joliet \
	 -eltorito-catalog boot/boot.cat \
	 -eltorito-boot boot/iso_boot.sys \
	 -no-emul-boot \
	 -boot-load-size 4 \
	 -pad \
	 -output os.iso \
	 ./iso_files/

sector_size = 512
# should be exact
os_total_size_sectors = ( $(os_image_size_kb)*1024 / $(sector_size) )
os_total_size_tracks = ( $(os_total_size_sectors) / $(os_floppy_chs_s) )
# round up
iso_size_sectors = ( ( $$(wc -c os.iso | cut -d ' ' -f 1) + $(sector_size) - 1 ) / $(sector_size) )
iso_size_tracks = ( ( $(iso_size_sectors) + $(os_floppy_chs_s) - 1 ) / $(os_floppy_chs_s) )
# round up
zip_size_sectors = ( ( $$(wc -c os.zip | cut -d ' ' -f 1) + $(sector_size) - 1 ) / $(sector_size) )
zip_size_tracks = ( ( $(zip_size_sectors) + $(os_floppy_chs_s) - 1 ) / $(os_floppy_chs_s) )
# allocate the remaining sectors, aligned on tracks
fat12_size_tracks = ( ( $(os_total_size_tracks) - $(iso_size_tracks) - $(zip_size_tracks) ) )
fat12_size_sectors = ( $(fat12_size_tracks) * $(os_floppy_chs_s) )
# zip should probably have its end aligned, not its start
space_before_zip_bytes = ( $(os_image_size_kb)*1024 - $$(wc -c os.zip | cut -d ' ' -f 1) )

mbr_start        = 0
mbr_end          = 512
header_32k_start = 0
header_32k_end   = ( 32 * 1024 )
header_32k_size  = ( $(header_32k_end) - $(header_32k_start) )
iso_start        = ( 32 * 1024 )
iso_end          = ( $(iso_size_sectors) * $(sector_size) )
fat12_start      = ( $(iso_size_tracks) * $(os_floppy_chs_s) * $(sector_size) )
fat12_size       = ( $(fat12_size_sectors) * $(sector_size) )
fat12_end        = ( $(fat12_start) + $(fat12_size) )
zip_start        = $(space_before_zip_bytes)
zip_end          = ( $(os_total_size_sectors) * $(sector_size) )

os_fat12_partition = "$@@@$$(( $(fat12_start) ))"
os.fat12: os.zip os.iso Makefile
	set -x; dd if=/dev/zero bs=$(sector_size) count=$$(( $(os_total_size_sectors) )) of=$@
	set -x; mformat -v "Example OS" \
	 -T $$(( $(fat12_size_sectors) )) \
	 -h $(os_floppy_chs_h) \
	 -s $(os_floppy_chs_s) \
	 -i $(os_fat12_partition)
	set -x; mcopy -i $(os_fat12_partition) os.zip "::os.zip"

iso_files: Makefile
	mkdir -p $@

iso_files/boot: iso_files Makefile
	mkdir -p $@

iso_files/os.zip: os.zip iso_files Makefile
# TODO: make it so that the various file formats are mutual quines:
# * the ISO should contain the original file
# * the ZIP should contain the original file
# * the FAT12 should contain the original file
	cp $< $@

# 4 sectors loaded when booting from optical media (CD-ROM, …):
iso_files/boot/iso_boot.sys: os.32k iso_files/boot Makefile
	dd if=$< bs=512 count=4 of=$@

os.zip: os.32k Makefile
	zip $@ $<

os.zip.adjusted: os.zip Makefile
	set -x; dd if=/dev/zero bs=1 count=$$(( $(space_before_zip_bytes) )) of=$@
	cat $< >> $@
	zip --adjust-sfx $@

$(os_filename): os.32k os.iso os.fat12 os.zip os.zip.adjusted ../deploy-screenshots Makefile
	rm -f $@
# start with the .iso
	cp os.iso $@
# splice in the first 32k (bootsector and partition table)
	set -x; dd skip=$$(( $(header_32k_start) )) seek=$$(( $(header_32k_start) )) bs=1 count=$$(( $(header_32k_size) )) conv=notrunc if=os.32k of=$@
# splice in fat12
	set -x; dd skip=$$(( $(fat12_start) )) seek=$$(( $(fat12_start) )) bs=1 count=$$(( $(fat12_size) )) conv=notrunc if=os.fat12 of=$@
# splice in zip at the end
	set -x; dd skip=$$(( $(space_before_zip_bytes) )) seek=$$(( $(space_before_zip_bytes) )) bs=1 conv=notrunc if=os.zip.adjusted of=$@
# patch the partition table
	printf "p\nd\nn\np\n1\n$$(( $(fat12_start) / $(sector_size) ))\n$$(( $(fat12_size_sectors) ))\nt\n01\na\n1\np\nw\nq\n" | fdisk $@
	chmod a+x-w $@

os.file: $(os_filename) Makefile
	file -kr $< > $@

os.fdisk: $(os_filename) Makefile
	fdisk -l $< > $@

os.offsets: $(os_filename) os.32k os.iso os.fat12 os.zip Makefile
	printf 'total_size  = 0x%08x\n' $$(( $(os_total_size_sectors) * $(sector_size) ))  > $@
	printf 'mbr_start   = 0x%08x\n' $$(( $(mbr_start) ))                              >> $@
	printf 'mbr_end     = 0x%08x\n' $$(( $(mbr_end) ))                                >> $@
	printf '32k_start   = 0x%08x\n' $$(( $(header_32k_start) ))                       >> $@
	printf '32k_end     = 0x%08x\n' $$(( $(header_32k_end) ))                         >> $@
	printf 'iso_start   = 0x%08x\n' $$(( $(iso_start) ))                              >> $@
	printf 'iso_end     = 0x%08x\n' $$(( $(iso_end) ))                                >> $@
	printf 'fat12_start = 0x%08x\n' $$(( $(fat12_start) ))                            >> $@
	printf 'fat12_end   = 0x%08x\n' $$(( $(fat12_end) ))                              >> $@
	printf 'zip_start   = 0x%08x\n' $$(( $(zip_start) ))                              >> $@
	printf 'zip_end     = 0x%08x\n' $$(( $(zip_end) ))                                >> $@

os.ndisasm.disasm: $(os_filename) Makefile ../utils/compact-ndisasm.sh
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
	     exit 0) # For now ignore this error, since we cannot have a reliable re-assembly of arbitrary data.

#os.arm.disasm: $(os_filename) Makefile
#	arm-none-eabi-objdump --endian=little -marm -b binary -D --adjust-vma=0x8000 $< > $@

.PHONY: clean
clean: Makefile
	rm -f $(built_files)
	for d in $(built_directories); do if test -e "$$d"; then rmdir "$$d"; fi; done

.gitignore: Makefile
	for f in $(built_files); do echo "/$$f"; done > $@

.PHONY: test
test: $(tests) test/noemu all Makefile

.PHONY: $(tests)
$(tests): $(os_filename) ../deploy-screenshots Makefile
	cd .. && ./utils/gui-wrapper.sh 800x600x24 ./$@.sh example-os/$<

.PHONY: test/noemu
test/noemu: test/zip os.reasm test/sizes test/fat12_contents Makefile

.PHONY: test/zip
test/zip: $(os_filename) Makefile
	unzip -t $(os_filename)

.PHONY: test/sizes
test/sizes: os.32k $(os_filename) Makefile
	test "$$(wc -c os.32k)" = "$$((32*1024)) os.32k"
	test "$$(wc -c $(os_filename))" = "$$((1440*1024)) $(os_filename)"

# check that the fat filesystem has the correct contents
test/fat12_contents: $(os_filename)
	mdir -i "$<@@$$(( $(fat12_start) ))" :: | grep -E "^os\s+zip\s+"
