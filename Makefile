####################################
# Makefile configuration variables #
OS_FILENAME               = os.bat
BUILD_DIR                 = build
SCREENSHOTS_DIR           = deploy-screenshots
COMMIT_TIMESTAMP_ISO_8601 = $$(git log -1 --pretty=format:%ad --date=iso8601-strict)
####################################

MAKEFLAGS = --warn-undefined-variables
SHELL = bash -euET -o pipefail -c
.SECONDEXPANSION:

os_filename  = ${OS_FILENAME}
bld          = ${BUILD_DIR}
screenshots  = ${SCREENSHOTS_DIR}
tests_emu = test/qemu-system-i386-floppy test/qemu-system-i386-cdrom test/qemu-system-arm test/virtualbox test/bochs test/gui-sh test/dosbox
tests_requiring_sudo = test/fat12_mount test/iso_mount
tests_noemu = test/zip test/os.reasm test/sizes test/fat12_contents test/reproducible_build

# We truncate the timezone, because the Darwin version of date seems to lack
# the %:z format (for ±HH:MM timezone).
define date_command
  if test "$$(uname -s)" = Darwin; then \
    date -j -f %Y-%m-%dT%H:%M:%S $$(echo ${1} | cut -c 1-19) ${2}; \
  else \
    date -d ${1} ${2}; \
  fi
endef
commit_timestamp = "$$(${call date_command,"${COMMIT_TIMESTAMP_ISO_8601}",'+%Y%m%d%H%m.%S'})"
commit_faketime  = "$$(${call date_command,"${COMMIT_TIMESTAMP_ISO_8601}",'+%Y-%m-%d %H:%m:%S'})"

offset_names = bytes_os_size \
               bytes_mbr_start \
               bytes_mbr_end \
               bytes_header_32k_start \
               bytes_header_32k_end \
               bytes_iso_start \
               bytes_iso_end \
               bytes_fat12_start \
               bytes_fat12_end \
               bytes_gpt_mirror_start \
               bytes_gpt_mirror_end \
               bytes_zip_start \
               bytes_zip_end

more_offset_names = ${offset_names} \
                    bytes_fat12_size \
                    bytes_gpt_mirror_size \
                    bytes_header_32k_size \
                    bytes_iso_size \
                    bytes_zip_size \
                    sectors_fat12_size \
                    sectors_fat12_start \
                    sectors_gpt_mirror_size \
                    sectors_iso_size \
                    sectors_os_size \
                    sectors_zip_size \
                    tracks_fat12_size \
                    tracks_gpt_mirror_size \
                    tracks_iso_size \
                    tracks_os_size \
                    tracks_zip_size

more_offset_dec = ${more_offset_names:%=${bld}/offsets/%.dec}
more_offset_hex = ${more_offset_names:%=${bld}/offsets/%.hex}

reproducible_os_filename="${bld}/reproduced_$$(basename "${os_filename}")"

# + os.arm.disasm
# + os.reasm.disasm
built_files = ${os_filename} \
              ${bld}/check_makefile \
              ${bld}/check_makefile_targets \
              ${bld}/check_makefile_w_arnings \
              ${bld}/checkerboard_800x600.xbm \
              ${bld}/checkerboard_1024x768.png \
              ${bld}/makefile_built_directories \
              ${bld}/makefile_built_files \
              ${bld}/makefile_database \
              ${bld}/makefile_database_files \
              ${bld}/makefile_file_targets \
              ${bld}/makefile_non_file_targets \
              ${bld}/makefile_phony \
              ${bld}/makefile_targets \
              ${bld}/makefile_w_arnings \
              ${bld}/os.ndisasm.disasm \
              ${bld}/os.reasm.asm \
              ${bld}/os.reasm \
              ${bld}/os.file \
              ${bld}/os.gdisk \
              ${bld}/os.zip \
              ${bld}/os.zip.adjusted \
              ${bld}/os.iso \
              ${bld}/os.32k \
              ${bld}/os.fat12 \
              ${bld}/os.offsets.hex \
              ${bld}/os.offsets.dec \
              ${bld}/os.hex_with_offsets \
              ${bld}/iso_files/os.zip \
              ${bld}/iso_files/boot/iso_boot.sys \
              ${bld}/bochsrc \
              ${bld}/bochscontinue \
              ${bld}/twm_cfg \
              ${bld}/virtualbox.img \
              ${more_offset_dec} \
              ${more_offset_hex} \
              ${tests_emu:test/%=${bld}/test_pass/emu_%} \
              ${tests_noemu:test/%=${bld}/test_pass/noemu_%} \
              ${tests_requiring_sudo:test/%=${bld}/test_pass/sudo_%} \
              ${tests_emu:test/%=${screenshots}/%.png} \
              ${tests_emu:test/%=${screenshots}/%-anim.gif} \
              utils/mformat utils/mcopy utils/mkisofs

# Temporary copies used to adjust timestamps for reproducible builds.
# These are normally created and deleted within a single target, but
# could remain if make is interrupted during the build.
temp_files       = ${bld}/iso_files.tmp/os.zip \
                   ${bld}/iso_files.tmp/boot/iso_boot.sys
temp_directories = ${bld}/iso_files.tmp \
                   ${bld}/iso_files.tmp/boot/

built_directories = ${bld}/iso_files/boot \
                    ${bld}/iso_files \
                    ${bld}/offsets \
                    ${bld}/mnt_fat12 \
                    ${bld}/mnt_iso \
                    ${bld}/test_pass \
                    ${screenshots}
more_built_directories = ${built_directories} ${bld}

os_image_size_kb = 1440
os_partition_start_sectors = 3
os_partition_size_sectors = 717 # 720 - start
# CHS parameters for 1.44 MB floppy disk
os_floppy_chs_h = 2
os_floppy_chs_s = 9

.PHONY: all
# all: os.arm.disasm
all: ${os_filename} \
     ${bld}/os.ndisasm.disasm \
     ${bld}/os.reasm.asm \
     ${bld}/os.file \
     ${bld}/os.gdisk \
     ${bld}/os.offsets.hex \
     ${bld}/os.offsets.dec \
     ${bld}/os.hex_with_offsets \
     .gitignore \
     ${bld}/check_makefile \
     ${more_offset_dec} \
     ${more_offset_hex}

${bld}/makefile_w_arnings: | $${@D}
${built_files}: | $${@D}

${bld}/makefile_w_arnings: Makefile
	@unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	   make -n --warn-undefined-variables \
	        OS_FILENAME=${OS_FILENAME} \
	        BUILD_DIR=${BUILD_DIR} \
	        SCREENSHOTS_DIR=${SCREENSHOTS_DIR} \
	        COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	        test 2>$@ 1>/dev/null \
	 || cat $@

# Check that the file ${bld}/makefile_w_arnings is present, and that it does not contain the string "warn".
${bld}/check_makefile_w_arnings: ${bld}/makefile_w_arnings
	@cat ${bld}/makefile_w_arnings > /dev/null && (! grep -i warn $<) && touch $@

# Check that the declared list of built files matches the list of targets extracted from the Makefile.
${bld}/check_makefile_targets: ${bld}/makefile_built_files ${bld}/makefile_file_targets ${bld}/check_makefile_w_arnings
	@diff ${bld}/makefile_built_files ${bld}/makefile_file_targets && touch $@

${bld}/check_makefile: ${bld}/check_makefile_w_arnings ${bld}/check_makefile_targets
	@touch $@

${bld}/makefile_database: Makefile ${bld}/check_makefile_w_arnings
	@unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	   make -rpn \
	        OS_FILENAME=${OS_FILENAME} \
	        BUILD_DIR=${BUILD_DIR} \
	        SCREENSHOTS_DIR=${SCREENSHOTS_DIR} \
	        COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	 | sed -n -e '/^# Make data base,/,$$p' > $@

${bld}/makefile_database_files: ${bld}/makefile_database ${bld}/check_makefile_w_arnings
	@sed -n -e '/^# Files$$/,/^# files hash-table stats:$$/p' $< > $@

${bld}/makefile_built_directories: ${bld}/check_makefile_w_arnings
	@echo ${more_built_directories} | tr ' ' '\n' | grep -v '^[[:space:]]*$$' | sort > $@

${bld}/makefile_built_files: ${bld}/check_makefile_w_arnings
	@echo ${built_files} | tr ' ' '\n' | grep -v '^[[:space:]]*$$' | sort > $@

${bld}/makefile_phony: ${bld}/makefile_database_files ${bld}/check_makefile_w_arnings
	@sed -n -e 's/^\.PHONY: \(.*\)$$/\1/p' $< | tr ' ' '\n' | grep -v '^[[:space:]]*$$' | sort > $@

${bld}/makefile_targets: ${bld}/makefile_database_files ${bld}/check_makefile_w_arnings
	@grep -E -v '^([[:space:]]|#|\.|$$|^[^:]*:$$)' $< | grep '^[^ :]*:' | sed -e 's|^\([^:]*\):.*$$|\1|' | sort > $@

${bld}/makefile_non_file_targets: ${bld}/makefile_phony ${bld}/makefile_built_directories ${bld}/check_makefile_w_arnings
	@cat ${bld}/makefile_phony ${bld}/makefile_built_directories | sort > $@

${bld}/makefile_file_targets: ${bld}/makefile_non_file_targets ${bld}/makefile_targets ${bld}/check_makefile_w_arnings
	@comm -23 ${bld}/makefile_targets ${bld}/makefile_non_file_targets > $@

${built_directories}: ${bld}/check_makefile
${more_built_directories}: Makefile
	mkdir -p $@ && touch $@

# 32k header of the ISO9660 image
${bld}/os.32k: example-os/os.asm ${bld}/check_makefile
	nasm -w+macro-params -w+macro-selfref -w+orphan-labels -w+gnu-elf-extensions -o $@ $<

# Circumvent the fact that faketime does not work on system binaries in macos
./utils/mkisofs ./utils/mformat ./utils/mcopy: Makefile	# TODO: depend on the mkisofs binary
	cp $$(which $$(basename $@)) $@
	chmod u+x $@

cp_T_option = $$(if test "$$(uname -s)" = Darwin; then echo ''; else echo '-T'; fi)
${bld}/os.iso: ${bld}/iso_files/os.zip ${bld}/iso_files/boot/iso_boot.sys ./utils/mkisofs ${bld}/check_makefile
	! test -d ${bld}/iso_files.tmp
	cp -a ${cp_T_option} -- ${bld}/iso_files ${bld}/iso_files.tmp
	find ${bld}/iso_files.tmp -depth -exec touch -t ${commit_timestamp} '{}' ';'
	UTILS="$$PWD/utils" (cd ./${bld}/iso_files.tmp/ && faketime -f ${commit_faketime} $$UTILS/mkisofs \
	 --input-charset utf-8 \
	 -rock \
	 -joliet \
	 -eltorito-catalog boot/boot.cat \
	 -eltorito-boot boot/iso_boot.sys \
	 -no-emul-boot \
	 -boot-load-size 4 \
	 -pad \
	 -output ../os.iso \
	 .)
	rm -- ${bld}/iso_files.tmp/os.zip \
              ${bld}/iso_files.tmp/boot/iso_boot.sys
	rmdir ${bld}/iso_files.tmp/boot/
	rmdir ${bld}/iso_files.tmp/

# Layout:
# MBR; GPT; UNIX sh & MS-DOS batch scripts; ISO9660; FAT12; GPT mirror; ZIP

define offset
tmp_${1} = ${3}
${bld}/offsets/${1}.dec: $${tmp_${1}:%=${bld}/offsets/%.dec} ${4} ${bld}/check_makefile
	echo $$$$(( ${2} )) | tee $$@
${1} = $$$$(cat ${bld}/offsets/${1}.dec)
dep_${1} = ${bld}/offsets/${1}.dec
endef

define div_round_up
( ( ( ${1} ) + ( ${2} ) - 1 ) / ( ${2} ) )
endef

sector_size = 512
# should be exact (TODO: make a check)
${eval ${call offset,bytes_os_size,     $${os_image_size_kb} * 1024,,                                  }}
${eval ${call offset,sectors_os_size,   $${bytes_os_size}    / $${sector_size},                        bytes_os_size,}}
${eval ${call offset,tracks_os_size,    $${sectors_os_size}  / $${os_floppy_chs_s},                    sectors_os_size,}}

# round up
${eval ${call offset,bytes_iso_size,    $$$$(utils/file-length.sh -c ${bld}/os.iso),             ,${bld}/os.iso}}
${eval ${call offset,sectors_iso_size,  ${call div_round_up,$${bytes_iso_size},$${sector_size}},       bytes_iso_size,}}
${eval ${call offset,tracks_iso_size,   ${call div_round_up,$${sectors_iso_size},$${os_floppy_chs_s}}, sectors_iso_size,}}

# round up
${eval ${call offset,bytes_zip_size,    $$$$(utils/file-length.sh -c ${bld}/os.zip),             ,${bld}/os.zip}}
${eval ${call offset,sectors_zip_size,  ${call div_round_up,$${bytes_zip_size},$${sector_size}},       bytes_zip_size,}}
${eval ${call offset,tracks_zip_size,   ${call div_round_up,$${sectors_zip_size},$${os_floppy_chs_s}}, sectors_zip_size,}}

# round up
${eval ${call offset,sectors_gpt_mirror_size, 33,,                                                   }}
${eval ${call offset,tracks_gpt_mirror_size,  ${call div_round_up,$${sectors_gpt_mirror_size},$${os_floppy_chs_s}}, sectors_gpt_mirror_size,}}

# allocate the remaining sectors to the FAT, aligned on tracks
${eval ${call offset,tracks_fat12_size, $${tracks_os_size} - $${tracks_iso_size} - $${tracks_gpt_mirror_size} - $${tracks_zip_size}, tracks_os_size tracks_iso_size tracks_gpt_mirror_size tracks_zip_size,}}
${eval ${call offset,sectors_fat12_size,$${tracks_fat12_size} * $${os_floppy_chs_s},                   tracks_fat12_size,}}

# zip should probably have its end aligned, not its start
${eval ${call offset,bytes_zip_start,   $${bytes_os_size} - $${bytes_zip_size},                        bytes_os_size bytes_zip_size,}}

${eval ${call offset,bytes_mbr_start,        0,,}}
${eval ${call offset,bytes_mbr_end,          512,,}}
${eval ${call offset,bytes_header_32k_start, 0,,}}
${eval ${call offset,bytes_header_32k_end,   32 * 1024,,}}
${eval ${call offset,bytes_header_32k_size,  $${bytes_header_32k_end} - $${bytes_header_32k_start},      bytes_header_32k_end bytes_header_32k_start,}}
${eval ${call offset,bytes_iso_start,        32 * 1024,,}}
${eval ${call offset,bytes_iso_end,          $${sectors_iso_size} * $${sector_size},                     sectors_iso_size,}}
${eval ${call offset,bytes_fat12_start,      $${tracks_iso_size} * $${os_floppy_chs_s} * $${sector_size}, tracks_iso_size,}}
${eval ${call offset,sectors_fat12_start,    $${bytes_fat12_start} / $${sector_size},                    bytes_fat12_start,}}
${eval ${call offset,bytes_fat12_size,       $${sectors_fat12_size} * $${sector_size},                   sectors_fat12_size,}}
${eval ${call offset,bytes_fat12_end,        $${bytes_fat12_start} + $${bytes_fat12_size},               bytes_fat12_start bytes_fat12_size,}}
# It is probably not necessary to align the GPT mirror end on a track boundary.
${eval ${call offset,bytes_gpt_mirror_size,  $${sectors_gpt_mirror_size} + $${sector_size},              sectors_gpt_mirror_size,}}
${eval ${call offset,bytes_gpt_mirror_end,   $${bytes_fat12_end} + $${bytes_gpt_mirror_size},            bytes_fat12_end bytes_gpt_mirror_size,}}
${eval ${call offset,bytes_gpt_mirror_start, $${bytes_gpt_mirror_end} - $${bytes_gpt_mirror_size},       bytes_gpt_mirror_end bytes_gpt_mirror_size,}}
${eval ${call offset,bytes_zip_end,          $${bytes_os_size},                                          bytes_os_size,}}

os_fat12_partition = "$@@@${bytes_fat12_start}"
${bld}/os.fat12: ${bld}/os.zip ${dep_bytes_fat12_size} ${dep_bytes_fat12_start} ${dep_sectors_os_size} \
                 ./utils/mformat ./utils/mcopy ${bld}/check_makefile
	set -x; dd if=/dev/zero bs=${sector_size} count=${sectors_os_size} of=$@
	faketime -f ${commit_faketime} ./utils/mformat -v "Example OS" \
	 -T ${sectors_fat12_size} \
	 -h ${os_floppy_chs_h} \
	 -s ${os_floppy_chs_s} \
	 -i ${os_fat12_partition}
	faketime -f ${commit_faketime} ./utils/mcopy -i ${os_fat12_partition} $< "::os.zip"

${bld}/iso_files/os.zip: ${bld}/os.zip ${bld}/check_makefile
# TODO: make it so that the various file formats are mutual quines:
# * the ISO should contain the original file
# * the ZIP should contain the original file
# * the FAT12 should contain the original file
	cp $< $@

# 4 sectors loaded when booting from optical media (CD-ROM, …):
${bld}/iso_files/boot/iso_boot.sys: ${bld}/os.32k ${bld}/check_makefile
# TODO: this copy of the (or alternate) bootsector should contain a Boot Information Table,
#       see https://wiki.osdev.org/El-Torito#A_BareBones_Boot_Image_with_Boot_Information_Table
	dd if=$< bs=512 count=4 of=$@

${bld}/os.zip: ${bld}/os.32k ${bld}/check_makefile
#	We copy os.32k and alter its timestamp to ensure reproducible
#	builds.
	mkdir -p ${bld}/os.32k.tmp
	cp -a $< ${bld}/os.32k.tmp/os.32k
	touch -t ${commit_timestamp} ${bld}/os.32k.tmp/os.32k
	(cd ${bld}/os.32k.tmp/ && zip -X ../os.zip os.32k)
	rm ${bld}/os.32k.tmp/os.32k
	rmdir ${bld}/os.32k.tmp

${bld}/os.zip.adjusted: ${bld}/os.zip ${dep_bytes_zip_start} ${bld}/check_makefile
# TODO: the ZIP file can end with a variable-length comment, this would allow us to hide the GPT mirrors.
	set -x; dd if=/dev/zero bs=1 count=${bytes_zip_start} of=$@
	cat $< >> $@
	zip --adjust-sfx $@

gdisk_pipe_commands_slowly=while read str; do echo "$$str"; printf "\033[1;33m%s\033[m\n" "$$str" >&2; sleep 0.01; done

commit_hash_as_guid=$$(git log -1 --pretty=format:%H | sed -e 's/^\(.\{8\}\)\(.\{4\}\)\(.\{4\}\)\(.\{4\}\)\(.\{12\}\).*$$/\1-\2-\3-\4-\5/' | tr '[:lower:]' '[:upper:]')
git_dirty=test -n "$$(git diff --shortstat)"
gpt_disk_guid=${commit_hash_as_guid}$$(if $$git_dirty; then printf '0'; else printf '2'; fi)
gpt_partition_guid=${commit_hash_as_guid}$$(if $$git_dirty; then printf '1'; else printf '3'; fi)

${os_filename}: ${bld}/os.32k ${bld}/os.iso ${bld}/os.fat12 ${bld}/os.zip.adjusted \
                ${dep_bytes_header_32k_start} \
                ${dep_bytes_header_32k_size} \
                ${dep_bytes_fat12_start} \
                ${dep_bytes_fat12_size} \
                ${dep_bytes_gpt_mirror_start} \
                ${dep_bytes_gpt_mirror_end} \
                ${dep_sectors_fat12_start} \
                ${dep_sectors_fat12_size} \
                ${dep_bytes_zip_start} \
                ${bld}/check_makefile
	rm -f $@
# start with the .iso
	cp ${bld}/os.iso $@
# splice in the first 32k (bootsector and partition table)
	set -x; dd skip=${bytes_header_32k_start} seek=${bytes_header_32k_start} bs=1 count=${bytes_header_32k_size} conv=notrunc if=${bld}/os.32k of=$@
# splice in fat12
	set -x; dd skip=${bytes_fat12_start} seek=${bytes_fat12_start} bs=1 count=${bytes_fat12_size} conv=notrunc if=${bld}/os.fat12 of=$@
# pad with zeroes to prepare for GPT table
	set -x; dd if=/dev/zero seek=$$((${bytes_gpt_mirror_end} - 1 )) bs=1 count=1 conv=notrunc of=$@
# patch the partition table
# Thanks to https://wiki.gentoo.org/wiki/Hybrid_partition_table for showing that gdisk can be used to make a hybrid MBR / GPT.
#       gdisk commands:
#         * Delete (the only) partition, eXpert mode, sector aLignment = 1, back to Main menu,
#         * New partition (number = 1, start sector, end sector, type 0700)
#         * Recovery and transformation options, make Hybrid,
#           * add GPT partition #1 to the hybrid MBR, do Not put the EFI partition first,
#           * MBR partition type=0x01, bootable=Yes, do Not add extra partitions,
#           * back to Main menu,
#         * eXpert mode,
#           * Change partition GUID, the GUID itself,
#           * change disk GUID, the GUID itself,
#           * Print GPT, print prOtective MBR, Write, Proceed.
	(if test "$$(uname -o)" = "Cygwin"; then printf "Y\n"; fi; \
	 printf "d\nx\nl\n1\nm\n"; \
	 printf "n\n1\n${sectors_fat12_start}\n${sectors_fat12_size}\n0700\n"; \
	 printf "r\nh\n"; \
	 printf "1\nN\n"; \
	 printf "01\nY\nN\n"; \
	 printf "x\n"; \
	 printf "g\n${gpt_disk_guid}\n"; \
	 printf "c\n${gpt_partition_guid}\n"; \
	 printf "p\no\nw\nY\n") | ${gdisk_pipe_commands_slowly} | gdisk $@
# Inject MS-DOS newlines (CR+LF) and comments (":: ") in the GUID field of unused partition table entries,
# so that the part that is to be skipped by MS-DOS does not form a line longer than the MS-DOS maximum
# line length (8192 excluding CR+LF). $i below is the partition entry number, starting from 1
# The numbers 55 and 118 are arbitrarily chosen so that the space between two CR+LF is less than 8192.
	for i in 55 118; do \
	  printf "\r\n:: %02x" $$i | dd bs=1 seek=$$(( 1024 + ( ($$i) - 1) * 128 + 16)) count=7 conv=notrunc of=$@; \
	  printf "\r\n:: %02x" $$i | dd bs=1 seek=$$(( ${bytes_gpt_mirror_start} + ( ($$i) - 1) * 128 + 16)) count=7 conv=notrunc of=$@; \
	done
# splice in zip at the end
	set -x; dd skip=${bytes_zip_start} seek=${bytes_zip_start} bs=1 conv=notrunc if=${bld}/os.zip.adjusted of=$@
	chmod a+x-w $@

${bld}/os.file: ${os_filename} ${bld}/check_makefile
	file -kr $< > $@

${bld}/os.gdisk: ${os_filename} ${bld}/check_makefile
#       gdisk commands:
#         * eXpert mode
#           * Print partition table
#           * print detailed Information about the (only) partition
#           * print prOtective MBR table
#           * Quit
	printf '2\nx\np\ni\nr\no\nq\n' | ${gdisk_pipe_commands_slowly} | gdisk $< | tee $@

${bld}/os.offsets.hex: ${offset_names:%=${bld}/offsets/%.hex} ${bld}/check_makefile
	grep '^' ${offset_names:%=${bld}/offsets/%.hex} | sed -e 's|^.*/||' -e 's/:/: 0x/' | column -t > $@

${bld}/os.offsets.dec: ${offset_names:%=${bld}/offsets/%.dec} ${bld}/check_makefile
	grep '^' ${offset_names:%=${bld}/offsets/%.dec} | sed -e 's|^.*/||' -e 's/:/: /' | column -t > $@

${bld}/offsets/%.hex: ${bld}/offsets/%.dec
	printf '%x\n' $$(cat $<) > $@

${bld}/os.hex_with_offsets: ${os_filename} ${bld}/os.offsets.hex
	hexdump -C $< \
	 | grep -E -e "($$(cat ${bld}/os.offsets.hex | cut -d '=' -f 2 | sed -e 's/^[[:space:]]*0x\(.*\).$$/^\10/' | tr '\n' '|')^)" --color=yes > $@

${bld}/os.ndisasm.disasm: ${os_filename} utils/compact-ndisasm.sh ${bld}/check_makefile
	./utils/compact-ndisasm.sh $< $@

${bld}/os.reasm.asm: ${bld}/os.ndisasm.disasm ${bld}/check_makefile
	sed -e 's/^[^ ]\+ \+[^ ]\+ \+//' $< > $@

${bld}/test_pass/noemu_%.reasm ${bld}/%.reasm: ${bld}/%.reasm.asm ${os_filename} utils/compact-ndisasm.sh ${bld}/check_makefile
# For now ignore this test, since we cannot have a reliable re-assembly of arbitrary data.
	touch ${bld}/test_pass/noemu_$*.reasm ${bld}/$*.reasm
#	nasm $< -o $@
#	@echo "diff $@ ${os_filename}"
#	@diff $@ ${os_filename} \
#         && echo "[1;32mRe-assembled file is identical to ${os_filename}[m" \
#         || (./utils/compact-ndisasm.sh $@ ${bld}/os.reasm.disasm; \
#	     echo "[0;33mRe-assembled file is different from ${os_filename}. Use meld ${bld}/os.ndisasm.disasm ${bld}/os.reasm.disasm to see differences.[m"; \
#	     exit 0)

#os.arm.disasm: ${os_filename} ${bld}/check_makefile
#	arm-none-eabi-objdump --endian=little -marm -b binary -D --adjust-vma=0x8000 $< > $@

.PHONY: clean
clean: ${bld}/check_makefile
	rm -f ${built_files} ${temp_files} ${bld}/${reproducible_os_filename}
	if test -d ${bld}/reproducible; then \
	  unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	    make OS_FILENAME=${reproducible_os_filename} \
	         BUILD_DIR=${bld}/reproducible \
	         SCREENSHOTS_DIR=${bld}/reproducible/screenshots \
	         COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	         clean; \
	fi
	for d in $$(echo ${more_built_directories} ${temp_directories} | tr ' ' '\n' | sort --reverse); do \
          if test -e "$$d"; then \
            rmdir "$$d"; \
          fi; \
        done

.gitignore: ${bld}/check_makefile
	for f in ${built_files}; do echo "/$$f"; done | sort > $@

.PHONY: test
test: ${tests_emu:test/%=${bld}/test_pass/emu_%} \
      ${tests_noemu:test/%=${bld}/test_pass/noemu_%} \
      ${tests_requiring_sudo:test/%=${bld}/test_pass/sudo_%} \
      all \
      ${bld}/check_makefile

.PHONY: test/emu test/noemu test/requiring_sudo
test/emu:            ${tests_emu}            ${bld}/check_makefile
test/requiring_sudo: ${tests_requiring_sudo} ${bld}/check_makefile
test/noemu:          ${tests_noemu}          ${bld}/check_makefile

.PHONY: ${tests_emu} ${tests_noemu} ${tests_requiring_sudo}
${tests_emu}:            ${bld}/test_pass/emu_$$(@F)   ${bld}/check_makefile
${tests_noemu}:          ${bld}/test_pass/noemu_$$(@F) ${bld}/check_makefile
${tests_requiring_sudo}: ${bld}/test_pass/sudo_$$(@F)  ${bld}/check_makefile

${bld}/test_pass/emu_% ${screenshots}/%.png ${screenshots}/%-anim.gif: \
 ${os_filename} \
 ${bld}/checkerboard_800x600.xbm \
 utils/gui-wrapper.sh utils/ansi-screenshots/ansi_screenshot.sh utils/ansi-screenshots/to_ansi.sh \
 test/%.sh \
 ${bld}/check_makefile \
 | ${bld}/test_pass ${screenshots}
	./utils/gui-wrapper.sh 800x600x24 ./test/$*.sh $<
	touch ${bld}/test_pass/emu_$*

${bld}/test_pass/noemu_zip: ${os_filename} ${bld}/check_makefile
	unzip -t ${os_filename}
	touch $@

${bld}/test_pass/noemu_sizes: ${bld}/os.32k ${os_filename} ${bld}/check_makefile
	test "$$(utils/file-length.sh -c ${bld}/os.32k)" = "$$((32*1024))"
	test "$$(utils/file-length.sh -c ${os_filename})" = "$$((1440*1024))"
	touch $@

# check that the fat filesystem has the correct contents
${bld}/test_pass/noemu_fat12_contents: ${os_filename} ${dep_bytes_fat12_start} ${bld}/check_makefile
	mdir -i "$<@@${bytes_fat12_start}" :: | grep -E "^os[[:space:]]+zip[[:space:]]+"
	touch $@

.PHONY: test/requiring_sudo
test/requiring_sudo: ${tests_requiring_sudo:test/%=${bld}/test_pass/sudo_%} ${bld}/check_makefile

# check that the fat filesystem can be mounted and has the correct contents
${bld}/test_pass/sudo_fat12_mount: ${os_filename} ${dep_bytes_fat12_start} ${bld}/check_makefile | ${bld}/mnt_fat12
	sudo umount ${bld}/mnt_fat12 || true
	sudo mount -o loop,ro,offset=${bytes_fat12_start} $< ${bld}/mnt_fat12
	ls -l ${bld}/mnt_fat12 | grep os.zip
	sudo umount ${bld}/mnt_fat12
	touch $@

${bld}/test_pass/sudo_iso_mount: ${os_filename} ${bld}/check_makefile | ${bld}/mnt_iso
	sudo umount ${bld}/mnt_iso || true
	grep '^' ${bld}/offsets/* # debug failure to mount the ISO9660 filesystem
	(sudo mount -o loop,ro $< ${bld}/mnt_iso) || true
	dmesg | tail # debug failure to mount the ISO9660 filesystem
	hexdump -C ${os_filename}
	ls -l ${bld}/mnt_iso | grep os.zip
	sudo umount ${bld}/mnt_iso
	sudo mount -o loop,ro $< ${bld}/mnt_iso
	sudo umount ${bld}/mnt_iso
	touch $@

.PHONY: test/macos
test/macos: all test/noemu test/macos-sh test/macos-sh-x11

.PHONY: test/macos-sh-x11
test/macos-sh-x11:
	sudo mkdir -p /tmp/.X11-unix
	sudo chmod a+rwxt /tmp/.X11-unix
	xvfb :42 & \
	sleep 5; \
	DISPLAY=:42 xterm -e ./${os_filename} & \
	sleep 5; \
#	DISPLAY=:42 import -window root ${screenshots}/macos-sh-x11.png
	screencapture ${screenshots}/macos-sh-x11-screencapture.png

.PHONY: test/macos-sh
test/macos-sh: ${bld}/check_makefile \
               ${bld}/checkerboard_1024x768.png \
               | ${screenshots}
	osascript -e 'tell app "Terminal" to do script "'"$$PWD"'/${os_filename}"'
	sleep 2
	osascript -e 'tell app "Terminal" to activate'
	sleep 5
	(date +%n && sleep 0.2 && date +%n) || true
	screencapture ${screenshots}/screencapture-os-bat.png
	./utils/gui-wrapper-mac.sh 1024x768x24 ./test/gui-sh-mac.sh ${os_filename}

# See https://wiki.osdev.org/EFI#Emulation to emulate an UEFI system with qemu, to test the EFI boot from hdd / cd / fd (?).

# Create checkerboard background
${bld}/checkerboard_%.png: ${bld}/check_makefile
	convert -size "$*" \
	        tile:pattern:checkerboard \
	        -auto-level +level-colors 'gray(192),gray(128)' \
	        $@

${bld}/checkerboard_%.xbm: ${bld}/check_makefile
	convert -size "$*" \
	        tile:pattern:checkerboard \
	        -auto-level \
	        $@

# Temporary files
${bld}/bochsrc ${bld}/bochscontinue ${bld}/twm_cfg ${bld}/virtualbox.img: ${bld}/check_makefile
	touch $@

# DEBUG: ${bld}/os.hex_with_offsets ${bld}/os.offsets.hex
${bld}/test_pass/noemu_reproducible_build: ${os_filename} ${bld}/os.hex_with_offsets ${bld}/check_makefile
#       Let some time pass so that any timestamp that may affect the result changes.
	sleep 5
#       TODO: try to see if we can re-enable some of these variables without
#             causing problems on macos.
	unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	  make OS_FILENAME=${reproducible_os_filename} \
	       BUILD_DIR=${bld}/reproducible \
	       SCREENSHOTS_DIR=${bld}/reproducible/screenshots \
	       COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	       clean
	unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	  make OS_FILENAME=${reproducible_os_filename} \
	       BUILD_DIR=${bld}/reproducible \
	       SCREENSHOTS_DIR=${bld}/reproducible/screenshots \
	       COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	       ${reproducible_os_filename} \
               ${bld}/reproducible/os.hex_with_offsets
#       Check that the second build produced the same file.
	if ! diff ${os_filename} ${reproducible_os_filename}; then \
	  diff ${bld}/os.hex_with_offsets ${bld}/reproducible/os.hex_with_offsets || true; \
	  exit 1; \
	fi
	unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	  make OS_FILENAME=${reproducible_os_filename} \
	       BUILD_DIR=${bld}/reproducible \
	       SCREENSHOTS_DIR=${bld}/reproducible/screenshots \
	       COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	       clean
	touch $@
