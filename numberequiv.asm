;   Executable name         : numberequiv.asm
;   Version                 : 1.0
;   Created date            : 7 Mar 2019
;   Last update             : 7 Mar 2019
;   Author                  : Brian Hart
;   Description             : A simple program to take two numbers in from the user via the command line
;                             and then tell the user whether they are equal, or whether they are different
;                             from each other; in which case, this program outputs whether the first number
;                             is greater than or less than the second.
;
;   Run it this way:
;       numberequiv > (output file) < (input file)
;
;   Build using these commands:
;       nasm -f elf64 -g -F stabs numberequiv.asm
;       ld -o numberequiv numberequiv.o
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
	; I need to check whether the user has typed a minus sign here
	; but only if we are currently on the first char of the string
	cmp ecx, 1		    ; If ecx=1, check whether current char is minus sign or not	    
	jne Check-for-Digit	    ; Jump if Not Equal so we look for a digit
Check-for-Minus:
	cmp byte [ebp+ecx], 2Dh     ; Test input char against '-'
	jne Next		    ; Skip if not a minus sign
Check-for-Digit:
        cmp byte [ebp+ecx], 30h     ; Test input char against '0'
        jb Error                    ; If below '0' in ASCII chart, not a digit
        cmp byte [ebp+ecx], 39h     ; Test input char against '9'
        ja Error                    ; If above '9' in ASCII chart, not a digit
                                    ; At this point, we have a digit
        sub byte [ebp+ecx], 30h     ; Subtract 30h to give a digit...
	cmp ecx, esi		    ; Check whether we are in the one's place, i.e., ecx == esi
	je Next			    ; Don't waste time multiplying by 1, just skip

	; If we are here, then we aren't on the one's place
	; Figure out the power of 10 to apply to the current
	; digit by finding the difference between the position 
	; of the current digit and esi
	mov edx, ecx		   ; Copy the value currently in ecx to edx
	mov ebx, esi		   ; Copy the value currently in esi (num of chars read) to ebx
	sub esi, edx		   ; Then subtract whatever's in edx from esi and save it in esi
	mov edx, esi		   ; Now put the new value of esi into edx
	mov esi, ebx	           ; restore the old value of esi from ebx

	
	

Transform:

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
        
Error:
	mov eax, -1		    ; Program exit code: -1 for error
	; Done
