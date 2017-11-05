#############################################################
# tazzaoui
#
# Tokenizer: split up input into 8 word-tokens of
#	     the same type
# 
#############################################################
		
				
			.data
TOKEN:		.space		8				# .word 0,0
Tokens:		.word		0:30				# 10*(2-word Token, type)	
headerOne:	.asciiz		"Token           Token Type\n"	
headerTwo:	.asciiz		"---------------------------\n"
st_prompt:	.asciiz		"Enter a new input line. \n"	
spaceSeparator: .asciiz		"          " 			# Ten spaces to seperate token & type
inBuf:		.space 		80				# input buffer (80 bytes)
		
		.text

# Use $s0 and $s1 to hold the value of T and CUR 
main:
		li 	$s5, 0		# numTokens = 0	
newLine:
		jal	getline		# goto getline
		li 	$s7, 0		# index used to traverse inBuf
		li 	$s6, 8		# tokSpace = 8
		la	$s1, Q0		# cur = Q0
		li	$s0, 1		# T = 1

nextState:	
		lw	$s2, 0($s1)	# act = stab[cur][0]
		jalr	$v1, $s2	# call act

		sll	$s0, $s0, 2	# Multiply by 4 for word boundary
		add	$s1, $s1, $s0	# newQ = Q + T
		sra	$s0, $s0, 2	
		lw	$s1, 0($s1)	# cur = stab[cur][T]
		
		#bge	$s5, 10 ERROR	# More than 10 tokens...error
		
		b 	nextState
		
outLine:	
		li	$v0,4
		la	$a0, headerOne
		syscall
		
		la	$a0, headerTwo
		syscall
		
		# print token table
		li	$t1, 0	# loop index = 0
		li	$t2, -1	# byte index = 0
		li 	$v0, 11 # code to print char
forloop:
		#word 1
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		
		#word2
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 1
		lb	$a0, Tokens($t2)
		syscall
		
		li	$v0,4
		la	$a0, spaceSeparator
		syscall
		
		#word3 = type
		li	$v0, 1 			
		addi 	$t2, $t2, 1
		lw	$a0, Tokens($t2)
		syscall
		addi 	$t2, $t2, 3
		
		li  $v0, 11
		li  $a0, '\n'
		syscall
		
		addi $t1, $t1, 1		# Tokens printed count++
		
		beq  $t1, $s5, doneLooping	# Return if we've printed all the tokens
		
		b forloop
doneLooping:		
		li	$a0, '\n'		# print newline
		li	$v0, 11			# 4 = call code to print string
		syscall
		
		# clear inBuf
		jal clearInBuff
		# clear token table
		jal clearTokTable
		b main

ACT1:
	lb	$t1, inBuf($s7)		# curChar = get next char
	
	jal	lin_search		# s0 holds T and s4 holds currCHar after this is run..
	move	$a1, $s4		# s0 
	
	addi 	$s7, $s7, 1		# inBuffIndex++
	
	jr $v1

ACT2:
	la	$t1, TOKEN
	sb	$a1, 0($t1)		# TOKEN = currChar
	li 	$s6, 7			# tokSpace = 7
	
	jr 	$v1
	
ACT3:
	li	$t2, 8
	sub	$t3, $t2, $s6		# index = 8 - tokIndex
	sb	$s4, TOKEN($t3)		# TOKEN = TOKEN + curChar  
	addi 	$s6, $s6, -1		# tokSpace --
	
	ble	$s6,-1,ACT4
	
	jr $v1
ACT4:
	#Byte offset = numTokens + 2*numTokens
	
	mul	$t4, $s5, 12		# 12 * tokenNo gets me to my BIT offset 
	li	$t3, 0			
	
	lw	$t2, TOKEN($t3)		
	sw	$t2, Tokens($t4)
	
	lb	$t1, Tokens($t4)	# Load first char into arg reg
	
	addi	$t4, $t4, 4		
	addi	$t3, $t3, 4
	
	lw	$t2, TOKEN($t3)		# load token[1]
	sw	$t2, Tokens($t4)	# Store second token word in tokens
	

	addi	$t4, $t4, 4		# Tokens index++
	jal 	lin_search
	sw	$s0, Tokens($t4)	# Store type
	
	addi 	$s5, $s5, 1		# tokenNum++
	
	# Now we need to clear TOKEN
	la $t6, TOKEN
	li $t3, ' '
	
	sb, $t3, 0($t6)
	sb, $t3, 1($t6)
	sb, $t3, 2($t6)
	sb, $t3, 3($t6)
	sb, $t3, 4($t6)
	sb, $t3, 5($t6)
	sb, $t3, 6($t6)
	sb, $t3, 7($t6)
	
	ble	$s6,-1,ACT3	
	
	jr $v1
ERROR:
	b EXIT
RETURN:
	jal outLine
EXIT:
	li $v0,10
	syscall


###########
#
#   lin_search
#	argument: key - $t1
#	return char type: in $a0 CHANGED TO S4
#
############

lin_search:
	li	$a0, -1			# index = -1
	li	$s3, 0			# i = 0
	
chkChar:
	bge	$s3, 75, ret
	
	sll	$s3, $s3, 3		# C index i to byte offset in multiples of 8
	lb	$s4, Tabchar($s3)	# $s1 - Tabchar(i, 0)
	sra	$s3, $s3, 3		# restore to C index

	bne	$s4, $t1, nextChar	
	
	sll	$s3, $s3, 3
	lw	$s0, Tabchar+4($s3)	# index = Tabchar(i, 1)THIS IS WHERE CHARTYPE IS STORED
	sra	$s3, $s3, 3
	
	#addi	$s0, $s0, 0x30		# Make proper ascii value
	b	ret
	
nextChar:
	addi	$s3, $s3, 1		# i++
	b	chkChar

ret:	
	jr	$ra

getline: 
	# Prompt the user for input
	la	$a0, st_prompt		# Load Addr of string into argument register
	li	$v0, 4			# 4 = call code to print string
	syscall
	
	# Read the user's input
	la	$a0, inBuf		# Load Addr of inBuff --> for storing user's input
	li	$a1, 80			# Maximum length of text = 80 bytes
	li	$v0, 8			# 8 = call code to get userInput as text...
	syscall

	li	$a0, '\n'		# print newline
	li	$v0, 11			# 4 = call code to print string
	syscall
	
	jr	$ra			# Jump and return to the return addr

clearInBuff:
	la	$t1, inBuf		
	li	$t2, 0			# i = 0 index for traversing input Buffer
	
loopClearInBuff:
	sb	$0, inBuf($t2)		# store nullbyte in at inBuff[i]
	addi	$t2, $t2, 1		# i++
	
	bge	$t2, 80, done 		# if(i >= 80) break...
	b	loopClearInBuff		
done:
	jr $ra

clearTokTable:
	la	$t1, Tokens
	li	$t2, 0
loopClearTokTable:
	sw	$0, Tokens($t2)
	addi	$t2, $t2, 4
	bge	$t2, 120, doneClearTokTable
	b	loopClearTokTable
doneClearTokTable:
	jr	$ra


	
		.data
STAB:
Q0:     .word  ACT1
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q10  # T7

Q1:     .word  ACT2
        .word  Q2   # T1
        .word  Q5   # T2
        .word  Q3   # T3
        .word  Q3   # T4
        .word  Q0   # T5
        .word  Q4   # T6
        .word  Q10  # T7

Q2:     .word  ACT1
        .word  Q6   # T1
        .word  Q7   # T2
        .word  Q7   # T3
        .word  Q7   # T4
        .word  Q7   # T5
        .word  Q7   # T6
        .word  Q10  # T7

Q3:     .word  ACT4
        .word  Q0   # T1
        .word  Q0   # T2
        .word  Q0   # T3
        .word  Q0   # T4
        .word  Q0   # T5
        .word  Q0   # T6
        .word  Q10  # T7

Q4:     .word  RETURN
        .word  Q4   # T1
        .word  Q4   # T2
        .word  Q4   # T3
        .word  Q4   # T4
        .word  Q4   # T5
        .word  Q4   # T6
        .word  Q10  # T7

Q5:     .word  ACT1
        .word  Q8   # T1
        .word  Q8   # T2
        .word  Q9   # T3
        .word  Q9   # T4
        .word  Q9   # T5
        .word  Q9   # T6
        .word  Q10  # T7

Q6:     .word  ACT3
        .word  Q2   # T1
        .word  Q2   # T2
        .word  Q2   # T3
        .word  Q2   # T4
        .word  Q2   # T5
        .word  Q2   # T6
        .word  Q10  # T7

Q7:     .word  ACT4
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q10  # T7

Q8:     .word  ACT3
        .word  Q5   # T1
        .word  Q5   # T2
        .word  Q5   # T3
        .word  Q5   # T4
        .word  Q5   # T5
        .word  Q5   # T6
        .word  Q10  # T7

Q9:     .word  ACT4
        .word  Q1  # T1
        .word  Q1  # T2
        .word  Q1  # T3
        .word  Q1  # T4
        .word  Q1  # T5
        .word  Q1  # T6
        .word  Q10  # T7

Q10:    .word  ERROR 
        .word  Q4   # T1
        .word  Q4   # T2
        .word  Q4   # T3
        .word  Q4   # T4
        .word  Q4   # T5
        .word  Q4   # T6
        .word  Q4  # T7

Tabchar: 
	.word 0x0a, 6		# LF
	.word ' ', 5
 	.word '#', 6
	.word '$', 4
	.word '(', 4 
	.word ')', 4 
	.word '*', 3 
	.word '+', 3 
	.word ',', 4 
	.word '-', 3 
	.word '.', 4 
	.word '/', 3 

	.word '0', 1
	.word '1', 1 
	.word '2', 1 
	.word '3', 1 
	.word '4', 1 
	.word '5', 1 
	.word '6', 1 
	.word '7', 1 
	.word '8', 1 
	.word '9', 1 

	.word ':', 4 

	.word 'A', 2
	.word 'B', 2 
	.word 'C', 2 
	.word 'D', 2 
	.word 'E', 2 
	.word 'F', 2 
	.word 'G', 2 
	.word 'H', 2 
	.word 'I', 2 
	.word 'J', 2 
	.word 'K', 2
	.word 'L', 2 
	.word 'M', 2 
	.word 'N', 2 
	.word 'O', 2 
	.word 'P', 2 
	.word 'Q', 2 
	.word 'R', 2 
	.word 'S', 2 
	.word 'T', 2 
	.word 'U', 2
	.word 'V', 2 
	.word 'W', 2 
	.word 'X', 2 
	.word 'Y', 2
	.word 'Z', 2

	.word 'a', 2 
	.word 'b', 2 
	.word 'c', 2 
	.word 'd', 2 
	.word 'e', 2 
	.word 'f', 2 
	.word 'g', 2 
	.word 'h', 2 
	.word 'i', 2 
	.word 'j', 2 
	.word 'k', 2
	.word 'l', 2 
	.word 'm', 2 
	.word 'n', 2 
	.word 'o', 2 
	.word 'p', 2 
	.word 'q', 2 
	.word 'r', 2 
	.word 's', 2 
	.word 't', 2 
	.word 'u', 2
	.word 'v', 2 
	.word 'w', 2 
	.word 'x', 2 
	.word 'y', 2
	.word 'z', 2
