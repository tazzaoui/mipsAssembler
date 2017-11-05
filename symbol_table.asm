###########################################################
# tazzaoui
# Use generated tokens and their types to formulate
# a symbol table	
#
###########################################################				
								
		.data

# NULL or 0 in tokArray prematurely terminates dumping
# tokArray. Use blanks instead.

TOKEN:		.word 	0x20202020:3			# 2-word TOKEN & its TYPE
tokArray:	.word	0x20202020:60			# initializing with blanks
symbTab:	.word	0x20202020:40			# Space for 10 Symbols : 16 bytes each
numSymb:	.word	0
inBuf:		.space	80
hexPreFix:	.asciiz "0x"
st_prompt:	.asciiz	"Enter a new input line. \n"
st_error:	.asciiz	"An error has occurred. \n"	
tableHead:	.asciiz "  TOKEN        TYPE\n"
symTabHead:	.asciiz   TOKEN        VALUE        STATUS\n
saveReg:	.word	0:31
fourSpaces:	.asciiz "        "
doubleDef: 	.asciiz	"Double Definition Error!\n"
loc:		.word	0x400
defn:		.word	0
	
	.text
#######################################################################
#
# Main
#
#	read an input line
#	call scanner driver
#	clear buffers
#
######################################################################
li	$t0, 0x7F
la	$t1, symbTab

newline:
	jal	getline			# get a new input string
	
	li	$t5,0			# $t5: index to inBuf
	li	$a3,0			# $a3: index to tokArray

	la	$s1, Q0			# initial state Q0
driver:	lw	$s2, 0($s1)		# get the action routine
	jalr	$v1, $s2		# execute the action

	sll	$s0, $s0, 2		# compute byte offset of T
	add	$s1, $s1, $s0		# locate the next state
	la	$s1, ($s1)
	lw	$s1, ($s1)		# next State in $s1
	sra	$s0, $s0, 2		# reset $s0 for T
	b	driver			# go to the next state

hw4:
	lb	$t1, tokArray($0)		
	beq	$t1, '#', exit		#if (inBuf[0] == '#') exit
	
	li	$s2, 0			# i = 0

nextTok:
	addi 	$t0, $s2, 12		# i + byteOffset of 1
	lb	$t0, tokArray($t0)
	bne	$t0, ':', operator 	# if(tokArray[i + 1][0] != ":" goto operator
	
	lw	$a0, tokArray($s2)	# TOKEN = tokArray[i][0]
	li	$t2, 1
	sw	$t2, defn		#DEFN = 1
	
	la	$t3, tokArray
	add 	$a0, $t3, $s2		# $a0 = Address tokArray[i] (TOKEN)	
	
	jal	variable		# valVar = VARIABLE(TOKEN, 1)
	
	addi 	$s2, $s2, 12		# Skip next token!

operator:
	addi	$s2, $s2, 12		# i++	
	b	nextVar

	li	$t8, 1 			# isComma = true	

chkVar:
	add	$t0, $s2, 8		# offset 12 + 8 = [i][1] 
	lw	$t0, tokArray($t0)	# type = TOKENS[i][1]
	beq 	$t0, 0x0a362020, dump	# if(type == 6) dump
	beq	$t8, 1, nextVar		# if(!isComma)  nextVar
	bne 	$t0, 0x0a322020, nextVar# if(tokens[i][1] != 2) nextVar
	
	la	$a0, tokArray($s2)	# TOKEN = TOKENS[i][0] 
	sw	$0, defn		# DEFN = 0
	jal	variable		# valVar = VARIABLE(TOKEN, 0)		

nextVar:
	lb	$t0, tokArray($s2)	# TOKENS[i][0]
	beq	$t0, ',', isCommaTrue	# if(TOKENS[i][0] == ',') isComma = true
	li 	$t8, 0			# else	isComma = false

doneCommaTest:
	addi	$s2, $s2, 12		# i++
	b	chkVar
	
dump:	
	jal 	printSymbTable
	jal	clearInBuf		# clear input buffer
	jal	clearTokArray		# clear token array
	
	
	lw	$t0, loc	
	add	$t0, $t0, 4
	sw	$t0, loc		# loc += 4
	
	b 	newline
	
isCommaTrue:
	li	$t8, 1
	b	doneCommaTest

###################################################################
#
#	Variable(Token, DEFN)
# PRECONDITION:	
#	$a0: Address of TOKEN
#	$t4: Return valVar
#	DEFN: in memory
#
###################################################################
variable:	
		la	$t7, symb_lin_search
		jalr	$v1, $t7			# $s5 contains index of symbol in $a0 
		blt	$s5, 0, updateNewStatus		# index = -1, first occurance
		
		#else portion...
		addi	$t0, $s5, 12			# Move to status potion of the symbol index
		lw	$t0, symbTab($t0)		# oldStatus = symbTab[symIndex][2]
		
		and	$t1, $t0, 0x2			# $t1 = oldStatus & 0x2
		and 	$t3, $t0, 0x1			# $t3 = oldStatus & 0x1
		sll 	$t3, $t3, 1			# (oldStatus & 0x1) << 1
		
		# (oldStatus & 0x2) | ((oldStatus & 0x1) << 1)
		or	$t0, $t1, $t3			# set A flag	
		
		lw	$t3, defn
		or	$t0, $t0, $t3			# set D flag
		
		addi	$t1, $s5, 12			# Move to status potion of the symbol index
		sw	$t0, symbTab($t1)		# symbTab[symIndex][2] = newStatus
doneElseVar:
		la	$s6, symACTS			# compute which symACT to jump to (based on jTable)
		sll	$t0, $t0, 2
		add	$s6, $s6, $t0
		lw	$s6, ($s6)
		jr	$s6				#make sure to jr $v1 in every symACT		

updateNewStatus:
		lw	$t0, defn
		li	$t2, 0x4
		or	$t0, $t2, $t0			# 0x4 | DEFN
		la	$t4, saveSymTab
		jalr	$v1, $t4
		
		b 	doneElseVar	

###################################################################
#		saveSymTab
#
#		$a0	address of token
#		$t0	newStatus	
#		$s5 	index of symbol
#		$v1	return address
###################################################################	
saveSymTab:
		la 	$t8, getIndexOfLastSym
		jalr	$v0, $t8			# t9 has index of lastSymb
		lw	$t5, ($a0)
		sw	$t5, symbTab($t9)		# store the first word of the token
		
		add	$t1, $t9, 4	
		
		lw	$t5, 4($a0)		
		sw 	$t5, symbTab($t1)		# store the second word of the token
		
		addi 	$t1, $t1, 8
		sw 	$t0, symbTab($t1)			# store status 
		
		move 	$s5, $t9			# return the index
		
		lw	$a1, numSymb
		addi	$a1, $a1, 1			# increment numSymb
		sw 	$a1, numSymb
		
		jr 	$v1
###################################################################
#		getIndexOfLastSym
#	
#	returns:
#		$t9 - index of last value in symbol table
###################################################################	
# 
getIndexOfLastSym:
		li	$t9, 0			# i = 0
	loopGILS:
		li	$t5, 0x20202020
		lw	$t6, symbTab($t9)
		beq	$t6, $t5,  doneGILS	# Found blank symbol
		
		li	$t5, 0x7F
		beq	$t6, $t5, doneGILS	# Reached end of symbTab
		
		addi	$t9, $t9, 16			# move to next symbol
		b 	loopGILS
doneGILS:
		jr	$v0
		
####################### STATE ACTION ROUTINES #####################

#	$a0: Address of TOKEN
#	$t4: Return valVar
#	DEFN: in memory
#	$s5: index of symbol

symACT0:
	addi	$t6, $s5, 8	# Move to val section (2 words away)
	lw	$t4, symbTab($t6)
	lw	$s4, loc
	sw	$s4, symbTab($t6)
	jr 	$ra
symACT1:
	addi	$t6, $s5, 8	# Move to val section (2 words away)
	lw	$t4, symbTab($t6)
	lw	$s4, loc
	sw	$s4, symbTab($t6)
	jr 	$ra
symACT2:
	addi	$t6, $s5, 8	# Move to val section (2 words away)
	lw	$t4, symbTab($t6)
	jr 	$ra
symACT3:
	#print double defined!
	li	$t4, 0xFFFF
	la	$a0, doubleDef
	li	$v0, 4
	syscall	
	jr 	$ra
symACT4:
	addi	$t6, $s5, 8	# Move to val section (2 words away)
	li	$t4, 0xFFFF
	lw	$s4, loc
	sw	$s4, symbTab($t6)
	jr 	$ra
symACT5:
	addi	$t6, $s5, 8	# Move to val section (2 words away)
	li	$t4, 0x0
	lw	$s4, loc
	sw	$s4, symbTab($t6)
	jr 	$ra

##############################################
#
# ACT1:
#	$t5: Get next char
#	T = char type
#
##############################################
ACT1: 
	lb	$a0, inBuf($t5)			# $a0: next char
	jal	lin_search			# $s0: T (char type)
	addi	$t5, $t5, 1			# $t5++
	jr	$v1
	
###############################################
#
# ACT2:
#	save char to TOKEN for the first time
#	save char type as Token type
#	set remaining token space
#
##############################################
ACT2:
	li	$s3, 0				# initialize index to TOKEN char 
	sb	$a0, TOKEN($s3)			# save 1st char to TOKEN
	addi	$t0, $s0, 0x30			# T in ASCII
	sb	$t0, TOKEN+10($s3)		# save T as Token type
	li	$t0, '\n'
	sb	$t0, TOKEN+11($s3)		# NULL to terminate an entry
	addi	$s3, $s3, 1
	jr 	$v1
	
#############################################
#
# ACT3:
#	collect char to TOKEN
#	update remaining token space
#
#############################################
ACT3:
	bgt	$s3, 7, lenError		# TOKEN length error
	sb	$a0, TOKEN($s3)			# save char to TOKEN
	addi	$s3, $s3, 1			# $s3: index to TOKEN
	jr	$v1	
lenError:					# this->thing = 
	li	$s0, 7				# T=7 for token length error
	jr	$v1
					
#############################################
#
#  ACT4:
#	move TOKEN to tokArray
#
############################################
ACT4:
	lw	$t0, TOKEN($0)			# get 1st word of TOKEN
	sw	$t0, tokArray($a3)		# save 1st word to tokArray
	lw	$t0, TOKEN+4($0)		# get 2nd word of TOKEN
	sw	$t0, tokArray+4($a3)		# save 2nd word to tokArray
	lw	$t0, TOKEN+8($0)		# get Token Type
	sw	$t0, tokArray+8($a3)		# save Token Type to tokArray
	addi	$a3, $a3, 12			# update index to tokArray
	
	jal	clearTok			# clear 3-word TOKEN
	jr	$v1

############################################
#
#  RETURN:
#	End of the input string
#
############################################
RETURN:
	sw	$zero, tokArray($a3)		# force NULL into tokArray
	b	hw4				# leave the state table


#############################################
#
#  ERROR:
#	Error statement and quit
#
############################################
ERROR:
	la	$a0, st_error			# print error occurrence
	li	$v0, 4
	syscall
	b	dump


############################### BOOK-KEEPING FUNCTIONS #########################
#############################################
#
#  clearTok:
#	clear 3-word TOKEN after copying it to tokArray
#
#############################################
clearTok:
	li	$t1, 0x20202020
	sw	$t1, TOKEN($0)
	sw	$t1, TOKEN+4($0)
	sw	$t1, TOKEN+8($0)
	jr	$ra
	
#############################################
#
#  printline:
#	Echo print input string
#
#############################################
printline:
	la	$a0, inBuf			# input Buffer address
	li	$v0,4
	syscall
	jr	$ra

#############################################
#
#  printTokArray:
#	print Token array header
#	print each token entry
#
#############################################
printTokArray:
	la	$a0, tableHead			# table heading
	li	$v0, 4
	syscall

	la	$a0, tokArray			# print tokArray
	li	$v0, 4
	syscall

	jr	$ra

############################################
#
#  clearInBuf:
#	clear inbox
#
############################################
clearInBuf:
	li	$t0,0
loopInB:
	bge	$t0, 80, doneInB
	sw	$zero, inBuf$t0		# clear inBuf to 0x0
	addi	$t0, $t0, 4
	b	loopInB
doneInB:
	jr	$ra
	
###########################################
#
# clearTokArray:
#	clear Token Array
#1				;5B
###########################################
clearTokArray:
	li	$t0, 0
	li	$t1, 0x20202020			# intialized with blanks
loopCTok:
	bge	$t0, $a3, doneCTok
	sw	$t1, tokArray($t0)		# clear
	sw	$t1, tokArray+4($t0)		#  3-word entry
	sw	$t1, tokArray+8($t0)		#  in tokArray
	addi	$t0, $t0, 12
	b	loopCTok
doneCTok:
	jr	$ra
	

###################################################################
#
#  getline:
#	get input string into inbox
#
###################################################################
getline: 
	la	$a0, st_prompt			# Prompt to enter a new line
	li	$v0, 4
	syscall

	la	$a0, inBuf			# read a new line
	li	$a1, 80	
	li	$v0, 8
	syscall
	jr	$ra


##################################################################
#
#  lin_search:
#	Linear search of Tabchar
#
#   	$a0: char key
#   	$s0: char type, T
#
#################################################################
lin_search:
	li	$t0,0				# index to Tabchar
	li	$s0, 7				# return value, type T

loopSrch:
	lb	$t1, Tabchar($t0)
	beq	$t1, 0x7F, charFail
	beq	$t1, $a0, charFound
	addi	$t0, $t0, 8
	b	loopSrch

charFound:
	lw	$s0, Tabchar+4($t0)		# return char type

charFail:
	jr	$ra

##################################################################
#
#  symb_lin_search:
#	Linear search of symbol table
#
#   	$a0: address of first word of symbol (total: 2 words)
#   	$s5: index of symbol, -1 if not found
#	$v1: return address
#################################################################
symb_lin_search:
	li	$t0,0				# index to symbol table
	li	$s5, -1				# return value, index of TOKEN or -1

symbSrch:
	lw	$t1, symbTab($t0)
	#beq	$t1, 0x7F, symbFail
	bge	$t0, 65, symbFail
	lw	$t3, ($a0)
	beq	$t1, $t3, checkWord2

symbBreak:
	addi	$t0, $t0, 16		# 16 -> next symbol
	b	symbSrch

checkWord2:
	addi	$t2, $a0, 4		# Move symbol param over one word
	addi 	$t3, $t0, 4		# Move symbol table index over one word
	lw	$t1, symbTab($t3)
	beq	$t1, 0x7F, symbFail
	lw	$t3, ($t2)
	beq	$t1, $t3, symbFound
	addi	$t0, $t0, 16		# 16 -> next symbol
	b	symbSrch
	
symbFound:
	move	$s5, $t0		# return index
	jr	$v1
	
symbFail:
	li	$s5, -1			# return -1
	jr	$v1

#############################################
#
#  printSymbTable:
#	print Symbol Table header
#	print FAD, SYMBOL, VALUE
#
#############################################

printSymbTable:
	lw 	$t7, numSymb					
	
	la	$a0, symTabHead		# symbTab heading
	li	$v0, 4
	syscall
	
	li	$t4, 0
	la	$t5, symbTab

loopPST:
	move	$t8, $0
	loopW1:	
	add	$a0, $t4, $t5		# print symbol word 1
	lb	$a0, ($a0)
	li	$v0, 11
	syscall
	addi	$t8, $t8, 1
	addi	$t4, $t4, 1
	beq	$t8, 4, doneloopW1	# printed exactly 4 bytes
	b 	loopW1
	
	doneloopW1:
	move	$t8, $0
	loopW2:
	add	$a0, $t4, $t5		# print symbol word 2
	lb	$a0, ($a0)
	li	$v0, 11
	syscall
	addi	$t8, $t8, 1
	addi	$t4, $t4, 1
	beq	$t8, 4, printSpaces	# printed exactly 4 bytes
	b	loopW2
	
	printSpaces:
	la	$a0, fourSpaces		# print fourSpaces
	li	$v0, 4
	syscall
	
	
	la	$a0,hexPreFix
	li	$v0, 4
	syscall
	
	add	$a0, $t4, $t5		# Convert hexValue to charValue
	lw	$a0, ($a0)
	la	$s6, hex2char
	jalr	$s7, $s6
	

	move 	$a0, $v0
	li	$t8, 0
	loopPrintValue:
	li	$v0, 11
	syscall
	srl 	$a0, $a0, 8
	addi	$t8, $t8, 1
	addi	$t4, $t4, 1
	beq	$t8, 4, print4MoreSpaces 
	b	loopPrintValue
	
	
	print4MoreSpaces:
	la	$a0, fourSpaces		# Print fourSpaces
	li	$v0, 4
	syscall
	
	# Convert Status from hex -> binary -> char
	# Use repeated division for conversion, remainder stored in HI
	
	add	$a0, $t4, $t5	
	lw	$s2, ($a0)

	li	$s3, 2
	
	div	$s2, $s3
	mfhi	$a3
	addi	$a3, $a3, 48
	
	mflo	$s2
	
	div	$s2, $s3, 
	mfhi	$a2
	addi	$a2, $a2, 48
	
	mflo	$s2
	div	$s2, $s3
	mfhi	$t8
	addi	$t8, $t8, 48
	
	li	$v0, 11
	move	$a0, $t8
	syscall
	move 	$a0, $a2
	syscall
	move	$a0, $a3
	syscall
	
	printNewLine:
	addi	$t4, $t4, 4
	li	$a0, '\n'
	li	$v0, 11
	syscall	
	
	div 	$t3, $t4, 16
	
	blt	$t3, $t7, loopPST	
	
	jr	$ra

###########################################
#
# clearSymbTab:
#	clear symbol table
#
###########################################
clearSymbTab:
	li	$t0, 0
	li	$t1, 0x20202020			# intialized with blanks
loopsCST:
	bge	$t0, 65, doneCST		#  max size of symbtab is 65...
	sw	$t1, symbTab($t0)		#  clear value (word 1)
	sw	$t1, tokArray+4($t0)		#  clear value (word 2)
	sw	$t1, tokArray+8($t0)		#  clear location
	sw	$t1, tokArray+12($t0)		#  clear FAD
	addi	$t0, $t0, 16
	b	loopCTok
doneCST:
	jr	$ra
	
#
# 	hex2char:
#	    Convert a hex in $a0 to char hex in $v0 (0x6b6a in $a0, $v0 should have 'a''6''b''6')
#
#	    	4-bit mask slides from right to left in $a0.
#		As corresponding char is collected into $v0,
#		$a0 is shifted right by four bits for the next hex digit in the last four bits
#		
#		Globals Modified: $t0, $t1, $t9, $a0, $v0
#	Make it sure that you are handling nested function calls in return addresses
#

		.text
hex2char:
		# save registers
		sw	$t0, saveReg($0)	# hex digit to process
		sw	$t1, saveReg+4($0)	# 4-bit mask
		sw	$t9, saveReg+8($0)

		# initialize registers
		li	$t1, 0x0000000f	# $t1: mask of 4 bits
		li	$t9, 3			# $t9: counter limit

nibble2char:
		and 	$t0, $a0, $t1		# $t0 = least significant 4 bits of $a0

		# convert 4-bit number to hex char
		bgt	$t0, 9, hex_alpha	# if ($t0 > 9) goto alpha
		# hex char '0' to '9'
		addi	$t0, $t0, 0x30		# convert to hex digit
		b	collect

hex_alpha:
		addi	$t0, $t0, -10		# subtract hex # "A"
		addi	$t0, $t0, 0x61		# convert to hex char, a..f

		# save converted hex char to $v0
collect:
		sll	$v0, $v0, 8		# make a room for a new hex char
		or	$v0, $v0, $t0		# collect the new hex char

		# loop counter bookkeeping
		srl	$a0, $a0, 4		# right shift $a0 for the next digit
		addi	$t9, $t9, -1		# $t9--
		bgez	$t9, nibble2char

		# restore registers
		lw	$t0, saveReg($0)
		lw	$t1, saveReg+4($0)
		lw	$t9, saveReg+8($0)
		jr	$s7
char2hex:
		# save registers
		sw	$t0, saveReg($0)	# hex digit to process
		sw	$t1, saveReg+4($0)	# 4-bit mask
		sw	$t9, saveReg+8($0)
		
		li	$v0, 0
		li	$t1, 3
		li	$t0, 0
iterloop:
		bge	$t0, 4, hexdone
		add	$t0, $t0, $a0
		lb	$t9, symbTab($t0)
		sub	$t0, $t0, $a0
		subi	$t9, $t9, 0x30
		sll	$t1, $t1, 2
		sllv	$t9, $t9, $t1
		srl	$t1, $t1, 2
		add	$v0, $v0, $t9
		addi	$t0, $t0, 1
		addi	$t1, $t1, -1
		b iterloop
hexdone:
		# restore registers
		lw	$t0, saveReg($0)
		lw	$t1, saveReg+4($0)
		lw	$t9, saveReg+8($0)
		jr	$s7

exit:
	li	$v0, 10
	syscall

	.data
symACTS: 
	symACT0, symACT1, symACT2, symACT3, symACT4,symACT5
STAB:
Q0:     .word  ACT1
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q1:     .word  ACT2
        .word  Q2   # T1
        .word  Q5   # T2
        .word  Q3   # T3
        .word  Q3   # T4
        .word  Q0   # T5
        .word  Q4   # T6
        .word  Q11  # T7

Q2:     .word  ACT1
        .word  Q6   # T1
        .word  Q7   # T2
        .word  Q7   # T3
        .word  Q7   # T4
        .word  Q7   # T5
        .word  Q7   # T6
        .word  Q11  # T7

Q3:     .word  ACT4
        .word  Q0   # T1
        .word  Q0   # T2
        .word  Q0   # T3
        .word  Q0   # T4
        .word  Q0   # T5
        .word  Q0   # T6
        .word  Q11  # T7

Q4:     .word  ACT4
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q5:     .word  ACT1
        .word  Q8   # T1
        .word  Q8   # T2
        .word  Q9   # T3
        .word  Q9   # T4
        .word  Q9   # T5
        .word  Q9   # T6
        .word  Q11  # T7

Q6:     .word  ACT3
        .word  Q2   # T1
        .word  Q2   # T2
        .word  Q2   # T3
        .word  Q2   # T4
        .word  Q2   # T5
        .word  Q2   # T6
        .word  Q11  # T7

Q7:     .word  ACT4
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q8:     .word  ACT3
        .word  Q5   # T1
        .word  Q5   # T2
        .word  Q5   # T3
        .word  Q5   # T4
        .word  Q5   # T5
        .word  Q5   # T6
        .word  Q11  # T7

Q9:     .word  ACT4
        .word  Q1  # T1
        .word  Q1  # T2
        .word  Q1  # T3
        .word  Q1  # T4
        .word  Q1  # T5
        .word  Q1  # T6
        .word  Q11 # T7

Q10:	.word	RETURN
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q11:    .word  ERROR 
	.word  Q4  # T1
	.word  Q4  # T2
	.word  Q4  # T3
	.word  Q4  # T4
	.word  Q4  # T5
	.word  Q4  # T6
	.word  Q4  # T7
	
	
Tabchar: 
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

	.word 0x7F, 0
