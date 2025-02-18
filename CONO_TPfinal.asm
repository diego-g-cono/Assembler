		.macro read_int
		li $v0,5
		syscall
		.end_macro

		.macro print_label (%label)
		la $a0, %label
		li $v0, 4
		syscall
		.end_macro

		.macro done
		li $v0,10
		syscall
		.end_macro	

		.macro print_error (%errno)
		print_label(error)
		li $a0, %errno
		li $v0, 1
		syscall
		print_label(return)
		.end_macro
		
		.data
slist:	.word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu:	.ascii "Colecciones de objetos categorizados\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error:	.asciiz "Error: "
return:	.asciiz "\n"
catName:.asciiz "\nIngrese el nombre de una categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria: "
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "La operación se realizo con exito\n\n"
select: .asciiz "> "
notFound: .asciiz "notFound\n\n"
separacion: .asciiz "====================================\n"
separacion2: .asciiz "===================================="

		.text
main:
	# initialization scheduler vector
	la $t0, schedv
	la $t1, newcaterogy
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcaterogy
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcaterogy
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)
main_loop:
	# show menu
	jal menu_display
	beqz $v0, main_end
	addi $v0, $v0, -1		# dec menu option
	sll $v0, $v0, 2         # multiply menu option by 4
	la $t0, schedv
	add $t0, $t0, $v0
	lw $t1, ($t0)
    	la $ra, main_ret 		# save return address
    	jr $t1					# call menu subrutine
main_ret:
    j main_loop		
main_end:
	done

menu_display:
	print_label(menu)
	read_int
	# test if invalid option go to L1
	bgt $v0, 8, menu_display_L1
	bltz $v0, menu_display_L1
	# else return
	jr $ra
	# print error 101 and try again
menu_display_L1:
	print_error(101)
	j menu_display
	

newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName		# input category name
	jal getblock
	move $a2, $v0		# $a2 = *char to category name
	la $a0, cclist		# $a0 = list
	li $a1, 0			# $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
newcategory_end:
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

nextcategory:
	print_label (separacion2)
	lw $t0, wclist #tomo la direccion de la cat actual
	beqz $t0, ne201 # me fijo si no hay cat cargadas
	lw $t1, wclist #tomo la direccion de las cat
	la $t0, 12($t0)
	lw $t0, 0($t0) #cargo la direccion de la cat siguiente
	lw $t1, 0($t1) #cargo la direccion de la cat anterior para comaparar
	lw $t0, 0($t0) #cargo la direccion de la cat siguiente para comparar
	beq $t0, $t1, ne202 #me fijo que no haya una sola cat
	lw $t1, wclist
	lw $t1, 12($t1)
	sw $t1, wclist # actualizo la cat actual
	la $t1, 8($t1)
	lw $t1, 0($t1)#cargo el nombre de la cat
	la $a0, selCat
	li $v0, 4
	syscall
	la $a0, 0($t1)
	li $v0, 4
	syscall #muestro el nombre de la cat
nxc_q:	print_label (separacion)
	jr $ra
ne201:	print_error(201) #error por 0 cat
	j nxc_q
ne202:	print_error(202) #error por una sola cat
	j nxc_q	

prevcaterogy:
	print_label (separacion2)
	lw $t0, wclist #tomo la direccion de la cat actual
	beqz $t0, pe201 # me fijo si no hay cat cargadas
	lw $t1, wclist #idem pero lo utilizo para comparar
	la $t1, 12($t1)
	lw $t1, 0($t1)#busco donde esta guardada la categoria siguiente
	lw $t0, 0($t0) #cargo la direccion de la cat anterior
	lw $t1, 0($t1) #cargo la direccion de la cat siguiente para comparar
	beq $t0, $t1, pe202 #me fijo que no haya una sola cat
	sw $t0, wclist # actualizo la cat actual
	la $t0, 8($t0)
	lw $t0, 0($t0)#cargo el nombre de la cat
	la $a0, selCat
	li $v0, 4
	syscall
	la $a0, 0($t0)
	li $v0, 4
	syscall #muestro el nombre de la cat
prc_q:	print_label (separacion)
	jr $ra
pe201:	print_error(201) #error por 0 cat
	j prc_q
pe202:	print_error(202) #error por una sola cat
	j prc_q
	jr $ra

listcategories:
	print_label (separacion)
	lw $t0, wclist
	beqz $t0, le301
	lw $t0, cclist #tomo la direccion donde comienza la lista
	lw $t1, cclist
	lw $t2, wclist
L_list:	beq $t0, $t2, p_select 	#imprimo el caracter que muesta la cat actual
L2_list:la $a0, 8($t0)
	lw $a0, 0($a0) #cargo el nombre de la categoria
	li $v0, 4
	syscall #muestro el nombre de la cat
	la $t3, 12($t0)
	lw $t3, 0($t3) #cargo la direccion de memoria del puntero siguiente
	beq $t3, $t1, list_q #comparo para ver si termine de mostrar
	la $t0, 0($t3) #paso a la siguiente cat
	j L_list	
list_q:	print_label (separacion)
	jr $ra
le301:  print_error(301)
	j list_q
p_select: la $a0, select
	  li $v0, 4
	  syscall
	  j L2_list

delcaterogy:
	print_label (separacion)
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, wclist # tomo la direccion donde comienza la cat
	beqz $t0, dc401 # me fijo que exista cat cargada
	lw $t0, 4($t0) #cargo el puntero a los objetos
	bnez $t0, delobj
dc_L1:	lw $a0, wclist
	la $a1, cclist # cargo la dirección de donde está guardado la direccion a lista
	lw $t0, 12($a0)
	sw $t0, wclist #guardo la dirección de la cat siguiente
	jal delnode
	lw $t0, cclist
	beqz $t0, zero_wclist #si es 0 es porque no hay mas cat
dc_q:	print_label (success)
	print_label (separacion)
	li $v0, 0 # return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
dc401:  print_error(401)
	j dc_q
zero_wclist:
	sw $zero, wclist #pongo en 0 wclist
	j dc_q
delobj: lw $t1, wclist
	la $a1, 4($t1)	#guardo el puntero a la lista de objetos
dc_L2:	lw $t1, 12($t0)	#cargo la direccion del sig objeto
	lw $a0, 0($t0) #cargo la direccion del objeto a eliminar
	jal delnode		
	lw $t0, 0($t1)
	beq $a0, $t0, dc_L1 #me fijo que no haya mas objetos para borrar
	j dc_L2 

newobject:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, wclist		
	beqz $t0, no501	#verifico que existan cat
	la $a0, objName	#ingresa el nombre del objeto
	jal getblock
	move $a2, $v0 # $a2 = *char al objeto
	lw $a0, wclist				
	la $a0, 4($a0) #cargo la direccion donde se guarda el puntero a objetos
	lw $t0, 0($a0) #guardo el contenido de ese puntero para verificar si es el primero
	beqz $t0, nodo1	#si es el primero pongo a1 en 1
	lw $t0, 0($t0)		
	lw $t0, 4($t0) #cargo en t0 el ultimo ID
	addi $a1, $t0, 1 #le sumo 1 al ID
no_L1:	jal addnode		
	lw $t0, wclist		
	la $t0, 4($t0)	#cargo la direccion donde se guarda el puntero a objetos
	beqz $t0, first_node #si es el primero guardo la direccion del primer objeto
no_L2:	li $v0, 0 # return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
nodo1:	li $a1, 1
	j no_L1
first_node:
	sw $v0, 0($t0)
	j no_L2
no501:  print_error(501)
	j no_L2

listobjects:
	print_label (separacion)
	lw $t0, wclist #tomo la direccion donde comienza la lista
	beqz $t0, lo601 #me fijo que exista cat cargada
	lw $t0, 4($t0) #cargo el puntero a los objetos
	beqz $t0, lo602 #me fijo que haya objetos cargados
	lw $t1, wclist 
	lw $t1, 4($t1) # lo voy a usar para comparar y finalizar la lista
lo_L1:	la $a0, 8($t0)
	lw $a0, 0($a0) #cargo el nombre del objeto
	li $v0, 4
	syscall #muestro el nombre de la objeto
	la $t3, 12($t0)
	lw $t3, 0($t3) #cargo la direccion de memoria del puntero siguiente
	beq $t3, $t1, lo_q #comparo para ver si termine de mostrar
	la $t0, 0($t3) #paso al siguiente objeto
	j lo_L1	
lo_q:	print_label (separacion)
	jr $ra
lo601:  print_error(601)
	j lo_q
lo602:  print_error(602)
	j lo_q

delobject:
	print_label (separacion)
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, wclist #tomo la direccion donde comienza la cat
	beqz $t0, do701 #me fijo que exista cat cargada
	lw $t0, 4($t0) #cargo el puntero a los objetos
	beqz $t0, donF #me fijo que existan objetos cargado
	la $a0, idObj 
	li $v0, 4
	syscall   #pido el ID del objeto a eliminar
	li $v0, 5
	syscall #paso el ID por teclado del objeto a eliminar
	addi $t0, $t0, 4 #cargo el puntero al ID del objeto
	lw $t1, 0($t0) #cargo el ID del objeto
do_L1:	beqz $t1, donF #me fijo si el ID es 0 que significa que no encontro el objeto
	beq $t1, $v0, call_dn #me fijo si coinc
	#addi $t0, $t0, 32
	lw $t0, 8($t0)
	addi $t0, $t0, 4 #cargo el puntero al ID del objeto
	lw $t1, 0($t0)
	j do_L1
call_dn: addi $t0, $t0, -4 #cargo el puntero del objeto
	la $a0, 0($t0)
	lw $a1, wclist
	addi $a1, $a1, 4
	jal delnode
do_q:	print_label (success)
	print_label (separacion)
	li $v0, 0 # return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4	
	jr $ra
do701:  print_error(701)
	j do_q
donF:   la $a0, notFound
	li $v0, 4
	syscall
	j do_q
	
# a0: list address (pointer to the list)
# a1: NULL if category or ID if an object
# a2: address return by getblock
# v0: node address added
addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) # set node content
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0) # first node address
	beqz $t0, addnode_empty_list
addnode_to_end:
	lw $t1, ($t0) # last node address
 	# update prev and next pointers of new node
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	# update prev and first node to new node
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
addnode_empty_list:
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

# a0: node address to delete
# a1: list address where node is deleted
delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) # get block address
	jal sfree # free block
	lw $a0, 4($sp) # restore argument a0
	lw $t0, 12($a0) # get address to next node of a0 node
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) # get address to prev node
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) # get address to first node again
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1) # list point to next node
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1) # only one node
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

 # a0: msg to ask
 # v0: block address allocated with string
getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

smalloc:
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16 # node size fixed 4 words
	li $v0, 9
	syscall # return node address in v0
	jr $ra

sfree:
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist # $a0 node address in unused list
	jr $ra
