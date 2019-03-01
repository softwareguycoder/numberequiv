numberequiv: numberequiv.o
	ld -o numberequiv numberequiv.o
numberequiv.o: numberequiv.asm
	nasm -f elf64 -g -F stabs numberequiv.asm -l numberequiv.lst
clean:
rm -f *.o *.lst numberequiv
