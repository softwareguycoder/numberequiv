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

    INPUTONELEN:    resb 4          ; Contains number of bytes of input actually read from STDIN for Value #1
    INPUTTWOLEN:    resb 4          ; Contains number of bytes of input actually read from STDIN for Value #2

    INPUTLEN equ 1024               ; Length of buffer to store user input
    INPUT:   resb INPUTLEN          ; Text buffer itself to store user input

    INPUT2LEN equ 1024              ; Length of buffer to store user input #2
    INPUT2:   resb INPUT2LEN        ; Text buffer itself to store user input #2
    
    OUTPUTLEN equ 1024              ; Length of buffer to store program output
    OUTPUT:  resb OUTPUTLEN         ; Text buffer itself to store user output
     
SECTION     .data                   ; Section containing initialized data

    SYS_WRITE           EQU 4       ; Code for the sys_write syscall
    SYS_READ            EQU 3       ; Code for the sys_read syscall
    SYS_EXIT            EQU 1       ; Code for the sys_exit syscall
    
    STDIN               EQU 0       ; Standard File Descriptor 0: Standard Input
    STDOUT              EQU 1       ; Standard File Descriptor 1: Standard Output
    STDERR              EQU 2       ; Standard File Descriptor 2: Standard Error
    
    EXIT_OK             EQU 0       ; Process exit code for successful termination
    EXIT_ERR            EQU -1      ; Process exit code for a general error condition
    
    STRING_TERMINATOR   EQU 0       ; ASCII Code for '\0' char which is the null 
                                    ; terminator on a character string

    INVALIDVAL: db "ERROR! Invalid value.",10,0  
    INVALIDVALLEN equ $-INVALIDVAL      
    
    VALEQUALMSG: db "Value #1 is equal to Value #2.",10,0
    VALEQUALMSGLEN EQU $-VALEQUALMSG
    
    VALBELOWMSG: db "Value #1 is less than Value #2.",10,0
    VALBELOWMSGLEN EQU $-VALBELOWMSG

    VALABOVEMSG: db "Value #1 is greater than Value #2.",10,0
    VALABOVEMSGLEN EQU $-VALABOVEMSG   
    
    VALPRMPT: db "Please type an integer for Value #1:",10,0
    VALPRMPTLEN EQU $-VALPRMPT

    VALCONF: db "The value #1 inputted was ",0
    VALCONFLEN EQU $-VALCONF

    VAL2PRMPT: db "Please type an integer for Value #2:",10,0
    VAL2PRMPTLEN EQU $-VAL2PRMPT

    VAL2CONF: db "The value #2 inputted was ",0
    VAL2CONFLEN EQU $-VAL2CONF
    
    DONEMSG: db "Process exited with code 0.",10,0
    DONEMSGLEN EQU $-DONEMSG  
    
    LF: db 10,0
    LFLEN EQU $-LF      
    
    PERIOD: db ".",10,0
    PERIODLEN EQU $-PERIOD

SECTION     .text                   ; Section containing code

;------------------------------------------------------------------------------
; DisplayText:          Displays a text string on the screen
; UPDATED:              03/12/2019
; IN:                   ECX = Address of the start of the output buffer
;                       EDX = Count of characters to be displayed
; RETURNS:              Nothing
; MODIFIED:             Nothing
; CALLS:                sys_write via INT 80h
; DESCRIPTION:          Displays whatever text is referenced by ECX and EDX to the
;                       screen.
;
DisplayText:
    push eax                        ; Save caller's EAX
    push ebx                        ; Save caller's EBX
    mov eax, SYS_WRITE              ; Specify sys_write syscall
    mov ebX, STDOUT                 ; Specify File Descriptor 1: Standard Output
    int 80h                         ; Make kernel call; assume ECX and EDX already initialized
    pop ebx                         ; Restore caller's EBX
    pop eax                         ; Restore caller's EAX
    ret                             ; Return to caller
    
;------------------------------------------------------------------------------
; ValidateNumericInput: Validates that user input is indeed a number.
; UPDATED:              03/13/2019
; IN:                   ESI = Count of characters of user input
;                       EDI = Address of user input buffer
; RETURNS:              Nothing
; MODIFIED:             Nothing
; CALLS:                Nothing
; DESCRIPTION:          Validates the contents of the user input buffer to ensure
;                       that the contents of said buffer are parsable as a positive
;                       or negative integer.  If not, then jumps to this program's
;                       ERROR label; if so, then the function simply returns control
;                       to the caller.
ValidateNumericInput:
    pushad                          ; Save all 32-bit GP registers
    xor eax, eax                    ; Clear EAX to be zero
    xor ebx, ebx                    ; Clear EBX to be zero
    xor ecx, ecx                    ; Clear ECX to be zero
    xor edx, edx                    ; Clear EDX to be zero
    .Scan:
        cmp byte [edi+ecx], 0       ; Test input char for null-terminator
        je .Next                    ; Skip to next char if so
        cmp byte [edi+ecx], 0Ah     ; Test input char for null-terminator
        je .Next                    ; Skip to next char if so
        cmp byte [edi+ecx], 20h     ; Test input char for a nonprinting char
        jna Error                   ; All nonprinting chars are invalid
        cmp byte [edi+ecx], 2Dh     ; Test input char for hyphen (might be a minus sign)
        je .mightBeMinus            ; If currentChar == '-' then test whether it's the first char
        cmp byte [edi+ecx], 2Ch     ; Test input char for a thousands separator (comma)
        je .Next                    ; Ignore commas
        cmp byte [edi+ecx], 2Eh     ; Test input char for a decimal point
        je Error                    ; Invalid value; floating-point numbers not supported
        cmp byte [edi+ecx], 30h     ; Test input char against '0'
        jb Error                    ; If below '0' in ASCII chart, not a digit
        cmp byte [edi+ecx], 39h     ; Test input char against '9'
        ja Error                    ; If above '9' in ASCII chart, not a digit
        jmp .Next                   ; Skip to Next iteration now, because we are good to go
        .mightBeMinus:
            cmp ecx, 0              ; Check whether ECX==0, i.e., we are on the first iteration
            jne Error               ; If ECX != 0 and we are here, a hyphen occurred in the middle of the input
        .Next:
            inc ecx                 ; Like i++; increment our loop counter
            cmp ecx, esi            ; Is ecx==esi?
            jne .Scan               ; If ecx!=esi, then loop to next iteration  
    .Done:        
        popad                       ; Restore all 32-bit GP registers
    ret 
  
;------------------------------------------------------------------------------
; GetText:              Reads in text from user input
; UPDATED:              03/12/2019
; IN:                   ECX = Address of the start of the output buffer
;                       EDX = Count of characters to be displayed
; RETURNS:              Nothing
; MODIFIED:             EAX contains number of bytes read (including carriage return)
; CALLS:                sys_write via INT 80h
; DESCRIPTION:          Reads user input from screen into a buffer
;
GetText:
    push ebx                        ; Save caller's EBX
    mov eax, SYS_READ               ; Specify sys_read syscall
    mov ebX, STDIN                  ; Specify File Descriptor 0: Standard Input
    int 80h                         ; Make kernel call; assume ECX and EDX already initialized
    pop ebx                         ; Restore caller's EBX
    ret                             ; Return to caller

;------------------------------------------------------------------------------
; StringToInt:          Sets the value of EAX to the numeric value corresponding
;                       to the number represented by an ASCII string
; UPDATED:              03/12/2019
; IN:                   ESI = count of chars of user input, including '\n' if any
;                       EDI = Address of the start of the user input
; RETURNS:              Numeric value in EAX
; MODIFIED:             EAX
; CALLS:                ValidateNumericInput
; DESCRIPTION:          Assuming the user typed in a whole number that is
;                       strictly less than 2,147,483,647, or strictly greater
;                       than -2,147,483,649, converts this number into
;                       the actual int value and stores this value in EAX.
StringToInt:
    push ebx                        ; Save caller's EBX
    push ecx                        ; Save caller's ECX
    push edx                        ; Save caller's EDX
    call ValidateNumericInput              ; Validate the user input
    xor eax, eax                    ; Clear EAX to be zero
    xor ebx, ebx                    ; Clear EBX to be zero
    xor ecx, ecx                    ; Clear ECX to be zero
    xor edx, edx                    ; Clear EDX to be zero    
    .Scan:
        cmp byte [edi+ecx], 0Ah     ; Check for newline
        je .Next
        cmp byte [edi+ecx], '-'     ; Check for hyphen; if present, might be a neg number
        je .mightBeMinus            ; If a hyphen is the current char, ask is hyphen in the first slot? if so, might be a neg. number
        sub byte [edi+ecx], '0'     ; Convert from ASCII to digit
        movzx edx, byte [edi+ecx]   ; Put the value of the current digit into DL
        imul eax, 10                ; Multiply EAX by 10 (signed), so as to get the power of 10 to use
        add eax, edx                ; EAX = EAX*10 + EDX
        jmp .Next                   ; Go to .Next label to skip the .mightBeMinus block
        .mightBeMinus:
            cmp ecx, 0              ; Check whether ECX==0, i.e., we are on the first iteration
            jne Error               ; If ECX != 0 and we are here, a hyphen occurred in the middle of the input
            mov ebx, 1              ; Set EBX = 1 (EBX == 'BOOL bIsNegative') and fall down to .Next
        .Next:                      ; Check whether it's safe to loop again
            inc ecx                 ; Like i++; increment our loop counter
            cmp ecx, esi            ; Is ecx==esi?
            jne .Scan               ; If ecx!=esi, then loop to next iteration
    .askIsNegative:                 ; Check whether the value that's now in EAX is supposed to be a negative number
        cmp ebx, 1                  ; Check whether EBX == 1, if so then that means we are supposed to have a negative number in EAX
        jne .Done                   ; If EBX != 1 then we are done
        neg eax                     ; If we are still here then make the value in EAX a negative quantity (two's complement)
    .Done:        
        pop edx                         ; Restore caller's EDX
        pop ecx                         ; Restore caller's ECX
        pop ebx                         ; Restore caller's EBX
    ret                             ; Return to caller; desired number is in EAX
    
global      _start

_start:
        nop                         ; This no-op keeps gdb happy...

; Prompt for value #1
PromptForValue1:
        mov ecx, VALPRMPT           ; Address of message buffer
        mov edx, VALPRMPTLEN        ; Length of message
        call DisplayText
        
ReadValue1:
        mov ecx, INPUT              ; Address of input buffer
        mov edx, INPUTLEN           ; Size of input buffer
        call GetText                ; Get the text typed by the user        
        mov [INPUTONELEN], eax      ; Save the number bytes read in EAX to INPUTONELEN storage
        mov esi, eax                ; Copy the value that is currently in EAX to ESI
        mov edi, INPUT              ; Copy the address of INPUT to EDI
        call ValidateNumericInput          ; Validate the user input
        
EchoValue1:
        mov ecx, VALCONF            ; Address of value confirmation message
        mov edx, VALCONFLEN         ; Length of message
        call DisplayText
        
        mov ecx, INPUT              ; Address of input buffer
        mov edx, INPUTLEN           ; Length of message
        call DisplayText           
        
PromptForValue2:
        mov ecx, VAL2PRMPT          ; Address of message buffer
        mov edx, VAL2PRMPTLEN       ; Length of message
        call DisplayText

ReadValue2:
        mov ecx, INPUT2             ; Address of input buffer
        mov edx, INPUT2LEN          ; Size of input buffer
        call GetText                ; Get the text typed by the user
        mov [INPUTTWOLEN], eax      ; Save the value that is currently in EAX to INPUTTWOLEN storage
        
EchoValue2:
        mov ecx, VAL2CONF           ; Address of value confirmation message
        mov edx, VAL2CONFLEN        ; Length of message
        call DisplayText
        
        mov ecx, INPUT2             ; Address of input buffer
        mov edx, INPUT2LEN          ; Length of message
        call DisplayText            ; Display the message
        
ConvertValues:
        mov esi, [INPUTONELEN]      ; Copy the length of Value #1 input into ESI
        lea edi, [INPUT]            ; Copy the address of INPUT into EDI
        call StringToInt            ; Call to convert to string to integer
        
        mov ebp, eax

        mov esi, [INPUTTWOLEN]      ; Copy the length of Value #2 input into ESI
        lea edi, [INPUT2]           ; Copy the address of INPUT2 into EDI
        call StringToInt            ; Call to convert string to integer
        
        cmp ebp, eax
        je PrintEqual
        jl PrintBelow
        jg PrintAbove
        
PrintEqual:
        mov ecx, VALEQUALMSG        ; Address of message
        mov edx, VALEQUALMSGLEN     ; Message length
        call DisplayText            ; Display the message
        jmp Done                    ; Finished with this program

PrintAbove:
        mov ecx, VALABOVEMSG        ; Address of message
        mov edx, VALABOVEMSGLEN     ; Message length
        call DisplayText            ; Display the message
        jmp Done
        
PrintBelow:
        mov ecx, VALBELOWMSG        ; Address of message
        mov edx, VALBELOWMSGLEN     ; Message length
        call DisplayText            ; Display the message
        jmp Done
               
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
