CFLAGS=-m32 -ffreestanding -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -nostdlib -nostartfiles -nodefaultlibs -Wall -Wextra -O2

all: aku-os.iso

aku-os.iso:
	gcc $(CFLAGS) -c kernel.c -o kernel.o
	gcc $(CFLAGS) -c hardware.c -o hardware.o
	gcc $(CFLAGS) -c process.c -o process.o
	as --32 boot.s -o boot.o
	ld -m elf_i386 -T linker.ld -o aku.bin boot.o kernel.o hardware.o process.o
	mkdir -p iso/boot/grub
	cp aku.bin iso/boot/aku.bin
	cp grub.cfg iso/boot/grub/grub.cfg
	grub-mkrescue -o aku-os.iso iso

clean:
	rm -rf *.o aku.bin aku-os.iso iso
