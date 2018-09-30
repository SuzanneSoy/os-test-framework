####################################
# Makefile configuration variables #
OS_FILENAME               = os.bat
BUILD_DIR                 = build
SCREENSHOTS_DIR           = deploy-screenshots
COMMIT_TIMESTAMP_ISO_8601 = $$(git log -1 --pretty=format:%ad --date=iso8601-strict)
####################################

MAKEFLAGS = --warn-undefined-variables
SHELL = ${CURDIR}/utils/safe-bash.sh
# utils/safe-bash.sh
.SECONDEXPANSION:

Makefiles = Makefile Makefile.example-os Makefile.test-example-os

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
commit_timestamp_iso_8601 = ${COMMIT_TIMESTAMP_ISO_8601}

reproducible_os_filename="${bld}/reproduced_$$(basename "${os_filename}")"

built_files += ${bld}/check_makefile \
               ${bld}/check_makefile_targets \
               ${bld}/check_makefile_w_arnings \
               ${bld}/makefile_built_directories \
               ${bld}/makefile_built_files \
               ${bld}/makefile_database \
               ${bld}/makefile_database_files \
               ${bld}/makefile_file_targets \
               ${bld}/makefile_non_file_targets \
               ${bld}/makefile_phony \
               ${bld}/makefile_targets \
               ${bld}/makefile_w_arnings

include Makefile.example-os
include Makefile.test-example-os

more_built_directories = ${built_directories} ${bld}

.PHONY: all
# all: os.arm.disasm
all: .gitignore \
     ${bld}/check_makefile

${bld}/makefile_w_arnings: | $${@D}
${built_files}: | $${@D}

${bld}/makefile_w_arnings: ${Makefiles}
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

${bld}/makefile_database: ${Makefiles} ${bld}/check_makefile_w_arnings
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
${more_built_directories}: ${Makefiles}
	mkdir -p $@ && touch $@

.PHONY: clean
clean: clean_reproducible ${bld}/check_makefile
	rm -f ${built_files} ${temp_files}
	for d in $$(echo ${more_built_directories} ${temp_directories} | tr ' ' '\n' | sort --reverse); do \
          if test -e "$$d"; then \
            rmdir "$$d"; \
          fi; \
        done

.PHONY: clean_reproducible
clean_reproducible: ${bld}/check_makefile
#       Calling make unconditionally would cause infinite recursion, so we
#       first check whether there is anything to remove.
	if test -d ${bld}/reproducible -o -f ${bld}/${reproducible_os_filename}; then \
	  unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	    make OS_FILENAME=${reproducible_os_filename} \
	         BUILD_DIR=${bld}/reproducible \
	         SCREENSHOTS_DIR=${bld}/reproducible/screenshots \
	         COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	         clean; \
	fi

.gitignore: ${bld}/check_makefile
	for f in ${built_files}; do echo "/$$f"; done | sort > $@

test: all \
      ${bld}/check_makefile

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
	  if test "$$(uname -s)" = Darwin -o "$$(uname -o)" = "Cygwin"; then \
	    for i in `seq 5`; do \
	      printf '\033[1;31m########################################################\033[m'; \
	    done; \
	    echo "REPRODUCIBLE BUILDS ARE UNSUPPORTED ON MACOS AND WINDOWS"; \
	    for i in `seq 5`; do \
	      printf '\033[1;31m########################################################\033[m'; \
	    done; \
	  else \
	    exit 1; \
	  fi; \
	fi
	unset MAKEFLAGS MAKELEVEL MAKE_TERMERR MFLAGS; \
	  make OS_FILENAME=${reproducible_os_filename} \
	       BUILD_DIR=${bld}/reproducible \
	       SCREENSHOTS_DIR=${bld}/reproducible/screenshots \
	       COMMIT_TIMESTAMP_ISO_8601=${COMMIT_TIMESTAMP_ISO_8601} \
	       clean
	touch $@
