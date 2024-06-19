#--------Nguyen Kieu Duyen ----------
#=================PREPARE DATA==================
.data
infix: .space 256		#string infix
postfix: .space 256 		#string postfix
operatorStack: .space 256	# Ngan xep toan tu
valueStack: .space 200		# Ngan xep gia tri
mess1: .asciiz "\nTiep tuc chuyen doi (1/0): "
mess2: .asciiz "--Nhap bieu thuc trung to: "
mess3: .asciiz "! Bieu thuc trung to khong hop le.\n"
mess4: .asciiz "! Bieu thuc trung to hop le.\n"
mess5: .asciiz "--> Bieu thuc hau to: "
mess6: .asciiz "\n-->Ket qua: "

#=================MA LENH========================
.text
#------Khoi tao mang va dat chi so cac mang ve 0
init:
	la $s0, infix
	la $s1, postfix
	la $s2, operatorStack
	la $s3, valueStack
	li $s4, 0 		# s4: postIndex
	li $s5, 0		# s5: opIndex
	li $s6, 0 		# s6: valIndex
	
#-------------------------CHUONG TRINH CHINH-------------------
main:
process:
	li $v0, 4	# Hien thong bao nhap infix
	la $a0, mess2
	syscall
	
	li $v0, 8	# Nhap string infix 
	la $a0, infix
	li $a1, 256
	syscall
#------------------Kiem tra tinh hop le cua infix-------------------------
check_valid:		
	li $t5, 1 	# t5: lastWasOperator (ki tu truoc co phai op?)
	li $t6, 0	# t6: inOperand (dang o giua toan hang?)
	li $t7, 0 	# t7: bien dem so luong dau ngoac
	li $t0, 0 	# i=0
loop_check:		# Duyet qua tung ky tu cua infix de check
	add $t1, $s0, $t0
	lb $t2, 0($t1) 	# t2 = infix[i]
	beq $t2, 0, end_loop_check 	# neu infix[i] = null -> end check
	# Check ky tu la khoang trang hoac xuong dong
	beq $t2, ' ', case_space_in_loop_check 
	beq $t2, '\n', case_space_in_loop_check
	# Check ky tu la dau ngoac
	beq $t2, '(', case_open_paren_in_loop_check
	beq $t2, ')', case_close_paren_in_loop_check
	
	move $a0, $t2		# a0 = t2
	jal isOperator		# kiem tra infix[i] co la toan tu?
	beq $v0, 1, case_operator_in_loop_check
	
	move $a0, $t2    	# a0 = t2
	jal isDigit		# kiem tra infix[i] co la toan hang?
	beq $v0, 1, case_digit_in_loop_check
	
	j invalid 	# cac ki tu con lai la khong hop le
	
case_space_in_loop_check:
	li $t6, 0 	# inOperand = 0 (khong o giua toan hang)
	j continue_loop_check
case_open_paren_in_loop_check:
	addi $t7, $t7, 1 	# NumParen ++
	li $t5, 1		# lastWasOperator = 1
	li $t6, 0 		# inOperand = 0
	j continue_loop_check
case_close_paren_in_loop_check:
	addi $t7, $t7, -1 	# NumParen --
	li $t6, 0 		# inOperand = 0
	bltz $t7, invalid	# NumParen < 0 -> khong hop le
	j continue_loop_check
case_operator_in_loop_check:
	beq $t5, 1, invalid 	# 2 toan tu lien tiep -> khong hop le
	li $t5, 1 		# lastWasOperator = 1
	li $t6, 0 		# inOperand = 0
	j continue_loop_check
case_digit_in_loop_check:
	# lastWasOperator = 1 -> khong phai 2 toan hang lien tiep
	beq $t5, 1, not_2_consecutive_operands 
	# inOperand = 1 (dang o giua toan hang) -> hop le
	beq $t6, 1, not_2_consecutive_operands
	j invalid 		# 2 toan hang lien tiep -> khong hop le
not_2_consecutive_operands:
	li $t5, 0 		# lastWasOperator = 0
	li $t6, 1		# inOperand = 1
	j continue_loop_check

continue_loop_check:
	addi $t0, $t0, 1
	j loop_check
end_loop_check:
	beq $t5, 1, invalid	# ket thuc voi toan tu -> khong hop le
	bne $t7, 0, invalid	# so Paren khac 0 -> khong hop le
	j valid

invalid: 	# Khong hop le 
	li $v0, 4 
	la $a0, mess3
	syscall			# Thong bao khong hop le
	j enter_choice		# Hoi nguoi dung co muon tiep tuc?
valid:
	li $v0, 4
	la $a0, mess4
	syscall			# Thong bao hop le
	
#---------------------Chuyen doi infix -> postfix-----------------------
convert:
	li $t0, 0 		# i=0
loop_convert:
	add $t1, $s0, $t0 	
	lb $t2, 0($t1)		# t2 = infix[i]
	beq $t2, 0, end_loop_convert 	# infix[i] = null -> end loop
	# check ky tu co phai dau cach hay xuong dong?
	beq $t2, ' ', continue_loop_convert
	beq $t2, '\n', continue_loop_convert
	# check ky tu co phai ngoac khong?
	beq $t2, '(', case_open_paren_in_loop_convert
	beq $t2, ')', case_close_paren_in_loop_convert
	
	move $a0, $t2		# a0 = t2
	jal isDigit 		# check infix[i] co phai toan hang?
	beq $v0, 1, case_digit_in_loop_convert
	
	move $a0, $t2		# a0 = t2
	jal isOperator		# check infix[i] co phai toan tu?
	beq $v0, 1, case_operator_in_loop_convert
case_open_paren_in_loop_convert:
	move $a0, $t2		# a0 = t2
	jal operatorPush 	# operatorStack.push(infix[i])
	j continue_loop_convert
case_close_paren_in_loop_convert:
	loop_pop_until_open:
		jal operatorTop	# v0 = operatorStack.top()
		move $t3, $v0	# t3 = v0 = operator
		beq $t3, '(', end_loop_pop_until_open
		
		move $a0, $t3	# a0 = t3
		jal postfixAppend	# postfix.append(operator)
		li $a0, ' '
		jal postfixAppend  	# postfix.append(' ')
		
		# Tinh ket qua
		jal valueTop
		move $a2, $v0		# a2: toanhang2 = valueStack.top()
		addi $s6, $s6, -1	# valueStack.pop()
		jal valueTop
		move $a1, $v0		# a1: toanhang1 = valueStack.top()
		addi $s6, $s6, -1	# valueStack.pop()
		move $a3, $t3		# a3: toantu
		jal calculate
		move $a0, $v0	# a0: result = calculate(toanhang1, toanhang2, toantu)
		jal valuePush		# valueStack.push(result)
		
		addi $s5, $s5, -1	# operatorStack.pop()
		j loop_pop_until_open
	end_loop_pop_until_open:
		addi $s5, $s5, -1 	# operatorStack.pop(), pop '('
		j continue_loop_convert
case_digit_in_loop_convert:
	li $t3, 0 		# t3: value=0
	loop_digit:
		add $t1, $s0, $t0
		lb $t2, 0($t1)	# t2 = infix[i]
		
		move $a0, $t2	# a0 = t2
		jal isDigit 	# check infix[i] co phai toan hang?
		beq $v0, 0, end_loop_digit	
		
		mul $t3, $t3, 10	# value = value*10
		add $t3, $t3, $t2	# value = value*10 + infix[i]
		sub $t3, $t3, '0'	# value = value*10 +(infix[i]-32)
		
		move $a0, $t2	# a0 = t2
		jal postfixAppend 	# postfix.append(infix[i])
		addi $t0, $t0, 1 	# i++
		j loop_digit
	end_loop_digit:
		move $a0, $t3		# a0 = t3 = value
		jal valuePush		# valueStack.push(value)
		
		li $a0, ' '		
		jal postfixAppend	# postfix.append(' ')
		
		addi $t0, $t0, -1	# i--
		j continue_loop_convert
case_operator_in_loop_convert:
	loop_pop_until_lower_prec:
		# neu operatorIndex = 0 => operatorStack la empty -> ket thuc
		blez $s5, end_loop_pop_until_lower_prec
		
		jal operatorTop
		move $t3, $v0	# t3 = v0 = operator = operatorStack.top()
		move $a0, $t3	# a0 = operator
		jal prec
		move $t4, $v0	# t4 = prec(operator)
		move $a0, $t2  	# a0 = infix[i]
		jal prec
		move $t5, $v0 	# t5 = prec(infix[i])
		# t4<t5: prec(operator) < prec(infix[i]) -> ket thuc
		blt $t4, $t5, end_loop_pop_until_lower_prec
		
		move $a0, $t3	# a0 = operator
		jal postfixAppend	# postfix.append(operator)
		li $a0, ' '
		jal postfixAppend	# postfix.append(' ')
		
		# Tinh ket qua
		jal valueTop
		move $a2, $v0		# a2: toanhang2 = valueStack.top()
		addi $s6, $s6, -1	# valueStack.pop()
		jal valueTop
		move $a1, $v0		# a1: toanhang1 = valueStack.top()
		addi $s6, $s6, -1	# valueStack.pop()
		move $a3, $t3		# a3: toantu
		jal calculate
		move $a0, $v0	# a0: result = calculate(toanhang1, toanhang2, toantu)
		jal valuePush		# valueStack.push(result)
		
		addi $s5, $s5, -1	# operatorStack.pop()
		j loop_pop_until_lower_prec
	end_loop_pop_until_lower_prec:
		move $a0, $t2
		jal operatorPush
		j continue_loop_convert
continue_loop_convert:
	addi $t0, $t0, 1
	j loop_convert
end_loop_convert:
	# Vong lap dua tat ca toan hang con lai vao postfix
	loop_pop_remaining:
		# neu operatorIndex = 0 => operatorStack la empty -> ket thuc
		blez $s5, end_loop_pop_remaining
		
		jal operatorTop
		move $t3, $v0	# t3 = v0 = operator = operatorStack.top()
		
		move $a0, $t3	# a0 = operator
		jal postfixAppend	# postfix.append(operator)
		li $a0, ' '
		jal postfixAppend	# postfix.append(' ')
		
		# Tinh ket qua
		jal valueTop
		move $a2, $v0		# a2: toanhang2 = valueStack.top()
		addi $s6, $s6, -1	# valueStack.pop()
		jal valueTop
		move $a1, $v0		# a1: toanhang1 = valueStack.top()
		addi $s6, $s6, -1	# valueStack.pop()
		move $a3, $t3		# a3: toantu
		jal calculate
		move $a0, $v0	# a0: result = calculate(toanhang1, toanhang2, toantu)
		jal valuePush		# valueStack.push(result)
		
		addi $s5, $s5, -1	# operatorStack.pop()
		j loop_pop_remaining
	end_loop_pop_remaining:
		li $a0, 0
		jal postfixAppend	# postfix.append('\0')
		
		li $v0, 4
		la $a0, mess5
		syscall 	# Thong bao postfix
		
		li $v0, 4
		move $a0, $s1	# a0 = address postfix
		syscall 	# in ra postfix
		
		li $v0, 4
		la $a0, mess6 	
		syscall		# Thong bao ket qua
		
		jal valueTop
		move $a0, $v0
		li $v0, 1
		syscall 	# in ra result

reset: 
	li $s4, 0 		# s4: postIndex
	li $s5, 0		# s5: opIndex
	li $s6, 0 		# s6: valIndex	
	
enter_choice:
	li $v0, 4
	la $a0, mess1
	syscall		# Nguoi dung co muon tiep tuc hay khong?
	
	li $v0, 5
	syscall
	
	beq $v0, 1, main
end_main:
	li $v0, 10
	syscall
#-------------------KET THUC CHUONG TRINH CHINH---------------------

#-------------------CAC HAM SU DUNG---------------------------------
# int isOperator(char c)
# $a0 = c
# return $v0
isOperator:
	beq $a0, '+', is_operator
	beq $a0, '-', is_operator
	beq $a0, '*', is_operator
	beq $a0, '/', is_operator
	j is_not_operator
is_operator:		# tra ve 1 neu la toan tu
	li $v0, 1
	jr $ra
is_not_operator:	# tra ve 0 neu khong la toan tu
	li $v0, 0
	jr $ra

# int isDigit(char c)
# $a0 = c
# return $v0
isDigit:
	blt $a0, '0', is_not_digit	# a0<0 -> khong phai toan hang
	bgt $a0, '9', is_not_digit	# a0>9 -> khong phai toan hang
	j is_digit
is_digit: 		# tra ve 1 neu la toan hang
	li $v0, 1
	jr $ra
is_not_digit:		# tra ve 0 neu khong la toan hang
	li $v0, 0	
	jr $ra

# void operatorPush(char c)
# $a0 = c
operatorPush:
	add $t8, $s2, $s5	# t8 = addr(operatorStack) + operatorIndex
	sb $a0, 0($t8)		# operatorStack[operatorIndex] = c
	addi $s5, $s5, 1	# operatorIndex ++
	jr $ra

# char operatorTop()
# return $v0
operatorTop:
	add $t8, $s2, $s5	# t8 = addr(operatorStack) + operatorIndex
	addi $t8, $t8, -1
	lb $v0, 0($t8)		# v0 = operatorStack[operatorIndex - 1]
	jr $ra

# void valuePush(int value)
# $a0 = value
valuePush:
	add $t8, $s6, $s6	# t8 = 2*valueIndex
	add $t8, $t8, $t8 	# t8 = 4*valueIndex
	add $t8, $s3, $t8 	# t8 = addr(valueStack) + 4*valueIndex
	sw $a0, 0($t8)		# valueStack[valueIndex] = value
	addi $s6, $s6, 1	# valueIndex ++
	jr $ra

# int valueTop()
# return $v0
valueTop:
	add $t8, $s6, $s6	# t8 = 2*valueIndex
	add $t8, $t8, $t8 	# t8 = 4*valueIndex
	add $t8, $s3, $t8 	# t8 = addr(valueStack) + 4*valueIndex
	addi $t8, $t8, -4
	lw $v0, 0($t8)		# v0 = valueStack[valueIndex - 1]
	jr $ra

# void postfixAppend(char c)
# $a0 = c
postfixAppend:
	add $t8, $s1, $s4	# t8 = addr(postfix) + postIndex
	sb $a0, 0($t8)		# postfix[postIndex] = c
	addi $s4, $s4, 1	# postIndex ++
	jr $ra

# int calculate(int toanhang1, int toanhang2, char toantu)
# $a1 = toanhang1, $a2 = toanhang2, $a3 = toantu
# return $v0
calculate:
	beq $a3, '+', plus
	beq $a3, '-', minus
	beq $a3, '*', multiply
	beq $a3, '/', divide
	j default_case
plus:
	add $v0, $a1, $a2
	jr $ra
minus:
	sub $v0, $a1, $a2
	jr $ra
multiply:
	mul $v0, $a1, $a2
	jr $ra
divide:
	beq $a2, 0, default_case
	div $v0, $a1, $a2
	jr $ra
default_case:
	li $v0, 0
	jr $ra

# int prec(char c)
# $a0= c
# return $v0
prec:
	beq $a0, '*', high_prec
	beq $a0, '/', high_prec
	beq $a0, '+', low_prec
	beq $a0, '-', low_prec
	j default_prec
high_prec:
	li $v0, 2
	jr $ra
low_prec:
	li $v0, 1
	jr $ra
default_prec:
	li $v0, 0
	jr $ra