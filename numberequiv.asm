;   Executable name         : uppercaser2
;   Version                 : 1.0
;   Created date            : 28 Dec 2018
;   Last update             : 28 Dec 2018
;   Author                  : Brian Hart
;   Description             : A simple program in assembly for Linux, using NASM,
;                             demonstrating simple text file I/O (through redirection) for reading an
;                             input file to a buffer in blocks, forcing lowercase characters to 
;                             uppercase, and writing the modified buffer to an output file.
;
;   Run it this way:
;       uppercaser2 > (output file) < (input file)
;
;   Build using these commands:
;       nasm -f elf64 -g -F stabs uppercaser2.asm
;       ld -o uppercaser2 uppercaser2.o
;
SECTION     .bss                    ; Section contaning uninitialized data

      BUFFLEN equ 1024              ; Length of buffer
      Buff:   resb BUFFLEN          ; Text buffer itself
      
SECTION     .data                   ; Section containing initialized data

SECTION     .text                   ; Section containing code

global      _start

_start:
        nop                         ; This no-op keeps gdb happy...
        
; Read a buffer-full of text from STDIN...
Read:
        mov eax, 3                  ; Specify sys_read call
        mov ebx, 0                  ; Specify File Descriptor 0: Standard Input
        mov ecx, Buff               ; Pass offset of the buffer to read to
        mov edx, BUFFLEN            ; Pass number of bytes to read at one pass
        int 80h                     ; Call sys_read to fill the buffer
        mov esi, eax                ; Copy sys_read return value for safekeeping
        cmp eax, 0                  ; If eax=0, sys_read reached EOF on stdin
        je Done                     ; Jump If Equal (to 0, from compare)
        
; Set up the registers for the process buffer step:
        mov ecx, esi                ; Place the number of bytes read into ECX
        mov ebp, Buff               ; Place the address of the buffer into EBP
        dec ebp                     ; Adjust count to offset
        
; Go through the buffer and convert lowercase to uppercase characters:
Scan:
        cmp byte [ebp+ecx], 61h     ; Test input char against lowercase 'a'
        jb Next                     ; If below 'a' in ASCII chart, not lowercase
        cmp byte [ebp+ecx], 7Ah     ; Test input char against lowercase 'z'
        ja Next                     ; If above 'z' in ASCII chart, not lowercase
                                    ; At this point, we have a lowercase char
        sub byte [ebp+ecx], 20h     ; Subtract 20h to give uppercase...
Next:
        dec ecx                     ; Decrement counter
        jnz Scan                    ; If characters remain, loop back
        
; Write the buffer full of processed text to STDOUT:
Write:    
        mov eax, 4                  ; Specify sys_write call
        mov ebx, 1                  ; Specify File Descriptor 1: Standard Input
        mov ecx, Buff               ; Pass offset of the buffer
        mov edx, esi                ; Pass the # of bytes of data in the buffer
        int 80h                     ; Make sys_write kernel call
        jmp Read                    ; Loop back and load another buffer full
        
; All done! Let's end this party...
Done:
        mov eax, 1                  ; Code for Exit Syscall
        mov ebx, 0                  ; Return a code of zero
        int 80h                     ; Make sys_exit kernel call
        
              
      
