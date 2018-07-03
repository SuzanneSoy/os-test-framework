# Travis test harness for hobby operating systems

This Travis configuration runs an operating system in various emulators. It can execute a SikuliX test script to ensure that some elements are visible on-screen, send keystrokes and mouse events, and interact with the OS GUI in an automated way. Finally, it will take screenshots of the operating system, and upload them to a separate repository hosting these artifacts.

Below are screenshots of an example operating system. This example merely displays a gradient and does not process any user input.

## QEMU

![Latest screenshot of the operating system running in QEMU](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-qemu-system-i386/qemu-system-i386.png)

## VirtualBox

![Latest screenshot of the operating system running in VirtualBox](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-virtualbox/virtualbox.png)

## Bochs

![Latest screenshot of the operating system running in Bochs](https://raw.githubusercontent.com/jsmaniac/travis-os-deploy-artifacts/screenshots-bochs/bochs.png)
