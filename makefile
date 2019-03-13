numberequiv: numberequiv.o
	ld -m elf_i386 -o numberequiv numberequiv.o
numberequiv.o: numberequiv.asm
	nasm -f elf -F dwarf -g numberequiv.asm -l numberequiv.lst
clean:
	rm -f *.o *.lst numberequiv
