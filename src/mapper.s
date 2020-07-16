	.file	"mapper.c"
	.text
	.comm	touch_dev_path,80,32
	.comm	keyboard_dev_path,80,32
	.comm	mouse_dev_path,80,32
	.globl	keyboard_dev
	.data
	.align 4
	.type	keyboard_dev, @object
	.size	keyboard_dev, 4
keyboard_dev:
	.long	16
	.globl	mouse_dev
	.align 4
	.type	mouse_dev, @object
	.size	mouse_dev, 4
mouse_dev:
	.long	15
	.comm	touch_fd,4,4
	.globl	Exclusive_mode_flag
	.bss
	.align 4
	.type	Exclusive_mode_flag, @object
	.size	Exclusive_mode_flag, 4
Exclusive_mode_flag:
	.zero	4
	.globl	no_Exclusive_mode_flag
	.data
	.align 4
	.type	no_Exclusive_mode_flag, @object
	.size	no_Exclusive_mode_flag, 4
no_Exclusive_mode_flag:
	.long	1
	.comm	Mouse_queue,384,32
	.globl	m_len
	.bss
	.align 4
	.type	m_len, @object
	.size	m_len, 4
m_len:
	.zero	4
	.comm	Keyboard_queue,384,32
	.globl	k_len
	.align 4
	.type	k_len, @object
	.size	k_len, 4
k_len:
	.zero	4
	.globl	touch_id
	.align 32
	.type	touch_id, @object
	.size	touch_id, 40
touch_id:
	.zero	40
	.comm	postion,80,32
	.globl	allocatedID_num
	.align 4
	.type	allocatedID_num, @object
	.size	allocatedID_num, 4
allocatedID_num:
	.zero	4
	.globl	SYNC_EVENT
	.align 16
	.type	SYNC_EVENT, @object
	.size	SYNC_EVENT, 24
SYNC_EVENT:
	.zero	24
	.globl	SWITCH_ID_EVENT
	.data
	.align 16
	.type	SWITCH_ID_EVENT, @object
	.size	SWITCH_ID_EVENT, 24
SWITCH_ID_EVENT:
	.quad	0
	.quad	3
	.value	47
	.value	-1
	.zero	4
	.globl	POS_X_EVENT
	.align 16
	.type	POS_X_EVENT, @object
	.size	POS_X_EVENT, 24
POS_X_EVENT:
	.quad	0
	.quad	3
	.value	53
	.value	0
	.zero	4
	.globl	POS_Y_EVENT
	.align 16
	.type	POS_Y_EVENT, @object
	.size	POS_Y_EVENT, 24
POS_Y_EVENT:
	.quad	0
	.quad	3
	.value	54
	.value	0
	.zero	4
	.globl	DEFINE_UID_EVENT
	.align 16
	.type	DEFINE_UID_EVENT, @object
	.size	DEFINE_UID_EVENT, 24
DEFINE_UID_EVENT:
	.quad	0
	.quad	3
	.value	57
	.value	0
	.zero	4
	.globl	BTN_DOWN_EVENT
	.align 16
	.type	BTN_DOWN_EVENT, @object
	.size	BTN_DOWN_EVENT, 24
BTN_DOWN_EVENT:
	.quad	0
	.quad	1
	.value	330
	.value	1
	.zero	4
	.globl	BTN_UP_EVENT
	.align 16
	.type	BTN_UP_EVENT, @object
	.size	BTN_UP_EVENT, 24
BTN_UP_EVENT:
	.quad	0
	.quad	1
	.value	330
	.value	0
	.zero	4
	.comm	sem_control,32,32
	.text
	.globl	main_controler
	.type	main_controler, @function
main_controler:
.LFB5:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	%edi, -20(%rbp)
	movl	%esi, -24(%rbp)
	movl	%edx, -28(%rbp)
	movl	%ecx, -32(%rbp)
	leaq	sem_control(%rip), %rdi
	call	sem_wait@PLT
	movl	-24(%rbp), %eax
	movl	%eax, -8(%rbp)
	cmpl	$0, -20(%rbp)
	jne	.L2
	movl	-28(%rbp), %eax
	movl	%eax, 20+POS_X_EVENT(%rip)
	movl	-32(%rbp), %eax
	movl	%eax, 20+POS_Y_EVENT(%rip)
	movl	20+SWITCH_ID_EVENT(%rip), %eax
	cmpl	%eax, -8(%rbp)
	je	.L3
	movl	-8(%rbp), %eax
	movl	%eax, 20+SWITCH_ID_EVENT(%rip)
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	SWITCH_ID_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
.L3:
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	POS_X_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	POS_Y_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	SYNC_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	jmp	.L4
.L2:
	cmpl	$2, -20(%rbp)
	jne	.L5
	cmpl	$-1, -8(%rbp)
	jne	.L6
	leaq	sem_control(%rip), %rdi
	call	sem_post@PLT
	movl	$-1, %eax
	jmp	.L7
.L6:
	movl	-8(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	touch_id(%rip), %rax
	movl	$0, (%rdx,%rax)
	movl	allocatedID_num(%rip), %eax
	subl	$1, %eax
	movl	%eax, allocatedID_num(%rip)
	movl	$-1, 20+DEFINE_UID_EVENT(%rip)
	movl	20+SWITCH_ID_EVENT(%rip), %eax
	cmpl	%eax, -8(%rbp)
	je	.L8
	movl	-8(%rbp), %eax
	movl	%eax, 20+SWITCH_ID_EVENT(%rip)
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	SWITCH_ID_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
.L8:
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	DEFINE_UID_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	movl	allocatedID_num(%rip), %eax
	testl	%eax, %eax
	jne	.L9
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	BTN_UP_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
.L9:
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	SYNC_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	jmp	.L4
.L5:
	cmpl	$1, -20(%rbp)
	jne	.L4
	cmpl	$-1, -8(%rbp)
	jne	.L10
	movl	$0, -4(%rbp)
	jmp	.L11
.L13:
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	touch_id(%rip), %rax
	movl	(%rdx,%rax), %eax
	testl	%eax, %eax
	jne	.L12
	movl	-4(%rbp), %eax
	movl	%eax, -8(%rbp)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	touch_id(%rip), %rax
	movl	$1, (%rdx,%rax)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	postion(%rip), %rax
	movl	-28(%rbp), %edx
	movl	%edx, (%rcx,%rax)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	4+postion(%rip), %rax
	movl	-32(%rbp), %edx
	movl	%edx, (%rcx,%rax)
	movl	allocatedID_num(%rip), %eax
	addl	$1, %eax
	movl	%eax, allocatedID_num(%rip)
	jmp	.L10
.L12:
	addl	$1, -4(%rbp)
.L11:
	cmpl	$9, -4(%rbp)
	jle	.L13
.L10:
	cmpl	$-1, -8(%rbp)
	jne	.L14
	leaq	sem_control(%rip), %rdi
	call	sem_post@PLT
	movl	$-1, %eax
	jmp	.L7
.L14:
	movl	-8(%rbp), %eax
	addl	$226, %eax
	movl	%eax, 20+DEFINE_UID_EVENT(%rip)
	movl	-28(%rbp), %eax
	movl	%eax, 20+POS_X_EVENT(%rip)
	movl	-32(%rbp), %eax
	movl	%eax, 20+POS_Y_EVENT(%rip)
	movl	20+SWITCH_ID_EVENT(%rip), %eax
	cmpl	%eax, -8(%rbp)
	je	.L15
	movl	-8(%rbp), %eax
	movl	%eax, 20+SWITCH_ID_EVENT(%rip)
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	SWITCH_ID_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
.L15:
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	DEFINE_UID_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	movl	allocatedID_num(%rip), %eax
	cmpl	$1, %eax
	jne	.L16
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	BTN_DOWN_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
.L16:
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	POS_X_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	POS_Y_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
	movl	touch_fd(%rip), %eax
	movl	$24, %edx
	leaq	SYNC_EVENT(%rip), %rsi
	movl	%eax, %edi
	call	write@PLT
.L4:
	leaq	sem_control(%rip), %rdi
	call	sem_post@PLT
	movl	-8(%rbp), %eax
.L7:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE5:
	.size	main_controler, .-main_controler
	.globl	mouse_touch_id
	.data
	.align 4
	.type	mouse_touch_id, @object
	.size	mouse_touch_id, 4
mouse_touch_id:
	.long	-1
	.globl	mouse_Start_x
	.align 4
	.type	mouse_Start_x, @object
	.size	mouse_Start_x, 4
mouse_Start_x:
	.long	720
	.globl	mouse_Start_y
	.align 4
	.type	mouse_Start_y, @object
	.size	mouse_Start_y, 4
mouse_Start_y:
	.long	1600
	.comm	realtive_x,4,4
	.comm	realtive_y,4,4
	.globl	mouse_speedRatio
	.align 4
	.type	mouse_speedRatio, @object
	.size	mouse_speedRatio, 4
mouse_speedRatio:
	.long	1
	.comm	km_map_id,1056,32
	.comm	map_postion,2112,32
	.text
	.globl	handel_Mouse_queue
	.type	handel_Mouse_queue, @function
handel_Mouse_queue:
.LFB6:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movzwl	16+Mouse_queue(%rip), %eax
	cmpw	$2, %ax
	jne	.L18
	movl	$0, -12(%rbp)
	movl	$0, -8(%rbp)
	movl	m_len(%rip), %eax
	cmpl	$3, %eax
	jne	.L19
	movl	20+Mouse_queue(%rip), %eax
	movl	%eax, -12(%rbp)
	movl	44+Mouse_queue(%rip), %eax
	movl	%eax, -8(%rbp)
	jmp	.L20
.L19:
	movzwl	18+Mouse_queue(%rip), %eax
	testw	%ax, %ax
	jne	.L21
	movl	20+Mouse_queue(%rip), %eax
	movl	%eax, -12(%rbp)
	jmp	.L20
.L21:
	movl	20+Mouse_queue(%rip), %eax
	movl	%eax, -8(%rbp)
.L20:
	movl	mouse_touch_id(%rip), %eax
	cmpl	$-1, %eax
	jne	.L22
	movl	mouse_Start_y(%rip), %ecx
	movl	mouse_Start_x(%rip), %edx
	movl	mouse_touch_id(%rip), %eax
	movl	%eax, %esi
	movl	$1, %edi
	call	main_controler
	movl	%eax, mouse_touch_id(%rip)
	movl	mouse_Start_x(%rip), %eax
	movl	%eax, realtive_x(%rip)
	movl	mouse_Start_y(%rip), %eax
	movl	%eax, realtive_y(%rip)
	jmp	.L17
.L22:
	movl	realtive_x(%rip), %edx
	movl	mouse_speedRatio(%rip), %eax
	imull	-8(%rbp), %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, realtive_x(%rip)
	movl	mouse_speedRatio(%rip), %eax
	imull	-12(%rbp), %eax
	movl	%eax, %edx
	movl	realtive_y(%rip), %eax
	addl	%edx, %eax
	movl	%eax, realtive_y(%rip)
	movl	realtive_x(%rip), %eax
	cmpl	$99, %eax
	jle	.L24
	movl	realtive_x(%rip), %eax
	cmpl	$1400, %eax
	jg	.L24
	movl	realtive_y(%rip), %eax
	cmpl	$99, %eax
	jle	.L24
	movl	realtive_y(%rip), %eax
	cmpl	$3000, %eax
	jle	.L25
.L24:
	movl	mouse_touch_id(%rip), %eax
	movl	$0, %ecx
	movl	$0, %edx
	movl	%eax, %esi
	movl	$2, %edi
	call	main_controler
	movl	$-1, mouse_touch_id(%rip)
	movl	mouse_Start_y(%rip), %ecx
	movl	mouse_Start_x(%rip), %edx
	movl	mouse_touch_id(%rip), %eax
	movl	%eax, %esi
	movl	$1, %edi
	call	main_controler
	movl	%eax, mouse_touch_id(%rip)
	movl	mouse_Start_x(%rip), %eax
	movl	%eax, realtive_x(%rip)
	movl	mouse_Start_y(%rip), %eax
	movl	%eax, realtive_y(%rip)
.L25:
	movl	realtive_y(%rip), %ecx
	movl	realtive_x(%rip), %edx
	movl	mouse_touch_id(%rip), %eax
	movl	%eax, %esi
	movl	$0, %edi
	call	main_controler
	jmp	.L26
.L18:
	movzwl	16+Mouse_queue(%rip), %eax
	cmpw	$4, %ax
	jne	.L26
	movzwl	42+Mouse_queue(%rip), %eax
	movzwl	%ax, %eax
	subl	$16, %eax
	movl	%eax, -4(%rbp)
	movl	44+Mouse_queue(%rip), %eax
	cmpl	$1, %eax
	jne	.L27
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	4+map_postion(%rip), %rax
	movl	(%rdx,%rax), %edx
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	map_postion(%rip), %rax
	movl	(%rcx,%rax), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	movl	$-1, %esi
	movl	$1, %edi
	call	main_controler
	movl	%eax, %ecx
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	km_map_id(%rip), %rax
	movl	%ecx, (%rdx,%rax)
	jmp	.L26
.L27:
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	km_map_id(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	$0, %ecx
	movl	$0, %edx
	movl	%eax, %esi
	movl	$2, %edi
	call	main_controler
.L26:
	movl	$0, m_len(%rip)
	nop
.L17:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE6:
	.size	handel_Mouse_queue, .-handel_Mouse_queue
	.comm	wheel_satuse,16,16
	.globl	wheel_postion
	.bss
	.align 32
	.type	wheel_postion, @object
	.size	wheel_postion, 72
wheel_postion:
	.zero	72
	.globl	wheel_touch_id
	.data
	.align 4
	.type	wheel_touch_id, @object
	.size	wheel_touch_id, 4
wheel_touch_id:
	.long	-1
	.globl	cur_x
	.bss
	.align 4
	.type	cur_x, @object
	.size	cur_x, 4
cur_x:
	.zero	4
	.globl	cur_y
	.align 4
	.type	cur_y, @object
	.size	cur_y, 4
cur_y:
	.zero	4
	.globl	tar_x
	.align 4
	.type	tar_x, @object
	.size	tar_x, 4
tar_x:
	.zero	4
	.globl	tar_y
	.align 4
	.type	tar_y, @object
	.size	tar_y, 4
tar_y:
	.zero	4
	.globl	move_speed
	.data
	.align 4
	.type	move_speed, @object
	.size	move_speed, 4
move_speed:
	.long	5
	.globl	frequency
	.align 4
	.type	frequency, @object
	.size	frequency, 4
frequency:
	.long	500
	.globl	release_flag
	.bss
	.align 4
	.type	release_flag, @object
	.size	release_flag, 4
release_flag:
	.zero	4
	.text
	.globl	wheel_manager
	.type	wheel_manager, @function
wheel_manager:
.LFB7:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	jmp	.L29
.L41:
	movl	release_flag(%rip), %eax
	testl	%eax, %eax
	jle	.L30
	movl	32+wheel_postion(%rip), %edx
	movl	tar_x(%rip), %eax
	cmpl	%eax, %edx
	jne	.L30
	movl	36+wheel_postion(%rip), %edx
	movl	tar_y(%rip), %eax
	cmpl	%eax, %edx
	jne	.L30
	movl	tar_x(%rip), %eax
	movl	%eax, cur_x(%rip)
	movl	tar_y(%rip), %eax
	movl	%eax, cur_y(%rip)
	movl	wheel_touch_id(%rip), %eax
	movl	$0, %ecx
	movl	$0, %edx
	movl	%eax, %esi
	movl	$2, %edi
	call	main_controler
	movl	$-1, wheel_touch_id(%rip)
	movl	release_flag(%rip), %eax
	subl	$1, %eax
	movl	%eax, release_flag(%rip)
	jmp	.L31
.L30:
	movl	tar_x(%rip), %edx
	movl	cur_x(%rip), %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, -8(%rbp)
	movl	tar_y(%rip), %edx
	movl	cur_y(%rip), %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, -4(%rbp)
	cmpl	$0, -8(%rbp)
	je	.L32
	movl	-8(%rbp), %eax
	cltd
	movl	%edx, %eax
	xorl	-8(%rbp), %eax
	subl	%edx, %eax
	movl	move_speed(%rip), %edx
	cmpl	%edx, %eax
	jle	.L33
	cmpl	$0, -8(%rbp)
	jg	.L34
	movl	move_speed(%rip), %eax
	negl	%eax
	jmp	.L35
.L34:
	movl	move_speed(%rip), %eax
.L35:
	movl	cur_x(%rip), %edx
	addl	%edx, %eax
	movl	%eax, cur_x(%rip)
	jmp	.L32
.L33:
	movl	tar_x(%rip), %eax
	movl	%eax, cur_x(%rip)
.L32:
	cmpl	$0, -4(%rbp)
	je	.L36
	movl	-4(%rbp), %eax
	cltd
	movl	%edx, %eax
	xorl	-4(%rbp), %eax
	subl	%edx, %eax
	movl	move_speed(%rip), %edx
	cmpl	%edx, %eax
	jle	.L37
	cmpl	$0, -4(%rbp)
	jg	.L38
	movl	move_speed(%rip), %eax
	negl	%eax
	jmp	.L39
.L38:
	movl	move_speed(%rip), %eax
.L39:
	movl	cur_y(%rip), %edx
	addl	%edx, %eax
	movl	%eax, cur_y(%rip)
	jmp	.L36
.L37:
	movl	tar_y(%rip), %eax
	movl	%eax, cur_y(%rip)
.L36:
	cmpl	$0, -8(%rbp)
	jne	.L40
	cmpl	$0, -4(%rbp)
	je	.L31
.L40:
	movl	cur_y(%rip), %ecx
	movl	cur_x(%rip), %edx
	movl	wheel_touch_id(%rip), %eax
	movl	%eax, %esi
	movl	$0, %edi
	call	main_controler
.L31:
	movl	frequency(%rip), %eax
	movl	%eax, %edi
	call	usleep@PLT
.L29:
	movl	Exclusive_mode_flag(%rip), %eax
	testl	%eax, %eax
	jne	.L41
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE7:
	.size	wheel_manager, .-wheel_manager
	.globl	change_wheel_satuse
	.type	change_wheel_satuse, @function
change_wheel_satuse:
.LFB8:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movl	%edi, -36(%rbp)
	movl	%esi, -40(%rbp)
	movl	4+wheel_satuse(%rip), %eax
	movl	$1, %edx
	subl	%eax, %edx
	movl	12+wheel_satuse(%rip), %eax
	addl	%edx, %eax
	movl	%eax, -20(%rbp)
	movl	8+wheel_satuse(%rip), %eax
	movl	$1, %edx
	subl	%eax, %edx
	movl	wheel_satuse(%rip), %eax
	addl	%edx, %eax
	movl	%eax, -16(%rbp)
	movl	-20(%rbp), %edx
	movl	%edx, %eax
	addl	%eax, %eax
	addl	%eax, %edx
	movl	-16(%rbp), %eax
	addl	%edx, %eax
	movl	%eax, -12(%rbp)
	movl	$-1, -8(%rbp)
	movl	-36(%rbp), %eax
	cmpl	$30, %eax
	je	.L44
	cmpl	$30, %eax
	jg	.L45
	cmpl	$17, %eax
	je	.L46
	jmp	.L49
.L45:
	cmpl	$31, %eax
	je	.L47
	cmpl	$32, %eax
	je	.L48
	jmp	.L49
.L46:
	movl	-40(%rbp), %eax
	movl	%eax, wheel_satuse(%rip)
	jmp	.L49
.L44:
	movl	-40(%rbp), %eax
	movl	%eax, 4+wheel_satuse(%rip)
	jmp	.L49
.L47:
	movl	-40(%rbp), %eax
	movl	%eax, 8+wheel_satuse(%rip)
	jmp	.L49
.L48:
	movl	-40(%rbp), %eax
	movl	%eax, 12+wheel_satuse(%rip)
	nop
.L49:
	movl	4+wheel_satuse(%rip), %eax
	movl	$1, %edx
	subl	%eax, %edx
	movl	12+wheel_satuse(%rip), %eax
	addl	%edx, %eax
	movl	%eax, -20(%rbp)
	movl	8+wheel_satuse(%rip), %eax
	movl	$1, %edx
	subl	%eax, %edx
	movl	wheel_satuse(%rip), %eax
	addl	%edx, %eax
	movl	%eax, -16(%rbp)
	movl	-20(%rbp), %edx
	movl	%edx, %eax
	addl	%eax, %eax
	addl	%eax, %edx
	movl	-16(%rbp), %eax
	addl	%edx, %eax
	movl	%eax, -4(%rbp)
	cmpl	$4, -12(%rbp)
	jne	.L50
	cmpl	$4, -4(%rbp)
	je	.L50
	movl	32+wheel_postion(%rip), %eax
	movl	%eax, tar_x(%rip)
	movl	36+wheel_postion(%rip), %eax
	movl	%eax, tar_y(%rip)
	movl	tar_x(%rip), %eax
	movl	%eax, cur_x(%rip)
	movl	tar_y(%rip), %eax
	movl	%eax, cur_y(%rip)
	movl	36+wheel_postion(%rip), %edx
	movl	32+wheel_postion(%rip), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	movl	$-1, %esi
	movl	$1, %edi
	call	main_controler
	movl	%eax, wheel_touch_id(%rip)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	wheel_postion(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	%eax, tar_x(%rip)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	4+wheel_postion(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	%eax, tar_y(%rip)
	jmp	.L53
.L50:
	cmpl	$4, -4(%rbp)
	je	.L52
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	wheel_postion(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	%eax, tar_x(%rip)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	4+wheel_postion(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	%eax, tar_y(%rip)
	jmp	.L53
.L52:
	movl	32+wheel_postion(%rip), %eax
	movl	%eax, tar_x(%rip)
	movl	36+wheel_postion(%rip), %eax
	movl	%eax, tar_y(%rip)
	movl	release_flag(%rip), %eax
	addl	$1, %eax
	movl	%eax, release_flag(%rip)
.L53:
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE8:
	.size	change_wheel_satuse, .-change_wheel_satuse
	.globl	handel_Keyboard_queue
	.type	handel_Keyboard_queue, @function
handel_Keyboard_queue:
.LFB9:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	k_len(%rip), %eax
	subl	$2, %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	movq	%rax, %rdx
	leaq	18+Keyboard_queue(%rip), %rax
	movzwl	(%rdx,%rax), %eax
	movzwl	%ax, %eax
	movl	%eax, -12(%rbp)
	movl	k_len(%rip), %eax
	subl	$2, %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	movq	%rax, %rdx
	leaq	20+Keyboard_queue(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	%eax, -8(%rbp)
	cmpl	$41, -12(%rbp)
	jne	.L55
	cmpl	$0, -8(%rbp)
	jne	.L55
	movl	Exclusive_mode_flag(%rip), %eax
	movl	%eax, -4(%rbp)
	movl	no_Exclusive_mode_flag(%rip), %eax
	movl	%eax, Exclusive_mode_flag(%rip)
	movl	-4(%rbp), %eax
	movl	%eax, no_Exclusive_mode_flag(%rip)
	jmp	.L56
.L55:
	movl	Exclusive_mode_flag(%rip), %eax
	cmpl	$1, %eax
	jne	.L56
	cmpl	$17, -12(%rbp)
	je	.L57
	cmpl	$30, -12(%rbp)
	je	.L57
	cmpl	$31, -12(%rbp)
	je	.L57
	cmpl	$32, -12(%rbp)
	jne	.L58
.L57:
	movl	-8(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	change_wheel_satuse
	jmp	.L56
.L58:
	movl	-12(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	map_postion(%rip), %rax
	movl	(%rdx,%rax), %eax
	testl	%eax, %eax
	je	.L56
	movl	-12(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	4+map_postion(%rip), %rax
	movl	(%rdx,%rax), %eax
	testl	%eax, %eax
	je	.L56
	cmpl	$1, -8(%rbp)
	jne	.L59
	movl	-12(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	4+map_postion(%rip), %rax
	movl	(%rdx,%rax), %edx
	movl	-12(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	map_postion(%rip), %rax
	movl	(%rcx,%rax), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	movl	$-1, %esi
	movl	$1, %edi
	call	main_controler
	movl	%eax, %ecx
	movl	-12(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	km_map_id(%rip), %rax
	movl	%ecx, (%rdx,%rax)
	jmp	.L56
.L59:
	movl	-12(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	km_map_id(%rip), %rax
	movl	(%rdx,%rax), %eax
	movl	$0, %ecx
	movl	$0, %edx
	movl	%eax, %esi
	movl	$2, %edi
	call	main_controler
.L56:
	movl	$0, k_len(%rip)
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE9:
	.size	handel_Keyboard_queue, .-handel_Keyboard_queue
	.section	.rodata
.LC0:
	.string	"could not open touchScreen\n"
.LC1:
	.string	"Failed to open keyboard."
.LC2:
	.string	"Reading From : %s \n"
.LC3:
	.string	"Getting exclusive access: "
.LC4:
	.string	"SUCCESS"
.LC5:
	.string	"FAILURE"
.LC6:
	.string	"Failed to open mouse."
.LC7:
	.string	"Exiting."
	.text
	.globl	Exclusive_mode
	.type	Exclusive_mode, @function
Exclusive_mode:
.LFB10:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$640, %rsp
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movl	$2, %esi
	leaq	touch_dev_path(%rip), %rdi
	movl	$0, %eax
	call	open@PLT
	movl	%eax, touch_fd(%rip)
	movl	$0, -628(%rbp)
	jmp	.L62
.L63:
	movl	-628(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	wheel_satuse(%rip), %rax
	movl	$0, (%rdx,%rax)
	addl	$1, -628(%rbp)
.L62:
	cmpl	$3, -628(%rbp)
	jle	.L63
	movl	touch_fd(%rip), %eax
	testl	%eax, %eax
	jns	.L64
	movq	stderr(%rip), %rax
	movq	%rax, %rcx
	movl	$27, %edx
	movl	$1, %esi
	leaq	.LC0(%rip), %rdi
	call	fwrite@PLT
	movl	Exclusive_mode_flag(%rip), %eax
	movl	%eax, -604(%rbp)
	movl	no_Exclusive_mode_flag(%rip), %eax
	movl	%eax, Exclusive_mode_flag(%rip)
	movl	-604(%rbp), %eax
	movl	%eax, no_Exclusive_mode_flag(%rip)
	movl	$1, %eax
	jmp	.L80
.L64:
	movl	$0, -616(%rbp)
	movabsq	$31093567915781717, %rax
	movl	$0, %edx
	movq	%rax, -528(%rbp)
	movq	%rdx, -520(%rbp)
	leaq	-512(%rbp), %rdx
	movl	$0, %eax
	movl	$30, %ecx
	movq	%rdx, %rdi
	rep stosq
	movl	$2048, %esi
	leaq	keyboard_dev_path(%rip), %rdi
	movl	$0, %eax
	call	open@PLT
	movl	%eax, -612(%rbp)
	cmpl	$-1, -612(%rbp)
	jne	.L66
	leaq	.LC1(%rip), %rdi
	call	puts@PLT
	movl	$1, %edi
	call	exit@PLT
.L66:
	leaq	-528(%rbp), %rdx
	movl	-612(%rbp), %eax
	movl	$2164278534, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -616(%rbp)
	leaq	-528(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	leaq	.LC3(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	-612(%rbp), %eax
	movl	$1, %edx
	movl	$1074021776, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -616(%rbp)
	cmpl	$0, -616(%rbp)
	jne	.L67
	leaq	.LC4(%rip), %rax
	jmp	.L68
.L67:
	leaq	.LC5(%rip), %rax
.L68:
	movq	%rax, %rdi
	call	puts@PLT
	movabsq	$31093567915781717, %rax
	movl	$0, %edx
	movq	%rax, -272(%rbp)
	movq	%rdx, -264(%rbp)
	leaq	-256(%rbp), %rdx
	movl	$0, %eax
	movl	$30, %ecx
	movq	%rdx, %rdi
	rep stosq
	movl	$2048, %esi
	leaq	mouse_dev_path(%rip), %rdi
	movl	$0, %eax
	call	open@PLT
	movl	%eax, -608(%rbp)
	cmpl	$-1, -608(%rbp)
	jne	.L69
	leaq	.LC6(%rip), %rdi
	call	puts@PLT
	movl	$1, %edi
	call	exit@PLT
.L69:
	leaq	-272(%rbp), %rdx
	movl	-608(%rbp), %eax
	movl	$2164278534, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -616(%rbp)
	leaq	-272(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	leaq	.LC3(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	-608(%rbp), %eax
	movl	$1, %edx
	movl	$1074021776, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -616(%rbp)
	cmpl	$0, -616(%rbp)
	jne	.L70
	leaq	.LC4(%rip), %rax
	jmp	.L71
.L70:
	leaq	.LC5(%rip), %rax
.L71:
	movq	%rax, %rdi
	call	puts@PLT
	movl	32+wheel_postion(%rip), %eax
	movl	%eax, cur_x(%rip)
	movl	36+wheel_postion(%rip), %eax
	movl	%eax, cur_y(%rip)
	movl	cur_x(%rip), %eax
	movl	%eax, tar_x(%rip)
	movl	cur_y(%rip), %eax
	movl	%eax, tar_y(%rip)
	leaq	-600(%rbp), %rax
	movl	$0, %ecx
	leaq	wheel_manager(%rip), %rdx
	movl	$0, %esi
	movq	%rax, %rdi
	call	pthread_create@PLT
	jmp	.L72
.L74:
	leaq	-592(%rbp), %rcx
	movl	-612(%rbp), %eax
	movl	$24, %edx
	movq	%rcx, %rsi
	movl	%eax, %edi
	call	read@PLT
	cmpq	$-1, %rax
	je	.L73
	movl	k_len(%rip), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	movq	%rax, %rsi
	leaq	Keyboard_queue(%rip), %rcx
	movq	-592(%rbp), %rax
	movq	-584(%rbp), %rdx
	movq	%rax, (%rsi,%rcx)
	movq	%rdx, 8(%rsi,%rcx)
	movq	-576(%rbp), %rax
	movq	%rax, 16(%rsi,%rcx)
	movl	k_len(%rip), %eax
	addl	$1, %eax
	movl	%eax, k_len(%rip)
	movzwl	-576(%rbp), %eax
	testw	%ax, %ax
	jne	.L73
	movzwl	-574(%rbp), %eax
	testw	%ax, %ax
	jne	.L73
	movl	-572(%rbp), %eax
	testl	%eax, %eax
	jne	.L73
	movl	$0, %eax
	call	handel_Keyboard_queue
.L73:
	leaq	-560(%rbp), %rcx
	movl	-608(%rbp), %eax
	movl	$24, %edx
	movq	%rcx, %rsi
	movl	%eax, %edi
	call	read@PLT
	cmpq	$-1, %rax
	je	.L72
	movl	m_len(%rip), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	movq	%rax, %rsi
	leaq	Mouse_queue(%rip), %rcx
	movq	-560(%rbp), %rax
	movq	-552(%rbp), %rdx
	movq	%rax, (%rsi,%rcx)
	movq	%rdx, 8(%rsi,%rcx)
	movq	-544(%rbp), %rax
	movq	%rax, 16(%rsi,%rcx)
	movl	m_len(%rip), %eax
	addl	$1, %eax
	movl	%eax, m_len(%rip)
	movzwl	-544(%rbp), %eax
	testw	%ax, %ax
	jne	.L72
	movzwl	-542(%rbp), %eax
	testw	%ax, %ax
	jne	.L72
	movl	-540(%rbp), %eax
	testl	%eax, %eax
	jne	.L72
	movl	$0, %eax
	call	handel_Mouse_queue
.L72:
	movl	Exclusive_mode_flag(%rip), %eax
	cmpl	$1, %eax
	je	.L74
	leaq	.LC7(%rip), %rdi
	call	puts@PLT
	movq	-600(%rbp), %rax
	movl	$0, %esi
	movq	%rax, %rdi
	call	pthread_join@PLT
	movl	-612(%rbp), %eax
	movl	$1, %edx
	movl	$1074021776, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -616(%rbp)
	movl	-612(%rbp), %eax
	movl	%eax, %edi
	call	close@PLT
	movl	-608(%rbp), %eax
	movl	$1, %edx
	movl	$1074021776, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -616(%rbp)
	movl	-608(%rbp), %eax
	movl	%eax, %edi
	call	close@PLT
	movl	$0, -624(%rbp)
	jmp	.L75
.L76:
	movl	-624(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	wheel_satuse(%rip), %rax
	movl	$0, (%rdx,%rax)
	addl	$1, -624(%rbp)
.L75:
	cmpl	$3, -624(%rbp)
	jle	.L76
	movl	$0, -620(%rbp)
	jmp	.L77
.L79:
	movl	-620(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	touch_id(%rip), %rax
	movl	(%rdx,%rax), %eax
	testl	%eax, %eax
	je	.L78
	movl	-620(%rbp), %eax
	movl	$0, %ecx
	movl	$0, %edx
	movl	%eax, %esi
	movl	$2, %edi
	call	main_controler
.L78:
	addl	$1, -620(%rbp)
.L77:
	cmpl	$9, -620(%rbp)
	jle	.L79
	movl	$-1, mouse_touch_id(%rip)
	movl	$-1, wheel_touch_id(%rip)
	movl	$-1, 20+SWITCH_ID_EVENT(%rip)
	movl	touch_fd(%rip), %eax
	movl	%eax, %edi
	call	close@PLT
	movl	$0, %eax
.L80:
	movq	-8(%rbp), %rcx
	xorq	%fs:40, %rcx
	je	.L81
	call	__stack_chk_fail@PLT
.L81:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE10:
	.size	Exclusive_mode, .-Exclusive_mode
	.globl	no_Exclusive_mode
	.type	no_Exclusive_mode, @function
no_Exclusive_mode:
.LFB11:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$320, %rsp
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movl	$0, -312(%rbp)
	movabsq	$31093567915781717, %rax
	movl	$0, %edx
	movq	%rax, -272(%rbp)
	movq	%rdx, -264(%rbp)
	leaq	-256(%rbp), %rdx
	movl	$0, %eax
	movl	$30, %ecx
	movq	%rdx, %rdi
	rep stosq
	movl	$2048, %esi
	leaq	keyboard_dev_path(%rip), %rdi
	movl	$0, %eax
	call	open@PLT
	movl	%eax, -308(%rbp)
	cmpl	$-1, -308(%rbp)
	jne	.L83
	leaq	.LC1(%rip), %rdi
	call	puts@PLT
	movl	$1, %edi
	call	exit@PLT
.L83:
	leaq	-272(%rbp), %rdx
	movl	-308(%rbp), %eax
	movl	$2164278534, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl@PLT
	movl	%eax, -312(%rbp)
	leaq	-272(%rbp), %rax
	movq	%rax, %rsi
	leaq	.LC2(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	jmp	.L84
.L85:
	leaq	-304(%rbp), %rcx
	movl	-308(%rbp), %eax
	movl	$24, %edx
	movq	%rcx, %rsi
	movl	%eax, %edi
	call	read@PLT
	cmpq	$-1, %rax
	je	.L84
	movl	k_len(%rip), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	movq	%rax, %rsi
	leaq	Keyboard_queue(%rip), %rcx
	movq	-304(%rbp), %rax
	movq	-296(%rbp), %rdx
	movq	%rax, (%rsi,%rcx)
	movq	%rdx, 8(%rsi,%rcx)
	movq	-288(%rbp), %rax
	movq	%rax, 16(%rsi,%rcx)
	movl	k_len(%rip), %eax
	addl	$1, %eax
	movl	%eax, k_len(%rip)
	movzwl	-288(%rbp), %eax
	testw	%ax, %ax
	jne	.L84
	movzwl	-286(%rbp), %eax
	testw	%ax, %ax
	jne	.L84
	movl	-284(%rbp), %eax
	testl	%eax, %eax
	jne	.L84
	movl	$0, %eax
	call	handel_Keyboard_queue
.L84:
	movl	no_Exclusive_mode_flag(%rip), %eax
	cmpl	$1, %eax
	je	.L85
	leaq	.LC7(%rip), %rdi
	call	puts@PLT
	movl	-308(%rbp), %eax
	movl	%eax, %edi
	call	close@PLT
	movl	$0, %eax
	movq	-8(%rbp), %rcx
	xorq	%fs:40, %rcx
	je	.L87
	call	__stack_chk_fail@PLT
.L87:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE11:
	.size	no_Exclusive_mode, .-no_Exclusive_mode
	.section	.rodata
.LC8:
	.string	"/dev/input/event%d"
.LC9:
	.string	"Touch_dev_path:%s\n"
.LC10:
	.string	"Mouse_dev_path:%s\n"
.LC11:
	.string	"Keyboard_dev_path:%s\n"
.LC12:
	.string	"Fail to sem_sem_control init"
.LC13:
	.string	"Reading config from %s\n"
.LC14:
	.string	"r"
	.align 8
.LC15:
	.string	"Can't read map file from %s, %s\n"
.LC16:
	.string	"\n"
.LC17:
	.string	" "
	.text
	.globl	main
	.type	main, @function
main:
.LFB12:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$11280, %rsp
	movl	%edi, -11268(%rbp)
	movq	%rsi, -11280(%rbp)
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movq	-11280(%rbp), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	atoi@PLT
	movl	%eax, -11236(%rbp)
	movq	-11280(%rbp), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	atoi@PLT
	movl	%eax, -11232(%rbp)
	movq	-11280(%rbp), %rax
	addq	$24, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	atoi@PLT
	movl	%eax, -11228(%rbp)
	movl	-11232(%rbp), %eax
	movl	%eax, mouse_dev(%rip)
	movl	-11228(%rbp), %eax
	movl	%eax, keyboard_dev(%rip)
	movl	-11236(%rbp), %eax
	movl	%eax, %edx
	leaq	.LC8(%rip), %rsi
	leaq	touch_dev_path(%rip), %rdi
	movl	$0, %eax
	call	sprintf@PLT
	movl	-11232(%rbp), %eax
	movl	%eax, %edx
	leaq	.LC8(%rip), %rsi
	leaq	mouse_dev_path(%rip), %rdi
	movl	$0, %eax
	call	sprintf@PLT
	movl	-11228(%rbp), %eax
	movl	%eax, %edx
	leaq	.LC8(%rip), %rsi
	leaq	keyboard_dev_path(%rip), %rdi
	movl	$0, %eax
	call	sprintf@PLT
	leaq	touch_dev_path(%rip), %rsi
	leaq	.LC9(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	leaq	mouse_dev_path(%rip), %rsi
	leaq	.LC10(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	leaq	keyboard_dev_path(%rip), %rsi
	leaq	.LC11(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	$1, %edx
	movl	$0, %esi
	leaq	sem_control(%rip), %rdi
	call	sem_init@PLT
	testl	%eax, %eax
	je	.L89
	leaq	.LC12(%rip), %rdi
	call	perror@PLT
	movl	$-1, %edi
	call	exit@PLT
.L89:
	movq	-11280(%rbp), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	dirname@PLT
	movq	%rax, %rdi
	call	chdir@PLT
	movq	-11280(%rbp), %rax
	addq	$32, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	leaq	.LC13(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movq	-11280(%rbp), %rax
	addq	$32, %rax
	movq	(%rax), %rax
	leaq	.LC14(%rip), %rsi
	movq	%rax, %rdi
	call	fopen@PLT
	movq	%rax, -11216(%rbp)
	cmpq	$0, -11216(%rbp)
	jne	.L90
	call	__errno_location@PLT
	movl	(%rax), %eax
	movl	%eax, %edi
	call	strerror@PLT
	movq	%rax, %rcx
	movq	-11280(%rbp), %rax
	addq	$32, %rax
	movq	(%rax), %rdx
	movq	stderr(%rip), %rax
	leaq	.LC15(%rip), %rsi
	movq	%rax, %rdi
	movl	$0, %eax
	call	fprintf@PLT
	movl	$-2, %edi
	call	exit@PLT
.L90:
	movq	-11216(%rbp), %rdx
	leaq	-8208(%rbp), %rax
	movq	%rdx, %rcx
	movl	$1, %edx
	movl	$8192, %esi
	movq	%rax, %rdi
	call	fread@PLT
	movq	-11216(%rbp), %rax
	movq	%rax, %rdi
	call	fclose@PLT
	movl	$0, -11252(%rbp)
	leaq	-8208(%rbp), %rax
	leaq	.LC16(%rip), %rsi
	movq	%rax, %rdi
	call	strtok@PLT
	movq	%rax, -11224(%rbp)
	jmp	.L91
.L92:
	movl	-11252(%rbp), %eax
	leal	1(%rax), %edx
	movl	%edx, -11252(%rbp)
	leaq	-10384(%rbp), %rdx
	cltq
	salq	$5, %rax
	addq	%rax, %rdx
	movq	-11224(%rbp), %rax
	movq	%rax, %rsi
	movq	%rdx, %rdi
	call	strcpy@PLT
	leaq	.LC16(%rip), %rsi
	movl	$0, %edi
	call	strtok@PLT
	movq	%rax, -11224(%rbp)
.L91:
	cmpq	$0, -11224(%rbp)
	jne	.L92
	movl	$0, -11248(%rbp)
	jmp	.L93
.L94:
	leaq	-10384(%rbp), %rax
	movl	-11248(%rbp), %edx
	movslq	%edx, %rdx
	salq	$5, %rdx
	addq	%rdx, %rax
	leaq	.LC17(%rip), %rsi
	movq	%rax, %rdi
	call	strtok@PLT
	movq	%rax, -11208(%rbp)
	movq	-11208(%rbp), %rax
	movq	%rax, %rdi
	call	atoi@PLT
	movl	%eax, %ecx
	movl	-11248(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11200, %rax
	movl	%ecx, (%rax)
	leaq	.LC17(%rip), %rsi
	movl	$0, %edi
	call	strtok@PLT
	movq	%rax, %rdi
	call	atoi@PLT
	movl	%eax, %ecx
	movl	-11248(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11196, %rax
	movl	%ecx, (%rax)
	leaq	.LC17(%rip), %rsi
	movl	$0, %edi
	call	strtok@PLT
	movq	%rax, %rdi
	call	atoi@PLT
	movl	%eax, %ecx
	movl	-11248(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11192, %rax
	movl	%ecx, (%rax)
	addl	$1, -11248(%rbp)
.L93:
	movl	-11248(%rbp), %eax
	cmpl	-11252(%rbp), %eax
	jl	.L94
	movl	-11200(%rbp), %eax
	movl	%eax, mouse_Start_x(%rip)
	movl	-11196(%rbp), %eax
	movl	%eax, mouse_Start_y(%rip)
	movl	-11192(%rbp), %eax
	movl	%eax, mouse_speedRatio(%rip)
	movl	$0, -11244(%rbp)
	jmp	.L95
.L96:
	movl	-11244(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11196, %rax
	movl	(%rax), %edx
	movl	-11244(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	wheel_postion(%rip), %rax
	movl	%edx, (%rcx,%rax)
	movl	-11244(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11192, %rax
	movl	(%rax), %edx
	movl	-11244(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	4+wheel_postion(%rip), %rax
	movl	%edx, (%rcx,%rax)
	addl	$1, -11244(%rbp)
.L95:
	cmpl	$8, -11244(%rbp)
	jle	.L96
	movl	$9, -11240(%rbp)
	jmp	.L97
.L98:
	movl	-11240(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11200, %rax
	movl	(%rax), %ecx
	movl	-11240(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11196, %rax
	movl	(%rax), %edx
	movslq	%ecx, %rax
	leaq	0(,%rax,8), %rcx
	leaq	map_postion(%rip), %rax
	movl	%edx, (%rcx,%rax)
	movl	-11240(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11200, %rax
	movl	(%rax), %ecx
	movl	-11240(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$2, %rax
	addq	%rbp, %rax
	subq	$11192, %rax
	movl	(%rax), %edx
	movslq	%ecx, %rax
	leaq	0(,%rax,8), %rcx
	leaq	4+map_postion(%rip), %rax
	movl	%edx, (%rcx,%rax)
	addl	$1, -11240(%rbp)
.L97:
	movl	-11240(%rbp), %eax
	cmpl	-11252(%rbp), %eax
	jl	.L98
.L99:
	movl	$0, %eax
	call	no_Exclusive_mode
	movl	$0, %eax
	call	Exclusive_mode
	jmp	.L99
	.cfi_endproc
.LFE12:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0"
	.section	.note.GNU-stack,"",@progbits
