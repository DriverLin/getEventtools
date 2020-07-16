   1              		.file	"mapper.c"
   2              		.text
   3              	.Ltext0:
   4              		.comm	touch_dev_path,80,32
   5              		.comm	keyboard_dev_path,80,32
   6              		.comm	mouse_dev_path,80,32
   7              		.globl	keyboard_dev
   8              		.data
   9              		.align 4
  12              	keyboard_dev:
  13 0000 10000000 		.long	16
  14              		.globl	mouse_dev
  15              		.align 4
  18              	mouse_dev:
  19 0004 0F000000 		.long	15
  20              		.comm	touch_fd,4,4
  21              		.globl	Exclusive_mode_flag
  22              		.bss
  23              		.align 4
  26              	Exclusive_mode_flag:
  27 0000 00000000 		.zero	4
  28              		.globl	no_Exclusive_mode_flag
  29              		.data
  30              		.align 4
  33              	no_Exclusive_mode_flag:
  34 0008 01000000 		.long	1
  35              		.comm	Mouse_queue,384,32
  36              		.globl	m_len
  37              		.bss
  38              		.align 4
  41              	m_len:
  42 0004 00000000 		.zero	4
  43              		.comm	Keyboard_queue,384,32
  44              		.globl	k_len
  45              		.align 4
  48              	k_len:
  49 0008 00000000 		.zero	4
  50              		.globl	touch_id
  51 000c 00000000 		.align 32
  51      00000000 
  51      00000000 
  51      00000000 
  51      00000000 
  54              	touch_id:
  55 0020 00000000 		.zero	40
  55      00000000 
  55      00000000 
  55      00000000 
  55      00000000 
  56              		.comm	postion,80,32
  57              		.globl	allocatedID_num
  58              		.align 4
  61              	allocatedID_num:
  62 0048 00000000 		.zero	4
  63              		.globl	SYNC_EVENT
  64 004c 00000000 		.align 16
  67              	SYNC_EVENT:
  68 0050 00000000 		.zero	24
  68      00000000 
  68      00000000 
  68      00000000 
  68      00000000 
  69              		.globl	SWITCH_ID_EVENT
  70              		.data
  71 000c 00000000 		.align 16
  74              	SWITCH_ID_EVENT:
  75 0010 00000000 		.quad	0
  75      00000000 
  76 0018 03000000 		.quad	3
  76      00000000 
  79 0024 00000000 		.zero	4
  80              		.globl	POS_X_EVENT
  81 0028 00000000 		.align 16
  81      00000000 
  84              	POS_X_EVENT:
  85 0030 00000000 		.quad	0
  85      00000000 
  86 0038 03000000 		.quad	3
  86      00000000 
  89 0044 00000000 		.zero	4
  90              		.globl	POS_Y_EVENT
  91 0048 00000000 		.align 16
  91      00000000 
  94              	POS_Y_EVENT:
  95 0050 00000000 		.quad	0
  95      00000000 
  96 0058 03000000 		.quad	3
  96      00000000 
  99 0064 00000000 		.zero	4
 100              		.globl	DEFINE_UID_EVENT
 101 0068 00000000 		.align 16
 101      00000000 
 104              	DEFINE_UID_EVENT:
 105 0070 00000000 		.quad	0
 105      00000000 
 106 0078 03000000 		.quad	3
 106      00000000 
 109 0084 00000000 		.zero	4
 110              		.globl	BTN_DOWN_EVENT
 111 0088 00000000 		.align 16
 111      00000000 
 114              	BTN_DOWN_EVENT:
 115 0090 00000000 		.quad	0
 115      00000000 
 116 0098 01000000 		.quad	1
 116      00000000 
 119 00a4 00000000 		.zero	4
 120              		.globl	BTN_UP_EVENT
 121 00a8 00000000 		.align 16
 121      00000000 
 124              	BTN_UP_EVENT:
 125 00b0 00000000 		.quad	0
 125      00000000 
 126 00b8 01000000 		.quad	1
 126      00000000 
 129 00c4 00000000 		.zero	4
 130              		.comm	sem_control,32,32
 131              		.text
 132              		.globl	main_controler
 134              	main_controler:
 135              	.LFB5:
 136              		.file 1 "mapper.c"
   1:mapper.c      **** #include <stdio.h>
   2:mapper.c      **** #include <stdlib.h>
   3:mapper.c      **** #include <unistd.h>
   4:mapper.c      **** #include <fcntl.h>
   5:mapper.c      **** #include <linux/input.h>
   6:mapper.c      **** #include <time.h>
   7:mapper.c      **** #include <stdint.h>
   8:mapper.c      **** #include <limits.h>
   9:mapper.c      **** #include <sys/types.h>
  10:mapper.c      **** #include <sys/stat.h>
  11:mapper.c      **** #include <string.h>
  12:mapper.c      **** #include <errno.h>
  13:mapper.c      **** #include <libgen.h>
  14:mapper.c      **** #include <semaphore.h>
  15:mapper.c      **** #include <pthread.h>
  16:mapper.c      **** 
  17:mapper.c      **** #define DOWN 0x1
  18:mapper.c      **** #define UP 0x0
  19:mapper.c      **** #define MOVE_FLAG 0x0
  20:mapper.c      **** #define RELEASE_FLAG 0x2
  21:mapper.c      **** #define REQURIE_FLAG 0x1
  22:mapper.c      **** 
  23:mapper.c      **** char touch_dev_path[80];
  24:mapper.c      **** char keyboard_dev_path[80];
  25:mapper.c      **** char mouse_dev_path[80];
  26:mapper.c      **** 
  27:mapper.c      **** int keyboard_dev = 16;
  28:mapper.c      **** int mouse_dev = 15;
  29:mapper.c      **** 
  30:mapper.c      **** int touch_fd; //触屏的设备文件指针
  31:mapper.c      **** 
  32:mapper.c      **** int Exclusive_mode_flag = 0;    //独占模式标识
  33:mapper.c      **** int no_Exclusive_mode_flag = 1; //刚开始 进入非独占模式
  34:mapper.c      **** 
  35:mapper.c      **** struct input_event Mouse_queue[16]; //鼠标信号队列
  36:mapper.c      **** int m_len = 0;                      //队列长度
  37:mapper.c      **** 
  38:mapper.c      **** struct input_event Keyboard_queue[16]; //键盘信号队列
  39:mapper.c      **** int k_len = 0;                         //键盘队列长度
  40:mapper.c      **** 
  41:mapper.c      **** int touch_id[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  42:mapper.c      **** int postion[10][2];
  43:mapper.c      **** int allocatedID_num = 0;
  44:mapper.c      **** 
  45:mapper.c      **** struct input_event SYNC_EVENT = {0, EV_SYN, SYN_REPORT, 0};               //同步 最常用的 直
  46:mapper.c      **** struct input_event SWITCH_ID_EVENT = {0, EV_ABS, ABS_MT_SLOT, -1};        //切换触摸点 修改v
  47:mapper.c      **** struct input_event POS_X_EVENT = {0, EV_ABS, ABS_MT_POSITION_X, 0};       //X坐标
  48:mapper.c      **** struct input_event POS_Y_EVENT = {0, EV_ABS, ABS_MT_POSITION_Y, 0};       //Y坐标
  49:mapper.c      **** struct input_event DEFINE_UID_EVENT = {0, EV_ABS, ABS_MT_TRACKING_ID, 0}; //声明识别ID 用于�
  50:mapper.c      **** struct input_event BTN_DOWN_EVENT = {0, EV_KEY, BTN_TOUCH, 1};            //按下 没有触摸点�
  51:mapper.c      **** struct input_event BTN_UP_EVENT = {0, EV_KEY, BTN_TOUCH, 0};              //释放 触摸点全部�
  52:mapper.c      **** //type = 0,1,2 id = -1,.... ,x,y      ID为-1 则是按下，获取返回的ID，下次带上才可
  53:mapper.c      **** //x,y为绝对坐标 越界重置也由外部完成
  54:mapper.c      **** //按下 移动 释放
  55:mapper.c      **** //滑动 = 按下+移动+释放
  56:mapper.c      **** //不提供点击功能
  57:mapper.c      **** //点击 = 按下 + 释放
  58:mapper.c      **** //超出10点个不响应
  59:mapper.c      **** //返回触摸点的ID 下次带上
  60:mapper.c      **** //鼠标的映射 鼠标一开始就占一个 切换后才释放 是申请还是移动 在外边判
  61:mapper.c      **** //由于多线程 保证安全加上PV
  62:mapper.c      **** sem_t sem_control;
  63:mapper.c      **** int main_controler(int type, int unclear_id, int x, int y)
  64:mapper.c      **** {
 137              		.loc 1 64 0
 138              		.cfi_startproc
 139 0000 55       		pushq	%rbp
 140              		.cfi_def_cfa_offset 16
 141              		.cfi_offset 6, -16
 142 0001 4889E5   		movq	%rsp, %rbp
 143              		.cfi_def_cfa_register 6
 144 0004 4883EC20 		subq	$32, %rsp
 145 0008 897DEC   		movl	%edi, -20(%rbp)
 146 000b 8975E8   		movl	%esi, -24(%rbp)
 147 000e 8955E4   		movl	%edx, -28(%rbp)
 148 0011 894DE0   		movl	%ecx, -32(%rbp)
  65:mapper.c      ****     sem_wait(&sem_control);
 149              		.loc 1 65 0
 150 0014 488D3D00 		leaq	sem_control(%rip), %rdi
 150      000000
 151 001b E8000000 		call	sem_wait@PLT
 151      00
  66:mapper.c      ****     int id = unclear_id;
 152              		.loc 1 66 0
 153 0020 8B45E8   		movl	-24(%rbp), %eax
 154 0023 8945F8   		movl	%eax, -8(%rbp)
  67:mapper.c      ****     if (type == MOVE_FLAG) //移动:  切换ID,X,Y,同步 编码格式 "0 id x y"
 155              		.loc 1 67 0
 156 0026 837DEC00 		cmpl	$0, -20(%rbp)
 157 002a 0F858F00 		jne	.L2
 157      0000
  68:mapper.c      ****     {
  69:mapper.c      ****         POS_X_EVENT.value = x;
 158              		.loc 1 69 0
 159 0030 8B45E4   		movl	-28(%rbp), %eax
 160 0033 89050000 		movl	%eax, 20+POS_X_EVENT(%rip)
 160      0000
  70:mapper.c      ****         POS_Y_EVENT.value = y;
 161              		.loc 1 70 0
 162 0039 8B45E0   		movl	-32(%rbp), %eax
 163 003c 89050000 		movl	%eax, 20+POS_Y_EVENT(%rip)
 163      0000
  71:mapper.c      ****         if (SWITCH_ID_EVENT.value != id)
 164              		.loc 1 71 0
 165 0042 8B050000 		movl	20+SWITCH_ID_EVENT(%rip), %eax
 165      0000
 166 0048 3945F8   		cmpl	%eax, -8(%rbp)
 167 004b 7422     		je	.L3
  72:mapper.c      ****         {
  73:mapper.c      ****             SWITCH_ID_EVENT.value = id;
 168              		.loc 1 73 0
 169 004d 8B45F8   		movl	-8(%rbp), %eax
 170 0050 89050000 		movl	%eax, 20+SWITCH_ID_EVENT(%rip)
 170      0000
  74:mapper.c      ****             write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
 171              		.loc 1 74 0
 172 0056 8B050000 		movl	touch_fd(%rip), %eax
 172      0000
 173 005c BA180000 		movl	$24, %edx
 173      00
 174 0061 488D3500 		leaq	SWITCH_ID_EVENT(%rip), %rsi
 174      000000
 175 0068 89C7     		movl	%eax, %edi
 176 006a E8000000 		call	write@PLT
 176      00
 177              	.L3:
  75:mapper.c      ****         }
  76:mapper.c      ****         write(touch_fd, &POS_X_EVENT, sizeof(POS_X_EVENT));
 178              		.loc 1 76 0
 179 006f 8B050000 		movl	touch_fd(%rip), %eax
 179      0000
 180 0075 BA180000 		movl	$24, %edx
 180      00
 181 007a 488D3500 		leaq	POS_X_EVENT(%rip), %rsi
 181      000000
 182 0081 89C7     		movl	%eax, %edi
 183 0083 E8000000 		call	write@PLT
 183      00
  77:mapper.c      ****         write(touch_fd, &POS_Y_EVENT, sizeof(POS_Y_EVENT));
 184              		.loc 1 77 0
 185 0088 8B050000 		movl	touch_fd(%rip), %eax
 185      0000
 186 008e BA180000 		movl	$24, %edx
 186      00
 187 0093 488D3500 		leaq	POS_Y_EVENT(%rip), %rsi
 187      000000
 188 009a 89C7     		movl	%eax, %edi
 189 009c E8000000 		call	write@PLT
 189      00
  78:mapper.c      ****         write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
 190              		.loc 1 78 0
 191 00a1 8B050000 		movl	touch_fd(%rip), %eax
 191      0000
 192 00a7 BA180000 		movl	$24, %edx
 192      00
 193 00ac 488D3500 		leaq	SYNC_EVENT(%rip), %rsi
 193      000000
 194 00b3 89C7     		movl	%eax, %edi
 195 00b5 E8000000 		call	write@PLT
 195      00
 196 00ba E9810200 		jmp	.L4
 196      00
 197              	.L2:
  79:mapper.c      ****     }
  80:mapper.c      ****     else if (type == RELEASE_FLAG) //释放: 切换ID,uid=-1,同步 编码格式 "2 id 0 0"
 198              		.loc 1 80 0
 199 00bf 837DEC02 		cmpl	$2, -20(%rbp)
 200 00c3 0F85D700 		jne	.L5
 200      0000
  81:mapper.c      ****     {
  82:mapper.c      ****         if (id == -1)
 201              		.loc 1 82 0
 202 00c9 837DF8FF 		cmpl	$-1, -8(%rbp)
 203 00cd 7516     		jne	.L6
  83:mapper.c      ****         {
  84:mapper.c      ****             sem_post(&sem_control);
 204              		.loc 1 84 0
 205 00cf 488D3D00 		leaq	sem_control(%rip), %rdi
 205      000000
 206 00d6 E8000000 		call	sem_post@PLT
 206      00
  85:mapper.c      ****             return -1;
 207              		.loc 1 85 0
 208 00db B8FFFFFF 		movl	$-1, %eax
 208      FF
 209 00e0 E96A0200 		jmp	.L7
 209      00
 210              	.L6:
  86:mapper.c      ****         }                  //没申请成功的释放请求
  87:mapper.c      ****         touch_id[id] = 0;  // 释放
 211              		.loc 1 87 0
 212 00e5 8B45F8   		movl	-8(%rbp), %eax
 213 00e8 4898     		cltq
 214 00ea 488D1485 		leaq	0(,%rax,4), %rdx
 214      00000000 
 215 00f2 488D0500 		leaq	touch_id(%rip), %rax
 215      000000
 216 00f9 C7040200 		movl	$0, (%rdx,%rax)
 216      000000
  88:mapper.c      ****         allocatedID_num--; //占用数目-1
 217              		.loc 1 88 0
 218 0100 8B050000 		movl	allocatedID_num(%rip), %eax
 218      0000
 219 0106 83E801   		subl	$1, %eax
 220 0109 89050000 		movl	%eax, allocatedID_num(%rip)
 220      0000
  89:mapper.c      ****         DEFINE_UID_EVENT.value = 0xffffffff;
 221              		.loc 1 89 0
 222 010f C7050000 		movl	$-1, 20+DEFINE_UID_EVENT(%rip)
 222      0000FFFF 
 222      FFFF
  90:mapper.c      ****         if (SWITCH_ID_EVENT.value != id)
 223              		.loc 1 90 0
 224 0119 8B050000 		movl	20+SWITCH_ID_EVENT(%rip), %eax
 224      0000
 225 011f 3945F8   		cmpl	%eax, -8(%rbp)
 226 0122 7422     		je	.L8
  91:mapper.c      ****         {
  92:mapper.c      ****             SWITCH_ID_EVENT.value = id;
 227              		.loc 1 92 0
 228 0124 8B45F8   		movl	-8(%rbp), %eax
 229 0127 89050000 		movl	%eax, 20+SWITCH_ID_EVENT(%rip)
 229      0000
  93:mapper.c      ****             write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
 230              		.loc 1 93 0
 231 012d 8B050000 		movl	touch_fd(%rip), %eax
 231      0000
 232 0133 BA180000 		movl	$24, %edx
 232      00
 233 0138 488D3500 		leaq	SWITCH_ID_EVENT(%rip), %rsi
 233      000000
 234 013f 89C7     		movl	%eax, %edi
 235 0141 E8000000 		call	write@PLT
 235      00
 236              	.L8:
  94:mapper.c      ****         }
  95:mapper.c      ****         write(touch_fd, &DEFINE_UID_EVENT, sizeof(DEFINE_UID_EVENT));
 237              		.loc 1 95 0
 238 0146 8B050000 		movl	touch_fd(%rip), %eax
 238      0000
 239 014c BA180000 		movl	$24, %edx
 239      00
 240 0151 488D3500 		leaq	DEFINE_UID_EVENT(%rip), %rsi
 240      000000
 241 0158 89C7     		movl	%eax, %edi
 242 015a E8000000 		call	write@PLT
 242      00
  96:mapper.c      ****         if (allocatedID_num == 0) //为0 全部释放 btn up
 243              		.loc 1 96 0
 244 015f 8B050000 		movl	allocatedID_num(%rip), %eax
 244      0000
 245 0165 85C0     		testl	%eax, %eax
 246 0167 7519     		jne	.L9
  97:mapper.c      ****             write(touch_fd, &BTN_UP_EVENT, sizeof(BTN_UP_EVENT));
 247              		.loc 1 97 0
 248 0169 8B050000 		movl	touch_fd(%rip), %eax
 248      0000
 249 016f BA180000 		movl	$24, %edx
 249      00
 250 0174 488D3500 		leaq	BTN_UP_EVENT(%rip), %rsi
 250      000000
 251 017b 89C7     		movl	%eax, %edi
 252 017d E8000000 		call	write@PLT
 252      00
 253              	.L9:
  98:mapper.c      ****         write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
 254              		.loc 1 98 0
 255 0182 8B050000 		movl	touch_fd(%rip), %eax
 255      0000
 256 0188 BA180000 		movl	$24, %edx
 256      00
 257 018d 488D3500 		leaq	SYNC_EVENT(%rip), %rsi
 257      000000
 258 0194 89C7     		movl	%eax, %edi
 259 0196 E8000000 		call	write@PLT
 259      00
 260 019b E9A00100 		jmp	.L4
 260      00
 261              	.L5:
  99:mapper.c      ****     }
 100:mapper.c      ****     else if (type == REQURIE_FLAG)
 262              		.loc 1 100 0
 263 01a0 837DEC01 		cmpl	$1, -20(%rbp)
 264 01a4 0F859601 		jne	.L4
 264      0000
 101:mapper.c      ****     {                 //type == pressTouch  按下： 切换ID，uid=自定义，x，y，同步 编
 102:mapper.c      ****         if (id == -1) //申请触摸 是一个新的触摸点 或者申请没有成功 理论上是
 265              		.loc 1 102 0
 266 01aa 837DF8FF 		cmpl	$-1, -8(%rbp)
 267 01ae 0F859B00 		jne	.L10
 267      0000
 268              	.LBB2:
 103:mapper.c      ****         {
 104:mapper.c      ****             for (int i = 0; i < 10; i++)
 269              		.loc 1 104 0
 270 01b4 C745FC00 		movl	$0, -4(%rbp)
 270      000000
 271 01bb E9850000 		jmp	.L11
 271      00
 272              	.L13:
 105:mapper.c      ****             {
 106:mapper.c      ****                 if (touch_id[i] == 0) //找寻一个空的
 273              		.loc 1 106 0
 274 01c0 8B45FC   		movl	-4(%rbp), %eax
 275 01c3 4898     		cltq
 276 01c5 488D1485 		leaq	0(,%rax,4), %rdx
 276      00000000 
 277 01cd 488D0500 		leaq	touch_id(%rip), %rax
 277      000000
 278 01d4 8B0402   		movl	(%rdx,%rax), %eax
 279 01d7 85C0     		testl	%eax, %eax
 280 01d9 7566     		jne	.L12
 107:mapper.c      ****                 {
 108:mapper.c      ****                     id = i;          //分配id
 281              		.loc 1 108 0
 282 01db 8B45FC   		movl	-4(%rbp), %eax
 283 01de 8945F8   		movl	%eax, -8(%rbp)
 109:mapper.c      ****                     touch_id[i] = 1; //记录此置位已占用
 284              		.loc 1 109 0
 285 01e1 8B45FC   		movl	-4(%rbp), %eax
 286 01e4 4898     		cltq
 287 01e6 488D1485 		leaq	0(,%rax,4), %rdx
 287      00000000 
 288 01ee 488D0500 		leaq	touch_id(%rip), %rax
 288      000000
 289 01f5 C7040201 		movl	$1, (%rdx,%rax)
 289      000000
 110:mapper.c      ****                     postion[i][0] = x;
 290              		.loc 1 110 0
 291 01fc 8B45FC   		movl	-4(%rbp), %eax
 292 01ff 4898     		cltq
 293 0201 488D0CC5 		leaq	0(,%rax,8), %rcx
 293      00000000 
 294 0209 488D0500 		leaq	postion(%rip), %rax
 294      000000
 295 0210 8B55E4   		movl	-28(%rbp), %edx
 296 0213 891401   		movl	%edx, (%rcx,%rax)
 111:mapper.c      ****                     postion[i][1] = y; //更新位置
 297              		.loc 1 111 0
 298 0216 8B45FC   		movl	-4(%rbp), %eax
 299 0219 4898     		cltq
 300 021b 488D0CC5 		leaq	0(,%rax,8), %rcx
 300      00000000 
 301 0223 488D0500 		leaq	4+postion(%rip), %rax
 301      000000
 302 022a 8B55E0   		movl	-32(%rbp), %edx
 303 022d 891401   		movl	%edx, (%rcx,%rax)
 112:mapper.c      ****                     allocatedID_num++; //已分配计数+1
 304              		.loc 1 112 0
 305 0230 8B050000 		movl	allocatedID_num(%rip), %eax
 305      0000
 306 0236 83C001   		addl	$1, %eax
 307 0239 89050000 		movl	%eax, allocatedID_num(%rip)
 307      0000
 113:mapper.c      ****                     break;
 308              		.loc 1 113 0
 309 023f EB0E     		jmp	.L10
 310              	.L12:
 104:mapper.c      ****             {
 311              		.loc 1 104 0 discriminator 2
 312 0241 8345FC01 		addl	$1, -4(%rbp)
 313              	.L11:
 104:mapper.c      ****             {
 314              		.loc 1 104 0 is_stmt 0 discriminator 1
 315 0245 837DFC09 		cmpl	$9, -4(%rbp)
 316 0249 0F8E71FF 		jle	.L13
 316      FFFF
 317              	.L10:
 318              	.LBE2:
 114:mapper.c      ****                 }
 115:mapper.c      ****             }
 116:mapper.c      ****         }
 117:mapper.c      ****         if (id == -1)
 319              		.loc 1 117 0 is_stmt 1
 320 024f 837DF8FF 		cmpl	$-1, -8(%rbp)
 321 0253 7516     		jne	.L14
 118:mapper.c      ****         { //分配失败 下次再说
 119:mapper.c      ****             sem_post(&sem_control);
 322              		.loc 1 119 0
 323 0255 488D3D00 		leaq	sem_control(%rip), %rdi
 323      000000
 324 025c E8000000 		call	sem_post@PLT
 324      00
 120:mapper.c      ****             return -1;
 325              		.loc 1 120 0
 326 0261 B8FFFFFF 		movl	$-1, %eax
 326      FF
 327 0266 E9E40000 		jmp	.L7
 327      00
 328              	.L14:
 121:mapper.c      ****         }
 122:mapper.c      **** 
 123:mapper.c      ****         DEFINE_UID_EVENT.value = 0xe2 + id;
 329              		.loc 1 123 0
 330 026b 8B45F8   		movl	-8(%rbp), %eax
 331 026e 05E20000 		addl	$226, %eax
 331      00
 332 0273 89050000 		movl	%eax, 20+DEFINE_UID_EVENT(%rip)
 332      0000
 124:mapper.c      ****         POS_X_EVENT.value = x;
 333              		.loc 1 124 0
 334 0279 8B45E4   		movl	-28(%rbp), %eax
 335 027c 89050000 		movl	%eax, 20+POS_X_EVENT(%rip)
 335      0000
 125:mapper.c      ****         POS_Y_EVENT.value = y;
 336              		.loc 1 125 0
 337 0282 8B45E0   		movl	-32(%rbp), %eax
 338 0285 89050000 		movl	%eax, 20+POS_Y_EVENT(%rip)
 338      0000
 126:mapper.c      ****         if (SWITCH_ID_EVENT.value != id)
 339              		.loc 1 126 0
 340 028b 8B050000 		movl	20+SWITCH_ID_EVENT(%rip), %eax
 340      0000
 341 0291 3945F8   		cmpl	%eax, -8(%rbp)
 342 0294 7422     		je	.L15
 127:mapper.c      ****         {
 128:mapper.c      ****             SWITCH_ID_EVENT.value = id;
 343              		.loc 1 128 0
 344 0296 8B45F8   		movl	-8(%rbp), %eax
 345 0299 89050000 		movl	%eax, 20+SWITCH_ID_EVENT(%rip)
 345      0000
 129:mapper.c      ****             write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
 346              		.loc 1 129 0
 347 029f 8B050000 		movl	touch_fd(%rip), %eax
 347      0000
 348 02a5 BA180000 		movl	$24, %edx
 348      00
 349 02aa 488D3500 		leaq	SWITCH_ID_EVENT(%rip), %rsi
 349      000000
 350 02b1 89C7     		movl	%eax, %edi
 351 02b3 E8000000 		call	write@PLT
 351      00
 352              	.L15:
 130:mapper.c      ****         }
 131:mapper.c      ****         write(touch_fd, &DEFINE_UID_EVENT, sizeof(DEFINE_UID_EVENT));
 353              		.loc 1 131 0
 354 02b8 8B050000 		movl	touch_fd(%rip), %eax
 354      0000
 355 02be BA180000 		movl	$24, %edx
 355      00
 356 02c3 488D3500 		leaq	DEFINE_UID_EVENT(%rip), %rsi
 356      000000
 357 02ca 89C7     		movl	%eax, %edi
 358 02cc E8000000 		call	write@PLT
 358      00
 132:mapper.c      ****         if (allocatedID_num == 1) //为1 则是头一次按下 btn down
 359              		.loc 1 132 0
 360 02d1 8B050000 		movl	allocatedID_num(%rip), %eax
 360      0000
 361 02d7 83F801   		cmpl	$1, %eax
 362 02da 7519     		jne	.L16
 133:mapper.c      ****             write(touch_fd, &BTN_DOWN_EVENT, sizeof(BTN_DOWN_EVENT));
 363              		.loc 1 133 0
 364 02dc 8B050000 		movl	touch_fd(%rip), %eax
 364      0000
 365 02e2 BA180000 		movl	$24, %edx
 365      00
 366 02e7 488D3500 		leaq	BTN_DOWN_EVENT(%rip), %rsi
 366      000000
 367 02ee 89C7     		movl	%eax, %edi
 368 02f0 E8000000 		call	write@PLT
 368      00
 369              	.L16:
 134:mapper.c      ****         write(touch_fd, &POS_X_EVENT, sizeof(POS_X_EVENT));
 370              		.loc 1 134 0
 371 02f5 8B050000 		movl	touch_fd(%rip), %eax
 371      0000
 372 02fb BA180000 		movl	$24, %edx
 372      00
 373 0300 488D3500 		leaq	POS_X_EVENT(%rip), %rsi
 373      000000
 374 0307 89C7     		movl	%eax, %edi
 375 0309 E8000000 		call	write@PLT
 375      00
 135:mapper.c      ****         write(touch_fd, &POS_Y_EVENT, sizeof(POS_Y_EVENT));
 376              		.loc 1 135 0
 377 030e 8B050000 		movl	touch_fd(%rip), %eax
 377      0000
 378 0314 BA180000 		movl	$24, %edx
 378      00
 379 0319 488D3500 		leaq	POS_Y_EVENT(%rip), %rsi
 379      000000
 380 0320 89C7     		movl	%eax, %edi
 381 0322 E8000000 		call	write@PLT
 381      00
 136:mapper.c      ****         write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
 382              		.loc 1 136 0
 383 0327 8B050000 		movl	touch_fd(%rip), %eax
 383      0000
 384 032d BA180000 		movl	$24, %edx
 384      00
 385 0332 488D3500 		leaq	SYNC_EVENT(%rip), %rsi
 385      000000
 386 0339 89C7     		movl	%eax, %edi
 387 033b E8000000 		call	write@PLT
 387      00
 388              	.L4:
 137:mapper.c      ****     }
 138:mapper.c      ****     sem_post(&sem_control);
 389              		.loc 1 138 0
 390 0340 488D3D00 		leaq	sem_control(%rip), %rdi
 390      000000
 391 0347 E8000000 		call	sem_post@PLT
 391      00
 139:mapper.c      ****     return id;
 392              		.loc 1 139 0
 393 034c 8B45F8   		movl	-8(%rbp), %eax
 394              	.L7:
 140:mapper.c      **** }
 395              		.loc 1 140 0
 396 034f C9       		leave
 397              		.cfi_def_cfa 7, 8
 398 0350 C3       		ret
 399              		.cfi_endproc
 400              	.LFE5:
 402              		.globl	mouse_touch_id
 403              		.data
 404              		.align 4
 407              	mouse_touch_id:
 408 00c8 FFFFFFFF 		.long	-1
 409              		.globl	mouse_Start_x
 410              		.align 4
 413              	mouse_Start_x:
 414 00cc D0020000 		.long	720
 415              		.globl	mouse_Start_y
 416              		.align 4
 419              	mouse_Start_y:
 420 00d0 40060000 		.long	1600
 421              		.comm	realtive_x,4,4
 422              		.comm	realtive_y,4,4
 423              		.globl	mouse_speedRatio
 424              		.align 4
 427              	mouse_speedRatio:
 428 00d4 01000000 		.long	1
 429              		.comm	km_map_id,1056,32
 430              		.comm	map_postion,2112,32
 431              		.text
 432              		.globl	handel_Mouse_queue
 434              	handel_Mouse_queue:
 435              	.LFB6:
 141:mapper.c      **** 
 142:mapper.c      **** int mouse_touch_id = -1;    //鼠标映射的ID 唯一 第一次产生移动事件时按下 之后�
 143:mapper.c      **** int mouse_Start_x = 720;    ///开始结束坐标 只读
 144:mapper.c      **** int mouse_Start_y = 1600;   //中途可能有切换 还是会回到这里的
 145:mapper.c      **** int realtive_x, realtive_y; //保存当前移动坐标
 146:mapper.c      **** int mouse_speedRatio = 1;
 147:mapper.c      **** int km_map_id[256 + 8];      //键盘鼠标code 对应分配的ID 按下获取并存入 释放的�
 148:mapper.c      ****                              //鼠标编码0x110开始 0~7个
 149:mapper.c      ****                              //将其放在了一起 鼠标加偏移量256
 150:mapper.c      **** int map_postion[256 + 8][2]; //映射的XY坐标
 151:mapper.c      **** 
 152:mapper.c      **** void handel_Mouse_queue() //处理鼠标动作
 153:mapper.c      **** {
 436              		.loc 1 153 0
 437              		.cfi_startproc
 438 0351 55       		pushq	%rbp
 439              		.cfi_def_cfa_offset 16
 440              		.cfi_offset 6, -16
 441 0352 4889E5   		movq	%rsp, %rbp
 442              		.cfi_def_cfa_register 6
 443 0355 4883EC10 		subq	$16, %rsp
 154:mapper.c      **** 
 155:mapper.c      ****     if (Mouse_queue[0].type == 2) //移动
 444              		.loc 1 155 0
 445 0359 0FB70500 		movzwl	16+Mouse_queue(%rip), %eax
 445      000000
 446 0360 6683F802 		cmpw	$2, %ax
 447 0364 0F858201 		jne	.L18
 447      0000
 448              	.LBB3:
 156:mapper.c      ****     {
 157:mapper.c      ****         int x = 0;
 449              		.loc 1 157 0
 450 036a C745F400 		movl	$0, -12(%rbp)
 450      000000
 158:mapper.c      ****         int y = 0;
 451              		.loc 1 158 0
 452 0371 C745F800 		movl	$0, -8(%rbp)
 452      000000
 159:mapper.c      ****         if (m_len == 3)
 453              		.loc 1 159 0
 454 0378 8B050000 		movl	m_len(%rip), %eax
 454      0000
 455 037e 83F803   		cmpl	$3, %eax
 456 0381 7514     		jne	.L19
 160:mapper.c      ****         { //X和Y 顺序是固定的 先X 后y
 161:mapper.c      ****             x = Mouse_queue[0].value;
 457              		.loc 1 161 0
 458 0383 8B050000 		movl	20+Mouse_queue(%rip), %eax
 458      0000
 459 0389 8945F4   		movl	%eax, -12(%rbp)
 162:mapper.c      ****             y = Mouse_queue[1].value;
 460              		.loc 1 162 0
 461 038c 8B050000 		movl	44+Mouse_queue(%rip), %eax
 461      0000
 462 0392 8945F8   		movl	%eax, -8(%rbp)
 463 0395 EB20     		jmp	.L20
 464              	.L19:
 163:mapper.c      ****         }
 164:mapper.c      ****         else
 165:mapper.c      ****         { //单个 x或y
 166:mapper.c      ****             if (Mouse_queue[0].code == 0)
 465              		.loc 1 166 0
 466 0397 0FB70500 		movzwl	18+Mouse_queue(%rip), %eax
 466      000000
 467 039e 6685C0   		testw	%ax, %ax
 468 03a1 750B     		jne	.L21
 167:mapper.c      ****                 x = Mouse_queue[0].value;
 469              		.loc 1 167 0
 470 03a3 8B050000 		movl	20+Mouse_queue(%rip), %eax
 470      0000
 471 03a9 8945F4   		movl	%eax, -12(%rbp)
 472 03ac EB09     		jmp	.L20
 473              	.L21:
 168:mapper.c      ****             else
 169:mapper.c      ****                 y = Mouse_queue[0].value;
 474              		.loc 1 169 0
 475 03ae 8B050000 		movl	20+Mouse_queue(%rip), %eax
 475      0000
 476 03b4 8945F8   		movl	%eax, -8(%rbp)
 477              	.L20:
 170:mapper.c      ****         }
 171:mapper.c      **** 
 172:mapper.c      ****         if (mouse_touch_id == -1)
 478              		.loc 1 172 0
 479 03b7 8B050000 		movl	mouse_touch_id(%rip), %eax
 479      0000
 480 03bd 83F8FF   		cmpl	$-1, %eax
 481 03c0 7541     		jne	.L22
 173:mapper.c      ****         {
 174:mapper.c      ****             mouse_touch_id = main_controler(REQURIE_FLAG, mouse_touch_id, mouse_Start_x, mouse_Star
 482              		.loc 1 174 0
 483 03c2 8B0D0000 		movl	mouse_Start_y(%rip), %ecx
 483      0000
 484 03c8 8B150000 		movl	mouse_Start_x(%rip), %edx
 484      0000
 485 03ce 8B050000 		movl	mouse_touch_id(%rip), %eax
 485      0000
 486 03d4 89C6     		movl	%eax, %esi
 487 03d6 BF010000 		movl	$1, %edi
 487      00
 488 03db E8000000 		call	main_controler
 488      00
 489 03e0 89050000 		movl	%eax, mouse_touch_id(%rip)
 489      0000
 175:mapper.c      ****             realtive_x = mouse_Start_x;
 490              		.loc 1 175 0
 491 03e6 8B050000 		movl	mouse_Start_x(%rip), %eax
 491      0000
 492 03ec 89050000 		movl	%eax, realtive_x(%rip)
 492      0000
 176:mapper.c      ****             realtive_y = mouse_Start_y; //相对X,Y
 493              		.loc 1 176 0
 494 03f2 8B050000 		movl	mouse_Start_y(%rip), %eax
 494      0000
 495 03f8 89050000 		movl	%eax, realtive_y(%rip)
 495      0000
 177:mapper.c      ****             return;
 496              		.loc 1 177 0
 497 03fe E9A90100 		jmp	.L17
 497      00
 498              	.L22:
 178:mapper.c      ****         }
 179:mapper.c      ****         realtive_x -= y * mouse_speedRatio;
 499              		.loc 1 179 0
 500 0403 8B150000 		movl	realtive_x(%rip), %edx
 500      0000
 501 0409 8B050000 		movl	mouse_speedRatio(%rip), %eax
 501      0000
 502 040f 0FAF45F8 		imull	-8(%rbp), %eax
 503 0413 29C2     		subl	%eax, %edx
 504 0415 89D0     		movl	%edx, %eax
 505 0417 89050000 		movl	%eax, realtive_x(%rip)
 505      0000
 180:mapper.c      ****         realtive_y += x * mouse_speedRatio;
 506              		.loc 1 180 0
 507 041d 8B050000 		movl	mouse_speedRatio(%rip), %eax
 507      0000
 508 0423 0FAF45F4 		imull	-12(%rbp), %eax
 509 0427 89C2     		movl	%eax, %edx
 510 0429 8B050000 		movl	realtive_y(%rip), %eax
 510      0000
 511 042f 01D0     		addl	%edx, %eax
 512 0431 89050000 		movl	%eax, realtive_y(%rip)
 512      0000
 181:mapper.c      ****         if (realtive_x < 100 || realtive_x > 1400 || realtive_y < 100 || realtive_y > 3000)
 513              		.loc 1 181 0
 514 0437 8B050000 		movl	realtive_x(%rip), %eax
 514      0000
 515 043d 83F863   		cmpl	$99, %eax
 516 0440 7E25     		jle	.L24
 517              		.loc 1 181 0 is_stmt 0 discriminator 1
 518 0442 8B050000 		movl	realtive_x(%rip), %eax
 518      0000
 519 0448 3D780500 		cmpl	$1400, %eax
 519      00
 520 044d 7F18     		jg	.L24
 521              		.loc 1 181 0 discriminator 2
 522 044f 8B050000 		movl	realtive_y(%rip), %eax
 522      0000
 523 0455 83F863   		cmpl	$99, %eax
 524 0458 7E0D     		jle	.L24
 525              		.loc 1 181 0 discriminator 3
 526 045a 8B050000 		movl	realtive_y(%rip), %eax
 526      0000
 527 0460 3DB80B00 		cmpl	$3000, %eax
 527      00
 528 0465 7E62     		jle	.L25
 529              	.L24:
 182:mapper.c      ****         {
 183:mapper.c      ****             main_controler(RELEASE_FLAG, mouse_touch_id, 0, 0);
 530              		.loc 1 183 0 is_stmt 1
 531 0467 8B050000 		movl	mouse_touch_id(%rip), %eax
 531      0000
 532 046d B9000000 		movl	$0, %ecx
 532      00
 533 0472 BA000000 		movl	$0, %edx
 533      00
 534 0477 89C6     		movl	%eax, %esi
 535 0479 BF020000 		movl	$2, %edi
 535      00
 536 047e E8000000 		call	main_controler
 536      00
 184:mapper.c      ****             mouse_touch_id = -1;                                                                   
 537              		.loc 1 184 0
 538 0483 C7050000 		movl	$-1, mouse_touch_id(%rip)
 538      0000FFFF 
 538      FFFF
 185:mapper.c      ****             mouse_touch_id = main_controler(REQURIE_FLAG, mouse_touch_id, mouse_Start_x, mouse_Star
 539              		.loc 1 185 0
 540 048d 8B0D0000 		movl	mouse_Start_y(%rip), %ecx
 540      0000
 541 0493 8B150000 		movl	mouse_Start_x(%rip), %edx
 541      0000
 542 0499 8B050000 		movl	mouse_touch_id(%rip), %eax
 542      0000
 543 049f 89C6     		movl	%eax, %esi
 544 04a1 BF010000 		movl	$1, %edi
 544      00
 545 04a6 E8000000 		call	main_controler
 545      00
 546 04ab 89050000 		movl	%eax, mouse_touch_id(%rip)
 546      0000
 186:mapper.c      ****             realtive_x = mouse_Start_x;
 547              		.loc 1 186 0
 548 04b1 8B050000 		movl	mouse_Start_x(%rip), %eax
 548      0000
 549 04b7 89050000 		movl	%eax, realtive_x(%rip)
 549      0000
 187:mapper.c      ****             realtive_y = mouse_Start_y; //相对X,Y
 550              		.loc 1 187 0
 551 04bd 8B050000 		movl	mouse_Start_y(%rip), %eax
 551      0000
 552 04c3 89050000 		movl	%eax, realtive_y(%rip)
 552      0000
 553              	.L25:
 188:mapper.c      ****         }
 189:mapper.c      ****         main_controler(MOVE_FLAG, mouse_touch_id, realtive_x, realtive_y); //移动
 554              		.loc 1 189 0
 555 04c9 8B0D0000 		movl	realtive_y(%rip), %ecx
 555      0000
 556 04cf 8B150000 		movl	realtive_x(%rip), %edx
 556      0000
 557 04d5 8B050000 		movl	mouse_touch_id(%rip), %eax
 557      0000
 558 04db 89C6     		movl	%eax, %esi
 559 04dd BF000000 		movl	$0, %edi
 559      00
 560 04e2 E8000000 		call	main_controler
 560      00
 561              	.LBE3:
 562 04e7 E9B50000 		jmp	.L26
 562      00
 563              	.L18:
 190:mapper.c      ****         // printf("[%d,%d]\n", realtive_x, realtive_y);
 191:mapper.c      ****     }
 192:mapper.c      ****     else if (Mouse_queue[0].type == EV_MSC) //点击事件
 564              		.loc 1 192 0
 565 04ec 0FB70500 		movzwl	16+Mouse_queue(%rip), %eax
 565      000000
 566 04f3 6683F804 		cmpw	$4, %ax
 567 04f7 0F85A400 		jne	.L26
 567      0000
 568              	.LBB4:
 193:mapper.c      ****     {
 194:mapper.c      ****         int mouse_code = 256 + Mouse_queue[1].code - BTN_MOUSE; //0x110为左键 -0x110获得鼠标
 569              		.loc 1 194 0
 570 04fd 0FB70500 		movzwl	42+Mouse_queue(%rip), %eax
 570      000000
 571 0504 0FB7C0   		movzwl	%ax, %eax
 572 0507 83E810   		subl	$16, %eax
 573 050a 8945FC   		movl	%eax, -4(%rbp)
 195:mapper.c      ****         if (Mouse_queue[1].value == DOWN)                       //按下
 574              		.loc 1 195 0
 575 050d 8B050000 		movl	44+Mouse_queue(%rip), %eax
 575      0000
 576 0513 83F801   		cmpl	$1, %eax
 577 0516 755C     		jne	.L27
 196:mapper.c      ****             km_map_id[mouse_code] = main_controler(REQURIE_FLAG, -1, map_postion[mouse_code][0], ma
 578              		.loc 1 196 0
 579 0518 8B45FC   		movl	-4(%rbp), %eax
 580 051b 4898     		cltq
 581 051d 488D14C5 		leaq	0(,%rax,8), %rdx
 581      00000000 
 582 0525 488D0500 		leaq	4+map_postion(%rip), %rax
 582      000000
 583 052c 8B1402   		movl	(%rdx,%rax), %edx
 584 052f 8B45FC   		movl	-4(%rbp), %eax
 585 0532 4898     		cltq
 586 0534 488D0CC5 		leaq	0(,%rax,8), %rcx
 586      00000000 
 587 053c 488D0500 		leaq	map_postion(%rip), %rax
 587      000000
 588 0543 8B0401   		movl	(%rcx,%rax), %eax
 589 0546 89D1     		movl	%edx, %ecx
 590 0548 89C2     		movl	%eax, %edx
 591 054a BEFFFFFF 		movl	$-1, %esi
 591      FF
 592 054f BF010000 		movl	$1, %edi
 592      00
 593 0554 E8000000 		call	main_controler
 593      00
 594 0559 89C1     		movl	%eax, %ecx
 595 055b 8B45FC   		movl	-4(%rbp), %eax
 596 055e 4898     		cltq
 597 0560 488D1485 		leaq	0(,%rax,4), %rdx
 597      00000000 
 598 0568 488D0500 		leaq	km_map_id(%rip), %rax
 598      000000
 599 056f 890C02   		movl	%ecx, (%rdx,%rax)
 600 0572 EB2D     		jmp	.L26
 601              	.L27:
 197:mapper.c      ****         else //释放
 198:mapper.c      ****             main_controler(RELEASE_FLAG, km_map_id[mouse_code], 0, 0);
 602              		.loc 1 198 0
 603 0574 8B45FC   		movl	-4(%rbp), %eax
 604 0577 4898     		cltq
 605 0579 488D1485 		leaq	0(,%rax,4), %rdx
 605      00000000 
 606 0581 488D0500 		leaq	km_map_id(%rip), %rax
 606      000000
 607 0588 8B0402   		movl	(%rdx,%rax), %eax
 608 058b B9000000 		movl	$0, %ecx
 608      00
 609 0590 BA000000 		movl	$0, %edx
 609      00
 610 0595 89C6     		movl	%eax, %esi
 611 0597 BF020000 		movl	$2, %edi
 611      00
 612 059c E8000000 		call	main_controler
 612      00
 613              	.L26:
 614              	.LBE4:
 199:mapper.c      ****     }
 200:mapper.c      ****     m_len = 0;
 615              		.loc 1 200 0
 616 05a1 C7050000 		movl	$0, m_len(%rip)
 616      00000000 
 616      0000
 201:mapper.c      ****     return;
 617              		.loc 1 201 0
 618 05ab 90       		nop
 619              	.L17:
 202:mapper.c      **** }
 620              		.loc 1 202 0
 621 05ac C9       		leave
 622              		.cfi_def_cfa 7, 8
 623 05ad C3       		ret
 624              		.cfi_endproc
 625              	.LFE6:
 627              		.comm	wheel_satuse,16,16
 628              		.globl	wheel_postion
 629              		.bss
 630 0068 00000000 		.align 32
 630      00000000 
 630      00000000 
 630      00000000 
 630      00000000 
 633              	wheel_postion:
 634 0080 00000000 		.zero	72
 634      00000000 
 634      00000000 
 634      00000000 
 634      00000000 
 635              		.globl	wheel_touch_id
 636              		.data
 637              		.align 4
 640              	wheel_touch_id:
 641 00d8 FFFFFFFF 		.long	-1
 642              		.globl	cur_x
 643              		.bss
 644              		.align 4
 647              	cur_x:
 648 00c8 00000000 		.zero	4
 649              		.globl	cur_y
 650              		.align 4
 653              	cur_y:
 654 00cc 00000000 		.zero	4
 655              		.globl	tar_x
 656              		.align 4
 659              	tar_x:
 660 00d0 00000000 		.zero	4
 661              		.globl	tar_y
 662              		.align 4
 665              	tar_y:
 666 00d4 00000000 		.zero	4
 667              		.globl	move_speed
 668              		.data
 669              		.align 4
 672              	move_speed:
 673 00dc 05000000 		.long	5
 674              		.globl	frequency
 675              		.align 4
 678              	frequency:
 679 00e0 F4010000 		.long	500
 680              		.globl	release_flag
 681              		.bss
 682              		.align 4
 685              	release_flag:
 686 00d8 00000000 		.zero	4
 687              		.text
 688              		.globl	wheel_manager
 690              	wheel_manager:
 691              	.LFB7:
 203:mapper.c      **** 
 204:mapper.c      **** int wheel_satuse[4];                                                                               
 205:mapper.c      **** int wheel_postion[9][2] = {{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}};
 206:mapper.c      **** int wheel_touch_id = -1;
 207:mapper.c      **** int cur_x = 0, cur_y = 0; //当前位置
 208:mapper.c      **** int tar_x = 0, tar_y = 0; //目标位置
 209:mapper.c      **** int move_speed = 5;       //方向移动速度
 210:mapper.c      **** int frequency = 500;      //方向移动频率 关系到相应方向键速度
 211:mapper.c      **** int release_flag = 0;     //确保释放操作只执行一次
 212:mapper.c      **** void wheel_manager()
 213:mapper.c      **** {
 692              		.loc 1 213 0
 693              		.cfi_startproc
 694 05ae 55       		pushq	%rbp
 695              		.cfi_def_cfa_offset 16
 696              		.cfi_offset 6, -16
 697 05af 4889E5   		movq	%rsp, %rbp
 698              		.cfi_def_cfa_register 6
 699 05b2 4883EC10 		subq	$16, %rsp
 214:mapper.c      ****     while (Exclusive_mode_flag) //与独占模式共存亡
 700              		.loc 1 214 0
 701 05b6 E9730100 		jmp	.L29
 701      00
 702              	.L41:
 215:mapper.c      ****     {
 216:mapper.c      ****         if (release_flag > 0 && tar_x == wheel_postion[4][0] && tar_y == wheel_postion[4][1]) //目
 703              		.loc 1 216 0
 704 05bb 8B050000 		movl	release_flag(%rip), %eax
 704      0000
 705 05c1 85C0     		testl	%eax, %eax
 706 05c3 7E72     		jle	.L30
 707              		.loc 1 216 0 is_stmt 0 discriminator 1
 708 05c5 8B150000 		movl	32+wheel_postion(%rip), %edx
 708      0000
 709 05cb 8B050000 		movl	tar_x(%rip), %eax
 709      0000
 710 05d1 39C2     		cmpl	%eax, %edx
 711 05d3 7562     		jne	.L30
 712              		.loc 1 216 0 discriminator 2
 713 05d5 8B150000 		movl	36+wheel_postion(%rip), %edx
 713      0000
 714 05db 8B050000 		movl	tar_y(%rip), %eax
 714      0000
 715 05e1 39C2     		cmpl	%eax, %edx
 716 05e3 7552     		jne	.L30
 217:mapper.c      ****         {
 218:mapper.c      ****             cur_x = tar_x;
 717              		.loc 1 218 0 is_stmt 1
 718 05e5 8B050000 		movl	tar_x(%rip), %eax
 718      0000
 719 05eb 89050000 		movl	%eax, cur_x(%rip)
 719      0000
 219:mapper.c      ****             cur_y = tar_y;
 720              		.loc 1 219 0
 721 05f1 8B050000 		movl	tar_y(%rip), %eax
 721      0000
 722 05f7 89050000 		movl	%eax, cur_y(%rip)
 722      0000
 220:mapper.c      ****             main_controler(RELEASE_FLAG, wheel_touch_id, 0, 0); //释放
 723              		.loc 1 220 0
 724 05fd 8B050000 		movl	wheel_touch_id(%rip), %eax
 724      0000
 725 0603 B9000000 		movl	$0, %ecx
 725      00
 726 0608 BA000000 		movl	$0, %edx
 726      00
 727 060d 89C6     		movl	%eax, %esi
 728 060f BF020000 		movl	$2, %edi
 728      00
 729 0614 E8000000 		call	main_controler
 729      00
 221:mapper.c      ****             wheel_touch_id = -1;
 730              		.loc 1 221 0
 731 0619 C7050000 		movl	$-1, wheel_touch_id(%rip)
 731      0000FFFF 
 731      FFFF
 222:mapper.c      ****             release_flag--; //确保在不按下按键时 执行
 732              		.loc 1 222 0
 733 0623 8B050000 		movl	release_flag(%rip), %eax
 733      0000
 734 0629 83E801   		subl	$1, %eax
 735 062c 89050000 		movl	%eax, release_flag(%rip)
 735      0000
 736 0632 E9EA0000 		jmp	.L31
 736      00
 737              	.L30:
 738              	.LBB5:
 223:mapper.c      ****         }
 224:mapper.c      ****         else
 225:mapper.c      ****         {
 226:mapper.c      ****             int div_x = tar_x - cur_x;
 739              		.loc 1 226 0
 740 0637 8B150000 		movl	tar_x(%rip), %edx
 740      0000
 741 063d 8B050000 		movl	cur_x(%rip), %eax
 741      0000
 742 0643 29C2     		subl	%eax, %edx
 743 0645 89D0     		movl	%edx, %eax
 744 0647 8945F8   		movl	%eax, -8(%rbp)
 227:mapper.c      ****             int div_y = tar_y - cur_y;
 745              		.loc 1 227 0
 746 064a 8B150000 		movl	tar_y(%rip), %edx
 746      0000
 747 0650 8B050000 		movl	cur_y(%rip), %eax
 747      0000
 748 0656 29C2     		subl	%eax, %edx
 749 0658 89D0     		movl	%edx, %eax
 750 065a 8945FC   		movl	%eax, -4(%rbp)
 228:mapper.c      ****             if (div_x)
 751              		.loc 1 228 0
 752 065d 837DF800 		cmpl	$0, -8(%rbp)
 753 0661 7447     		je	.L32
 229:mapper.c      ****             {
 230:mapper.c      ****                 if (abs(div_x) > move_speed)
 754              		.loc 1 230 0
 755 0663 8B45F8   		movl	-8(%rbp), %eax
 756 0666 99       		cltd
 757 0667 89D0     		movl	%edx, %eax
 758 0669 3345F8   		xorl	-8(%rbp), %eax
 759 066c 29D0     		subl	%edx, %eax
 760 066e 8B150000 		movl	move_speed(%rip), %edx
 760      0000
 761 0674 39D0     		cmpl	%edx, %eax
 762 0676 7E26     		jle	.L33
 231:mapper.c      ****                     cur_x += div_x > 0 ? 1 * move_speed : -1 * move_speed;
 763              		.loc 1 231 0
 764 0678 837DF800 		cmpl	$0, -8(%rbp)
 765 067c 7F0A     		jg	.L34
 766              		.loc 1 231 0 is_stmt 0 discriminator 1
 767 067e 8B050000 		movl	move_speed(%rip), %eax
 767      0000
 768 0684 F7D8     		negl	%eax
 769 0686 EB06     		jmp	.L35
 770              	.L34:
 771              		.loc 1 231 0 discriminator 2
 772 0688 8B050000 		movl	move_speed(%rip), %eax
 772      0000
 773              	.L35:
 774              		.loc 1 231 0 discriminator 4
 775 068e 8B150000 		movl	cur_x(%rip), %edx
 775      0000
 776 0694 01D0     		addl	%edx, %eax
 777 0696 89050000 		movl	%eax, cur_x(%rip)
 777      0000
 778 069c EB0C     		jmp	.L32
 779              	.L33:
 232:mapper.c      ****                 else
 233:mapper.c      ****                     cur_x = tar_x;
 780              		.loc 1 233 0 is_stmt 1
 781 069e 8B050000 		movl	tar_x(%rip), %eax
 781      0000
 782 06a4 89050000 		movl	%eax, cur_x(%rip)
 782      0000
 783              	.L32:
 234:mapper.c      ****             }
 235:mapper.c      ****             if (div_y)
 784              		.loc 1 235 0
 785 06aa 837DFC00 		cmpl	$0, -4(%rbp)
 786 06ae 7447     		je	.L36
 236:mapper.c      ****             {
 237:mapper.c      ****                 if (abs(div_y) > move_speed)
 787              		.loc 1 237 0
 788 06b0 8B45FC   		movl	-4(%rbp), %eax
 789 06b3 99       		cltd
 790 06b4 89D0     		movl	%edx, %eax
 791 06b6 3345FC   		xorl	-4(%rbp), %eax
 792 06b9 29D0     		subl	%edx, %eax
 793 06bb 8B150000 		movl	move_speed(%rip), %edx
 793      0000
 794 06c1 39D0     		cmpl	%edx, %eax
 795 06c3 7E26     		jle	.L37
 238:mapper.c      ****                     cur_y += div_y > 0 ? 1 * move_speed : -1 * move_speed;
 796              		.loc 1 238 0
 797 06c5 837DFC00 		cmpl	$0, -4(%rbp)
 798 06c9 7F0A     		jg	.L38
 799              		.loc 1 238 0 is_stmt 0 discriminator 1
 800 06cb 8B050000 		movl	move_speed(%rip), %eax
 800      0000
 801 06d1 F7D8     		negl	%eax
 802 06d3 EB06     		jmp	.L39
 803              	.L38:
 804              		.loc 1 238 0 discriminator 2
 805 06d5 8B050000 		movl	move_speed(%rip), %eax
 805      0000
 806              	.L39:
 807              		.loc 1 238 0 discriminator 4
 808 06db 8B150000 		movl	cur_y(%rip), %edx
 808      0000
 809 06e1 01D0     		addl	%edx, %eax
 810 06e3 89050000 		movl	%eax, cur_y(%rip)
 810      0000
 811 06e9 EB0C     		jmp	.L36
 812              	.L37:
 239:mapper.c      ****                 else
 240:mapper.c      ****                     cur_y = tar_y;
 813              		.loc 1 240 0 is_stmt 1
 814 06eb 8B050000 		movl	tar_y(%rip), %eax
 814      0000
 815 06f1 89050000 		movl	%eax, cur_y(%rip)
 815      0000
 816              	.L36:
 241:mapper.c      ****             }
 242:mapper.c      ****             if (div_x || div_y)
 817              		.loc 1 242 0
 818 06f7 837DF800 		cmpl	$0, -8(%rbp)
 819 06fb 7506     		jne	.L40
 820              		.loc 1 242 0 is_stmt 0 discriminator 1
 821 06fd 837DFC00 		cmpl	$0, -4(%rbp)
 822 0701 741E     		je	.L31
 823              	.L40:
 243:mapper.c      ****                 main_controler(MOVE_FLAG, wheel_touch_id, cur_x, cur_y); //正常移动
 824              		.loc 1 243 0 is_stmt 1
 825 0703 8B0D0000 		movl	cur_y(%rip), %ecx
 825      0000
 826 0709 8B150000 		movl	cur_x(%rip), %edx
 826      0000
 827 070f 8B050000 		movl	wheel_touch_id(%rip), %eax
 827      0000
 828 0715 89C6     		movl	%eax, %esi
 829 0717 BF000000 		movl	$0, %edi
 829      00
 830 071c E8000000 		call	main_controler
 830      00
 831              	.L31:
 832              	.LBE5:
 244:mapper.c      ****         }
 245:mapper.c      ****         usleep(frequency);
 833              		.loc 1 245 0
 834 0721 8B050000 		movl	frequency(%rip), %eax
 834      0000
 835 0727 89C7     		movl	%eax, %edi
 836 0729 E8000000 		call	usleep@PLT
 836      00
 837              	.L29:
 214:mapper.c      ****     {
 838              		.loc 1 214 0
 839 072e 8B050000 		movl	Exclusive_mode_flag(%rip), %eax
 839      0000
 840 0734 85C0     		testl	%eax, %eax
 841 0736 0F857FFE 		jne	.L41
 841      FFFF
 246:mapper.c      ****     }
 247:mapper.c      **** }
 842              		.loc 1 247 0
 843 073c 90       		nop
 844 073d C9       		leave
 845              		.cfi_def_cfa 7, 8
 846 073e C3       		ret
 847              		.cfi_endproc
 848              	.LFE7:
 850              		.globl	change_wheel_satuse
 852              	change_wheel_satuse:
 853              	.LFB8:
 248:mapper.c      **** void change_wheel_satuse(int keyCode, int updown)
 249:mapper.c      **** {
 854              		.loc 1 249 0
 855              		.cfi_startproc
 856 073f 55       		pushq	%rbp
 857              		.cfi_def_cfa_offset 16
 858              		.cfi_offset 6, -16
 859 0740 4889E5   		movq	%rsp, %rbp
 860              		.cfi_def_cfa_register 6
 861 0743 4883EC30 		subq	$48, %rsp
 862 0747 897DDC   		movl	%edi, -36(%rbp)
 863 074a 8975D8   		movl	%esi, -40(%rbp)
 250:mapper.c      ****     int x_Asix = 1 - wheel_satuse[1] + wheel_satuse[3];
 864              		.loc 1 250 0
 865 074d 8B050000 		movl	4+wheel_satuse(%rip), %eax
 865      0000
 866 0753 BA010000 		movl	$1, %edx
 866      00
 867 0758 29C2     		subl	%eax, %edx
 868 075a 8B050000 		movl	12+wheel_satuse(%rip), %eax
 868      0000
 869 0760 01D0     		addl	%edx, %eax
 870 0762 8945EC   		movl	%eax, -20(%rbp)
 251:mapper.c      ****     int y_Asix = 1 - wheel_satuse[2] + wheel_satuse[0];
 871              		.loc 1 251 0
 872 0765 8B050000 		movl	8+wheel_satuse(%rip), %eax
 872      0000
 873 076b BA010000 		movl	$1, %edx
 873      00
 874 0770 29C2     		subl	%eax, %edx
 875 0772 8B050000 		movl	wheel_satuse(%rip), %eax
 875      0000
 876 0778 01D0     		addl	%edx, %eax
 877 077a 8945F0   		movl	%eax, -16(%rbp)
 252:mapper.c      ****     int last_map_value = x_Asix * 3 + y_Asix;
 878              		.loc 1 252 0
 879 077d 8B55EC   		movl	-20(%rbp), %edx
 880 0780 89D0     		movl	%edx, %eax
 881 0782 01C0     		addl	%eax, %eax
 882 0784 01C2     		addl	%eax, %edx
 883 0786 8B45F0   		movl	-16(%rbp), %eax
 884 0789 01D0     		addl	%edx, %eax
 885 078b 8945F4   		movl	%eax, -12(%rbp)
 253:mapper.c      ****     int index = -1;
 886              		.loc 1 253 0
 887 078e C745F8FF 		movl	$-1, -8(%rbp)
 887      FFFFFF
 254:mapper.c      ****     switch (keyCode)
 888              		.loc 1 254 0
 889 0795 8B45DC   		movl	-36(%rbp), %eax
 890 0798 83F81E   		cmpl	$30, %eax
 891 079b 7423     		je	.L44
 892 079d 83F81E   		cmpl	$30, %eax
 893 07a0 7F07     		jg	.L45
 894 07a2 83F811   		cmpl	$17, %eax
 895 07a5 740E     		je	.L46
 255:mapper.c      ****     {
 256:mapper.c      ****     case KEY_W:
 257:mapper.c      ****         wheel_satuse[0] = updown;
 258:mapper.c      ****         break;
 259:mapper.c      ****     case KEY_A:
 260:mapper.c      ****         wheel_satuse[1] = updown;
 261:mapper.c      ****         break;
 262:mapper.c      ****     case KEY_S:
 263:mapper.c      ****         wheel_satuse[2] = updown;
 264:mapper.c      ****         break;
 265:mapper.c      ****     case KEY_D:
 266:mapper.c      ****         wheel_satuse[3] = updown;
 267:mapper.c      ****         break;
 268:mapper.c      ****     default:
 269:mapper.c      ****         break;
 896              		.loc 1 269 0
 897 07a7 EB37     		jmp	.L49
 898              	.L45:
 254:mapper.c      ****     switch (keyCode)
 899              		.loc 1 254 0
 900 07a9 83F81F   		cmpl	$31, %eax
 901 07ac 741D     		je	.L47
 902 07ae 83F820   		cmpl	$32, %eax
 903 07b1 7423     		je	.L48
 904              		.loc 1 269 0
 905 07b3 EB2B     		jmp	.L49
 906              	.L46:
 257:mapper.c      ****         break;
 907              		.loc 1 257 0
 908 07b5 8B45D8   		movl	-40(%rbp), %eax
 909 07b8 89050000 		movl	%eax, wheel_satuse(%rip)
 909      0000
 258:mapper.c      ****     case KEY_A:
 910              		.loc 1 258 0
 911 07be EB20     		jmp	.L49
 912              	.L44:
 260:mapper.c      ****         break;
 913              		.loc 1 260 0
 914 07c0 8B45D8   		movl	-40(%rbp), %eax
 915 07c3 89050000 		movl	%eax, 4+wheel_satuse(%rip)
 915      0000
 261:mapper.c      ****     case KEY_S:
 916              		.loc 1 261 0
 917 07c9 EB15     		jmp	.L49
 918              	.L47:
 263:mapper.c      ****         break;
 919              		.loc 1 263 0
 920 07cb 8B45D8   		movl	-40(%rbp), %eax
 921 07ce 89050000 		movl	%eax, 8+wheel_satuse(%rip)
 921      0000
 264:mapper.c      ****     case KEY_D:
 922              		.loc 1 264 0
 923 07d4 EB0A     		jmp	.L49
 924              	.L48:
 266:mapper.c      ****         break;
 925              		.loc 1 266 0
 926 07d6 8B45D8   		movl	-40(%rbp), %eax
 927 07d9 89050000 		movl	%eax, 12+wheel_satuse(%rip)
 927      0000
 267:mapper.c      ****     default:
 928              		.loc 1 267 0
 929 07df 90       		nop
 930              	.L49:
 270:mapper.c      ****     }
 271:mapper.c      ****     x_Asix = 1 - wheel_satuse[1] + wheel_satuse[3];
 931              		.loc 1 271 0
 932 07e0 8B050000 		movl	4+wheel_satuse(%rip), %eax
 932      0000
 933 07e6 BA010000 		movl	$1, %edx
 933      00
 934 07eb 29C2     		subl	%eax, %edx
 935 07ed 8B050000 		movl	12+wheel_satuse(%rip), %eax
 935      0000
 936 07f3 01D0     		addl	%edx, %eax
 937 07f5 8945EC   		movl	%eax, -20(%rbp)
 272:mapper.c      ****     y_Asix = 1 - wheel_satuse[2] + wheel_satuse[0];
 938              		.loc 1 272 0
 939 07f8 8B050000 		movl	8+wheel_satuse(%rip), %eax
 939      0000
 940 07fe BA010000 		movl	$1, %edx
 940      00
 941 0803 29C2     		subl	%eax, %edx
 942 0805 8B050000 		movl	wheel_satuse(%rip), %eax
 942      0000
 943 080b 01D0     		addl	%edx, %eax
 944 080d 8945F0   		movl	%eax, -16(%rbp)
 273:mapper.c      ****     int map_value = x_Asix * 3 + y_Asix;
 945              		.loc 1 273 0
 946 0810 8B55EC   		movl	-20(%rbp), %edx
 947 0813 89D0     		movl	%edx, %eax
 948 0815 01C0     		addl	%eax, %eax
 949 0817 01C2     		addl	%eax, %edx
 950 0819 8B45F0   		movl	-16(%rbp), %eax
 951 081c 01D0     		addl	%edx, %eax
 952 081e 8945FC   		movl	%eax, -4(%rbp)
 274:mapper.c      ****     if (last_map_value == 4 && map_value != 4) //按下 移动
 953              		.loc 1 274 0
 954 0821 837DF404 		cmpl	$4, -12(%rbp)
 955 0825 0F859B00 		jne	.L50
 955      0000
 956              		.loc 1 274 0 is_stmt 0 discriminator 1
 957 082b 837DFC04 		cmpl	$4, -4(%rbp)
 958 082f 0F849100 		je	.L50
 958      0000
 275:mapper.c      ****     {
 276:mapper.c      ****         tar_x = wheel_postion[4][0];
 959              		.loc 1 276 0 is_stmt 1
 960 0835 8B050000 		movl	32+wheel_postion(%rip), %eax
 960      0000
 961 083b 89050000 		movl	%eax, tar_x(%rip)
 961      0000
 277:mapper.c      ****         tar_y = wheel_postion[4][1];
 962              		.loc 1 277 0
 963 0841 8B050000 		movl	36+wheel_postion(%rip), %eax
 963      0000
 964 0847 89050000 		movl	%eax, tar_y(%rip)
 964      0000
 278:mapper.c      ****         cur_x = tar_x;
 965              		.loc 1 278 0
 966 084d 8B050000 		movl	tar_x(%rip), %eax
 966      0000
 967 0853 89050000 		movl	%eax, cur_x(%rip)
 967      0000
 279:mapper.c      ****         cur_y = tar_y;                                                                             
 968              		.loc 1 279 0
 969 0859 8B050000 		movl	tar_y(%rip), %eax
 969      0000
 970 085f 89050000 		movl	%eax, cur_y(%rip)
 970      0000
 280:mapper.c      ****         wheel_touch_id = main_controler(REQURIE_FLAG, -1, wheel_postion[4][0], wheel_postion[4][1])
 971              		.loc 1 280 0
 972 0865 8B150000 		movl	36+wheel_postion(%rip), %edx
 972      0000
 973 086b 8B050000 		movl	32+wheel_postion(%rip), %eax
 973      0000
 974 0871 89D1     		movl	%edx, %ecx
 975 0873 89C2     		movl	%eax, %edx
 976 0875 BEFFFFFF 		movl	$-1, %esi
 976      FF
 977 087a BF010000 		movl	$1, %edi
 977      00
 978 087f E8000000 		call	main_controler
 978      00
 979 0884 89050000 		movl	%eax, wheel_touch_id(%rip)
 979      0000
 281:mapper.c      ****         tar_x = wheel_postion[map_value][0];
 980              		.loc 1 281 0
 981 088a 8B45FC   		movl	-4(%rbp), %eax
 982 088d 4898     		cltq
 983 088f 488D14C5 		leaq	0(,%rax,8), %rdx
 983      00000000 
 984 0897 488D0500 		leaq	wheel_postion(%rip), %rax
 984      000000
 985 089e 8B0402   		movl	(%rdx,%rax), %eax
 986 08a1 89050000 		movl	%eax, tar_x(%rip)
 986      0000
 282:mapper.c      ****         tar_y = wheel_postion[map_value][1]; //设置移动目标
 987              		.loc 1 282 0
 988 08a7 8B45FC   		movl	-4(%rbp), %eax
 989 08aa 4898     		cltq
 990 08ac 488D14C5 		leaq	0(,%rax,8), %rdx
 990      00000000 
 991 08b4 488D0500 		leaq	4+wheel_postion(%rip), %rax
 991      000000
 992 08bb 8B0402   		movl	(%rdx,%rax), %eax
 993 08be 89050000 		movl	%eax, tar_y(%rip)
 993      0000
 283:mapper.c      ****     }
 284:mapper.c      ****     else
 285:mapper.c      ****     {
 286:mapper.c      ****         if (map_value != 4) //正常移动
 287:mapper.c      ****         {
 288:mapper.c      ****             tar_x = wheel_postion[map_value][0];
 289:mapper.c      ****             tar_y = wheel_postion[map_value][1];
 290:mapper.c      ****         }
 291:mapper.c      ****         else //移动目标为中点 释放
 292:mapper.c      ****         {
 293:mapper.c      ****             tar_x = wheel_postion[4][0];
 294:mapper.c      ****             tar_y = wheel_postion[4][1]; //管理器检测目标为中点 直接释放
 295:mapper.c      ****             release_flag++;              //确保只释放一次
 296:mapper.c      ****         }
 297:mapper.c      ****     }
 298:mapper.c      **** }
 994              		.loc 1 298 0
 995 08c4 EB69     		jmp	.L53
 996              	.L50:
 286:mapper.c      ****         {
 997              		.loc 1 286 0
 998 08c6 837DFC04 		cmpl	$4, -4(%rbp)
 999 08ca 743C     		je	.L52
 288:mapper.c      ****             tar_y = wheel_postion[map_value][1];
 1000              		.loc 1 288 0
 1001 08cc 8B45FC   		movl	-4(%rbp), %eax
 1002 08cf 4898     		cltq
 1003 08d1 488D14C5 		leaq	0(,%rax,8), %rdx
 1003      00000000 
 1004 08d9 488D0500 		leaq	wheel_postion(%rip), %rax
 1004      000000
 1005 08e0 8B0402   		movl	(%rdx,%rax), %eax
 1006 08e3 89050000 		movl	%eax, tar_x(%rip)
 1006      0000
 289:mapper.c      ****         }
 1007              		.loc 1 289 0
 1008 08e9 8B45FC   		movl	-4(%rbp), %eax
 1009 08ec 4898     		cltq
 1010 08ee 488D14C5 		leaq	0(,%rax,8), %rdx
 1010      00000000 
 1011 08f6 488D0500 		leaq	4+wheel_postion(%rip), %rax
 1011      000000
 1012 08fd 8B0402   		movl	(%rdx,%rax), %eax
 1013 0900 89050000 		movl	%eax, tar_y(%rip)
 1013      0000
 1014              		.loc 1 298 0
 1015 0906 EB27     		jmp	.L53
 1016              	.L52:
 293:mapper.c      ****             tar_y = wheel_postion[4][1]; //管理器检测目标为中点 直接释放
 1017              		.loc 1 293 0
 1018 0908 8B050000 		movl	32+wheel_postion(%rip), %eax
 1018      0000
 1019 090e 89050000 		movl	%eax, tar_x(%rip)
 1019      0000
 294:mapper.c      ****             release_flag++;              //确保只释放一次
 1020              		.loc 1 294 0
 1021 0914 8B050000 		movl	36+wheel_postion(%rip), %eax
 1021      0000
 1022 091a 89050000 		movl	%eax, tar_y(%rip)
 1022      0000
 295:mapper.c      ****         }
 1023              		.loc 1 295 0
 1024 0920 8B050000 		movl	release_flag(%rip), %eax
 1024      0000
 1025 0926 83C001   		addl	$1, %eax
 1026 0929 89050000 		movl	%eax, release_flag(%rip)
 1026      0000
 1027              	.L53:
 1028              		.loc 1 298 0
 1029 092f 90       		nop
 1030 0930 C9       		leave
 1031              		.cfi_def_cfa 7, 8
 1032 0931 C3       		ret
 1033              		.cfi_endproc
 1034              	.LFE8:
 1036              		.globl	handel_Keyboard_queue
 1038              	handel_Keyboard_queue:
 1039              	.LFB9:
 299:mapper.c      **** 
 300:mapper.c      **** void handel_Keyboard_queue() //处理键盘动作
 301:mapper.c      **** {
 1040              		.loc 1 301 0
 1041              		.cfi_startproc
 1042 0932 55       		pushq	%rbp
 1043              		.cfi_def_cfa_offset 16
 1044              		.cfi_offset 6, -16
 1045 0933 4889E5   		movq	%rsp, %rbp
 1046              		.cfi_def_cfa_register 6
 1047 0936 4883EC10 		subq	$16, %rsp
 302:mapper.c      ****     int keyCode = Keyboard_queue[k_len - 2].code;
 1048              		.loc 1 302 0
 1049 093a 8B050000 		movl	k_len(%rip), %eax
 1049      0000
 1050 0940 83E802   		subl	$2, %eax
 1051 0943 4863D0   		movslq	%eax, %rdx
 1052 0946 4889D0   		movq	%rdx, %rax
 1053 0949 4801C0   		addq	%rax, %rax
 1054 094c 4801D0   		addq	%rdx, %rax
 1055 094f 48C1E003 		salq	$3, %rax
 1056 0953 4889C2   		movq	%rax, %rdx
 1057 0956 488D0500 		leaq	18+Keyboard_queue(%rip), %rax
 1057      000000
 1058 095d 0FB70402 		movzwl	(%rdx,%rax), %eax
 1059 0961 0FB7C0   		movzwl	%ax, %eax
 1060 0964 8945F4   		movl	%eax, -12(%rbp)
 303:mapper.c      ****     int updown = Keyboard_queue[k_len - 2].value;
 1061              		.loc 1 303 0
 1062 0967 8B050000 		movl	k_len(%rip), %eax
 1062      0000
 1063 096d 83E802   		subl	$2, %eax
 1064 0970 4863D0   		movslq	%eax, %rdx
 1065 0973 4889D0   		movq	%rdx, %rax
 1066 0976 4801C0   		addq	%rax, %rax
 1067 0979 4801D0   		addq	%rdx, %rax
 1068 097c 48C1E003 		salq	$3, %rax
 1069 0980 4889C2   		movq	%rax, %rdx
 1070 0983 488D0500 		leaq	20+Keyboard_queue(%rip), %rax
 1070      000000
 1071 098a 8B0402   		movl	(%rdx,%rax), %eax
 1072 098d 8945F8   		movl	%eax, -8(%rbp)
 304:mapper.c      ****     if (keyCode == KEY_GRAVE && updown == UP) //独占和非独占都关注 ` 用于切换状态  `
 1073              		.loc 1 304 0
 1074 0990 837DF429 		cmpl	$41, -12(%rbp)
 1075 0994 7529     		jne	.L55
 1076              		.loc 1 304 0 is_stmt 0 discriminator 1
 1077 0996 837DF800 		cmpl	$0, -8(%rbp)
 1078 099a 7523     		jne	.L55
 1079              	.LBB6:
 305:mapper.c      ****     {
 306:mapper.c      ****         int tmp = Exclusive_mode_flag;
 1080              		.loc 1 306 0 is_stmt 1
 1081 099c 8B050000 		movl	Exclusive_mode_flag(%rip), %eax
 1081      0000
 1082 09a2 8945FC   		movl	%eax, -4(%rbp)
 307:mapper.c      ****         Exclusive_mode_flag = no_Exclusive_mode_flag;
 1083              		.loc 1 307 0
 1084 09a5 8B050000 		movl	no_Exclusive_mode_flag(%rip), %eax
 1084      0000
 1085 09ab 89050000 		movl	%eax, Exclusive_mode_flag(%rip)
 1085      0000
 308:mapper.c      ****         no_Exclusive_mode_flag = tmp;
 1086              		.loc 1 308 0
 1087 09b1 8B45FC   		movl	-4(%rbp), %eax
 1088 09b4 89050000 		movl	%eax, no_Exclusive_mode_flag(%rip)
 1088      0000
 1089              	.LBE6:
 305:mapper.c      ****     {
 1090              		.loc 1 305 0
 1091 09ba E9080100 		jmp	.L56
 1091      00
 1092              	.L55:
 309:mapper.c      ****     }
 310:mapper.c      ****     else if (Exclusive_mode_flag == 1)
 1093              		.loc 1 310 0
 1094 09bf 8B050000 		movl	Exclusive_mode_flag(%rip), %eax
 1094      0000
 1095 09c5 83F801   		cmpl	$1, %eax
 1096 09c8 0F85F900 		jne	.L56
 1096      0000
 311:mapper.c      ****     { //独占模式下 才会处理其他信号 非独占不处理
 312:mapper.c      ****         // printf("{ code = %d , UD = %d }\n", keyCode, updown);
 313:mapper.c      ****         if (keyCode == KEY_W || keyCode == KEY_A || keyCode == KEY_S || keyCode == KEY_D) //方向�
 1097              		.loc 1 313 0
 1098 09ce 837DF411 		cmpl	$17, -12(%rbp)
 1099 09d2 7412     		je	.L57
 1100              		.loc 1 313 0 is_stmt 0 discriminator 1
 1101 09d4 837DF41E 		cmpl	$30, -12(%rbp)
 1102 09d8 740C     		je	.L57
 1103              		.loc 1 313 0 discriminator 2
 1104 09da 837DF41F 		cmpl	$31, -12(%rbp)
 1105 09de 7406     		je	.L57
 1106              		.loc 1 313 0 discriminator 3
 1107 09e0 837DF420 		cmpl	$32, -12(%rbp)
 1108 09e4 7514     		jne	.L58
 1109              	.L57:
 314:mapper.c      ****             change_wheel_satuse(keyCode, updown);
 1110              		.loc 1 314 0 is_stmt 1
 1111 09e6 8B55F8   		movl	-8(%rbp), %edx
 1112 09e9 8B45F4   		movl	-12(%rbp), %eax
 1113 09ec 89D6     		movl	%edx, %esi
 1114 09ee 89C7     		movl	%eax, %edi
 1115 09f0 E8000000 		call	change_wheel_satuse
 1115      00
 1116 09f5 E9CD0000 		jmp	.L56
 1116      00
 1117              	.L58:
 315:mapper.c      ****         else if (map_postion[keyCode][0] && map_postion[keyCode][1])
 1118              		.loc 1 315 0
 1119 09fa 8B45F4   		movl	-12(%rbp), %eax
 1120 09fd 4898     		cltq
 1121 09ff 488D14C5 		leaq	0(,%rax,8), %rdx
 1121      00000000 
 1122 0a07 488D0500 		leaq	map_postion(%rip), %rax
 1122      000000
 1123 0a0e 8B0402   		movl	(%rdx,%rax), %eax
 1124 0a11 85C0     		testl	%eax, %eax
 1125 0a13 0F84AE00 		je	.L56
 1125      0000
 1126              		.loc 1 315 0 is_stmt 0 discriminator 1
 1127 0a19 8B45F4   		movl	-12(%rbp), %eax
 1128 0a1c 4898     		cltq
 1129 0a1e 488D14C5 		leaq	0(,%rax,8), %rdx
 1129      00000000 
 1130 0a26 488D0500 		leaq	4+map_postion(%rip), %rax
 1130      000000
 1131 0a2d 8B0402   		movl	(%rdx,%rax), %eax
 1132 0a30 85C0     		testl	%eax, %eax
 1133 0a32 0F848F00 		je	.L56
 1133      0000
 316:mapper.c      ****         { //映射坐标不为0 设定映射
 317:mapper.c      ****             if (updown == DOWN)
 1134              		.loc 1 317 0 is_stmt 1
 1135 0a38 837DF801 		cmpl	$1, -8(%rbp)
 1136 0a3c 755C     		jne	.L59
 318:mapper.c      ****                 km_map_id[keyCode] = main_controler(REQURIE_FLAG, -1, map_postion[keyCode][0], map_
 1137              		.loc 1 318 0
 1138 0a3e 8B45F4   		movl	-12(%rbp), %eax
 1139 0a41 4898     		cltq
 1140 0a43 488D14C5 		leaq	0(,%rax,8), %rdx
 1140      00000000 
 1141 0a4b 488D0500 		leaq	4+map_postion(%rip), %rax
 1141      000000
 1142 0a52 8B1402   		movl	(%rdx,%rax), %edx
 1143 0a55 8B45F4   		movl	-12(%rbp), %eax
 1144 0a58 4898     		cltq
 1145 0a5a 488D0CC5 		leaq	0(,%rax,8), %rcx
 1145      00000000 
 1146 0a62 488D0500 		leaq	map_postion(%rip), %rax
 1146      000000
 1147 0a69 8B0401   		movl	(%rcx,%rax), %eax
 1148 0a6c 89D1     		movl	%edx, %ecx
 1149 0a6e 89C2     		movl	%eax, %edx
 1150 0a70 BEFFFFFF 		movl	$-1, %esi
 1150      FF
 1151 0a75 BF010000 		movl	$1, %edi
 1151      00
 1152 0a7a E8000000 		call	main_controler
 1152      00
 1153 0a7f 89C1     		movl	%eax, %ecx
 1154 0a81 8B45F4   		movl	-12(%rbp), %eax
 1155 0a84 4898     		cltq
 1156 0a86 488D1485 		leaq	0(,%rax,4), %rdx
 1156      00000000 
 1157 0a8e 488D0500 		leaq	km_map_id(%rip), %rax
 1157      000000
 1158 0a95 890C02   		movl	%ecx, (%rdx,%rax)
 1159 0a98 EB2D     		jmp	.L56
 1160              	.L59:
 319:mapper.c      ****             else
 320:mapper.c      ****                 main_controler(RELEASE_FLAG, km_map_id[keyCode], 0, 0); //释放
 1161              		.loc 1 320 0
 1162 0a9a 8B45F4   		movl	-12(%rbp), %eax
 1163 0a9d 4898     		cltq
 1164 0a9f 488D1485 		leaq	0(,%rax,4), %rdx
 1164      00000000 
 1165 0aa7 488D0500 		leaq	km_map_id(%rip), %rax
 1165      000000
 1166 0aae 8B0402   		movl	(%rdx,%rax), %eax
 1167 0ab1 B9000000 		movl	$0, %ecx
 1167      00
 1168 0ab6 BA000000 		movl	$0, %edx
 1168      00
 1169 0abb 89C6     		movl	%eax, %esi
 1170 0abd BF020000 		movl	$2, %edi
 1170      00
 1171 0ac2 E8000000 		call	main_controler
 1171      00
 1172              	.L56:
 321:mapper.c      ****         }
 322:mapper.c      ****     }
 323:mapper.c      ****     k_len = 0; //队列清空
 1173              		.loc 1 323 0
 1174 0ac7 C7050000 		movl	$0, k_len(%rip)
 1174      00000000 
 1174      0000
 324:mapper.c      ****     return;
 1175              		.loc 1 324 0
 1176 0ad1 90       		nop
 325:mapper.c      **** }
 1177              		.loc 1 325 0
 1178 0ad2 C9       		leave
 1179              		.cfi_def_cfa 7, 8
 1180 0ad3 C3       		ret
 1181              		.cfi_endproc
 1182              	.LFE9:
 1184              		.section	.rodata
 1185              	.LC0:
 1186 0000 636F756C 		.string	"could not open touchScreen\n"
 1186      64206E6F 
 1186      74206F70 
 1186      656E2074 
 1186      6F756368 
 1187              	.LC1:
 1188 001c 4661696C 		.string	"Failed to open keyboard."
 1188      65642074 
 1188      6F206F70 
 1188      656E206B 
 1188      6579626F 
 1189              	.LC2:
 1190 0035 52656164 		.string	"Reading From : %s \n"
 1190      696E6720 
 1190      46726F6D 
 1190      203A2025 
 1190      73200A00 
 1191              	.LC3:
 1192 0049 47657474 		.string	"Getting exclusive access: "
 1192      696E6720 
 1192      6578636C 
 1192      75736976 
 1192      65206163 
 1193              	.LC4:
 1194 0064 53554343 		.string	"SUCCESS"
 1194      45535300 
 1195              	.LC5:
 1196 006c 4641494C 		.string	"FAILURE"
 1196      55524500 
 1197              	.LC6:
 1198 0074 4661696C 		.string	"Failed to open mouse."
 1198      65642074 
 1198      6F206F70 
 1198      656E206D 
 1198      6F757365 
 1199              	.LC7:
 1200 008a 45786974 		.string	"Exiting."
 1200      696E672E 
 1200      00
 1201              		.text
 1202              		.globl	Exclusive_mode
 1204              	Exclusive_mode:
 1205              	.LFB10:
 326:mapper.c      **** 
 327:mapper.c      **** int Exclusive_mode()
 328:mapper.c      **** {
 1206              		.loc 1 328 0
 1207              		.cfi_startproc
 1208 0ad4 55       		pushq	%rbp
 1209              		.cfi_def_cfa_offset 16
 1210              		.cfi_offset 6, -16
 1211 0ad5 4889E5   		movq	%rsp, %rbp
 1212              		.cfi_def_cfa_register 6
 1213 0ad8 4881EC80 		subq	$640, %rsp
 1213      020000
 1214              		.loc 1 328 0
 1215 0adf 64488B04 		movq	%fs:40, %rax
 1215      25280000 
 1215      00
 1216 0ae8 488945F8 		movq	%rax, -8(%rbp)
 1217 0aec 31C0     		xorl	%eax, %eax
 329:mapper.c      ****     touch_fd = open(touch_dev_path, O_RDWR); //触摸设备号
 1218              		.loc 1 329 0
 1219 0aee BE020000 		movl	$2, %esi
 1219      00
 1220 0af3 488D3D00 		leaq	touch_dev_path(%rip), %rdi
 1220      000000
 1221 0afa B8000000 		movl	$0, %eax
 1221      00
 1222 0aff E8000000 		call	open@PLT
 1222      00
 1223 0b04 89050000 		movl	%eax, touch_fd(%rip)
 1223      0000
 1224              	.LBB7:
 330:mapper.c      ****     for (int i = 0; i < 4; i++)
 1225              		.loc 1 330 0
 1226 0b0a C7858CFD 		movl	$0, -628(%rbp)
 1226      FFFF0000 
 1226      0000
 1227 0b14 EB25     		jmp	.L62
 1228              	.L63:
 331:mapper.c      ****         wheel_satuse[i] = 0; //清除方向盘状态
 1229              		.loc 1 331 0 discriminator 3
 1230 0b16 8B858CFD 		movl	-628(%rbp), %eax
 1230      FFFF
 1231 0b1c 4898     		cltq
 1232 0b1e 488D1485 		leaq	0(,%rax,4), %rdx
 1232      00000000 
 1233 0b26 488D0500 		leaq	wheel_satuse(%rip), %rax
 1233      000000
 1234 0b2d C7040200 		movl	$0, (%rdx,%rax)
 1234      000000
 330:mapper.c      ****     for (int i = 0; i < 4; i++)
 1235              		.loc 1 330 0 discriminator 3
 1236 0b34 83858CFD 		addl	$1, -628(%rbp)
 1236      FFFF01
 1237              	.L62:
 330:mapper.c      ****     for (int i = 0; i < 4; i++)
 1238              		.loc 1 330 0 is_stmt 0 discriminator 1
 1239 0b3b 83BD8CFD 		cmpl	$3, -628(%rbp)
 1239      FFFF03
 1240 0b42 7ED2     		jle	.L63
 1241              	.LBE7:
 332:mapper.c      ****     if (touch_fd < 0)
 1242              		.loc 1 332 0 is_stmt 1
 1243 0b44 8B050000 		movl	touch_fd(%rip), %eax
 1243      0000
 1244 0b4a 85C0     		testl	%eax, %eax
 1245 0b4c 794E     		jns	.L64
 1246              	.LBB8:
 333:mapper.c      ****     {
 334:mapper.c      ****         fprintf(stderr, "could not open touchScreen\n");
 1247              		.loc 1 334 0
 1248 0b4e 488B0500 		movq	stderr(%rip), %rax
 1248      000000
 1249 0b55 4889C1   		movq	%rax, %rcx
 1250 0b58 BA1B0000 		movl	$27, %edx
 1250      00
 1251 0b5d BE010000 		movl	$1, %esi
 1251      00
 1252 0b62 488D3D00 		leaq	.LC0(%rip), %rdi
 1252      000000
 1253 0b69 E8000000 		call	fwrite@PLT
 1253      00
 335:mapper.c      ****         int tmp = Exclusive_mode_flag;
 1254              		.loc 1 335 0
 1255 0b6e 8B050000 		movl	Exclusive_mode_flag(%rip), %eax
 1255      0000
 1256 0b74 8985A4FD 		movl	%eax, -604(%rbp)
 1256      FFFF
 336:mapper.c      ****         Exclusive_mode_flag = no_Exclusive_mode_flag;
 1257              		.loc 1 336 0
 1258 0b7a 8B050000 		movl	no_Exclusive_mode_flag(%rip), %eax
 1258      0000
 1259 0b80 89050000 		movl	%eax, Exclusive_mode_flag(%rip)
 1259      0000
 337:mapper.c      ****         no_Exclusive_mode_flag = tmp; //切换回非独占
 1260              		.loc 1 337 0
 1261 0b86 8B85A4FD 		movl	-604(%rbp), %eax
 1261      FFFF
 1262 0b8c 89050000 		movl	%eax, no_Exclusive_mode_flag(%rip)
 1262      0000
 338:mapper.c      ****         return 1;
 1263              		.loc 1 338 0
 1264 0b92 B8010000 		movl	$1, %eax
 1264      00
 1265 0b97 E9F00400 		jmp	.L80
 1265      00
 1266              	.L64:
 1267              	.LBE8:
 339:mapper.c      ****     }
 340:mapper.c      **** 
 341:mapper.c      ****     int rcode = 0;
 1268              		.loc 1 341 0
 1269 0b9c C78598FD 		movl	$0, -616(%rbp)
 1269      FFFF0000 
 1269      0000
 342:mapper.c      ****     char keyboard_name[256] = "Unknown";
 1270              		.loc 1 342 0
 1271 0ba6 48B8556E 		movabsq	$31093567915781717, %rax
 1271      6B6E6F77 
 1271      6E00
 1272 0bb0 BA000000 		movl	$0, %edx
 1272      00
 1273 0bb5 488985F0 		movq	%rax, -528(%rbp)
 1273      FDFFFF
 1274 0bbc 488995F8 		movq	%rdx, -520(%rbp)
 1274      FDFFFF
 1275 0bc3 488D9500 		leaq	-512(%rbp), %rdx
 1275      FEFFFF
 1276 0bca B8000000 		movl	$0, %eax
 1276      00
 1277 0bcf B91E0000 		movl	$30, %ecx
 1277      00
 1278 0bd4 4889D7   		movq	%rdx, %rdi
 1279 0bd7 F348AB   		rep stosq
 343:mapper.c      ****     int keyboard_fd = open(keyboard_dev_path, O_RDONLY | O_NONBLOCK);
 1280              		.loc 1 343 0
 1281 0bda BE000800 		movl	$2048, %esi
 1281      00
 1282 0bdf 488D3D00 		leaq	keyboard_dev_path(%rip), %rdi
 1282      000000
 1283 0be6 B8000000 		movl	$0, %eax
 1283      00
 1284 0beb E8000000 		call	open@PLT
 1284      00
 1285 0bf0 89859CFD 		movl	%eax, -612(%rbp)
 1285      FFFF
 344:mapper.c      ****     if (keyboard_fd == -1)
 1286              		.loc 1 344 0
 1287 0bf6 83BD9CFD 		cmpl	$-1, -612(%rbp)
 1287      FFFFFF
 1288 0bfd 7516     		jne	.L66
 345:mapper.c      ****     {
 346:mapper.c      ****         printf("Failed to open keyboard.\n");
 1289              		.loc 1 346 0
 1290 0bff 488D3D00 		leaq	.LC1(%rip), %rdi
 1290      000000
 1291 0c06 E8000000 		call	puts@PLT
 1291      00
 347:mapper.c      ****         exit(1);
 1292              		.loc 1 347 0
 1293 0c0b BF010000 		movl	$1, %edi
 1293      00
 1294 0c10 E8000000 		call	exit@PLT
 1294      00
 1295              	.L66:
 348:mapper.c      ****     }
 349:mapper.c      ****     rcode = ioctl(keyboard_fd, EVIOCGNAME(sizeof(keyboard_name)), keyboard_name);
 1296              		.loc 1 349 0
 1297 0c15 488D95F0 		leaq	-528(%rbp), %rdx
 1297      FDFFFF
 1298 0c1c 8B859CFD 		movl	-612(%rbp), %eax
 1298      FFFF
 1299 0c22 BE064500 		movl	$2164278534, %esi
 1299      81
 1300 0c27 89C7     		movl	%eax, %edi
 1301 0c29 B8000000 		movl	$0, %eax
 1301      00
 1302 0c2e E8000000 		call	ioctl@PLT
 1302      00
 1303 0c33 898598FD 		movl	%eax, -616(%rbp)
 1303      FFFF
 350:mapper.c      ****     printf("Reading From : %s \n", keyboard_name);
 1304              		.loc 1 350 0
 1305 0c39 488D85F0 		leaq	-528(%rbp), %rax
 1305      FDFFFF
 1306 0c40 4889C6   		movq	%rax, %rsi
 1307 0c43 488D3D00 		leaq	.LC2(%rip), %rdi
 1307      000000
 1308 0c4a B8000000 		movl	$0, %eax
 1308      00
 1309 0c4f E8000000 		call	printf@PLT
 1309      00
 351:mapper.c      ****     printf("Getting exclusive access: ");
 1310              		.loc 1 351 0
 1311 0c54 488D3D00 		leaq	.LC3(%rip), %rdi
 1311      000000
 1312 0c5b B8000000 		movl	$0, %eax
 1312      00
 1313 0c60 E8000000 		call	printf@PLT
 1313      00
 352:mapper.c      ****     rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
 1314              		.loc 1 352 0
 1315 0c65 8B859CFD 		movl	-612(%rbp), %eax
 1315      FFFF
 1316 0c6b BA010000 		movl	$1, %edx
 1316      00
 1317 0c70 BE904504 		movl	$1074021776, %esi
 1317      40
 1318 0c75 89C7     		movl	%eax, %edi
 1319 0c77 B8000000 		movl	$0, %eax
 1319      00
 1320 0c7c E8000000 		call	ioctl@PLT
 1320      00
 1321 0c81 898598FD 		movl	%eax, -616(%rbp)
 1321      FFFF
 353:mapper.c      ****     printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
 1322              		.loc 1 353 0
 1323 0c87 83BD98FD 		cmpl	$0, -616(%rbp)
 1323      FFFF00
 1324 0c8e 7509     		jne	.L67
 1325              		.loc 1 353 0 is_stmt 0 discriminator 1
 1326 0c90 488D0500 		leaq	.LC4(%rip), %rax
 1326      000000
 1327 0c97 EB07     		jmp	.L68
 1328              	.L67:
 1329              		.loc 1 353 0 discriminator 2
 1330 0c99 488D0500 		leaq	.LC5(%rip), %rax
 1330      000000
 1331              	.L68:
 1332              		.loc 1 353 0 discriminator 4
 1333 0ca0 4889C7   		movq	%rax, %rdi
 1334 0ca3 E8000000 		call	puts@PLT
 1334      00
 354:mapper.c      ****     struct input_event keyboard_event;
 355:mapper.c      **** 
 356:mapper.c      ****     char mouse_name[256] = "Unknown";
 1335              		.loc 1 356 0 is_stmt 1 discriminator 4
 1336 0ca8 48B8556E 		movabsq	$31093567915781717, %rax
 1336      6B6E6F77 
 1336      6E00
 1337 0cb2 BA000000 		movl	$0, %edx
 1337      00
 1338 0cb7 488985F0 		movq	%rax, -272(%rbp)
 1338      FEFFFF
 1339 0cbe 488995F8 		movq	%rdx, -264(%rbp)
 1339      FEFFFF
 1340 0cc5 488D9500 		leaq	-256(%rbp), %rdx
 1340      FFFFFF
 1341 0ccc B8000000 		movl	$0, %eax
 1341      00
 1342 0cd1 B91E0000 		movl	$30, %ecx
 1342      00
 1343 0cd6 4889D7   		movq	%rdx, %rdi
 1344 0cd9 F348AB   		rep stosq
 357:mapper.c      ****     int mouse_fd = open(mouse_dev_path, O_RDONLY | O_NONBLOCK);
 1345              		.loc 1 357 0 discriminator 4
 1346 0cdc BE000800 		movl	$2048, %esi
 1346      00
 1347 0ce1 488D3D00 		leaq	mouse_dev_path(%rip), %rdi
 1347      000000
 1348 0ce8 B8000000 		movl	$0, %eax
 1348      00
 1349 0ced E8000000 		call	open@PLT
 1349      00
 1350 0cf2 8985A0FD 		movl	%eax, -608(%rbp)
 1350      FFFF
 358:mapper.c      ****     if (mouse_fd == -1)
 1351              		.loc 1 358 0 discriminator 4
 1352 0cf8 83BDA0FD 		cmpl	$-1, -608(%rbp)
 1352      FFFFFF
 1353 0cff 7516     		jne	.L69
 359:mapper.c      ****     {
 360:mapper.c      ****         printf("Failed to open mouse.\n");
 1354              		.loc 1 360 0
 1355 0d01 488D3D00 		leaq	.LC6(%rip), %rdi
 1355      000000
 1356 0d08 E8000000 		call	puts@PLT
 1356      00
 361:mapper.c      ****         exit(1);
 1357              		.loc 1 361 0
 1358 0d0d BF010000 		movl	$1, %edi
 1358      00
 1359 0d12 E8000000 		call	exit@PLT
 1359      00
 1360              	.L69:
 362:mapper.c      ****     }
 363:mapper.c      ****     rcode = ioctl(mouse_fd, EVIOCGNAME(sizeof(mouse_name)), mouse_name);
 1361              		.loc 1 363 0
 1362 0d17 488D95F0 		leaq	-272(%rbp), %rdx
 1362      FEFFFF
 1363 0d1e 8B85A0FD 		movl	-608(%rbp), %eax
 1363      FFFF
 1364 0d24 BE064500 		movl	$2164278534, %esi
 1364      81
 1365 0d29 89C7     		movl	%eax, %edi
 1366 0d2b B8000000 		movl	$0, %eax
 1366      00
 1367 0d30 E8000000 		call	ioctl@PLT
 1367      00
 1368 0d35 898598FD 		movl	%eax, -616(%rbp)
 1368      FFFF
 364:mapper.c      ****     printf("Reading From : %s \n", mouse_name);
 1369              		.loc 1 364 0
 1370 0d3b 488D85F0 		leaq	-272(%rbp), %rax
 1370      FEFFFF
 1371 0d42 4889C6   		movq	%rax, %rsi
 1372 0d45 488D3D00 		leaq	.LC2(%rip), %rdi
 1372      000000
 1373 0d4c B8000000 		movl	$0, %eax
 1373      00
 1374 0d51 E8000000 		call	printf@PLT
 1374      00
 365:mapper.c      ****     printf("Getting exclusive access: ");
 1375              		.loc 1 365 0
 1376 0d56 488D3D00 		leaq	.LC3(%rip), %rdi
 1376      000000
 1377 0d5d B8000000 		movl	$0, %eax
 1377      00
 1378 0d62 E8000000 		call	printf@PLT
 1378      00
 366:mapper.c      ****     rcode = ioctl(mouse_fd, EVIOCGRAB, 1);
 1379              		.loc 1 366 0
 1380 0d67 8B85A0FD 		movl	-608(%rbp), %eax
 1380      FFFF
 1381 0d6d BA010000 		movl	$1, %edx
 1381      00
 1382 0d72 BE904504 		movl	$1074021776, %esi
 1382      40
 1383 0d77 89C7     		movl	%eax, %edi
 1384 0d79 B8000000 		movl	$0, %eax
 1384      00
 1385 0d7e E8000000 		call	ioctl@PLT
 1385      00
 1386 0d83 898598FD 		movl	%eax, -616(%rbp)
 1386      FFFF
 367:mapper.c      ****     printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
 1387              		.loc 1 367 0
 1388 0d89 83BD98FD 		cmpl	$0, -616(%rbp)
 1388      FFFF00
 1389 0d90 7509     		jne	.L70
 1390              		.loc 1 367 0 is_stmt 0 discriminator 1
 1391 0d92 488D0500 		leaq	.LC4(%rip), %rax
 1391      000000
 1392 0d99 EB07     		jmp	.L71
 1393              	.L70:
 1394              		.loc 1 367 0 discriminator 2
 1395 0d9b 488D0500 		leaq	.LC5(%rip), %rax
 1395      000000
 1396              	.L71:
 1397              		.loc 1 367 0 discriminator 4
 1398 0da2 4889C7   		movq	%rax, %rdi
 1399 0da5 E8000000 		call	puts@PLT
 1399      00
 368:mapper.c      ****     struct input_event mouse_event;
 369:mapper.c      ****     cur_x = wheel_postion[4][0];
 1400              		.loc 1 369 0 is_stmt 1 discriminator 4
 1401 0daa 8B050000 		movl	32+wheel_postion(%rip), %eax
 1401      0000
 1402 0db0 89050000 		movl	%eax, cur_x(%rip)
 1402      0000
 370:mapper.c      ****     cur_y = wheel_postion[4][1];
 1403              		.loc 1 370 0 discriminator 4
 1404 0db6 8B050000 		movl	36+wheel_postion(%rip), %eax
 1404      0000
 1405 0dbc 89050000 		movl	%eax, cur_y(%rip)
 1405      0000
 371:mapper.c      ****     tar_x = cur_x;
 1406              		.loc 1 371 0 discriminator 4
 1407 0dc2 8B050000 		movl	cur_x(%rip), %eax
 1407      0000
 1408 0dc8 89050000 		movl	%eax, tar_x(%rip)
 1408      0000
 372:mapper.c      ****     tar_y = cur_y; //管理器位置重置
 1409              		.loc 1 372 0 discriminator 4
 1410 0dce 8B050000 		movl	cur_y(%rip), %eax
 1410      0000
 1411 0dd4 89050000 		movl	%eax, tar_y(%rip)
 1411      0000
 373:mapper.c      ****     pthread_t manager_thread;
 374:mapper.c      ****     pthread_create(&manager_thread, NULL, (void *)&wheel_manager, NULL);
 1412              		.loc 1 374 0 discriminator 4
 1413 0dda 488D85A8 		leaq	-600(%rbp), %rax
 1413      FDFFFF
 1414 0de1 B9000000 		movl	$0, %ecx
 1414      00
 1415 0de6 488D1500 		leaq	wheel_manager(%rip), %rdx
 1415      000000
 1416 0ded BE000000 		movl	$0, %esi
 1416      00
 1417 0df2 4889C7   		movq	%rax, %rdi
 1418 0df5 E8000000 		call	pthread_create@PLT
 1418      00
 375:mapper.c      ****     while (Exclusive_mode_flag == 1)
 1419              		.loc 1 375 0 discriminator 4
 1420 0dfa E9400100 		jmp	.L72
 1420      00
 1421              	.L74:
 376:mapper.c      ****     {
 377:mapper.c      ****         if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
 1422              		.loc 1 377 0
 1423 0dff 488D8DB0 		leaq	-592(%rbp), %rcx
 1423      FDFFFF
 1424 0e06 8B859CFD 		movl	-612(%rbp), %eax
 1424      FFFF
 1425 0e0c BA180000 		movl	$24, %edx
 1425      00
 1426 0e11 4889CE   		movq	%rcx, %rsi
 1427 0e14 89C7     		movl	%eax, %edi
 1428 0e16 E8000000 		call	read@PLT
 1428      00
 1429 0e1b 4883F8FF 		cmpq	$-1, %rax
 1430 0e1f 747E     		je	.L73
 378:mapper.c      ****         {
 379:mapper.c      ****             Keyboard_queue[k_len] = keyboard_event;
 1431              		.loc 1 379 0
 1432 0e21 8B050000 		movl	k_len(%rip), %eax
 1432      0000
 1433 0e27 4863D0   		movslq	%eax, %rdx
 1434 0e2a 4889D0   		movq	%rdx, %rax
 1435 0e2d 4801C0   		addq	%rax, %rax
 1436 0e30 4801D0   		addq	%rdx, %rax
 1437 0e33 48C1E003 		salq	$3, %rax
 1438 0e37 4889C6   		movq	%rax, %rsi
 1439 0e3a 488D0D00 		leaq	Keyboard_queue(%rip), %rcx
 1439      000000
 1440 0e41 488B85B0 		movq	-592(%rbp), %rax
 1440      FDFFFF
 1441 0e48 488B95B8 		movq	-584(%rbp), %rdx
 1441      FDFFFF
 1442 0e4f 4889040E 		movq	%rax, (%rsi,%rcx)
 1443 0e53 4889540E 		movq	%rdx, 8(%rsi,%rcx)
 1443      08
 1444 0e58 488B85C0 		movq	-576(%rbp), %rax
 1444      FDFFFF
 1445 0e5f 4889440E 		movq	%rax, 16(%rsi,%rcx)
 1445      10
 380:mapper.c      ****             k_len++;
 1446              		.loc 1 380 0
 1447 0e64 8B050000 		movl	k_len(%rip), %eax
 1447      0000
 1448 0e6a 83C001   		addl	$1, %eax
 1449 0e6d 89050000 		movl	%eax, k_len(%rip)
 1449      0000
 381:mapper.c      ****             if (keyboard_event.type == 0 && keyboard_event.code == 0 && keyboard_event.value == 0)
 1450              		.loc 1 381 0
 1451 0e73 0FB785C0 		movzwl	-576(%rbp), %eax
 1451      FDFFFF
 1452 0e7a 6685C0   		testw	%ax, %ax
 1453 0e7d 7520     		jne	.L73
 1454              		.loc 1 381 0 is_stmt 0 discriminator 1
 1455 0e7f 0FB785C2 		movzwl	-574(%rbp), %eax
 1455      FDFFFF
 1456 0e86 6685C0   		testw	%ax, %ax
 1457 0e89 7514     		jne	.L73
 1458              		.loc 1 381 0 discriminator 2
 1459 0e8b 8B85C4FD 		movl	-572(%rbp), %eax
 1459      FFFF
 1460 0e91 85C0     		testl	%eax, %eax
 1461 0e93 750A     		jne	.L73
 382:mapper.c      ****                 handel_Keyboard_queue();
 1462              		.loc 1 382 0 is_stmt 1
 1463 0e95 B8000000 		movl	$0, %eax
 1463      00
 1464 0e9a E8000000 		call	handel_Keyboard_queue
 1464      00
 1465              	.L73:
 383:mapper.c      ****         }
 384:mapper.c      ****         if (read(mouse_fd, &mouse_event, sizeof(mouse_event)) != -1)
 1466              		.loc 1 384 0
 1467 0e9f 488D8DD0 		leaq	-560(%rbp), %rcx
 1467      FDFFFF
 1468 0ea6 8B85A0FD 		movl	-608(%rbp), %eax
 1468      FFFF
 1469 0eac BA180000 		movl	$24, %edx
 1469      00
 1470 0eb1 4889CE   		movq	%rcx, %rsi
 1471 0eb4 89C7     		movl	%eax, %edi
 1472 0eb6 E8000000 		call	read@PLT
 1472      00
 1473 0ebb 4883F8FF 		cmpq	$-1, %rax
 1474 0ebf 747E     		je	.L72
 385:mapper.c      ****         {
 386:mapper.c      ****             Mouse_queue[m_len] = mouse_event;
 1475              		.loc 1 386 0
 1476 0ec1 8B050000 		movl	m_len(%rip), %eax
 1476      0000
 1477 0ec7 4863D0   		movslq	%eax, %rdx
 1478 0eca 4889D0   		movq	%rdx, %rax
 1479 0ecd 4801C0   		addq	%rax, %rax
 1480 0ed0 4801D0   		addq	%rdx, %rax
 1481 0ed3 48C1E003 		salq	$3, %rax
 1482 0ed7 4889C6   		movq	%rax, %rsi
 1483 0eda 488D0D00 		leaq	Mouse_queue(%rip), %rcx
 1483      000000
 1484 0ee1 488B85D0 		movq	-560(%rbp), %rax
 1484      FDFFFF
 1485 0ee8 488B95D8 		movq	-552(%rbp), %rdx
 1485      FDFFFF
 1486 0eef 4889040E 		movq	%rax, (%rsi,%rcx)
 1487 0ef3 4889540E 		movq	%rdx, 8(%rsi,%rcx)
 1487      08
 1488 0ef8 488B85E0 		movq	-544(%rbp), %rax
 1488      FDFFFF
 1489 0eff 4889440E 		movq	%rax, 16(%rsi,%rcx)
 1489      10
 387:mapper.c      ****             m_len++;
 1490              		.loc 1 387 0
 1491 0f04 8B050000 		movl	m_len(%rip), %eax
 1491      0000
 1492 0f0a 83C001   		addl	$1, %eax
 1493 0f0d 89050000 		movl	%eax, m_len(%rip)
 1493      0000
 388:mapper.c      ****             if (mouse_event.type == 0 && mouse_event.code == 0 && mouse_event.value == 0)
 1494              		.loc 1 388 0
 1495 0f13 0FB785E0 		movzwl	-544(%rbp), %eax
 1495      FDFFFF
 1496 0f1a 6685C0   		testw	%ax, %ax
 1497 0f1d 7520     		jne	.L72
 1498              		.loc 1 388 0 is_stmt 0 discriminator 1
 1499 0f1f 0FB785E2 		movzwl	-542(%rbp), %eax
 1499      FDFFFF
 1500 0f26 6685C0   		testw	%ax, %ax
 1501 0f29 7514     		jne	.L72
 1502              		.loc 1 388 0 discriminator 2
 1503 0f2b 8B85E4FD 		movl	-540(%rbp), %eax
 1503      FFFF
 1504 0f31 85C0     		testl	%eax, %eax
 1505 0f33 750A     		jne	.L72
 389:mapper.c      ****                 handel_Mouse_queue(); //同步信号 转处理
 1506              		.loc 1 389 0 is_stmt 1
 1507 0f35 B8000000 		movl	$0, %eax
 1507      00
 1508 0f3a E8000000 		call	handel_Mouse_queue
 1508      00
 1509              	.L72:
 375:mapper.c      ****     {
 1510              		.loc 1 375 0
 1511 0f3f 8B050000 		movl	Exclusive_mode_flag(%rip), %eax
 1511      0000
 1512 0f45 83F801   		cmpl	$1, %eax
 1513 0f48 0F84B1FE 		je	.L74
 1513      FFFF
 390:mapper.c      ****         }
 391:mapper.c      ****     }
 392:mapper.c      ****     printf("Exiting.\n");
 1514              		.loc 1 392 0
 1515 0f4e 488D3D00 		leaq	.LC7(%rip), %rdi
 1515      000000
 1516 0f55 E8000000 		call	puts@PLT
 1516      00
 393:mapper.c      ****     pthread_join(manager_thread, NULL);
 1517              		.loc 1 393 0
 1518 0f5a 488B85A8 		movq	-600(%rbp), %rax
 1518      FDFFFF
 1519 0f61 BE000000 		movl	$0, %esi
 1519      00
 1520 0f66 4889C7   		movq	%rax, %rdi
 1521 0f69 E8000000 		call	pthread_join@PLT
 1521      00
 394:mapper.c      ****     rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
 1522              		.loc 1 394 0
 1523 0f6e 8B859CFD 		movl	-612(%rbp), %eax
 1523      FFFF
 1524 0f74 BA010000 		movl	$1, %edx
 1524      00
 1525 0f79 BE904504 		movl	$1074021776, %esi
 1525      40
 1526 0f7e 89C7     		movl	%eax, %edi
 1527 0f80 B8000000 		movl	$0, %eax
 1527      00
 1528 0f85 E8000000 		call	ioctl@PLT
 1528      00
 1529 0f8a 898598FD 		movl	%eax, -616(%rbp)
 1529      FFFF
 395:mapper.c      ****     close(keyboard_fd);
 1530              		.loc 1 395 0
 1531 0f90 8B859CFD 		movl	-612(%rbp), %eax
 1531      FFFF
 1532 0f96 89C7     		movl	%eax, %edi
 1533 0f98 E8000000 		call	close@PLT
 1533      00
 396:mapper.c      ****     rcode = ioctl(mouse_fd, EVIOCGRAB, 1);
 1534              		.loc 1 396 0
 1535 0f9d 8B85A0FD 		movl	-608(%rbp), %eax
 1535      FFFF
 1536 0fa3 BA010000 		movl	$1, %edx
 1536      00
 1537 0fa8 BE904504 		movl	$1074021776, %esi
 1537      40
 1538 0fad 89C7     		movl	%eax, %edi
 1539 0faf B8000000 		movl	$0, %eax
 1539      00
 1540 0fb4 E8000000 		call	ioctl@PLT
 1540      00
 1541 0fb9 898598FD 		movl	%eax, -616(%rbp)
 1541      FFFF
 397:mapper.c      ****     close(mouse_fd); //解除独占状态
 1542              		.loc 1 397 0
 1543 0fbf 8B85A0FD 		movl	-608(%rbp), %eax
 1543      FFFF
 1544 0fc5 89C7     		movl	%eax, %edi
 1545 0fc7 E8000000 		call	close@PLT
 1545      00
 1546              	.LBB9:
 398:mapper.c      ****     for (int i = 0; i < 4; i++)
 1547              		.loc 1 398 0
 1548 0fcc C78590FD 		movl	$0, -624(%rbp)
 1548      FFFF0000 
 1548      0000
 1549 0fd6 EB25     		jmp	.L75
 1550              	.L76:
 399:mapper.c      ****         wheel_satuse[i] = 0; //清除方向盘状态
 1551              		.loc 1 399 0 discriminator 3
 1552 0fd8 8B8590FD 		movl	-624(%rbp), %eax
 1552      FFFF
 1553 0fde 4898     		cltq
 1554 0fe0 488D1485 		leaq	0(,%rax,4), %rdx
 1554      00000000 
 1555 0fe8 488D0500 		leaq	wheel_satuse(%rip), %rax
 1555      000000
 1556 0fef C7040200 		movl	$0, (%rdx,%rax)
 1556      000000
 398:mapper.c      ****     for (int i = 0; i < 4; i++)
 1557              		.loc 1 398 0 discriminator 3
 1558 0ff6 838590FD 		addl	$1, -624(%rbp)
 1558      FFFF01
 1559              	.L75:
 398:mapper.c      ****     for (int i = 0; i < 4; i++)
 1560              		.loc 1 398 0 is_stmt 0 discriminator 1
 1561 0ffd 83BD90FD 		cmpl	$3, -624(%rbp)
 1561      FFFF03
 1562 1004 7ED2     		jle	.L76
 1563              	.LBE9:
 1564              	.LBB10:
 400:mapper.c      ****     for (int i = 0; i < 10; i++)
 1565              		.loc 1 400 0 is_stmt 1
 1566 1006 C78594FD 		movl	$0, -620(%rbp)
 1566      FFFF0000 
 1566      0000
 1567 1010 EB41     		jmp	.L77
 1568              	.L79:
 401:mapper.c      ****         if (touch_id[i] != 0)
 1569              		.loc 1 401 0
 1570 1012 8B8594FD 		movl	-620(%rbp), %eax
 1570      FFFF
 1571 1018 4898     		cltq
 1572 101a 488D1485 		leaq	0(,%rax,4), %rdx
 1572      00000000 
 1573 1022 488D0500 		leaq	touch_id(%rip), %rax
 1573      000000
 1574 1029 8B0402   		movl	(%rdx,%rax), %eax
 1575 102c 85C0     		testl	%eax, %eax
 1576 102e 741C     		je	.L78
 402:mapper.c      ****             main_controler(RELEASE_FLAG, i, 0, 0); //释放所有按键
 1577              		.loc 1 402 0
 1578 1030 8B8594FD 		movl	-620(%rbp), %eax
 1578      FFFF
 1579 1036 B9000000 		movl	$0, %ecx
 1579      00
 1580 103b BA000000 		movl	$0, %edx
 1580      00
 1581 1040 89C6     		movl	%eax, %esi
 1582 1042 BF020000 		movl	$2, %edi
 1582      00
 1583 1047 E8000000 		call	main_controler
 1583      00
 1584              	.L78:
 400:mapper.c      ****     for (int i = 0; i < 10; i++)
 1585              		.loc 1 400 0 discriminator 2
 1586 104c 838594FD 		addl	$1, -620(%rbp)
 1586      FFFF01
 1587              	.L77:
 400:mapper.c      ****     for (int i = 0; i < 10; i++)
 1588              		.loc 1 400 0 is_stmt 0 discriminator 1
 1589 1053 83BD94FD 		cmpl	$9, -620(%rbp)
 1589      FFFF09
 1590 105a 7EB6     		jle	.L79
 1591              	.LBE10:
 403:mapper.c      ****     mouse_touch_id = -1;
 1592              		.loc 1 403 0 is_stmt 1
 1593 105c C7050000 		movl	$-1, mouse_touch_id(%rip)
 1593      0000FFFF 
 1593      FFFF
 404:mapper.c      ****     wheel_touch_id = -1;
 1594              		.loc 1 404 0
 1595 1066 C7050000 		movl	$-1, wheel_touch_id(%rip)
 1595      0000FFFF 
 1595      FFFF
 405:mapper.c      ****     SWITCH_ID_EVENT.value = -1; //不再每次都切换ID
 1596              		.loc 1 405 0
 1597 1070 C7050000 		movl	$-1, 20+SWITCH_ID_EVENT(%rip)
 1597      0000FFFF 
 1597      FFFF
 406:mapper.c      ****     close(touch_fd);
 1598              		.loc 1 406 0
 1599 107a 8B050000 		movl	touch_fd(%rip), %eax
 1599      0000
 1600 1080 89C7     		movl	%eax, %edi
 1601 1082 E8000000 		call	close@PLT
 1601      00
 407:mapper.c      ****     return 0;
 1602              		.loc 1 407 0
 1603 1087 B8000000 		movl	$0, %eax
 1603      00
 1604              	.L80:
 408:mapper.c      **** }
 1605              		.loc 1 408 0 discriminator 1
 1606 108c 488B4DF8 		movq	-8(%rbp), %rcx
 1607 1090 6448330C 		xorq	%fs:40, %rcx
 1607      25280000 
 1607      00
 1608 1099 7405     		je	.L81
 1609              		.loc 1 408 0 is_stmt 0
 1610 109b E8000000 		call	__stack_chk_fail@PLT
 1610      00
 1611              	.L81:
 1612 10a0 C9       		leave
 1613              		.cfi_def_cfa 7, 8
 1614 10a1 C3       		ret
 1615              		.cfi_endproc
 1616              	.LFE10:
 1618              		.globl	no_Exclusive_mode
 1620              	no_Exclusive_mode:
 1621              	.LFB11:
 409:mapper.c      **** 
 410:mapper.c      **** int no_Exclusive_mode()
 411:mapper.c      **** {
 1622              		.loc 1 411 0 is_stmt 1
 1623              		.cfi_startproc
 1624 10a2 55       		pushq	%rbp
 1625              		.cfi_def_cfa_offset 16
 1626              		.cfi_offset 6, -16
 1627 10a3 4889E5   		movq	%rsp, %rbp
 1628              		.cfi_def_cfa_register 6
 1629 10a6 4881EC40 		subq	$320, %rsp
 1629      010000
 1630              		.loc 1 411 0
 1631 10ad 64488B04 		movq	%fs:40, %rax
 1631      25280000 
 1631      00
 1632 10b6 488945F8 		movq	%rax, -8(%rbp)
 1633 10ba 31C0     		xorl	%eax, %eax
 412:mapper.c      **** 
 413:mapper.c      ****     int rcode = 0;
 1634              		.loc 1 413 0
 1635 10bc C785C8FE 		movl	$0, -312(%rbp)
 1635      FFFF0000 
 1635      0000
 414:mapper.c      ****     char keyboard_name[256] = "Unknown";
 1636              		.loc 1 414 0
 1637 10c6 48B8556E 		movabsq	$31093567915781717, %rax
 1637      6B6E6F77 
 1637      6E00
 1638 10d0 BA000000 		movl	$0, %edx
 1638      00
 1639 10d5 488985F0 		movq	%rax, -272(%rbp)
 1639      FEFFFF
 1640 10dc 488995F8 		movq	%rdx, -264(%rbp)
 1640      FEFFFF
 1641 10e3 488D9500 		leaq	-256(%rbp), %rdx
 1641      FFFFFF
 1642 10ea B8000000 		movl	$0, %eax
 1642      00
 1643 10ef B91E0000 		movl	$30, %ecx
 1643      00
 1644 10f4 4889D7   		movq	%rdx, %rdi
 1645 10f7 F348AB   		rep stosq
 415:mapper.c      ****     int keyboard_fd = open(keyboard_dev_path, O_RDONLY | O_NONBLOCK);
 1646              		.loc 1 415 0
 1647 10fa BE000800 		movl	$2048, %esi
 1647      00
 1648 10ff 488D3D00 		leaq	keyboard_dev_path(%rip), %rdi
 1648      000000
 1649 1106 B8000000 		movl	$0, %eax
 1649      00
 1650 110b E8000000 		call	open@PLT
 1650      00
 1651 1110 8985CCFE 		movl	%eax, -308(%rbp)
 1651      FFFF
 416:mapper.c      ****     if (keyboard_fd == -1)
 1652              		.loc 1 416 0
 1653 1116 83BDCCFE 		cmpl	$-1, -308(%rbp)
 1653      FFFFFF
 1654 111d 7516     		jne	.L83
 417:mapper.c      ****     {
 418:mapper.c      ****         printf("Failed to open keyboard.\n");
 1655              		.loc 1 418 0
 1656 111f 488D3D00 		leaq	.LC1(%rip), %rdi
 1656      000000
 1657 1126 E8000000 		call	puts@PLT
 1657      00
 419:mapper.c      ****         exit(1);
 1658              		.loc 1 419 0
 1659 112b BF010000 		movl	$1, %edi
 1659      00
 1660 1130 E8000000 		call	exit@PLT
 1660      00
 1661              	.L83:
 420:mapper.c      ****     }
 421:mapper.c      ****     rcode = ioctl(keyboard_fd, EVIOCGNAME(sizeof(keyboard_name)), keyboard_name);
 1662              		.loc 1 421 0
 1663 1135 488D95F0 		leaq	-272(%rbp), %rdx
 1663      FEFFFF
 1664 113c 8B85CCFE 		movl	-308(%rbp), %eax
 1664      FFFF
 1665 1142 BE064500 		movl	$2164278534, %esi
 1665      81
 1666 1147 89C7     		movl	%eax, %edi
 1667 1149 B8000000 		movl	$0, %eax
 1667      00
 1668 114e E8000000 		call	ioctl@PLT
 1668      00
 1669 1153 8985C8FE 		movl	%eax, -312(%rbp)
 1669      FFFF
 422:mapper.c      ****     printf("Reading From : %s \n", keyboard_name);
 1670              		.loc 1 422 0
 1671 1159 488D85F0 		leaq	-272(%rbp), %rax
 1671      FEFFFF
 1672 1160 4889C6   		movq	%rax, %rsi
 1673 1163 488D3D00 		leaq	.LC2(%rip), %rdi
 1673      000000
 1674 116a B8000000 		movl	$0, %eax
 1674      00
 1675 116f E8000000 		call	printf@PLT
 1675      00
 423:mapper.c      ****     struct input_event keyboard_event;
 424:mapper.c      ****     while (no_Exclusive_mode_flag == 1)
 1676              		.loc 1 424 0
 1677 1174 E9A00000 		jmp	.L84
 1677      00
 1678              	.L85:
 425:mapper.c      ****         if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
 1679              		.loc 1 425 0
 1680 1179 488D8DD0 		leaq	-304(%rbp), %rcx
 1680      FEFFFF
 1681 1180 8B85CCFE 		movl	-308(%rbp), %eax
 1681      FFFF
 1682 1186 BA180000 		movl	$24, %edx
 1682      00
 1683 118b 4889CE   		movq	%rcx, %rsi
 1684 118e 89C7     		movl	%eax, %edi
 1685 1190 E8000000 		call	read@PLT
 1685      00
 1686 1195 4883F8FF 		cmpq	$-1, %rax
 1687 1199 747E     		je	.L84
 426:mapper.c      ****         {
 427:mapper.c      ****             Keyboard_queue[k_len] = keyboard_event;
 1688              		.loc 1 427 0
 1689 119b 8B050000 		movl	k_len(%rip), %eax
 1689      0000
 1690 11a1 4863D0   		movslq	%eax, %rdx
 1691 11a4 4889D0   		movq	%rdx, %rax
 1692 11a7 4801C0   		addq	%rax, %rax
 1693 11aa 4801D0   		addq	%rdx, %rax
 1694 11ad 48C1E003 		salq	$3, %rax
 1695 11b1 4889C6   		movq	%rax, %rsi
 1696 11b4 488D0D00 		leaq	Keyboard_queue(%rip), %rcx
 1696      000000
 1697 11bb 488B85D0 		movq	-304(%rbp), %rax
 1697      FEFFFF
 1698 11c2 488B95D8 		movq	-296(%rbp), %rdx
 1698      FEFFFF
 1699 11c9 4889040E 		movq	%rax, (%rsi,%rcx)
 1700 11cd 4889540E 		movq	%rdx, 8(%rsi,%rcx)
 1700      08
 1701 11d2 488B85E0 		movq	-288(%rbp), %rax
 1701      FEFFFF
 1702 11d9 4889440E 		movq	%rax, 16(%rsi,%rcx)
 1702      10
 428:mapper.c      ****             k_len++;
 1703              		.loc 1 428 0
 1704 11de 8B050000 		movl	k_len(%rip), %eax
 1704      0000
 1705 11e4 83C001   		addl	$1, %eax
 1706 11e7 89050000 		movl	%eax, k_len(%rip)
 1706      0000
 429:mapper.c      ****             if (keyboard_event.type == 0 && keyboard_event.code == 0 && keyboard_event.value == 0)
 1707              		.loc 1 429 0
 1708 11ed 0FB785E0 		movzwl	-288(%rbp), %eax
 1708      FEFFFF
 1709 11f4 6685C0   		testw	%ax, %ax
 1710 11f7 7520     		jne	.L84
 1711              		.loc 1 429 0 is_stmt 0 discriminator 1
 1712 11f9 0FB785E2 		movzwl	-286(%rbp), %eax
 1712      FEFFFF
 1713 1200 6685C0   		testw	%ax, %ax
 1714 1203 7514     		jne	.L84
 1715              		.loc 1 429 0 discriminator 2
 1716 1205 8B85E4FE 		movl	-284(%rbp), %eax
 1716      FFFF
 1717 120b 85C0     		testl	%eax, %eax
 1718 120d 750A     		jne	.L84
 430:mapper.c      ****                 handel_Keyboard_queue();
 1719              		.loc 1 430 0 is_stmt 1
 1720 120f B8000000 		movl	$0, %eax
 1720      00
 1721 1214 E8000000 		call	handel_Keyboard_queue
 1721      00
 1722              	.L84:
 424:mapper.c      ****         if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
 1723              		.loc 1 424 0
 1724 1219 8B050000 		movl	no_Exclusive_mode_flag(%rip), %eax
 1724      0000
 1725 121f 83F801   		cmpl	$1, %eax
 1726 1222 0F8451FF 		je	.L85
 1726      FFFF
 431:mapper.c      ****         }
 432:mapper.c      ****     printf("Exiting.\n");
 1727              		.loc 1 432 0
 1728 1228 488D3D00 		leaq	.LC7(%rip), %rdi
 1728      000000
 1729 122f E8000000 		call	puts@PLT
 1729      00
 433:mapper.c      ****     close(keyboard_fd);
 1730              		.loc 1 433 0
 1731 1234 8B85CCFE 		movl	-308(%rbp), %eax
 1731      FFFF
 1732 123a 89C7     		movl	%eax, %edi
 1733 123c E8000000 		call	close@PLT
 1733      00
 434:mapper.c      ****     return 0;
 1734              		.loc 1 434 0
 1735 1241 B8000000 		movl	$0, %eax
 1735      00
 435:mapper.c      **** }
 1736              		.loc 1 435 0
 1737 1246 488B4DF8 		movq	-8(%rbp), %rcx
 1738 124a 6448330C 		xorq	%fs:40, %rcx
 1738      25280000 
 1738      00
 1739 1253 7405     		je	.L87
 1740 1255 E8000000 		call	__stack_chk_fail@PLT
 1740      00
 1741              	.L87:
 1742 125a C9       		leave
 1743              		.cfi_def_cfa 7, 8
 1744 125b C3       		ret
 1745              		.cfi_endproc
 1746              	.LFE11:
 1748              		.section	.rodata
 1749              	.LC8:
 1750 0093 2F646576 		.string	"/dev/input/event%d"
 1750      2F696E70 
 1750      75742F65 
 1750      76656E74 
 1750      256400
 1751              	.LC9:
 1752 00a6 546F7563 		.string	"Touch_dev_path:%s\n"
 1752      685F6465 
 1752      765F7061 
 1752      74683A25 
 1752      730A00
 1753              	.LC10:
 1754 00b9 4D6F7573 		.string	"Mouse_dev_path:%s\n"
 1754      655F6465 
 1754      765F7061 
 1754      74683A25 
 1754      730A00
 1755              	.LC11:
 1756 00cc 4B657962 		.string	"Keyboard_dev_path:%s\n"
 1756      6F617264 
 1756      5F646576 
 1756      5F706174 
 1756      683A2573 
 1757              	.LC12:
 1758 00e2 4661696C 		.string	"Fail to sem_sem_control init"
 1758      20746F20 
 1758      73656D5F 
 1758      73656D5F 
 1758      636F6E74 
 1759              	.LC13:
 1760 00ff 52656164 		.string	"Reading config from %s\n"
 1760      696E6720 
 1760      636F6E66 
 1760      69672066 
 1760      726F6D20 
 1761              	.LC14:
 1762 0117 7200     		.string	"r"
 1763 0119 00000000 		.align 8
 1763      000000
 1764              	.LC15:
 1765 0120 43616E27 		.string	"Can't read map file from %s, %s\n"
 1765      74207265 
 1765      6164206D 
 1765      61702066 
 1765      696C6520 
 1766              	.LC16:
 1767 0141 0A00     		.string	"\n"
 1768              	.LC17:
 1769 0143 2000     		.string	" "
 1770              		.text
 1771              		.globl	main
 1773              	main:
 1774              	.LFB12:
 436:mapper.c      **** 
 437:mapper.c      **** int main(int argc, char *argv[]) //触屏设备号 键盘设备号 鼠标设备号 mapper映射文�
 438:mapper.c      ****                                  //首先是非独占模式 由`键启动进入独占模式 独占�
 439:mapper.c      **** {
 1775              		.loc 1 439 0
 1776              		.cfi_startproc
 1777 125c 55       		pushq	%rbp
 1778              		.cfi_def_cfa_offset 16
 1779              		.cfi_offset 6, -16
 1780 125d 4889E5   		movq	%rsp, %rbp
 1781              		.cfi_def_cfa_register 6
 1782 1260 4881EC10 		subq	$11280, %rsp
 1782      2C0000
 1783 1267 89BDFCD3 		movl	%edi, -11268(%rbp)
 1783      FFFF
 1784 126d 4889B5F0 		movq	%rsi, -11280(%rbp)
 1784      D3FFFF
 1785              		.loc 1 439 0
 1786 1274 64488B04 		movq	%fs:40, %rax
 1786      25280000 
 1786      00
 1787 127d 488945F8 		movq	%rax, -8(%rbp)
 1788 1281 31C0     		xorl	%eax, %eax
 440:mapper.c      ****     int touch_dev_num = atoi(argv[1]);
 1789              		.loc 1 440 0
 1790 1283 488B85F0 		movq	-11280(%rbp), %rax
 1790      D3FFFF
 1791 128a 4883C008 		addq	$8, %rax
 1792 128e 488B00   		movq	(%rax), %rax
 1793 1291 4889C7   		movq	%rax, %rdi
 1794 1294 E8000000 		call	atoi@PLT
 1794      00
 1795 1299 89851CD4 		movl	%eax, -11236(%rbp)
 1795      FFFF
 441:mapper.c      ****     int mouse_dev_num = atoi(argv[2]);
 1796              		.loc 1 441 0
 1797 129f 488B85F0 		movq	-11280(%rbp), %rax
 1797      D3FFFF
 1798 12a6 4883C010 		addq	$16, %rax
 1799 12aa 488B00   		movq	(%rax), %rax
 1800 12ad 4889C7   		movq	%rax, %rdi
 1801 12b0 E8000000 		call	atoi@PLT
 1801      00
 1802 12b5 898520D4 		movl	%eax, -11232(%rbp)
 1802      FFFF
 442:mapper.c      ****     int keyboard_dev_num = atoi(argv[3]);
 1803              		.loc 1 442 0
 1804 12bb 488B85F0 		movq	-11280(%rbp), %rax
 1804      D3FFFF
 1805 12c2 4883C018 		addq	$24, %rax
 1806 12c6 488B00   		movq	(%rax), %rax
 1807 12c9 4889C7   		movq	%rax, %rdi
 1808 12cc E8000000 		call	atoi@PLT
 1808      00
 1809 12d1 898524D4 		movl	%eax, -11228(%rbp)
 1809      FFFF
 443:mapper.c      ****     mouse_dev = mouse_dev_num;
 1810              		.loc 1 443 0
 1811 12d7 8B8520D4 		movl	-11232(%rbp), %eax
 1811      FFFF
 1812 12dd 89050000 		movl	%eax, mouse_dev(%rip)
 1812      0000
 444:mapper.c      ****     keyboard_dev = keyboard_dev_num;
 1813              		.loc 1 444 0
 1814 12e3 8B8524D4 		movl	-11228(%rbp), %eax
 1814      FFFF
 1815 12e9 89050000 		movl	%eax, keyboard_dev(%rip)
 1815      0000
 445:mapper.c      ****     sprintf(touch_dev_path, "/dev/input/event%d", touch_dev_num);
 1816              		.loc 1 445 0
 1817 12ef 8B851CD4 		movl	-11236(%rbp), %eax
 1817      FFFF
 1818 12f5 89C2     		movl	%eax, %edx
 1819 12f7 488D3500 		leaq	.LC8(%rip), %rsi
 1819      000000
 1820 12fe 488D3D00 		leaq	touch_dev_path(%rip), %rdi
 1820      000000
 1821 1305 B8000000 		movl	$0, %eax
 1821      00
 1822 130a E8000000 		call	sprintf@PLT
 1822      00
 446:mapper.c      ****     sprintf(mouse_dev_path, "/dev/input/event%d", mouse_dev_num);
 1823              		.loc 1 446 0
 1824 130f 8B8520D4 		movl	-11232(%rbp), %eax
 1824      FFFF
 1825 1315 89C2     		movl	%eax, %edx
 1826 1317 488D3500 		leaq	.LC8(%rip), %rsi
 1826      000000
 1827 131e 488D3D00 		leaq	mouse_dev_path(%rip), %rdi
 1827      000000
 1828 1325 B8000000 		movl	$0, %eax
 1828      00
 1829 132a E8000000 		call	sprintf@PLT
 1829      00
 447:mapper.c      ****     sprintf(keyboard_dev_path, "/dev/input/event%d", keyboard_dev_num);
 1830              		.loc 1 447 0
 1831 132f 8B8524D4 		movl	-11228(%rbp), %eax
 1831      FFFF
 1832 1335 89C2     		movl	%eax, %edx
 1833 1337 488D3500 		leaq	.LC8(%rip), %rsi
 1833      000000
 1834 133e 488D3D00 		leaq	keyboard_dev_path(%rip), %rdi
 1834      000000
 1835 1345 B8000000 		movl	$0, %eax
 1835      00
 1836 134a E8000000 		call	sprintf@PLT
 1836      00
 448:mapper.c      ****     printf("Touch_dev_path:%s\n", touch_dev_path);
 1837              		.loc 1 448 0
 1838 134f 488D3500 		leaq	touch_dev_path(%rip), %rsi
 1838      000000
 1839 1356 488D3D00 		leaq	.LC9(%rip), %rdi
 1839      000000
 1840 135d B8000000 		movl	$0, %eax
 1840      00
 1841 1362 E8000000 		call	printf@PLT
 1841      00
 449:mapper.c      ****     printf("Mouse_dev_path:%s\n", mouse_dev_path);
 1842              		.loc 1 449 0
 1843 1367 488D3500 		leaq	mouse_dev_path(%rip), %rsi
 1843      000000
 1844 136e 488D3D00 		leaq	.LC10(%rip), %rdi
 1844      000000
 1845 1375 B8000000 		movl	$0, %eax
 1845      00
 1846 137a E8000000 		call	printf@PLT
 1846      00
 450:mapper.c      ****     printf("Keyboard_dev_path:%s\n", keyboard_dev_path);
 1847              		.loc 1 450 0
 1848 137f 488D3500 		leaq	keyboard_dev_path(%rip), %rsi
 1848      000000
 1849 1386 488D3D00 		leaq	.LC11(%rip), %rdi
 1849      000000
 1850 138d B8000000 		movl	$0, %eax
 1850      00
 1851 1392 E8000000 		call	printf@PLT
 1851      00
 451:mapper.c      ****     if (sem_init(&sem_control, 0, 1) != 0)
 1852              		.loc 1 451 0
 1853 1397 BA010000 		movl	$1, %edx
 1853      00
 1854 139c BE000000 		movl	$0, %esi
 1854      00
 1855 13a1 488D3D00 		leaq	sem_control(%rip), %rdi
 1855      000000
 1856 13a8 E8000000 		call	sem_init@PLT
 1856      00
 1857 13ad 85C0     		testl	%eax, %eax
 1858 13af 7416     		je	.L89
 452:mapper.c      ****     {
 453:mapper.c      ****         perror("Fail to sem_sem_control init");
 1859              		.loc 1 453 0
 1860 13b1 488D3D00 		leaq	.LC12(%rip), %rdi
 1860      000000
 1861 13b8 E8000000 		call	perror@PLT
 1861      00
 454:mapper.c      ****         exit(-1);
 1862              		.loc 1 454 0
 1863 13bd BFFFFFFF 		movl	$-1, %edi
 1863      FF
 1864 13c2 E8000000 		call	exit@PLT
 1864      00
 1865              	.L89:
 455:mapper.c      ****     }
 456:mapper.c      ****     char buf[1024 * 8];      //配置文件大小最大8KB
 457:mapper.c      ****     chdir(dirname(argv[0])); //设置当前目录为应用程序所在的目录
 1866              		.loc 1 457 0
 1867 13c7 488B85F0 		movq	-11280(%rbp), %rax
 1867      D3FFFF
 1868 13ce 488B00   		movq	(%rax), %rax
 1869 13d1 4889C7   		movq	%rax, %rdi
 1870 13d4 E8000000 		call	dirname@PLT
 1870      00
 1871 13d9 4889C7   		movq	%rax, %rdi
 1872 13dc E8000000 		call	chdir@PLT
 1872      00
 458:mapper.c      ****     printf("Reading config from %s\n", argv[4]);
 1873              		.loc 1 458 0
 1874 13e1 488B85F0 		movq	-11280(%rbp), %rax
 1874      D3FFFF
 1875 13e8 4883C020 		addq	$32, %rax
 1876 13ec 488B00   		movq	(%rax), %rax
 1877 13ef 4889C6   		movq	%rax, %rsi
 1878 13f2 488D3D00 		leaq	.LC13(%rip), %rdi
 1878      000000
 1879 13f9 B8000000 		movl	$0, %eax
 1879      00
 1880 13fe E8000000 		call	printf@PLT
 1880      00
 459:mapper.c      ****     FILE *fp = fopen(argv[4], "r");
 1881              		.loc 1 459 0
 1882 1403 488B85F0 		movq	-11280(%rbp), %rax
 1882      D3FFFF
 1883 140a 4883C020 		addq	$32, %rax
 1884 140e 488B00   		movq	(%rax), %rax
 1885 1411 488D3500 		leaq	.LC14(%rip), %rsi
 1885      000000
 1886 1418 4889C7   		movq	%rax, %rdi
 1887 141b E8000000 		call	fopen@PLT
 1887      00
 1888 1420 48898530 		movq	%rax, -11216(%rbp)
 1888      D4FFFF
 460:mapper.c      ****     if (fp == NULL)
 1889              		.loc 1 460 0
 1890 1427 4883BD30 		cmpq	$0, -11216(%rbp)
 1890      D4FFFF00 
 1891 142f 7544     		jne	.L90
 461:mapper.c      ****     {
 462:mapper.c      ****         fprintf(stderr, "Can't read map file from %s, %s\n", argv[4], strerror(errno));
 1892              		.loc 1 462 0
 1893 1431 E8000000 		call	__errno_location@PLT
 1893      00
 1894 1436 8B00     		movl	(%rax), %eax
 1895 1438 89C7     		movl	%eax, %edi
 1896 143a E8000000 		call	strerror@PLT
 1896      00
 1897 143f 4889C1   		movq	%rax, %rcx
 1898 1442 488B85F0 		movq	-11280(%rbp), %rax
 1898      D3FFFF
 1899 1449 4883C020 		addq	$32, %rax
 1900 144d 488B10   		movq	(%rax), %rdx
 1901 1450 488B0500 		movq	stderr(%rip), %rax
 1901      000000
 1902 1457 488D3500 		leaq	.LC15(%rip), %rsi
 1902      000000
 1903 145e 4889C7   		movq	%rax, %rdi
 1904 1461 B8000000 		movl	$0, %eax
 1904      00
 1905 1466 E8000000 		call	fprintf@PLT
 1905      00
 463:mapper.c      ****         exit(-2);
 1906              		.loc 1 463 0
 1907 146b BFFEFFFF 		movl	$-2, %edi
 1907      FF
 1908 1470 E8000000 		call	exit@PLT
 1908      00
 1909              	.L90:
 464:mapper.c      ****     }
 465:mapper.c      ****     fread(buf, 1024 * 8, 1, fp);
 1910              		.loc 1 465 0
 1911 1475 488B9530 		movq	-11216(%rbp), %rdx
 1911      D4FFFF
 1912 147c 488D85F0 		leaq	-8208(%rbp), %rax
 1912      DFFFFF
 1913 1483 4889D1   		movq	%rdx, %rcx
 1914 1486 BA010000 		movl	$1, %edx
 1914      00
 1915 148b BE002000 		movl	$8192, %esi
 1915      00
 1916 1490 4889C7   		movq	%rax, %rdi
 1917 1493 E8000000 		call	fread@PLT
 1917      00
 466:mapper.c      ****     fclose(fp);
 1918              		.loc 1 466 0
 1919 1498 488B8530 		movq	-11216(%rbp), %rax
 1919      D4FFFF
 1920 149f 4889C7   		movq	%rax, %rdi
 1921 14a2 E8000000 		call	fclose@PLT
 1921      00
 467:mapper.c      ****     int linecount = 0;
 1922              		.loc 1 467 0
 1923 14a7 C7850CD4 		movl	$0, -11252(%rbp)
 1923      FFFF0000 
 1923      0000
 468:mapper.c      ****     char lines[68][32];
 469:mapper.c      ****     char *token = strtok(buf, "\n");
 1924              		.loc 1 469 0
 1925 14b1 488D85F0 		leaq	-8208(%rbp), %rax
 1925      DFFFFF
 1926 14b8 488D3500 		leaq	.LC16(%rip), %rsi
 1926      000000
 1927 14bf 4889C7   		movq	%rax, %rdi
 1928 14c2 E8000000 		call	strtok@PLT
 1928      00
 1929 14c7 48898528 		movq	%rax, -11224(%rbp)
 1929      D4FFFF
 470:mapper.c      ****     while (token != NULL)
 1930              		.loc 1 470 0
 1931 14ce EB49     		jmp	.L91
 1932              	.L92:
 471:mapper.c      ****     {
 472:mapper.c      ****         strcpy(lines[linecount++], token);
 1933              		.loc 1 472 0
 1934 14d0 8B850CD4 		movl	-11252(%rbp), %eax
 1934      FFFF
 1935 14d6 8D5001   		leal	1(%rax), %edx
 1936 14d9 89950CD4 		movl	%edx, -11252(%rbp)
 1936      FFFF
 1937 14df 488D9570 		leaq	-10384(%rbp), %rdx
 1937      D7FFFF
 1938 14e6 4898     		cltq
 1939 14e8 48C1E005 		salq	$5, %rax
 1940 14ec 4801C2   		addq	%rax, %rdx
 1941 14ef 488B8528 		movq	-11224(%rbp), %rax
 1941      D4FFFF
 1942 14f6 4889C6   		movq	%rax, %rsi
 1943 14f9 4889D7   		movq	%rdx, %rdi
 1944 14fc E8000000 		call	strcpy@PLT
 1944      00
 473:mapper.c      ****         token = strtok(NULL, "\n");
 1945              		.loc 1 473 0
 1946 1501 488D3500 		leaq	.LC16(%rip), %rsi
 1946      000000
 1947 1508 BF000000 		movl	$0, %edi
 1947      00
 1948 150d E8000000 		call	strtok@PLT
 1948      00
 1949 1512 48898528 		movq	%rax, -11224(%rbp)
 1949      D4FFFF
 1950              	.L91:
 470:mapper.c      ****     while (token != NULL)
 1951              		.loc 1 470 0
 1952 1519 4883BD28 		cmpq	$0, -11224(%rbp)
 1952      D4FFFF00 
 1953 1521 75AD     		jne	.L92
 1954              	.LBB11:
 474:mapper.c      ****     }
 475:mapper.c      ****     int config[68][3];
 476:mapper.c      ****     for (int i = 0; i < linecount; i++)
 1955              		.loc 1 476 0
 1956 1523 C78510D4 		movl	$0, -11248(%rbp)
 1956      FFFF0000 
 1956      0000
 1957 152d E9DE0000 		jmp	.L93
 1957      00
 1958              	.L94:
 1959              	.LBB12:
 477:mapper.c      ****     {
 478:mapper.c      ****         char *rowData = strtok(lines[i], " ");
 1960              		.loc 1 478 0 discriminator 3
 1961 1532 488D8570 		leaq	-10384(%rbp), %rax
 1961      D7FFFF
 1962 1539 8B9510D4 		movl	-11248(%rbp), %edx
 1962      FFFF
 1963 153f 4863D2   		movslq	%edx, %rdx
 1964 1542 48C1E205 		salq	$5, %rdx
 1965 1546 4801D0   		addq	%rdx, %rax
 1966 1549 488D3500 		leaq	.LC17(%rip), %rsi
 1966      000000
 1967 1550 4889C7   		movq	%rax, %rdi
 1968 1553 E8000000 		call	strtok@PLT
 1968      00
 1969 1558 48898538 		movq	%rax, -11208(%rbp)
 1969      D4FFFF
 479:mapper.c      ****         config[i][0] = atoi(rowData);
 1970              		.loc 1 479 0 discriminator 3
 1971 155f 488B8538 		movq	-11208(%rbp), %rax
 1971      D4FFFF
 1972 1566 4889C7   		movq	%rax, %rdi
 1973 1569 E8000000 		call	atoi@PLT
 1973      00
 1974 156e 89C1     		movl	%eax, %ecx
 1975 1570 8B8510D4 		movl	-11248(%rbp), %eax
 1975      FFFF
 1976 1576 4863D0   		movslq	%eax, %rdx
 1977 1579 4889D0   		movq	%rdx, %rax
 1978 157c 4801C0   		addq	%rax, %rax
 1979 157f 4801D0   		addq	%rdx, %rax
 1980 1582 48C1E002 		salq	$2, %rax
 1981 1586 4801E8   		addq	%rbp, %rax
 1982 1589 482DC02B 		subq	$11200, %rax
 1982      0000
 1983 158f 8908     		movl	%ecx, (%rax)
 480:mapper.c      ****         config[i][1] = atoi(strtok(NULL, " "));
 1984              		.loc 1 480 0 discriminator 3
 1985 1591 488D3500 		leaq	.LC17(%rip), %rsi
 1985      000000
 1986 1598 BF000000 		movl	$0, %edi
 1986      00
 1987 159d E8000000 		call	strtok@PLT
 1987      00
 1988 15a2 4889C7   		movq	%rax, %rdi
 1989 15a5 E8000000 		call	atoi@PLT
 1989      00
 1990 15aa 89C1     		movl	%eax, %ecx
 1991 15ac 8B8510D4 		movl	-11248(%rbp), %eax
 1991      FFFF
 1992 15b2 4863D0   		movslq	%eax, %rdx
 1993 15b5 4889D0   		movq	%rdx, %rax
 1994 15b8 4801C0   		addq	%rax, %rax
 1995 15bb 4801D0   		addq	%rdx, %rax
 1996 15be 48C1E002 		salq	$2, %rax
 1997 15c2 4801E8   		addq	%rbp, %rax
 1998 15c5 482DBC2B 		subq	$11196, %rax
 1998      0000
 1999 15cb 8908     		movl	%ecx, (%rax)
 481:mapper.c      ****         config[i][2] = atoi(strtok(NULL, " "));
 2000              		.loc 1 481 0 discriminator 3
 2001 15cd 488D3500 		leaq	.LC17(%rip), %rsi
 2001      000000
 2002 15d4 BF000000 		movl	$0, %edi
 2002      00
 2003 15d9 E8000000 		call	strtok@PLT
 2003      00
 2004 15de 4889C7   		movq	%rax, %rdi
 2005 15e1 E8000000 		call	atoi@PLT
 2005      00
 2006 15e6 89C1     		movl	%eax, %ecx
 2007 15e8 8B8510D4 		movl	-11248(%rbp), %eax
 2007      FFFF
 2008 15ee 4863D0   		movslq	%eax, %rdx
 2009 15f1 4889D0   		movq	%rdx, %rax
 2010 15f4 4801C0   		addq	%rax, %rax
 2011 15f7 4801D0   		addq	%rdx, %rax
 2012 15fa 48C1E002 		salq	$2, %rax
 2013 15fe 4801E8   		addq	%rbp, %rax
 2014 1601 482DB82B 		subq	$11192, %rax
 2014      0000
 2015 1607 8908     		movl	%ecx, (%rax)
 2016              	.LBE12:
 476:mapper.c      ****     {
 2017              		.loc 1 476 0 discriminator 3
 2018 1609 838510D4 		addl	$1, -11248(%rbp)
 2018      FFFF01
 2019              	.L93:
 476:mapper.c      ****     {
 2020              		.loc 1 476 0 is_stmt 0 discriminator 1
 2021 1610 8B8510D4 		movl	-11248(%rbp), %eax
 2021      FFFF
 2022 1616 3B850CD4 		cmpl	-11252(%rbp), %eax
 2022      FFFF
 2023 161c 0F8C10FF 		jl	.L94
 2023      FFFF
 2024              	.LBE11:
 482:mapper.c      ****     }
 483:mapper.c      ****     mouse_Start_x = config[0][0];
 2025              		.loc 1 483 0 is_stmt 1
 2026 1622 8B8540D4 		movl	-11200(%rbp), %eax
 2026      FFFF
 2027 1628 89050000 		movl	%eax, mouse_Start_x(%rip)
 2027      0000
 484:mapper.c      ****     mouse_Start_y = config[0][1];
 2028              		.loc 1 484 0
 2029 162e 8B8544D4 		movl	-11196(%rbp), %eax
 2029      FFFF
 2030 1634 89050000 		movl	%eax, mouse_Start_y(%rip)
 2030      0000
 485:mapper.c      ****     mouse_speedRatio = config[0][2];
 2031              		.loc 1 485 0
 2032 163a 8B8548D4 		movl	-11192(%rbp), %eax
 2032      FFFF
 2033 1640 89050000 		movl	%eax, mouse_speedRatio(%rip)
 2033      0000
 2034              	.LBB13:
 486:mapper.c      ****     for (int i = 0; i < 9; i++)
 2035              		.loc 1 486 0
 2036 1646 C78514D4 		movl	$0, -11244(%rbp)
 2036      FFFF0000 
 2036      0000
 2037 1650 E9830000 		jmp	.L95
 2037      00
 2038              	.L96:
 487:mapper.c      ****     {
 488:mapper.c      ****         wheel_postion[i][0] = config[i + 1][1];
 2039              		.loc 1 488 0 discriminator 3
 2040 1655 8B8514D4 		movl	-11244(%rbp), %eax
 2040      FFFF
 2041 165b 83C001   		addl	$1, %eax
 2042 165e 4863D0   		movslq	%eax, %rdx
 2043 1661 4889D0   		movq	%rdx, %rax
 2044 1664 4801C0   		addq	%rax, %rax
 2045 1667 4801D0   		addq	%rdx, %rax
 2046 166a 48C1E002 		salq	$2, %rax
 2047 166e 4801E8   		addq	%rbp, %rax
 2048 1671 482DBC2B 		subq	$11196, %rax
 2048      0000
 2049 1677 8B10     		movl	(%rax), %edx
 2050 1679 8B8514D4 		movl	-11244(%rbp), %eax
 2050      FFFF
 2051 167f 4898     		cltq
 2052 1681 488D0CC5 		leaq	0(,%rax,8), %rcx
 2052      00000000 
 2053 1689 488D0500 		leaq	wheel_postion(%rip), %rax
 2053      000000
 2054 1690 891401   		movl	%edx, (%rcx,%rax)
 489:mapper.c      ****         wheel_postion[i][1] = config[i + 1][2];
 2055              		.loc 1 489 0 discriminator 3
 2056 1693 8B8514D4 		movl	-11244(%rbp), %eax
 2056      FFFF
 2057 1699 83C001   		addl	$1, %eax
 2058 169c 4863D0   		movslq	%eax, %rdx
 2059 169f 4889D0   		movq	%rdx, %rax
 2060 16a2 4801C0   		addq	%rax, %rax
 2061 16a5 4801D0   		addq	%rdx, %rax
 2062 16a8 48C1E002 		salq	$2, %rax
 2063 16ac 4801E8   		addq	%rbp, %rax
 2064 16af 482DB82B 		subq	$11192, %rax
 2064      0000
 2065 16b5 8B10     		movl	(%rax), %edx
 2066 16b7 8B8514D4 		movl	-11244(%rbp), %eax
 2066      FFFF
 2067 16bd 4898     		cltq
 2068 16bf 488D0CC5 		leaq	0(,%rax,8), %rcx
 2068      00000000 
 2069 16c7 488D0500 		leaq	4+wheel_postion(%rip), %rax
 2069      000000
 2070 16ce 891401   		movl	%edx, (%rcx,%rax)
 486:mapper.c      ****     for (int i = 0; i < 9; i++)
 2071              		.loc 1 486 0 discriminator 3
 2072 16d1 838514D4 		addl	$1, -11244(%rbp)
 2072      FFFF01
 2073              	.L95:
 486:mapper.c      ****     for (int i = 0; i < 9; i++)
 2074              		.loc 1 486 0 is_stmt 0 discriminator 1
 2075 16d8 83BD14D4 		cmpl	$8, -11244(%rbp)
 2075      FFFF08
 2076 16df 0F8E70FF 		jle	.L96
 2076      FFFF
 2077              	.LBE13:
 2078              	.LBB14:
 490:mapper.c      ****     }
 491:mapper.c      ****     for (int i = 9; i < linecount; i++)
 2079              		.loc 1 491 0 is_stmt 1
 2080 16e5 C78518D4 		movl	$9, -11240(%rbp)
 2080      FFFF0900 
 2080      0000
 2081 16ef E9B50000 		jmp	.L97
 2081      00
 2082              	.L98:
 492:mapper.c      ****     {
 493:mapper.c      ****         map_postion[config[i][0]][0] = config[i][1];
 2083              		.loc 1 493 0 discriminator 3
 2084 16f4 8B8518D4 		movl	-11240(%rbp), %eax
 2084      FFFF
 2085 16fa 4863D0   		movslq	%eax, %rdx
 2086 16fd 4889D0   		movq	%rdx, %rax
 2087 1700 4801C0   		addq	%rax, %rax
 2088 1703 4801D0   		addq	%rdx, %rax
 2089 1706 48C1E002 		salq	$2, %rax
 2090 170a 4801E8   		addq	%rbp, %rax
 2091 170d 482DC02B 		subq	$11200, %rax
 2091      0000
 2092 1713 8B08     		movl	(%rax), %ecx
 2093 1715 8B8518D4 		movl	-11240(%rbp), %eax
 2093      FFFF
 2094 171b 4863D0   		movslq	%eax, %rdx
 2095 171e 4889D0   		movq	%rdx, %rax
 2096 1721 4801C0   		addq	%rax, %rax
 2097 1724 4801D0   		addq	%rdx, %rax
 2098 1727 48C1E002 		salq	$2, %rax
 2099 172b 4801E8   		addq	%rbp, %rax
 2100 172e 482DBC2B 		subq	$11196, %rax
 2100      0000
 2101 1734 8B10     		movl	(%rax), %edx
 2102 1736 4863C1   		movslq	%ecx, %rax
 2103 1739 488D0CC5 		leaq	0(,%rax,8), %rcx
 2103      00000000 
 2104 1741 488D0500 		leaq	map_postion(%rip), %rax
 2104      000000
 2105 1748 891401   		movl	%edx, (%rcx,%rax)
 494:mapper.c      ****         map_postion[config[i][0]][1] = config[i][2];
 2106              		.loc 1 494 0 discriminator 3
 2107 174b 8B8518D4 		movl	-11240(%rbp), %eax
 2107      FFFF
 2108 1751 4863D0   		movslq	%eax, %rdx
 2109 1754 4889D0   		movq	%rdx, %rax
 2110 1757 4801C0   		addq	%rax, %rax
 2111 175a 4801D0   		addq	%rdx, %rax
 2112 175d 48C1E002 		salq	$2, %rax
 2113 1761 4801E8   		addq	%rbp, %rax
 2114 1764 482DC02B 		subq	$11200, %rax
 2114      0000
 2115 176a 8B08     		movl	(%rax), %ecx
 2116 176c 8B8518D4 		movl	-11240(%rbp), %eax
 2116      FFFF
 2117 1772 4863D0   		movslq	%eax, %rdx
 2118 1775 4889D0   		movq	%rdx, %rax
 2119 1778 4801C0   		addq	%rax, %rax
 2120 177b 4801D0   		addq	%rdx, %rax
 2121 177e 48C1E002 		salq	$2, %rax
 2122 1782 4801E8   		addq	%rbp, %rax
 2123 1785 482DB82B 		subq	$11192, %rax
 2123      0000
 2124 178b 8B10     		movl	(%rax), %edx
 2125 178d 4863C1   		movslq	%ecx, %rax
 2126 1790 488D0CC5 		leaq	0(,%rax,8), %rcx
 2126      00000000 
 2127 1798 488D0500 		leaq	4+map_postion(%rip), %rax
 2127      000000
 2128 179f 891401   		movl	%edx, (%rcx,%rax)
 491:mapper.c      ****     {
 2129              		.loc 1 491 0 discriminator 3
 2130 17a2 838518D4 		addl	$1, -11240(%rbp)
 2130      FFFF01
 2131              	.L97:
 491:mapper.c      ****     {
 2132              		.loc 1 491 0 is_stmt 0 discriminator 1
 2133 17a9 8B8518D4 		movl	-11240(%rbp), %eax
 2133      FFFF
 2134 17af 3B850CD4 		cmpl	-11252(%rbp), %eax
 2134      FFFF
 2135 17b5 0F8C39FF 		jl	.L98
 2135      FFFF
 2136              	.L99:
 2137              	.LBE14:
 495:mapper.c      ****     }
 496:mapper.c      **** 
 497:mapper.c      ****     while (1)
 498:mapper.c      ****     {
 499:mapper.c      ****         no_Exclusive_mode();
 2138              		.loc 1 499 0 is_stmt 1 discriminator 1
 2139 17bb B8000000 		movl	$0, %eax
 2139      00
 2140 17c0 E8000000 		call	no_Exclusive_mode
 2140      00
 500:mapper.c      ****         Exclusive_mode(); //记得先插鼠标 再插键盘
 2141              		.loc 1 500 0 discriminator 1
 2142 17c5 B8000000 		movl	$0, %eax
 2142      00
 2143 17ca E8000000 		call	Exclusive_mode
 2143      00
 499:mapper.c      ****         Exclusive_mode(); //记得先插鼠标 再插键盘
 2144              		.loc 1 499 0 discriminator 1
 2145 17cf EBEA     		jmp	.L99
 2146              		.cfi_endproc
 2147              	.LFE12:
 2149              	.Letext0:
 2150              		.file 2 "/usr/lib/gcc/x86_64-linux-gnu/7/include/stddef.h"
 2151              		.file 3 "/usr/include/x86_64-linux-gnu/bits/types.h"
 2152              		.file 4 "/usr/include/x86_64-linux-gnu/bits/libio.h"
 2153              		.file 5 "/usr/include/x86_64-linux-gnu/bits/types/FILE.h"
 2154              		.file 6 "/usr/include/stdio.h"
 2155              		.file 7 "/usr/include/x86_64-linux-gnu/bits/sys_errlist.h"
 2156              		.file 8 "/usr/include/x86_64-linux-gnu/bits/types/struct_timeval.h"
 2157              		.file 9 "/usr/include/x86_64-linux-gnu/bits/pthreadtypes.h"
 2158              		.file 10 "/usr/include/unistd.h"
 2159              		.file 11 "/usr/include/x86_64-linux-gnu/bits/getopt_core.h"
 2160              		.file 12 "/usr/include/x86_64-linux-gnu/sys/time.h"
 2161              		.file 13 "/usr/include/asm-generic/int-ll64.h"
 2162              		.file 14 "/usr/include/linux/input.h"
 2163              		.file 15 "/usr/include/time.h"
 2164              		.file 16 "/usr/include/x86_64-linux-gnu/bits/semaphore.h"
