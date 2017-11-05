#############################################################
# tazzaoui
# 
# Read <= 80 chars terminated by a '#' from input buffer
# Search for & store their type in the output buffer
# Print the output buffer...
# 
# Inf. loop terminates when '#' is entered.
#
#############################################################

		.data
inBuf:		.space		80				# char type input buffer -> 1 byte per element
st_prompt:	.asciiz		"Enter a new input line. \n"
outBuf: 	.space 		80				# char type output buffer -> 1 byte per element

	.text
	
# newLine: Gets <= 80 bytes (up until '#') from input buffer and stores in into inBuf
newLine:
	jal	getline			# getline() --> read input from user, store it in inBuf
	
	lb	$t0, inBuf($0)		# $t0 = inBuf[0]
	beq	$t0, '#', exit		# Terminating Condition --> if(inBuf[0] == '#') break;
					
	li	$t0, 0			# i = 0
	
# forLoop: Search TabChar for the type of each char in inBuf and store it in outBuf
forLoop:		 
	bge	$t0, 80, endLoop	# (i>=80) done with for loop
	lb	$t1, inBuf($t0)		# key = inBuf(i)
					
	jal	lin_search		# key in $t1, return in $a0

	addi	$a0, $a0, 0x30		# a0: char(return value)
	sb	$a0, outBuf($t0)	
	
	addi	$t0, $t0, 1		# i++
	beq	$t1, '#', endLoop	# key == '#', done with loop
	b	forLoop

# Print a new line to separate output
endLoop:
	li	$v0, 11	
	li	$a0, '\n'
	syscall

# print inBuff -> iterate through all 80 chars (or up to '#') and print each of them...
printInBuff:
	li 	$t0, 0			# i = 0
iterateInBuff:
	lb	$a0, inBuf($t0)		# $a0 = inBuff[i]
	syscall				# print inBuff[i]
	beq	$a0, '#', printOutBuff	# if(inBuff[i] == '#') break
	addi	$t0, $t0, 1 		# i++
	b iterateInBuff			

# print outBuff -> iterate through all 80 chars (or up to '#') and print each of them...
printOutBuff:
	li	$a0, '\n'		# Print a new line
	syscall				
	li 	$t0, 0			# i = 0
iterateOutBuff:
	lb	$a0, outBuf($t0)	# $a0 = outBuf[i]
	syscall
	beq	$a0, 6, clearInBuff	# if(outBuf[i] == 6) break; // Found a '#'!
	addi	$t0, $t0, 1 		# i++
	b iterateOutBuff

# Clear input buffer by writing '#' to every index. This is our 'null terminator'
clearInBuff:
	li	$a0, '\n'		# Print a new line
	syscall	
	li $t0, 0			# i = 0
	li $t1, '#'			
iterateClearInBuff:
	sb $t1, inBuf($t0)		# outBuf[i] = '#'
	addi $t0, $t0, 1		# i++
	beq  $t0, 80, clearOutBuff	# if(i == 80) break; // Iterated through entire buffer
	b iterateClearInBuff

# Clear output buffer by writing a null byte to every index
clearOutBuff:
	li $t0, 0			# i = 0
	li $t1, '\0'	
iterateClearOutBuff:
	sb $t1, outBuf($t0)		# outBuf[i] = '\0'
	addi $t0, $t0, 1		# i++
	beq  $t0, 80, newLine		# if(i == 80) break; // Iterated through entire buffer
	b iterateClearOutBuff
	
exit:
	li $v0,10
    	syscall

###########
#
#   lin_search
#	argument: key - $t1
#	return char type: in $a0
#
############

lin_search:
	li	$a0, -1			# index = -1
	li	$s0, 0			# i = 0
	
chkChar:
	bge	$s0, 75, ret
	
	sll	$s0, $s0, 3		# C index i to byte offset in multiples of 8
	lb	$s1, Tabchar($s0)	# $s1 - Tabchar(i, 0)
	sra	$s0, $s0, 3		# restore to C index

	bne	$s1, $t1, nextChar	
	
	sll	$s0, $s0, 3
	lw	$a0, Tabchar+4($s0)	# index = Tabchar(i, 1)
	sra	$s0, $s0, 3

	b	ret
	
nextChar:
	addi	$s0, $s0, 1		# i++
	b	chkChar

ret:	jr	$ra

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

	jr	$ra			# Jump and return to the return addr

.data
Tabchar: 
	.word 0x0a, 6		# LF
	.word ' ', 5
 	.word '#', 6
	.word '$',4
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
