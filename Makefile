all: aku-os.iso

aku-os.iso:
	gcc -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -nostartfiles -nodefaultlibs -Wall -Wextra -O2 -c kernel.c -o kernel.o
	as --32 boot.s -o boot.o
	ld -m elf_i386 -T linker.ld -o aku.bin boot.o kernel.o
	mkdir -p iso/boot/grub
	cp aku.bin iso/boot/aku.bin
	cp grub.cfg iso/boot/grub/grub.cfg
	grub-mkrescue -o aku-os.iso iso

clean:
	rm -rf *.o aku.bin aku-os.iso iso
