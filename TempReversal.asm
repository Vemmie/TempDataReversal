TITLE String Primitives and Macros     (TempReversal.asm)

; Author: Francis Truong
; Description: 
; This program will have 3 macros and 2 procedures! It will take the users input and
; open a file to then read from it to be placed into a buffer string. That string will
; then be parsed from string to signed intergers. Those parsed values will be stored
; in a temporary array which will be printed backwards. The 3 macros are used for getting
; uservalue, printing string, and print characters. which will be in the procedures.
; Procedure will contain the logic to parse and then print out the arrays.

INCLUDE Irvine32.inc
;-------------------------------------------------------------------------------------
; Name: mGetString macro
;
; Display prompts and get user input
; Precoditions: N/A
;
; Receives:
;	promptStrOffset = address of prompt string to display
;	userInputOffset = address of the userInput array to store input
;	sizeOfInput = the size of the userInput array
;	numOfBytesRead = this is where the number of bytes would be stored
;
; Returns: numOfBytesRead
;-------------------------------------------------------------------------------------
mGetString MACRO promptStrOffset, userInputOffset, sizeOfInput, bytesRead	
	; using mDisplayString to print out the string
	mDisplayString promptStrOffset

	; this will read the string of the user with the preconditions of the offset and size
	; then it will store the number of bytes read in the postcodition
	mov	EDX, userInputOffset
	mov	ECX, sizeOfInput
	call	ReadString
	mov	bytesRead, EAX
ENDM
;-------------------------------------------------------------------------------------
; Name: mDisplayString macro
;
; Will display the string that is recieved as an argument
; Precoditions: N/A
;
; Receives:
;	stringOffset = address of the string to be printed
;
; Returns: N/A
;-------------------------------------------------------------------------------------
mDisplayString MACRO stringOffset
	; moves the offset of the string to be printed
	mov	EDX, stringOffset
	call	WriteString
ENDM
;-------------------------------------------------------------------------------------
; Name: mDisplayChar macro
;
; Will print an ASCII-formatted character  (input; immediate, constant, or register)
; Precoditions: N/A
;
; Receives:
;	stringOffset = address of the string to be printed
;
; Returns: N/A
;-------------------------------------------------------------------------------------
mDisplayChar MACRO char
	; moves the char into
	mov	AL, char
	call	WriteChar
ENDM

; Constants
TEMP_PER_DAY = 24
DELIMITER = ','
BUFFER_SIZE = 5000
INPUT_SIZE = 100

.data
; string
welcomePrompt	BYTE	"Welcome to the intern error-corrector! I'll read a ','-delimited file storing a series of temperature values.", 10, 13
					BYTE	"The file must be ASCII-formatted. I'll then reverse the ordering and provide the corrected temperature", 10, 13
					BYTE	"ordering as a printout!", 10, 13
					BYTE	"Enter the name of the file to be read: ", 0
resultPrompt	BYTE	"Here's the corrected temperature order!", 10, 13, 0
goodbyePrompt	BYTE	"Hope that helps resolve the issue, goodbye! ", 0 

; arrays
userInput		BYTE	INPUT_SIZE Dup(?)
fileBuffer		BYTE	BUFFER_SIZE Dup(?)
tempArray		SDWORD TEMP_PER_DAY Dup(?)

; numbers
negFlag			DWORD	 ?
inputLength		DWORD	 ?
tempValue		SDWORD ?

.code
main PROC

; this PROC will parse the string
push OFFSET inputLength	
push OFFSET userInput
push OFFSET welcomePrompt

push OFFSET tempValue
push OFFSET negFlag
push OFFSET tempArray
push OFFSET	fileBuffer
call ParseTempFromString

; this will print out the array in reverse
push OFFSET goodbyePrompt
push OFFSET	resultPrompt
push OFFSET tempArray
call WriteTempsReverse

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;-------------------------------------------------------------------------------------
; Name: ParseTempFromString
;
; Description: This does the bulk of the program. It calls the mGetString Macro
; that prints out the prompt and gets the string from the user. It then opens
; and loads the file for it to be read and stored in the file buffer. The 
; file buffer is then parsed through using LODSB which will continue the loop
; untill it hits the end of the string loaded which is just a null terminator.
; Finally the program parses the string and stores the value into a temp array.
;
; Preconditions: file must be in the same directory as project, definited delimiter,
; and enoguh storage for the bugger size and tempArray 
;
; Postconditions: tempArray is filled out and stack is handled
;
; Receives:
;		[EBP + 32] = lenght of userinput value
;		[EBP + 28] = userInput offset
;		[EBP + 24] = welcomePrompt offset
;		[EBP + 20] = OFFSET tempValue
;		[EBP + 16] = negFlag offset
;		[EBP + 12] = tempArray offset
;		[EBP + 8] =  fileBuffer offset
;		[EBP + 4] = return address
;		[EBP] = old ebp
;
; returns: tempArray
;-------------------------------------------------------------------------------------
ParseTempFromString PROC
	push	ebp
	mov	ebp, esp

	; This is for the macro and opening the file
	; [EBP + 32] = lenght of userinput value
	; [EBP + 28] = userInput offset
	; [EBP + 24] = welcomePrompt offset

	; using mGetString Macro
	mov eax, INPUT_SIZE
	dec eax
	mGetString [ebp + 24], [ebp + 28], eax, [ebp + 32]
	call CrLf

	; opening the file 
	mov	edx, [ebp + 28]		; offset userInput 
	call	OpenInputFile
	; reading from the file
	mov	edx, [ebp + 8]			; offset filebuffer
	mov	ecx, BUFFER_SIZE		; constant of buffer size global
	call	ReadFromFile

	; [EBP + 20] = OFFSET tempValue
	; [EBP + 16] = negFlag offset
	; [EBP + 12] = tempArray offset
	; [EBP + 8] =  fileBuffer offset
	; [EBP + 4] = return address
	; [EBP] = old ebp

	; moves fileBuffer into esi to be use LODSB
	; edi will be the location of the values to be stored after parsing
	mov	esi, [ebp + 8]
	mov	edi, [ebp + 12]

	; initializes edx to be 0 beceause it starts as a single digit
	; (which is used in the math to hold any digit after the first one)
	mov	edx, 0
	; in a sense a for loop that goes through the temp string for every char in temp
	_forCharInTemp:
		; this parses the values
		_toNextChar:
			LODSB
			; if it hits the end which is the null value it will break from the loop
			cmp	al, 0
			je _break

			; if it is negative it will jmp to isNeg
			cmp al, '-'
			je	_isNeg

			; if it is the delimiter jmp to isComma
			cmp al, DELIMITER
			je _isComma

			; these 2 check if it is a number
			cmp al, '0'
			jb _toNextChar
			cmp al, '9'
			ja _toNextChar

			; if not any of the above it is a number!
			sub	al, '0'					; this converts it to the appropriate ASCII integer by subtracting '0'
			movzx ebx, al					; converts the al 8 bit to 32 bits

			mov	eax, 10					; moves 10 to adjust placement later
			mul	edx						; multiple with the previous digit (greatest digit if not single digit otherwise it will return 0)
			mov	edx, eax					; moves the result into edx to use if there are more than one digit
			add	edx, ebx					; adds the current read value to the previous value
			
			mov	ebx, [EBP + 20]		; mov the temp offset into ebx
			mov	[ebx], edx				; store the calculated value into the dereferenced offset
			jmp	_toNextChar
	LOOP _forCharInTemp

	jmp _break								; after the loop is finished

	; this updates are custom flag to show that the current value is negative
	_isNeg:
		mov	ebx, [EBP + 16]
		mov	byte ptr [ebx], 1
		jmp	_toNextChar

	; isComma stores the tempValue into the array
	; if it is negative it jmps to makeNeg
	_isComma:
		mov	ebx, [EBP + 16]
		mov	edx, [EBP + 20]
		mov	eax, [edx]					; moves the temp value into eax
		cmp	byte ptr [ebx], 1			; checks if it is negative
		je		_makeNeg
		_continue:
		mov	[edi], eax				   ; moves the temp value into temp array
		add	edi, 4						; increments it by 4 to go to the next slot because it is a SDWORD (4)

		mov	byte ptr [ebx], 0			; this just sets the negative flag back to false which is 0
		mov	edx, 0						; resetting EDX which is the placement holder mentioned before _forCharInTemp

		jmp	_toNextChar
	
	; make Neg makes the value inserted negative
	_makeNeg:
		neg  eax
		jmp	_continue					; jumps back to continue isComma

	_break:				
		pop ebp								; restores the stack
		ret 28
ParseTempFromString ENDP

;-------------------------------------------------------------------------------------
; Name: WriteTempsReverse
;
; Description: prints out the temp Array in reverse!
;
; Preconditions: tempArray needs to be filled out / intialized
;
; Postconditions: the strings and array will be displayed properly
;
; Receives:
;		[EBP + 16] = goodbye string offset
;		[EBP + 12] = result string offset
;		[EBP + 8] =  tempArray offset
;		[EBP + 4] = return address
;		[EBP] = old ebp
;
; returns: N/A
;-------------------------------------------------------------------------------------
WriteTempsReverse PROC
	push	ebp
	mov	ebp, esp
	; [EBP + 16] = goodbye string offset
	; [EBP + 12] = result string offset
	; [EBP + 8] = tempArray offset
	; [EBP + 4] = return address
	; [EBP] = old ebp

	; moves the tempArray offset into esi to deference later
	mov	esi, [EBP + 8]

	; this math basically takes the amount of days minus - 1 and muliply that with 4 to go to the end of the array
	mov	eax, 4
	mov	ebx, TEMP_PER_DAY-1
	mul	ebx
	; this is the counter which should be 23 * 4
	mov	ecx, eax
	; this makes it go back to the end of the array
	add	esi, ecx

	; prints out result string
	mDisplayString	[EBP + 12]

	; this is the printing loop
	_printLoop:
		mov	eax, [esi]
		call	WriteInt
		mDisplayChar DELIMITER
		sub	esi, 4
		sub	ecx, 4
		cmp	ecx, 0
		jge	_printLoop

	; spacing
	call CrLf
	call CrLf

	; prints out the goodbye string
	mDisplayString	[EBP + 16]

	; restores the stack
	pop ebp
	ret 12
WriteTempsReverse ENDP

END main
