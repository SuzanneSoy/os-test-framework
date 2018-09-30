;;; This file is a recipie for building os-test-framework as a Guix package.
;;;
;;; This recipe is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; This recipe is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this recipe. If not, see <http://www.gnu.org/licenses/>.
;;;
;;; The copy of the GNU General Public License is stored in the
;;; guix.scm-gpl-license file.

(use-modules (guix packages)
             ;; (guix build gnu-build-system) ;; for the phases?
             (guix build-system gnu)
             (guix gexp)
             (guix)
             (gnu packages assembly)
             (gnu packages base)
             (gnu packages mtools)
             (gnu packages cdrom)
             (gnu packages compression)
             (gnu packages disk)
             (gnu packages linux))

;; For faketime
(use-modules (guix git-download))

(define-public faketime
  (package
   (name "faketime")
   (version "0.9.7")
   (build-system gnu-build-system)
   (arguments
    `(#:phases (modify-phases %standard-phases
                 (delete 'configure)
                 (delete 'check))
      #:make-flags `("CC=gcc"
                     ,(string-append "PREFIX=" %output))))
   (description "LD_PRELOAD hack which allows changing and freezing the system time")
   (home-page "https://github.com/wolfcw/libfaketime")
   (license "CC0-1.0")
   (source
    (origin (uri (git-reference
                  (url    "https://github.com/wolfcw/libfaketime.git")
                  (commit "5c6518c597160109fbe599fb4db9ca91e4a6769c")))
            (method git-fetch)
            (sha256 (base32 "1cisgkw0c7c9psi1g4ji9y2gqans0mm223rs1xhj1bjah95kgkp9"))))
   (synopsis "")))

(define-public os-test-framework
  (package
   (name "os-test-framework")
   (version "0.0")
   (build-system gnu-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
        ;; unpack                ;; this phase is enabled
        ;; patch-source-shebangs ;; this phase is enabled
        (add-after 'patch-source-shebangs 'make-clean
          (lambda* (#:key inputs #:allow-other-keys)
            (invoke "make" "clean" "COMMIT_TIMESTAMP_ISO_8601=1970-01-01T00:00:00+00:00")))
        (delete 'configure)
        (add-before 'build 'make-.gitignore-writable
          (lambda* (#:key inputs #:allow-other-keys)
            (invoke "chmod" "+w" ".gitignore")))
        ;; build                 ;; this phase is enabled
        (delete 'check)          ;; disabled for now, will enable it later.
        (replace 'install
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((out (lambda (f) (string-append (assoc-ref outputs "out") f)))) ;; TODO: use path-append or something similar
              (invoke "mkdir" "-p" (out "/bin"))
              (invoke "cp" "os.bat" (out "/bin/os.bat")))))
        (delete 'patch-shebangs)
        (delete 'strip))
      #:parallel-build? #t
      #:make-flags '("in-guix" "COMMIT_TIMESTAMP_ISO_8601=1970-01-01T00:00:00+00:00")))
   (native-inputs
    `(("nasm" ,nasm)
      ("which" ,which)
      ("mtools" ,mtools)
      ("mkisofs" ,xorriso)
      ("zip" ,zip)
      ("faketime" ,faketime)
      ("gdisk" ,gptfdisk)
      ("column" ,util-linux)))
   (description "Test framework to run an OS in multiple emulators, as a guest graphical / text shell on linux, and so on.")
   (home-page "https://github.com/jsmaniac/os-test-framework")
   (license "CC0-1.0")
   (source (local-file
            (current-source-directory)
            #:recursive? #t
            #:select? (lambda (file stat)
                        (not (equal? (basename file) ".git")))))
   (synopsis "")))

os-test-framework
