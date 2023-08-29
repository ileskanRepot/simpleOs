# Simple OS

## How develop
1. Create `build` directory
2. `make` to compile OS
3. `qemu-system-i386 -fda build/main_floppy.img` to launch os in `qemu`

## OS to usb stick
`sudo dd of=/dev/sda if=build/main_floppy.img`

## Tutorial
https://www.youtube.com/watch?v=9t-SPC7Tczc
