;   Executable name         : numberequiv.asm
;   Version                 : 2.0
;   Created date            : 7 Mar 2019
;   Last update             : 8 Mar 2019
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
;       nasm -f elf -g -F stabs numberequiv.asm -l numberequiv.lst
;        ld -m elf_i386 -s -o numberequiv numberequiv.o
;
SECTION     .bss                    ; Section contaning uninitialized data

    INPUTLEN equ 1024               ; Length of buffer to store user input
    INPUT:   resb INPUTLEN          ; Text buffer itself to store user input
     
SECTION     .data                   ; Section containing initialized data

    SYS_WRITE   EQU 4               ; Code for the sys_write syscall
    SYS_READ    EQU 3               ; Code for the sys_read syscall
    SYS_EXIT    EQU 1               ; Code for the sys_exit syscall
    
    STDIN       EQU 0               ; Standard File Descriptor 0: Standard Input
    STDOUT      EQU 1               ; Standard File Descriptor 1: Standard Output
    STDERR      EQU 2               ; Standard File Descriptor 2: Standard Error
    
    EXIT_OK     EQU 0               ; Process exit code for successful termination
    EXIT_ERR    EQU -1              ; Process exit code for a general error condition

    INVALIDVAL: db "ERROR! Invalid value.",10,0  
    INVALIDVALLEN equ $-INVALIDVAL      
    
    DONEMSG: db "Ding!",10,0
    DONEMSGLEN EQU $-DONEMSG         

SECTION     .text                   ; Section containing code

global      _start

_start:
        nop                         ; This no-op keeps gdb happy...
        
; Read a buffer-full of text from STDIN...
Read:
        ; A note -- the sys_read call always reports the number of chars the user typed + 1 (for the newline
        ; that is entered when the user presses the ENTER key.  If we are instead feeding in a textfile on 
        ; STDIN from, say, a redirect, then the exact number of chars in the text file (or every chunk of BUFFLIN chars)
        ; will be reported as read

        mov eax, SYS_READ           ; Specify sys_read call
        mov ebx, STDIN              ; Specify File Descriptor 0: Standard Input
        mov ecx, INPUT              ; Pass offset of the buffer to read to
        mov edx, INPUTLEN           ; Pass number of bytes to read at one pass
        int 80h                     ; Call sys_read to fill the buffer
        mov esi, eax                ; Copy sys_read return value for safekeeping
        cmp eax, 0                  ; If eax=0, sys_read reached EOF on STDIN        
        je Done                     ; Jump If Equal (to 0, from compare)
        
; Set up the registers for the process buffer step:
        mov ecx, esi                ; Place the number of bytes read into ECX
        mov ebp, INPUT               ; Place the address of the buffer into EBP
        dec ebp                     ; Adjust count to offset

; Go through the buffer and convert lowercase to uppercase characters:
Scan:
        xor ebx, ebx                ; Clear EBX
        cmp ecx, 0                  ; Have we finished? If so, then don't move off the rez!
        je Done                     ; If ecx == 0 then goto Done
	                                ; I need to check whether the user has typed a minus sign here
                                    ; but only if we are currently on the first char of the string
        cmp ecx, 1                  ; If ecx=1, check whether current char is minus sign or not	    
        jne CheckForDigit           ; Jump if Not Equal so we look for a digit
CheckForMinus:
	    cmp byte [ebp+ecx], 2Dh         ; Test input char against '-'
	    jne Next		                ; Skip if not a minus sign
CheckForDigit:
        cmp byte [ebp+ecx], 30h     ; Test input char against '0'
        jb Error                    ; If below '0' in ASCII chart, not a digit
        cmp byte [ebp+ecx], 39h     ; Test input char against '9'
        ja Error                    ; If above '9' in ASCII chart, not a digit
                                    ; At this point, we have a digit
        sub byte [ebp+ecx], '0'     ; Convert from ASCII to digit
        imul ebx,10                 ; Multiply ebx by 10 (signed), so as to get the power of 10 to use
        movzx eax, byte [ebp+ecx]   ; Put the value of the current digit into EAX with zeroes
        add ebx,eax                 ; ebx = ebx*10 + eax
        jmp Next                    ; On to next loop iteraion
Transform:

Next:
        dec ecx                     ; Decrement counter
        jnz Scan                    ; If characters remain, loop back
        mov eax, ebx                ; Put the numeric value into EAX
; numeric value is now in eax
        jmp Write
; Write the buffer full of processed text to STDOUT:
Write:    
        ; If we are here, we have a value in EAX that is the number the user typed in
        ; Now, let's convert that value into a string and display it

        mov eax, SYS_WRITE          ; Specify sys_write syscall
        mov ebx, 1                  ; Specify File Descriptor 1: Standard Input
        mov ecx, INPUT              ; Pass offset of the buffer
        mov edx, esi                ; Pass the # of bytes of data in the buffer
        int 80h                     ; Make sys_write kernel call
        jmp Read                    ; Loop back and load another buffer full

; All done! Let's end this party...
Done:
        mov eax, SYS_WRITE          ; Specify sys_write syscall
        mov ebx, STDOUT             ; Specify Standard File Descriptor 1: Standard Output
        mov ecx, DONEMSG            ; Address of message to display
        mov edx, DONEMSGLEN         ; Length of the message
        int 80h                     ; Make kernel call

        mov eax, SYS_EXIT           ; Code for Exit Syscall
        mov ebx, EXIT_OK            ; Return a code of zero
        int 80h                     ; Make sys_exit kernel call
        
Error:
        mov eax, SYS_WRITE          ; Specify sys_write syscall
        mov ebx, STDOUT             ; Specify Standard File Descriptor 1: Standard Output
        mov ecx, INVALIDVAL         ; Address of message to display
        mov edx, INVALIDVALLEN      ; Length of the message
        int 80h                     ; Make kernel call

; Because we arrived here at the Error label, and we've told the user that they
; are not doing things correctly, we need to shut this whole thing down and with
; a system exit code of -1.  No reason it is -1 per se, just our choice.

        mov eax, SYS_EXIT           ; Code for Exit Syscall
        mov ebx, EXIT_ERR           ; Return a code of -1 for error
        int 80h                     ; Make sys_exit kernel call
