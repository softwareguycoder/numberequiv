numberequiv: numberequiv.o
	ld -m elf_i386 -s -o numberequiv numberequiv.o
numberequiv.o: numberequiv.asm
	nasm -f elf -g -F stabs numberequiv.asm -l numberequiv.lst
clean:
	rm -f *.o *.lst numberequiv
