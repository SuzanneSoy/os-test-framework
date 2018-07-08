# Travis test harness for hobby operating systems

This Travis configuration runs an operating system in various emulators. It can execute a SikuliX test script to ensure that some elements are visible on-screen, send keystrokes and mouse events, and interact with the OS GUI in an automated way. Finally, it will take screenshots of the operating system, and upload them to a separate repository hosting these artifacts.

Below are screenshots of an example operating system. This example merely displays a gradient and does not process any user input.

## QEMU (floppy disk)

![Latest screenshot of the operating system running in QEMU, booted as a floppy disk](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-master-qemu-system-i386-floppy/qemu-system-i386-floppy.png)

## QEMU (CD-ROM)

![Latest screenshot of the operating system running in QEMU, booted as a CD-ROM](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-master-qemu-system-i386-cdrom/qemu-system-i386-cdrom.png)

## VirtualBox

![Latest screenshot of the operating system running in VirtualBox](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-master-virtualbox/virtualbox.png)

## Bochs

![Latest screenshot of the operating system running in Bochs](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-master-bochs/bochs.png)

## DOSBox (.bat)

![Latest screenshot of the operating system running in dosbox](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-master-dosbox/dosbox.png)

## Unix graphical environment (.sh)

![Latest screenshot of the operating system running in gui-sh](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-master-gui-sh/gui-sh.png)
