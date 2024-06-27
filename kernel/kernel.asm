
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	06e000ef          	jal	ra,80000084 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 10000; // cycles; about 1ms in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	6709                	lui	a4,0x2
    8000003a:	71070713          	addi	a4,a4,1808 # 2710 <_entry-0x7fffd8f0>
    8000003e:	963a                	add	a2,a2,a4
    80000040:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000042:	0057979b          	slliw	a5,a5,0x5
    80000046:	078e                	slli	a5,a5,0x3
    80000048:	00009617          	auipc	a2,0x9
    8000004c:	fe860613          	addi	a2,a2,-24 # 80009030 <mscratch0>
    80000050:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000052:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000054:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000056:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005a:	00006797          	auipc	a5,0x6
    8000005e:	ea678793          	addi	a5,a5,-346 # 80005f00 <timervec>
    80000062:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000066:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006a:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000006e:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000072:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000076:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007a:	30479073          	csrw	mie,a5
}
    8000007e:	6422                	ld	s0,8(sp)
    80000080:	0141                	addi	sp,sp,16
    80000082:	8082                	ret

0000000080000084 <start>:
{
    80000084:	1141                	addi	sp,sp,-16
    80000086:	e406                	sd	ra,8(sp)
    80000088:	e022                	sd	s0,0(sp)
    8000008a:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008c:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000090:	7779                	lui	a4,0xffffe
    80000092:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000096:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000098:	6705                	lui	a4,0x1
    8000009a:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000009e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a0:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a4:	00001797          	auipc	a5,0x1
    800000a8:	e0278793          	addi	a5,a5,-510 # 80000ea6 <main>
    800000ac:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b0:	4781                	li	a5,0
    800000b2:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b6:	67c1                	lui	a5,0x10
    800000b8:	17fd                	addi	a5,a5,-1
    800000ba:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000be:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c2:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c6:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000ca:	10479073          	csrw	sie,a5
  timerinit();
    800000ce:	00000097          	auipc	ra,0x0
    800000d2:	f4e080e7          	jalr	-178(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d6:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000da:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000dc:	823e                	mv	tp,a5
  asm volatile("mret");
    800000de:	30200073          	mret
}
    800000e2:	60a2                	ld	ra,8(sp)
    800000e4:	6402                	ld	s0,0(sp)
    800000e6:	0141                	addi	sp,sp,16
    800000e8:	8082                	ret

00000000800000ea <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ea:	715d                	addi	sp,sp,-80
    800000ec:	e486                	sd	ra,72(sp)
    800000ee:	e0a2                	sd	s0,64(sp)
    800000f0:	fc26                	sd	s1,56(sp)
    800000f2:	f84a                	sd	s2,48(sp)
    800000f4:	f44e                	sd	s3,40(sp)
    800000f6:	f052                	sd	s4,32(sp)
    800000f8:	ec56                	sd	s5,24(sp)
    800000fa:	0880                	addi	s0,sp,80
    800000fc:	8a2a                	mv	s4,a0
    800000fe:	84ae                	mv	s1,a1
    80000100:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000102:	00011517          	auipc	a0,0x11
    80000106:	72e50513          	addi	a0,a0,1838 # 80011830 <cons>
    8000010a:	00001097          	auipc	ra,0x1
    8000010e:	af2080e7          	jalr	-1294(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80000112:	05305b63          	blez	s3,80000168 <consolewrite+0x7e>
    80000116:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000118:	5afd                	li	s5,-1
    8000011a:	4685                	li	a3,1
    8000011c:	8626                	mv	a2,s1
    8000011e:	85d2                	mv	a1,s4
    80000120:	fbf40513          	addi	a0,s0,-65
    80000124:	00002097          	auipc	ra,0x2
    80000128:	690080e7          	jalr	1680(ra) # 800027b4 <either_copyin>
    8000012c:	01550c63          	beq	a0,s5,80000144 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000130:	fbf44503          	lbu	a0,-65(s0)
    80000134:	00000097          	auipc	ra,0x0
    80000138:	796080e7          	jalr	1942(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    8000013c:	2905                	addiw	s2,s2,1
    8000013e:	0485                	addi	s1,s1,1
    80000140:	fd299de3          	bne	s3,s2,8000011a <consolewrite+0x30>
  }
  release(&cons.lock);
    80000144:	00011517          	auipc	a0,0x11
    80000148:	6ec50513          	addi	a0,a0,1772 # 80011830 <cons>
    8000014c:	00001097          	auipc	ra,0x1
    80000150:	b64080e7          	jalr	-1180(ra) # 80000cb0 <release>

  return i;
}
    80000154:	854a                	mv	a0,s2
    80000156:	60a6                	ld	ra,72(sp)
    80000158:	6406                	ld	s0,64(sp)
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	7942                	ld	s2,48(sp)
    8000015e:	79a2                	ld	s3,40(sp)
    80000160:	7a02                	ld	s4,32(sp)
    80000162:	6ae2                	ld	s5,24(sp)
    80000164:	6161                	addi	sp,sp,80
    80000166:	8082                	ret
  for(i = 0; i < n; i++){
    80000168:	4901                	li	s2,0
    8000016a:	bfe9                	j	80000144 <consolewrite+0x5a>

000000008000016c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016c:	7159                	addi	sp,sp,-112
    8000016e:	f486                	sd	ra,104(sp)
    80000170:	f0a2                	sd	s0,96(sp)
    80000172:	eca6                	sd	s1,88(sp)
    80000174:	e8ca                	sd	s2,80(sp)
    80000176:	e4ce                	sd	s3,72(sp)
    80000178:	e0d2                	sd	s4,64(sp)
    8000017a:	fc56                	sd	s5,56(sp)
    8000017c:	f85a                	sd	s6,48(sp)
    8000017e:	f45e                	sd	s7,40(sp)
    80000180:	f062                	sd	s8,32(sp)
    80000182:	ec66                	sd	s9,24(sp)
    80000184:	e86a                	sd	s10,16(sp)
    80000186:	1880                	addi	s0,sp,112
    80000188:	8aaa                	mv	s5,a0
    8000018a:	8a2e                	mv	s4,a1
    8000018c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000018e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000192:	00011517          	auipc	a0,0x11
    80000196:	69e50513          	addi	a0,a0,1694 # 80011830 <cons>
    8000019a:	00001097          	auipc	ra,0x1
    8000019e:	a62080e7          	jalr	-1438(ra) # 80000bfc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a2:	00011497          	auipc	s1,0x11
    800001a6:	68e48493          	addi	s1,s1,1678 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001aa:	00011917          	auipc	s2,0x11
    800001ae:	71e90913          	addi	s2,s2,1822 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b2:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b4:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b6:	4ca9                	li	s9,10
  while(n > 0){
    800001b8:	07305863          	blez	s3,80000228 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001bc:	0984a783          	lw	a5,152(s1)
    800001c0:	09c4a703          	lw	a4,156(s1)
    800001c4:	02f71463          	bne	a4,a5,800001ec <consoleread+0x80>
      if(myproc()->killed){
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	96c080e7          	jalr	-1684(ra) # 80001b34 <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	292080e7          	jalr	658(ra) # 8000246a <sleep>
    while(cons.r == cons.w){
    800001e0:	0984a783          	lw	a5,152(s1)
    800001e4:	09c4a703          	lw	a4,156(s1)
    800001e8:	fef700e3          	beq	a4,a5,800001c8 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ec:	0017871b          	addiw	a4,a5,1
    800001f0:	08e4ac23          	sw	a4,152(s1)
    800001f4:	07f7f713          	andi	a4,a5,127
    800001f8:	9726                	add	a4,a4,s1
    800001fa:	01874703          	lbu	a4,24(a4)
    800001fe:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000202:	077d0563          	beq	s10,s7,8000026c <consoleread+0x100>
    cbuf = c;
    80000206:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	f9f40613          	addi	a2,s0,-97
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	54a080e7          	jalr	1354(ra) # 8000275e <either_copyout>
    8000021c:	01850663          	beq	a0,s8,80000228 <consoleread+0xbc>
    dst++;
    80000220:	0a05                	addi	s4,s4,1
    --n;
    80000222:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000224:	f99d1ae3          	bne	s10,s9,800001b8 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	60850513          	addi	a0,a0,1544 # 80011830 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a80080e7          	jalr	-1408(ra) # 80000cb0 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xe4>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	5f250513          	addi	a0,a0,1522 # 80011830 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a6a080e7          	jalr	-1430(ra) # 80000cb0 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	70a6                	ld	ra,104(sp)
    80000252:	7406                	ld	s0,96(sp)
    80000254:	64e6                	ld	s1,88(sp)
    80000256:	6946                	ld	s2,80(sp)
    80000258:	69a6                	ld	s3,72(sp)
    8000025a:	6a06                	ld	s4,64(sp)
    8000025c:	7ae2                	ld	s5,56(sp)
    8000025e:	7b42                	ld	s6,48(sp)
    80000260:	7ba2                	ld	s7,40(sp)
    80000262:	7c02                	ld	s8,32(sp)
    80000264:	6ce2                	ld	s9,24(sp)
    80000266:	6d42                	ld	s10,16(sp)
    80000268:	6165                	addi	sp,sp,112
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	0009871b          	sext.w	a4,s3
    80000270:	fb677ce3          	bgeu	a4,s6,80000228 <consoleread+0xbc>
        cons.r--;
    80000274:	00011717          	auipc	a4,0x11
    80000278:	64f72a23          	sw	a5,1620(a4) # 800118c8 <cons+0x98>
    8000027c:	b775                	j	80000228 <consoleread+0xbc>

000000008000027e <consputc>:
{
    8000027e:	1141                	addi	sp,sp,-16
    80000280:	e406                	sd	ra,8(sp)
    80000282:	e022                	sd	s0,0(sp)
    80000284:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000286:	10000793          	li	a5,256
    8000028a:	00f50a63          	beq	a0,a5,8000029e <consputc+0x20>
    uartputc_sync(c);
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	55e080e7          	jalr	1374(ra) # 800007ec <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	addi	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	54c080e7          	jalr	1356(ra) # 800007ec <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	540080e7          	jalr	1344(ra) # 800007ec <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	536080e7          	jalr	1334(ra) # 800007ec <uartputc_sync>
    800002be:	bfe1                	j	80000296 <consputc+0x18>

00000000800002c0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c0:	1101                	addi	sp,sp,-32
    800002c2:	ec06                	sd	ra,24(sp)
    800002c4:	e822                	sd	s0,16(sp)
    800002c6:	e426                	sd	s1,8(sp)
    800002c8:	e04a                	sd	s2,0(sp)
    800002ca:	1000                	addi	s0,sp,32
    800002cc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ce:	00011517          	auipc	a0,0x11
    800002d2:	56250513          	addi	a0,a0,1378 # 80011830 <cons>
    800002d6:	00001097          	auipc	ra,0x1
    800002da:	926080e7          	jalr	-1754(ra) # 80000bfc <acquire>

  switch(c){
    800002de:	47d5                	li	a5,21
    800002e0:	0af48663          	beq	s1,a5,8000038c <consoleintr+0xcc>
    800002e4:	0297ca63          	blt	a5,s1,80000318 <consoleintr+0x58>
    800002e8:	47a1                	li	a5,8
    800002ea:	0ef48763          	beq	s1,a5,800003d8 <consoleintr+0x118>
    800002ee:	47c1                	li	a5,16
    800002f0:	10f49a63          	bne	s1,a5,80000404 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f4:	00002097          	auipc	ra,0x2
    800002f8:	516080e7          	jalr	1302(ra) # 8000280a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	addi	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	9ac080e7          	jalr	-1620(ra) # 80000cb0 <release>
}
    8000030c:	60e2                	ld	ra,24(sp)
    8000030e:	6442                	ld	s0,16(sp)
    80000310:	64a2                	ld	s1,8(sp)
    80000312:	6902                	ld	s2,0(sp)
    80000314:	6105                	addi	sp,sp,32
    80000316:	8082                	ret
  switch(c){
    80000318:	07f00793          	li	a5,127
    8000031c:	0af48e63          	beq	s1,a5,800003d8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000320:	00011717          	auipc	a4,0x11
    80000324:	51070713          	addi	a4,a4,1296 # 80011830 <cons>
    80000328:	0a072783          	lw	a5,160(a4)
    8000032c:	09872703          	lw	a4,152(a4)
    80000330:	9f99                	subw	a5,a5,a4
    80000332:	07f00713          	li	a4,127
    80000336:	fcf763e3          	bltu	a4,a5,800002fc <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033a:	47b5                	li	a5,13
    8000033c:	0cf48763          	beq	s1,a5,8000040a <consoleintr+0x14a>
      consputc(c);
    80000340:	8526                	mv	a0,s1
    80000342:	00000097          	auipc	ra,0x0
    80000346:	f3c080e7          	jalr	-196(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034a:	00011797          	auipc	a5,0x11
    8000034e:	4e678793          	addi	a5,a5,1254 # 80011830 <cons>
    80000352:	0a07a703          	lw	a4,160(a5)
    80000356:	0017069b          	addiw	a3,a4,1
    8000035a:	0006861b          	sext.w	a2,a3
    8000035e:	0ad7a023          	sw	a3,160(a5)
    80000362:	07f77713          	andi	a4,a4,127
    80000366:	97ba                	add	a5,a5,a4
    80000368:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036c:	47a9                	li	a5,10
    8000036e:	0cf48563          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000372:	4791                	li	a5,4
    80000374:	0cf48263          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000378:	00011797          	auipc	a5,0x11
    8000037c:	5507a783          	lw	a5,1360(a5) # 800118c8 <cons+0x98>
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	4a470713          	addi	a4,a4,1188 # 80011830 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	49448493          	addi	s1,s1,1172 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a4:	4929                	li	s2,10
    800003a6:	f4f70be3          	beq	a4,a5,800002fc <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	37fd                	addiw	a5,a5,-1
    800003ac:	07f7f713          	andi	a4,a5,127
    800003b0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b2:	01874703          	lbu	a4,24(a4)
    800003b6:	f52703e3          	beq	a4,s2,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ba:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003be:	10000513          	li	a0,256
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	ebc080e7          	jalr	-324(ra) # 8000027e <consputc>
    while(cons.e != cons.w &&
    800003ca:	0a04a783          	lw	a5,160(s1)
    800003ce:	09c4a703          	lw	a4,156(s1)
    800003d2:	fcf71ce3          	bne	a4,a5,800003aa <consoleintr+0xea>
    800003d6:	b71d                	j	800002fc <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	45870713          	addi	a4,a4,1112 # 80011830 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addiw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	4ef72123          	sw	a5,1250(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f6:	10000513          	li	a0,256
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	e84080e7          	jalr	-380(ra) # 8000027e <consputc>
    80000402:	bded                	j	800002fc <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000404:	ee048ce3          	beqz	s1,800002fc <consoleintr+0x3c>
    80000408:	bf21                	j	80000320 <consoleintr+0x60>
      consputc(c);
    8000040a:	4529                	li	a0,10
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e72080e7          	jalr	-398(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000414:	00011797          	auipc	a5,0x11
    80000418:	41c78793          	addi	a5,a5,1052 # 80011830 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addiw	a3,a4,1
    80000424:	0006861b          	sext.w	a2,a3
    80000428:	0ad7a023          	sw	a3,160(a5)
    8000042c:	07f77713          	andi	a4,a4,127
    80000430:	97ba                	add	a5,a5,a4
    80000432:	4729                	li	a4,10
    80000434:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000438:	00011797          	auipc	a5,0x11
    8000043c:	48c7aa23          	sw	a2,1172(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	48850513          	addi	a0,a0,1160 # 800118c8 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	1ce080e7          	jalr	462(ra) # 80002616 <wakeup>
    80000450:	b575                	j	800002fc <consoleintr+0x3c>

0000000080000452 <consoleinit>:

void
consoleinit(void)
{
    80000452:	1141                	addi	sp,sp,-16
    80000454:	e406                	sd	ra,8(sp)
    80000456:	e022                	sd	s0,0(sp)
    80000458:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045a:	00008597          	auipc	a1,0x8
    8000045e:	bb658593          	addi	a1,a1,-1098 # 80008010 <etext+0x10>
    80000462:	00011517          	auipc	a0,0x11
    80000466:	3ce50513          	addi	a0,a0,974 # 80011830 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	702080e7          	jalr	1794(ra) # 80000b6c <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	32a080e7          	jalr	810(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00022797          	auipc	a5,0x22
    8000047e:	33678793          	addi	a5,a5,822 # 800227b0 <devsw>
    80000482:	00000717          	auipc	a4,0x0
    80000486:	cea70713          	addi	a4,a4,-790 # 8000016c <consoleread>
    8000048a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	c5e70713          	addi	a4,a4,-930 # 800000ea <consolewrite>
    80000494:	ef98                	sd	a4,24(a5)
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	addi	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049e:	7179                	addi	sp,sp,-48
    800004a0:	f406                	sd	ra,40(sp)
    800004a2:	f022                	sd	s0,32(sp)
    800004a4:	ec26                	sd	s1,24(sp)
    800004a6:	e84a                	sd	s2,16(sp)
    800004a8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004aa:	c219                	beqz	a2,800004b0 <printint+0x12>
    800004ac:	08054663          	bltz	a0,80000538 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b0:	2501                	sext.w	a0,a0
    800004b2:	4881                	li	a7,0
    800004b4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ba:	2581                	sext.w	a1,a1
    800004bc:	00008617          	auipc	a2,0x8
    800004c0:	b8460613          	addi	a2,a2,-1148 # 80008040 <digits>
    800004c4:	883a                	mv	a6,a4
    800004c6:	2705                	addiw	a4,a4,1
    800004c8:	02b577bb          	remuw	a5,a0,a1
    800004cc:	1782                	slli	a5,a5,0x20
    800004ce:	9381                	srli	a5,a5,0x20
    800004d0:	97b2                	add	a5,a5,a2
    800004d2:	0007c783          	lbu	a5,0(a5)
    800004d6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004da:	0005079b          	sext.w	a5,a0
    800004de:	02b5553b          	divuw	a0,a0,a1
    800004e2:	0685                	addi	a3,a3,1
    800004e4:	feb7f0e3          	bgeu	a5,a1,800004c4 <printint+0x26>

  if(sign)
    800004e8:	00088b63          	beqz	a7,800004fe <printint+0x60>
    buf[i++] = '-';
    800004ec:	fe040793          	addi	a5,s0,-32
    800004f0:	973e                	add	a4,a4,a5
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x8e>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d60080e7          	jalr	-672(ra) # 8000027e <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7c>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf9d                	j	800004b4 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	3a07a223          	sw	zero,932(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b7a50513          	addi	a0,a0,-1158 # 800080e8 <digits+0xa8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	a8f72023          	sw	a5,-1408(a4) # 80009000 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	334dad83          	lw	s11,820(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	2de50513          	addi	a0,a0,734 # 800118d8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5fa080e7          	jalr	1530(ra) # 80000bfc <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c62080e7          	jalr	-926(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e32080e7          	jalr	-462(ra) # 8000049e <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0e080e7          	jalr	-498(ra) # 8000049e <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bd0080e7          	jalr	-1072(ra) # 8000027e <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc4080e7          	jalr	-1084(ra) # 8000027e <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bb0080e7          	jalr	-1104(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b8a080e7          	jalr	-1142(ra) # 8000027e <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b68080e7          	jalr	-1176(ra) # 8000027e <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5c080e7          	jalr	-1188(ra) # 8000027e <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b52080e7          	jalr	-1198(ra) # 8000027e <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00011517          	auipc	a0,0x11
    8000075c:	18050513          	addi	a0,a0,384 # 800118d8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	550080e7          	jalr	1360(ra) # 80000cb0 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00011497          	auipc	s1,0x11
    80000778:	16448493          	addi	s1,s1,356 # 800118d8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3e6080e7          	jalr	998(ra) # 80000b6c <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00011517          	auipc	a0,0x11
    800007d8:	12450513          	addi	a0,a0,292 # 800118f8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	390080e7          	jalr	912(ra) # 80000b6c <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	3b8080e7          	jalr	952(ra) # 80000bb0 <push_off>

  if(panicked){
    80000800:	00009797          	auipc	a5,0x9
    80000804:	8007a783          	lw	a5,-2048(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	andi	a0,s1,255
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	42a080e7          	jalr	1066(ra) # 80000c50 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	7cc7a783          	lw	a5,1996(a5) # 80009004 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c872703          	lw	a4,1992(a4) # 80009008 <uart_tx_w>
    80000848:	08f70063          	beq	a4,a5,800008c8 <uartstart+0x90>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000862:	00011a97          	auipc	s5,0x11
    80000866:	096a8a93          	addi	s5,s5,150 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	79a48493          	addi	s1,s1,1946 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008a17          	auipc	s4,0x8
    80000876:	796a0a13          	addi	s4,s4,1942 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	cb15                	beqz	a4,800008b6 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000884:	00fa8733          	add	a4,s5,a5
    80000888:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088c:	2785                	addiw	a5,a5,1
    8000088e:	41f7d71b          	sraiw	a4,a5,0x1f
    80000892:	01b7571b          	srliw	a4,a4,0x1b
    80000896:	9fb9                	addw	a5,a5,a4
    80000898:	8bfd                	andi	a5,a5,31
    8000089a:	9f99                	subw	a5,a5,a4
    8000089c:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	d76080e7          	jalr	-650(ra) # 80002616 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	409c                	lw	a5,0(s1)
    800008ae:	000a2703          	lw	a4,0(s4)
    800008b2:	fcf714e3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	01c50513          	addi	a0,a0,28 # 800118f8 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	318080e7          	jalr	792(ra) # 80000bfc <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008f8:	00008697          	auipc	a3,0x8
    800008fc:	7106a683          	lw	a3,1808(a3) # 80009008 <uart_tx_w>
    80000900:	0016879b          	addiw	a5,a3,1
    80000904:	41f7d71b          	sraiw	a4,a5,0x1f
    80000908:	01b7571b          	srliw	a4,a4,0x1b
    8000090c:	9fb9                	addw	a5,a5,a4
    8000090e:	8bfd                	andi	a5,a5,31
    80000910:	9f99                	subw	a5,a5,a4
    80000912:	00008717          	auipc	a4,0x8
    80000916:	6f272703          	lw	a4,1778(a4) # 80009004 <uart_tx_r>
    8000091a:	04f71363          	bne	a4,a5,80000960 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091e:	00011a17          	auipc	s4,0x11
    80000922:	fdaa0a13          	addi	s4,s4,-38 # 800118f8 <uart_tx_lock>
    80000926:	00008917          	auipc	s2,0x8
    8000092a:	6de90913          	addi	s2,s2,1758 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000092e:	00008997          	auipc	s3,0x8
    80000932:	6da98993          	addi	s3,s3,1754 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000936:	85d2                	mv	a1,s4
    80000938:	854a                	mv	a0,s2
    8000093a:	00002097          	auipc	ra,0x2
    8000093e:	b30080e7          	jalr	-1232(ra) # 8000246a <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000942:	0009a683          	lw	a3,0(s3)
    80000946:	0016879b          	addiw	a5,a3,1
    8000094a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000094e:	01b7571b          	srliw	a4,a4,0x1b
    80000952:	9fb9                	addw	a5,a5,a4
    80000954:	8bfd                	andi	a5,a5,31
    80000956:	9f99                	subw	a5,a5,a4
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	fcf70de3          	beq	a4,a5,80000936 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000960:	00011917          	auipc	s2,0x11
    80000964:	f9890913          	addi	s2,s2,-104 # 800118f8 <uart_tx_lock>
    80000968:	96ca                	add	a3,a3,s2
    8000096a:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000096e:	00008717          	auipc	a4,0x8
    80000972:	68f72d23          	sw	a5,1690(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000976:	00000097          	auipc	ra,0x0
    8000097a:	ec2080e7          	jalr	-318(ra) # 80000838 <uartstart>
      release(&uart_tx_lock);
    8000097e:	854a                	mv	a0,s2
    80000980:	00000097          	auipc	ra,0x0
    80000984:	330080e7          	jalr	816(ra) # 80000cb0 <release>
}
    80000988:	70a2                	ld	ra,40(sp)
    8000098a:	7402                	ld	s0,32(sp)
    8000098c:	64e2                	ld	s1,24(sp)
    8000098e:	6942                	ld	s2,16(sp)
    80000990:	69a2                	ld	s3,8(sp)
    80000992:	6a02                	ld	s4,0(sp)
    80000994:	6145                	addi	sp,sp,48
    80000996:	8082                	ret

0000000080000998 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000998:	1141                	addi	sp,sp,-16
    8000099a:	e422                	sd	s0,8(sp)
    8000099c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a6:	8b85                	andi	a5,a5,1
    800009a8:	cb91                	beqz	a5,800009bc <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b2:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b6:	6422                	ld	s0,8(sp)
    800009b8:	0141                	addi	sp,sp,16
    800009ba:	8082                	ret
    return -1;
    800009bc:	557d                	li	a0,-1
    800009be:	bfe5                	j	800009b6 <uartgetc+0x1e>

00000000800009c0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c0:	1101                	addi	sp,sp,-32
    800009c2:	ec06                	sd	ra,24(sp)
    800009c4:	e822                	sd	s0,16(sp)
    800009c6:	e426                	sd	s1,8(sp)
    800009c8:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ca:	54fd                	li	s1,-1
    800009cc:	a029                	j	800009d6 <uartintr+0x16>
      break;
    consoleintr(c);
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	8f2080e7          	jalr	-1806(ra) # 800002c0 <consoleintr>
    int c = uartgetc();
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	fc2080e7          	jalr	-62(ra) # 80000998 <uartgetc>
    if(c == -1)
    800009de:	fe9518e3          	bne	a0,s1,800009ce <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e2:	00011497          	auipc	s1,0x11
    800009e6:	f1648493          	addi	s1,s1,-234 # 800118f8 <uart_tx_lock>
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	210080e7          	jalr	528(ra) # 80000bfc <acquire>
  uartstart();
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	e44080e7          	jalr	-444(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009fc:	8526                	mv	a0,s1
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	2b2080e7          	jalr	690(ra) # 80000cb0 <release>
}
    80000a06:	60e2                	ld	ra,24(sp)
    80000a08:	6442                	ld	s0,16(sp)
    80000a0a:	64a2                	ld	s1,8(sp)
    80000a0c:	6105                	addi	sp,sp,32
    80000a0e:	8082                	ret

0000000080000a10 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a10:	1101                	addi	sp,sp,-32
    80000a12:	ec06                	sd	ra,24(sp)
    80000a14:	e822                	sd	s0,16(sp)
    80000a16:	e426                	sd	s1,8(sp)
    80000a18:	e04a                	sd	s2,0(sp)
    80000a1a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1c:	03451793          	slli	a5,a0,0x34
    80000a20:	ebb9                	bnez	a5,80000a76 <kfree+0x66>
    80000a22:	84aa                	mv	s1,a0
    80000a24:	00026797          	auipc	a5,0x26
    80000a28:	5dc78793          	addi	a5,a5,1500 # 80027000 <end>
    80000a2c:	04f56563          	bltu	a0,a5,80000a76 <kfree+0x66>
    80000a30:	47c5                	li	a5,17
    80000a32:	07ee                	slli	a5,a5,0x1b
    80000a34:	04f57163          	bgeu	a0,a5,80000a76 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a38:	6605                	lui	a2,0x1
    80000a3a:	4585                	li	a1,1
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	2bc080e7          	jalr	700(ra) # 80000cf8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a44:	00011917          	auipc	s2,0x11
    80000a48:	eec90913          	addi	s2,s2,-276 # 80011930 <kmem>
    80000a4c:	854a                	mv	a0,s2
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	1ae080e7          	jalr	430(ra) # 80000bfc <acquire>
  r->next = kmem.freelist;
    80000a56:	01893783          	ld	a5,24(s2)
    80000a5a:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5c:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	24e080e7          	jalr	590(ra) # 80000cb0 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00007517          	auipc	a0,0x7
    80000a7a:	5ea50513          	addi	a0,a0,1514 # 80008060 <digits+0x20>
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	ac2080e7          	jalr	-1342(ra) # 80000540 <panic>

0000000080000a86 <freerange>:
{
    80000a86:	7179                	addi	sp,sp,-48
    80000a88:	f406                	sd	ra,40(sp)
    80000a8a:	f022                	sd	s0,32(sp)
    80000a8c:	ec26                	sd	s1,24(sp)
    80000a8e:	e84a                	sd	s2,16(sp)
    80000a90:	e44e                	sd	s3,8(sp)
    80000a92:	e052                	sd	s4,0(sp)
    80000a94:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a96:	6785                	lui	a5,0x1
    80000a98:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9c:	94aa                	add	s1,s1,a0
    80000a9e:	757d                	lui	a0,0xfffff
    80000aa0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94be                	add	s1,s1,a5
    80000aa4:	0095ee63          	bltu	a1,s1,80000ac0 <freerange+0x3a>
    80000aa8:	892e                	mv	s2,a1
    kfree(p);
    80000aaa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aac:	6985                	lui	s3,0x1
    kfree(p);
    80000aae:	01448533          	add	a0,s1,s4
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	f5e080e7          	jalr	-162(ra) # 80000a10 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aba:	94ce                	add	s1,s1,s3
    80000abc:	fe9979e3          	bgeu	s2,s1,80000aae <freerange+0x28>
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6942                	ld	s2,16(sp)
    80000ac8:	69a2                	ld	s3,8(sp)
    80000aca:	6a02                	ld	s4,0(sp)
    80000acc:	6145                	addi	sp,sp,48
    80000ace:	8082                	ret

0000000080000ad0 <kinit>:
{
    80000ad0:	1141                	addi	sp,sp,-16
    80000ad2:	e406                	sd	ra,8(sp)
    80000ad4:	e022                	sd	s0,0(sp)
    80000ad6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad8:	00007597          	auipc	a1,0x7
    80000adc:	59058593          	addi	a1,a1,1424 # 80008068 <digits+0x28>
    80000ae0:	00011517          	auipc	a0,0x11
    80000ae4:	e5050513          	addi	a0,a0,-432 # 80011930 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af0:	45c5                	li	a1,17
    80000af2:	05ee                	slli	a1,a1,0x1b
    80000af4:	00026517          	auipc	a0,0x26
    80000af8:	50c50513          	addi	a0,a0,1292 # 80027000 <end>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	f8a080e7          	jalr	-118(ra) # 80000a86 <freerange>
}
    80000b04:	60a2                	ld	ra,8(sp)
    80000b06:	6402                	ld	s0,0(sp)
    80000b08:	0141                	addi	sp,sp,16
    80000b0a:	8082                	ret

0000000080000b0c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0c:	1101                	addi	sp,sp,-32
    80000b0e:	ec06                	sd	ra,24(sp)
    80000b10:	e822                	sd	s0,16(sp)
    80000b12:	e426                	sd	s1,8(sp)
    80000b14:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b16:	00011497          	auipc	s1,0x11
    80000b1a:	e1a48493          	addi	s1,s1,-486 # 80011930 <kmem>
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	0dc080e7          	jalr	220(ra) # 80000bfc <acquire>
  r = kmem.freelist;
    80000b28:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2a:	c885                	beqz	s1,80000b5a <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2c:	609c                	ld	a5,0(s1)
    80000b2e:	00011517          	auipc	a0,0x11
    80000b32:	e0250513          	addi	a0,a0,-510 # 80011930 <kmem>
    80000b36:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b40:	6605                	lui	a2,0x1
    80000b42:	4595                	li	a1,5
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	1b2080e7          	jalr	434(ra) # 80000cf8 <memset>
  return (void*)r;
}
    80000b4e:	8526                	mv	a0,s1
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	addi	sp,sp,32
    80000b58:	8082                	ret
  release(&kmem.lock);
    80000b5a:	00011517          	auipc	a0,0x11
    80000b5e:	dd650513          	addi	a0,a0,-554 # 80011930 <kmem>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	14e080e7          	jalr	334(ra) # 80000cb0 <release>
  if(r)
    80000b6a:	b7d5                	j	80000b4e <kalloc+0x42>

0000000080000b6c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6c:	1141                	addi	sp,sp,-16
    80000b6e:	e422                	sd	s0,8(sp)
    80000b70:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b72:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b74:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b78:	00053823          	sd	zero,16(a0)
}
    80000b7c:	6422                	ld	s0,8(sp)
    80000b7e:	0141                	addi	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	411c                	lw	a5,0(a0)
    80000b84:	e399                	bnez	a5,80000b8a <holding+0x8>
    80000b86:	4501                	li	a0,0
  return r;
}
    80000b88:	8082                	ret
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b94:	6904                	ld	s1,16(a0)
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	f82080e7          	jalr	-126(ra) # 80001b18 <mycpu>
    80000b9e:	40a48533          	sub	a0,s1,a0
    80000ba2:	00153513          	seqz	a0,a0
}
    80000ba6:	60e2                	ld	ra,24(sp)
    80000ba8:	6442                	ld	s0,16(sp)
    80000baa:	64a2                	ld	s1,8(sp)
    80000bac:	6105                	addi	sp,sp,32
    80000bae:	8082                	ret

0000000080000bb0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bba:	100024f3          	csrr	s1,sstatus
    80000bbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bc8:	00001097          	auipc	ra,0x1
    80000bcc:	f50080e7          	jalr	-176(ra) # 80001b18 <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f44080e7          	jalr	-188(ra) # 80001b18 <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	2785                	addiw	a5,a5,1
    80000be0:	dd3c                	sw	a5,120(a0)
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret
    mycpu()->intena = old;
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	f2c080e7          	jalr	-212(ra) # 80001b18 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf4:	8085                	srli	s1,s1,0x1
    80000bf6:	8885                	andi	s1,s1,1
    80000bf8:	dd64                	sw	s1,124(a0)
    80000bfa:	bfe9                	j	80000bd4 <push_off+0x24>

0000000080000bfc <acquire>:
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
    80000c06:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	fa8080e7          	jalr	-88(ra) # 80000bb0 <push_off>
  if(holding(lk))
    80000c10:	8526                	mv	a0,s1
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	f70080e7          	jalr	-144(ra) # 80000b82 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	4705                	li	a4,1
  if(holding(lk))
    80000c1c:	e115                	bnez	a0,80000c40 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	87ba                	mv	a5,a4
    80000c20:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c24:	2781                	sext.w	a5,a5
    80000c26:	ffe5                	bnez	a5,80000c1e <acquire+0x22>
  __sync_synchronize();
    80000c28:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	eec080e7          	jalr	-276(ra) # 80001b18 <mycpu>
    80000c34:	e888                	sd	a0,16(s1)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	addi	sp,sp,32
    80000c3e:	8082                	ret
    panic("acquire");
    80000c40:	00007517          	auipc	a0,0x7
    80000c44:	43050513          	addi	a0,a0,1072 # 80008070 <digits+0x30>
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	8f8080e7          	jalr	-1800(ra) # 80000540 <panic>

0000000080000c50 <pop_off>:

void
pop_off(void)
{
    80000c50:	1141                	addi	sp,sp,-16
    80000c52:	e406                	sd	ra,8(sp)
    80000c54:	e022                	sd	s0,0(sp)
    80000c56:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c58:	00001097          	auipc	ra,0x1
    80000c5c:	ec0080e7          	jalr	-320(ra) # 80001b18 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c66:	e78d                	bnez	a5,80000c90 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c68:	5d3c                	lw	a5,120(a0)
    80000c6a:	02f05b63          	blez	a5,80000ca0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c6e:	37fd                	addiw	a5,a5,-1
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c76:	eb09                	bnez	a4,80000c88 <pop_off+0x38>
    80000c78:	5d7c                	lw	a5,124(a0)
    80000c7a:	c799                	beqz	a5,80000c88 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c80:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c84:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c88:	60a2                	ld	ra,8(sp)
    80000c8a:	6402                	ld	s0,0(sp)
    80000c8c:	0141                	addi	sp,sp,16
    80000c8e:	8082                	ret
    panic("pop_off - interruptible");
    80000c90:	00007517          	auipc	a0,0x7
    80000c94:	3e850513          	addi	a0,a0,1000 # 80008078 <digits+0x38>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8a8080e7          	jalr	-1880(ra) # 80000540 <panic>
    panic("pop_off");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3f050513          	addi	a0,a0,1008 # 80008090 <digits+0x50>
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	898080e7          	jalr	-1896(ra) # 80000540 <panic>

0000000080000cb0 <release>:
{
    80000cb0:	1101                	addi	sp,sp,-32
    80000cb2:	ec06                	sd	ra,24(sp)
    80000cb4:	e822                	sd	s0,16(sp)
    80000cb6:	e426                	sd	s1,8(sp)
    80000cb8:	1000                	addi	s0,sp,32
    80000cba:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	ec6080e7          	jalr	-314(ra) # 80000b82 <holding>
    80000cc4:	c115                	beqz	a0,80000ce8 <release+0x38>
  lk->cpu = 0;
    80000cc6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cce:	0f50000f          	fence	iorw,ow
    80000cd2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd6:	00000097          	auipc	ra,0x0
    80000cda:	f7a080e7          	jalr	-134(ra) # 80000c50 <pop_off>
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	addi	sp,sp,32
    80000ce6:	8082                	ret
    panic("release");
    80000ce8:	00007517          	auipc	a0,0x7
    80000cec:	3b050513          	addi	a0,a0,944 # 80008098 <digits+0x58>
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	850080e7          	jalr	-1968(ra) # 80000540 <panic>

0000000080000cf8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cfe:	ca19                	beqz	a2,80000d14 <memset+0x1c>
    80000d00:	87aa                	mv	a5,a0
    80000d02:	1602                	slli	a2,a2,0x20
    80000d04:	9201                	srli	a2,a2,0x20
    80000d06:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0e:	0785                	addi	a5,a5,1
    80000d10:	fee79de3          	bne	a5,a4,80000d0a <memset+0x12>
  }
  return dst;
}
    80000d14:	6422                	ld	s0,8(sp)
    80000d16:	0141                	addi	sp,sp,16
    80000d18:	8082                	ret

0000000080000d1a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d20:	ca05                	beqz	a2,80000d50 <memcmp+0x36>
    80000d22:	fff6069b          	addiw	a3,a2,-1
    80000d26:	1682                	slli	a3,a3,0x20
    80000d28:	9281                	srli	a3,a3,0x20
    80000d2a:	0685                	addi	a3,a3,1
    80000d2c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2e:	00054783          	lbu	a5,0(a0)
    80000d32:	0005c703          	lbu	a4,0(a1)
    80000d36:	00e79863          	bne	a5,a4,80000d46 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3a:	0505                	addi	a0,a0,1
    80000d3c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d3e:	fed518e3          	bne	a0,a3,80000d2e <memcmp+0x14>
  }

  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	a019                	j	80000d4a <memcmp+0x30>
      return *s1 - *s2;
    80000d46:	40e7853b          	subw	a0,a5,a4
}
    80000d4a:	6422                	ld	s0,8(sp)
    80000d4c:	0141                	addi	sp,sp,16
    80000d4e:	8082                	ret
  return 0;
    80000d50:	4501                	li	a0,0
    80000d52:	bfe5                	j	80000d4a <memcmp+0x30>

0000000080000d54 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d54:	1141                	addi	sp,sp,-16
    80000d56:	e422                	sd	s0,8(sp)
    80000d58:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5a:	02a5e563          	bltu	a1,a0,80000d84 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5e:	fff6069b          	addiw	a3,a2,-1
    80000d62:	ce11                	beqz	a2,80000d7e <memmove+0x2a>
    80000d64:	1682                	slli	a3,a3,0x20
    80000d66:	9281                	srli	a3,a3,0x20
    80000d68:	0685                	addi	a3,a3,1
    80000d6a:	96ae                	add	a3,a3,a1
    80000d6c:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fff5c703          	lbu	a4,-1(a1)
    80000d76:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7a:	fed59ae3          	bne	a1,a3,80000d6e <memmove+0x1a>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
  if(s < d && s + n > d){
    80000d84:	02061713          	slli	a4,a2,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	fcf578e3          	bgeu	a0,a5,80000d5e <memmove+0xa>
    d += n;
    80000d92:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d94:	fff6069b          	addiw	a3,a2,-1
    80000d98:	d27d                	beqz	a2,80000d7e <memmove+0x2a>
    80000d9a:	02069613          	slli	a2,a3,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	fff64613          	not	a2,a2
    80000da4:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da6:	17fd                	addi	a5,a5,-1
    80000da8:	177d                	addi	a4,a4,-1
    80000daa:	0007c683          	lbu	a3,0(a5)
    80000dae:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db2:	fef61ae3          	bne	a2,a5,80000da6 <memmove+0x52>
    80000db6:	b7e1                	j	80000d7e <memmove+0x2a>

0000000080000db8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e406                	sd	ra,8(sp)
    80000dbc:	e022                	sd	s0,0(sp)
    80000dbe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc0:	00000097          	auipc	ra,0x0
    80000dc4:	f94080e7          	jalr	-108(ra) # 80000d54 <memmove>
}
    80000dc8:	60a2                	ld	ra,8(sp)
    80000dca:	6402                	ld	s0,0(sp)
    80000dcc:	0141                	addi	sp,sp,16
    80000dce:	8082                	ret

0000000080000dd0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd6:	ce11                	beqz	a2,80000df2 <strncmp+0x22>
    80000dd8:	00054783          	lbu	a5,0(a0)
    80000ddc:	cf89                	beqz	a5,80000df6 <strncmp+0x26>
    80000dde:	0005c703          	lbu	a4,0(a1)
    80000de2:	00f71a63          	bne	a4,a5,80000df6 <strncmp+0x26>
    n--, p++, q++;
    80000de6:	367d                	addiw	a2,a2,-1
    80000de8:	0505                	addi	a0,a0,1
    80000dea:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dec:	f675                	bnez	a2,80000dd8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	a809                	j	80000e02 <strncmp+0x32>
    80000df2:	4501                	li	a0,0
    80000df4:	a039                	j	80000e02 <strncmp+0x32>
  if(n == 0)
    80000df6:	ca09                	beqz	a2,80000e08 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000df8:	00054503          	lbu	a0,0(a0)
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	9d1d                	subw	a0,a0,a5
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret
    return 0;
    80000e08:	4501                	li	a0,0
    80000e0a:	bfe5                	j	80000e02 <strncmp+0x32>

0000000080000e0c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e12:	872a                	mv	a4,a0
    80000e14:	8832                	mv	a6,a2
    80000e16:	367d                	addiw	a2,a2,-1
    80000e18:	01005963          	blez	a6,80000e2a <strncpy+0x1e>
    80000e1c:	0705                	addi	a4,a4,1
    80000e1e:	0005c783          	lbu	a5,0(a1)
    80000e22:	fef70fa3          	sb	a5,-1(a4)
    80000e26:	0585                	addi	a1,a1,1
    80000e28:	f7f5                	bnez	a5,80000e14 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2a:	86ba                	mv	a3,a4
    80000e2c:	00c05c63          	blez	a2,80000e44 <strncpy+0x38>
    *s++ = 0;
    80000e30:	0685                	addi	a3,a3,1
    80000e32:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e36:	fff6c793          	not	a5,a3
    80000e3a:	9fb9                	addw	a5,a5,a4
    80000e3c:	010787bb          	addw	a5,a5,a6
    80000e40:	fef048e3          	bgtz	a5,80000e30 <strncpy+0x24>
  return os;
}
    80000e44:	6422                	ld	s0,8(sp)
    80000e46:	0141                	addi	sp,sp,16
    80000e48:	8082                	ret

0000000080000e4a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4a:	1141                	addi	sp,sp,-16
    80000e4c:	e422                	sd	s0,8(sp)
    80000e4e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e50:	02c05363          	blez	a2,80000e76 <safestrcpy+0x2c>
    80000e54:	fff6069b          	addiw	a3,a2,-1
    80000e58:	1682                	slli	a3,a3,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	96ae                	add	a3,a3,a1
    80000e5e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e60:	00d58963          	beq	a1,a3,80000e72 <safestrcpy+0x28>
    80000e64:	0585                	addi	a1,a1,1
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff5c703          	lbu	a4,-1(a1)
    80000e6c:	fee78fa3          	sb	a4,-1(a5)
    80000e70:	fb65                	bnez	a4,80000e60 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e72:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret

0000000080000e7c <strlen>:

int
strlen(const char *s)
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e422                	sd	s0,8(sp)
    80000e80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e82:	00054783          	lbu	a5,0(a0)
    80000e86:	cf91                	beqz	a5,80000ea2 <strlen+0x26>
    80000e88:	0505                	addi	a0,a0,1
    80000e8a:	87aa                	mv	a5,a0
    80000e8c:	4685                	li	a3,1
    80000e8e:	9e89                	subw	a3,a3,a0
    80000e90:	00f6853b          	addw	a0,a3,a5
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff7c703          	lbu	a4,-1(a5)
    80000e9a:	fb7d                	bnez	a4,80000e90 <strlen+0x14>
    ;
  return n;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea2:	4501                	li	a0,0
    80000ea4:	bfe5                	j	80000e9c <strlen+0x20>

0000000080000ea6 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e406                	sd	ra,8(sp)
    80000eaa:	e022                	sd	s0,0(sp)
    80000eac:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eae:	00001097          	auipc	ra,0x1
    80000eb2:	c5a080e7          	jalr	-934(ra) # 80001b08 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb6:	00008717          	auipc	a4,0x8
    80000eba:	15670713          	addi	a4,a4,342 # 8000900c <started>
  if(cpuid() == 0){
    80000ebe:	c139                	beqz	a0,80000f04 <main+0x5e>
    while(started == 0)
    80000ec0:	431c                	lw	a5,0(a4)
    80000ec2:	2781                	sext.w	a5,a5
    80000ec4:	dff5                	beqz	a5,80000ec0 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	c3e080e7          	jalr	-962(ra) # 80001b08 <cpuid>
    80000ed2:	85aa                	mv	a1,a0
    80000ed4:	00007517          	auipc	a0,0x7
    80000ed8:	20450513          	addi	a0,a0,516 # 800080d8 <digits+0x98>
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	6ae080e7          	jalr	1710(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	0c8080e7          	jalr	200(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eec:	00002097          	auipc	ra,0x2
    80000ef0:	a5e080e7          	jalr	-1442(ra) # 8000294a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	04c080e7          	jalr	76(ra) # 80005f40 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	1dc080e7          	jalr	476(ra) # 800020d8 <scheduler>
    consoleinit();
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	54e080e7          	jalr	1358(ra) # 80000452 <consoleinit>
    printfinit();
    80000f0c:	00000097          	auipc	ra,0x0
    80000f10:	85e080e7          	jalr	-1954(ra) # 8000076a <printfinit>
    printf("\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	1d450513          	addi	a0,a0,468 # 800080e8 <digits+0xa8>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66e080e7          	jalr	1646(ra) # 8000058a <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	17c50513          	addi	a0,a0,380 # 800080a0 <digits+0x60>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65e080e7          	jalr	1630(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b9c080e7          	jalr	-1124(ra) # 80000ad0 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	2a0080e7          	jalr	672(ra) # 800011dc <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	aec080e7          	jalr	-1300(ra) # 80001a38 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9ce080e7          	jalr	-1586(ra) # 80002922 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	9ee080e7          	jalr	-1554(ra) # 8000294a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fc6080e7          	jalr	-58(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	fd4080e7          	jalr	-44(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	17a080e7          	jalr	378(ra) # 800030ee <binit>
    iinit();         // inode cache
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	80a080e7          	jalr	-2038(ra) # 80003786 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	7a4080e7          	jalr	1956(ra) # 80004728 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	0bc080e7          	jalr	188(ra) # 80006048 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	eda080e7          	jalr	-294(ra) # 80001e6e <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72523          	sw	a5,106(a4) # 8000900c <started>
    80000faa:	bf89                	j	80000efc <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	05e7b783          	ld	a5,94(a5) # 80009010 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0fa50513          	addi	a0,a0,250 # 800080f0 <digits+0xb0>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	542080e7          	jalr	1346(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	b02080e7          	jalr	-1278(ra) # 80000b0c <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cde080e7          	jalr	-802(ra) # 80000cf8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010b8:	1101                	addi	sp,sp,-32
    800010ba:	ec06                	sd	ra,24(sp)
    800010bc:	e822                	sd	s0,16(sp)
    800010be:	e426                	sd	s1,8(sp)
    800010c0:	1000                	addi	s0,sp,32
    800010c2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010c4:	1552                	slli	a0,a0,0x34
    800010c6:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00008517          	auipc	a0,0x8
    800010d0:	f4453503          	ld	a0,-188(a0) # 80009010 <kernel_pagetable>
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	efc080e7          	jalr	-260(ra) # 80000fd0 <walk>
  if(pte == 0)
    800010dc:	cd09                	beqz	a0,800010f6 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010de:	6108                	ld	a0,0(a0)
    800010e0:	00157793          	andi	a5,a0,1
    800010e4:	c38d                	beqz	a5,80001106 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010e6:	8129                	srli	a0,a0,0xa
    800010e8:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ea:	9526                	add	a0,a0,s1
    800010ec:	60e2                	ld	ra,24(sp)
    800010ee:	6442                	ld	s0,16(sp)
    800010f0:	64a2                	ld	s1,8(sp)
    800010f2:	6105                	addi	sp,sp,32
    800010f4:	8082                	ret
    panic("kvmpa");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	00250513          	addi	a0,a0,2 # 800080f8 <digits+0xb8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	442080e7          	jalr	1090(ra) # 80000540 <panic>
    panic("kvmpa");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	ff250513          	addi	a0,a0,-14 # 800080f8 <digits+0xb8>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	432080e7          	jalr	1074(ra) # 80000540 <panic>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
    8000112c:	8aaa                	mv	s5,a0
    8000112e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001130:	777d                	lui	a4,0xfffff
    80001132:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001136:	167d                	addi	a2,a2,-1
    80001138:	00b609b3          	add	s3,a2,a1
    8000113c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001140:	893e                	mv	s2,a5
    80001142:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001146:	6b85                	lui	s7,0x1
    80001148:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114c:	4605                	li	a2,1
    8000114e:	85ca                	mv	a1,s2
    80001150:	8556                	mv	a0,s5
    80001152:	00000097          	auipc	ra,0x0
    80001156:	e7e080e7          	jalr	-386(ra) # 80000fd0 <walk>
    8000115a:	c51d                	beqz	a0,80001188 <mappages+0x72>
    if(*pte & PTE_V)
    8000115c:	611c                	ld	a5,0(a0)
    8000115e:	8b85                	andi	a5,a5,1
    80001160:	ef81                	bnez	a5,80001178 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001162:	80b1                	srli	s1,s1,0xc
    80001164:	04aa                	slli	s1,s1,0xa
    80001166:	0164e4b3          	or	s1,s1,s6
    8000116a:	0014e493          	ori	s1,s1,1
    8000116e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001170:	03390863          	beq	s2,s3,800011a0 <mappages+0x8a>
    a += PGSIZE;
    80001174:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001176:	bfc9                	j	80001148 <mappages+0x32>
      panic("remap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8850513          	addi	a0,a0,-120 # 80008100 <digits+0xc0>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c0080e7          	jalr	960(ra) # 80000540 <panic>
      return -1;
    80001188:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118a:	60a6                	ld	ra,72(sp)
    8000118c:	6406                	ld	s0,64(sp)
    8000118e:	74e2                	ld	s1,56(sp)
    80001190:	7942                	ld	s2,48(sp)
    80001192:	79a2                	ld	s3,40(sp)
    80001194:	7a02                	ld	s4,32(sp)
    80001196:	6ae2                	ld	s5,24(sp)
    80001198:	6b42                	ld	s6,16(sp)
    8000119a:	6ba2                	ld	s7,8(sp)
    8000119c:	6161                	addi	sp,sp,80
    8000119e:	8082                	ret
  return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	b7e5                	j	8000118a <mappages+0x74>

00000000800011a4 <kvmmap>:
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e406                	sd	ra,8(sp)
    800011a8:	e022                	sd	s0,0(sp)
    800011aa:	0800                	addi	s0,sp,16
    800011ac:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011ae:	86ae                	mv	a3,a1
    800011b0:	85aa                	mv	a1,a0
    800011b2:	00008517          	auipc	a0,0x8
    800011b6:	e5e53503          	ld	a0,-418(a0) # 80009010 <kernel_pagetable>
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	f5c080e7          	jalr	-164(ra) # 80001116 <mappages>
    800011c2:	e509                	bnez	a0,800011cc <kvmmap+0x28>
}
    800011c4:	60a2                	ld	ra,8(sp)
    800011c6:	6402                	ld	s0,0(sp)
    800011c8:	0141                	addi	sp,sp,16
    800011ca:	8082                	ret
    panic("kvmmap");
    800011cc:	00007517          	auipc	a0,0x7
    800011d0:	f3c50513          	addi	a0,a0,-196 # 80008108 <digits+0xc8>
    800011d4:	fffff097          	auipc	ra,0xfffff
    800011d8:	36c080e7          	jalr	876(ra) # 80000540 <panic>

00000000800011dc <kvminit>:
{
    800011dc:	1101                	addi	sp,sp,-32
    800011de:	ec06                	sd	ra,24(sp)
    800011e0:	e822                	sd	s0,16(sp)
    800011e2:	e426                	sd	s1,8(sp)
    800011e4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	926080e7          	jalr	-1754(ra) # 80000b0c <kalloc>
    800011ee:	00008797          	auipc	a5,0x8
    800011f2:	e2a7b123          	sd	a0,-478(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800011f6:	6605                	lui	a2,0x1
    800011f8:	4581                	li	a1,0
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	afe080e7          	jalr	-1282(ra) # 80000cf8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001202:	4699                	li	a3,6
    80001204:	6605                	lui	a2,0x1
    80001206:	100005b7          	lui	a1,0x10000
    8000120a:	10000537          	lui	a0,0x10000
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f96080e7          	jalr	-106(ra) # 800011a4 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001216:	4699                	li	a3,6
    80001218:	6605                	lui	a2,0x1
    8000121a:	100015b7          	lui	a1,0x10001
    8000121e:	10001537          	lui	a0,0x10001
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f82080e7          	jalr	-126(ra) # 800011a4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6641                	lui	a2,0x10
    8000122e:	020005b7          	lui	a1,0x2000
    80001232:	02000537          	lui	a0,0x2000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f6e080e7          	jalr	-146(ra) # 800011a4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	00400637          	lui	a2,0x400
    80001244:	0c0005b7          	lui	a1,0xc000
    80001248:	0c000537          	lui	a0,0xc000
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f58080e7          	jalr	-168(ra) # 800011a4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001254:	00007497          	auipc	s1,0x7
    80001258:	dac48493          	addi	s1,s1,-596 # 80008000 <etext>
    8000125c:	46a9                	li	a3,10
    8000125e:	80007617          	auipc	a2,0x80007
    80001262:	da260613          	addi	a2,a2,-606 # 8000 <_entry-0x7fff8000>
    80001266:	4585                	li	a1,1
    80001268:	05fe                	slli	a1,a1,0x1f
    8000126a:	852e                	mv	a0,a1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f38080e7          	jalr	-200(ra) # 800011a4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	4645                	li	a2,17
    80001278:	066e                	slli	a2,a2,0x1b
    8000127a:	8e05                	sub	a2,a2,s1
    8000127c:	85a6                	mv	a1,s1
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f24080e7          	jalr	-220(ra) # 800011a4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001288:	46a9                	li	a3,10
    8000128a:	6605                	lui	a2,0x1
    8000128c:	00006597          	auipc	a1,0x6
    80001290:	d7458593          	addi	a1,a1,-652 # 80007000 <_trampoline>
    80001294:	04000537          	lui	a0,0x4000
    80001298:	157d                	addi	a0,a0,-1
    8000129a:	0532                	slli	a0,a0,0xc
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f08080e7          	jalr	-248(ra) # 800011a4 <kvmmap>
}
    800012a4:	60e2                	ld	ra,24(sp)
    800012a6:	6442                	ld	s0,16(sp)
    800012a8:	64a2                	ld	s1,8(sp)
    800012aa:	6105                	addi	sp,sp,32
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6b05                	lui	s6,0x1
    800012da:	0735e263          	bltu	a1,s3,8000133e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e1c50513          	addi	a0,a0,-484 # 80008110 <digits+0xd0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	244080e7          	jalr	580(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e2450513          	addi	a0,a0,-476 # 80008128 <digits+0xe8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	234080e7          	jalr	564(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e2450513          	addi	a0,a0,-476 # 80008138 <digits+0xf8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	224080e7          	jalr	548(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e2c50513          	addi	a0,a0,-468 # 80008150 <digits+0x110>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	214080e7          	jalr	532(ra) # 80000540 <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fb3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	c8c080e7          	jalr	-884(ra) # 80000fd0 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d95d                	beqz	a0,80001304 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dfdd                	beqz	a5,80001314 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fd7784e3          	beq	a5,s7,80001324 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	6a8080e7          	jalr	1704(ra) # 80000a10 <kfree>
    80001370:	b7d1                	j	80001334 <uvmunmap+0x86>

0000000080001372 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001372:	1101                	addi	sp,sp,-32
    80001374:	ec06                	sd	ra,24(sp)
    80001376:	e822                	sd	s0,16(sp)
    80001378:	e426                	sd	s1,8(sp)
    8000137a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	790080e7          	jalr	1936(ra) # 80000b0c <kalloc>
    80001384:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001386:	c519                	beqz	a0,80001394 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001388:	6605                	lui	a2,0x1
    8000138a:	4581                	li	a1,0
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	96c080e7          	jalr	-1684(ra) # 80000cf8 <memset>
  return pagetable;
}
    80001394:	8526                	mv	a0,s1
    80001396:	60e2                	ld	ra,24(sp)
    80001398:	6442                	ld	s0,16(sp)
    8000139a:	64a2                	ld	s1,8(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a0:	7179                	addi	sp,sp,-48
    800013a2:	f406                	sd	ra,40(sp)
    800013a4:	f022                	sd	s0,32(sp)
    800013a6:	ec26                	sd	s1,24(sp)
    800013a8:	e84a                	sd	s2,16(sp)
    800013aa:	e44e                	sd	s3,8(sp)
    800013ac:	e052                	sd	s4,0(sp)
    800013ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b0:	6785                	lui	a5,0x1
    800013b2:	04f67863          	bgeu	a2,a5,80001402 <uvminit+0x62>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	750080e7          	jalr	1872(ra) # 80000b0c <kalloc>
    800013c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	92e080e7          	jalr	-1746(ra) # 80000cf8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d2:	4779                	li	a4,30
    800013d4:	86ca                	mv	a3,s2
    800013d6:	6605                	lui	a2,0x1
    800013d8:	4581                	li	a1,0
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	d3a080e7          	jalr	-710(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    800013e4:	8626                	mv	a2,s1
    800013e6:	85ce                	mv	a1,s3
    800013e8:	854a                	mv	a0,s2
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	96a080e7          	jalr	-1686(ra) # 80000d54 <memmove>
}
    800013f2:	70a2                	ld	ra,40(sp)
    800013f4:	7402                	ld	s0,32(sp)
    800013f6:	64e2                	ld	s1,24(sp)
    800013f8:	6942                	ld	s2,16(sp)
    800013fa:	69a2                	ld	s3,8(sp)
    800013fc:	6a02                	ld	s4,0(sp)
    800013fe:	6145                	addi	sp,sp,48
    80001400:	8082                	ret
    panic("inituvm: more than a page");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d6650513          	addi	a0,a0,-666 # 80008168 <digits+0x128>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>

0000000080001412 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001412:	1101                	addi	sp,sp,-32
    80001414:	ec06                	sd	ra,24(sp)
    80001416:	e822                	sd	s0,16(sp)
    80001418:	e426                	sd	s1,8(sp)
    8000141a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000141e:	00b67d63          	bgeu	a2,a1,80001438 <uvmdealloc+0x26>
    80001422:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	addi	a5,a5,-1
    80001428:	00f60733          	add	a4,a2,a5
    8000142c:	767d                	lui	a2,0xfffff
    8000142e:	8f71                	and	a4,a4,a2
    80001430:	97ae                	add	a5,a5,a1
    80001432:	8ff1                	and	a5,a5,a2
    80001434:	00f76863          	bltu	a4,a5,80001444 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001444:	8f99                	sub	a5,a5,a4
    80001446:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001448:	4685                	li	a3,1
    8000144a:	0007861b          	sext.w	a2,a5
    8000144e:	85ba                	mv	a1,a4
    80001450:	00000097          	auipc	ra,0x0
    80001454:	e5e080e7          	jalr	-418(ra) # 800012ae <uvmunmap>
    80001458:	b7c5                	j	80001438 <uvmdealloc+0x26>

000000008000145a <uvmalloc>:
  if(newsz < oldsz)
    8000145a:	0ab66163          	bltu	a2,a1,800014fc <uvmalloc+0xa2>
{
    8000145e:	7139                	addi	sp,sp,-64
    80001460:	fc06                	sd	ra,56(sp)
    80001462:	f822                	sd	s0,48(sp)
    80001464:	f426                	sd	s1,40(sp)
    80001466:	f04a                	sd	s2,32(sp)
    80001468:	ec4e                	sd	s3,24(sp)
    8000146a:	e852                	sd	s4,16(sp)
    8000146c:	e456                	sd	s5,8(sp)
    8000146e:	0080                	addi	s0,sp,64
    80001470:	8aaa                	mv	s5,a0
    80001472:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001474:	6985                	lui	s3,0x1
    80001476:	19fd                	addi	s3,s3,-1
    80001478:	95ce                	add	a1,a1,s3
    8000147a:	79fd                	lui	s3,0xfffff
    8000147c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001480:	08c9f063          	bgeu	s3,a2,80001500 <uvmalloc+0xa6>
    80001484:	894e                	mv	s2,s3
    mem = kalloc();
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	686080e7          	jalr	1670(ra) # 80000b0c <kalloc>
    8000148e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001490:	c51d                	beqz	a0,800014be <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001492:	6605                	lui	a2,0x1
    80001494:	4581                	li	a1,0
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	862080e7          	jalr	-1950(ra) # 80000cf8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000149e:	4779                	li	a4,30
    800014a0:	86a6                	mv	a3,s1
    800014a2:	6605                	lui	a2,0x1
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	c6e080e7          	jalr	-914(ra) # 80001116 <mappages>
    800014b0:	e905                	bnez	a0,800014e0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b2:	6785                	lui	a5,0x1
    800014b4:	993e                	add	s2,s2,a5
    800014b6:	fd4968e3          	bltu	s2,s4,80001486 <uvmalloc+0x2c>
  return newsz;
    800014ba:	8552                	mv	a0,s4
    800014bc:	a809                	j	800014ce <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014be:	864e                	mv	a2,s3
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8556                	mv	a0,s5
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	f4e080e7          	jalr	-178(ra) # 80001412 <uvmdealloc>
      return 0;
    800014cc:	4501                	li	a0,0
}
    800014ce:	70e2                	ld	ra,56(sp)
    800014d0:	7442                	ld	s0,48(sp)
    800014d2:	74a2                	ld	s1,40(sp)
    800014d4:	7902                	ld	s2,32(sp)
    800014d6:	69e2                	ld	s3,24(sp)
    800014d8:	6a42                	ld	s4,16(sp)
    800014da:	6aa2                	ld	s5,8(sp)
    800014dc:	6121                	addi	sp,sp,64
    800014de:	8082                	ret
      kfree(mem);
    800014e0:	8526                	mv	a0,s1
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	52e080e7          	jalr	1326(ra) # 80000a10 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f22080e7          	jalr	-222(ra) # 80001412 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	bfd1                	j	800014ce <uvmalloc+0x74>
    return oldsz;
    800014fc:	852e                	mv	a0,a1
}
    800014fe:	8082                	ret
  return newsz;
    80001500:	8532                	mv	a0,a2
    80001502:	b7f1                	j	800014ce <uvmalloc+0x74>

0000000080001504 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001504:	7179                	addi	sp,sp,-48
    80001506:	f406                	sd	ra,40(sp)
    80001508:	f022                	sd	s0,32(sp)
    8000150a:	ec26                	sd	s1,24(sp)
    8000150c:	e84a                	sd	s2,16(sp)
    8000150e:	e44e                	sd	s3,8(sp)
    80001510:	e052                	sd	s4,0(sp)
    80001512:	1800                	addi	s0,sp,48
    80001514:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001516:	84aa                	mv	s1,a0
    80001518:	6905                	lui	s2,0x1
    8000151a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151c:	4985                	li	s3,1
    8000151e:	a821                	j	80001536 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001520:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001522:	0532                	slli	a0,a0,0xc
    80001524:	00000097          	auipc	ra,0x0
    80001528:	fe0080e7          	jalr	-32(ra) # 80001504 <freewalk>
      pagetable[i] = 0;
    8000152c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001530:	04a1                	addi	s1,s1,8
    80001532:	03248163          	beq	s1,s2,80001554 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001536:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001538:	00f57793          	andi	a5,a0,15
    8000153c:	ff3782e3          	beq	a5,s3,80001520 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001540:	8905                	andi	a0,a0,1
    80001542:	d57d                	beqz	a0,80001530 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001544:	00007517          	auipc	a0,0x7
    80001548:	c4450513          	addi	a0,a0,-956 # 80008188 <digits+0x148>
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001554:	8552                	mv	a0,s4
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	4ba080e7          	jalr	1210(ra) # 80000a10 <kfree>
}
    8000155e:	70a2                	ld	ra,40(sp)
    80001560:	7402                	ld	s0,32(sp)
    80001562:	64e2                	ld	s1,24(sp)
    80001564:	6942                	ld	s2,16(sp)
    80001566:	69a2                	ld	s3,8(sp)
    80001568:	6a02                	ld	s4,0(sp)
    8000156a:	6145                	addi	sp,sp,48
    8000156c:	8082                	ret

000000008000156e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000156e:	1101                	addi	sp,sp,-32
    80001570:	ec06                	sd	ra,24(sp)
    80001572:	e822                	sd	s0,16(sp)
    80001574:	e426                	sd	s1,8(sp)
    80001576:	1000                	addi	s0,sp,32
    80001578:	84aa                	mv	s1,a0
  if(sz > 0)
    8000157a:	e999                	bnez	a1,80001590 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000157c:	8526                	mv	a0,s1
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	f86080e7          	jalr	-122(ra) # 80001504 <freewalk>
}
    80001586:	60e2                	ld	ra,24(sp)
    80001588:	6442                	ld	s0,16(sp)
    8000158a:	64a2                	ld	s1,8(sp)
    8000158c:	6105                	addi	sp,sp,32
    8000158e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001590:	6605                	lui	a2,0x1
    80001592:	167d                	addi	a2,a2,-1
    80001594:	962e                	add	a2,a2,a1
    80001596:	4685                	li	a3,1
    80001598:	8231                	srli	a2,a2,0xc
    8000159a:	4581                	li	a1,0
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	d12080e7          	jalr	-750(ra) # 800012ae <uvmunmap>
    800015a4:	bfe1                	j	8000157c <uvmfree+0xe>

00000000800015a6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a6:	c679                	beqz	a2,80001674 <uvmcopy+0xce>
{
    800015a8:	715d                	addi	sp,sp,-80
    800015aa:	e486                	sd	ra,72(sp)
    800015ac:	e0a2                	sd	s0,64(sp)
    800015ae:	fc26                	sd	s1,56(sp)
    800015b0:	f84a                	sd	s2,48(sp)
    800015b2:	f44e                	sd	s3,40(sp)
    800015b4:	f052                	sd	s4,32(sp)
    800015b6:	ec56                	sd	s5,24(sp)
    800015b8:	e85a                	sd	s6,16(sp)
    800015ba:	e45e                	sd	s7,8(sp)
    800015bc:	0880                	addi	s0,sp,80
    800015be:	8b2a                	mv	s6,a0
    800015c0:	8aae                	mv	s5,a1
    800015c2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c6:	4601                	li	a2,0
    800015c8:	85ce                	mv	a1,s3
    800015ca:	855a                	mv	a0,s6
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	a04080e7          	jalr	-1532(ra) # 80000fd0 <walk>
    800015d4:	c531                	beqz	a0,80001620 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d6:	6118                	ld	a4,0(a0)
    800015d8:	00177793          	andi	a5,a4,1
    800015dc:	cbb1                	beqz	a5,80001630 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015de:	00a75593          	srli	a1,a4,0xa
    800015e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	522080e7          	jalr	1314(ra) # 80000b0c <kalloc>
    800015f2:	892a                	mv	s2,a0
    800015f4:	c939                	beqz	a0,8000164a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85de                	mv	a1,s7
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	75a080e7          	jalr	1882(ra) # 80000d54 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001602:	8726                	mv	a4,s1
    80001604:	86ca                	mv	a3,s2
    80001606:	6605                	lui	a2,0x1
    80001608:	85ce                	mv	a1,s3
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	b0a080e7          	jalr	-1270(ra) # 80001116 <mappages>
    80001614:	e515                	bnez	a0,80001640 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001616:	6785                	lui	a5,0x1
    80001618:	99be                	add	s3,s3,a5
    8000161a:	fb49e6e3          	bltu	s3,s4,800015c6 <uvmcopy+0x20>
    8000161e:	a081                	j	8000165e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b7850513          	addi	a0,a0,-1160 # 80008198 <digits+0x158>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f18080e7          	jalr	-232(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001630:	00007517          	auipc	a0,0x7
    80001634:	b8850513          	addi	a0,a0,-1144 # 800081b8 <digits+0x178>
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	f08080e7          	jalr	-248(ra) # 80000540 <panic>
      kfree(mem);
    80001640:	854a                	mv	a0,s2
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	3ce080e7          	jalr	974(ra) # 80000a10 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000164a:	4685                	li	a3,1
    8000164c:	00c9d613          	srli	a2,s3,0xc
    80001650:	4581                	li	a1,0
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	c5a080e7          	jalr	-934(ra) # 800012ae <uvmunmap>
  return -1;
    8000165c:	557d                	li	a0,-1
}
    8000165e:	60a6                	ld	ra,72(sp)
    80001660:	6406                	ld	s0,64(sp)
    80001662:	74e2                	ld	s1,56(sp)
    80001664:	7942                	ld	s2,48(sp)
    80001666:	79a2                	ld	s3,40(sp)
    80001668:	7a02                	ld	s4,32(sp)
    8000166a:	6ae2                	ld	s5,24(sp)
    8000166c:	6b42                	ld	s6,16(sp)
    8000166e:	6ba2                	ld	s7,8(sp)
    80001670:	6161                	addi	sp,sp,80
    80001672:	8082                	ret
  return 0;
    80001674:	4501                	li	a0,0
}
    80001676:	8082                	ret

0000000080001678 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001678:	1141                	addi	sp,sp,-16
    8000167a:	e406                	sd	ra,8(sp)
    8000167c:	e022                	sd	s0,0(sp)
    8000167e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001680:	4601                	li	a2,0
    80001682:	00000097          	auipc	ra,0x0
    80001686:	94e080e7          	jalr	-1714(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000168a:	c901                	beqz	a0,8000169a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168c:	611c                	ld	a5,0(a0)
    8000168e:	9bbd                	andi	a5,a5,-17
    80001690:	e11c                	sd	a5,0(a0)
}
    80001692:	60a2                	ld	ra,8(sp)
    80001694:	6402                	ld	s0,0(sp)
    80001696:	0141                	addi	sp,sp,16
    80001698:	8082                	ret
    panic("uvmclear");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	b3e50513          	addi	a0,a0,-1218 # 800081d8 <digits+0x198>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	e9e080e7          	jalr	-354(ra) # 80000540 <panic>

00000000800016aa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016aa:	c6bd                	beqz	a3,80001718 <copyout+0x6e>
{
    800016ac:	715d                	addi	sp,sp,-80
    800016ae:	e486                	sd	ra,72(sp)
    800016b0:	e0a2                	sd	s0,64(sp)
    800016b2:	fc26                	sd	s1,56(sp)
    800016b4:	f84a                	sd	s2,48(sp)
    800016b6:	f44e                	sd	s3,40(sp)
    800016b8:	f052                	sd	s4,32(sp)
    800016ba:	ec56                	sd	s5,24(sp)
    800016bc:	e85a                	sd	s6,16(sp)
    800016be:	e45e                	sd	s7,8(sp)
    800016c0:	e062                	sd	s8,0(sp)
    800016c2:	0880                	addi	s0,sp,80
    800016c4:	8b2a                	mv	s6,a0
    800016c6:	8c2e                	mv	s8,a1
    800016c8:	8a32                	mv	s4,a2
    800016ca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016cc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ce:	6a85                	lui	s5,0x1
    800016d0:	a015                	j	800016f4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d2:	9562                	add	a0,a0,s8
    800016d4:	0004861b          	sext.w	a2,s1
    800016d8:	85d2                	mv	a1,s4
    800016da:	41250533          	sub	a0,a0,s2
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	676080e7          	jalr	1654(ra) # 80000d54 <memmove>

    len -= n;
    800016e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f0:	02098263          	beqz	s3,80001714 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f8:	85ca                	mv	a1,s2
    800016fa:	855a                	mv	a0,s6
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	97a080e7          	jalr	-1670(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001704:	cd01                	beqz	a0,8000171c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001706:	418904b3          	sub	s1,s2,s8
    8000170a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170c:	fc99f3e3          	bgeu	s3,s1,800016d2 <copyout+0x28>
    80001710:	84ce                	mv	s1,s3
    80001712:	b7c1                	j	800016d2 <copyout+0x28>
  }
  return 0;
    80001714:	4501                	li	a0,0
    80001716:	a021                	j	8000171e <copyout+0x74>
    80001718:	4501                	li	a0,0
}
    8000171a:	8082                	ret
      return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6c02                	ld	s8,0(sp)
    80001732:	6161                	addi	sp,sp,80
    80001734:	8082                	ret

0000000080001736 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	caa5                	beqz	a3,800017a6 <copyin+0x70>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8a2e                	mv	s4,a1
    80001754:	8c32                	mv	s8,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001758:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175a:	6a85                	lui	s5,0x1
    8000175c:	a01d                	j	80001782 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175e:	018505b3          	add	a1,a0,s8
    80001762:	0004861b          	sext.w	a2,s1
    80001766:	412585b3          	sub	a1,a1,s2
    8000176a:	8552                	mv	a0,s4
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	5e8080e7          	jalr	1512(ra) # 80000d54 <memmove>

    len -= n;
    80001774:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001778:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177e:	02098263          	beqz	s3,800017a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001782:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001786:	85ca                	mv	a1,s2
    80001788:	855a                	mv	a0,s6
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	8ec080e7          	jalr	-1812(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001792:	cd01                	beqz	a0,800017aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001794:	418904b3          	sub	s1,s2,s8
    80001798:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179a:	fc99f2e3          	bgeu	s3,s1,8000175e <copyin+0x28>
    8000179e:	84ce                	mv	s1,s3
    800017a0:	bf7d                	j	8000175e <copyin+0x28>
  }
  return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	a021                	j	800017ac <copyin+0x76>
    800017a6:	4501                	li	a0,0
}
    800017a8:	8082                	ret
      return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6c02                	ld	s8,0(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret

00000000800017c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c4:	c6c5                	beqz	a3,8000186c <copyinstr+0xa8>
{
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8a2a                	mv	s4,a0
    800017de:	8b2e                	mv	s6,a1
    800017e0:	8bb2                	mv	s7,a2
    800017e2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6985                	lui	s3,0x1
    800017e8:	a035                	j	80001814 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f0:	0017b793          	seqz	a5,a5
    800017f4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f8:	60a6                	ld	ra,72(sp)
    800017fa:	6406                	ld	s0,64(sp)
    800017fc:	74e2                	ld	s1,56(sp)
    800017fe:	7942                	ld	s2,48(sp)
    80001800:	79a2                	ld	s3,40(sp)
    80001802:	7a02                	ld	s4,32(sp)
    80001804:	6ae2                	ld	s5,24(sp)
    80001806:	6b42                	ld	s6,16(sp)
    80001808:	6ba2                	ld	s7,8(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000180e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001812:	c8a9                	beqz	s1,80001864 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001814:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ca                	mv	a1,s2
    8000181a:	8552                	mv	a0,s4
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	85a080e7          	jalr	-1958(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001824:	c131                	beqz	a0,80001868 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001826:	41790833          	sub	a6,s2,s7
    8000182a:	984e                	add	a6,a6,s3
    if(n > max)
    8000182c:	0104f363          	bgeu	s1,a6,80001832 <copyinstr+0x6e>
    80001830:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001832:	955e                	add	a0,a0,s7
    80001834:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001838:	fc080be3          	beqz	a6,8000180e <copyinstr+0x4a>
    8000183c:	985a                	add	a6,a6,s6
    8000183e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001840:	41650633          	sub	a2,a0,s6
    80001844:	14fd                	addi	s1,s1,-1
    80001846:	9b26                	add	s6,s6,s1
    80001848:	00f60733          	add	a4,a2,a5
    8000184c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    80001850:	df49                	beqz	a4,800017ea <copyinstr+0x26>
        *dst = *p;
    80001852:	00e78023          	sb	a4,0(a5)
      --max;
    80001856:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185c:	ff0796e3          	bne	a5,a6,80001848 <copyinstr+0x84>
      dst++;
    80001860:	8b42                	mv	s6,a6
    80001862:	b775                	j	8000180e <copyinstr+0x4a>
    80001864:	4781                	li	a5,0
    80001866:	b769                	j	800017f0 <copyinstr+0x2c>
      return -1;
    80001868:	557d                	li	a0,-1
    8000186a:	b779                	j	800017f8 <copyinstr+0x34>
  int got_null = 0;
    8000186c:	4781                	li	a5,0
  if(got_null){
    8000186e:	0017b793          	seqz	a5,a5
    80001872:	40f00533          	neg	a0,a5
}
    80001876:	8082                	ret

0000000080001878 <getportion>:

extern char trampoline[]; // trampoline.S

// Calculate time portion
void getportion(struct proc *p)
{
    80001878:	1141                	addi	sp,sp,-16
    8000187a:	e422                	sd	s0,8(sp)
    8000187c:	0800                	addi	s0,sp,16
  // where(queue) the job is finished
  int endqueue = p->priority;

  // wrap up the timer of the queue where the job is finished
  p->Qinterval[endqueue] = ticks - p->Qinterval[endqueue];
    8000187e:	18052783          	lw	a5,384(a0)
    80001882:	078a                	slli	a5,a5,0x2
    80001884:	97aa                	add	a5,a5,a0
    80001886:	1747a683          	lw	a3,372(a5)
    8000188a:	00007717          	auipc	a4,0x7
    8000188e:	79672703          	lw	a4,1942(a4) # 80009020 <ticks>
    80001892:	9f15                	subw	a4,a4,a3
    80001894:	16e7aa23          	sw	a4,372(a5)
  p->Qtime[endqueue] += p->Qinterval[endqueue];
    80001898:	1687a683          	lw	a3,360(a5)
    8000189c:	9f35                	addw	a4,a4,a3
    8000189e:	16e7a423          	sw	a4,360(a5)

    // get total execution time
    int total = p->Qtime[2] + p->Qtime[1] + p->Qtime[0];
    800018a2:	17052783          	lw	a5,368(a0)
    800018a6:	16c52683          	lw	a3,364(a0)
    800018aa:	00d7873b          	addw	a4,a5,a3
    800018ae:	16852583          	lw	a1,360(a0)
    800018b2:	9db9                	addw	a1,a1,a4

    // get portion of each queue
    p->Qtime[2] = p->Qtime[2] * 100 / total;
    800018b4:	06400613          	li	a2,100
    800018b8:	02f607bb          	mulw	a5,a2,a5
    800018bc:	02b7c7bb          	divw	a5,a5,a1
    800018c0:	16f52823          	sw	a5,368(a0)
    p->Qtime[1] = p->Qtime[1] * 100 / total;
    800018c4:	02d6073b          	mulw	a4,a2,a3
    800018c8:	02b7473b          	divw	a4,a4,a1
    800018cc:	16e52623          	sw	a4,364(a0)
    p->Qtime[0] = 100 - (p->Qtime[1] + p->Qtime[2]);
    800018d0:	9fb9                	addw	a5,a5,a4
    800018d2:	40f607bb          	subw	a5,a2,a5
    800018d6:	16f52423          	sw	a5,360(a0)

}
    800018da:	6422                	ld	s0,8(sp)
    800018dc:	0141                	addi	sp,sp,16
    800018de:	8082                	ret

00000000800018e0 <findproc>:


// find where 'obj' process resides in
// the Q[priority] queue
int findproc(struct proc *obj, int priority)
{
    800018e0:	1141                	addi	sp,sp,-16
    800018e2:	e422                	sd	s0,8(sp)
    800018e4:	0800                	addi	s0,sp,16
    int index = 0;
    while (1)
    {
        if (Q[priority][index] == obj)
    800018e6:	00959713          	slli	a4,a1,0x9
    800018ea:	00010797          	auipc	a5,0x10
    800018ee:	06678793          	addi	a5,a5,102 # 80011950 <Q>
    800018f2:	97ba                	add	a5,a5,a4
    800018f4:	639c                	ld	a5,0(a5)
    800018f6:	02f50263          	beq	a0,a5,8000191a <findproc+0x3a>
    800018fa:	86aa                	mv	a3,a0
    800018fc:	00010797          	auipc	a5,0x10
    80001900:	05c78793          	addi	a5,a5,92 # 80011958 <Q+0x8>
    80001904:	97ba                	add	a5,a5,a4
    int index = 0;
    80001906:	4501                	li	a0,0
            break;
        index++;
    80001908:	2505                	addiw	a0,a0,1
        if (Q[priority][index] == obj)
    8000190a:	07a1                	addi	a5,a5,8
    8000190c:	ff87b703          	ld	a4,-8(a5)
    80001910:	fed71ce3          	bne	a4,a3,80001908 <findproc+0x28>
    }
    return index;
}
    80001914:	6422                	ld	s0,8(sp)
    80001916:	0141                	addi	sp,sp,16
    80001918:	8082                	ret
    int index = 0;
    8000191a:	4501                	li	a0,0
    8000191c:	bfe5                	j	80001914 <findproc+0x34>

000000008000191e <movequeue>:

// handle process change
void movequeue(struct proc *obj, int priority, int opt)
{
    8000191e:	7179                	addi	sp,sp,-48
    80001920:	f406                	sd	ra,40(sp)
    80001922:	f022                	sd	s0,32(sp)
    80001924:	ec26                	sd	s1,24(sp)
    80001926:	e84a                	sd	s2,16(sp)
    80001928:	e44e                	sd	s3,8(sp)
    8000192a:	1800                	addi	s0,sp,48
    8000192c:	84aa                	mv	s1,a0
    8000192e:	892e                	mv	s2,a1
    // INSERT means pushing process to empty process
    // so doesn't need to handle delete operation.
    if (opt != INSERT)
    80001930:	4785                	li	a5,1
    80001932:	06f60163          	beq	a2,a5,80001994 <movequeue+0x76>
    80001936:	89b2                	mv	s3,a2
    {
        // delete the obj process from queue where it was in
        // and pull up the processes behind
        // obj process is in Q[obj.priority][pos]
        int pos = findproc(obj, obj->priority);
    80001938:	18052583          	lw	a1,384(a0)
    8000193c:	00000097          	auipc	ra,0x0
    80001940:	fa4080e7          	jalr	-92(ra) # 800018e0 <findproc>
        for (int i = pos; i < NPROC - 1; i++)
    80001944:	03e00793          	li	a5,62
    80001948:	02a7c863          	blt	a5,a0,80001978 <movequeue+0x5a>
            Q[obj->priority][i] = Q[obj->priority][i + 1];
    8000194c:	00010697          	auipc	a3,0x10
    80001950:	00468693          	addi	a3,a3,4 # 80011950 <Q>
        for (int i = pos; i < NPROC - 1; i++)
    80001954:	03f00593          	li	a1,63
            Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001958:	1804a783          	lw	a5,384(s1)
    8000195c:	862a                	mv	a2,a0
    8000195e:	2505                	addiw	a0,a0,1
    80001960:	079a                	slli	a5,a5,0x6
    80001962:	00a78733          	add	a4,a5,a0
    80001966:	070e                	slli	a4,a4,0x3
    80001968:	9736                	add	a4,a4,a3
    8000196a:	6318                	ld	a4,0(a4)
    8000196c:	97b2                	add	a5,a5,a2
    8000196e:	078e                	slli	a5,a5,0x3
    80001970:	97b6                	add	a5,a5,a3
    80001972:	e398                	sd	a4,0(a5)
        for (int i = pos; i < NPROC - 1; i++)
    80001974:	feb512e3          	bne	a0,a1,80001958 <movequeue+0x3a>
        Q[obj->priority][NPROC - 1] = 0;
    80001978:	1804a783          	lw	a5,384(s1)
    8000197c:	00979713          	slli	a4,a5,0x9
    80001980:	00010797          	auipc	a5,0x10
    80001984:	fd078793          	addi	a5,a5,-48 # 80011950 <Q>
    80001988:	97ba                	add	a5,a5,a4
    8000198a:	1e07bc23          	sd	zero,504(a5)
    }

    // DELETE means just delete the process from all Qs,
    // so doesn't have to handle inserting process to another queue.
    if (opt != DELETE)
    8000198e:	4789                	li	a5,2
    80001990:	02f98463          	beq	s3,a5,800019b8 <movequeue+0x9a>
    {
        // insert obj process in another queue. insertback
        // endstart indicates the position right after the tail
        // which can be found by finding NULL process in the queue
        int endstart = findproc(0, priority);
    80001994:	85ca                	mv	a1,s2
    80001996:	4501                	li	a0,0
    80001998:	00000097          	auipc	ra,0x0
    8000199c:	f48080e7          	jalr	-184(ra) # 800018e0 <findproc>
        Q[priority][endstart] = obj;
    800019a0:	00691793          	slli	a5,s2,0x6
    800019a4:	97aa                	add	a5,a5,a0
    800019a6:	078e                	slli	a5,a5,0x3
    800019a8:	00010717          	auipc	a4,0x10
    800019ac:	fa870713          	addi	a4,a4,-88 # 80011950 <Q>
    800019b0:	97ba                	add	a5,a5,a4
    800019b2:	e384                	sd	s1,0(a5)
        obj->priority = priority;
    800019b4:	1924a023          	sw	s2,384(s1)
    }
}
    800019b8:	70a2                	ld	ra,40(sp)
    800019ba:	7402                	ld	s0,32(sp)
    800019bc:	64e2                	ld	s1,24(sp)
    800019be:	6942                	ld	s2,16(sp)
    800019c0:	69a2                	ld	s3,8(sp)
    800019c2:	6145                	addi	sp,sp,48
    800019c4:	8082                	ret

00000000800019c6 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
    800019d0:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	1b0080e7          	jalr	432(ra) # 80000b82 <holding>
    800019da:	c909                	beqz	a0,800019ec <wakeup1+0x26>
        panic("wakeup1");
    if (p->chan == p && p->state == SLEEPING)
    800019dc:	749c                	ld	a5,40(s1)
    800019de:	00978f63          	beq	a5,s1,800019fc <wakeup1+0x36>
        // start Q2 timer, end Q0 timer
        p->Qinterval[2] = ticks;
        p->Qinterval[0] = ticks - p->Qinterval[0];
        p->Qtime[0] += p->Qinterval[0];
    }
}
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6105                	addi	sp,sp,32
    800019ea:	8082                	ret
        panic("wakeup1");
    800019ec:	00006517          	auipc	a0,0x6
    800019f0:	7fc50513          	addi	a0,a0,2044 # 800081e8 <digits+0x1a8>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	b4c080e7          	jalr	-1204(ra) # 80000540 <panic>
    if (p->chan == p && p->state == SLEEPING)
    800019fc:	4c98                	lw	a4,24(s1)
    800019fe:	4785                	li	a5,1
    80001a00:	fef711e3          	bne	a4,a5,800019e2 <wakeup1+0x1c>
        p->state = RUNNABLE;
    80001a04:	4789                	li	a5,2
    80001a06:	cc9c                	sw	a5,24(s1)
        movequeue(p, 2, MOVE);
    80001a08:	4601                	li	a2,0
    80001a0a:	4589                	li	a1,2
    80001a0c:	8526                	mv	a0,s1
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	f10080e7          	jalr	-240(ra) # 8000191e <movequeue>
        p->Qinterval[2] = ticks;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	60a7a783          	lw	a5,1546(a5) # 80009020 <ticks>
    80001a1e:	16f4ae23          	sw	a5,380(s1)
        p->Qinterval[0] = ticks - p->Qinterval[0];
    80001a22:	1744a703          	lw	a4,372(s1)
    80001a26:	9f99                	subw	a5,a5,a4
    80001a28:	16f4aa23          	sw	a5,372(s1)
        p->Qtime[0] += p->Qinterval[0];
    80001a2c:	1684a703          	lw	a4,360(s1)
    80001a30:	9fb9                	addw	a5,a5,a4
    80001a32:	16f4a423          	sw	a5,360(s1)
}
    80001a36:	b775                	j	800019e2 <wakeup1+0x1c>

0000000080001a38 <procinit>:
{
    80001a38:	715d                	addi	sp,sp,-80
    80001a3a:	e486                	sd	ra,72(sp)
    80001a3c:	e0a2                	sd	s0,64(sp)
    80001a3e:	fc26                	sd	s1,56(sp)
    80001a40:	f84a                	sd	s2,48(sp)
    80001a42:	f44e                	sd	s3,40(sp)
    80001a44:	f052                	sd	s4,32(sp)
    80001a46:	ec56                	sd	s5,24(sp)
    80001a48:	e85a                	sd	s6,16(sp)
    80001a4a:	e45e                	sd	s7,8(sp)
    80001a4c:	0880                	addi	s0,sp,80
    initlock(&pid_lock, "nextpid");
    80001a4e:	00006597          	auipc	a1,0x6
    80001a52:	7a258593          	addi	a1,a1,1954 # 800081f0 <digits+0x1b0>
    80001a56:	00010517          	auipc	a0,0x10
    80001a5a:	4fa50513          	addi	a0,a0,1274 # 80011f50 <pid_lock>
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	10e080e7          	jalr	270(ra) # 80000b6c <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a66:	00011917          	auipc	s2,0x11
    80001a6a:	90290913          	addi	s2,s2,-1790 # 80012368 <proc>
        initlock(&p->lock, "proc");
    80001a6e:	00006b97          	auipc	s7,0x6
    80001a72:	78ab8b93          	addi	s7,s7,1930 # 800081f8 <digits+0x1b8>
        uint64 va = KSTACK((int)(p - proc));
    80001a76:	8b4a                	mv	s6,s2
    80001a78:	00006a97          	auipc	s5,0x6
    80001a7c:	588a8a93          	addi	s5,s5,1416 # 80008000 <etext>
    80001a80:	040009b7          	lui	s3,0x4000
    80001a84:	19fd                	addi	s3,s3,-1
    80001a86:	09b2                	slli	s3,s3,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a88:	00017a17          	auipc	s4,0x17
    80001a8c:	ae0a0a13          	addi	s4,s4,-1312 # 80018568 <tickslock>
        initlock(&p->lock, "proc");
    80001a90:	85de                	mv	a1,s7
    80001a92:	854a                	mv	a0,s2
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	0d8080e7          	jalr	216(ra) # 80000b6c <initlock>
        char *pa = kalloc();
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	070080e7          	jalr	112(ra) # 80000b0c <kalloc>
    80001aa4:	85aa                	mv	a1,a0
        if (pa == 0)
    80001aa6:	c929                	beqz	a0,80001af8 <procinit+0xc0>
        uint64 va = KSTACK((int)(p - proc));
    80001aa8:	416904b3          	sub	s1,s2,s6
    80001aac:	848d                	srai	s1,s1,0x3
    80001aae:	000ab783          	ld	a5,0(s5)
    80001ab2:	02f484b3          	mul	s1,s1,a5
    80001ab6:	2485                	addiw	s1,s1,1
    80001ab8:	00d4949b          	slliw	s1,s1,0xd
    80001abc:	409984b3          	sub	s1,s3,s1
        kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ac0:	4699                	li	a3,6
    80001ac2:	6605                	lui	a2,0x1
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	6de080e7          	jalr	1758(ra) # 800011a4 <kvmmap>
        p->kstack = va;
    80001ace:	04993023          	sd	s1,64(s2)
    for (p = proc; p < &proc[NPROC]; p++)
    80001ad2:	18890913          	addi	s2,s2,392
    80001ad6:	fb491de3          	bne	s2,s4,80001a90 <procinit+0x58>
    kvminithart();
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	4d2080e7          	jalr	1234(ra) # 80000fac <kvminithart>
}
    80001ae2:	60a6                	ld	ra,72(sp)
    80001ae4:	6406                	ld	s0,64(sp)
    80001ae6:	74e2                	ld	s1,56(sp)
    80001ae8:	7942                	ld	s2,48(sp)
    80001aea:	79a2                	ld	s3,40(sp)
    80001aec:	7a02                	ld	s4,32(sp)
    80001aee:	6ae2                	ld	s5,24(sp)
    80001af0:	6b42                	ld	s6,16(sp)
    80001af2:	6ba2                	ld	s7,8(sp)
    80001af4:	6161                	addi	sp,sp,80
    80001af6:	8082                	ret
            panic("kalloc");
    80001af8:	00006517          	auipc	a0,0x6
    80001afc:	70850513          	addi	a0,a0,1800 # 80008200 <digits+0x1c0>
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	a40080e7          	jalr	-1472(ra) # 80000540 <panic>

0000000080001b08 <cpuid>:
{
    80001b08:	1141                	addi	sp,sp,-16
    80001b0a:	e422                	sd	s0,8(sp)
    80001b0c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b0e:	8512                	mv	a0,tp
}
    80001b10:	2501                	sext.w	a0,a0
    80001b12:	6422                	ld	s0,8(sp)
    80001b14:	0141                	addi	sp,sp,16
    80001b16:	8082                	ret

0000000080001b18 <mycpu>:
{
    80001b18:	1141                	addi	sp,sp,-16
    80001b1a:	e422                	sd	s0,8(sp)
    80001b1c:	0800                	addi	s0,sp,16
    80001b1e:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001b20:	2781                	sext.w	a5,a5
    80001b22:	079e                	slli	a5,a5,0x7
}
    80001b24:	00010517          	auipc	a0,0x10
    80001b28:	44450513          	addi	a0,a0,1092 # 80011f68 <cpus>
    80001b2c:	953e                	add	a0,a0,a5
    80001b2e:	6422                	ld	s0,8(sp)
    80001b30:	0141                	addi	sp,sp,16
    80001b32:	8082                	ret

0000000080001b34 <myproc>:
{
    80001b34:	1101                	addi	sp,sp,-32
    80001b36:	ec06                	sd	ra,24(sp)
    80001b38:	e822                	sd	s0,16(sp)
    80001b3a:	e426                	sd	s1,8(sp)
    80001b3c:	1000                	addi	s0,sp,32
    push_off();
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	072080e7          	jalr	114(ra) # 80000bb0 <push_off>
    80001b46:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001b48:	2781                	sext.w	a5,a5
    80001b4a:	079e                	slli	a5,a5,0x7
    80001b4c:	00010717          	auipc	a4,0x10
    80001b50:	e0470713          	addi	a4,a4,-508 # 80011950 <Q>
    80001b54:	97ba                	add	a5,a5,a4
    80001b56:	6187b483          	ld	s1,1560(a5)
    pop_off();
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	0f6080e7          	jalr	246(ra) # 80000c50 <pop_off>
}
    80001b62:	8526                	mv	a0,s1
    80001b64:	60e2                	ld	ra,24(sp)
    80001b66:	6442                	ld	s0,16(sp)
    80001b68:	64a2                	ld	s1,8(sp)
    80001b6a:	6105                	addi	sp,sp,32
    80001b6c:	8082                	ret

0000000080001b6e <forkret>:
{
    80001b6e:	1141                	addi	sp,sp,-16
    80001b70:	e406                	sd	ra,8(sp)
    80001b72:	e022                	sd	s0,0(sp)
    80001b74:	0800                	addi	s0,sp,16
    release(&myproc()->lock);
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	fbe080e7          	jalr	-66(ra) # 80001b34 <myproc>
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	132080e7          	jalr	306(ra) # 80000cb0 <release>
    if (first)
    80001b86:	00007797          	auipc	a5,0x7
    80001b8a:	cda7a783          	lw	a5,-806(a5) # 80008860 <first.1>
    80001b8e:	eb89                	bnez	a5,80001ba0 <forkret+0x32>
    usertrapret();
    80001b90:	00001097          	auipc	ra,0x1
    80001b94:	dd2080e7          	jalr	-558(ra) # 80002962 <usertrapret>
}
    80001b98:	60a2                	ld	ra,8(sp)
    80001b9a:	6402                	ld	s0,0(sp)
    80001b9c:	0141                	addi	sp,sp,16
    80001b9e:	8082                	ret
        first = 0;
    80001ba0:	00007797          	auipc	a5,0x7
    80001ba4:	cc07a023          	sw	zero,-832(a5) # 80008860 <first.1>
        fsinit(ROOTDEV);
    80001ba8:	4505                	li	a0,1
    80001baa:	00002097          	auipc	ra,0x2
    80001bae:	b5c080e7          	jalr	-1188(ra) # 80003706 <fsinit>
    80001bb2:	bff9                	j	80001b90 <forkret+0x22>

0000000080001bb4 <allocpid>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	e04a                	sd	s2,0(sp)
    80001bbe:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001bc0:	00010917          	auipc	s2,0x10
    80001bc4:	39090913          	addi	s2,s2,912 # 80011f50 <pid_lock>
    80001bc8:	854a                	mv	a0,s2
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	032080e7          	jalr	50(ra) # 80000bfc <acquire>
    pid = nextpid;
    80001bd2:	00007797          	auipc	a5,0x7
    80001bd6:	c9278793          	addi	a5,a5,-878 # 80008864 <nextpid>
    80001bda:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001bdc:	0014871b          	addiw	a4,s1,1
    80001be0:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001be2:	854a                	mv	a0,s2
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	0cc080e7          	jalr	204(ra) # 80000cb0 <release>
}
    80001bec:	8526                	mv	a0,s1
    80001bee:	60e2                	ld	ra,24(sp)
    80001bf0:	6442                	ld	s0,16(sp)
    80001bf2:	64a2                	ld	s1,8(sp)
    80001bf4:	6902                	ld	s2,0(sp)
    80001bf6:	6105                	addi	sp,sp,32
    80001bf8:	8082                	ret

0000000080001bfa <proc_pagetable>:
{
    80001bfa:	1101                	addi	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	e04a                	sd	s2,0(sp)
    80001c04:	1000                	addi	s0,sp,32
    80001c06:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	76a080e7          	jalr	1898(ra) # 80001372 <uvmcreate>
    80001c10:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c12:	c121                	beqz	a0,80001c52 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c14:	4729                	li	a4,10
    80001c16:	00005697          	auipc	a3,0x5
    80001c1a:	3ea68693          	addi	a3,a3,1002 # 80007000 <_trampoline>
    80001c1e:	6605                	lui	a2,0x1
    80001c20:	040005b7          	lui	a1,0x4000
    80001c24:	15fd                	addi	a1,a1,-1
    80001c26:	05b2                	slli	a1,a1,0xc
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	4ee080e7          	jalr	1262(ra) # 80001116 <mappages>
    80001c30:	02054863          	bltz	a0,80001c60 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c34:	4719                	li	a4,6
    80001c36:	05893683          	ld	a3,88(s2)
    80001c3a:	6605                	lui	a2,0x1
    80001c3c:	020005b7          	lui	a1,0x2000
    80001c40:	15fd                	addi	a1,a1,-1
    80001c42:	05b6                	slli	a1,a1,0xd
    80001c44:	8526                	mv	a0,s1
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	4d0080e7          	jalr	1232(ra) # 80001116 <mappages>
    80001c4e:	02054163          	bltz	a0,80001c70 <proc_pagetable+0x76>
}
    80001c52:	8526                	mv	a0,s1
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6902                	ld	s2,0(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret
        uvmfree(pagetable, 0);
    80001c60:	4581                	li	a1,0
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	90a080e7          	jalr	-1782(ra) # 8000156e <uvmfree>
        return 0;
    80001c6c:	4481                	li	s1,0
    80001c6e:	b7d5                	j	80001c52 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c70:	4681                	li	a3,0
    80001c72:	4605                	li	a2,1
    80001c74:	040005b7          	lui	a1,0x4000
    80001c78:	15fd                	addi	a1,a1,-1
    80001c7a:	05b2                	slli	a1,a1,0xc
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	630080e7          	jalr	1584(ra) # 800012ae <uvmunmap>
        uvmfree(pagetable, 0);
    80001c86:	4581                	li	a1,0
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	8e4080e7          	jalr	-1820(ra) # 8000156e <uvmfree>
        return 0;
    80001c92:	4481                	li	s1,0
    80001c94:	bf7d                	j	80001c52 <proc_pagetable+0x58>

0000000080001c96 <proc_freepagetable>:
{
    80001c96:	1101                	addi	sp,sp,-32
    80001c98:	ec06                	sd	ra,24(sp)
    80001c9a:	e822                	sd	s0,16(sp)
    80001c9c:	e426                	sd	s1,8(sp)
    80001c9e:	e04a                	sd	s2,0(sp)
    80001ca0:	1000                	addi	s0,sp,32
    80001ca2:	84aa                	mv	s1,a0
    80001ca4:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca6:	4681                	li	a3,0
    80001ca8:	4605                	li	a2,1
    80001caa:	040005b7          	lui	a1,0x4000
    80001cae:	15fd                	addi	a1,a1,-1
    80001cb0:	05b2                	slli	a1,a1,0xc
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	5fc080e7          	jalr	1532(ra) # 800012ae <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cba:	4681                	li	a3,0
    80001cbc:	4605                	li	a2,1
    80001cbe:	020005b7          	lui	a1,0x2000
    80001cc2:	15fd                	addi	a1,a1,-1
    80001cc4:	05b6                	slli	a1,a1,0xd
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	5e6080e7          	jalr	1510(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, sz);
    80001cd0:	85ca                	mv	a1,s2
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	89a080e7          	jalr	-1894(ra) # 8000156e <uvmfree>
}
    80001cdc:	60e2                	ld	ra,24(sp)
    80001cde:	6442                	ld	s0,16(sp)
    80001ce0:	64a2                	ld	s1,8(sp)
    80001ce2:	6902                	ld	s2,0(sp)
    80001ce4:	6105                	addi	sp,sp,32
    80001ce6:	8082                	ret

0000000080001ce8 <freeproc>:
{
    80001ce8:	1101                	addi	sp,sp,-32
    80001cea:	ec06                	sd	ra,24(sp)
    80001cec:	e822                	sd	s0,16(sp)
    80001cee:	e426                	sd	s1,8(sp)
    80001cf0:	1000                	addi	s0,sp,32
    80001cf2:	84aa                	mv	s1,a0
    getportion(p);
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	b84080e7          	jalr	-1148(ra) # 80001878 <getportion>
    printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cfc:	1684a783          	lw	a5,360(s1)
    80001d00:	16c4a703          	lw	a4,364(s1)
    80001d04:	1704a683          	lw	a3,368(s1)
    80001d08:	5c90                	lw	a2,56(s1)
    80001d0a:	15848593          	addi	a1,s1,344
    80001d0e:	00006517          	auipc	a0,0x6
    80001d12:	4fa50513          	addi	a0,a0,1274 # 80008208 <digits+0x1c8>
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	874080e7          	jalr	-1932(ra) # 8000058a <printf>
    if (p->trapframe)
    80001d1e:	6ca8                	ld	a0,88(s1)
    80001d20:	c509                	beqz	a0,80001d2a <freeproc+0x42>
        kfree((void *)p->trapframe);
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	cee080e7          	jalr	-786(ra) # 80000a10 <kfree>
    p->trapframe = 0;
    80001d2a:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d2e:	68a8                	ld	a0,80(s1)
    80001d30:	c511                	beqz	a0,80001d3c <freeproc+0x54>
        proc_freepagetable(p->pagetable, p->sz);
    80001d32:	64ac                	ld	a1,72(s1)
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f62080e7          	jalr	-158(ra) # 80001c96 <proc_freepagetable>
    p->pagetable = 0;
    80001d3c:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d40:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d44:	0204ac23          	sw	zero,56(s1)
    p->parent = 0;
    80001d48:	0204b023          	sd	zero,32(s1)
    p->name[0] = 0;
    80001d4c:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d50:	0204b423          	sd	zero,40(s1)
    p->killed = 0;
    80001d54:	0204a823          	sw	zero,48(s1)
    p->xstate = 0;
    80001d58:	0204aa23          	sw	zero,52(s1)
    p->state = UNUSED;
    80001d5c:	0004ac23          	sw	zero,24(s1)
    p->priority = 0;
    80001d60:	1804a023          	sw	zero,384(s1)
    p->Qtime[2] = 0;
    80001d64:	1604a823          	sw	zero,368(s1)
    p->Qtime[1] = 0;
    80001d68:	1604a623          	sw	zero,364(s1)
    p->Qtime[0] = 0;
    80001d6c:	1604a423          	sw	zero,360(s1)
    p->Qinterval[2] = 0;
    80001d70:	1604ae23          	sw	zero,380(s1)
    p->Qinterval[1] = 0;
    80001d74:	1604ac23          	sw	zero,376(s1)
    p->Qinterval[0] = 0;
    80001d78:	1604aa23          	sw	zero,372(s1)
    movequeue(p, 0, DELETE);
    80001d7c:	4609                	li	a2,2
    80001d7e:	4581                	li	a1,0
    80001d80:	8526                	mv	a0,s1
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	b9c080e7          	jalr	-1124(ra) # 8000191e <movequeue>
}
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6105                	addi	sp,sp,32
    80001d92:	8082                	ret

0000000080001d94 <allocproc>:
{
    80001d94:	1101                	addi	sp,sp,-32
    80001d96:	ec06                	sd	ra,24(sp)
    80001d98:	e822                	sd	s0,16(sp)
    80001d9a:	e426                	sd	s1,8(sp)
    80001d9c:	e04a                	sd	s2,0(sp)
    80001d9e:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001da0:	00010497          	auipc	s1,0x10
    80001da4:	5c848493          	addi	s1,s1,1480 # 80012368 <proc>
    80001da8:	00016917          	auipc	s2,0x16
    80001dac:	7c090913          	addi	s2,s2,1984 # 80018568 <tickslock>
        acquire(&p->lock);
    80001db0:	8526                	mv	a0,s1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	e4a080e7          	jalr	-438(ra) # 80000bfc <acquire>
        if (p->state == UNUSED)
    80001dba:	4c9c                	lw	a5,24(s1)
    80001dbc:	cf81                	beqz	a5,80001dd4 <allocproc+0x40>
            release(&p->lock);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	ef0080e7          	jalr	-272(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001dc8:	18848493          	addi	s1,s1,392
    80001dcc:	ff2492e3          	bne	s1,s2,80001db0 <allocproc+0x1c>
    return 0;
    80001dd0:	4481                	li	s1,0
    80001dd2:	a0a5                	j	80001e3a <allocproc+0xa6>
    p->pid = allocpid();
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	de0080e7          	jalr	-544(ra) # 80001bb4 <allocpid>
    80001ddc:	dc88                	sw	a0,56(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	d2e080e7          	jalr	-722(ra) # 80000b0c <kalloc>
    80001de6:	892a                	mv	s2,a0
    80001de8:	eca8                	sd	a0,88(s1)
    80001dea:	cd39                	beqz	a0,80001e48 <allocproc+0xb4>
    p->pagetable = proc_pagetable(p);
    80001dec:	8526                	mv	a0,s1
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e0c080e7          	jalr	-500(ra) # 80001bfa <proc_pagetable>
    80001df6:	892a                	mv	s2,a0
    80001df8:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001dfa:	cd31                	beqz	a0,80001e56 <allocproc+0xc2>
    memset(&p->context, 0, sizeof(p->context));
    80001dfc:	07000613          	li	a2,112
    80001e00:	4581                	li	a1,0
    80001e02:	06048513          	addi	a0,s1,96
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	ef2080e7          	jalr	-270(ra) # 80000cf8 <memset>
    p->context.ra = (uint64)forkret;
    80001e0e:	00000797          	auipc	a5,0x0
    80001e12:	d6078793          	addi	a5,a5,-672 # 80001b6e <forkret>
    80001e16:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e18:	60bc                	ld	a5,64(s1)
    80001e1a:	6705                	lui	a4,0x1
    80001e1c:	97ba                	add	a5,a5,a4
    80001e1e:	f4bc                	sd	a5,104(s1)
    p->Qinterval[2] = ticks;
    80001e20:	00007797          	auipc	a5,0x7
    80001e24:	2007a783          	lw	a5,512(a5) # 80009020 <ticks>
    80001e28:	16f4ae23          	sw	a5,380(s1)
    movequeue(p, 2, INSERT);
    80001e2c:	4605                	li	a2,1
    80001e2e:	4589                	li	a1,2
    80001e30:	8526                	mv	a0,s1
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	aec080e7          	jalr	-1300(ra) # 8000191e <movequeue>
}
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	60e2                	ld	ra,24(sp)
    80001e3e:	6442                	ld	s0,16(sp)
    80001e40:	64a2                	ld	s1,8(sp)
    80001e42:	6902                	ld	s2,0(sp)
    80001e44:	6105                	addi	sp,sp,32
    80001e46:	8082                	ret
        release(&p->lock);
    80001e48:	8526                	mv	a0,s1
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e66080e7          	jalr	-410(ra) # 80000cb0 <release>
        return 0;
    80001e52:	84ca                	mv	s1,s2
    80001e54:	b7dd                	j	80001e3a <allocproc+0xa6>
        freeproc(p);
    80001e56:	8526                	mv	a0,s1
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	e90080e7          	jalr	-368(ra) # 80001ce8 <freeproc>
        release(&p->lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e4e080e7          	jalr	-434(ra) # 80000cb0 <release>
        return 0;
    80001e6a:	84ca                	mv	s1,s2
    80001e6c:	b7f9                	j	80001e3a <allocproc+0xa6>

0000000080001e6e <userinit>:
{
    80001e6e:	1101                	addi	sp,sp,-32
    80001e70:	ec06                	sd	ra,24(sp)
    80001e72:	e822                	sd	s0,16(sp)
    80001e74:	e426                	sd	s1,8(sp)
    80001e76:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	f1c080e7          	jalr	-228(ra) # 80001d94 <allocproc>
    80001e80:	84aa                	mv	s1,a0
    initproc = p;
    80001e82:	00007797          	auipc	a5,0x7
    80001e86:	18a7bb23          	sd	a0,406(a5) # 80009018 <initproc>
    uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e8a:	03400613          	li	a2,52
    80001e8e:	00007597          	auipc	a1,0x7
    80001e92:	9e258593          	addi	a1,a1,-1566 # 80008870 <initcode>
    80001e96:	6928                	ld	a0,80(a0)
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	508080e7          	jalr	1288(ra) # 800013a0 <uvminit>
    p->sz = PGSIZE;
    80001ea0:	6785                	lui	a5,0x1
    80001ea2:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001ea4:	6cb8                	ld	a4,88(s1)
    80001ea6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001eaa:	6cb8                	ld	a4,88(s1)
    80001eac:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eae:	4641                	li	a2,16
    80001eb0:	00006597          	auipc	a1,0x6
    80001eb4:	38858593          	addi	a1,a1,904 # 80008238 <digits+0x1f8>
    80001eb8:	15848513          	addi	a0,s1,344
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	f8e080e7          	jalr	-114(ra) # 80000e4a <safestrcpy>
    p->cwd = namei("/");
    80001ec4:	00006517          	auipc	a0,0x6
    80001ec8:	38450513          	addi	a0,a0,900 # 80008248 <digits+0x208>
    80001ecc:	00002097          	auipc	ra,0x2
    80001ed0:	262080e7          	jalr	610(ra) # 8000412e <namei>
    80001ed4:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001ed8:	4789                	li	a5,2
    80001eda:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001edc:	8526                	mv	a0,s1
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dd2080e7          	jalr	-558(ra) # 80000cb0 <release>
}
    80001ee6:	60e2                	ld	ra,24(sp)
    80001ee8:	6442                	ld	s0,16(sp)
    80001eea:	64a2                	ld	s1,8(sp)
    80001eec:	6105                	addi	sp,sp,32
    80001eee:	8082                	ret

0000000080001ef0 <growproc>:
{
    80001ef0:	1101                	addi	sp,sp,-32
    80001ef2:	ec06                	sd	ra,24(sp)
    80001ef4:	e822                	sd	s0,16(sp)
    80001ef6:	e426                	sd	s1,8(sp)
    80001ef8:	e04a                	sd	s2,0(sp)
    80001efa:	1000                	addi	s0,sp,32
    80001efc:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	c36080e7          	jalr	-970(ra) # 80001b34 <myproc>
    80001f06:	892a                	mv	s2,a0
    sz = p->sz;
    80001f08:	652c                	ld	a1,72(a0)
    80001f0a:	0005861b          	sext.w	a2,a1
    if (n > 0)
    80001f0e:	00904f63          	bgtz	s1,80001f2c <growproc+0x3c>
    else if (n < 0)
    80001f12:	0204cc63          	bltz	s1,80001f4a <growproc+0x5a>
    p->sz = sz;
    80001f16:	1602                	slli	a2,a2,0x20
    80001f18:	9201                	srli	a2,a2,0x20
    80001f1a:	04c93423          	sd	a2,72(s2)
    return 0;
    80001f1e:	4501                	li	a0,0
}
    80001f20:	60e2                	ld	ra,24(sp)
    80001f22:	6442                	ld	s0,16(sp)
    80001f24:	64a2                	ld	s1,8(sp)
    80001f26:	6902                	ld	s2,0(sp)
    80001f28:	6105                	addi	sp,sp,32
    80001f2a:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f2c:	9e25                	addw	a2,a2,s1
    80001f2e:	1602                	slli	a2,a2,0x20
    80001f30:	9201                	srli	a2,a2,0x20
    80001f32:	1582                	slli	a1,a1,0x20
    80001f34:	9181                	srli	a1,a1,0x20
    80001f36:	6928                	ld	a0,80(a0)
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	522080e7          	jalr	1314(ra) # 8000145a <uvmalloc>
    80001f40:	0005061b          	sext.w	a2,a0
    80001f44:	fa69                	bnez	a2,80001f16 <growproc+0x26>
            return -1;
    80001f46:	557d                	li	a0,-1
    80001f48:	bfe1                	j	80001f20 <growproc+0x30>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f4a:	9e25                	addw	a2,a2,s1
    80001f4c:	1602                	slli	a2,a2,0x20
    80001f4e:	9201                	srli	a2,a2,0x20
    80001f50:	1582                	slli	a1,a1,0x20
    80001f52:	9181                	srli	a1,a1,0x20
    80001f54:	6928                	ld	a0,80(a0)
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	4bc080e7          	jalr	1212(ra) # 80001412 <uvmdealloc>
    80001f5e:	0005061b          	sext.w	a2,a0
    80001f62:	bf55                	j	80001f16 <growproc+0x26>

0000000080001f64 <fork>:
{
    80001f64:	7139                	addi	sp,sp,-64
    80001f66:	fc06                	sd	ra,56(sp)
    80001f68:	f822                	sd	s0,48(sp)
    80001f6a:	f426                	sd	s1,40(sp)
    80001f6c:	f04a                	sd	s2,32(sp)
    80001f6e:	ec4e                	sd	s3,24(sp)
    80001f70:	e852                	sd	s4,16(sp)
    80001f72:	e456                	sd	s5,8(sp)
    80001f74:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	bbe080e7          	jalr	-1090(ra) # 80001b34 <myproc>
    80001f7e:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	e14080e7          	jalr	-492(ra) # 80001d94 <allocproc>
    80001f88:	c17d                	beqz	a0,8000206e <fork+0x10a>
    80001f8a:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f8c:	048ab603          	ld	a2,72(s5)
    80001f90:	692c                	ld	a1,80(a0)
    80001f92:	050ab503          	ld	a0,80(s5)
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	610080e7          	jalr	1552(ra) # 800015a6 <uvmcopy>
    80001f9e:	04054a63          	bltz	a0,80001ff2 <fork+0x8e>
    np->sz = p->sz;
    80001fa2:	048ab783          	ld	a5,72(s5)
    80001fa6:	04fa3423          	sd	a5,72(s4)
    np->parent = p;
    80001faa:	035a3023          	sd	s5,32(s4)
    *(np->trapframe) = *(p->trapframe);
    80001fae:	058ab683          	ld	a3,88(s5)
    80001fb2:	87b6                	mv	a5,a3
    80001fb4:	058a3703          	ld	a4,88(s4)
    80001fb8:	12068693          	addi	a3,a3,288
    80001fbc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fc0:	6788                	ld	a0,8(a5)
    80001fc2:	6b8c                	ld	a1,16(a5)
    80001fc4:	6f90                	ld	a2,24(a5)
    80001fc6:	01073023          	sd	a6,0(a4)
    80001fca:	e708                	sd	a0,8(a4)
    80001fcc:	eb0c                	sd	a1,16(a4)
    80001fce:	ef10                	sd	a2,24(a4)
    80001fd0:	02078793          	addi	a5,a5,32
    80001fd4:	02070713          	addi	a4,a4,32
    80001fd8:	fed792e3          	bne	a5,a3,80001fbc <fork+0x58>
    np->trapframe->a0 = 0;
    80001fdc:	058a3783          	ld	a5,88(s4)
    80001fe0:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80001fe4:	0d0a8493          	addi	s1,s5,208
    80001fe8:	0d0a0913          	addi	s2,s4,208
    80001fec:	150a8993          	addi	s3,s5,336
    80001ff0:	a00d                	j	80002012 <fork+0xae>
        freeproc(np);
    80001ff2:	8552                	mv	a0,s4
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	cf4080e7          	jalr	-780(ra) # 80001ce8 <freeproc>
        release(&np->lock);
    80001ffc:	8552                	mv	a0,s4
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	cb2080e7          	jalr	-846(ra) # 80000cb0 <release>
        return -1;
    80002006:	54fd                	li	s1,-1
    80002008:	a889                	j	8000205a <fork+0xf6>
    for (i = 0; i < NOFILE; i++)
    8000200a:	04a1                	addi	s1,s1,8
    8000200c:	0921                	addi	s2,s2,8
    8000200e:	01348b63          	beq	s1,s3,80002024 <fork+0xc0>
        if (p->ofile[i])
    80002012:	6088                	ld	a0,0(s1)
    80002014:	d97d                	beqz	a0,8000200a <fork+0xa6>
            np->ofile[i] = filedup(p->ofile[i]);
    80002016:	00002097          	auipc	ra,0x2
    8000201a:	7a4080e7          	jalr	1956(ra) # 800047ba <filedup>
    8000201e:	00a93023          	sd	a0,0(s2)
    80002022:	b7e5                	j	8000200a <fork+0xa6>
    np->cwd = idup(p->cwd);
    80002024:	150ab503          	ld	a0,336(s5)
    80002028:	00002097          	auipc	ra,0x2
    8000202c:	918080e7          	jalr	-1768(ra) # 80003940 <idup>
    80002030:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002034:	4641                	li	a2,16
    80002036:	158a8593          	addi	a1,s5,344
    8000203a:	158a0513          	addi	a0,s4,344
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	e0c080e7          	jalr	-500(ra) # 80000e4a <safestrcpy>
    pid = np->pid;
    80002046:	038a2483          	lw	s1,56(s4)
    np->state = RUNNABLE;
    8000204a:	4789                	li	a5,2
    8000204c:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002050:	8552                	mv	a0,s4
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	c5e080e7          	jalr	-930(ra) # 80000cb0 <release>
}
    8000205a:	8526                	mv	a0,s1
    8000205c:	70e2                	ld	ra,56(sp)
    8000205e:	7442                	ld	s0,48(sp)
    80002060:	74a2                	ld	s1,40(sp)
    80002062:	7902                	ld	s2,32(sp)
    80002064:	69e2                	ld	s3,24(sp)
    80002066:	6a42                	ld	s4,16(sp)
    80002068:	6aa2                	ld	s5,8(sp)
    8000206a:	6121                	addi	sp,sp,64
    8000206c:	8082                	ret
        return -1;
    8000206e:	54fd                	li	s1,-1
    80002070:	b7ed                	j	8000205a <fork+0xf6>

0000000080002072 <reparent>:
{
    80002072:	7179                	addi	sp,sp,-48
    80002074:	f406                	sd	ra,40(sp)
    80002076:	f022                	sd	s0,32(sp)
    80002078:	ec26                	sd	s1,24(sp)
    8000207a:	e84a                	sd	s2,16(sp)
    8000207c:	e44e                	sd	s3,8(sp)
    8000207e:	e052                	sd	s4,0(sp)
    80002080:	1800                	addi	s0,sp,48
    80002082:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002084:	00010497          	auipc	s1,0x10
    80002088:	2e448493          	addi	s1,s1,740 # 80012368 <proc>
            pp->parent = initproc;
    8000208c:	00007a17          	auipc	s4,0x7
    80002090:	f8ca0a13          	addi	s4,s4,-116 # 80009018 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002094:	00016997          	auipc	s3,0x16
    80002098:	4d498993          	addi	s3,s3,1236 # 80018568 <tickslock>
    8000209c:	a029                	j	800020a6 <reparent+0x34>
    8000209e:	18848493          	addi	s1,s1,392
    800020a2:	03348363          	beq	s1,s3,800020c8 <reparent+0x56>
        if (pp->parent == p)
    800020a6:	709c                	ld	a5,32(s1)
    800020a8:	ff279be3          	bne	a5,s2,8000209e <reparent+0x2c>
            acquire(&pp->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b4e080e7          	jalr	-1202(ra) # 80000bfc <acquire>
            pp->parent = initproc;
    800020b6:	000a3783          	ld	a5,0(s4)
    800020ba:	f09c                	sd	a5,32(s1)
            release(&pp->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	bf2080e7          	jalr	-1038(ra) # 80000cb0 <release>
    800020c6:	bfe1                	j	8000209e <reparent+0x2c>
}
    800020c8:	70a2                	ld	ra,40(sp)
    800020ca:	7402                	ld	s0,32(sp)
    800020cc:	64e2                	ld	s1,24(sp)
    800020ce:	6942                	ld	s2,16(sp)
    800020d0:	69a2                	ld	s3,8(sp)
    800020d2:	6a02                	ld	s4,0(sp)
    800020d4:	6145                	addi	sp,sp,48
    800020d6:	8082                	ret

00000000800020d8 <scheduler>:
{
    800020d8:	711d                	addi	sp,sp,-96
    800020da:	ec86                	sd	ra,88(sp)
    800020dc:	e8a2                	sd	s0,80(sp)
    800020de:	e4a6                	sd	s1,72(sp)
    800020e0:	e0ca                	sd	s2,64(sp)
    800020e2:	fc4e                	sd	s3,56(sp)
    800020e4:	f852                	sd	s4,48(sp)
    800020e6:	f456                	sd	s5,40(sp)
    800020e8:	f05a                	sd	s6,32(sp)
    800020ea:	ec5e                	sd	s7,24(sp)
    800020ec:	e862                	sd	s8,16(sp)
    800020ee:	e466                	sd	s9,8(sp)
    800020f0:	1080                	addi	s0,sp,96
    800020f2:	8792                	mv	a5,tp
    int id = r_tp();
    800020f4:	2781                	sext.w	a5,a5
    c->proc = 0;
    800020f6:	00779b93          	slli	s7,a5,0x7
    800020fa:	00010717          	auipc	a4,0x10
    800020fe:	85670713          	addi	a4,a4,-1962 # 80011950 <Q>
    80002102:	975e                	add	a4,a4,s7
    80002104:	60073c23          	sd	zero,1560(a4)
                swtch(&c->context, &p->context);
    80002108:	00010717          	auipc	a4,0x10
    8000210c:	e6870713          	addi	a4,a4,-408 # 80011f70 <cpus+0x8>
    80002110:	9bba                	add	s7,s7,a4
    int exec = 0;
    80002112:	4b01                	li	s6,0
        for (int i = 0; i < findproc(0, 2); i++)
    80002114:	4a01                	li	s4,0
                p->state = RUNNING;
    80002116:	4c0d                	li	s8,3
                c->proc = p;
    80002118:	00010c97          	auipc	s9,0x10
    8000211c:	838c8c93          	addi	s9,s9,-1992 # 80011950 <Q>
    80002120:	079e                	slli	a5,a5,0x7
    80002122:	00fc8ab3          	add	s5,s9,a5
    80002126:	a049                	j	800021a8 <scheduler+0xd0>
            exec = 0;
    80002128:	8b52                	mv	s6,s4
    8000212a:	a8bd                	j	800021a8 <scheduler+0xd0>
            release(&p->lock);
    8000212c:	8526                	mv	a0,s1
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b82080e7          	jalr	-1150(ra) # 80000cb0 <release>
        for (int i = 0; i < findproc(0, 2); i++)
    80002136:	2905                	addiw	s2,s2,1
    80002138:	09a1                	addi	s3,s3,8
    8000213a:	4589                	li	a1,2
    8000213c:	8552                	mv	a0,s4
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	7a2080e7          	jalr	1954(ra) # 800018e0 <findproc>
    80002146:	02a95c63          	bge	s2,a0,8000217e <scheduler+0xa6>
            p = Q[2][i];
    8000214a:	0009b483          	ld	s1,0(s3)
            if (p == 0)
    8000214e:	c885                	beqz	s1,8000217e <scheduler+0xa6>
            acquire(&p->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	aaa080e7          	jalr	-1366(ra) # 80000bfc <acquire>
            if (p->state == RUNNABLE)
    8000215a:	4c98                	lw	a4,24(s1)
    8000215c:	4789                	li	a5,2
    8000215e:	fcf717e3          	bne	a4,a5,8000212c <scheduler+0x54>
                p->state = RUNNING;
    80002162:	0184ac23          	sw	s8,24(s1)
                c->proc = p;
    80002166:	609abc23          	sd	s1,1560(s5)
                swtch(&c->context, &p->context);
    8000216a:	06048593          	addi	a1,s1,96
    8000216e:	855e                	mv	a0,s7
    80002170:	00000097          	auipc	ra,0x0
    80002174:	748080e7          	jalr	1864(ra) # 800028b8 <swtch>
                c->proc = 0;
    80002178:	600abc23          	sd	zero,1560(s5)
    8000217c:	bf45                	j	8000212c <scheduler+0x54>
        p = Q[1][exec];
    8000217e:	040b0793          	addi	a5,s6,64 # 1040 <_entry-0x7fffefc0>
    80002182:	078e                	slli	a5,a5,0x3
    80002184:	97e6                	add	a5,a5,s9
    80002186:	6384                	ld	s1,0(a5)
        if (p == 0)
    80002188:	d0c5                	beqz	s1,80002128 <scheduler+0x50>
        acquire(&p->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	a70080e7          	jalr	-1424(ra) # 80000bfc <acquire>
        if (p->state == RUNNABLE)
    80002194:	4c98                	lw	a4,24(s1)
    80002196:	4789                	li	a5,2
    80002198:	02f70463          	beq	a4,a5,800021c0 <scheduler+0xe8>
        release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	b12080e7          	jalr	-1262(ra) # 80000cb0 <release>
        exec++;   
    800021a6:	2b05                	addiw	s6,s6,1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021ac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021b0:	10079073          	csrw	sstatus,a5
        for (int i = 0; i < findproc(0, 2); i++)
    800021b4:	00010997          	auipc	s3,0x10
    800021b8:	b9c98993          	addi	s3,s3,-1124 # 80011d50 <Q+0x400>
    800021bc:	8952                	mv	s2,s4
    800021be:	bfb5                	j	8000213a <scheduler+0x62>
            p->state = RUNNING;
    800021c0:	0184ac23          	sw	s8,24(s1)
            c->proc = p;
    800021c4:	609abc23          	sd	s1,1560(s5)
            swtch(&c->context, &p->context);   
    800021c8:	06048593          	addi	a1,s1,96
    800021cc:	855e                	mv	a0,s7
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	6ea080e7          	jalr	1770(ra) # 800028b8 <swtch>
            c->proc = 0;
    800021d6:	600abc23          	sd	zero,1560(s5)
    800021da:	b7c9                	j	8000219c <scheduler+0xc4>

00000000800021dc <sched>:
{
    800021dc:	7179                	addi	sp,sp,-48
    800021de:	f406                	sd	ra,40(sp)
    800021e0:	f022                	sd	s0,32(sp)
    800021e2:	ec26                	sd	s1,24(sp)
    800021e4:	e84a                	sd	s2,16(sp)
    800021e6:	e44e                	sd	s3,8(sp)
    800021e8:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	94a080e7          	jalr	-1718(ra) # 80001b34 <myproc>
    800021f2:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	98e080e7          	jalr	-1650(ra) # 80000b82 <holding>
    800021fc:	c93d                	beqz	a0,80002272 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021fe:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002200:	2781                	sext.w	a5,a5
    80002202:	079e                	slli	a5,a5,0x7
    80002204:	0000f717          	auipc	a4,0xf
    80002208:	74c70713          	addi	a4,a4,1868 # 80011950 <Q>
    8000220c:	97ba                	add	a5,a5,a4
    8000220e:	6907a703          	lw	a4,1680(a5)
    80002212:	4785                	li	a5,1
    80002214:	06f71763          	bne	a4,a5,80002282 <sched+0xa6>
    if (p->state == RUNNING)
    80002218:	4c98                	lw	a4,24(s1)
    8000221a:	478d                	li	a5,3
    8000221c:	06f70b63          	beq	a4,a5,80002292 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002220:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002224:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002226:	efb5                	bnez	a5,800022a2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002228:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000222a:	0000f917          	auipc	s2,0xf
    8000222e:	72690913          	addi	s2,s2,1830 # 80011950 <Q>
    80002232:	2781                	sext.w	a5,a5
    80002234:	079e                	slli	a5,a5,0x7
    80002236:	97ca                	add	a5,a5,s2
    80002238:	6947a983          	lw	s3,1684(a5)
    8000223c:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    8000223e:	2781                	sext.w	a5,a5
    80002240:	079e                	slli	a5,a5,0x7
    80002242:	00010597          	auipc	a1,0x10
    80002246:	d2e58593          	addi	a1,a1,-722 # 80011f70 <cpus+0x8>
    8000224a:	95be                	add	a1,a1,a5
    8000224c:	06048513          	addi	a0,s1,96
    80002250:	00000097          	auipc	ra,0x0
    80002254:	668080e7          	jalr	1640(ra) # 800028b8 <swtch>
    80002258:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000225a:	2781                	sext.w	a5,a5
    8000225c:	079e                	slli	a5,a5,0x7
    8000225e:	97ca                	add	a5,a5,s2
    80002260:	6937aa23          	sw	s3,1684(a5)
}
    80002264:	70a2                	ld	ra,40(sp)
    80002266:	7402                	ld	s0,32(sp)
    80002268:	64e2                	ld	s1,24(sp)
    8000226a:	6942                	ld	s2,16(sp)
    8000226c:	69a2                	ld	s3,8(sp)
    8000226e:	6145                	addi	sp,sp,48
    80002270:	8082                	ret
        panic("sched p->lock");
    80002272:	00006517          	auipc	a0,0x6
    80002276:	fde50513          	addi	a0,a0,-34 # 80008250 <digits+0x210>
    8000227a:	ffffe097          	auipc	ra,0xffffe
    8000227e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>
        panic("sched locks");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	fde50513          	addi	a0,a0,-34 # 80008260 <digits+0x220>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2b6080e7          	jalr	694(ra) # 80000540 <panic>
        panic("sched running");
    80002292:	00006517          	auipc	a0,0x6
    80002296:	fde50513          	addi	a0,a0,-34 # 80008270 <digits+0x230>
    8000229a:	ffffe097          	auipc	ra,0xffffe
    8000229e:	2a6080e7          	jalr	678(ra) # 80000540 <panic>
        panic("sched interruptible");
    800022a2:	00006517          	auipc	a0,0x6
    800022a6:	fde50513          	addi	a0,a0,-34 # 80008280 <digits+0x240>
    800022aa:	ffffe097          	auipc	ra,0xffffe
    800022ae:	296080e7          	jalr	662(ra) # 80000540 <panic>

00000000800022b2 <exit>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	e052                	sd	s4,0(sp)
    800022c0:	1800                	addi	s0,sp,48
    800022c2:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	870080e7          	jalr	-1936(ra) # 80001b34 <myproc>
    800022cc:	892a                	mv	s2,a0
    if (p == initproc)
    800022ce:	00007797          	auipc	a5,0x7
    800022d2:	d4a7b783          	ld	a5,-694(a5) # 80009018 <initproc>
    800022d6:	0d050493          	addi	s1,a0,208
    800022da:	15050993          	addi	s3,a0,336
    800022de:	02a79363          	bne	a5,a0,80002304 <exit+0x52>
        panic("init exiting");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	fb650513          	addi	a0,a0,-74 # 80008298 <digits+0x258>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	256080e7          	jalr	598(ra) # 80000540 <panic>
            fileclose(f);
    800022f2:	00002097          	auipc	ra,0x2
    800022f6:	51a080e7          	jalr	1306(ra) # 8000480c <fileclose>
            p->ofile[fd] = 0;
    800022fa:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800022fe:	04a1                	addi	s1,s1,8
    80002300:	01348563          	beq	s1,s3,8000230a <exit+0x58>
        if (p->ofile[fd])
    80002304:	6088                	ld	a0,0(s1)
    80002306:	f575                	bnez	a0,800022f2 <exit+0x40>
    80002308:	bfdd                	j	800022fe <exit+0x4c>
    begin_op();
    8000230a:	00002097          	auipc	ra,0x2
    8000230e:	030080e7          	jalr	48(ra) # 8000433a <begin_op>
    iput(p->cwd);
    80002312:	15093503          	ld	a0,336(s2)
    80002316:	00002097          	auipc	ra,0x2
    8000231a:	822080e7          	jalr	-2014(ra) # 80003b38 <iput>
    end_op();
    8000231e:	00002097          	auipc	ra,0x2
    80002322:	09c080e7          	jalr	156(ra) # 800043ba <end_op>
    p->cwd = 0;
    80002326:	14093823          	sd	zero,336(s2)
    acquire(&initproc->lock);
    8000232a:	00007497          	auipc	s1,0x7
    8000232e:	cee48493          	addi	s1,s1,-786 # 80009018 <initproc>
    80002332:	6088                	ld	a0,0(s1)
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	8c8080e7          	jalr	-1848(ra) # 80000bfc <acquire>
    wakeup1(initproc);
    8000233c:	6088                	ld	a0,0(s1)
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	688080e7          	jalr	1672(ra) # 800019c6 <wakeup1>
    release(&initproc->lock);
    80002346:	6088                	ld	a0,0(s1)
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	968080e7          	jalr	-1688(ra) # 80000cb0 <release>
    acquire(&p->lock);
    80002350:	854a                	mv	a0,s2
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	8aa080e7          	jalr	-1878(ra) # 80000bfc <acquire>
    struct proc *original_parent = p->parent;
    8000235a:	02093483          	ld	s1,32(s2)
    release(&p->lock);
    8000235e:	854a                	mv	a0,s2
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	950080e7          	jalr	-1712(ra) # 80000cb0 <release>
    acquire(&original_parent->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	892080e7          	jalr	-1902(ra) # 80000bfc <acquire>
    acquire(&p->lock);
    80002372:	854a                	mv	a0,s2
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	888080e7          	jalr	-1912(ra) # 80000bfc <acquire>
    reparent(p);
    8000237c:	854a                	mv	a0,s2
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	cf4080e7          	jalr	-780(ra) # 80002072 <reparent>
    wakeup1(original_parent);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	63e080e7          	jalr	1598(ra) # 800019c6 <wakeup1>
    p->xstate = status;
    80002390:	03492a23          	sw	s4,52(s2)
    p->state = ZOMBIE;
    80002394:	4791                	li	a5,4
    80002396:	00f92c23          	sw	a5,24(s2)
    p->Qinterval[p->priority] = ticks - p->Qinterval[p->priority];
    8000239a:	00007617          	auipc	a2,0x7
    8000239e:	c8662603          	lw	a2,-890(a2) # 80009020 <ticks>
    800023a2:	18092783          	lw	a5,384(s2)
    800023a6:	078a                	slli	a5,a5,0x2
    800023a8:	97ca                	add	a5,a5,s2
    800023aa:	1747a703          	lw	a4,372(a5)
    800023ae:	40e6073b          	subw	a4,a2,a4
    800023b2:	16e7aa23          	sw	a4,372(a5)
    p->Qtime[p->priority] += p->Qinterval[p->priority];
    800023b6:	1687a683          	lw	a3,360(a5)
    800023ba:	9f35                	addw	a4,a4,a3
    800023bc:	16e7a423          	sw	a4,360(a5)
    p->Qinterval[0] = ticks;
    800023c0:	16c92a23          	sw	a2,372(s2)
    movequeue(p, 0, MOVE);
    800023c4:	4601                	li	a2,0
    800023c6:	4581                	li	a1,0
    800023c8:	854a                	mv	a0,s2
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	554080e7          	jalr	1364(ra) # 8000191e <movequeue>
    release(&original_parent->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8dc080e7          	jalr	-1828(ra) # 80000cb0 <release>
    sched();
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	e00080e7          	jalr	-512(ra) # 800021dc <sched>
    panic("zombie exit");
    800023e4:	00006517          	auipc	a0,0x6
    800023e8:	ec450513          	addi	a0,a0,-316 # 800082a8 <digits+0x268>
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	154080e7          	jalr	340(ra) # 80000540 <panic>

00000000800023f4 <yield>:
{
    800023f4:	1101                	addi	sp,sp,-32
    800023f6:	ec06                	sd	ra,24(sp)
    800023f8:	e822                	sd	s0,16(sp)
    800023fa:	e426                	sd	s1,8(sp)
    800023fc:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	736080e7          	jalr	1846(ra) # 80001b34 <myproc>
    80002406:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	7f4080e7          	jalr	2036(ra) # 80000bfc <acquire>
    p->state = RUNNABLE;
    80002410:	4789                	li	a5,2
    80002412:	cc9c                	sw	a5,24(s1)
    if (p->priority == 2)
    80002414:	1804a703          	lw	a4,384(s1)
    80002418:	02f70063          	beq	a4,a5,80002438 <yield+0x44>
    sched();
    8000241c:	00000097          	auipc	ra,0x0
    80002420:	dc0080e7          	jalr	-576(ra) # 800021dc <sched>
    release(&p->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	88a080e7          	jalr	-1910(ra) # 80000cb0 <release>
}
    8000242e:	60e2                	ld	ra,24(sp)
    80002430:	6442                	ld	s0,16(sp)
    80002432:	64a2                	ld	s1,8(sp)
    80002434:	6105                	addi	sp,sp,32
    80002436:	8082                	ret
        movequeue(p, 1, MOVE);
    80002438:	4601                	li	a2,0
    8000243a:	4585                	li	a1,1
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	4e0080e7          	jalr	1248(ra) # 8000191e <movequeue>
        p->Qinterval[2] = ticks - p->Qinterval[2];
    80002446:	00007697          	auipc	a3,0x7
    8000244a:	bda6a683          	lw	a3,-1062(a3) # 80009020 <ticks>
    8000244e:	17c4a783          	lw	a5,380(s1)
    80002452:	40f687bb          	subw	a5,a3,a5
    80002456:	16f4ae23          	sw	a5,380(s1)
        p->Qtime[2] += p->Qinterval[2];
    8000245a:	1704a703          	lw	a4,368(s1)
    8000245e:	9fb9                	addw	a5,a5,a4
    80002460:	16f4a823          	sw	a5,368(s1)
        p->Qinterval[1] = ticks;
    80002464:	16d4ac23          	sw	a3,376(s1)
    80002468:	bf55                	j	8000241c <yield+0x28>

000000008000246a <sleep>:
{
    8000246a:	7179                	addi	sp,sp,-48
    8000246c:	f406                	sd	ra,40(sp)
    8000246e:	f022                	sd	s0,32(sp)
    80002470:	ec26                	sd	s1,24(sp)
    80002472:	e84a                	sd	s2,16(sp)
    80002474:	e44e                	sd	s3,8(sp)
    80002476:	e052                	sd	s4,0(sp)
    80002478:	1800                	addi	s0,sp,48
    8000247a:	89aa                	mv	s3,a0
    8000247c:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	6b6080e7          	jalr	1718(ra) # 80001b34 <myproc>
    80002486:	84aa                	mv	s1,a0
    if (lk != &p->lock)
    80002488:	8a2a                	mv	s4,a0
    8000248a:	01250b63          	beq	a0,s2,800024a0 <sleep+0x36>
        acquire(&p->lock); //DOC: sleeplock1
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	76e080e7          	jalr	1902(ra) # 80000bfc <acquire>
        release(lk);
    80002496:	854a                	mv	a0,s2
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	818080e7          	jalr	-2024(ra) # 80000cb0 <release>
    p->chan = chan;
    800024a0:	0334b423          	sd	s3,40(s1)
    p->state = SLEEPING;
    800024a4:	4785                	li	a5,1
    800024a6:	cc9c                	sw	a5,24(s1)
    p->Qinterval[p->priority] = ticks - p->Qinterval[p->priority];
    800024a8:	00007617          	auipc	a2,0x7
    800024ac:	b7862603          	lw	a2,-1160(a2) # 80009020 <ticks>
    800024b0:	1804a783          	lw	a5,384(s1)
    800024b4:	078a                	slli	a5,a5,0x2
    800024b6:	97a6                	add	a5,a5,s1
    800024b8:	1747a703          	lw	a4,372(a5)
    800024bc:	40e6073b          	subw	a4,a2,a4
    800024c0:	16e7aa23          	sw	a4,372(a5)
    p->Qtime[p->priority] += p->Qinterval[p->priority];
    800024c4:	1687a683          	lw	a3,360(a5)
    800024c8:	9f35                	addw	a4,a4,a3
    800024ca:	16e7a423          	sw	a4,360(a5)
    p->Qinterval[0] = ticks;
    800024ce:	16c4aa23          	sw	a2,372(s1)
    movequeue(p, 0, MOVE);
    800024d2:	4601                	li	a2,0
    800024d4:	4581                	li	a1,0
    800024d6:	8526                	mv	a0,s1
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	446080e7          	jalr	1094(ra) # 8000191e <movequeue>
    sched();
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	cfc080e7          	jalr	-772(ra) # 800021dc <sched>
    p->chan = 0;
    800024e8:	0204b423          	sd	zero,40(s1)
    if (lk != &p->lock)
    800024ec:	012a0c63          	beq	s4,s2,80002504 <sleep+0x9a>
        release(&p->lock);
    800024f0:	8526                	mv	a0,s1
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	7be080e7          	jalr	1982(ra) # 80000cb0 <release>
        acquire(lk);
    800024fa:	854a                	mv	a0,s2
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	700080e7          	jalr	1792(ra) # 80000bfc <acquire>
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret

0000000080002514 <wait>:
{
    80002514:	715d                	addi	sp,sp,-80
    80002516:	e486                	sd	ra,72(sp)
    80002518:	e0a2                	sd	s0,64(sp)
    8000251a:	fc26                	sd	s1,56(sp)
    8000251c:	f84a                	sd	s2,48(sp)
    8000251e:	f44e                	sd	s3,40(sp)
    80002520:	f052                	sd	s4,32(sp)
    80002522:	ec56                	sd	s5,24(sp)
    80002524:	e85a                	sd	s6,16(sp)
    80002526:	e45e                	sd	s7,8(sp)
    80002528:	0880                	addi	s0,sp,80
    8000252a:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	608080e7          	jalr	1544(ra) # 80001b34 <myproc>
    80002534:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	6c6080e7          	jalr	1734(ra) # 80000bfc <acquire>
        havekids = 0;
    8000253e:	4b81                	li	s7,0
                if (np->state == ZOMBIE)
    80002540:	4a11                	li	s4,4
                havekids = 1;
    80002542:	4a85                	li	s5,1
        for (np = proc; np < &proc[NPROC]; np++)
    80002544:	00016997          	auipc	s3,0x16
    80002548:	02498993          	addi	s3,s3,36 # 80018568 <tickslock>
        havekids = 0;
    8000254c:	875e                	mv	a4,s7
        for (np = proc; np < &proc[NPROC]; np++)
    8000254e:	00010497          	auipc	s1,0x10
    80002552:	e1a48493          	addi	s1,s1,-486 # 80012368 <proc>
    80002556:	a08d                	j	800025b8 <wait+0xa4>
                    pid = np->pid;
    80002558:	0384a983          	lw	s3,56(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000255c:	000b0e63          	beqz	s6,80002578 <wait+0x64>
    80002560:	4691                	li	a3,4
    80002562:	03448613          	addi	a2,s1,52
    80002566:	85da                	mv	a1,s6
    80002568:	05093503          	ld	a0,80(s2)
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	13e080e7          	jalr	318(ra) # 800016aa <copyout>
    80002574:	02054263          	bltz	a0,80002598 <wait+0x84>
                    freeproc(np);
    80002578:	8526                	mv	a0,s1
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	76e080e7          	jalr	1902(ra) # 80001ce8 <freeproc>
                    release(&np->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	72c080e7          	jalr	1836(ra) # 80000cb0 <release>
                    release(&p->lock);
    8000258c:	854a                	mv	a0,s2
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	722080e7          	jalr	1826(ra) # 80000cb0 <release>
                    return pid;
    80002596:	a8a9                	j	800025f0 <wait+0xdc>
                        release(&np->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	716080e7          	jalr	1814(ra) # 80000cb0 <release>
                        release(&p->lock);
    800025a2:	854a                	mv	a0,s2
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	70c080e7          	jalr	1804(ra) # 80000cb0 <release>
                        return -1;
    800025ac:	59fd                	li	s3,-1
    800025ae:	a089                	j	800025f0 <wait+0xdc>
        for (np = proc; np < &proc[NPROC]; np++)
    800025b0:	18848493          	addi	s1,s1,392
    800025b4:	03348463          	beq	s1,s3,800025dc <wait+0xc8>
            if (np->parent == p)
    800025b8:	709c                	ld	a5,32(s1)
    800025ba:	ff279be3          	bne	a5,s2,800025b0 <wait+0x9c>
                acquire(&np->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	63c080e7          	jalr	1596(ra) # 80000bfc <acquire>
                if (np->state == ZOMBIE)
    800025c8:	4c9c                	lw	a5,24(s1)
    800025ca:	f94787e3          	beq	a5,s4,80002558 <wait+0x44>
                release(&np->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6e0080e7          	jalr	1760(ra) # 80000cb0 <release>
                havekids = 1;
    800025d8:	8756                	mv	a4,s5
    800025da:	bfd9                	j	800025b0 <wait+0x9c>
        if (!havekids || p->killed)
    800025dc:	c701                	beqz	a4,800025e4 <wait+0xd0>
    800025de:	03092783          	lw	a5,48(s2)
    800025e2:	c39d                	beqz	a5,80002608 <wait+0xf4>
            release(&p->lock);
    800025e4:	854a                	mv	a0,s2
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	6ca080e7          	jalr	1738(ra) # 80000cb0 <release>
            return -1;
    800025ee:	59fd                	li	s3,-1
}
    800025f0:	854e                	mv	a0,s3
    800025f2:	60a6                	ld	ra,72(sp)
    800025f4:	6406                	ld	s0,64(sp)
    800025f6:	74e2                	ld	s1,56(sp)
    800025f8:	7942                	ld	s2,48(sp)
    800025fa:	79a2                	ld	s3,40(sp)
    800025fc:	7a02                	ld	s4,32(sp)
    800025fe:	6ae2                	ld	s5,24(sp)
    80002600:	6b42                	ld	s6,16(sp)
    80002602:	6ba2                	ld	s7,8(sp)
    80002604:	6161                	addi	sp,sp,80
    80002606:	8082                	ret
        sleep(p, &p->lock); //DOC: wait-sleep
    80002608:	85ca                	mv	a1,s2
    8000260a:	854a                	mv	a0,s2
    8000260c:	00000097          	auipc	ra,0x0
    80002610:	e5e080e7          	jalr	-418(ra) # 8000246a <sleep>
        havekids = 0;
    80002614:	bf25                	j	8000254c <wait+0x38>

0000000080002616 <wakeup>:
{
    80002616:	7139                	addi	sp,sp,-64
    80002618:	fc06                	sd	ra,56(sp)
    8000261a:	f822                	sd	s0,48(sp)
    8000261c:	f426                	sd	s1,40(sp)
    8000261e:	f04a                	sd	s2,32(sp)
    80002620:	ec4e                	sd	s3,24(sp)
    80002622:	e852                	sd	s4,16(sp)
    80002624:	e456                	sd	s5,8(sp)
    80002626:	e05a                	sd	s6,0(sp)
    80002628:	0080                	addi	s0,sp,64
    8000262a:	8a2a                	mv	s4,a0
    for (p = proc; p < &proc[NPROC]; p++)
    8000262c:	00010497          	auipc	s1,0x10
    80002630:	d3c48493          	addi	s1,s1,-708 # 80012368 <proc>
        if (p->state == SLEEPING && p->chan == chan)
    80002634:	4985                	li	s3,1
            p->state = RUNNABLE;
    80002636:	4a89                	li	s5,2
            p->Qinterval[2] = ticks;
    80002638:	00007b17          	auipc	s6,0x7
    8000263c:	9e8b0b13          	addi	s6,s6,-1560 # 80009020 <ticks>
    for (p = proc; p < &proc[NPROC]; p++)
    80002640:	00016917          	auipc	s2,0x16
    80002644:	f2890913          	addi	s2,s2,-216 # 80018568 <tickslock>
    80002648:	a811                	j	8000265c <wakeup+0x46>
        release(&p->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	664080e7          	jalr	1636(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002654:	18848493          	addi	s1,s1,392
    80002658:	05248563          	beq	s1,s2,800026a2 <wakeup+0x8c>
        acquire(&p->lock);
    8000265c:	8526                	mv	a0,s1
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	59e080e7          	jalr	1438(ra) # 80000bfc <acquire>
        if (p->state == SLEEPING && p->chan == chan)
    80002666:	4c9c                	lw	a5,24(s1)
    80002668:	ff3791e3          	bne	a5,s3,8000264a <wakeup+0x34>
    8000266c:	749c                	ld	a5,40(s1)
    8000266e:	fd479ee3          	bne	a5,s4,8000264a <wakeup+0x34>
            p->state = RUNNABLE;
    80002672:	0154ac23          	sw	s5,24(s1)
            movequeue(p, 2, MOVE);
    80002676:	4601                	li	a2,0
    80002678:	85d6                	mv	a1,s5
    8000267a:	8526                	mv	a0,s1
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	2a2080e7          	jalr	674(ra) # 8000191e <movequeue>
            p->Qinterval[2] = ticks;
    80002684:	000b2783          	lw	a5,0(s6)
    80002688:	16f4ae23          	sw	a5,380(s1)
            p->Qinterval[0] = ticks - p->Qinterval[0];
    8000268c:	1744a703          	lw	a4,372(s1)
    80002690:	9f99                	subw	a5,a5,a4
    80002692:	16f4aa23          	sw	a5,372(s1)
            p->Qtime[0] += p->Qinterval[0];
    80002696:	1684a703          	lw	a4,360(s1)
    8000269a:	9fb9                	addw	a5,a5,a4
    8000269c:	16f4a423          	sw	a5,360(s1)
    800026a0:	b76d                	j	8000264a <wakeup+0x34>
}
    800026a2:	70e2                	ld	ra,56(sp)
    800026a4:	7442                	ld	s0,48(sp)
    800026a6:	74a2                	ld	s1,40(sp)
    800026a8:	7902                	ld	s2,32(sp)
    800026aa:	69e2                	ld	s3,24(sp)
    800026ac:	6a42                	ld	s4,16(sp)
    800026ae:	6aa2                	ld	s5,8(sp)
    800026b0:	6b02                	ld	s6,0(sp)
    800026b2:	6121                	addi	sp,sp,64
    800026b4:	8082                	ret

00000000800026b6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026b6:	7179                	addi	sp,sp,-48
    800026b8:	f406                	sd	ra,40(sp)
    800026ba:	f022                	sd	s0,32(sp)
    800026bc:	ec26                	sd	s1,24(sp)
    800026be:	e84a                	sd	s2,16(sp)
    800026c0:	e44e                	sd	s3,8(sp)
    800026c2:	1800                	addi	s0,sp,48
    800026c4:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800026c6:	00010497          	auipc	s1,0x10
    800026ca:	ca248493          	addi	s1,s1,-862 # 80012368 <proc>
    800026ce:	00016997          	auipc	s3,0x16
    800026d2:	e9a98993          	addi	s3,s3,-358 # 80018568 <tickslock>
    {
        acquire(&p->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	524080e7          	jalr	1316(ra) # 80000bfc <acquire>
        if (p->pid == pid)
    800026e0:	5c9c                	lw	a5,56(s1)
    800026e2:	01278d63          	beq	a5,s2,800026fc <kill+0x46>
                movequeue(p, 2, MOVE);
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5c8080e7          	jalr	1480(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800026f0:	18848493          	addi	s1,s1,392
    800026f4:	ff3491e3          	bne	s1,s3,800026d6 <kill+0x20>
    }
    return -1;
    800026f8:	557d                	li	a0,-1
    800026fa:	a821                	j	80002712 <kill+0x5c>
            p->killed = 1;
    800026fc:	4785                	li	a5,1
    800026fe:	d89c                	sw	a5,48(s1)
            if (p->state == SLEEPING)
    80002700:	4c98                	lw	a4,24(s1)
    80002702:	00f70f63          	beq	a4,a5,80002720 <kill+0x6a>
            release(&p->lock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	5a8080e7          	jalr	1448(ra) # 80000cb0 <release>
            return 0;
    80002710:	4501                	li	a0,0
}
    80002712:	70a2                	ld	ra,40(sp)
    80002714:	7402                	ld	s0,32(sp)
    80002716:	64e2                	ld	s1,24(sp)
    80002718:	6942                	ld	s2,16(sp)
    8000271a:	69a2                	ld	s3,8(sp)
    8000271c:	6145                	addi	sp,sp,48
    8000271e:	8082                	ret
                p->state = RUNNABLE;
    80002720:	4789                	li	a5,2
    80002722:	cc9c                	sw	a5,24(s1)
                p->Qinterval[p->priority] = ticks - p->Qinterval[p->priority];
    80002724:	00007617          	auipc	a2,0x7
    80002728:	8fc62603          	lw	a2,-1796(a2) # 80009020 <ticks>
    8000272c:	1804a783          	lw	a5,384(s1)
    80002730:	078a                	slli	a5,a5,0x2
    80002732:	97a6                	add	a5,a5,s1
    80002734:	1747a703          	lw	a4,372(a5)
    80002738:	40e6073b          	subw	a4,a2,a4
    8000273c:	16e7aa23          	sw	a4,372(a5)
                p->Qtime[p->priority] += p->Qinterval[p->priority];
    80002740:	1687a683          	lw	a3,360(a5)
    80002744:	9f35                	addw	a4,a4,a3
    80002746:	16e7a423          	sw	a4,360(a5)
                p->Qinterval[2] = ticks;
    8000274a:	16c4ae23          	sw	a2,380(s1)
                movequeue(p, 2, MOVE);
    8000274e:	4601                	li	a2,0
    80002750:	4589                	li	a1,2
    80002752:	8526                	mv	a0,s1
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	1ca080e7          	jalr	458(ra) # 8000191e <movequeue>
    8000275c:	b76d                	j	80002706 <kill+0x50>

000000008000275e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000275e:	7179                	addi	sp,sp,-48
    80002760:	f406                	sd	ra,40(sp)
    80002762:	f022                	sd	s0,32(sp)
    80002764:	ec26                	sd	s1,24(sp)
    80002766:	e84a                	sd	s2,16(sp)
    80002768:	e44e                	sd	s3,8(sp)
    8000276a:	e052                	sd	s4,0(sp)
    8000276c:	1800                	addi	s0,sp,48
    8000276e:	84aa                	mv	s1,a0
    80002770:	892e                	mv	s2,a1
    80002772:	89b2                	mv	s3,a2
    80002774:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002776:	fffff097          	auipc	ra,0xfffff
    8000277a:	3be080e7          	jalr	958(ra) # 80001b34 <myproc>
    if (user_dst)
    8000277e:	c08d                	beqz	s1,800027a0 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002780:	86d2                	mv	a3,s4
    80002782:	864e                	mv	a2,s3
    80002784:	85ca                	mv	a1,s2
    80002786:	6928                	ld	a0,80(a0)
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	f22080e7          	jalr	-222(ra) # 800016aa <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002790:	70a2                	ld	ra,40(sp)
    80002792:	7402                	ld	s0,32(sp)
    80002794:	64e2                	ld	s1,24(sp)
    80002796:	6942                	ld	s2,16(sp)
    80002798:	69a2                	ld	s3,8(sp)
    8000279a:	6a02                	ld	s4,0(sp)
    8000279c:	6145                	addi	sp,sp,48
    8000279e:	8082                	ret
        memmove((char *)dst, src, len);
    800027a0:	000a061b          	sext.w	a2,s4
    800027a4:	85ce                	mv	a1,s3
    800027a6:	854a                	mv	a0,s2
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	5ac080e7          	jalr	1452(ra) # 80000d54 <memmove>
        return 0;
    800027b0:	8526                	mv	a0,s1
    800027b2:	bff9                	j	80002790 <either_copyout+0x32>

00000000800027b4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027b4:	7179                	addi	sp,sp,-48
    800027b6:	f406                	sd	ra,40(sp)
    800027b8:	f022                	sd	s0,32(sp)
    800027ba:	ec26                	sd	s1,24(sp)
    800027bc:	e84a                	sd	s2,16(sp)
    800027be:	e44e                	sd	s3,8(sp)
    800027c0:	e052                	sd	s4,0(sp)
    800027c2:	1800                	addi	s0,sp,48
    800027c4:	892a                	mv	s2,a0
    800027c6:	84ae                	mv	s1,a1
    800027c8:	89b2                	mv	s3,a2
    800027ca:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	368080e7          	jalr	872(ra) # 80001b34 <myproc>
    if (user_src)
    800027d4:	c08d                	beqz	s1,800027f6 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800027d6:	86d2                	mv	a3,s4
    800027d8:	864e                	mv	a2,s3
    800027da:	85ca                	mv	a1,s2
    800027dc:	6928                	ld	a0,80(a0)
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	f58080e7          	jalr	-168(ra) # 80001736 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800027e6:	70a2                	ld	ra,40(sp)
    800027e8:	7402                	ld	s0,32(sp)
    800027ea:	64e2                	ld	s1,24(sp)
    800027ec:	6942                	ld	s2,16(sp)
    800027ee:	69a2                	ld	s3,8(sp)
    800027f0:	6a02                	ld	s4,0(sp)
    800027f2:	6145                	addi	sp,sp,48
    800027f4:	8082                	ret
        memmove(dst, (char *)src, len);
    800027f6:	000a061b          	sext.w	a2,s4
    800027fa:	85ce                	mv	a1,s3
    800027fc:	854a                	mv	a0,s2
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	556080e7          	jalr	1366(ra) # 80000d54 <memmove>
        return 0;
    80002806:	8526                	mv	a0,s1
    80002808:	bff9                	j	800027e6 <either_copyin+0x32>

000000008000280a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000280a:	715d                	addi	sp,sp,-80
    8000280c:	e486                	sd	ra,72(sp)
    8000280e:	e0a2                	sd	s0,64(sp)
    80002810:	fc26                	sd	s1,56(sp)
    80002812:	f84a                	sd	s2,48(sp)
    80002814:	f44e                	sd	s3,40(sp)
    80002816:	f052                	sd	s4,32(sp)
    80002818:	ec56                	sd	s5,24(sp)
    8000281a:	e85a                	sd	s6,16(sp)
    8000281c:	e45e                	sd	s7,8(sp)
    8000281e:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002820:	00006517          	auipc	a0,0x6
    80002824:	8c850513          	addi	a0,a0,-1848 # 800080e8 <digits+0xa8>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	d62080e7          	jalr	-670(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002830:	00010497          	auipc	s1,0x10
    80002834:	c9048493          	addi	s1,s1,-880 # 800124c0 <proc+0x158>
    80002838:	00016917          	auipc	s2,0x16
    8000283c:	e8890913          	addi	s2,s2,-376 # 800186c0 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002840:	4b11                	li	s6,4
            state = states[p->state];
        else
            state = "???";
    80002842:	00006997          	auipc	s3,0x6
    80002846:	a7698993          	addi	s3,s3,-1418 # 800082b8 <digits+0x278>
        printf("%d %s %s", p->pid, state, p->name);
    8000284a:	00006a97          	auipc	s5,0x6
    8000284e:	a76a8a93          	addi	s5,s5,-1418 # 800082c0 <digits+0x280>
        printf("\n");
    80002852:	00006a17          	auipc	s4,0x6
    80002856:	896a0a13          	addi	s4,s4,-1898 # 800080e8 <digits+0xa8>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285a:	00006b97          	auipc	s7,0x6
    8000285e:	a9eb8b93          	addi	s7,s7,-1378 # 800082f8 <states.0>
    80002862:	a00d                	j	80002884 <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    80002864:	ee06a583          	lw	a1,-288(a3)
    80002868:	8556                	mv	a0,s5
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	d20080e7          	jalr	-736(ra) # 8000058a <printf>
        printf("\n");
    80002872:	8552                	mv	a0,s4
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	d16080e7          	jalr	-746(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000287c:	18848493          	addi	s1,s1,392
    80002880:	03248163          	beq	s1,s2,800028a2 <procdump+0x98>
        if (p->state == UNUSED)
    80002884:	86a6                	mv	a3,s1
    80002886:	ec04a783          	lw	a5,-320(s1)
    8000288a:	dbed                	beqz	a5,8000287c <procdump+0x72>
            state = "???";
    8000288c:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288e:	fcfb6be3          	bltu	s6,a5,80002864 <procdump+0x5a>
    80002892:	1782                	slli	a5,a5,0x20
    80002894:	9381                	srli	a5,a5,0x20
    80002896:	078e                	slli	a5,a5,0x3
    80002898:	97de                	add	a5,a5,s7
    8000289a:	6390                	ld	a2,0(a5)
    8000289c:	f661                	bnez	a2,80002864 <procdump+0x5a>
            state = "???";
    8000289e:	864e                	mv	a2,s3
    800028a0:	b7d1                	j	80002864 <procdump+0x5a>
    }
}
    800028a2:	60a6                	ld	ra,72(sp)
    800028a4:	6406                	ld	s0,64(sp)
    800028a6:	74e2                	ld	s1,56(sp)
    800028a8:	7942                	ld	s2,48(sp)
    800028aa:	79a2                	ld	s3,40(sp)
    800028ac:	7a02                	ld	s4,32(sp)
    800028ae:	6ae2                	ld	s5,24(sp)
    800028b0:	6b42                	ld	s6,16(sp)
    800028b2:	6ba2                	ld	s7,8(sp)
    800028b4:	6161                	addi	sp,sp,80
    800028b6:	8082                	ret

00000000800028b8 <swtch>:
    800028b8:	00153023          	sd	ra,0(a0)
    800028bc:	00253423          	sd	sp,8(a0)
    800028c0:	e900                	sd	s0,16(a0)
    800028c2:	ed04                	sd	s1,24(a0)
    800028c4:	03253023          	sd	s2,32(a0)
    800028c8:	03353423          	sd	s3,40(a0)
    800028cc:	03453823          	sd	s4,48(a0)
    800028d0:	03553c23          	sd	s5,56(a0)
    800028d4:	05653023          	sd	s6,64(a0)
    800028d8:	05753423          	sd	s7,72(a0)
    800028dc:	05853823          	sd	s8,80(a0)
    800028e0:	05953c23          	sd	s9,88(a0)
    800028e4:	07a53023          	sd	s10,96(a0)
    800028e8:	07b53423          	sd	s11,104(a0)
    800028ec:	0005b083          	ld	ra,0(a1)
    800028f0:	0085b103          	ld	sp,8(a1)
    800028f4:	6980                	ld	s0,16(a1)
    800028f6:	6d84                	ld	s1,24(a1)
    800028f8:	0205b903          	ld	s2,32(a1)
    800028fc:	0285b983          	ld	s3,40(a1)
    80002900:	0305ba03          	ld	s4,48(a1)
    80002904:	0385ba83          	ld	s5,56(a1)
    80002908:	0405bb03          	ld	s6,64(a1)
    8000290c:	0485bb83          	ld	s7,72(a1)
    80002910:	0505bc03          	ld	s8,80(a1)
    80002914:	0585bc83          	ld	s9,88(a1)
    80002918:	0605bd03          	ld	s10,96(a1)
    8000291c:	0685bd83          	ld	s11,104(a1)
    80002920:	8082                	ret

0000000080002922 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002922:	1141                	addi	sp,sp,-16
    80002924:	e406                	sd	ra,8(sp)
    80002926:	e022                	sd	s0,0(sp)
    80002928:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000292a:	00006597          	auipc	a1,0x6
    8000292e:	9f658593          	addi	a1,a1,-1546 # 80008320 <states.0+0x28>
    80002932:	00016517          	auipc	a0,0x16
    80002936:	c3650513          	addi	a0,a0,-970 # 80018568 <tickslock>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	232080e7          	jalr	562(ra) # 80000b6c <initlock>
}
    80002942:	60a2                	ld	ra,8(sp)
    80002944:	6402                	ld	s0,0(sp)
    80002946:	0141                	addi	sp,sp,16
    80002948:	8082                	ret

000000008000294a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000294a:	1141                	addi	sp,sp,-16
    8000294c:	e422                	sd	s0,8(sp)
    8000294e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002950:	00003797          	auipc	a5,0x3
    80002954:	52078793          	addi	a5,a5,1312 # 80005e70 <kernelvec>
    80002958:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000295c:	6422                	ld	s0,8(sp)
    8000295e:	0141                	addi	sp,sp,16
    80002960:	8082                	ret

0000000080002962 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002962:	1141                	addi	sp,sp,-16
    80002964:	e406                	sd	ra,8(sp)
    80002966:	e022                	sd	s0,0(sp)
    80002968:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	1ca080e7          	jalr	458(ra) # 80001b34 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002972:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002976:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002978:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000297c:	00004617          	auipc	a2,0x4
    80002980:	68460613          	addi	a2,a2,1668 # 80007000 <_trampoline>
    80002984:	00004697          	auipc	a3,0x4
    80002988:	67c68693          	addi	a3,a3,1660 # 80007000 <_trampoline>
    8000298c:	8e91                	sub	a3,a3,a2
    8000298e:	040007b7          	lui	a5,0x4000
    80002992:	17fd                	addi	a5,a5,-1
    80002994:	07b2                	slli	a5,a5,0xc
    80002996:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002998:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000299c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000299e:	180026f3          	csrr	a3,satp
    800029a2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029a4:	6d38                	ld	a4,88(a0)
    800029a6:	6134                	ld	a3,64(a0)
    800029a8:	6585                	lui	a1,0x1
    800029aa:	96ae                	add	a3,a3,a1
    800029ac:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ae:	6d38                	ld	a4,88(a0)
    800029b0:	00000697          	auipc	a3,0x0
    800029b4:	13868693          	addi	a3,a3,312 # 80002ae8 <usertrap>
    800029b8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029ba:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029bc:	8692                	mv	a3,tp
    800029be:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029c4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029c8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029cc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029d0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d2:	6f18                	ld	a4,24(a4)
    800029d4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029d8:	692c                	ld	a1,80(a0)
    800029da:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029dc:	00004717          	auipc	a4,0x4
    800029e0:	6b470713          	addi	a4,a4,1716 # 80007090 <userret>
    800029e4:	8f11                	sub	a4,a4,a2
    800029e6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029e8:	577d                	li	a4,-1
    800029ea:	177e                	slli	a4,a4,0x3f
    800029ec:	8dd9                	or	a1,a1,a4
    800029ee:	02000537          	lui	a0,0x2000
    800029f2:	157d                	addi	a0,a0,-1
    800029f4:	0536                	slli	a0,a0,0xd
    800029f6:	9782                	jalr	a5
}
    800029f8:	60a2                	ld	ra,8(sp)
    800029fa:	6402                	ld	s0,0(sp)
    800029fc:	0141                	addi	sp,sp,16
    800029fe:	8082                	ret

0000000080002a00 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a00:	1101                	addi	sp,sp,-32
    80002a02:	ec06                	sd	ra,24(sp)
    80002a04:	e822                	sd	s0,16(sp)
    80002a06:	e426                	sd	s1,8(sp)
    80002a08:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a0a:	00016497          	auipc	s1,0x16
    80002a0e:	b5e48493          	addi	s1,s1,-1186 # 80018568 <tickslock>
    80002a12:	8526                	mv	a0,s1
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	1e8080e7          	jalr	488(ra) # 80000bfc <acquire>
  ticks++;
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	60450513          	addi	a0,a0,1540 # 80009020 <ticks>
    80002a24:	411c                	lw	a5,0(a0)
    80002a26:	2785                	addiw	a5,a5,1
    80002a28:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	bec080e7          	jalr	-1044(ra) # 80002616 <wakeup>
  release(&tickslock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	27c080e7          	jalr	636(ra) # 80000cb0 <release>
}
    80002a3c:	60e2                	ld	ra,24(sp)
    80002a3e:	6442                	ld	s0,16(sp)
    80002a40:	64a2                	ld	s1,8(sp)
    80002a42:	6105                	addi	sp,sp,32
    80002a44:	8082                	ret

0000000080002a46 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a50:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a54:	00074d63          	bltz	a4,80002a6e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a58:	57fd                	li	a5,-1
    80002a5a:	17fe                	slli	a5,a5,0x3f
    80002a5c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a5e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a60:	06f70363          	beq	a4,a5,80002ac6 <devintr+0x80>
  }
}
    80002a64:	60e2                	ld	ra,24(sp)
    80002a66:	6442                	ld	s0,16(sp)
    80002a68:	64a2                	ld	s1,8(sp)
    80002a6a:	6105                	addi	sp,sp,32
    80002a6c:	8082                	ret
     (scause & 0xff) == 9){
    80002a6e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a72:	46a5                	li	a3,9
    80002a74:	fed792e3          	bne	a5,a3,80002a58 <devintr+0x12>
    int irq = plic_claim();
    80002a78:	00003097          	auipc	ra,0x3
    80002a7c:	500080e7          	jalr	1280(ra) # 80005f78 <plic_claim>
    80002a80:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a82:	47a9                	li	a5,10
    80002a84:	02f50763          	beq	a0,a5,80002ab2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a88:	4785                	li	a5,1
    80002a8a:	02f50963          	beq	a0,a5,80002abc <devintr+0x76>
    return 1;
    80002a8e:	4505                	li	a0,1
    } else if(irq){
    80002a90:	d8f1                	beqz	s1,80002a64 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a92:	85a6                	mv	a1,s1
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	89450513          	addi	a0,a0,-1900 # 80008328 <states.0+0x30>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aee080e7          	jalr	-1298(ra) # 8000058a <printf>
      plic_complete(irq);
    80002aa4:	8526                	mv	a0,s1
    80002aa6:	00003097          	auipc	ra,0x3
    80002aaa:	4f6080e7          	jalr	1270(ra) # 80005f9c <plic_complete>
    return 1;
    80002aae:	4505                	li	a0,1
    80002ab0:	bf55                	j	80002a64 <devintr+0x1e>
      uartintr();
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	f0e080e7          	jalr	-242(ra) # 800009c0 <uartintr>
    80002aba:	b7ed                	j	80002aa4 <devintr+0x5e>
      virtio_disk_intr();
    80002abc:	00004097          	auipc	ra,0x4
    80002ac0:	95a080e7          	jalr	-1702(ra) # 80006416 <virtio_disk_intr>
    80002ac4:	b7c5                	j	80002aa4 <devintr+0x5e>
    if(cpuid() == 0){
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	042080e7          	jalr	66(ra) # 80001b08 <cpuid>
    80002ace:	c901                	beqz	a0,80002ade <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ad0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ad4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ad6:	14479073          	csrw	sip,a5
    return 2;
    80002ada:	4509                	li	a0,2
    80002adc:	b761                	j	80002a64 <devintr+0x1e>
      clockintr();
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	f22080e7          	jalr	-222(ra) # 80002a00 <clockintr>
    80002ae6:	b7ed                	j	80002ad0 <devintr+0x8a>

0000000080002ae8 <usertrap>:
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	e04a                	sd	s2,0(sp)
    80002af2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002af8:	1007f793          	andi	a5,a5,256
    80002afc:	e3ad                	bnez	a5,80002b5e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002afe:	00003797          	auipc	a5,0x3
    80002b02:	37278793          	addi	a5,a5,882 # 80005e70 <kernelvec>
    80002b06:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	02a080e7          	jalr	42(ra) # 80001b34 <myproc>
    80002b12:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b14:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b16:	14102773          	csrr	a4,sepc
    80002b1a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b20:	47a1                	li	a5,8
    80002b22:	04f71c63          	bne	a4,a5,80002b7a <usertrap+0x92>
    if(p->killed)
    80002b26:	591c                	lw	a5,48(a0)
    80002b28:	e3b9                	bnez	a5,80002b6e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b2a:	6cb8                	ld	a4,88(s1)
    80002b2c:	6f1c                	ld	a5,24(a4)
    80002b2e:	0791                	addi	a5,a5,4
    80002b30:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b36:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b3e:	00000097          	auipc	ra,0x0
    80002b42:	2f8080e7          	jalr	760(ra) # 80002e36 <syscall>
  if(p->killed)
    80002b46:	589c                	lw	a5,48(s1)
    80002b48:	ebc1                	bnez	a5,80002bd8 <usertrap+0xf0>
  usertrapret();
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	e18080e7          	jalr	-488(ra) # 80002962 <usertrapret>
}
    80002b52:	60e2                	ld	ra,24(sp)
    80002b54:	6442                	ld	s0,16(sp)
    80002b56:	64a2                	ld	s1,8(sp)
    80002b58:	6902                	ld	s2,0(sp)
    80002b5a:	6105                	addi	sp,sp,32
    80002b5c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b5e:	00005517          	auipc	a0,0x5
    80002b62:	7ea50513          	addi	a0,a0,2026 # 80008348 <states.0+0x50>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	9da080e7          	jalr	-1574(ra) # 80000540 <panic>
      exit(-1);
    80002b6e:	557d                	li	a0,-1
    80002b70:	fffff097          	auipc	ra,0xfffff
    80002b74:	742080e7          	jalr	1858(ra) # 800022b2 <exit>
    80002b78:	bf4d                	j	80002b2a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	ecc080e7          	jalr	-308(ra) # 80002a46 <devintr>
    80002b82:	892a                	mv	s2,a0
    80002b84:	c501                	beqz	a0,80002b8c <usertrap+0xa4>
  if(p->killed)
    80002b86:	589c                	lw	a5,48(s1)
    80002b88:	c3a1                	beqz	a5,80002bc8 <usertrap+0xe0>
    80002b8a:	a815                	j	80002bbe <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b90:	5c90                	lw	a2,56(s1)
    80002b92:	00005517          	auipc	a0,0x5
    80002b96:	7d650513          	addi	a0,a0,2006 # 80008368 <states.0+0x70>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9f0080e7          	jalr	-1552(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ba6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002baa:	00005517          	auipc	a0,0x5
    80002bae:	7ee50513          	addi	a0,a0,2030 # 80008398 <states.0+0xa0>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	9d8080e7          	jalr	-1576(ra) # 8000058a <printf>
    p->killed = 1;
    80002bba:	4785                	li	a5,1
    80002bbc:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002bbe:	557d                	li	a0,-1
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	6f2080e7          	jalr	1778(ra) # 800022b2 <exit>
  if(which_dev == 2)
    80002bc8:	4789                	li	a5,2
    80002bca:	f8f910e3          	bne	s2,a5,80002b4a <usertrap+0x62>
    yield();
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	826080e7          	jalr	-2010(ra) # 800023f4 <yield>
    80002bd6:	bf95                	j	80002b4a <usertrap+0x62>
  int which_dev = 0;
    80002bd8:	4901                	li	s2,0
    80002bda:	b7d5                	j	80002bbe <usertrap+0xd6>

0000000080002bdc <kerneltrap>:
{
    80002bdc:	7179                	addi	sp,sp,-48
    80002bde:	f406                	sd	ra,40(sp)
    80002be0:	f022                	sd	s0,32(sp)
    80002be2:	ec26                	sd	s1,24(sp)
    80002be4:	e84a                	sd	s2,16(sp)
    80002be6:	e44e                	sd	s3,8(sp)
    80002be8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bea:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bee:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bf6:	1004f793          	andi	a5,s1,256
    80002bfa:	cb85                	beqz	a5,80002c2a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c00:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c02:	ef85                	bnez	a5,80002c3a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	e42080e7          	jalr	-446(ra) # 80002a46 <devintr>
    80002c0c:	cd1d                	beqz	a0,80002c4a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c0e:	4789                	li	a5,2
    80002c10:	08f50663          	beq	a0,a5,80002c9c <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c14:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c18:	10049073          	csrw	sstatus,s1
}
    80002c1c:	70a2                	ld	ra,40(sp)
    80002c1e:	7402                	ld	s0,32(sp)
    80002c20:	64e2                	ld	s1,24(sp)
    80002c22:	6942                	ld	s2,16(sp)
    80002c24:	69a2                	ld	s3,8(sp)
    80002c26:	6145                	addi	sp,sp,48
    80002c28:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c2a:	00005517          	auipc	a0,0x5
    80002c2e:	78e50513          	addi	a0,a0,1934 # 800083b8 <states.0+0xc0>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	90e080e7          	jalr	-1778(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c3a:	00005517          	auipc	a0,0x5
    80002c3e:	7a650513          	addi	a0,a0,1958 # 800083e0 <states.0+0xe8>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	8fe080e7          	jalr	-1794(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c4a:	00006597          	auipc	a1,0x6
    80002c4e:	3d65a583          	lw	a1,982(a1) # 80009020 <ticks>
    80002c52:	00006517          	auipc	a0,0x6
    80002c56:	80650513          	addi	a0,a0,-2042 # 80008458 <states.0+0x160>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	930080e7          	jalr	-1744(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002c62:	85ce                	mv	a1,s3
    80002c64:	00005517          	auipc	a0,0x5
    80002c68:	79c50513          	addi	a0,a0,1948 # 80008400 <states.0+0x108>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	91e080e7          	jalr	-1762(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c78:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c7c:	00005517          	auipc	a0,0x5
    80002c80:	79450513          	addi	a0,a0,1940 # 80008410 <states.0+0x118>
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	906080e7          	jalr	-1786(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	79c50513          	addi	a0,a0,1948 # 80008428 <states.0+0x130>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	e98080e7          	jalr	-360(ra) # 80001b34 <myproc>
    80002ca4:	d925                	beqz	a0,80002c14 <kerneltrap+0x38>
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	e8e080e7          	jalr	-370(ra) # 80001b34 <myproc>
    80002cae:	4d18                	lw	a4,24(a0)
    80002cb0:	478d                	li	a5,3
    80002cb2:	f6f711e3          	bne	a4,a5,80002c14 <kerneltrap+0x38>
    yield();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	73e080e7          	jalr	1854(ra) # 800023f4 <yield>
    80002cbe:	bf99                	j	80002c14 <kerneltrap+0x38>

0000000080002cc0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	1000                	addi	s0,sp,32
    80002cca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	e68080e7          	jalr	-408(ra) # 80001b34 <myproc>
  switch (n)
    80002cd4:	4795                	li	a5,5
    80002cd6:	0497e163          	bltu	a5,s1,80002d18 <argraw+0x58>
    80002cda:	048a                	slli	s1,s1,0x2
    80002cdc:	00005717          	auipc	a4,0x5
    80002ce0:	78470713          	addi	a4,a4,1924 # 80008460 <states.0+0x168>
    80002ce4:	94ba                	add	s1,s1,a4
    80002ce6:	409c                	lw	a5,0(s1)
    80002ce8:	97ba                	add	a5,a5,a4
    80002cea:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002cec:	6d3c                	ld	a5,88(a0)
    80002cee:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6105                	addi	sp,sp,32
    80002cf8:	8082                	ret
    return p->trapframe->a1;
    80002cfa:	6d3c                	ld	a5,88(a0)
    80002cfc:	7fa8                	ld	a0,120(a5)
    80002cfe:	bfcd                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a2;
    80002d00:	6d3c                	ld	a5,88(a0)
    80002d02:	63c8                	ld	a0,128(a5)
    80002d04:	b7f5                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a3;
    80002d06:	6d3c                	ld	a5,88(a0)
    80002d08:	67c8                	ld	a0,136(a5)
    80002d0a:	b7dd                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a4;
    80002d0c:	6d3c                	ld	a5,88(a0)
    80002d0e:	6bc8                	ld	a0,144(a5)
    80002d10:	b7c5                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a5;
    80002d12:	6d3c                	ld	a5,88(a0)
    80002d14:	6fc8                	ld	a0,152(a5)
    80002d16:	bfe9                	j	80002cf0 <argraw+0x30>
  panic("argraw");
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	72050513          	addi	a0,a0,1824 # 80008438 <states.0+0x140>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	820080e7          	jalr	-2016(ra) # 80000540 <panic>

0000000080002d28 <fetchaddr>:
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	e04a                	sd	s2,0(sp)
    80002d32:	1000                	addi	s0,sp,32
    80002d34:	84aa                	mv	s1,a0
    80002d36:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	dfc080e7          	jalr	-516(ra) # 80001b34 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d40:	653c                	ld	a5,72(a0)
    80002d42:	02f4f863          	bgeu	s1,a5,80002d72 <fetchaddr+0x4a>
    80002d46:	00848713          	addi	a4,s1,8
    80002d4a:	02e7e663          	bltu	a5,a4,80002d76 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d4e:	46a1                	li	a3,8
    80002d50:	8626                	mv	a2,s1
    80002d52:	85ca                	mv	a1,s2
    80002d54:	6928                	ld	a0,80(a0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	9e0080e7          	jalr	-1568(ra) # 80001736 <copyin>
    80002d5e:	00a03533          	snez	a0,a0
    80002d62:	40a00533          	neg	a0,a0
}
    80002d66:	60e2                	ld	ra,24(sp)
    80002d68:	6442                	ld	s0,16(sp)
    80002d6a:	64a2                	ld	s1,8(sp)
    80002d6c:	6902                	ld	s2,0(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret
    return -1;
    80002d72:	557d                	li	a0,-1
    80002d74:	bfcd                	j	80002d66 <fetchaddr+0x3e>
    80002d76:	557d                	li	a0,-1
    80002d78:	b7fd                	j	80002d66 <fetchaddr+0x3e>

0000000080002d7a <fetchstr>:
{
    80002d7a:	7179                	addi	sp,sp,-48
    80002d7c:	f406                	sd	ra,40(sp)
    80002d7e:	f022                	sd	s0,32(sp)
    80002d80:	ec26                	sd	s1,24(sp)
    80002d82:	e84a                	sd	s2,16(sp)
    80002d84:	e44e                	sd	s3,8(sp)
    80002d86:	1800                	addi	s0,sp,48
    80002d88:	892a                	mv	s2,a0
    80002d8a:	84ae                	mv	s1,a1
    80002d8c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	da6080e7          	jalr	-602(ra) # 80001b34 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d96:	86ce                	mv	a3,s3
    80002d98:	864a                	mv	a2,s2
    80002d9a:	85a6                	mv	a1,s1
    80002d9c:	6928                	ld	a0,80(a0)
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	a26080e7          	jalr	-1498(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002da6:	00054763          	bltz	a0,80002db4 <fetchstr+0x3a>
  return strlen(buf);
    80002daa:	8526                	mv	a0,s1
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	0d0080e7          	jalr	208(ra) # 80000e7c <strlen>
}
    80002db4:	70a2                	ld	ra,40(sp)
    80002db6:	7402                	ld	s0,32(sp)
    80002db8:	64e2                	ld	s1,24(sp)
    80002dba:	6942                	ld	s2,16(sp)
    80002dbc:	69a2                	ld	s3,8(sp)
    80002dbe:	6145                	addi	sp,sp,48
    80002dc0:	8082                	ret

0000000080002dc2 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002dc2:	1101                	addi	sp,sp,-32
    80002dc4:	ec06                	sd	ra,24(sp)
    80002dc6:	e822                	sd	s0,16(sp)
    80002dc8:	e426                	sd	s1,8(sp)
    80002dca:	1000                	addi	s0,sp,32
    80002dcc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	ef2080e7          	jalr	-270(ra) # 80002cc0 <argraw>
    80002dd6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dd8:	4501                	li	a0,0
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret

0000000080002de4 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	e426                	sd	s1,8(sp)
    80002dec:	1000                	addi	s0,sp,32
    80002dee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	ed0080e7          	jalr	-304(ra) # 80002cc0 <argraw>
    80002df8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dfa:	4501                	li	a0,0
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	e04a                	sd	s2,0(sp)
    80002e10:	1000                	addi	s0,sp,32
    80002e12:	84ae                	mv	s1,a1
    80002e14:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	eaa080e7          	jalr	-342(ra) # 80002cc0 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e1e:	864a                	mv	a2,s2
    80002e20:	85a6                	mv	a1,s1
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	f58080e7          	jalr	-168(ra) # 80002d7a <fetchstr>
}
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6902                	ld	s2,0(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	e426                	sd	s1,8(sp)
    80002e3e:	e04a                	sd	s2,0(sp)
    80002e40:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	cf2080e7          	jalr	-782(ra) # 80001b34 <myproc>
    80002e4a:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process
  if (p->priority != 2) 
    80002e4c:	18052703          	lw	a4,384(a0)
    80002e50:	4789                	li	a5,2
    80002e52:	02f71963          	bne	a4,a5,80002e84 <syscall+0x4e>
    p->Qtime[1] += p->Qinterval[1];
    
    release(&p->lock);
  }

  num = p->trapframe->a7;
    80002e56:	0584b903          	ld	s2,88(s1)
    80002e5a:	0a893783          	ld	a5,168(s2)
    80002e5e:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e62:	37fd                	addiw	a5,a5,-1
    80002e64:	4751                	li	a4,20
    80002e66:	06f76063          	bltu	a4,a5,80002ec6 <syscall+0x90>
    80002e6a:	00369713          	slli	a4,a3,0x3
    80002e6e:	00005797          	auipc	a5,0x5
    80002e72:	60a78793          	addi	a5,a5,1546 # 80008478 <syscalls>
    80002e76:	97ba                	add	a5,a5,a4
    80002e78:	639c                	ld	a5,0(a5)
    80002e7a:	c7b1                	beqz	a5,80002ec6 <syscall+0x90>
  {
    p->trapframe->a0 = syscalls[num]();
    80002e7c:	9782                	jalr	a5
    80002e7e:	06a93823          	sd	a0,112(s2)
    80002e82:	a085                	j	80002ee2 <syscall+0xac>
    acquire(&p->lock);
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	d78080e7          	jalr	-648(ra) # 80000bfc <acquire>
    movequeue(p, 2, 0);
    80002e8c:	4601                	li	a2,0
    80002e8e:	4589                	li	a1,2
    80002e90:	8526                	mv	a0,s1
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	a8c080e7          	jalr	-1396(ra) # 8000191e <movequeue>
    p->Qinterval[2] = ticks;
    80002e9a:	00006797          	auipc	a5,0x6
    80002e9e:	1867a783          	lw	a5,390(a5) # 80009020 <ticks>
    80002ea2:	16f4ae23          	sw	a5,380(s1)
    p->Qinterval[1] = ticks - p->Qinterval[1];
    80002ea6:	1784a703          	lw	a4,376(s1)
    80002eaa:	9f99                	subw	a5,a5,a4
    80002eac:	16f4ac23          	sw	a5,376(s1)
    p->Qtime[1] += p->Qinterval[1];
    80002eb0:	16c4a703          	lw	a4,364(s1)
    80002eb4:	9fb9                	addw	a5,a5,a4
    80002eb6:	16f4a623          	sw	a5,364(s1)
    release(&p->lock);
    80002eba:	8526                	mv	a0,s1
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	df4080e7          	jalr	-524(ra) # 80000cb0 <release>
    80002ec4:	bf49                	j	80002e56 <syscall+0x20>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002ec6:	15848613          	addi	a2,s1,344
    80002eca:	5c8c                	lw	a1,56(s1)
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	57450513          	addi	a0,a0,1396 # 80008440 <states.0+0x148>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6b6080e7          	jalr	1718(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002edc:	6cbc                	ld	a5,88(s1)
    80002ede:	577d                	li	a4,-1
    80002ee0:	fbb8                	sd	a4,112(a5)
  }
}
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	64a2                	ld	s1,8(sp)
    80002ee8:	6902                	ld	s2,0(sp)
    80002eea:	6105                	addi	sp,sp,32
    80002eec:	8082                	ret

0000000080002eee <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eee:	1101                	addi	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ef6:	fec40593          	addi	a1,s0,-20
    80002efa:	4501                	li	a0,0
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	ec6080e7          	jalr	-314(ra) # 80002dc2 <argint>
    return -1;
    80002f04:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f06:	00054963          	bltz	a0,80002f18 <sys_exit+0x2a>
  exit(n);
    80002f0a:	fec42503          	lw	a0,-20(s0)
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	3a4080e7          	jalr	932(ra) # 800022b2 <exit>
  return 0;  // not reached
    80002f16:	4781                	li	a5,0
}
    80002f18:	853e                	mv	a0,a5
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	6105                	addi	sp,sp,32
    80002f20:	8082                	ret

0000000080002f22 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f22:	1141                	addi	sp,sp,-16
    80002f24:	e406                	sd	ra,8(sp)
    80002f26:	e022                	sd	s0,0(sp)
    80002f28:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	c0a080e7          	jalr	-1014(ra) # 80001b34 <myproc>
}
    80002f32:	5d08                	lw	a0,56(a0)
    80002f34:	60a2                	ld	ra,8(sp)
    80002f36:	6402                	ld	s0,0(sp)
    80002f38:	0141                	addi	sp,sp,16
    80002f3a:	8082                	ret

0000000080002f3c <sys_fork>:

uint64
sys_fork(void)
{
    80002f3c:	1141                	addi	sp,sp,-16
    80002f3e:	e406                	sd	ra,8(sp)
    80002f40:	e022                	sd	s0,0(sp)
    80002f42:	0800                	addi	s0,sp,16
  return fork();
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	020080e7          	jalr	32(ra) # 80001f64 <fork>
}
    80002f4c:	60a2                	ld	ra,8(sp)
    80002f4e:	6402                	ld	s0,0(sp)
    80002f50:	0141                	addi	sp,sp,16
    80002f52:	8082                	ret

0000000080002f54 <sys_wait>:

uint64
sys_wait(void)
{
    80002f54:	1101                	addi	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f5c:	fe840593          	addi	a1,s0,-24
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	e82080e7          	jalr	-382(ra) # 80002de4 <argaddr>
    80002f6a:	87aa                	mv	a5,a0
    return -1;
    80002f6c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f6e:	0007c863          	bltz	a5,80002f7e <sys_wait+0x2a>
  return wait(p);
    80002f72:	fe843503          	ld	a0,-24(s0)
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	59e080e7          	jalr	1438(ra) # 80002514 <wait>
}
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret

0000000080002f86 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f86:	7179                	addi	sp,sp,-48
    80002f88:	f406                	sd	ra,40(sp)
    80002f8a:	f022                	sd	s0,32(sp)
    80002f8c:	ec26                	sd	s1,24(sp)
    80002f8e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f90:	fdc40593          	addi	a1,s0,-36
    80002f94:	4501                	li	a0,0
    80002f96:	00000097          	auipc	ra,0x0
    80002f9a:	e2c080e7          	jalr	-468(ra) # 80002dc2 <argint>
    return -1;
    80002f9e:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fa0:	00054f63          	bltz	a0,80002fbe <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	b90080e7          	jalr	-1136(ra) # 80001b34 <myproc>
    80002fac:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fae:	fdc42503          	lw	a0,-36(s0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	f3e080e7          	jalr	-194(ra) # 80001ef0 <growproc>
    80002fba:	00054863          	bltz	a0,80002fca <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	70a2                	ld	ra,40(sp)
    80002fc2:	7402                	ld	s0,32(sp)
    80002fc4:	64e2                	ld	s1,24(sp)
    80002fc6:	6145                	addi	sp,sp,48
    80002fc8:	8082                	ret
    return -1;
    80002fca:	54fd                	li	s1,-1
    80002fcc:	bfcd                	j	80002fbe <sys_sbrk+0x38>

0000000080002fce <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fce:	7139                	addi	sp,sp,-64
    80002fd0:	fc06                	sd	ra,56(sp)
    80002fd2:	f822                	sd	s0,48(sp)
    80002fd4:	f426                	sd	s1,40(sp)
    80002fd6:	f04a                	sd	s2,32(sp)
    80002fd8:	ec4e                	sd	s3,24(sp)
    80002fda:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fdc:	fcc40593          	addi	a1,s0,-52
    80002fe0:	4501                	li	a0,0
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	de0080e7          	jalr	-544(ra) # 80002dc2 <argint>
    return -1;
    80002fea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fec:	06054563          	bltz	a0,80003056 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ff0:	00015517          	auipc	a0,0x15
    80002ff4:	57850513          	addi	a0,a0,1400 # 80018568 <tickslock>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	c04080e7          	jalr	-1020(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80003000:	00006917          	auipc	s2,0x6
    80003004:	02092903          	lw	s2,32(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003008:	fcc42783          	lw	a5,-52(s0)
    8000300c:	cf85                	beqz	a5,80003044 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000300e:	00015997          	auipc	s3,0x15
    80003012:	55a98993          	addi	s3,s3,1370 # 80018568 <tickslock>
    80003016:	00006497          	auipc	s1,0x6
    8000301a:	00a48493          	addi	s1,s1,10 # 80009020 <ticks>
    if(myproc()->killed){
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	b16080e7          	jalr	-1258(ra) # 80001b34 <myproc>
    80003026:	591c                	lw	a5,48(a0)
    80003028:	ef9d                	bnez	a5,80003066 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000302a:	85ce                	mv	a1,s3
    8000302c:	8526                	mv	a0,s1
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	43c080e7          	jalr	1084(ra) # 8000246a <sleep>
  while(ticks - ticks0 < n){
    80003036:	409c                	lw	a5,0(s1)
    80003038:	412787bb          	subw	a5,a5,s2
    8000303c:	fcc42703          	lw	a4,-52(s0)
    80003040:	fce7efe3          	bltu	a5,a4,8000301e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003044:	00015517          	auipc	a0,0x15
    80003048:	52450513          	addi	a0,a0,1316 # 80018568 <tickslock>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c64080e7          	jalr	-924(ra) # 80000cb0 <release>
  return 0;
    80003054:	4781                	li	a5,0
}
    80003056:	853e                	mv	a0,a5
    80003058:	70e2                	ld	ra,56(sp)
    8000305a:	7442                	ld	s0,48(sp)
    8000305c:	74a2                	ld	s1,40(sp)
    8000305e:	7902                	ld	s2,32(sp)
    80003060:	69e2                	ld	s3,24(sp)
    80003062:	6121                	addi	sp,sp,64
    80003064:	8082                	ret
      release(&tickslock);
    80003066:	00015517          	auipc	a0,0x15
    8000306a:	50250513          	addi	a0,a0,1282 # 80018568 <tickslock>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	c42080e7          	jalr	-958(ra) # 80000cb0 <release>
      return -1;
    80003076:	57fd                	li	a5,-1
    80003078:	bff9                	j	80003056 <sys_sleep+0x88>

000000008000307a <sys_kill>:

uint64
sys_kill(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003082:	fec40593          	addi	a1,s0,-20
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	d3a080e7          	jalr	-710(ra) # 80002dc2 <argint>
    80003090:	87aa                	mv	a5,a0
    return -1;
    80003092:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003094:	0007c863          	bltz	a5,800030a4 <sys_kill+0x2a>
  return kill(pid);
    80003098:	fec42503          	lw	a0,-20(s0)
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	61a080e7          	jalr	1562(ra) # 800026b6 <kill>
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030ac:	1101                	addi	sp,sp,-32
    800030ae:	ec06                	sd	ra,24(sp)
    800030b0:	e822                	sd	s0,16(sp)
    800030b2:	e426                	sd	s1,8(sp)
    800030b4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030b6:	00015517          	auipc	a0,0x15
    800030ba:	4b250513          	addi	a0,a0,1202 # 80018568 <tickslock>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	b3e080e7          	jalr	-1218(ra) # 80000bfc <acquire>
  xticks = ticks;
    800030c6:	00006497          	auipc	s1,0x6
    800030ca:	f5a4a483          	lw	s1,-166(s1) # 80009020 <ticks>
  release(&tickslock);
    800030ce:	00015517          	auipc	a0,0x15
    800030d2:	49a50513          	addi	a0,a0,1178 # 80018568 <tickslock>
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	bda080e7          	jalr	-1062(ra) # 80000cb0 <release>
  return xticks;
}
    800030de:	02049513          	slli	a0,s1,0x20
    800030e2:	9101                	srli	a0,a0,0x20
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030ee:	7179                	addi	sp,sp,-48
    800030f0:	f406                	sd	ra,40(sp)
    800030f2:	f022                	sd	s0,32(sp)
    800030f4:	ec26                	sd	s1,24(sp)
    800030f6:	e84a                	sd	s2,16(sp)
    800030f8:	e44e                	sd	s3,8(sp)
    800030fa:	e052                	sd	s4,0(sp)
    800030fc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030fe:	00005597          	auipc	a1,0x5
    80003102:	42a58593          	addi	a1,a1,1066 # 80008528 <syscalls+0xb0>
    80003106:	00015517          	auipc	a0,0x15
    8000310a:	47a50513          	addi	a0,a0,1146 # 80018580 <bcache>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	a5e080e7          	jalr	-1442(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003116:	0001d797          	auipc	a5,0x1d
    8000311a:	46a78793          	addi	a5,a5,1130 # 80020580 <bcache+0x8000>
    8000311e:	0001d717          	auipc	a4,0x1d
    80003122:	6ca70713          	addi	a4,a4,1738 # 800207e8 <bcache+0x8268>
    80003126:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000312a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000312e:	00015497          	auipc	s1,0x15
    80003132:	46a48493          	addi	s1,s1,1130 # 80018598 <bcache+0x18>
    b->next = bcache.head.next;
    80003136:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003138:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000313a:	00005a17          	auipc	s4,0x5
    8000313e:	3f6a0a13          	addi	s4,s4,1014 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003142:	2b893783          	ld	a5,696(s2)
    80003146:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003148:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000314c:	85d2                	mv	a1,s4
    8000314e:	01048513          	addi	a0,s1,16
    80003152:	00001097          	auipc	ra,0x1
    80003156:	4ac080e7          	jalr	1196(ra) # 800045fe <initsleeplock>
    bcache.head.next->prev = b;
    8000315a:	2b893783          	ld	a5,696(s2)
    8000315e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003160:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003164:	45848493          	addi	s1,s1,1112
    80003168:	fd349de3          	bne	s1,s3,80003142 <binit+0x54>
  }
}
    8000316c:	70a2                	ld	ra,40(sp)
    8000316e:	7402                	ld	s0,32(sp)
    80003170:	64e2                	ld	s1,24(sp)
    80003172:	6942                	ld	s2,16(sp)
    80003174:	69a2                	ld	s3,8(sp)
    80003176:	6a02                	ld	s4,0(sp)
    80003178:	6145                	addi	sp,sp,48
    8000317a:	8082                	ret

000000008000317c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000317c:	7179                	addi	sp,sp,-48
    8000317e:	f406                	sd	ra,40(sp)
    80003180:	f022                	sd	s0,32(sp)
    80003182:	ec26                	sd	s1,24(sp)
    80003184:	e84a                	sd	s2,16(sp)
    80003186:	e44e                	sd	s3,8(sp)
    80003188:	1800                	addi	s0,sp,48
    8000318a:	892a                	mv	s2,a0
    8000318c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000318e:	00015517          	auipc	a0,0x15
    80003192:	3f250513          	addi	a0,a0,1010 # 80018580 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a66080e7          	jalr	-1434(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000319e:	0001d497          	auipc	s1,0x1d
    800031a2:	69a4b483          	ld	s1,1690(s1) # 80020838 <bcache+0x82b8>
    800031a6:	0001d797          	auipc	a5,0x1d
    800031aa:	64278793          	addi	a5,a5,1602 # 800207e8 <bcache+0x8268>
    800031ae:	02f48f63          	beq	s1,a5,800031ec <bread+0x70>
    800031b2:	873e                	mv	a4,a5
    800031b4:	a021                	j	800031bc <bread+0x40>
    800031b6:	68a4                	ld	s1,80(s1)
    800031b8:	02e48a63          	beq	s1,a4,800031ec <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031bc:	449c                	lw	a5,8(s1)
    800031be:	ff279ce3          	bne	a5,s2,800031b6 <bread+0x3a>
    800031c2:	44dc                	lw	a5,12(s1)
    800031c4:	ff3799e3          	bne	a5,s3,800031b6 <bread+0x3a>
      b->refcnt++;
    800031c8:	40bc                	lw	a5,64(s1)
    800031ca:	2785                	addiw	a5,a5,1
    800031cc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ce:	00015517          	auipc	a0,0x15
    800031d2:	3b250513          	addi	a0,a0,946 # 80018580 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	ada080e7          	jalr	-1318(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031de:	01048513          	addi	a0,s1,16
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	456080e7          	jalr	1110(ra) # 80004638 <acquiresleep>
      return b;
    800031ea:	a8b9                	j	80003248 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ec:	0001d497          	auipc	s1,0x1d
    800031f0:	6444b483          	ld	s1,1604(s1) # 80020830 <bcache+0x82b0>
    800031f4:	0001d797          	auipc	a5,0x1d
    800031f8:	5f478793          	addi	a5,a5,1524 # 800207e8 <bcache+0x8268>
    800031fc:	00f48863          	beq	s1,a5,8000320c <bread+0x90>
    80003200:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	cf81                	beqz	a5,8000321c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003206:	64a4                	ld	s1,72(s1)
    80003208:	fee49de3          	bne	s1,a4,80003202 <bread+0x86>
  panic("bget: no buffers");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	32c50513          	addi	a0,a0,812 # 80008538 <syscalls+0xc0>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	32c080e7          	jalr	812(ra) # 80000540 <panic>
      b->dev = dev;
    8000321c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003220:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003224:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003228:	4785                	li	a5,1
    8000322a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000322c:	00015517          	auipc	a0,0x15
    80003230:	35450513          	addi	a0,a0,852 # 80018580 <bcache>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	a7c080e7          	jalr	-1412(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    8000323c:	01048513          	addi	a0,s1,16
    80003240:	00001097          	auipc	ra,0x1
    80003244:	3f8080e7          	jalr	1016(ra) # 80004638 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003248:	409c                	lw	a5,0(s1)
    8000324a:	cb89                	beqz	a5,8000325c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000324c:	8526                	mv	a0,s1
    8000324e:	70a2                	ld	ra,40(sp)
    80003250:	7402                	ld	s0,32(sp)
    80003252:	64e2                	ld	s1,24(sp)
    80003254:	6942                	ld	s2,16(sp)
    80003256:	69a2                	ld	s3,8(sp)
    80003258:	6145                	addi	sp,sp,48
    8000325a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000325c:	4581                	li	a1,0
    8000325e:	8526                	mv	a0,s1
    80003260:	00003097          	auipc	ra,0x3
    80003264:	f2c080e7          	jalr	-212(ra) # 8000618c <virtio_disk_rw>
    b->valid = 1;
    80003268:	4785                	li	a5,1
    8000326a:	c09c                	sw	a5,0(s1)
  return b;
    8000326c:	b7c5                	j	8000324c <bread+0xd0>

000000008000326e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	e426                	sd	s1,8(sp)
    80003276:	1000                	addi	s0,sp,32
    80003278:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000327a:	0541                	addi	a0,a0,16
    8000327c:	00001097          	auipc	ra,0x1
    80003280:	456080e7          	jalr	1110(ra) # 800046d2 <holdingsleep>
    80003284:	cd01                	beqz	a0,8000329c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003286:	4585                	li	a1,1
    80003288:	8526                	mv	a0,s1
    8000328a:	00003097          	auipc	ra,0x3
    8000328e:	f02080e7          	jalr	-254(ra) # 8000618c <virtio_disk_rw>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	64a2                	ld	s1,8(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret
    panic("bwrite");
    8000329c:	00005517          	auipc	a0,0x5
    800032a0:	2b450513          	addi	a0,a0,692 # 80008550 <syscalls+0xd8>
    800032a4:	ffffd097          	auipc	ra,0xffffd
    800032a8:	29c080e7          	jalr	668(ra) # 80000540 <panic>

00000000800032ac <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	e426                	sd	s1,8(sp)
    800032b4:	e04a                	sd	s2,0(sp)
    800032b6:	1000                	addi	s0,sp,32
    800032b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ba:	01050913          	addi	s2,a0,16
    800032be:	854a                	mv	a0,s2
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	412080e7          	jalr	1042(ra) # 800046d2 <holdingsleep>
    800032c8:	c92d                	beqz	a0,8000333a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032ca:	854a                	mv	a0,s2
    800032cc:	00001097          	auipc	ra,0x1
    800032d0:	3c2080e7          	jalr	962(ra) # 8000468e <releasesleep>

  acquire(&bcache.lock);
    800032d4:	00015517          	auipc	a0,0x15
    800032d8:	2ac50513          	addi	a0,a0,684 # 80018580 <bcache>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	920080e7          	jalr	-1760(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032e4:	40bc                	lw	a5,64(s1)
    800032e6:	37fd                	addiw	a5,a5,-1
    800032e8:	0007871b          	sext.w	a4,a5
    800032ec:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032ee:	eb05                	bnez	a4,8000331e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032f0:	68bc                	ld	a5,80(s1)
    800032f2:	64b8                	ld	a4,72(s1)
    800032f4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032f6:	64bc                	ld	a5,72(s1)
    800032f8:	68b8                	ld	a4,80(s1)
    800032fa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032fc:	0001d797          	auipc	a5,0x1d
    80003300:	28478793          	addi	a5,a5,644 # 80020580 <bcache+0x8000>
    80003304:	2b87b703          	ld	a4,696(a5)
    80003308:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000330a:	0001d717          	auipc	a4,0x1d
    8000330e:	4de70713          	addi	a4,a4,1246 # 800207e8 <bcache+0x8268>
    80003312:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003314:	2b87b703          	ld	a4,696(a5)
    80003318:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000331a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000331e:	00015517          	auipc	a0,0x15
    80003322:	26250513          	addi	a0,a0,610 # 80018580 <bcache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	98a080e7          	jalr	-1654(ra) # 80000cb0 <release>
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6902                	ld	s2,0(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret
    panic("brelse");
    8000333a:	00005517          	auipc	a0,0x5
    8000333e:	21e50513          	addi	a0,a0,542 # 80008558 <syscalls+0xe0>
    80003342:	ffffd097          	auipc	ra,0xffffd
    80003346:	1fe080e7          	jalr	510(ra) # 80000540 <panic>

000000008000334a <bpin>:

void
bpin(struct buf *b) {
    8000334a:	1101                	addi	sp,sp,-32
    8000334c:	ec06                	sd	ra,24(sp)
    8000334e:	e822                	sd	s0,16(sp)
    80003350:	e426                	sd	s1,8(sp)
    80003352:	1000                	addi	s0,sp,32
    80003354:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003356:	00015517          	auipc	a0,0x15
    8000335a:	22a50513          	addi	a0,a0,554 # 80018580 <bcache>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	89e080e7          	jalr	-1890(ra) # 80000bfc <acquire>
  b->refcnt++;
    80003366:	40bc                	lw	a5,64(s1)
    80003368:	2785                	addiw	a5,a5,1
    8000336a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000336c:	00015517          	auipc	a0,0x15
    80003370:	21450513          	addi	a0,a0,532 # 80018580 <bcache>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	93c080e7          	jalr	-1732(ra) # 80000cb0 <release>
}
    8000337c:	60e2                	ld	ra,24(sp)
    8000337e:	6442                	ld	s0,16(sp)
    80003380:	64a2                	ld	s1,8(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret

0000000080003386 <bunpin>:

void
bunpin(struct buf *b) {
    80003386:	1101                	addi	sp,sp,-32
    80003388:	ec06                	sd	ra,24(sp)
    8000338a:	e822                	sd	s0,16(sp)
    8000338c:	e426                	sd	s1,8(sp)
    8000338e:	1000                	addi	s0,sp,32
    80003390:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003392:	00015517          	auipc	a0,0x15
    80003396:	1ee50513          	addi	a0,a0,494 # 80018580 <bcache>
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	862080e7          	jalr	-1950(ra) # 80000bfc <acquire>
  b->refcnt--;
    800033a2:	40bc                	lw	a5,64(s1)
    800033a4:	37fd                	addiw	a5,a5,-1
    800033a6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a8:	00015517          	auipc	a0,0x15
    800033ac:	1d850513          	addi	a0,a0,472 # 80018580 <bcache>
    800033b0:	ffffe097          	auipc	ra,0xffffe
    800033b4:	900080e7          	jalr	-1792(ra) # 80000cb0 <release>
}
    800033b8:	60e2                	ld	ra,24(sp)
    800033ba:	6442                	ld	s0,16(sp)
    800033bc:	64a2                	ld	s1,8(sp)
    800033be:	6105                	addi	sp,sp,32
    800033c0:	8082                	ret

00000000800033c2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033c2:	1101                	addi	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	e426                	sd	s1,8(sp)
    800033ca:	e04a                	sd	s2,0(sp)
    800033cc:	1000                	addi	s0,sp,32
    800033ce:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033d0:	00d5d59b          	srliw	a1,a1,0xd
    800033d4:	0001e797          	auipc	a5,0x1e
    800033d8:	8887a783          	lw	a5,-1912(a5) # 80020c5c <sb+0x1c>
    800033dc:	9dbd                	addw	a1,a1,a5
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	d9e080e7          	jalr	-610(ra) # 8000317c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033e6:	0074f713          	andi	a4,s1,7
    800033ea:	4785                	li	a5,1
    800033ec:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033f0:	14ce                	slli	s1,s1,0x33
    800033f2:	90d9                	srli	s1,s1,0x36
    800033f4:	00950733          	add	a4,a0,s1
    800033f8:	05874703          	lbu	a4,88(a4)
    800033fc:	00e7f6b3          	and	a3,a5,a4
    80003400:	c69d                	beqz	a3,8000342e <bfree+0x6c>
    80003402:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003404:	94aa                	add	s1,s1,a0
    80003406:	fff7c793          	not	a5,a5
    8000340a:	8ff9                	and	a5,a5,a4
    8000340c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003410:	00001097          	auipc	ra,0x1
    80003414:	100080e7          	jalr	256(ra) # 80004510 <log_write>
  brelse(bp);
    80003418:	854a                	mv	a0,s2
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e92080e7          	jalr	-366(ra) # 800032ac <brelse>
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	64a2                	ld	s1,8(sp)
    80003428:	6902                	ld	s2,0(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret
    panic("freeing free block");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	13250513          	addi	a0,a0,306 # 80008560 <syscalls+0xe8>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	10a080e7          	jalr	266(ra) # 80000540 <panic>

000000008000343e <balloc>:
{
    8000343e:	711d                	addi	sp,sp,-96
    80003440:	ec86                	sd	ra,88(sp)
    80003442:	e8a2                	sd	s0,80(sp)
    80003444:	e4a6                	sd	s1,72(sp)
    80003446:	e0ca                	sd	s2,64(sp)
    80003448:	fc4e                	sd	s3,56(sp)
    8000344a:	f852                	sd	s4,48(sp)
    8000344c:	f456                	sd	s5,40(sp)
    8000344e:	f05a                	sd	s6,32(sp)
    80003450:	ec5e                	sd	s7,24(sp)
    80003452:	e862                	sd	s8,16(sp)
    80003454:	e466                	sd	s9,8(sp)
    80003456:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003458:	0001d797          	auipc	a5,0x1d
    8000345c:	7ec7a783          	lw	a5,2028(a5) # 80020c44 <sb+0x4>
    80003460:	cbd1                	beqz	a5,800034f4 <balloc+0xb6>
    80003462:	8baa                	mv	s7,a0
    80003464:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003466:	0001db17          	auipc	s6,0x1d
    8000346a:	7dab0b13          	addi	s6,s6,2010 # 80020c40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003470:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003472:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003474:	6c89                	lui	s9,0x2
    80003476:	a831                	j	80003492 <balloc+0x54>
    brelse(bp);
    80003478:	854a                	mv	a0,s2
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	e32080e7          	jalr	-462(ra) # 800032ac <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003482:	015c87bb          	addw	a5,s9,s5
    80003486:	00078a9b          	sext.w	s5,a5
    8000348a:	004b2703          	lw	a4,4(s6)
    8000348e:	06eaf363          	bgeu	s5,a4,800034f4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003492:	41fad79b          	sraiw	a5,s5,0x1f
    80003496:	0137d79b          	srliw	a5,a5,0x13
    8000349a:	015787bb          	addw	a5,a5,s5
    8000349e:	40d7d79b          	sraiw	a5,a5,0xd
    800034a2:	01cb2583          	lw	a1,28(s6)
    800034a6:	9dbd                	addw	a1,a1,a5
    800034a8:	855e                	mv	a0,s7
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	cd2080e7          	jalr	-814(ra) # 8000317c <bread>
    800034b2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b4:	004b2503          	lw	a0,4(s6)
    800034b8:	000a849b          	sext.w	s1,s5
    800034bc:	8662                	mv	a2,s8
    800034be:	faa4fde3          	bgeu	s1,a0,80003478 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034c2:	41f6579b          	sraiw	a5,a2,0x1f
    800034c6:	01d7d69b          	srliw	a3,a5,0x1d
    800034ca:	00c6873b          	addw	a4,a3,a2
    800034ce:	00777793          	andi	a5,a4,7
    800034d2:	9f95                	subw	a5,a5,a3
    800034d4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034d8:	4037571b          	sraiw	a4,a4,0x3
    800034dc:	00e906b3          	add	a3,s2,a4
    800034e0:	0586c683          	lbu	a3,88(a3)
    800034e4:	00d7f5b3          	and	a1,a5,a3
    800034e8:	cd91                	beqz	a1,80003504 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ea:	2605                	addiw	a2,a2,1
    800034ec:	2485                	addiw	s1,s1,1
    800034ee:	fd4618e3          	bne	a2,s4,800034be <balloc+0x80>
    800034f2:	b759                	j	80003478 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	08450513          	addi	a0,a0,132 # 80008578 <syscalls+0x100>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	044080e7          	jalr	68(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003504:	974a                	add	a4,a4,s2
    80003506:	8fd5                	or	a5,a5,a3
    80003508:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	00001097          	auipc	ra,0x1
    80003512:	002080e7          	jalr	2(ra) # 80004510 <log_write>
        brelse(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	d94080e7          	jalr	-620(ra) # 800032ac <brelse>
  bp = bread(dev, bno);
    80003520:	85a6                	mv	a1,s1
    80003522:	855e                	mv	a0,s7
    80003524:	00000097          	auipc	ra,0x0
    80003528:	c58080e7          	jalr	-936(ra) # 8000317c <bread>
    8000352c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000352e:	40000613          	li	a2,1024
    80003532:	4581                	li	a1,0
    80003534:	05850513          	addi	a0,a0,88
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	7c0080e7          	jalr	1984(ra) # 80000cf8 <memset>
  log_write(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	fce080e7          	jalr	-50(ra) # 80004510 <log_write>
  brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	d60080e7          	jalr	-672(ra) # 800032ac <brelse>
}
    80003554:	8526                	mv	a0,s1
    80003556:	60e6                	ld	ra,88(sp)
    80003558:	6446                	ld	s0,80(sp)
    8000355a:	64a6                	ld	s1,72(sp)
    8000355c:	6906                	ld	s2,64(sp)
    8000355e:	79e2                	ld	s3,56(sp)
    80003560:	7a42                	ld	s4,48(sp)
    80003562:	7aa2                	ld	s5,40(sp)
    80003564:	7b02                	ld	s6,32(sp)
    80003566:	6be2                	ld	s7,24(sp)
    80003568:	6c42                	ld	s8,16(sp)
    8000356a:	6ca2                	ld	s9,8(sp)
    8000356c:	6125                	addi	sp,sp,96
    8000356e:	8082                	ret

0000000080003570 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003570:	7179                	addi	sp,sp,-48
    80003572:	f406                	sd	ra,40(sp)
    80003574:	f022                	sd	s0,32(sp)
    80003576:	ec26                	sd	s1,24(sp)
    80003578:	e84a                	sd	s2,16(sp)
    8000357a:	e44e                	sd	s3,8(sp)
    8000357c:	e052                	sd	s4,0(sp)
    8000357e:	1800                	addi	s0,sp,48
    80003580:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003582:	47ad                	li	a5,11
    80003584:	04b7fe63          	bgeu	a5,a1,800035e0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003588:	ff45849b          	addiw	s1,a1,-12
    8000358c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003590:	0ff00793          	li	a5,255
    80003594:	0ae7e363          	bltu	a5,a4,8000363a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003598:	08052583          	lw	a1,128(a0)
    8000359c:	c5ad                	beqz	a1,80003606 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000359e:	00092503          	lw	a0,0(s2)
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	bda080e7          	jalr	-1062(ra) # 8000317c <bread>
    800035aa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035ac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b0:	02049593          	slli	a1,s1,0x20
    800035b4:	9181                	srli	a1,a1,0x20
    800035b6:	058a                	slli	a1,a1,0x2
    800035b8:	00b784b3          	add	s1,a5,a1
    800035bc:	0004a983          	lw	s3,0(s1)
    800035c0:	04098d63          	beqz	s3,8000361a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035c4:	8552                	mv	a0,s4
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	ce6080e7          	jalr	-794(ra) # 800032ac <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ce:	854e                	mv	a0,s3
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6a02                	ld	s4,0(sp)
    800035dc:	6145                	addi	sp,sp,48
    800035de:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035e0:	02059493          	slli	s1,a1,0x20
    800035e4:	9081                	srli	s1,s1,0x20
    800035e6:	048a                	slli	s1,s1,0x2
    800035e8:	94aa                	add	s1,s1,a0
    800035ea:	0504a983          	lw	s3,80(s1)
    800035ee:	fe0990e3          	bnez	s3,800035ce <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035f2:	4108                	lw	a0,0(a0)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	e4a080e7          	jalr	-438(ra) # 8000343e <balloc>
    800035fc:	0005099b          	sext.w	s3,a0
    80003600:	0534a823          	sw	s3,80(s1)
    80003604:	b7e9                	j	800035ce <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003606:	4108                	lw	a0,0(a0)
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	e36080e7          	jalr	-458(ra) # 8000343e <balloc>
    80003610:	0005059b          	sext.w	a1,a0
    80003614:	08b92023          	sw	a1,128(s2)
    80003618:	b759                	j	8000359e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000361a:	00092503          	lw	a0,0(s2)
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	e20080e7          	jalr	-480(ra) # 8000343e <balloc>
    80003626:	0005099b          	sext.w	s3,a0
    8000362a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000362e:	8552                	mv	a0,s4
    80003630:	00001097          	auipc	ra,0x1
    80003634:	ee0080e7          	jalr	-288(ra) # 80004510 <log_write>
    80003638:	b771                	j	800035c4 <bmap+0x54>
  panic("bmap: out of range");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	f5650513          	addi	a0,a0,-170 # 80008590 <syscalls+0x118>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	efe080e7          	jalr	-258(ra) # 80000540 <panic>

000000008000364a <iget>:
{
    8000364a:	7179                	addi	sp,sp,-48
    8000364c:	f406                	sd	ra,40(sp)
    8000364e:	f022                	sd	s0,32(sp)
    80003650:	ec26                	sd	s1,24(sp)
    80003652:	e84a                	sd	s2,16(sp)
    80003654:	e44e                	sd	s3,8(sp)
    80003656:	e052                	sd	s4,0(sp)
    80003658:	1800                	addi	s0,sp,48
    8000365a:	89aa                	mv	s3,a0
    8000365c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000365e:	0001d517          	auipc	a0,0x1d
    80003662:	60250513          	addi	a0,a0,1538 # 80020c60 <icache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	596080e7          	jalr	1430(ra) # 80000bfc <acquire>
  empty = 0;
    8000366e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003670:	0001d497          	auipc	s1,0x1d
    80003674:	60848493          	addi	s1,s1,1544 # 80020c78 <icache+0x18>
    80003678:	0001f697          	auipc	a3,0x1f
    8000367c:	09068693          	addi	a3,a3,144 # 80022708 <log>
    80003680:	a039                	j	8000368e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003682:	02090b63          	beqz	s2,800036b8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003686:	08848493          	addi	s1,s1,136
    8000368a:	02d48a63          	beq	s1,a3,800036be <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000368e:	449c                	lw	a5,8(s1)
    80003690:	fef059e3          	blez	a5,80003682 <iget+0x38>
    80003694:	4098                	lw	a4,0(s1)
    80003696:	ff3716e3          	bne	a4,s3,80003682 <iget+0x38>
    8000369a:	40d8                	lw	a4,4(s1)
    8000369c:	ff4713e3          	bne	a4,s4,80003682 <iget+0x38>
      ip->ref++;
    800036a0:	2785                	addiw	a5,a5,1
    800036a2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036a4:	0001d517          	auipc	a0,0x1d
    800036a8:	5bc50513          	addi	a0,a0,1468 # 80020c60 <icache>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	604080e7          	jalr	1540(ra) # 80000cb0 <release>
      return ip;
    800036b4:	8926                	mv	s2,s1
    800036b6:	a03d                	j	800036e4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b8:	f7f9                	bnez	a5,80003686 <iget+0x3c>
    800036ba:	8926                	mv	s2,s1
    800036bc:	b7e9                	j	80003686 <iget+0x3c>
  if(empty == 0)
    800036be:	02090c63          	beqz	s2,800036f6 <iget+0xac>
  ip->dev = dev;
    800036c2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036c6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036ca:	4785                	li	a5,1
    800036cc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036d4:	0001d517          	auipc	a0,0x1d
    800036d8:	58c50513          	addi	a0,a0,1420 # 80020c60 <icache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	5d4080e7          	jalr	1492(ra) # 80000cb0 <release>
}
    800036e4:	854a                	mv	a0,s2
    800036e6:	70a2                	ld	ra,40(sp)
    800036e8:	7402                	ld	s0,32(sp)
    800036ea:	64e2                	ld	s1,24(sp)
    800036ec:	6942                	ld	s2,16(sp)
    800036ee:	69a2                	ld	s3,8(sp)
    800036f0:	6a02                	ld	s4,0(sp)
    800036f2:	6145                	addi	sp,sp,48
    800036f4:	8082                	ret
    panic("iget: no inodes");
    800036f6:	00005517          	auipc	a0,0x5
    800036fa:	eb250513          	addi	a0,a0,-334 # 800085a8 <syscalls+0x130>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	e42080e7          	jalr	-446(ra) # 80000540 <panic>

0000000080003706 <fsinit>:
fsinit(int dev) {
    80003706:	7179                	addi	sp,sp,-48
    80003708:	f406                	sd	ra,40(sp)
    8000370a:	f022                	sd	s0,32(sp)
    8000370c:	ec26                	sd	s1,24(sp)
    8000370e:	e84a                	sd	s2,16(sp)
    80003710:	e44e                	sd	s3,8(sp)
    80003712:	1800                	addi	s0,sp,48
    80003714:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003716:	4585                	li	a1,1
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	a64080e7          	jalr	-1436(ra) # 8000317c <bread>
    80003720:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003722:	0001d997          	auipc	s3,0x1d
    80003726:	51e98993          	addi	s3,s3,1310 # 80020c40 <sb>
    8000372a:	02000613          	li	a2,32
    8000372e:	05850593          	addi	a1,a0,88
    80003732:	854e                	mv	a0,s3
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	620080e7          	jalr	1568(ra) # 80000d54 <memmove>
  brelse(bp);
    8000373c:	8526                	mv	a0,s1
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	b6e080e7          	jalr	-1170(ra) # 800032ac <brelse>
  if(sb.magic != FSMAGIC)
    80003746:	0009a703          	lw	a4,0(s3)
    8000374a:	102037b7          	lui	a5,0x10203
    8000374e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003752:	02f71263          	bne	a4,a5,80003776 <fsinit+0x70>
  initlog(dev, &sb);
    80003756:	0001d597          	auipc	a1,0x1d
    8000375a:	4ea58593          	addi	a1,a1,1258 # 80020c40 <sb>
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	b38080e7          	jalr	-1224(ra) # 80004298 <initlog>
}
    80003768:	70a2                	ld	ra,40(sp)
    8000376a:	7402                	ld	s0,32(sp)
    8000376c:	64e2                	ld	s1,24(sp)
    8000376e:	6942                	ld	s2,16(sp)
    80003770:	69a2                	ld	s3,8(sp)
    80003772:	6145                	addi	sp,sp,48
    80003774:	8082                	ret
    panic("invalid file system");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	e4250513          	addi	a0,a0,-446 # 800085b8 <syscalls+0x140>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dc2080e7          	jalr	-574(ra) # 80000540 <panic>

0000000080003786 <iinit>:
{
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003794:	00005597          	auipc	a1,0x5
    80003798:	e3c58593          	addi	a1,a1,-452 # 800085d0 <syscalls+0x158>
    8000379c:	0001d517          	auipc	a0,0x1d
    800037a0:	4c450513          	addi	a0,a0,1220 # 80020c60 <icache>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	3c8080e7          	jalr	968(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ac:	0001d497          	auipc	s1,0x1d
    800037b0:	4dc48493          	addi	s1,s1,1244 # 80020c88 <icache+0x28>
    800037b4:	0001f997          	auipc	s3,0x1f
    800037b8:	f6498993          	addi	s3,s3,-156 # 80022718 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037bc:	00005917          	auipc	s2,0x5
    800037c0:	e1c90913          	addi	s2,s2,-484 # 800085d8 <syscalls+0x160>
    800037c4:	85ca                	mv	a1,s2
    800037c6:	8526                	mv	a0,s1
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	e36080e7          	jalr	-458(ra) # 800045fe <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d0:	08848493          	addi	s1,s1,136
    800037d4:	ff3498e3          	bne	s1,s3,800037c4 <iinit+0x3e>
}
    800037d8:	70a2                	ld	ra,40(sp)
    800037da:	7402                	ld	s0,32(sp)
    800037dc:	64e2                	ld	s1,24(sp)
    800037de:	6942                	ld	s2,16(sp)
    800037e0:	69a2                	ld	s3,8(sp)
    800037e2:	6145                	addi	sp,sp,48
    800037e4:	8082                	ret

00000000800037e6 <ialloc>:
{
    800037e6:	715d                	addi	sp,sp,-80
    800037e8:	e486                	sd	ra,72(sp)
    800037ea:	e0a2                	sd	s0,64(sp)
    800037ec:	fc26                	sd	s1,56(sp)
    800037ee:	f84a                	sd	s2,48(sp)
    800037f0:	f44e                	sd	s3,40(sp)
    800037f2:	f052                	sd	s4,32(sp)
    800037f4:	ec56                	sd	s5,24(sp)
    800037f6:	e85a                	sd	s6,16(sp)
    800037f8:	e45e                	sd	s7,8(sp)
    800037fa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037fc:	0001d717          	auipc	a4,0x1d
    80003800:	45072703          	lw	a4,1104(a4) # 80020c4c <sb+0xc>
    80003804:	4785                	li	a5,1
    80003806:	04e7fa63          	bgeu	a5,a4,8000385a <ialloc+0x74>
    8000380a:	8aaa                	mv	s5,a0
    8000380c:	8bae                	mv	s7,a1
    8000380e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003810:	0001da17          	auipc	s4,0x1d
    80003814:	430a0a13          	addi	s4,s4,1072 # 80020c40 <sb>
    80003818:	00048b1b          	sext.w	s6,s1
    8000381c:	0044d793          	srli	a5,s1,0x4
    80003820:	018a2583          	lw	a1,24(s4)
    80003824:	9dbd                	addw	a1,a1,a5
    80003826:	8556                	mv	a0,s5
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	954080e7          	jalr	-1708(ra) # 8000317c <bread>
    80003830:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003832:	05850993          	addi	s3,a0,88
    80003836:	00f4f793          	andi	a5,s1,15
    8000383a:	079a                	slli	a5,a5,0x6
    8000383c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000383e:	00099783          	lh	a5,0(s3)
    80003842:	c785                	beqz	a5,8000386a <ialloc+0x84>
    brelse(bp);
    80003844:	00000097          	auipc	ra,0x0
    80003848:	a68080e7          	jalr	-1432(ra) # 800032ac <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000384c:	0485                	addi	s1,s1,1
    8000384e:	00ca2703          	lw	a4,12(s4)
    80003852:	0004879b          	sext.w	a5,s1
    80003856:	fce7e1e3          	bltu	a5,a4,80003818 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000385a:	00005517          	auipc	a0,0x5
    8000385e:	d8650513          	addi	a0,a0,-634 # 800085e0 <syscalls+0x168>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	cde080e7          	jalr	-802(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    8000386a:	04000613          	li	a2,64
    8000386e:	4581                	li	a1,0
    80003870:	854e                	mv	a0,s3
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	486080e7          	jalr	1158(ra) # 80000cf8 <memset>
      dip->type = type;
    8000387a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	c90080e7          	jalr	-880(ra) # 80004510 <log_write>
      brelse(bp);
    80003888:	854a                	mv	a0,s2
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	a22080e7          	jalr	-1502(ra) # 800032ac <brelse>
      return iget(dev, inum);
    80003892:	85da                	mv	a1,s6
    80003894:	8556                	mv	a0,s5
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	db4080e7          	jalr	-588(ra) # 8000364a <iget>
}
    8000389e:	60a6                	ld	ra,72(sp)
    800038a0:	6406                	ld	s0,64(sp)
    800038a2:	74e2                	ld	s1,56(sp)
    800038a4:	7942                	ld	s2,48(sp)
    800038a6:	79a2                	ld	s3,40(sp)
    800038a8:	7a02                	ld	s4,32(sp)
    800038aa:	6ae2                	ld	s5,24(sp)
    800038ac:	6b42                	ld	s6,16(sp)
    800038ae:	6ba2                	ld	s7,8(sp)
    800038b0:	6161                	addi	sp,sp,80
    800038b2:	8082                	ret

00000000800038b4 <iupdate>:
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	e04a                	sd	s2,0(sp)
    800038be:	1000                	addi	s0,sp,32
    800038c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c2:	415c                	lw	a5,4(a0)
    800038c4:	0047d79b          	srliw	a5,a5,0x4
    800038c8:	0001d597          	auipc	a1,0x1d
    800038cc:	3905a583          	lw	a1,912(a1) # 80020c58 <sb+0x18>
    800038d0:	9dbd                	addw	a1,a1,a5
    800038d2:	4108                	lw	a0,0(a0)
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	8a8080e7          	jalr	-1880(ra) # 8000317c <bread>
    800038dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038de:	05850793          	addi	a5,a0,88
    800038e2:	40c8                	lw	a0,4(s1)
    800038e4:	893d                	andi	a0,a0,15
    800038e6:	051a                	slli	a0,a0,0x6
    800038e8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038ea:	04449703          	lh	a4,68(s1)
    800038ee:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038f2:	04649703          	lh	a4,70(s1)
    800038f6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038fa:	04849703          	lh	a4,72(s1)
    800038fe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003902:	04a49703          	lh	a4,74(s1)
    80003906:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000390a:	44f8                	lw	a4,76(s1)
    8000390c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000390e:	03400613          	li	a2,52
    80003912:	05048593          	addi	a1,s1,80
    80003916:	0531                	addi	a0,a0,12
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	43c080e7          	jalr	1084(ra) # 80000d54 <memmove>
  log_write(bp);
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	bee080e7          	jalr	-1042(ra) # 80004510 <log_write>
  brelse(bp);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	980080e7          	jalr	-1664(ra) # 800032ac <brelse>
}
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6902                	ld	s2,0(sp)
    8000393c:	6105                	addi	sp,sp,32
    8000393e:	8082                	ret

0000000080003940 <idup>:
{
    80003940:	1101                	addi	sp,sp,-32
    80003942:	ec06                	sd	ra,24(sp)
    80003944:	e822                	sd	s0,16(sp)
    80003946:	e426                	sd	s1,8(sp)
    80003948:	1000                	addi	s0,sp,32
    8000394a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000394c:	0001d517          	auipc	a0,0x1d
    80003950:	31450513          	addi	a0,a0,788 # 80020c60 <icache>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	2a8080e7          	jalr	680(ra) # 80000bfc <acquire>
  ip->ref++;
    8000395c:	449c                	lw	a5,8(s1)
    8000395e:	2785                	addiw	a5,a5,1
    80003960:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003962:	0001d517          	auipc	a0,0x1d
    80003966:	2fe50513          	addi	a0,a0,766 # 80020c60 <icache>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	346080e7          	jalr	838(ra) # 80000cb0 <release>
}
    80003972:	8526                	mv	a0,s1
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	64a2                	ld	s1,8(sp)
    8000397a:	6105                	addi	sp,sp,32
    8000397c:	8082                	ret

000000008000397e <ilock>:
{
    8000397e:	1101                	addi	sp,sp,-32
    80003980:	ec06                	sd	ra,24(sp)
    80003982:	e822                	sd	s0,16(sp)
    80003984:	e426                	sd	s1,8(sp)
    80003986:	e04a                	sd	s2,0(sp)
    80003988:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000398a:	c115                	beqz	a0,800039ae <ilock+0x30>
    8000398c:	84aa                	mv	s1,a0
    8000398e:	451c                	lw	a5,8(a0)
    80003990:	00f05f63          	blez	a5,800039ae <ilock+0x30>
  acquiresleep(&ip->lock);
    80003994:	0541                	addi	a0,a0,16
    80003996:	00001097          	auipc	ra,0x1
    8000399a:	ca2080e7          	jalr	-862(ra) # 80004638 <acquiresleep>
  if(ip->valid == 0){
    8000399e:	40bc                	lw	a5,64(s1)
    800039a0:	cf99                	beqz	a5,800039be <ilock+0x40>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6902                	ld	s2,0(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret
    panic("ilock");
    800039ae:	00005517          	auipc	a0,0x5
    800039b2:	c4a50513          	addi	a0,a0,-950 # 800085f8 <syscalls+0x180>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	b8a080e7          	jalr	-1142(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039be:	40dc                	lw	a5,4(s1)
    800039c0:	0047d79b          	srliw	a5,a5,0x4
    800039c4:	0001d597          	auipc	a1,0x1d
    800039c8:	2945a583          	lw	a1,660(a1) # 80020c58 <sb+0x18>
    800039cc:	9dbd                	addw	a1,a1,a5
    800039ce:	4088                	lw	a0,0(s1)
    800039d0:	fffff097          	auipc	ra,0xfffff
    800039d4:	7ac080e7          	jalr	1964(ra) # 8000317c <bread>
    800039d8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039da:	05850593          	addi	a1,a0,88
    800039de:	40dc                	lw	a5,4(s1)
    800039e0:	8bbd                	andi	a5,a5,15
    800039e2:	079a                	slli	a5,a5,0x6
    800039e4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039e6:	00059783          	lh	a5,0(a1)
    800039ea:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039ee:	00259783          	lh	a5,2(a1)
    800039f2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039f6:	00459783          	lh	a5,4(a1)
    800039fa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039fe:	00659783          	lh	a5,6(a1)
    80003a02:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a06:	459c                	lw	a5,8(a1)
    80003a08:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a0a:	03400613          	li	a2,52
    80003a0e:	05b1                	addi	a1,a1,12
    80003a10:	05048513          	addi	a0,s1,80
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	340080e7          	jalr	832(ra) # 80000d54 <memmove>
    brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	88e080e7          	jalr	-1906(ra) # 800032ac <brelse>
    ip->valid = 1;
    80003a26:	4785                	li	a5,1
    80003a28:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a2a:	04449783          	lh	a5,68(s1)
    80003a2e:	fbb5                	bnez	a5,800039a2 <ilock+0x24>
      panic("ilock: no type");
    80003a30:	00005517          	auipc	a0,0x5
    80003a34:	bd050513          	addi	a0,a0,-1072 # 80008600 <syscalls+0x188>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	b08080e7          	jalr	-1272(ra) # 80000540 <panic>

0000000080003a40 <iunlock>:
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	e04a                	sd	s2,0(sp)
    80003a4a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a4c:	c905                	beqz	a0,80003a7c <iunlock+0x3c>
    80003a4e:	84aa                	mv	s1,a0
    80003a50:	01050913          	addi	s2,a0,16
    80003a54:	854a                	mv	a0,s2
    80003a56:	00001097          	auipc	ra,0x1
    80003a5a:	c7c080e7          	jalr	-900(ra) # 800046d2 <holdingsleep>
    80003a5e:	cd19                	beqz	a0,80003a7c <iunlock+0x3c>
    80003a60:	449c                	lw	a5,8(s1)
    80003a62:	00f05d63          	blez	a5,80003a7c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a66:	854a                	mv	a0,s2
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	c26080e7          	jalr	-986(ra) # 8000468e <releasesleep>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6902                	ld	s2,0(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret
    panic("iunlock");
    80003a7c:	00005517          	auipc	a0,0x5
    80003a80:	b9450513          	addi	a0,a0,-1132 # 80008610 <syscalls+0x198>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	abc080e7          	jalr	-1348(ra) # 80000540 <panic>

0000000080003a8c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a8c:	7179                	addi	sp,sp,-48
    80003a8e:	f406                	sd	ra,40(sp)
    80003a90:	f022                	sd	s0,32(sp)
    80003a92:	ec26                	sd	s1,24(sp)
    80003a94:	e84a                	sd	s2,16(sp)
    80003a96:	e44e                	sd	s3,8(sp)
    80003a98:	e052                	sd	s4,0(sp)
    80003a9a:	1800                	addi	s0,sp,48
    80003a9c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a9e:	05050493          	addi	s1,a0,80
    80003aa2:	08050913          	addi	s2,a0,128
    80003aa6:	a021                	j	80003aae <itrunc+0x22>
    80003aa8:	0491                	addi	s1,s1,4
    80003aaa:	01248d63          	beq	s1,s2,80003ac4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aae:	408c                	lw	a1,0(s1)
    80003ab0:	dde5                	beqz	a1,80003aa8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ab2:	0009a503          	lw	a0,0(s3)
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	90c080e7          	jalr	-1780(ra) # 800033c2 <bfree>
      ip->addrs[i] = 0;
    80003abe:	0004a023          	sw	zero,0(s1)
    80003ac2:	b7dd                	j	80003aa8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ac4:	0809a583          	lw	a1,128(s3)
    80003ac8:	e185                	bnez	a1,80003ae8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aca:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ace:	854e                	mv	a0,s3
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	de4080e7          	jalr	-540(ra) # 800038b4 <iupdate>
}
    80003ad8:	70a2                	ld	ra,40(sp)
    80003ada:	7402                	ld	s0,32(sp)
    80003adc:	64e2                	ld	s1,24(sp)
    80003ade:	6942                	ld	s2,16(sp)
    80003ae0:	69a2                	ld	s3,8(sp)
    80003ae2:	6a02                	ld	s4,0(sp)
    80003ae4:	6145                	addi	sp,sp,48
    80003ae6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ae8:	0009a503          	lw	a0,0(s3)
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	690080e7          	jalr	1680(ra) # 8000317c <bread>
    80003af4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003af6:	05850493          	addi	s1,a0,88
    80003afa:	45850913          	addi	s2,a0,1112
    80003afe:	a021                	j	80003b06 <itrunc+0x7a>
    80003b00:	0491                	addi	s1,s1,4
    80003b02:	01248b63          	beq	s1,s2,80003b18 <itrunc+0x8c>
      if(a[j])
    80003b06:	408c                	lw	a1,0(s1)
    80003b08:	dde5                	beqz	a1,80003b00 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b0a:	0009a503          	lw	a0,0(s3)
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	8b4080e7          	jalr	-1868(ra) # 800033c2 <bfree>
    80003b16:	b7ed                	j	80003b00 <itrunc+0x74>
    brelse(bp);
    80003b18:	8552                	mv	a0,s4
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	792080e7          	jalr	1938(ra) # 800032ac <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b22:	0809a583          	lw	a1,128(s3)
    80003b26:	0009a503          	lw	a0,0(s3)
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	898080e7          	jalr	-1896(ra) # 800033c2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b32:	0809a023          	sw	zero,128(s3)
    80003b36:	bf51                	j	80003aca <itrunc+0x3e>

0000000080003b38 <iput>:
{
    80003b38:	1101                	addi	sp,sp,-32
    80003b3a:	ec06                	sd	ra,24(sp)
    80003b3c:	e822                	sd	s0,16(sp)
    80003b3e:	e426                	sd	s1,8(sp)
    80003b40:	e04a                	sd	s2,0(sp)
    80003b42:	1000                	addi	s0,sp,32
    80003b44:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b46:	0001d517          	auipc	a0,0x1d
    80003b4a:	11a50513          	addi	a0,a0,282 # 80020c60 <icache>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	0ae080e7          	jalr	174(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b56:	4498                	lw	a4,8(s1)
    80003b58:	4785                	li	a5,1
    80003b5a:	02f70363          	beq	a4,a5,80003b80 <iput+0x48>
  ip->ref--;
    80003b5e:	449c                	lw	a5,8(s1)
    80003b60:	37fd                	addiw	a5,a5,-1
    80003b62:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b64:	0001d517          	auipc	a0,0x1d
    80003b68:	0fc50513          	addi	a0,a0,252 # 80020c60 <icache>
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	144080e7          	jalr	324(ra) # 80000cb0 <release>
}
    80003b74:	60e2                	ld	ra,24(sp)
    80003b76:	6442                	ld	s0,16(sp)
    80003b78:	64a2                	ld	s1,8(sp)
    80003b7a:	6902                	ld	s2,0(sp)
    80003b7c:	6105                	addi	sp,sp,32
    80003b7e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b80:	40bc                	lw	a5,64(s1)
    80003b82:	dff1                	beqz	a5,80003b5e <iput+0x26>
    80003b84:	04a49783          	lh	a5,74(s1)
    80003b88:	fbf9                	bnez	a5,80003b5e <iput+0x26>
    acquiresleep(&ip->lock);
    80003b8a:	01048913          	addi	s2,s1,16
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00001097          	auipc	ra,0x1
    80003b94:	aa8080e7          	jalr	-1368(ra) # 80004638 <acquiresleep>
    release(&icache.lock);
    80003b98:	0001d517          	auipc	a0,0x1d
    80003b9c:	0c850513          	addi	a0,a0,200 # 80020c60 <icache>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	110080e7          	jalr	272(ra) # 80000cb0 <release>
    itrunc(ip);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	ee2080e7          	jalr	-286(ra) # 80003a8c <itrunc>
    ip->type = 0;
    80003bb2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	cfc080e7          	jalr	-772(ra) # 800038b4 <iupdate>
    ip->valid = 0;
    80003bc0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	00001097          	auipc	ra,0x1
    80003bca:	ac8080e7          	jalr	-1336(ra) # 8000468e <releasesleep>
    acquire(&icache.lock);
    80003bce:	0001d517          	auipc	a0,0x1d
    80003bd2:	09250513          	addi	a0,a0,146 # 80020c60 <icache>
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	026080e7          	jalr	38(ra) # 80000bfc <acquire>
    80003bde:	b741                	j	80003b5e <iput+0x26>

0000000080003be0 <iunlockput>:
{
    80003be0:	1101                	addi	sp,sp,-32
    80003be2:	ec06                	sd	ra,24(sp)
    80003be4:	e822                	sd	s0,16(sp)
    80003be6:	e426                	sd	s1,8(sp)
    80003be8:	1000                	addi	s0,sp,32
    80003bea:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	e54080e7          	jalr	-428(ra) # 80003a40 <iunlock>
  iput(ip);
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	f42080e7          	jalr	-190(ra) # 80003b38 <iput>
}
    80003bfe:	60e2                	ld	ra,24(sp)
    80003c00:	6442                	ld	s0,16(sp)
    80003c02:	64a2                	ld	s1,8(sp)
    80003c04:	6105                	addi	sp,sp,32
    80003c06:	8082                	ret

0000000080003c08 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c08:	1141                	addi	sp,sp,-16
    80003c0a:	e422                	sd	s0,8(sp)
    80003c0c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c0e:	411c                	lw	a5,0(a0)
    80003c10:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c12:	415c                	lw	a5,4(a0)
    80003c14:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c16:	04451783          	lh	a5,68(a0)
    80003c1a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c1e:	04a51783          	lh	a5,74(a0)
    80003c22:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c26:	04c56783          	lwu	a5,76(a0)
    80003c2a:	e99c                	sd	a5,16(a1)
}
    80003c2c:	6422                	ld	s0,8(sp)
    80003c2e:	0141                	addi	sp,sp,16
    80003c30:	8082                	ret

0000000080003c32 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c32:	457c                	lw	a5,76(a0)
    80003c34:	0ed7e863          	bltu	a5,a3,80003d24 <readi+0xf2>
{
    80003c38:	7159                	addi	sp,sp,-112
    80003c3a:	f486                	sd	ra,104(sp)
    80003c3c:	f0a2                	sd	s0,96(sp)
    80003c3e:	eca6                	sd	s1,88(sp)
    80003c40:	e8ca                	sd	s2,80(sp)
    80003c42:	e4ce                	sd	s3,72(sp)
    80003c44:	e0d2                	sd	s4,64(sp)
    80003c46:	fc56                	sd	s5,56(sp)
    80003c48:	f85a                	sd	s6,48(sp)
    80003c4a:	f45e                	sd	s7,40(sp)
    80003c4c:	f062                	sd	s8,32(sp)
    80003c4e:	ec66                	sd	s9,24(sp)
    80003c50:	e86a                	sd	s10,16(sp)
    80003c52:	e46e                	sd	s11,8(sp)
    80003c54:	1880                	addi	s0,sp,112
    80003c56:	8baa                	mv	s7,a0
    80003c58:	8c2e                	mv	s8,a1
    80003c5a:	8ab2                	mv	s5,a2
    80003c5c:	84b6                	mv	s1,a3
    80003c5e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c60:	9f35                	addw	a4,a4,a3
    return 0;
    80003c62:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c64:	08d76f63          	bltu	a4,a3,80003d02 <readi+0xd0>
  if(off + n > ip->size)
    80003c68:	00e7f463          	bgeu	a5,a4,80003c70 <readi+0x3e>
    n = ip->size - off;
    80003c6c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c70:	0a0b0863          	beqz	s6,80003d20 <readi+0xee>
    80003c74:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c76:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c7a:	5cfd                	li	s9,-1
    80003c7c:	a82d                	j	80003cb6 <readi+0x84>
    80003c7e:	020a1d93          	slli	s11,s4,0x20
    80003c82:	020ddd93          	srli	s11,s11,0x20
    80003c86:	05890793          	addi	a5,s2,88
    80003c8a:	86ee                	mv	a3,s11
    80003c8c:	963e                	add	a2,a2,a5
    80003c8e:	85d6                	mv	a1,s5
    80003c90:	8562                	mv	a0,s8
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	acc080e7          	jalr	-1332(ra) # 8000275e <either_copyout>
    80003c9a:	05950d63          	beq	a0,s9,80003cf4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c9e:	854a                	mv	a0,s2
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	60c080e7          	jalr	1548(ra) # 800032ac <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca8:	013a09bb          	addw	s3,s4,s3
    80003cac:	009a04bb          	addw	s1,s4,s1
    80003cb0:	9aee                	add	s5,s5,s11
    80003cb2:	0569f663          	bgeu	s3,s6,80003cfe <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb6:	000ba903          	lw	s2,0(s7)
    80003cba:	00a4d59b          	srliw	a1,s1,0xa
    80003cbe:	855e                	mv	a0,s7
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	8b0080e7          	jalr	-1872(ra) # 80003570 <bmap>
    80003cc8:	0005059b          	sext.w	a1,a0
    80003ccc:	854a                	mv	a0,s2
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	4ae080e7          	jalr	1198(ra) # 8000317c <bread>
    80003cd6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd8:	3ff4f613          	andi	a2,s1,1023
    80003cdc:	40cd07bb          	subw	a5,s10,a2
    80003ce0:	413b073b          	subw	a4,s6,s3
    80003ce4:	8a3e                	mv	s4,a5
    80003ce6:	2781                	sext.w	a5,a5
    80003ce8:	0007069b          	sext.w	a3,a4
    80003cec:	f8f6f9e3          	bgeu	a3,a5,80003c7e <readi+0x4c>
    80003cf0:	8a3a                	mv	s4,a4
    80003cf2:	b771                	j	80003c7e <readi+0x4c>
      brelse(bp);
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	5b6080e7          	jalr	1462(ra) # 800032ac <brelse>
  }
  return tot;
    80003cfe:	0009851b          	sext.w	a0,s3
}
    80003d02:	70a6                	ld	ra,104(sp)
    80003d04:	7406                	ld	s0,96(sp)
    80003d06:	64e6                	ld	s1,88(sp)
    80003d08:	6946                	ld	s2,80(sp)
    80003d0a:	69a6                	ld	s3,72(sp)
    80003d0c:	6a06                	ld	s4,64(sp)
    80003d0e:	7ae2                	ld	s5,56(sp)
    80003d10:	7b42                	ld	s6,48(sp)
    80003d12:	7ba2                	ld	s7,40(sp)
    80003d14:	7c02                	ld	s8,32(sp)
    80003d16:	6ce2                	ld	s9,24(sp)
    80003d18:	6d42                	ld	s10,16(sp)
    80003d1a:	6da2                	ld	s11,8(sp)
    80003d1c:	6165                	addi	sp,sp,112
    80003d1e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d20:	89da                	mv	s3,s6
    80003d22:	bff1                	j	80003cfe <readi+0xcc>
    return 0;
    80003d24:	4501                	li	a0,0
}
    80003d26:	8082                	ret

0000000080003d28 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d28:	457c                	lw	a5,76(a0)
    80003d2a:	10d7e663          	bltu	a5,a3,80003e36 <writei+0x10e>
{
    80003d2e:	7159                	addi	sp,sp,-112
    80003d30:	f486                	sd	ra,104(sp)
    80003d32:	f0a2                	sd	s0,96(sp)
    80003d34:	eca6                	sd	s1,88(sp)
    80003d36:	e8ca                	sd	s2,80(sp)
    80003d38:	e4ce                	sd	s3,72(sp)
    80003d3a:	e0d2                	sd	s4,64(sp)
    80003d3c:	fc56                	sd	s5,56(sp)
    80003d3e:	f85a                	sd	s6,48(sp)
    80003d40:	f45e                	sd	s7,40(sp)
    80003d42:	f062                	sd	s8,32(sp)
    80003d44:	ec66                	sd	s9,24(sp)
    80003d46:	e86a                	sd	s10,16(sp)
    80003d48:	e46e                	sd	s11,8(sp)
    80003d4a:	1880                	addi	s0,sp,112
    80003d4c:	8baa                	mv	s7,a0
    80003d4e:	8c2e                	mv	s8,a1
    80003d50:	8ab2                	mv	s5,a2
    80003d52:	8936                	mv	s2,a3
    80003d54:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d56:	00e687bb          	addw	a5,a3,a4
    80003d5a:	0ed7e063          	bltu	a5,a3,80003e3a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d5e:	00043737          	lui	a4,0x43
    80003d62:	0cf76e63          	bltu	a4,a5,80003e3e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d66:	0a0b0763          	beqz	s6,80003e14 <writei+0xec>
    80003d6a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d70:	5cfd                	li	s9,-1
    80003d72:	a091                	j	80003db6 <writei+0x8e>
    80003d74:	02099d93          	slli	s11,s3,0x20
    80003d78:	020ddd93          	srli	s11,s11,0x20
    80003d7c:	05848793          	addi	a5,s1,88
    80003d80:	86ee                	mv	a3,s11
    80003d82:	8656                	mv	a2,s5
    80003d84:	85e2                	mv	a1,s8
    80003d86:	953e                	add	a0,a0,a5
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	a2c080e7          	jalr	-1492(ra) # 800027b4 <either_copyin>
    80003d90:	07950263          	beq	a0,s9,80003df4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d94:	8526                	mv	a0,s1
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	77a080e7          	jalr	1914(ra) # 80004510 <log_write>
    brelse(bp);
    80003d9e:	8526                	mv	a0,s1
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	50c080e7          	jalr	1292(ra) # 800032ac <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da8:	01498a3b          	addw	s4,s3,s4
    80003dac:	0129893b          	addw	s2,s3,s2
    80003db0:	9aee                	add	s5,s5,s11
    80003db2:	056a7663          	bgeu	s4,s6,80003dfe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003db6:	000ba483          	lw	s1,0(s7)
    80003dba:	00a9559b          	srliw	a1,s2,0xa
    80003dbe:	855e                	mv	a0,s7
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	7b0080e7          	jalr	1968(ra) # 80003570 <bmap>
    80003dc8:	0005059b          	sext.w	a1,a0
    80003dcc:	8526                	mv	a0,s1
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	3ae080e7          	jalr	942(ra) # 8000317c <bread>
    80003dd6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd8:	3ff97513          	andi	a0,s2,1023
    80003ddc:	40ad07bb          	subw	a5,s10,a0
    80003de0:	414b073b          	subw	a4,s6,s4
    80003de4:	89be                	mv	s3,a5
    80003de6:	2781                	sext.w	a5,a5
    80003de8:	0007069b          	sext.w	a3,a4
    80003dec:	f8f6f4e3          	bgeu	a3,a5,80003d74 <writei+0x4c>
    80003df0:	89ba                	mv	s3,a4
    80003df2:	b749                	j	80003d74 <writei+0x4c>
      brelse(bp);
    80003df4:	8526                	mv	a0,s1
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	4b6080e7          	jalr	1206(ra) # 800032ac <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003dfe:	04cba783          	lw	a5,76(s7)
    80003e02:	0127f463          	bgeu	a5,s2,80003e0a <writei+0xe2>
      ip->size = off;
    80003e06:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e0a:	855e                	mv	a0,s7
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	aa8080e7          	jalr	-1368(ra) # 800038b4 <iupdate>
  }

  return n;
    80003e14:	000b051b          	sext.w	a0,s6
}
    80003e18:	70a6                	ld	ra,104(sp)
    80003e1a:	7406                	ld	s0,96(sp)
    80003e1c:	64e6                	ld	s1,88(sp)
    80003e1e:	6946                	ld	s2,80(sp)
    80003e20:	69a6                	ld	s3,72(sp)
    80003e22:	6a06                	ld	s4,64(sp)
    80003e24:	7ae2                	ld	s5,56(sp)
    80003e26:	7b42                	ld	s6,48(sp)
    80003e28:	7ba2                	ld	s7,40(sp)
    80003e2a:	7c02                	ld	s8,32(sp)
    80003e2c:	6ce2                	ld	s9,24(sp)
    80003e2e:	6d42                	ld	s10,16(sp)
    80003e30:	6da2                	ld	s11,8(sp)
    80003e32:	6165                	addi	sp,sp,112
    80003e34:	8082                	ret
    return -1;
    80003e36:	557d                	li	a0,-1
}
    80003e38:	8082                	ret
    return -1;
    80003e3a:	557d                	li	a0,-1
    80003e3c:	bff1                	j	80003e18 <writei+0xf0>
    return -1;
    80003e3e:	557d                	li	a0,-1
    80003e40:	bfe1                	j	80003e18 <writei+0xf0>

0000000080003e42 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e42:	1141                	addi	sp,sp,-16
    80003e44:	e406                	sd	ra,8(sp)
    80003e46:	e022                	sd	s0,0(sp)
    80003e48:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e4a:	4639                	li	a2,14
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	f84080e7          	jalr	-124(ra) # 80000dd0 <strncmp>
}
    80003e54:	60a2                	ld	ra,8(sp)
    80003e56:	6402                	ld	s0,0(sp)
    80003e58:	0141                	addi	sp,sp,16
    80003e5a:	8082                	ret

0000000080003e5c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e5c:	7139                	addi	sp,sp,-64
    80003e5e:	fc06                	sd	ra,56(sp)
    80003e60:	f822                	sd	s0,48(sp)
    80003e62:	f426                	sd	s1,40(sp)
    80003e64:	f04a                	sd	s2,32(sp)
    80003e66:	ec4e                	sd	s3,24(sp)
    80003e68:	e852                	sd	s4,16(sp)
    80003e6a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e6c:	04451703          	lh	a4,68(a0)
    80003e70:	4785                	li	a5,1
    80003e72:	00f71a63          	bne	a4,a5,80003e86 <dirlookup+0x2a>
    80003e76:	892a                	mv	s2,a0
    80003e78:	89ae                	mv	s3,a1
    80003e7a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7c:	457c                	lw	a5,76(a0)
    80003e7e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e80:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e82:	e79d                	bnez	a5,80003eb0 <dirlookup+0x54>
    80003e84:	a8a5                	j	80003efc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e86:	00004517          	auipc	a0,0x4
    80003e8a:	79250513          	addi	a0,a0,1938 # 80008618 <syscalls+0x1a0>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6b2080e7          	jalr	1714(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e96:	00004517          	auipc	a0,0x4
    80003e9a:	79a50513          	addi	a0,a0,1946 # 80008630 <syscalls+0x1b8>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6a2080e7          	jalr	1698(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea6:	24c1                	addiw	s1,s1,16
    80003ea8:	04c92783          	lw	a5,76(s2)
    80003eac:	04f4f763          	bgeu	s1,a5,80003efa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb0:	4741                	li	a4,16
    80003eb2:	86a6                	mv	a3,s1
    80003eb4:	fc040613          	addi	a2,s0,-64
    80003eb8:	4581                	li	a1,0
    80003eba:	854a                	mv	a0,s2
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	d76080e7          	jalr	-650(ra) # 80003c32 <readi>
    80003ec4:	47c1                	li	a5,16
    80003ec6:	fcf518e3          	bne	a0,a5,80003e96 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eca:	fc045783          	lhu	a5,-64(s0)
    80003ece:	dfe1                	beqz	a5,80003ea6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ed0:	fc240593          	addi	a1,s0,-62
    80003ed4:	854e                	mv	a0,s3
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	f6c080e7          	jalr	-148(ra) # 80003e42 <namecmp>
    80003ede:	f561                	bnez	a0,80003ea6 <dirlookup+0x4a>
      if(poff)
    80003ee0:	000a0463          	beqz	s4,80003ee8 <dirlookup+0x8c>
        *poff = off;
    80003ee4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ee8:	fc045583          	lhu	a1,-64(s0)
    80003eec:	00092503          	lw	a0,0(s2)
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	75a080e7          	jalr	1882(ra) # 8000364a <iget>
    80003ef8:	a011                	j	80003efc <dirlookup+0xa0>
  return 0;
    80003efa:	4501                	li	a0,0
}
    80003efc:	70e2                	ld	ra,56(sp)
    80003efe:	7442                	ld	s0,48(sp)
    80003f00:	74a2                	ld	s1,40(sp)
    80003f02:	7902                	ld	s2,32(sp)
    80003f04:	69e2                	ld	s3,24(sp)
    80003f06:	6a42                	ld	s4,16(sp)
    80003f08:	6121                	addi	sp,sp,64
    80003f0a:	8082                	ret

0000000080003f0c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f0c:	711d                	addi	sp,sp,-96
    80003f0e:	ec86                	sd	ra,88(sp)
    80003f10:	e8a2                	sd	s0,80(sp)
    80003f12:	e4a6                	sd	s1,72(sp)
    80003f14:	e0ca                	sd	s2,64(sp)
    80003f16:	fc4e                	sd	s3,56(sp)
    80003f18:	f852                	sd	s4,48(sp)
    80003f1a:	f456                	sd	s5,40(sp)
    80003f1c:	f05a                	sd	s6,32(sp)
    80003f1e:	ec5e                	sd	s7,24(sp)
    80003f20:	e862                	sd	s8,16(sp)
    80003f22:	e466                	sd	s9,8(sp)
    80003f24:	1080                	addi	s0,sp,96
    80003f26:	84aa                	mv	s1,a0
    80003f28:	8aae                	mv	s5,a1
    80003f2a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f2c:	00054703          	lbu	a4,0(a0)
    80003f30:	02f00793          	li	a5,47
    80003f34:	02f70363          	beq	a4,a5,80003f5a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f38:	ffffe097          	auipc	ra,0xffffe
    80003f3c:	bfc080e7          	jalr	-1028(ra) # 80001b34 <myproc>
    80003f40:	15053503          	ld	a0,336(a0)
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	9fc080e7          	jalr	-1540(ra) # 80003940 <idup>
    80003f4c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f4e:	02f00913          	li	s2,47
  len = path - s;
    80003f52:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f54:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f56:	4b85                	li	s7,1
    80003f58:	a865                	j	80004010 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f5a:	4585                	li	a1,1
    80003f5c:	4505                	li	a0,1
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	6ec080e7          	jalr	1772(ra) # 8000364a <iget>
    80003f66:	89aa                	mv	s3,a0
    80003f68:	b7dd                	j	80003f4e <namex+0x42>
      iunlockput(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	c74080e7          	jalr	-908(ra) # 80003be0 <iunlockput>
      return 0;
    80003f74:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f76:	854e                	mv	a0,s3
    80003f78:	60e6                	ld	ra,88(sp)
    80003f7a:	6446                	ld	s0,80(sp)
    80003f7c:	64a6                	ld	s1,72(sp)
    80003f7e:	6906                	ld	s2,64(sp)
    80003f80:	79e2                	ld	s3,56(sp)
    80003f82:	7a42                	ld	s4,48(sp)
    80003f84:	7aa2                	ld	s5,40(sp)
    80003f86:	7b02                	ld	s6,32(sp)
    80003f88:	6be2                	ld	s7,24(sp)
    80003f8a:	6c42                	ld	s8,16(sp)
    80003f8c:	6ca2                	ld	s9,8(sp)
    80003f8e:	6125                	addi	sp,sp,96
    80003f90:	8082                	ret
      iunlock(ip);
    80003f92:	854e                	mv	a0,s3
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	aac080e7          	jalr	-1364(ra) # 80003a40 <iunlock>
      return ip;
    80003f9c:	bfe9                	j	80003f76 <namex+0x6a>
      iunlockput(ip);
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	c40080e7          	jalr	-960(ra) # 80003be0 <iunlockput>
      return 0;
    80003fa8:	89e6                	mv	s3,s9
    80003faa:	b7f1                	j	80003f76 <namex+0x6a>
  len = path - s;
    80003fac:	40b48633          	sub	a2,s1,a1
    80003fb0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fb4:	099c5463          	bge	s8,s9,8000403c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fb8:	4639                	li	a2,14
    80003fba:	8552                	mv	a0,s4
    80003fbc:	ffffd097          	auipc	ra,0xffffd
    80003fc0:	d98080e7          	jalr	-616(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003fc4:	0004c783          	lbu	a5,0(s1)
    80003fc8:	01279763          	bne	a5,s2,80003fd6 <namex+0xca>
    path++;
    80003fcc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fce:	0004c783          	lbu	a5,0(s1)
    80003fd2:	ff278de3          	beq	a5,s2,80003fcc <namex+0xc0>
    ilock(ip);
    80003fd6:	854e                	mv	a0,s3
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	9a6080e7          	jalr	-1626(ra) # 8000397e <ilock>
    if(ip->type != T_DIR){
    80003fe0:	04499783          	lh	a5,68(s3)
    80003fe4:	f97793e3          	bne	a5,s7,80003f6a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fe8:	000a8563          	beqz	s5,80003ff2 <namex+0xe6>
    80003fec:	0004c783          	lbu	a5,0(s1)
    80003ff0:	d3cd                	beqz	a5,80003f92 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff2:	865a                	mv	a2,s6
    80003ff4:	85d2                	mv	a1,s4
    80003ff6:	854e                	mv	a0,s3
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	e64080e7          	jalr	-412(ra) # 80003e5c <dirlookup>
    80004000:	8caa                	mv	s9,a0
    80004002:	dd51                	beqz	a0,80003f9e <namex+0x92>
    iunlockput(ip);
    80004004:	854e                	mv	a0,s3
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	bda080e7          	jalr	-1062(ra) # 80003be0 <iunlockput>
    ip = next;
    8000400e:	89e6                	mv	s3,s9
  while(*path == '/')
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	05279763          	bne	a5,s2,80004062 <namex+0x156>
    path++;
    80004018:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	ff278de3          	beq	a5,s2,80004018 <namex+0x10c>
  if(*path == 0)
    80004022:	c79d                	beqz	a5,80004050 <namex+0x144>
    path++;
    80004024:	85a6                	mv	a1,s1
  len = path - s;
    80004026:	8cda                	mv	s9,s6
    80004028:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000402a:	01278963          	beq	a5,s2,8000403c <namex+0x130>
    8000402e:	dfbd                	beqz	a5,80003fac <namex+0xa0>
    path++;
    80004030:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004032:	0004c783          	lbu	a5,0(s1)
    80004036:	ff279ce3          	bne	a5,s2,8000402e <namex+0x122>
    8000403a:	bf8d                	j	80003fac <namex+0xa0>
    memmove(name, s, len);
    8000403c:	2601                	sext.w	a2,a2
    8000403e:	8552                	mv	a0,s4
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	d14080e7          	jalr	-748(ra) # 80000d54 <memmove>
    name[len] = 0;
    80004048:	9cd2                	add	s9,s9,s4
    8000404a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000404e:	bf9d                	j	80003fc4 <namex+0xb8>
  if(nameiparent){
    80004050:	f20a83e3          	beqz	s5,80003f76 <namex+0x6a>
    iput(ip);
    80004054:	854e                	mv	a0,s3
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	ae2080e7          	jalr	-1310(ra) # 80003b38 <iput>
    return 0;
    8000405e:	4981                	li	s3,0
    80004060:	bf19                	j	80003f76 <namex+0x6a>
  if(*path == 0)
    80004062:	d7fd                	beqz	a5,80004050 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004064:	0004c783          	lbu	a5,0(s1)
    80004068:	85a6                	mv	a1,s1
    8000406a:	b7d1                	j	8000402e <namex+0x122>

000000008000406c <dirlink>:
{
    8000406c:	7139                	addi	sp,sp,-64
    8000406e:	fc06                	sd	ra,56(sp)
    80004070:	f822                	sd	s0,48(sp)
    80004072:	f426                	sd	s1,40(sp)
    80004074:	f04a                	sd	s2,32(sp)
    80004076:	ec4e                	sd	s3,24(sp)
    80004078:	e852                	sd	s4,16(sp)
    8000407a:	0080                	addi	s0,sp,64
    8000407c:	892a                	mv	s2,a0
    8000407e:	8a2e                	mv	s4,a1
    80004080:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004082:	4601                	li	a2,0
    80004084:	00000097          	auipc	ra,0x0
    80004088:	dd8080e7          	jalr	-552(ra) # 80003e5c <dirlookup>
    8000408c:	e93d                	bnez	a0,80004102 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408e:	04c92483          	lw	s1,76(s2)
    80004092:	c49d                	beqz	s1,800040c0 <dirlink+0x54>
    80004094:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004096:	4741                	li	a4,16
    80004098:	86a6                	mv	a3,s1
    8000409a:	fc040613          	addi	a2,s0,-64
    8000409e:	4581                	li	a1,0
    800040a0:	854a                	mv	a0,s2
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	b90080e7          	jalr	-1136(ra) # 80003c32 <readi>
    800040aa:	47c1                	li	a5,16
    800040ac:	06f51163          	bne	a0,a5,8000410e <dirlink+0xa2>
    if(de.inum == 0)
    800040b0:	fc045783          	lhu	a5,-64(s0)
    800040b4:	c791                	beqz	a5,800040c0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b6:	24c1                	addiw	s1,s1,16
    800040b8:	04c92783          	lw	a5,76(s2)
    800040bc:	fcf4ede3          	bltu	s1,a5,80004096 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c0:	4639                	li	a2,14
    800040c2:	85d2                	mv	a1,s4
    800040c4:	fc240513          	addi	a0,s0,-62
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	d44080e7          	jalr	-700(ra) # 80000e0c <strncpy>
  de.inum = inum;
    800040d0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d4:	4741                	li	a4,16
    800040d6:	86a6                	mv	a3,s1
    800040d8:	fc040613          	addi	a2,s0,-64
    800040dc:	4581                	li	a1,0
    800040de:	854a                	mv	a0,s2
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	c48080e7          	jalr	-952(ra) # 80003d28 <writei>
    800040e8:	872a                	mv	a4,a0
    800040ea:	47c1                	li	a5,16
  return 0;
    800040ec:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ee:	02f71863          	bne	a4,a5,8000411e <dirlink+0xb2>
}
    800040f2:	70e2                	ld	ra,56(sp)
    800040f4:	7442                	ld	s0,48(sp)
    800040f6:	74a2                	ld	s1,40(sp)
    800040f8:	7902                	ld	s2,32(sp)
    800040fa:	69e2                	ld	s3,24(sp)
    800040fc:	6a42                	ld	s4,16(sp)
    800040fe:	6121                	addi	sp,sp,64
    80004100:	8082                	ret
    iput(ip);
    80004102:	00000097          	auipc	ra,0x0
    80004106:	a36080e7          	jalr	-1482(ra) # 80003b38 <iput>
    return -1;
    8000410a:	557d                	li	a0,-1
    8000410c:	b7dd                	j	800040f2 <dirlink+0x86>
      panic("dirlink read");
    8000410e:	00004517          	auipc	a0,0x4
    80004112:	53250513          	addi	a0,a0,1330 # 80008640 <syscalls+0x1c8>
    80004116:	ffffc097          	auipc	ra,0xffffc
    8000411a:	42a080e7          	jalr	1066(ra) # 80000540 <panic>
    panic("dirlink");
    8000411e:	00004517          	auipc	a0,0x4
    80004122:	64250513          	addi	a0,a0,1602 # 80008760 <syscalls+0x2e8>
    80004126:	ffffc097          	auipc	ra,0xffffc
    8000412a:	41a080e7          	jalr	1050(ra) # 80000540 <panic>

000000008000412e <namei>:

struct inode*
namei(char *path)
{
    8000412e:	1101                	addi	sp,sp,-32
    80004130:	ec06                	sd	ra,24(sp)
    80004132:	e822                	sd	s0,16(sp)
    80004134:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004136:	fe040613          	addi	a2,s0,-32
    8000413a:	4581                	li	a1,0
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	dd0080e7          	jalr	-560(ra) # 80003f0c <namex>
}
    80004144:	60e2                	ld	ra,24(sp)
    80004146:	6442                	ld	s0,16(sp)
    80004148:	6105                	addi	sp,sp,32
    8000414a:	8082                	ret

000000008000414c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000414c:	1141                	addi	sp,sp,-16
    8000414e:	e406                	sd	ra,8(sp)
    80004150:	e022                	sd	s0,0(sp)
    80004152:	0800                	addi	s0,sp,16
    80004154:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004156:	4585                	li	a1,1
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	db4080e7          	jalr	-588(ra) # 80003f0c <namex>
}
    80004160:	60a2                	ld	ra,8(sp)
    80004162:	6402                	ld	s0,0(sp)
    80004164:	0141                	addi	sp,sp,16
    80004166:	8082                	ret

0000000080004168 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004168:	1101                	addi	sp,sp,-32
    8000416a:	ec06                	sd	ra,24(sp)
    8000416c:	e822                	sd	s0,16(sp)
    8000416e:	e426                	sd	s1,8(sp)
    80004170:	e04a                	sd	s2,0(sp)
    80004172:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004174:	0001e917          	auipc	s2,0x1e
    80004178:	59490913          	addi	s2,s2,1428 # 80022708 <log>
    8000417c:	01892583          	lw	a1,24(s2)
    80004180:	02892503          	lw	a0,40(s2)
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	ff8080e7          	jalr	-8(ra) # 8000317c <bread>
    8000418c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000418e:	02c92683          	lw	a3,44(s2)
    80004192:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004194:	02d05763          	blez	a3,800041c2 <write_head+0x5a>
    80004198:	0001e797          	auipc	a5,0x1e
    8000419c:	5a078793          	addi	a5,a5,1440 # 80022738 <log+0x30>
    800041a0:	05c50713          	addi	a4,a0,92
    800041a4:	36fd                	addiw	a3,a3,-1
    800041a6:	1682                	slli	a3,a3,0x20
    800041a8:	9281                	srli	a3,a3,0x20
    800041aa:	068a                	slli	a3,a3,0x2
    800041ac:	0001e617          	auipc	a2,0x1e
    800041b0:	59060613          	addi	a2,a2,1424 # 8002273c <log+0x34>
    800041b4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b6:	4390                	lw	a2,0(a5)
    800041b8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ba:	0791                	addi	a5,a5,4
    800041bc:	0711                	addi	a4,a4,4
    800041be:	fed79ce3          	bne	a5,a3,800041b6 <write_head+0x4e>
  }
  bwrite(buf);
    800041c2:	8526                	mv	a0,s1
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	0aa080e7          	jalr	170(ra) # 8000326e <bwrite>
  brelse(buf);
    800041cc:	8526                	mv	a0,s1
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	0de080e7          	jalr	222(ra) # 800032ac <brelse>
}
    800041d6:	60e2                	ld	ra,24(sp)
    800041d8:	6442                	ld	s0,16(sp)
    800041da:	64a2                	ld	s1,8(sp)
    800041dc:	6902                	ld	s2,0(sp)
    800041de:	6105                	addi	sp,sp,32
    800041e0:	8082                	ret

00000000800041e2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e2:	0001e797          	auipc	a5,0x1e
    800041e6:	5527a783          	lw	a5,1362(a5) # 80022734 <log+0x2c>
    800041ea:	0af05663          	blez	a5,80004296 <install_trans+0xb4>
{
    800041ee:	7139                	addi	sp,sp,-64
    800041f0:	fc06                	sd	ra,56(sp)
    800041f2:	f822                	sd	s0,48(sp)
    800041f4:	f426                	sd	s1,40(sp)
    800041f6:	f04a                	sd	s2,32(sp)
    800041f8:	ec4e                	sd	s3,24(sp)
    800041fa:	e852                	sd	s4,16(sp)
    800041fc:	e456                	sd	s5,8(sp)
    800041fe:	0080                	addi	s0,sp,64
    80004200:	0001ea97          	auipc	s5,0x1e
    80004204:	538a8a93          	addi	s5,s5,1336 # 80022738 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004208:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000420a:	0001e997          	auipc	s3,0x1e
    8000420e:	4fe98993          	addi	s3,s3,1278 # 80022708 <log>
    80004212:	0189a583          	lw	a1,24(s3)
    80004216:	014585bb          	addw	a1,a1,s4
    8000421a:	2585                	addiw	a1,a1,1
    8000421c:	0289a503          	lw	a0,40(s3)
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	f5c080e7          	jalr	-164(ra) # 8000317c <bread>
    80004228:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000422a:	000aa583          	lw	a1,0(s5)
    8000422e:	0289a503          	lw	a0,40(s3)
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	f4a080e7          	jalr	-182(ra) # 8000317c <bread>
    8000423a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000423c:	40000613          	li	a2,1024
    80004240:	05890593          	addi	a1,s2,88
    80004244:	05850513          	addi	a0,a0,88
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	b0c080e7          	jalr	-1268(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004250:	8526                	mv	a0,s1
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	01c080e7          	jalr	28(ra) # 8000326e <bwrite>
    bunpin(dbuf);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	12a080e7          	jalr	298(ra) # 80003386 <bunpin>
    brelse(lbuf);
    80004264:	854a                	mv	a0,s2
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	046080e7          	jalr	70(ra) # 800032ac <brelse>
    brelse(dbuf);
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	03c080e7          	jalr	60(ra) # 800032ac <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004278:	2a05                	addiw	s4,s4,1
    8000427a:	0a91                	addi	s5,s5,4
    8000427c:	02c9a783          	lw	a5,44(s3)
    80004280:	f8fa49e3          	blt	s4,a5,80004212 <install_trans+0x30>
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6aa2                	ld	s5,8(sp)
    80004292:	6121                	addi	sp,sp,64
    80004294:	8082                	ret
    80004296:	8082                	ret

0000000080004298 <initlog>:
{
    80004298:	7179                	addi	sp,sp,-48
    8000429a:	f406                	sd	ra,40(sp)
    8000429c:	f022                	sd	s0,32(sp)
    8000429e:	ec26                	sd	s1,24(sp)
    800042a0:	e84a                	sd	s2,16(sp)
    800042a2:	e44e                	sd	s3,8(sp)
    800042a4:	1800                	addi	s0,sp,48
    800042a6:	892a                	mv	s2,a0
    800042a8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042aa:	0001e497          	auipc	s1,0x1e
    800042ae:	45e48493          	addi	s1,s1,1118 # 80022708 <log>
    800042b2:	00004597          	auipc	a1,0x4
    800042b6:	39e58593          	addi	a1,a1,926 # 80008650 <syscalls+0x1d8>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	8b0080e7          	jalr	-1872(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800042c4:	0149a583          	lw	a1,20(s3)
    800042c8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042ca:	0109a783          	lw	a5,16(s3)
    800042ce:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042d0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042d4:	854a                	mv	a0,s2
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	ea6080e7          	jalr	-346(ra) # 8000317c <bread>
  log.lh.n = lh->n;
    800042de:	4d34                	lw	a3,88(a0)
    800042e0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e2:	02d05563          	blez	a3,8000430c <initlog+0x74>
    800042e6:	05c50793          	addi	a5,a0,92
    800042ea:	0001e717          	auipc	a4,0x1e
    800042ee:	44e70713          	addi	a4,a4,1102 # 80022738 <log+0x30>
    800042f2:	36fd                	addiw	a3,a3,-1
    800042f4:	1682                	slli	a3,a3,0x20
    800042f6:	9281                	srli	a3,a3,0x20
    800042f8:	068a                	slli	a3,a3,0x2
    800042fa:	06050613          	addi	a2,a0,96
    800042fe:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004300:	4390                	lw	a2,0(a5)
    80004302:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004304:	0791                	addi	a5,a5,4
    80004306:	0711                	addi	a4,a4,4
    80004308:	fed79ce3          	bne	a5,a3,80004300 <initlog+0x68>
  brelse(buf);
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	fa0080e7          	jalr	-96(ra) # 800032ac <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004314:	00000097          	auipc	ra,0x0
    80004318:	ece080e7          	jalr	-306(ra) # 800041e2 <install_trans>
  log.lh.n = 0;
    8000431c:	0001e797          	auipc	a5,0x1e
    80004320:	4007ac23          	sw	zero,1048(a5) # 80022734 <log+0x2c>
  write_head(); // clear the log
    80004324:	00000097          	auipc	ra,0x0
    80004328:	e44080e7          	jalr	-444(ra) # 80004168 <write_head>
}
    8000432c:	70a2                	ld	ra,40(sp)
    8000432e:	7402                	ld	s0,32(sp)
    80004330:	64e2                	ld	s1,24(sp)
    80004332:	6942                	ld	s2,16(sp)
    80004334:	69a2                	ld	s3,8(sp)
    80004336:	6145                	addi	sp,sp,48
    80004338:	8082                	ret

000000008000433a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000433a:	1101                	addi	sp,sp,-32
    8000433c:	ec06                	sd	ra,24(sp)
    8000433e:	e822                	sd	s0,16(sp)
    80004340:	e426                	sd	s1,8(sp)
    80004342:	e04a                	sd	s2,0(sp)
    80004344:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004346:	0001e517          	auipc	a0,0x1e
    8000434a:	3c250513          	addi	a0,a0,962 # 80022708 <log>
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	8ae080e7          	jalr	-1874(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004356:	0001e497          	auipc	s1,0x1e
    8000435a:	3b248493          	addi	s1,s1,946 # 80022708 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000435e:	4979                	li	s2,30
    80004360:	a039                	j	8000436e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004362:	85a6                	mv	a1,s1
    80004364:	8526                	mv	a0,s1
    80004366:	ffffe097          	auipc	ra,0xffffe
    8000436a:	104080e7          	jalr	260(ra) # 8000246a <sleep>
    if(log.committing){
    8000436e:	50dc                	lw	a5,36(s1)
    80004370:	fbed                	bnez	a5,80004362 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004372:	509c                	lw	a5,32(s1)
    80004374:	0017871b          	addiw	a4,a5,1
    80004378:	0007069b          	sext.w	a3,a4
    8000437c:	0027179b          	slliw	a5,a4,0x2
    80004380:	9fb9                	addw	a5,a5,a4
    80004382:	0017979b          	slliw	a5,a5,0x1
    80004386:	54d8                	lw	a4,44(s1)
    80004388:	9fb9                	addw	a5,a5,a4
    8000438a:	00f95963          	bge	s2,a5,8000439c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000438e:	85a6                	mv	a1,s1
    80004390:	8526                	mv	a0,s1
    80004392:	ffffe097          	auipc	ra,0xffffe
    80004396:	0d8080e7          	jalr	216(ra) # 8000246a <sleep>
    8000439a:	bfd1                	j	8000436e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000439c:	0001e517          	auipc	a0,0x1e
    800043a0:	36c50513          	addi	a0,a0,876 # 80022708 <log>
    800043a4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	90a080e7          	jalr	-1782(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043ba:	7139                	addi	sp,sp,-64
    800043bc:	fc06                	sd	ra,56(sp)
    800043be:	f822                	sd	s0,48(sp)
    800043c0:	f426                	sd	s1,40(sp)
    800043c2:	f04a                	sd	s2,32(sp)
    800043c4:	ec4e                	sd	s3,24(sp)
    800043c6:	e852                	sd	s4,16(sp)
    800043c8:	e456                	sd	s5,8(sp)
    800043ca:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043cc:	0001e497          	auipc	s1,0x1e
    800043d0:	33c48493          	addi	s1,s1,828 # 80022708 <log>
    800043d4:	8526                	mv	a0,s1
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	826080e7          	jalr	-2010(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    800043de:	509c                	lw	a5,32(s1)
    800043e0:	37fd                	addiw	a5,a5,-1
    800043e2:	0007891b          	sext.w	s2,a5
    800043e6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043e8:	50dc                	lw	a5,36(s1)
    800043ea:	e7b9                	bnez	a5,80004438 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ec:	04091e63          	bnez	s2,80004448 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043f0:	0001e497          	auipc	s1,0x1e
    800043f4:	31848493          	addi	s1,s1,792 # 80022708 <log>
    800043f8:	4785                	li	a5,1
    800043fa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	8b2080e7          	jalr	-1870(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004406:	54dc                	lw	a5,44(s1)
    80004408:	06f04763          	bgtz	a5,80004476 <end_op+0xbc>
    acquire(&log.lock);
    8000440c:	0001e497          	auipc	s1,0x1e
    80004410:	2fc48493          	addi	s1,s1,764 # 80022708 <log>
    80004414:	8526                	mv	a0,s1
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	7e6080e7          	jalr	2022(ra) # 80000bfc <acquire>
    log.committing = 0;
    8000441e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004422:	8526                	mv	a0,s1
    80004424:	ffffe097          	auipc	ra,0xffffe
    80004428:	1f2080e7          	jalr	498(ra) # 80002616 <wakeup>
    release(&log.lock);
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	882080e7          	jalr	-1918(ra) # 80000cb0 <release>
}
    80004436:	a03d                	j	80004464 <end_op+0xaa>
    panic("log.committing");
    80004438:	00004517          	auipc	a0,0x4
    8000443c:	22050513          	addi	a0,a0,544 # 80008658 <syscalls+0x1e0>
    80004440:	ffffc097          	auipc	ra,0xffffc
    80004444:	100080e7          	jalr	256(ra) # 80000540 <panic>
    wakeup(&log);
    80004448:	0001e497          	auipc	s1,0x1e
    8000444c:	2c048493          	addi	s1,s1,704 # 80022708 <log>
    80004450:	8526                	mv	a0,s1
    80004452:	ffffe097          	auipc	ra,0xffffe
    80004456:	1c4080e7          	jalr	452(ra) # 80002616 <wakeup>
  release(&log.lock);
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	854080e7          	jalr	-1964(ra) # 80000cb0 <release>
}
    80004464:	70e2                	ld	ra,56(sp)
    80004466:	7442                	ld	s0,48(sp)
    80004468:	74a2                	ld	s1,40(sp)
    8000446a:	7902                	ld	s2,32(sp)
    8000446c:	69e2                	ld	s3,24(sp)
    8000446e:	6a42                	ld	s4,16(sp)
    80004470:	6aa2                	ld	s5,8(sp)
    80004472:	6121                	addi	sp,sp,64
    80004474:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004476:	0001ea97          	auipc	s5,0x1e
    8000447a:	2c2a8a93          	addi	s5,s5,706 # 80022738 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000447e:	0001ea17          	auipc	s4,0x1e
    80004482:	28aa0a13          	addi	s4,s4,650 # 80022708 <log>
    80004486:	018a2583          	lw	a1,24(s4)
    8000448a:	012585bb          	addw	a1,a1,s2
    8000448e:	2585                	addiw	a1,a1,1
    80004490:	028a2503          	lw	a0,40(s4)
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	ce8080e7          	jalr	-792(ra) # 8000317c <bread>
    8000449c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000449e:	000aa583          	lw	a1,0(s5)
    800044a2:	028a2503          	lw	a0,40(s4)
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	cd6080e7          	jalr	-810(ra) # 8000317c <bread>
    800044ae:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044b0:	40000613          	li	a2,1024
    800044b4:	05850593          	addi	a1,a0,88
    800044b8:	05848513          	addi	a0,s1,88
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	898080e7          	jalr	-1896(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800044c4:	8526                	mv	a0,s1
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	da8080e7          	jalr	-600(ra) # 8000326e <bwrite>
    brelse(from);
    800044ce:	854e                	mv	a0,s3
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	ddc080e7          	jalr	-548(ra) # 800032ac <brelse>
    brelse(to);
    800044d8:	8526                	mv	a0,s1
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	dd2080e7          	jalr	-558(ra) # 800032ac <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e2:	2905                	addiw	s2,s2,1
    800044e4:	0a91                	addi	s5,s5,4
    800044e6:	02ca2783          	lw	a5,44(s4)
    800044ea:	f8f94ee3          	blt	s2,a5,80004486 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	c7a080e7          	jalr	-902(ra) # 80004168 <write_head>
    install_trans(); // Now install writes to home locations
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	cec080e7          	jalr	-788(ra) # 800041e2 <install_trans>
    log.lh.n = 0;
    800044fe:	0001e797          	auipc	a5,0x1e
    80004502:	2207ab23          	sw	zero,566(a5) # 80022734 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	c62080e7          	jalr	-926(ra) # 80004168 <write_head>
    8000450e:	bdfd                	j	8000440c <end_op+0x52>

0000000080004510 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	e04a                	sd	s2,0(sp)
    8000451a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000451c:	0001e717          	auipc	a4,0x1e
    80004520:	21872703          	lw	a4,536(a4) # 80022734 <log+0x2c>
    80004524:	47f5                	li	a5,29
    80004526:	08e7c063          	blt	a5,a4,800045a6 <log_write+0x96>
    8000452a:	84aa                	mv	s1,a0
    8000452c:	0001e797          	auipc	a5,0x1e
    80004530:	1f87a783          	lw	a5,504(a5) # 80022724 <log+0x1c>
    80004534:	37fd                	addiw	a5,a5,-1
    80004536:	06f75863          	bge	a4,a5,800045a6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000453a:	0001e797          	auipc	a5,0x1e
    8000453e:	1ee7a783          	lw	a5,494(a5) # 80022728 <log+0x20>
    80004542:	06f05a63          	blez	a5,800045b6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004546:	0001e917          	auipc	s2,0x1e
    8000454a:	1c290913          	addi	s2,s2,450 # 80022708 <log>
    8000454e:	854a                	mv	a0,s2
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	6ac080e7          	jalr	1708(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004558:	02c92603          	lw	a2,44(s2)
    8000455c:	06c05563          	blez	a2,800045c6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004560:	44cc                	lw	a1,12(s1)
    80004562:	0001e717          	auipc	a4,0x1e
    80004566:	1d670713          	addi	a4,a4,470 # 80022738 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456c:	4314                	lw	a3,0(a4)
    8000456e:	04b68d63          	beq	a3,a1,800045c8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004572:	2785                	addiw	a5,a5,1
    80004574:	0711                	addi	a4,a4,4
    80004576:	fec79be3          	bne	a5,a2,8000456c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000457a:	0621                	addi	a2,a2,8
    8000457c:	060a                	slli	a2,a2,0x2
    8000457e:	0001e797          	auipc	a5,0x1e
    80004582:	18a78793          	addi	a5,a5,394 # 80022708 <log>
    80004586:	963e                	add	a2,a2,a5
    80004588:	44dc                	lw	a5,12(s1)
    8000458a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000458c:	8526                	mv	a0,s1
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	dbc080e7          	jalr	-580(ra) # 8000334a <bpin>
    log.lh.n++;
    80004596:	0001e717          	auipc	a4,0x1e
    8000459a:	17270713          	addi	a4,a4,370 # 80022708 <log>
    8000459e:	575c                	lw	a5,44(a4)
    800045a0:	2785                	addiw	a5,a5,1
    800045a2:	d75c                	sw	a5,44(a4)
    800045a4:	a83d                	j	800045e2 <log_write+0xd2>
    panic("too big a transaction");
    800045a6:	00004517          	auipc	a0,0x4
    800045aa:	0c250513          	addi	a0,a0,194 # 80008668 <syscalls+0x1f0>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	f92080e7          	jalr	-110(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	0ca50513          	addi	a0,a0,202 # 80008680 <syscalls+0x208>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f82080e7          	jalr	-126(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045c6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045c8:	00878713          	addi	a4,a5,8
    800045cc:	00271693          	slli	a3,a4,0x2
    800045d0:	0001e717          	auipc	a4,0x1e
    800045d4:	13870713          	addi	a4,a4,312 # 80022708 <log>
    800045d8:	9736                	add	a4,a4,a3
    800045da:	44d4                	lw	a3,12(s1)
    800045dc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045de:	faf607e3          	beq	a2,a5,8000458c <log_write+0x7c>
  }
  release(&log.lock);
    800045e2:	0001e517          	auipc	a0,0x1e
    800045e6:	12650513          	addi	a0,a0,294 # 80022708 <log>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6c6080e7          	jalr	1734(ra) # 80000cb0 <release>
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6902                	ld	s2,0(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	addi	s0,sp,32
    8000460a:	84aa                	mv	s1,a0
    8000460c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000460e:	00004597          	auipc	a1,0x4
    80004612:	09258593          	addi	a1,a1,146 # 800086a0 <syscalls+0x228>
    80004616:	0521                	addi	a0,a0,8
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	554080e7          	jalr	1364(ra) # 80000b6c <initlock>
  lk->name = name;
    80004620:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004624:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004628:	0204a423          	sw	zero,40(s1)
}
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6902                	ld	s2,0(sp)
    80004634:	6105                	addi	sp,sp,32
    80004636:	8082                	ret

0000000080004638 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004638:	1101                	addi	sp,sp,-32
    8000463a:	ec06                	sd	ra,24(sp)
    8000463c:	e822                	sd	s0,16(sp)
    8000463e:	e426                	sd	s1,8(sp)
    80004640:	e04a                	sd	s2,0(sp)
    80004642:	1000                	addi	s0,sp,32
    80004644:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004646:	00850913          	addi	s2,a0,8
    8000464a:	854a                	mv	a0,s2
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	5b0080e7          	jalr	1456(ra) # 80000bfc <acquire>
  while (lk->locked) {
    80004654:	409c                	lw	a5,0(s1)
    80004656:	cb89                	beqz	a5,80004668 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004658:	85ca                	mv	a1,s2
    8000465a:	8526                	mv	a0,s1
    8000465c:	ffffe097          	auipc	ra,0xffffe
    80004660:	e0e080e7          	jalr	-498(ra) # 8000246a <sleep>
  while (lk->locked) {
    80004664:	409c                	lw	a5,0(s1)
    80004666:	fbed                	bnez	a5,80004658 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004668:	4785                	li	a5,1
    8000466a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000466c:	ffffd097          	auipc	ra,0xffffd
    80004670:	4c8080e7          	jalr	1224(ra) # 80001b34 <myproc>
    80004674:	5d1c                	lw	a5,56(a0)
    80004676:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004678:	854a                	mv	a0,s2
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	636080e7          	jalr	1590(ra) # 80000cb0 <release>
}
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6902                	ld	s2,0(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	e04a                	sd	s2,0(sp)
    80004698:	1000                	addi	s0,sp,32
    8000469a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000469c:	00850913          	addi	s2,a0,8
    800046a0:	854a                	mv	a0,s2
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	55a080e7          	jalr	1370(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800046aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ae:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046b2:	8526                	mv	a0,s1
    800046b4:	ffffe097          	auipc	ra,0xffffe
    800046b8:	f62080e7          	jalr	-158(ra) # 80002616 <wakeup>
  release(&lk->lk);
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5f2080e7          	jalr	1522(ra) # 80000cb0 <release>
}
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6902                	ld	s2,0(sp)
    800046ce:	6105                	addi	sp,sp,32
    800046d0:	8082                	ret

00000000800046d2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046d2:	7179                	addi	sp,sp,-48
    800046d4:	f406                	sd	ra,40(sp)
    800046d6:	f022                	sd	s0,32(sp)
    800046d8:	ec26                	sd	s1,24(sp)
    800046da:	e84a                	sd	s2,16(sp)
    800046dc:	e44e                	sd	s3,8(sp)
    800046de:	1800                	addi	s0,sp,48
    800046e0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046e2:	00850913          	addi	s2,a0,8
    800046e6:	854a                	mv	a0,s2
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	514080e7          	jalr	1300(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f0:	409c                	lw	a5,0(s1)
    800046f2:	ef99                	bnez	a5,80004710 <holdingsleep+0x3e>
    800046f4:	4481                	li	s1,0
  release(&lk->lk);
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	5b8080e7          	jalr	1464(ra) # 80000cb0 <release>
  return r;
}
    80004700:	8526                	mv	a0,s1
    80004702:	70a2                	ld	ra,40(sp)
    80004704:	7402                	ld	s0,32(sp)
    80004706:	64e2                	ld	s1,24(sp)
    80004708:	6942                	ld	s2,16(sp)
    8000470a:	69a2                	ld	s3,8(sp)
    8000470c:	6145                	addi	sp,sp,48
    8000470e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004710:	0284a983          	lw	s3,40(s1)
    80004714:	ffffd097          	auipc	ra,0xffffd
    80004718:	420080e7          	jalr	1056(ra) # 80001b34 <myproc>
    8000471c:	5d04                	lw	s1,56(a0)
    8000471e:	413484b3          	sub	s1,s1,s3
    80004722:	0014b493          	seqz	s1,s1
    80004726:	bfc1                	j	800046f6 <holdingsleep+0x24>

0000000080004728 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004728:	1141                	addi	sp,sp,-16
    8000472a:	e406                	sd	ra,8(sp)
    8000472c:	e022                	sd	s0,0(sp)
    8000472e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004730:	00004597          	auipc	a1,0x4
    80004734:	f8058593          	addi	a1,a1,-128 # 800086b0 <syscalls+0x238>
    80004738:	0001e517          	auipc	a0,0x1e
    8000473c:	11850513          	addi	a0,a0,280 # 80022850 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	42c080e7          	jalr	1068(ra) # 80000b6c <initlock>
}
    80004748:	60a2                	ld	ra,8(sp)
    8000474a:	6402                	ld	s0,0(sp)
    8000474c:	0141                	addi	sp,sp,16
    8000474e:	8082                	ret

0000000080004750 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004750:	1101                	addi	sp,sp,-32
    80004752:	ec06                	sd	ra,24(sp)
    80004754:	e822                	sd	s0,16(sp)
    80004756:	e426                	sd	s1,8(sp)
    80004758:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000475a:	0001e517          	auipc	a0,0x1e
    8000475e:	0f650513          	addi	a0,a0,246 # 80022850 <ftable>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	49a080e7          	jalr	1178(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000476a:	0001e497          	auipc	s1,0x1e
    8000476e:	0fe48493          	addi	s1,s1,254 # 80022868 <ftable+0x18>
    80004772:	0001f717          	auipc	a4,0x1f
    80004776:	09670713          	addi	a4,a4,150 # 80023808 <ftable+0xfb8>
    if(f->ref == 0){
    8000477a:	40dc                	lw	a5,4(s1)
    8000477c:	cf99                	beqz	a5,8000479a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477e:	02848493          	addi	s1,s1,40
    80004782:	fee49ce3          	bne	s1,a4,8000477a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004786:	0001e517          	auipc	a0,0x1e
    8000478a:	0ca50513          	addi	a0,a0,202 # 80022850 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	522080e7          	jalr	1314(ra) # 80000cb0 <release>
  return 0;
    80004796:	4481                	li	s1,0
    80004798:	a819                	j	800047ae <filealloc+0x5e>
      f->ref = 1;
    8000479a:	4785                	li	a5,1
    8000479c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000479e:	0001e517          	auipc	a0,0x1e
    800047a2:	0b250513          	addi	a0,a0,178 # 80022850 <ftable>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	50a080e7          	jalr	1290(ra) # 80000cb0 <release>
}
    800047ae:	8526                	mv	a0,s1
    800047b0:	60e2                	ld	ra,24(sp)
    800047b2:	6442                	ld	s0,16(sp)
    800047b4:	64a2                	ld	s1,8(sp)
    800047b6:	6105                	addi	sp,sp,32
    800047b8:	8082                	ret

00000000800047ba <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047ba:	1101                	addi	sp,sp,-32
    800047bc:	ec06                	sd	ra,24(sp)
    800047be:	e822                	sd	s0,16(sp)
    800047c0:	e426                	sd	s1,8(sp)
    800047c2:	1000                	addi	s0,sp,32
    800047c4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047c6:	0001e517          	auipc	a0,0x1e
    800047ca:	08a50513          	addi	a0,a0,138 # 80022850 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	42e080e7          	jalr	1070(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047d6:	40dc                	lw	a5,4(s1)
    800047d8:	02f05263          	blez	a5,800047fc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047dc:	2785                	addiw	a5,a5,1
    800047de:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e0:	0001e517          	auipc	a0,0x1e
    800047e4:	07050513          	addi	a0,a0,112 # 80022850 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	4c8080e7          	jalr	1224(ra) # 80000cb0 <release>
  return f;
}
    800047f0:	8526                	mv	a0,s1
    800047f2:	60e2                	ld	ra,24(sp)
    800047f4:	6442                	ld	s0,16(sp)
    800047f6:	64a2                	ld	s1,8(sp)
    800047f8:	6105                	addi	sp,sp,32
    800047fa:	8082                	ret
    panic("filedup");
    800047fc:	00004517          	auipc	a0,0x4
    80004800:	ebc50513          	addi	a0,a0,-324 # 800086b8 <syscalls+0x240>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	d3c080e7          	jalr	-708(ra) # 80000540 <panic>

000000008000480c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000480c:	7139                	addi	sp,sp,-64
    8000480e:	fc06                	sd	ra,56(sp)
    80004810:	f822                	sd	s0,48(sp)
    80004812:	f426                	sd	s1,40(sp)
    80004814:	f04a                	sd	s2,32(sp)
    80004816:	ec4e                	sd	s3,24(sp)
    80004818:	e852                	sd	s4,16(sp)
    8000481a:	e456                	sd	s5,8(sp)
    8000481c:	0080                	addi	s0,sp,64
    8000481e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004820:	0001e517          	auipc	a0,0x1e
    80004824:	03050513          	addi	a0,a0,48 # 80022850 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	3d4080e7          	jalr	980(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    80004830:	40dc                	lw	a5,4(s1)
    80004832:	06f05163          	blez	a5,80004894 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004836:	37fd                	addiw	a5,a5,-1
    80004838:	0007871b          	sext.w	a4,a5
    8000483c:	c0dc                	sw	a5,4(s1)
    8000483e:	06e04363          	bgtz	a4,800048a4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004842:	0004a903          	lw	s2,0(s1)
    80004846:	0094ca83          	lbu	s5,9(s1)
    8000484a:	0104ba03          	ld	s4,16(s1)
    8000484e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004852:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004856:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000485a:	0001e517          	auipc	a0,0x1e
    8000485e:	ff650513          	addi	a0,a0,-10 # 80022850 <ftable>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	44e080e7          	jalr	1102(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    8000486a:	4785                	li	a5,1
    8000486c:	04f90d63          	beq	s2,a5,800048c6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004870:	3979                	addiw	s2,s2,-2
    80004872:	4785                	li	a5,1
    80004874:	0527e063          	bltu	a5,s2,800048b4 <fileclose+0xa8>
    begin_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	ac2080e7          	jalr	-1342(ra) # 8000433a <begin_op>
    iput(ff.ip);
    80004880:	854e                	mv	a0,s3
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	2b6080e7          	jalr	694(ra) # 80003b38 <iput>
    end_op();
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	b30080e7          	jalr	-1232(ra) # 800043ba <end_op>
    80004892:	a00d                	j	800048b4 <fileclose+0xa8>
    panic("fileclose");
    80004894:	00004517          	auipc	a0,0x4
    80004898:	e2c50513          	addi	a0,a0,-468 # 800086c0 <syscalls+0x248>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	ca4080e7          	jalr	-860(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048a4:	0001e517          	auipc	a0,0x1e
    800048a8:	fac50513          	addi	a0,a0,-84 # 80022850 <ftable>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	404080e7          	jalr	1028(ra) # 80000cb0 <release>
  }
}
    800048b4:	70e2                	ld	ra,56(sp)
    800048b6:	7442                	ld	s0,48(sp)
    800048b8:	74a2                	ld	s1,40(sp)
    800048ba:	7902                	ld	s2,32(sp)
    800048bc:	69e2                	ld	s3,24(sp)
    800048be:	6a42                	ld	s4,16(sp)
    800048c0:	6aa2                	ld	s5,8(sp)
    800048c2:	6121                	addi	sp,sp,64
    800048c4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048c6:	85d6                	mv	a1,s5
    800048c8:	8552                	mv	a0,s4
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	372080e7          	jalr	882(ra) # 80004c3c <pipeclose>
    800048d2:	b7cd                	j	800048b4 <fileclose+0xa8>

00000000800048d4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d4:	715d                	addi	sp,sp,-80
    800048d6:	e486                	sd	ra,72(sp)
    800048d8:	e0a2                	sd	s0,64(sp)
    800048da:	fc26                	sd	s1,56(sp)
    800048dc:	f84a                	sd	s2,48(sp)
    800048de:	f44e                	sd	s3,40(sp)
    800048e0:	0880                	addi	s0,sp,80
    800048e2:	84aa                	mv	s1,a0
    800048e4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048e6:	ffffd097          	auipc	ra,0xffffd
    800048ea:	24e080e7          	jalr	590(ra) # 80001b34 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ee:	409c                	lw	a5,0(s1)
    800048f0:	37f9                	addiw	a5,a5,-2
    800048f2:	4705                	li	a4,1
    800048f4:	04f76763          	bltu	a4,a5,80004942 <filestat+0x6e>
    800048f8:	892a                	mv	s2,a0
    ilock(f->ip);
    800048fa:	6c88                	ld	a0,24(s1)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	082080e7          	jalr	130(ra) # 8000397e <ilock>
    stati(f->ip, &st);
    80004904:	fb840593          	addi	a1,s0,-72
    80004908:	6c88                	ld	a0,24(s1)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	2fe080e7          	jalr	766(ra) # 80003c08 <stati>
    iunlock(f->ip);
    80004912:	6c88                	ld	a0,24(s1)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	12c080e7          	jalr	300(ra) # 80003a40 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000491c:	46e1                	li	a3,24
    8000491e:	fb840613          	addi	a2,s0,-72
    80004922:	85ce                	mv	a1,s3
    80004924:	05093503          	ld	a0,80(s2)
    80004928:	ffffd097          	auipc	ra,0xffffd
    8000492c:	d82080e7          	jalr	-638(ra) # 800016aa <copyout>
    80004930:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004934:	60a6                	ld	ra,72(sp)
    80004936:	6406                	ld	s0,64(sp)
    80004938:	74e2                	ld	s1,56(sp)
    8000493a:	7942                	ld	s2,48(sp)
    8000493c:	79a2                	ld	s3,40(sp)
    8000493e:	6161                	addi	sp,sp,80
    80004940:	8082                	ret
  return -1;
    80004942:	557d                	li	a0,-1
    80004944:	bfc5                	j	80004934 <filestat+0x60>

0000000080004946 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004946:	7179                	addi	sp,sp,-48
    80004948:	f406                	sd	ra,40(sp)
    8000494a:	f022                	sd	s0,32(sp)
    8000494c:	ec26                	sd	s1,24(sp)
    8000494e:	e84a                	sd	s2,16(sp)
    80004950:	e44e                	sd	s3,8(sp)
    80004952:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004954:	00854783          	lbu	a5,8(a0)
    80004958:	c3d5                	beqz	a5,800049fc <fileread+0xb6>
    8000495a:	84aa                	mv	s1,a0
    8000495c:	89ae                	mv	s3,a1
    8000495e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004960:	411c                	lw	a5,0(a0)
    80004962:	4705                	li	a4,1
    80004964:	04e78963          	beq	a5,a4,800049b6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004968:	470d                	li	a4,3
    8000496a:	04e78d63          	beq	a5,a4,800049c4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000496e:	4709                	li	a4,2
    80004970:	06e79e63          	bne	a5,a4,800049ec <fileread+0xa6>
    ilock(f->ip);
    80004974:	6d08                	ld	a0,24(a0)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	008080e7          	jalr	8(ra) # 8000397e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000497e:	874a                	mv	a4,s2
    80004980:	5094                	lw	a3,32(s1)
    80004982:	864e                	mv	a2,s3
    80004984:	4585                	li	a1,1
    80004986:	6c88                	ld	a0,24(s1)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	2aa080e7          	jalr	682(ra) # 80003c32 <readi>
    80004990:	892a                	mv	s2,a0
    80004992:	00a05563          	blez	a0,8000499c <fileread+0x56>
      f->off += r;
    80004996:	509c                	lw	a5,32(s1)
    80004998:	9fa9                	addw	a5,a5,a0
    8000499a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000499c:	6c88                	ld	a0,24(s1)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	0a2080e7          	jalr	162(ra) # 80003a40 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049a6:	854a                	mv	a0,s2
    800049a8:	70a2                	ld	ra,40(sp)
    800049aa:	7402                	ld	s0,32(sp)
    800049ac:	64e2                	ld	s1,24(sp)
    800049ae:	6942                	ld	s2,16(sp)
    800049b0:	69a2                	ld	s3,8(sp)
    800049b2:	6145                	addi	sp,sp,48
    800049b4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049b6:	6908                	ld	a0,16(a0)
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	3f4080e7          	jalr	1012(ra) # 80004dac <piperead>
    800049c0:	892a                	mv	s2,a0
    800049c2:	b7d5                	j	800049a6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c4:	02451783          	lh	a5,36(a0)
    800049c8:	03079693          	slli	a3,a5,0x30
    800049cc:	92c1                	srli	a3,a3,0x30
    800049ce:	4725                	li	a4,9
    800049d0:	02d76863          	bltu	a4,a3,80004a00 <fileread+0xba>
    800049d4:	0792                	slli	a5,a5,0x4
    800049d6:	0001e717          	auipc	a4,0x1e
    800049da:	dda70713          	addi	a4,a4,-550 # 800227b0 <devsw>
    800049de:	97ba                	add	a5,a5,a4
    800049e0:	639c                	ld	a5,0(a5)
    800049e2:	c38d                	beqz	a5,80004a04 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e4:	4505                	li	a0,1
    800049e6:	9782                	jalr	a5
    800049e8:	892a                	mv	s2,a0
    800049ea:	bf75                	j	800049a6 <fileread+0x60>
    panic("fileread");
    800049ec:	00004517          	auipc	a0,0x4
    800049f0:	ce450513          	addi	a0,a0,-796 # 800086d0 <syscalls+0x258>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	b4c080e7          	jalr	-1204(ra) # 80000540 <panic>
    return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	b765                	j	800049a6 <fileread+0x60>
      return -1;
    80004a00:	597d                	li	s2,-1
    80004a02:	b755                	j	800049a6 <fileread+0x60>
    80004a04:	597d                	li	s2,-1
    80004a06:	b745                	j	800049a6 <fileread+0x60>

0000000080004a08 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a08:	00954783          	lbu	a5,9(a0)
    80004a0c:	14078563          	beqz	a5,80004b56 <filewrite+0x14e>
{
    80004a10:	715d                	addi	sp,sp,-80
    80004a12:	e486                	sd	ra,72(sp)
    80004a14:	e0a2                	sd	s0,64(sp)
    80004a16:	fc26                	sd	s1,56(sp)
    80004a18:	f84a                	sd	s2,48(sp)
    80004a1a:	f44e                	sd	s3,40(sp)
    80004a1c:	f052                	sd	s4,32(sp)
    80004a1e:	ec56                	sd	s5,24(sp)
    80004a20:	e85a                	sd	s6,16(sp)
    80004a22:	e45e                	sd	s7,8(sp)
    80004a24:	e062                	sd	s8,0(sp)
    80004a26:	0880                	addi	s0,sp,80
    80004a28:	892a                	mv	s2,a0
    80004a2a:	8aae                	mv	s5,a1
    80004a2c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2e:	411c                	lw	a5,0(a0)
    80004a30:	4705                	li	a4,1
    80004a32:	02e78263          	beq	a5,a4,80004a56 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a36:	470d                	li	a4,3
    80004a38:	02e78563          	beq	a5,a4,80004a62 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a3c:	4709                	li	a4,2
    80004a3e:	10e79463          	bne	a5,a4,80004b46 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a42:	0ec05e63          	blez	a2,80004b3e <filewrite+0x136>
    int i = 0;
    80004a46:	4981                	li	s3,0
    80004a48:	6b05                	lui	s6,0x1
    80004a4a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a4e:	6b85                	lui	s7,0x1
    80004a50:	c00b8b9b          	addiw	s7,s7,-1024
    80004a54:	a851                	j	80004ae8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a56:	6908                	ld	a0,16(a0)
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	254080e7          	jalr	596(ra) # 80004cac <pipewrite>
    80004a60:	a85d                	j	80004b16 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a62:	02451783          	lh	a5,36(a0)
    80004a66:	03079693          	slli	a3,a5,0x30
    80004a6a:	92c1                	srli	a3,a3,0x30
    80004a6c:	4725                	li	a4,9
    80004a6e:	0ed76663          	bltu	a4,a3,80004b5a <filewrite+0x152>
    80004a72:	0792                	slli	a5,a5,0x4
    80004a74:	0001e717          	auipc	a4,0x1e
    80004a78:	d3c70713          	addi	a4,a4,-708 # 800227b0 <devsw>
    80004a7c:	97ba                	add	a5,a5,a4
    80004a7e:	679c                	ld	a5,8(a5)
    80004a80:	cff9                	beqz	a5,80004b5e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a82:	4505                	li	a0,1
    80004a84:	9782                	jalr	a5
    80004a86:	a841                	j	80004b16 <filewrite+0x10e>
    80004a88:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	8ae080e7          	jalr	-1874(ra) # 8000433a <begin_op>
      ilock(f->ip);
    80004a94:	01893503          	ld	a0,24(s2)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	ee6080e7          	jalr	-282(ra) # 8000397e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa0:	8762                	mv	a4,s8
    80004aa2:	02092683          	lw	a3,32(s2)
    80004aa6:	01598633          	add	a2,s3,s5
    80004aaa:	4585                	li	a1,1
    80004aac:	01893503          	ld	a0,24(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	278080e7          	jalr	632(ra) # 80003d28 <writei>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	02a05f63          	blez	a0,80004af8 <filewrite+0xf0>
        f->off += r;
    80004abe:	02092783          	lw	a5,32(s2)
    80004ac2:	9fa9                	addw	a5,a5,a0
    80004ac4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ac8:	01893503          	ld	a0,24(s2)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	f74080e7          	jalr	-140(ra) # 80003a40 <iunlock>
      end_op();
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	8e6080e7          	jalr	-1818(ra) # 800043ba <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004adc:	049c1963          	bne	s8,s1,80004b2e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004ae0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae4:	0349d663          	bge	s3,s4,80004b10 <filewrite+0x108>
      int n1 = n - i;
    80004ae8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aec:	84be                	mv	s1,a5
    80004aee:	2781                	sext.w	a5,a5
    80004af0:	f8fb5ce3          	bge	s6,a5,80004a88 <filewrite+0x80>
    80004af4:	84de                	mv	s1,s7
    80004af6:	bf49                	j	80004a88 <filewrite+0x80>
      iunlock(f->ip);
    80004af8:	01893503          	ld	a0,24(s2)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	f44080e7          	jalr	-188(ra) # 80003a40 <iunlock>
      end_op();
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	8b6080e7          	jalr	-1866(ra) # 800043ba <end_op>
      if(r < 0)
    80004b0c:	fc04d8e3          	bgez	s1,80004adc <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b10:	8552                	mv	a0,s4
    80004b12:	033a1863          	bne	s4,s3,80004b42 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b16:	60a6                	ld	ra,72(sp)
    80004b18:	6406                	ld	s0,64(sp)
    80004b1a:	74e2                	ld	s1,56(sp)
    80004b1c:	7942                	ld	s2,48(sp)
    80004b1e:	79a2                	ld	s3,40(sp)
    80004b20:	7a02                	ld	s4,32(sp)
    80004b22:	6ae2                	ld	s5,24(sp)
    80004b24:	6b42                	ld	s6,16(sp)
    80004b26:	6ba2                	ld	s7,8(sp)
    80004b28:	6c02                	ld	s8,0(sp)
    80004b2a:	6161                	addi	sp,sp,80
    80004b2c:	8082                	ret
        panic("short filewrite");
    80004b2e:	00004517          	auipc	a0,0x4
    80004b32:	bb250513          	addi	a0,a0,-1102 # 800086e0 <syscalls+0x268>
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	a0a080e7          	jalr	-1526(ra) # 80000540 <panic>
    int i = 0;
    80004b3e:	4981                	li	s3,0
    80004b40:	bfc1                	j	80004b10 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b42:	557d                	li	a0,-1
    80004b44:	bfc9                	j	80004b16 <filewrite+0x10e>
    panic("filewrite");
    80004b46:	00004517          	auipc	a0,0x4
    80004b4a:	baa50513          	addi	a0,a0,-1110 # 800086f0 <syscalls+0x278>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	9f2080e7          	jalr	-1550(ra) # 80000540 <panic>
    return -1;
    80004b56:	557d                	li	a0,-1
}
    80004b58:	8082                	ret
      return -1;
    80004b5a:	557d                	li	a0,-1
    80004b5c:	bf6d                	j	80004b16 <filewrite+0x10e>
    80004b5e:	557d                	li	a0,-1
    80004b60:	bf5d                	j	80004b16 <filewrite+0x10e>

0000000080004b62 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b62:	7179                	addi	sp,sp,-48
    80004b64:	f406                	sd	ra,40(sp)
    80004b66:	f022                	sd	s0,32(sp)
    80004b68:	ec26                	sd	s1,24(sp)
    80004b6a:	e84a                	sd	s2,16(sp)
    80004b6c:	e44e                	sd	s3,8(sp)
    80004b6e:	e052                	sd	s4,0(sp)
    80004b70:	1800                	addi	s0,sp,48
    80004b72:	84aa                	mv	s1,a0
    80004b74:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b76:	0005b023          	sd	zero,0(a1)
    80004b7a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	bd2080e7          	jalr	-1070(ra) # 80004750 <filealloc>
    80004b86:	e088                	sd	a0,0(s1)
    80004b88:	c551                	beqz	a0,80004c14 <pipealloc+0xb2>
    80004b8a:	00000097          	auipc	ra,0x0
    80004b8e:	bc6080e7          	jalr	-1082(ra) # 80004750 <filealloc>
    80004b92:	00aa3023          	sd	a0,0(s4)
    80004b96:	c92d                	beqz	a0,80004c08 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	f74080e7          	jalr	-140(ra) # 80000b0c <kalloc>
    80004ba0:	892a                	mv	s2,a0
    80004ba2:	c125                	beqz	a0,80004c02 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ba4:	4985                	li	s3,1
    80004ba6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004baa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bae:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bb2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bb6:	00004597          	auipc	a1,0x4
    80004bba:	b4a58593          	addi	a1,a1,-1206 # 80008700 <syscalls+0x288>
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	fae080e7          	jalr	-82(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004bc6:	609c                	ld	a5,0(s1)
    80004bc8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bcc:	609c                	ld	a5,0(s1)
    80004bce:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bd2:	609c                	ld	a5,0(s1)
    80004bd4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bd8:	609c                	ld	a5,0(s1)
    80004bda:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bde:	000a3783          	ld	a5,0(s4)
    80004be2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004be6:	000a3783          	ld	a5,0(s4)
    80004bea:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bee:	000a3783          	ld	a5,0(s4)
    80004bf2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bf6:	000a3783          	ld	a5,0(s4)
    80004bfa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bfe:	4501                	li	a0,0
    80004c00:	a025                	j	80004c28 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c02:	6088                	ld	a0,0(s1)
    80004c04:	e501                	bnez	a0,80004c0c <pipealloc+0xaa>
    80004c06:	a039                	j	80004c14 <pipealloc+0xb2>
    80004c08:	6088                	ld	a0,0(s1)
    80004c0a:	c51d                	beqz	a0,80004c38 <pipealloc+0xd6>
    fileclose(*f0);
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	c00080e7          	jalr	-1024(ra) # 8000480c <fileclose>
  if(*f1)
    80004c14:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c18:	557d                	li	a0,-1
  if(*f1)
    80004c1a:	c799                	beqz	a5,80004c28 <pipealloc+0xc6>
    fileclose(*f1);
    80004c1c:	853e                	mv	a0,a5
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	bee080e7          	jalr	-1042(ra) # 8000480c <fileclose>
  return -1;
    80004c26:	557d                	li	a0,-1
}
    80004c28:	70a2                	ld	ra,40(sp)
    80004c2a:	7402                	ld	s0,32(sp)
    80004c2c:	64e2                	ld	s1,24(sp)
    80004c2e:	6942                	ld	s2,16(sp)
    80004c30:	69a2                	ld	s3,8(sp)
    80004c32:	6a02                	ld	s4,0(sp)
    80004c34:	6145                	addi	sp,sp,48
    80004c36:	8082                	ret
  return -1;
    80004c38:	557d                	li	a0,-1
    80004c3a:	b7fd                	j	80004c28 <pipealloc+0xc6>

0000000080004c3c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c3c:	1101                	addi	sp,sp,-32
    80004c3e:	ec06                	sd	ra,24(sp)
    80004c40:	e822                	sd	s0,16(sp)
    80004c42:	e426                	sd	s1,8(sp)
    80004c44:	e04a                	sd	s2,0(sp)
    80004c46:	1000                	addi	s0,sp,32
    80004c48:	84aa                	mv	s1,a0
    80004c4a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	fb0080e7          	jalr	-80(ra) # 80000bfc <acquire>
  if(writable){
    80004c54:	02090d63          	beqz	s2,80004c8e <pipeclose+0x52>
    pi->writeopen = 0;
    80004c58:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c5c:	21848513          	addi	a0,s1,536
    80004c60:	ffffe097          	auipc	ra,0xffffe
    80004c64:	9b6080e7          	jalr	-1610(ra) # 80002616 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c68:	2204b783          	ld	a5,544(s1)
    80004c6c:	eb95                	bnez	a5,80004ca0 <pipeclose+0x64>
    release(&pi->lock);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	040080e7          	jalr	64(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	d96080e7          	jalr	-618(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c82:	60e2                	ld	ra,24(sp)
    80004c84:	6442                	ld	s0,16(sp)
    80004c86:	64a2                	ld	s1,8(sp)
    80004c88:	6902                	ld	s2,0(sp)
    80004c8a:	6105                	addi	sp,sp,32
    80004c8c:	8082                	ret
    pi->readopen = 0;
    80004c8e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c92:	21c48513          	addi	a0,s1,540
    80004c96:	ffffe097          	auipc	ra,0xffffe
    80004c9a:	980080e7          	jalr	-1664(ra) # 80002616 <wakeup>
    80004c9e:	b7e9                	j	80004c68 <pipeclose+0x2c>
    release(&pi->lock);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	00e080e7          	jalr	14(ra) # 80000cb0 <release>
}
    80004caa:	bfe1                	j	80004c82 <pipeclose+0x46>

0000000080004cac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cac:	711d                	addi	sp,sp,-96
    80004cae:	ec86                	sd	ra,88(sp)
    80004cb0:	e8a2                	sd	s0,80(sp)
    80004cb2:	e4a6                	sd	s1,72(sp)
    80004cb4:	e0ca                	sd	s2,64(sp)
    80004cb6:	fc4e                	sd	s3,56(sp)
    80004cb8:	f852                	sd	s4,48(sp)
    80004cba:	f456                	sd	s5,40(sp)
    80004cbc:	f05a                	sd	s6,32(sp)
    80004cbe:	ec5e                	sd	s7,24(sp)
    80004cc0:	e862                	sd	s8,16(sp)
    80004cc2:	1080                	addi	s0,sp,96
    80004cc4:	84aa                	mv	s1,a0
    80004cc6:	8b2e                	mv	s6,a1
    80004cc8:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	e6a080e7          	jalr	-406(ra) # 80001b34 <myproc>
    80004cd2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	f26080e7          	jalr	-218(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004cde:	09505763          	blez	s5,80004d6c <pipewrite+0xc0>
    80004ce2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ce4:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ce8:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cec:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cee:	2184a783          	lw	a5,536(s1)
    80004cf2:	21c4a703          	lw	a4,540(s1)
    80004cf6:	2007879b          	addiw	a5,a5,512
    80004cfa:	02f71b63          	bne	a4,a5,80004d30 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004cfe:	2204a783          	lw	a5,544(s1)
    80004d02:	c3d1                	beqz	a5,80004d86 <pipewrite+0xda>
    80004d04:	03092783          	lw	a5,48(s2)
    80004d08:	efbd                	bnez	a5,80004d86 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004d0a:	8552                	mv	a0,s4
    80004d0c:	ffffe097          	auipc	ra,0xffffe
    80004d10:	90a080e7          	jalr	-1782(ra) # 80002616 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d14:	85a6                	mv	a1,s1
    80004d16:	854e                	mv	a0,s3
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	752080e7          	jalr	1874(ra) # 8000246a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d20:	2184a783          	lw	a5,536(s1)
    80004d24:	21c4a703          	lw	a4,540(s1)
    80004d28:	2007879b          	addiw	a5,a5,512
    80004d2c:	fcf709e3          	beq	a4,a5,80004cfe <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d30:	4685                	li	a3,1
    80004d32:	865a                	mv	a2,s6
    80004d34:	faf40593          	addi	a1,s0,-81
    80004d38:	05093503          	ld	a0,80(s2)
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	9fa080e7          	jalr	-1542(ra) # 80001736 <copyin>
    80004d44:	03850563          	beq	a0,s8,80004d6e <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d48:	21c4a783          	lw	a5,540(s1)
    80004d4c:	0017871b          	addiw	a4,a5,1
    80004d50:	20e4ae23          	sw	a4,540(s1)
    80004d54:	1ff7f793          	andi	a5,a5,511
    80004d58:	97a6                	add	a5,a5,s1
    80004d5a:	faf44703          	lbu	a4,-81(s0)
    80004d5e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d62:	2b85                	addiw	s7,s7,1
    80004d64:	0b05                	addi	s6,s6,1
    80004d66:	f97a94e3          	bne	s5,s7,80004cee <pipewrite+0x42>
    80004d6a:	a011                	j	80004d6e <pipewrite+0xc2>
    80004d6c:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d6e:	21848513          	addi	a0,s1,536
    80004d72:	ffffe097          	auipc	ra,0xffffe
    80004d76:	8a4080e7          	jalr	-1884(ra) # 80002616 <wakeup>
  release(&pi->lock);
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	f34080e7          	jalr	-204(ra) # 80000cb0 <release>
  return i;
    80004d84:	a039                	j	80004d92 <pipewrite+0xe6>
        release(&pi->lock);
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	f28080e7          	jalr	-216(ra) # 80000cb0 <release>
        return -1;
    80004d90:	5bfd                	li	s7,-1
}
    80004d92:	855e                	mv	a0,s7
    80004d94:	60e6                	ld	ra,88(sp)
    80004d96:	6446                	ld	s0,80(sp)
    80004d98:	64a6                	ld	s1,72(sp)
    80004d9a:	6906                	ld	s2,64(sp)
    80004d9c:	79e2                	ld	s3,56(sp)
    80004d9e:	7a42                	ld	s4,48(sp)
    80004da0:	7aa2                	ld	s5,40(sp)
    80004da2:	7b02                	ld	s6,32(sp)
    80004da4:	6be2                	ld	s7,24(sp)
    80004da6:	6c42                	ld	s8,16(sp)
    80004da8:	6125                	addi	sp,sp,96
    80004daa:	8082                	ret

0000000080004dac <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dac:	715d                	addi	sp,sp,-80
    80004dae:	e486                	sd	ra,72(sp)
    80004db0:	e0a2                	sd	s0,64(sp)
    80004db2:	fc26                	sd	s1,56(sp)
    80004db4:	f84a                	sd	s2,48(sp)
    80004db6:	f44e                	sd	s3,40(sp)
    80004db8:	f052                	sd	s4,32(sp)
    80004dba:	ec56                	sd	s5,24(sp)
    80004dbc:	e85a                	sd	s6,16(sp)
    80004dbe:	0880                	addi	s0,sp,80
    80004dc0:	84aa                	mv	s1,a0
    80004dc2:	892e                	mv	s2,a1
    80004dc4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dc6:	ffffd097          	auipc	ra,0xffffd
    80004dca:	d6e080e7          	jalr	-658(ra) # 80001b34 <myproc>
    80004dce:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	e2a080e7          	jalr	-470(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dda:	2184a703          	lw	a4,536(s1)
    80004dde:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de6:	02f71463          	bne	a4,a5,80004e0e <piperead+0x62>
    80004dea:	2244a783          	lw	a5,548(s1)
    80004dee:	c385                	beqz	a5,80004e0e <piperead+0x62>
    if(pr->killed){
    80004df0:	030a2783          	lw	a5,48(s4)
    80004df4:	ebc1                	bnez	a5,80004e84 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004df6:	85a6                	mv	a1,s1
    80004df8:	854e                	mv	a0,s3
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	670080e7          	jalr	1648(ra) # 8000246a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e02:	2184a703          	lw	a4,536(s1)
    80004e06:	21c4a783          	lw	a5,540(s1)
    80004e0a:	fef700e3          	beq	a4,a5,80004dea <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e0e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e10:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e12:	05505363          	blez	s5,80004e58 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e16:	2184a783          	lw	a5,536(s1)
    80004e1a:	21c4a703          	lw	a4,540(s1)
    80004e1e:	02f70d63          	beq	a4,a5,80004e58 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e22:	0017871b          	addiw	a4,a5,1
    80004e26:	20e4ac23          	sw	a4,536(s1)
    80004e2a:	1ff7f793          	andi	a5,a5,511
    80004e2e:	97a6                	add	a5,a5,s1
    80004e30:	0187c783          	lbu	a5,24(a5)
    80004e34:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e38:	4685                	li	a3,1
    80004e3a:	fbf40613          	addi	a2,s0,-65
    80004e3e:	85ca                	mv	a1,s2
    80004e40:	050a3503          	ld	a0,80(s4)
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	866080e7          	jalr	-1946(ra) # 800016aa <copyout>
    80004e4c:	01650663          	beq	a0,s6,80004e58 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e50:	2985                	addiw	s3,s3,1
    80004e52:	0905                	addi	s2,s2,1
    80004e54:	fd3a91e3          	bne	s5,s3,80004e16 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e58:	21c48513          	addi	a0,s1,540
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	7ba080e7          	jalr	1978(ra) # 80002616 <wakeup>
  release(&pi->lock);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	e4a080e7          	jalr	-438(ra) # 80000cb0 <release>
  return i;
}
    80004e6e:	854e                	mv	a0,s3
    80004e70:	60a6                	ld	ra,72(sp)
    80004e72:	6406                	ld	s0,64(sp)
    80004e74:	74e2                	ld	s1,56(sp)
    80004e76:	7942                	ld	s2,48(sp)
    80004e78:	79a2                	ld	s3,40(sp)
    80004e7a:	7a02                	ld	s4,32(sp)
    80004e7c:	6ae2                	ld	s5,24(sp)
    80004e7e:	6b42                	ld	s6,16(sp)
    80004e80:	6161                	addi	sp,sp,80
    80004e82:	8082                	ret
      release(&pi->lock);
    80004e84:	8526                	mv	a0,s1
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	e2a080e7          	jalr	-470(ra) # 80000cb0 <release>
      return -1;
    80004e8e:	59fd                	li	s3,-1
    80004e90:	bff9                	j	80004e6e <piperead+0xc2>

0000000080004e92 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e92:	de010113          	addi	sp,sp,-544
    80004e96:	20113c23          	sd	ra,536(sp)
    80004e9a:	20813823          	sd	s0,528(sp)
    80004e9e:	20913423          	sd	s1,520(sp)
    80004ea2:	21213023          	sd	s2,512(sp)
    80004ea6:	ffce                	sd	s3,504(sp)
    80004ea8:	fbd2                	sd	s4,496(sp)
    80004eaa:	f7d6                	sd	s5,488(sp)
    80004eac:	f3da                	sd	s6,480(sp)
    80004eae:	efde                	sd	s7,472(sp)
    80004eb0:	ebe2                	sd	s8,464(sp)
    80004eb2:	e7e6                	sd	s9,456(sp)
    80004eb4:	e3ea                	sd	s10,448(sp)
    80004eb6:	ff6e                	sd	s11,440(sp)
    80004eb8:	1400                	addi	s0,sp,544
    80004eba:	892a                	mv	s2,a0
    80004ebc:	dea43423          	sd	a0,-536(s0)
    80004ec0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	c70080e7          	jalr	-912(ra) # 80001b34 <myproc>
    80004ecc:	84aa                	mv	s1,a0

  begin_op();
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	46c080e7          	jalr	1132(ra) # 8000433a <begin_op>

  if((ip = namei(path)) == 0){
    80004ed6:	854a                	mv	a0,s2
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	256080e7          	jalr	598(ra) # 8000412e <namei>
    80004ee0:	c93d                	beqz	a0,80004f56 <exec+0xc4>
    80004ee2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	a9a080e7          	jalr	-1382(ra) # 8000397e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eec:	04000713          	li	a4,64
    80004ef0:	4681                	li	a3,0
    80004ef2:	e4840613          	addi	a2,s0,-440
    80004ef6:	4581                	li	a1,0
    80004ef8:	8556                	mv	a0,s5
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	d38080e7          	jalr	-712(ra) # 80003c32 <readi>
    80004f02:	04000793          	li	a5,64
    80004f06:	00f51a63          	bne	a0,a5,80004f1a <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f0a:	e4842703          	lw	a4,-440(s0)
    80004f0e:	464c47b7          	lui	a5,0x464c4
    80004f12:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f16:	04f70663          	beq	a4,a5,80004f62 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f1a:	8556                	mv	a0,s5
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	cc4080e7          	jalr	-828(ra) # 80003be0 <iunlockput>
    end_op();
    80004f24:	fffff097          	auipc	ra,0xfffff
    80004f28:	496080e7          	jalr	1174(ra) # 800043ba <end_op>
  }
  return -1;
    80004f2c:	557d                	li	a0,-1
}
    80004f2e:	21813083          	ld	ra,536(sp)
    80004f32:	21013403          	ld	s0,528(sp)
    80004f36:	20813483          	ld	s1,520(sp)
    80004f3a:	20013903          	ld	s2,512(sp)
    80004f3e:	79fe                	ld	s3,504(sp)
    80004f40:	7a5e                	ld	s4,496(sp)
    80004f42:	7abe                	ld	s5,488(sp)
    80004f44:	7b1e                	ld	s6,480(sp)
    80004f46:	6bfe                	ld	s7,472(sp)
    80004f48:	6c5e                	ld	s8,464(sp)
    80004f4a:	6cbe                	ld	s9,456(sp)
    80004f4c:	6d1e                	ld	s10,448(sp)
    80004f4e:	7dfa                	ld	s11,440(sp)
    80004f50:	22010113          	addi	sp,sp,544
    80004f54:	8082                	ret
    end_op();
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	464080e7          	jalr	1124(ra) # 800043ba <end_op>
    return -1;
    80004f5e:	557d                	li	a0,-1
    80004f60:	b7f9                	j	80004f2e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f62:	8526                	mv	a0,s1
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	c96080e7          	jalr	-874(ra) # 80001bfa <proc_pagetable>
    80004f6c:	8b2a                	mv	s6,a0
    80004f6e:	d555                	beqz	a0,80004f1a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f70:	e6842783          	lw	a5,-408(s0)
    80004f74:	e8045703          	lhu	a4,-384(s0)
    80004f78:	c735                	beqz	a4,80004fe4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f7a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f80:	6a05                	lui	s4,0x1
    80004f82:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f86:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f8a:	6d85                	lui	s11,0x1
    80004f8c:	7d7d                	lui	s10,0xfffff
    80004f8e:	ac1d                	j	800051c4 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f90:	00003517          	auipc	a0,0x3
    80004f94:	77850513          	addi	a0,a0,1912 # 80008708 <syscalls+0x290>
    80004f98:	ffffb097          	auipc	ra,0xffffb
    80004f9c:	5a8080e7          	jalr	1448(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fa0:	874a                	mv	a4,s2
    80004fa2:	009c86bb          	addw	a3,s9,s1
    80004fa6:	4581                	li	a1,0
    80004fa8:	8556                	mv	a0,s5
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	c88080e7          	jalr	-888(ra) # 80003c32 <readi>
    80004fb2:	2501                	sext.w	a0,a0
    80004fb4:	1aa91863          	bne	s2,a0,80005164 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fb8:	009d84bb          	addw	s1,s11,s1
    80004fbc:	013d09bb          	addw	s3,s10,s3
    80004fc0:	1f74f263          	bgeu	s1,s7,800051a4 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fc4:	02049593          	slli	a1,s1,0x20
    80004fc8:	9181                	srli	a1,a1,0x20
    80004fca:	95e2                	add	a1,a1,s8
    80004fcc:	855a                	mv	a0,s6
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	0a8080e7          	jalr	168(ra) # 80001076 <walkaddr>
    80004fd6:	862a                	mv	a2,a0
    if(pa == 0)
    80004fd8:	dd45                	beqz	a0,80004f90 <exec+0xfe>
      n = PGSIZE;
    80004fda:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fdc:	fd49f2e3          	bgeu	s3,s4,80004fa0 <exec+0x10e>
      n = sz - i;
    80004fe0:	894e                	mv	s2,s3
    80004fe2:	bf7d                	j	80004fa0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fe4:	4481                	li	s1,0
  iunlockput(ip);
    80004fe6:	8556                	mv	a0,s5
    80004fe8:	fffff097          	auipc	ra,0xfffff
    80004fec:	bf8080e7          	jalr	-1032(ra) # 80003be0 <iunlockput>
  end_op();
    80004ff0:	fffff097          	auipc	ra,0xfffff
    80004ff4:	3ca080e7          	jalr	970(ra) # 800043ba <end_op>
  p = myproc();
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	b3c080e7          	jalr	-1220(ra) # 80001b34 <myproc>
    80005000:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005002:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005006:	6785                	lui	a5,0x1
    80005008:	17fd                	addi	a5,a5,-1
    8000500a:	94be                	add	s1,s1,a5
    8000500c:	77fd                	lui	a5,0xfffff
    8000500e:	8fe5                	and	a5,a5,s1
    80005010:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005014:	6609                	lui	a2,0x2
    80005016:	963e                	add	a2,a2,a5
    80005018:	85be                	mv	a1,a5
    8000501a:	855a                	mv	a0,s6
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	43e080e7          	jalr	1086(ra) # 8000145a <uvmalloc>
    80005024:	8c2a                	mv	s8,a0
  ip = 0;
    80005026:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005028:	12050e63          	beqz	a0,80005164 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000502c:	75f9                	lui	a1,0xffffe
    8000502e:	95aa                	add	a1,a1,a0
    80005030:	855a                	mv	a0,s6
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	646080e7          	jalr	1606(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    8000503a:	7afd                	lui	s5,0xfffff
    8000503c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000503e:	df043783          	ld	a5,-528(s0)
    80005042:	6388                	ld	a0,0(a5)
    80005044:	c925                	beqz	a0,800050b4 <exec+0x222>
    80005046:	e8840993          	addi	s3,s0,-376
    8000504a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000504e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005050:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	e2a080e7          	jalr	-470(ra) # 80000e7c <strlen>
    8000505a:	0015079b          	addiw	a5,a0,1
    8000505e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005062:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005066:	13596363          	bltu	s2,s5,8000518c <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000506a:	df043d83          	ld	s11,-528(s0)
    8000506e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005072:	8552                	mv	a0,s4
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	e08080e7          	jalr	-504(ra) # 80000e7c <strlen>
    8000507c:	0015069b          	addiw	a3,a0,1
    80005080:	8652                	mv	a2,s4
    80005082:	85ca                	mv	a1,s2
    80005084:	855a                	mv	a0,s6
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	624080e7          	jalr	1572(ra) # 800016aa <copyout>
    8000508e:	10054363          	bltz	a0,80005194 <exec+0x302>
    ustack[argc] = sp;
    80005092:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005096:	0485                	addi	s1,s1,1
    80005098:	008d8793          	addi	a5,s11,8
    8000509c:	def43823          	sd	a5,-528(s0)
    800050a0:	008db503          	ld	a0,8(s11)
    800050a4:	c911                	beqz	a0,800050b8 <exec+0x226>
    if(argc >= MAXARG)
    800050a6:	09a1                	addi	s3,s3,8
    800050a8:	fb3c95e3          	bne	s9,s3,80005052 <exec+0x1c0>
  sz = sz1;
    800050ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b0:	4a81                	li	s5,0
    800050b2:	a84d                	j	80005164 <exec+0x2d2>
  sp = sz;
    800050b4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050b6:	4481                	li	s1,0
  ustack[argc] = 0;
    800050b8:	00349793          	slli	a5,s1,0x3
    800050bc:	f9040713          	addi	a4,s0,-112
    800050c0:	97ba                	add	a5,a5,a4
    800050c2:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050c6:	00148693          	addi	a3,s1,1
    800050ca:	068e                	slli	a3,a3,0x3
    800050cc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050d0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050d4:	01597663          	bgeu	s2,s5,800050e0 <exec+0x24e>
  sz = sz1;
    800050d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050dc:	4a81                	li	s5,0
    800050de:	a059                	j	80005164 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050e0:	e8840613          	addi	a2,s0,-376
    800050e4:	85ca                	mv	a1,s2
    800050e6:	855a                	mv	a0,s6
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	5c2080e7          	jalr	1474(ra) # 800016aa <copyout>
    800050f0:	0a054663          	bltz	a0,8000519c <exec+0x30a>
  p->trapframe->a1 = sp;
    800050f4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800050f8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050fc:	de843783          	ld	a5,-536(s0)
    80005100:	0007c703          	lbu	a4,0(a5)
    80005104:	cf11                	beqz	a4,80005120 <exec+0x28e>
    80005106:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005108:	02f00693          	li	a3,47
    8000510c:	a039                	j	8000511a <exec+0x288>
      last = s+1;
    8000510e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005112:	0785                	addi	a5,a5,1
    80005114:	fff7c703          	lbu	a4,-1(a5)
    80005118:	c701                	beqz	a4,80005120 <exec+0x28e>
    if(*s == '/')
    8000511a:	fed71ce3          	bne	a4,a3,80005112 <exec+0x280>
    8000511e:	bfc5                	j	8000510e <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005120:	4641                	li	a2,16
    80005122:	de843583          	ld	a1,-536(s0)
    80005126:	158b8513          	addi	a0,s7,344
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	d20080e7          	jalr	-736(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    80005132:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005136:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000513a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000513e:	058bb783          	ld	a5,88(s7)
    80005142:	e6043703          	ld	a4,-416(s0)
    80005146:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005148:	058bb783          	ld	a5,88(s7)
    8000514c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005150:	85ea                	mv	a1,s10
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	b44080e7          	jalr	-1212(ra) # 80001c96 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000515a:	0004851b          	sext.w	a0,s1
    8000515e:	bbc1                	j	80004f2e <exec+0x9c>
    80005160:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005164:	df843583          	ld	a1,-520(s0)
    80005168:	855a                	mv	a0,s6
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	b2c080e7          	jalr	-1236(ra) # 80001c96 <proc_freepagetable>
  if(ip){
    80005172:	da0a94e3          	bnez	s5,80004f1a <exec+0x88>
  return -1;
    80005176:	557d                	li	a0,-1
    80005178:	bb5d                	j	80004f2e <exec+0x9c>
    8000517a:	de943c23          	sd	s1,-520(s0)
    8000517e:	b7dd                	j	80005164 <exec+0x2d2>
    80005180:	de943c23          	sd	s1,-520(s0)
    80005184:	b7c5                	j	80005164 <exec+0x2d2>
    80005186:	de943c23          	sd	s1,-520(s0)
    8000518a:	bfe9                	j	80005164 <exec+0x2d2>
  sz = sz1;
    8000518c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005190:	4a81                	li	s5,0
    80005192:	bfc9                	j	80005164 <exec+0x2d2>
  sz = sz1;
    80005194:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005198:	4a81                	li	s5,0
    8000519a:	b7e9                	j	80005164 <exec+0x2d2>
  sz = sz1;
    8000519c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a0:	4a81                	li	s5,0
    800051a2:	b7c9                	j	80005164 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051a4:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051a8:	e0843783          	ld	a5,-504(s0)
    800051ac:	0017869b          	addiw	a3,a5,1
    800051b0:	e0d43423          	sd	a3,-504(s0)
    800051b4:	e0043783          	ld	a5,-512(s0)
    800051b8:	0387879b          	addiw	a5,a5,56
    800051bc:	e8045703          	lhu	a4,-384(s0)
    800051c0:	e2e6d3e3          	bge	a3,a4,80004fe6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051c4:	2781                	sext.w	a5,a5
    800051c6:	e0f43023          	sd	a5,-512(s0)
    800051ca:	03800713          	li	a4,56
    800051ce:	86be                	mv	a3,a5
    800051d0:	e1040613          	addi	a2,s0,-496
    800051d4:	4581                	li	a1,0
    800051d6:	8556                	mv	a0,s5
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	a5a080e7          	jalr	-1446(ra) # 80003c32 <readi>
    800051e0:	03800793          	li	a5,56
    800051e4:	f6f51ee3          	bne	a0,a5,80005160 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051e8:	e1042783          	lw	a5,-496(s0)
    800051ec:	4705                	li	a4,1
    800051ee:	fae79de3          	bne	a5,a4,800051a8 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051f2:	e3843603          	ld	a2,-456(s0)
    800051f6:	e3043783          	ld	a5,-464(s0)
    800051fa:	f8f660e3          	bltu	a2,a5,8000517a <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051fe:	e2043783          	ld	a5,-480(s0)
    80005202:	963e                	add	a2,a2,a5
    80005204:	f6f66ee3          	bltu	a2,a5,80005180 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005208:	85a6                	mv	a1,s1
    8000520a:	855a                	mv	a0,s6
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	24e080e7          	jalr	590(ra) # 8000145a <uvmalloc>
    80005214:	dea43c23          	sd	a0,-520(s0)
    80005218:	d53d                	beqz	a0,80005186 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000521a:	e2043c03          	ld	s8,-480(s0)
    8000521e:	de043783          	ld	a5,-544(s0)
    80005222:	00fc77b3          	and	a5,s8,a5
    80005226:	ff9d                	bnez	a5,80005164 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005228:	e1842c83          	lw	s9,-488(s0)
    8000522c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005230:	f60b8ae3          	beqz	s7,800051a4 <exec+0x312>
    80005234:	89de                	mv	s3,s7
    80005236:	4481                	li	s1,0
    80005238:	b371                	j	80004fc4 <exec+0x132>

000000008000523a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000523a:	7179                	addi	sp,sp,-48
    8000523c:	f406                	sd	ra,40(sp)
    8000523e:	f022                	sd	s0,32(sp)
    80005240:	ec26                	sd	s1,24(sp)
    80005242:	e84a                	sd	s2,16(sp)
    80005244:	1800                	addi	s0,sp,48
    80005246:	892e                	mv	s2,a1
    80005248:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000524a:	fdc40593          	addi	a1,s0,-36
    8000524e:	ffffe097          	auipc	ra,0xffffe
    80005252:	b74080e7          	jalr	-1164(ra) # 80002dc2 <argint>
    80005256:	04054063          	bltz	a0,80005296 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000525a:	fdc42703          	lw	a4,-36(s0)
    8000525e:	47bd                	li	a5,15
    80005260:	02e7ed63          	bltu	a5,a4,8000529a <argfd+0x60>
    80005264:	ffffd097          	auipc	ra,0xffffd
    80005268:	8d0080e7          	jalr	-1840(ra) # 80001b34 <myproc>
    8000526c:	fdc42703          	lw	a4,-36(s0)
    80005270:	01a70793          	addi	a5,a4,26
    80005274:	078e                	slli	a5,a5,0x3
    80005276:	953e                	add	a0,a0,a5
    80005278:	611c                	ld	a5,0(a0)
    8000527a:	c395                	beqz	a5,8000529e <argfd+0x64>
    return -1;
  if(pfd)
    8000527c:	00090463          	beqz	s2,80005284 <argfd+0x4a>
    *pfd = fd;
    80005280:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005284:	4501                	li	a0,0
  if(pf)
    80005286:	c091                	beqz	s1,8000528a <argfd+0x50>
    *pf = f;
    80005288:	e09c                	sd	a5,0(s1)
}
    8000528a:	70a2                	ld	ra,40(sp)
    8000528c:	7402                	ld	s0,32(sp)
    8000528e:	64e2                	ld	s1,24(sp)
    80005290:	6942                	ld	s2,16(sp)
    80005292:	6145                	addi	sp,sp,48
    80005294:	8082                	ret
    return -1;
    80005296:	557d                	li	a0,-1
    80005298:	bfcd                	j	8000528a <argfd+0x50>
    return -1;
    8000529a:	557d                	li	a0,-1
    8000529c:	b7fd                	j	8000528a <argfd+0x50>
    8000529e:	557d                	li	a0,-1
    800052a0:	b7ed                	j	8000528a <argfd+0x50>

00000000800052a2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052a2:	1101                	addi	sp,sp,-32
    800052a4:	ec06                	sd	ra,24(sp)
    800052a6:	e822                	sd	s0,16(sp)
    800052a8:	e426                	sd	s1,8(sp)
    800052aa:	1000                	addi	s0,sp,32
    800052ac:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	886080e7          	jalr	-1914(ra) # 80001b34 <myproc>
    800052b6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052b8:	0d050793          	addi	a5,a0,208
    800052bc:	4501                	li	a0,0
    800052be:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052c0:	6398                	ld	a4,0(a5)
    800052c2:	cb19                	beqz	a4,800052d8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052c4:	2505                	addiw	a0,a0,1
    800052c6:	07a1                	addi	a5,a5,8
    800052c8:	fed51ce3          	bne	a0,a3,800052c0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052cc:	557d                	li	a0,-1
}
    800052ce:	60e2                	ld	ra,24(sp)
    800052d0:	6442                	ld	s0,16(sp)
    800052d2:	64a2                	ld	s1,8(sp)
    800052d4:	6105                	addi	sp,sp,32
    800052d6:	8082                	ret
      p->ofile[fd] = f;
    800052d8:	01a50793          	addi	a5,a0,26
    800052dc:	078e                	slli	a5,a5,0x3
    800052de:	963e                	add	a2,a2,a5
    800052e0:	e204                	sd	s1,0(a2)
      return fd;
    800052e2:	b7f5                	j	800052ce <fdalloc+0x2c>

00000000800052e4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052e4:	715d                	addi	sp,sp,-80
    800052e6:	e486                	sd	ra,72(sp)
    800052e8:	e0a2                	sd	s0,64(sp)
    800052ea:	fc26                	sd	s1,56(sp)
    800052ec:	f84a                	sd	s2,48(sp)
    800052ee:	f44e                	sd	s3,40(sp)
    800052f0:	f052                	sd	s4,32(sp)
    800052f2:	ec56                	sd	s5,24(sp)
    800052f4:	0880                	addi	s0,sp,80
    800052f6:	89ae                	mv	s3,a1
    800052f8:	8ab2                	mv	s5,a2
    800052fa:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052fc:	fb040593          	addi	a1,s0,-80
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	e4c080e7          	jalr	-436(ra) # 8000414c <nameiparent>
    80005308:	892a                	mv	s2,a0
    8000530a:	12050e63          	beqz	a0,80005446 <create+0x162>
    return 0;

  ilock(dp);
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	670080e7          	jalr	1648(ra) # 8000397e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005316:	4601                	li	a2,0
    80005318:	fb040593          	addi	a1,s0,-80
    8000531c:	854a                	mv	a0,s2
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	b3e080e7          	jalr	-1218(ra) # 80003e5c <dirlookup>
    80005326:	84aa                	mv	s1,a0
    80005328:	c921                	beqz	a0,80005378 <create+0x94>
    iunlockput(dp);
    8000532a:	854a                	mv	a0,s2
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	8b4080e7          	jalr	-1868(ra) # 80003be0 <iunlockput>
    ilock(ip);
    80005334:	8526                	mv	a0,s1
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	648080e7          	jalr	1608(ra) # 8000397e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000533e:	2981                	sext.w	s3,s3
    80005340:	4789                	li	a5,2
    80005342:	02f99463          	bne	s3,a5,8000536a <create+0x86>
    80005346:	0444d783          	lhu	a5,68(s1)
    8000534a:	37f9                	addiw	a5,a5,-2
    8000534c:	17c2                	slli	a5,a5,0x30
    8000534e:	93c1                	srli	a5,a5,0x30
    80005350:	4705                	li	a4,1
    80005352:	00f76c63          	bltu	a4,a5,8000536a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005356:	8526                	mv	a0,s1
    80005358:	60a6                	ld	ra,72(sp)
    8000535a:	6406                	ld	s0,64(sp)
    8000535c:	74e2                	ld	s1,56(sp)
    8000535e:	7942                	ld	s2,48(sp)
    80005360:	79a2                	ld	s3,40(sp)
    80005362:	7a02                	ld	s4,32(sp)
    80005364:	6ae2                	ld	s5,24(sp)
    80005366:	6161                	addi	sp,sp,80
    80005368:	8082                	ret
    iunlockput(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	874080e7          	jalr	-1932(ra) # 80003be0 <iunlockput>
    return 0;
    80005374:	4481                	li	s1,0
    80005376:	b7c5                	j	80005356 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005378:	85ce                	mv	a1,s3
    8000537a:	00092503          	lw	a0,0(s2)
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	468080e7          	jalr	1128(ra) # 800037e6 <ialloc>
    80005386:	84aa                	mv	s1,a0
    80005388:	c521                	beqz	a0,800053d0 <create+0xec>
  ilock(ip);
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	5f4080e7          	jalr	1524(ra) # 8000397e <ilock>
  ip->major = major;
    80005392:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005396:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000539a:	4a05                	li	s4,1
    8000539c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	512080e7          	jalr	1298(ra) # 800038b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053aa:	2981                	sext.w	s3,s3
    800053ac:	03498a63          	beq	s3,s4,800053e0 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053b0:	40d0                	lw	a2,4(s1)
    800053b2:	fb040593          	addi	a1,s0,-80
    800053b6:	854a                	mv	a0,s2
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	cb4080e7          	jalr	-844(ra) # 8000406c <dirlink>
    800053c0:	06054b63          	bltz	a0,80005436 <create+0x152>
  iunlockput(dp);
    800053c4:	854a                	mv	a0,s2
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	81a080e7          	jalr	-2022(ra) # 80003be0 <iunlockput>
  return ip;
    800053ce:	b761                	j	80005356 <create+0x72>
    panic("create: ialloc");
    800053d0:	00003517          	auipc	a0,0x3
    800053d4:	35850513          	addi	a0,a0,856 # 80008728 <syscalls+0x2b0>
    800053d8:	ffffb097          	auipc	ra,0xffffb
    800053dc:	168080e7          	jalr	360(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800053e0:	04a95783          	lhu	a5,74(s2)
    800053e4:	2785                	addiw	a5,a5,1
    800053e6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053ea:	854a                	mv	a0,s2
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	4c8080e7          	jalr	1224(ra) # 800038b4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053f4:	40d0                	lw	a2,4(s1)
    800053f6:	00003597          	auipc	a1,0x3
    800053fa:	34258593          	addi	a1,a1,834 # 80008738 <syscalls+0x2c0>
    800053fe:	8526                	mv	a0,s1
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	c6c080e7          	jalr	-916(ra) # 8000406c <dirlink>
    80005408:	00054f63          	bltz	a0,80005426 <create+0x142>
    8000540c:	00492603          	lw	a2,4(s2)
    80005410:	00003597          	auipc	a1,0x3
    80005414:	33058593          	addi	a1,a1,816 # 80008740 <syscalls+0x2c8>
    80005418:	8526                	mv	a0,s1
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	c52080e7          	jalr	-942(ra) # 8000406c <dirlink>
    80005422:	f80557e3          	bgez	a0,800053b0 <create+0xcc>
      panic("create dots");
    80005426:	00003517          	auipc	a0,0x3
    8000542a:	32250513          	addi	a0,a0,802 # 80008748 <syscalls+0x2d0>
    8000542e:	ffffb097          	auipc	ra,0xffffb
    80005432:	112080e7          	jalr	274(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005436:	00003517          	auipc	a0,0x3
    8000543a:	32250513          	addi	a0,a0,802 # 80008758 <syscalls+0x2e0>
    8000543e:	ffffb097          	auipc	ra,0xffffb
    80005442:	102080e7          	jalr	258(ra) # 80000540 <panic>
    return 0;
    80005446:	84aa                	mv	s1,a0
    80005448:	b739                	j	80005356 <create+0x72>

000000008000544a <sys_dup>:
{
    8000544a:	7179                	addi	sp,sp,-48
    8000544c:	f406                	sd	ra,40(sp)
    8000544e:	f022                	sd	s0,32(sp)
    80005450:	ec26                	sd	s1,24(sp)
    80005452:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005454:	fd840613          	addi	a2,s0,-40
    80005458:	4581                	li	a1,0
    8000545a:	4501                	li	a0,0
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	dde080e7          	jalr	-546(ra) # 8000523a <argfd>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005466:	02054363          	bltz	a0,8000548c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000546a:	fd843503          	ld	a0,-40(s0)
    8000546e:	00000097          	auipc	ra,0x0
    80005472:	e34080e7          	jalr	-460(ra) # 800052a2 <fdalloc>
    80005476:	84aa                	mv	s1,a0
    return -1;
    80005478:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000547a:	00054963          	bltz	a0,8000548c <sys_dup+0x42>
  filedup(f);
    8000547e:	fd843503          	ld	a0,-40(s0)
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	338080e7          	jalr	824(ra) # 800047ba <filedup>
  return fd;
    8000548a:	87a6                	mv	a5,s1
}
    8000548c:	853e                	mv	a0,a5
    8000548e:	70a2                	ld	ra,40(sp)
    80005490:	7402                	ld	s0,32(sp)
    80005492:	64e2                	ld	s1,24(sp)
    80005494:	6145                	addi	sp,sp,48
    80005496:	8082                	ret

0000000080005498 <sys_read>:
{
    80005498:	7179                	addi	sp,sp,-48
    8000549a:	f406                	sd	ra,40(sp)
    8000549c:	f022                	sd	s0,32(sp)
    8000549e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a0:	fe840613          	addi	a2,s0,-24
    800054a4:	4581                	li	a1,0
    800054a6:	4501                	li	a0,0
    800054a8:	00000097          	auipc	ra,0x0
    800054ac:	d92080e7          	jalr	-622(ra) # 8000523a <argfd>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b2:	04054163          	bltz	a0,800054f4 <sys_read+0x5c>
    800054b6:	fe440593          	addi	a1,s0,-28
    800054ba:	4509                	li	a0,2
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	906080e7          	jalr	-1786(ra) # 80002dc2 <argint>
    return -1;
    800054c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c6:	02054763          	bltz	a0,800054f4 <sys_read+0x5c>
    800054ca:	fd840593          	addi	a1,s0,-40
    800054ce:	4505                	li	a0,1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	914080e7          	jalr	-1772(ra) # 80002de4 <argaddr>
    return -1;
    800054d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054da:	00054d63          	bltz	a0,800054f4 <sys_read+0x5c>
  return fileread(f, p, n);
    800054de:	fe442603          	lw	a2,-28(s0)
    800054e2:	fd843583          	ld	a1,-40(s0)
    800054e6:	fe843503          	ld	a0,-24(s0)
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	45c080e7          	jalr	1116(ra) # 80004946 <fileread>
    800054f2:	87aa                	mv	a5,a0
}
    800054f4:	853e                	mv	a0,a5
    800054f6:	70a2                	ld	ra,40(sp)
    800054f8:	7402                	ld	s0,32(sp)
    800054fa:	6145                	addi	sp,sp,48
    800054fc:	8082                	ret

00000000800054fe <sys_write>:
{
    800054fe:	7179                	addi	sp,sp,-48
    80005500:	f406                	sd	ra,40(sp)
    80005502:	f022                	sd	s0,32(sp)
    80005504:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005506:	fe840613          	addi	a2,s0,-24
    8000550a:	4581                	li	a1,0
    8000550c:	4501                	li	a0,0
    8000550e:	00000097          	auipc	ra,0x0
    80005512:	d2c080e7          	jalr	-724(ra) # 8000523a <argfd>
    return -1;
    80005516:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005518:	04054163          	bltz	a0,8000555a <sys_write+0x5c>
    8000551c:	fe440593          	addi	a1,s0,-28
    80005520:	4509                	li	a0,2
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	8a0080e7          	jalr	-1888(ra) # 80002dc2 <argint>
    return -1;
    8000552a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552c:	02054763          	bltz	a0,8000555a <sys_write+0x5c>
    80005530:	fd840593          	addi	a1,s0,-40
    80005534:	4505                	li	a0,1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	8ae080e7          	jalr	-1874(ra) # 80002de4 <argaddr>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005540:	00054d63          	bltz	a0,8000555a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005544:	fe442603          	lw	a2,-28(s0)
    80005548:	fd843583          	ld	a1,-40(s0)
    8000554c:	fe843503          	ld	a0,-24(s0)
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	4b8080e7          	jalr	1208(ra) # 80004a08 <filewrite>
    80005558:	87aa                	mv	a5,a0
}
    8000555a:	853e                	mv	a0,a5
    8000555c:	70a2                	ld	ra,40(sp)
    8000555e:	7402                	ld	s0,32(sp)
    80005560:	6145                	addi	sp,sp,48
    80005562:	8082                	ret

0000000080005564 <sys_close>:
{
    80005564:	1101                	addi	sp,sp,-32
    80005566:	ec06                	sd	ra,24(sp)
    80005568:	e822                	sd	s0,16(sp)
    8000556a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000556c:	fe040613          	addi	a2,s0,-32
    80005570:	fec40593          	addi	a1,s0,-20
    80005574:	4501                	li	a0,0
    80005576:	00000097          	auipc	ra,0x0
    8000557a:	cc4080e7          	jalr	-828(ra) # 8000523a <argfd>
    return -1;
    8000557e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005580:	02054463          	bltz	a0,800055a8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005584:	ffffc097          	auipc	ra,0xffffc
    80005588:	5b0080e7          	jalr	1456(ra) # 80001b34 <myproc>
    8000558c:	fec42783          	lw	a5,-20(s0)
    80005590:	07e9                	addi	a5,a5,26
    80005592:	078e                	slli	a5,a5,0x3
    80005594:	97aa                	add	a5,a5,a0
    80005596:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000559a:	fe043503          	ld	a0,-32(s0)
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	26e080e7          	jalr	622(ra) # 8000480c <fileclose>
  return 0;
    800055a6:	4781                	li	a5,0
}
    800055a8:	853e                	mv	a0,a5
    800055aa:	60e2                	ld	ra,24(sp)
    800055ac:	6442                	ld	s0,16(sp)
    800055ae:	6105                	addi	sp,sp,32
    800055b0:	8082                	ret

00000000800055b2 <sys_fstat>:
{
    800055b2:	1101                	addi	sp,sp,-32
    800055b4:	ec06                	sd	ra,24(sp)
    800055b6:	e822                	sd	s0,16(sp)
    800055b8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ba:	fe840613          	addi	a2,s0,-24
    800055be:	4581                	li	a1,0
    800055c0:	4501                	li	a0,0
    800055c2:	00000097          	auipc	ra,0x0
    800055c6:	c78080e7          	jalr	-904(ra) # 8000523a <argfd>
    return -1;
    800055ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055cc:	02054563          	bltz	a0,800055f6 <sys_fstat+0x44>
    800055d0:	fe040593          	addi	a1,s0,-32
    800055d4:	4505                	li	a0,1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	80e080e7          	jalr	-2034(ra) # 80002de4 <argaddr>
    return -1;
    800055de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e0:	00054b63          	bltz	a0,800055f6 <sys_fstat+0x44>
  return filestat(f, st);
    800055e4:	fe043583          	ld	a1,-32(s0)
    800055e8:	fe843503          	ld	a0,-24(s0)
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	2e8080e7          	jalr	744(ra) # 800048d4 <filestat>
    800055f4:	87aa                	mv	a5,a0
}
    800055f6:	853e                	mv	a0,a5
    800055f8:	60e2                	ld	ra,24(sp)
    800055fa:	6442                	ld	s0,16(sp)
    800055fc:	6105                	addi	sp,sp,32
    800055fe:	8082                	ret

0000000080005600 <sys_link>:
{
    80005600:	7169                	addi	sp,sp,-304
    80005602:	f606                	sd	ra,296(sp)
    80005604:	f222                	sd	s0,288(sp)
    80005606:	ee26                	sd	s1,280(sp)
    80005608:	ea4a                	sd	s2,272(sp)
    8000560a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000560c:	08000613          	li	a2,128
    80005610:	ed040593          	addi	a1,s0,-304
    80005614:	4501                	li	a0,0
    80005616:	ffffd097          	auipc	ra,0xffffd
    8000561a:	7f0080e7          	jalr	2032(ra) # 80002e06 <argstr>
    return -1;
    8000561e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005620:	10054e63          	bltz	a0,8000573c <sys_link+0x13c>
    80005624:	08000613          	li	a2,128
    80005628:	f5040593          	addi	a1,s0,-176
    8000562c:	4505                	li	a0,1
    8000562e:	ffffd097          	auipc	ra,0xffffd
    80005632:	7d8080e7          	jalr	2008(ra) # 80002e06 <argstr>
    return -1;
    80005636:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005638:	10054263          	bltz	a0,8000573c <sys_link+0x13c>
  begin_op();
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	cfe080e7          	jalr	-770(ra) # 8000433a <begin_op>
  if((ip = namei(old)) == 0){
    80005644:	ed040513          	addi	a0,s0,-304
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	ae6080e7          	jalr	-1306(ra) # 8000412e <namei>
    80005650:	84aa                	mv	s1,a0
    80005652:	c551                	beqz	a0,800056de <sys_link+0xde>
  ilock(ip);
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	32a080e7          	jalr	810(ra) # 8000397e <ilock>
  if(ip->type == T_DIR){
    8000565c:	04449703          	lh	a4,68(s1)
    80005660:	4785                	li	a5,1
    80005662:	08f70463          	beq	a4,a5,800056ea <sys_link+0xea>
  ip->nlink++;
    80005666:	04a4d783          	lhu	a5,74(s1)
    8000566a:	2785                	addiw	a5,a5,1
    8000566c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	242080e7          	jalr	578(ra) # 800038b4 <iupdate>
  iunlock(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	3c4080e7          	jalr	964(ra) # 80003a40 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005684:	fd040593          	addi	a1,s0,-48
    80005688:	f5040513          	addi	a0,s0,-176
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	ac0080e7          	jalr	-1344(ra) # 8000414c <nameiparent>
    80005694:	892a                	mv	s2,a0
    80005696:	c935                	beqz	a0,8000570a <sys_link+0x10a>
  ilock(dp);
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	2e6080e7          	jalr	742(ra) # 8000397e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056a0:	00092703          	lw	a4,0(s2)
    800056a4:	409c                	lw	a5,0(s1)
    800056a6:	04f71d63          	bne	a4,a5,80005700 <sys_link+0x100>
    800056aa:	40d0                	lw	a2,4(s1)
    800056ac:	fd040593          	addi	a1,s0,-48
    800056b0:	854a                	mv	a0,s2
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	9ba080e7          	jalr	-1606(ra) # 8000406c <dirlink>
    800056ba:	04054363          	bltz	a0,80005700 <sys_link+0x100>
  iunlockput(dp);
    800056be:	854a                	mv	a0,s2
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	520080e7          	jalr	1312(ra) # 80003be0 <iunlockput>
  iput(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	46e080e7          	jalr	1134(ra) # 80003b38 <iput>
  end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	ce8080e7          	jalr	-792(ra) # 800043ba <end_op>
  return 0;
    800056da:	4781                	li	a5,0
    800056dc:	a085                	j	8000573c <sys_link+0x13c>
    end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	cdc080e7          	jalr	-804(ra) # 800043ba <end_op>
    return -1;
    800056e6:	57fd                	li	a5,-1
    800056e8:	a891                	j	8000573c <sys_link+0x13c>
    iunlockput(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	4f4080e7          	jalr	1268(ra) # 80003be0 <iunlockput>
    end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	cc6080e7          	jalr	-826(ra) # 800043ba <end_op>
    return -1;
    800056fc:	57fd                	li	a5,-1
    800056fe:	a83d                	j	8000573c <sys_link+0x13c>
    iunlockput(dp);
    80005700:	854a                	mv	a0,s2
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	4de080e7          	jalr	1246(ra) # 80003be0 <iunlockput>
  ilock(ip);
    8000570a:	8526                	mv	a0,s1
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	272080e7          	jalr	626(ra) # 8000397e <ilock>
  ip->nlink--;
    80005714:	04a4d783          	lhu	a5,74(s1)
    80005718:	37fd                	addiw	a5,a5,-1
    8000571a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	194080e7          	jalr	404(ra) # 800038b4 <iupdate>
  iunlockput(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	4b6080e7          	jalr	1206(ra) # 80003be0 <iunlockput>
  end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	c88080e7          	jalr	-888(ra) # 800043ba <end_op>
  return -1;
    8000573a:	57fd                	li	a5,-1
}
    8000573c:	853e                	mv	a0,a5
    8000573e:	70b2                	ld	ra,296(sp)
    80005740:	7412                	ld	s0,288(sp)
    80005742:	64f2                	ld	s1,280(sp)
    80005744:	6952                	ld	s2,272(sp)
    80005746:	6155                	addi	sp,sp,304
    80005748:	8082                	ret

000000008000574a <sys_unlink>:
{
    8000574a:	7151                	addi	sp,sp,-240
    8000574c:	f586                	sd	ra,232(sp)
    8000574e:	f1a2                	sd	s0,224(sp)
    80005750:	eda6                	sd	s1,216(sp)
    80005752:	e9ca                	sd	s2,208(sp)
    80005754:	e5ce                	sd	s3,200(sp)
    80005756:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005758:	08000613          	li	a2,128
    8000575c:	f3040593          	addi	a1,s0,-208
    80005760:	4501                	li	a0,0
    80005762:	ffffd097          	auipc	ra,0xffffd
    80005766:	6a4080e7          	jalr	1700(ra) # 80002e06 <argstr>
    8000576a:	18054163          	bltz	a0,800058ec <sys_unlink+0x1a2>
  begin_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	bcc080e7          	jalr	-1076(ra) # 8000433a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005776:	fb040593          	addi	a1,s0,-80
    8000577a:	f3040513          	addi	a0,s0,-208
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	9ce080e7          	jalr	-1586(ra) # 8000414c <nameiparent>
    80005786:	84aa                	mv	s1,a0
    80005788:	c979                	beqz	a0,8000585e <sys_unlink+0x114>
  ilock(dp);
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	1f4080e7          	jalr	500(ra) # 8000397e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005792:	00003597          	auipc	a1,0x3
    80005796:	fa658593          	addi	a1,a1,-90 # 80008738 <syscalls+0x2c0>
    8000579a:	fb040513          	addi	a0,s0,-80
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	6a4080e7          	jalr	1700(ra) # 80003e42 <namecmp>
    800057a6:	14050a63          	beqz	a0,800058fa <sys_unlink+0x1b0>
    800057aa:	00003597          	auipc	a1,0x3
    800057ae:	f9658593          	addi	a1,a1,-106 # 80008740 <syscalls+0x2c8>
    800057b2:	fb040513          	addi	a0,s0,-80
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	68c080e7          	jalr	1676(ra) # 80003e42 <namecmp>
    800057be:	12050e63          	beqz	a0,800058fa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057c2:	f2c40613          	addi	a2,s0,-212
    800057c6:	fb040593          	addi	a1,s0,-80
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	690080e7          	jalr	1680(ra) # 80003e5c <dirlookup>
    800057d4:	892a                	mv	s2,a0
    800057d6:	12050263          	beqz	a0,800058fa <sys_unlink+0x1b0>
  ilock(ip);
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	1a4080e7          	jalr	420(ra) # 8000397e <ilock>
  if(ip->nlink < 1)
    800057e2:	04a91783          	lh	a5,74(s2)
    800057e6:	08f05263          	blez	a5,8000586a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	4785                	li	a5,1
    800057f0:	08f70563          	beq	a4,a5,8000587a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057f4:	4641                	li	a2,16
    800057f6:	4581                	li	a1,0
    800057f8:	fc040513          	addi	a0,s0,-64
    800057fc:	ffffb097          	auipc	ra,0xffffb
    80005800:	4fc080e7          	jalr	1276(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005804:	4741                	li	a4,16
    80005806:	f2c42683          	lw	a3,-212(s0)
    8000580a:	fc040613          	addi	a2,s0,-64
    8000580e:	4581                	li	a1,0
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	516080e7          	jalr	1302(ra) # 80003d28 <writei>
    8000581a:	47c1                	li	a5,16
    8000581c:	0af51563          	bne	a0,a5,800058c6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005820:	04491703          	lh	a4,68(s2)
    80005824:	4785                	li	a5,1
    80005826:	0af70863          	beq	a4,a5,800058d6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000582a:	8526                	mv	a0,s1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	3b4080e7          	jalr	948(ra) # 80003be0 <iunlockput>
  ip->nlink--;
    80005834:	04a95783          	lhu	a5,74(s2)
    80005838:	37fd                	addiw	a5,a5,-1
    8000583a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000583e:	854a                	mv	a0,s2
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	074080e7          	jalr	116(ra) # 800038b4 <iupdate>
  iunlockput(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	396080e7          	jalr	918(ra) # 80003be0 <iunlockput>
  end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	b68080e7          	jalr	-1176(ra) # 800043ba <end_op>
  return 0;
    8000585a:	4501                	li	a0,0
    8000585c:	a84d                	j	8000590e <sys_unlink+0x1c4>
    end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	b5c080e7          	jalr	-1188(ra) # 800043ba <end_op>
    return -1;
    80005866:	557d                	li	a0,-1
    80005868:	a05d                	j	8000590e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000586a:	00003517          	auipc	a0,0x3
    8000586e:	efe50513          	addi	a0,a0,-258 # 80008768 <syscalls+0x2f0>
    80005872:	ffffb097          	auipc	ra,0xffffb
    80005876:	cce080e7          	jalr	-818(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000587a:	04c92703          	lw	a4,76(s2)
    8000587e:	02000793          	li	a5,32
    80005882:	f6e7f9e3          	bgeu	a5,a4,800057f4 <sys_unlink+0xaa>
    80005886:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000588a:	4741                	li	a4,16
    8000588c:	86ce                	mv	a3,s3
    8000588e:	f1840613          	addi	a2,s0,-232
    80005892:	4581                	li	a1,0
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	39c080e7          	jalr	924(ra) # 80003c32 <readi>
    8000589e:	47c1                	li	a5,16
    800058a0:	00f51b63          	bne	a0,a5,800058b6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058a4:	f1845783          	lhu	a5,-232(s0)
    800058a8:	e7a1                	bnez	a5,800058f0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058aa:	29c1                	addiw	s3,s3,16
    800058ac:	04c92783          	lw	a5,76(s2)
    800058b0:	fcf9ede3          	bltu	s3,a5,8000588a <sys_unlink+0x140>
    800058b4:	b781                	j	800057f4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058b6:	00003517          	auipc	a0,0x3
    800058ba:	eca50513          	addi	a0,a0,-310 # 80008780 <syscalls+0x308>
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	c82080e7          	jalr	-894(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058c6:	00003517          	auipc	a0,0x3
    800058ca:	ed250513          	addi	a0,a0,-302 # 80008798 <syscalls+0x320>
    800058ce:	ffffb097          	auipc	ra,0xffffb
    800058d2:	c72080e7          	jalr	-910(ra) # 80000540 <panic>
    dp->nlink--;
    800058d6:	04a4d783          	lhu	a5,74(s1)
    800058da:	37fd                	addiw	a5,a5,-1
    800058dc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	fd2080e7          	jalr	-46(ra) # 800038b4 <iupdate>
    800058ea:	b781                	j	8000582a <sys_unlink+0xe0>
    return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	a005                	j	8000590e <sys_unlink+0x1c4>
    iunlockput(ip);
    800058f0:	854a                	mv	a0,s2
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	2ee080e7          	jalr	750(ra) # 80003be0 <iunlockput>
  iunlockput(dp);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	2e4080e7          	jalr	740(ra) # 80003be0 <iunlockput>
  end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	ab6080e7          	jalr	-1354(ra) # 800043ba <end_op>
  return -1;
    8000590c:	557d                	li	a0,-1
}
    8000590e:	70ae                	ld	ra,232(sp)
    80005910:	740e                	ld	s0,224(sp)
    80005912:	64ee                	ld	s1,216(sp)
    80005914:	694e                	ld	s2,208(sp)
    80005916:	69ae                	ld	s3,200(sp)
    80005918:	616d                	addi	sp,sp,240
    8000591a:	8082                	ret

000000008000591c <sys_open>:

uint64
sys_open(void)
{
    8000591c:	7131                	addi	sp,sp,-192
    8000591e:	fd06                	sd	ra,184(sp)
    80005920:	f922                	sd	s0,176(sp)
    80005922:	f526                	sd	s1,168(sp)
    80005924:	f14a                	sd	s2,160(sp)
    80005926:	ed4e                	sd	s3,152(sp)
    80005928:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000592a:	08000613          	li	a2,128
    8000592e:	f5040593          	addi	a1,s0,-176
    80005932:	4501                	li	a0,0
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	4d2080e7          	jalr	1234(ra) # 80002e06 <argstr>
    return -1;
    8000593c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000593e:	0c054163          	bltz	a0,80005a00 <sys_open+0xe4>
    80005942:	f4c40593          	addi	a1,s0,-180
    80005946:	4505                	li	a0,1
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	47a080e7          	jalr	1146(ra) # 80002dc2 <argint>
    80005950:	0a054863          	bltz	a0,80005a00 <sys_open+0xe4>

  begin_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	9e6080e7          	jalr	-1562(ra) # 8000433a <begin_op>

  if(omode & O_CREATE){
    8000595c:	f4c42783          	lw	a5,-180(s0)
    80005960:	2007f793          	andi	a5,a5,512
    80005964:	cbdd                	beqz	a5,80005a1a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005966:	4681                	li	a3,0
    80005968:	4601                	li	a2,0
    8000596a:	4589                	li	a1,2
    8000596c:	f5040513          	addi	a0,s0,-176
    80005970:	00000097          	auipc	ra,0x0
    80005974:	974080e7          	jalr	-1676(ra) # 800052e4 <create>
    80005978:	892a                	mv	s2,a0
    if(ip == 0){
    8000597a:	c959                	beqz	a0,80005a10 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000597c:	04491703          	lh	a4,68(s2)
    80005980:	478d                	li	a5,3
    80005982:	00f71763          	bne	a4,a5,80005990 <sys_open+0x74>
    80005986:	04695703          	lhu	a4,70(s2)
    8000598a:	47a5                	li	a5,9
    8000598c:	0ce7ec63          	bltu	a5,a4,80005a64 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	dc0080e7          	jalr	-576(ra) # 80004750 <filealloc>
    80005998:	89aa                	mv	s3,a0
    8000599a:	10050263          	beqz	a0,80005a9e <sys_open+0x182>
    8000599e:	00000097          	auipc	ra,0x0
    800059a2:	904080e7          	jalr	-1788(ra) # 800052a2 <fdalloc>
    800059a6:	84aa                	mv	s1,a0
    800059a8:	0e054663          	bltz	a0,80005a94 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059ac:	04491703          	lh	a4,68(s2)
    800059b0:	478d                	li	a5,3
    800059b2:	0cf70463          	beq	a4,a5,80005a7a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059b6:	4789                	li	a5,2
    800059b8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059bc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059c0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059c4:	f4c42783          	lw	a5,-180(s0)
    800059c8:	0017c713          	xori	a4,a5,1
    800059cc:	8b05                	andi	a4,a4,1
    800059ce:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059d2:	0037f713          	andi	a4,a5,3
    800059d6:	00e03733          	snez	a4,a4
    800059da:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059de:	4007f793          	andi	a5,a5,1024
    800059e2:	c791                	beqz	a5,800059ee <sys_open+0xd2>
    800059e4:	04491703          	lh	a4,68(s2)
    800059e8:	4789                	li	a5,2
    800059ea:	08f70f63          	beq	a4,a5,80005a88 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059ee:	854a                	mv	a0,s2
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	050080e7          	jalr	80(ra) # 80003a40 <iunlock>
  end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	9c2080e7          	jalr	-1598(ra) # 800043ba <end_op>

  return fd;
}
    80005a00:	8526                	mv	a0,s1
    80005a02:	70ea                	ld	ra,184(sp)
    80005a04:	744a                	ld	s0,176(sp)
    80005a06:	74aa                	ld	s1,168(sp)
    80005a08:	790a                	ld	s2,160(sp)
    80005a0a:	69ea                	ld	s3,152(sp)
    80005a0c:	6129                	addi	sp,sp,192
    80005a0e:	8082                	ret
      end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	9aa080e7          	jalr	-1622(ra) # 800043ba <end_op>
      return -1;
    80005a18:	b7e5                	j	80005a00 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a1a:	f5040513          	addi	a0,s0,-176
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	710080e7          	jalr	1808(ra) # 8000412e <namei>
    80005a26:	892a                	mv	s2,a0
    80005a28:	c905                	beqz	a0,80005a58 <sys_open+0x13c>
    ilock(ip);
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	f54080e7          	jalr	-172(ra) # 8000397e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a32:	04491703          	lh	a4,68(s2)
    80005a36:	4785                	li	a5,1
    80005a38:	f4f712e3          	bne	a4,a5,8000597c <sys_open+0x60>
    80005a3c:	f4c42783          	lw	a5,-180(s0)
    80005a40:	dba1                	beqz	a5,80005990 <sys_open+0x74>
      iunlockput(ip);
    80005a42:	854a                	mv	a0,s2
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	19c080e7          	jalr	412(ra) # 80003be0 <iunlockput>
      end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	96e080e7          	jalr	-1682(ra) # 800043ba <end_op>
      return -1;
    80005a54:	54fd                	li	s1,-1
    80005a56:	b76d                	j	80005a00 <sys_open+0xe4>
      end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	962080e7          	jalr	-1694(ra) # 800043ba <end_op>
      return -1;
    80005a60:	54fd                	li	s1,-1
    80005a62:	bf79                	j	80005a00 <sys_open+0xe4>
    iunlockput(ip);
    80005a64:	854a                	mv	a0,s2
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	17a080e7          	jalr	378(ra) # 80003be0 <iunlockput>
    end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	94c080e7          	jalr	-1716(ra) # 800043ba <end_op>
    return -1;
    80005a76:	54fd                	li	s1,-1
    80005a78:	b761                	j	80005a00 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a7a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a7e:	04691783          	lh	a5,70(s2)
    80005a82:	02f99223          	sh	a5,36(s3)
    80005a86:	bf2d                	j	800059c0 <sys_open+0xa4>
    itrunc(ip);
    80005a88:	854a                	mv	a0,s2
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	002080e7          	jalr	2(ra) # 80003a8c <itrunc>
    80005a92:	bfb1                	j	800059ee <sys_open+0xd2>
      fileclose(f);
    80005a94:	854e                	mv	a0,s3
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	d76080e7          	jalr	-650(ra) # 8000480c <fileclose>
    iunlockput(ip);
    80005a9e:	854a                	mv	a0,s2
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	140080e7          	jalr	320(ra) # 80003be0 <iunlockput>
    end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	912080e7          	jalr	-1774(ra) # 800043ba <end_op>
    return -1;
    80005ab0:	54fd                	li	s1,-1
    80005ab2:	b7b9                	j	80005a00 <sys_open+0xe4>

0000000080005ab4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ab4:	7175                	addi	sp,sp,-144
    80005ab6:	e506                	sd	ra,136(sp)
    80005ab8:	e122                	sd	s0,128(sp)
    80005aba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	87e080e7          	jalr	-1922(ra) # 8000433a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ac4:	08000613          	li	a2,128
    80005ac8:	f7040593          	addi	a1,s0,-144
    80005acc:	4501                	li	a0,0
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	338080e7          	jalr	824(ra) # 80002e06 <argstr>
    80005ad6:	02054963          	bltz	a0,80005b08 <sys_mkdir+0x54>
    80005ada:	4681                	li	a3,0
    80005adc:	4601                	li	a2,0
    80005ade:	4585                	li	a1,1
    80005ae0:	f7040513          	addi	a0,s0,-144
    80005ae4:	00000097          	auipc	ra,0x0
    80005ae8:	800080e7          	jalr	-2048(ra) # 800052e4 <create>
    80005aec:	cd11                	beqz	a0,80005b08 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	0f2080e7          	jalr	242(ra) # 80003be0 <iunlockput>
  end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	8c4080e7          	jalr	-1852(ra) # 800043ba <end_op>
  return 0;
    80005afe:	4501                	li	a0,0
}
    80005b00:	60aa                	ld	ra,136(sp)
    80005b02:	640a                	ld	s0,128(sp)
    80005b04:	6149                	addi	sp,sp,144
    80005b06:	8082                	ret
    end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	8b2080e7          	jalr	-1870(ra) # 800043ba <end_op>
    return -1;
    80005b10:	557d                	li	a0,-1
    80005b12:	b7fd                	j	80005b00 <sys_mkdir+0x4c>

0000000080005b14 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b14:	7135                	addi	sp,sp,-160
    80005b16:	ed06                	sd	ra,152(sp)
    80005b18:	e922                	sd	s0,144(sp)
    80005b1a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	81e080e7          	jalr	-2018(ra) # 8000433a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b24:	08000613          	li	a2,128
    80005b28:	f7040593          	addi	a1,s0,-144
    80005b2c:	4501                	li	a0,0
    80005b2e:	ffffd097          	auipc	ra,0xffffd
    80005b32:	2d8080e7          	jalr	728(ra) # 80002e06 <argstr>
    80005b36:	04054a63          	bltz	a0,80005b8a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b3a:	f6c40593          	addi	a1,s0,-148
    80005b3e:	4505                	li	a0,1
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	282080e7          	jalr	642(ra) # 80002dc2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b48:	04054163          	bltz	a0,80005b8a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b4c:	f6840593          	addi	a1,s0,-152
    80005b50:	4509                	li	a0,2
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	270080e7          	jalr	624(ra) # 80002dc2 <argint>
     argint(1, &major) < 0 ||
    80005b5a:	02054863          	bltz	a0,80005b8a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b5e:	f6841683          	lh	a3,-152(s0)
    80005b62:	f6c41603          	lh	a2,-148(s0)
    80005b66:	458d                	li	a1,3
    80005b68:	f7040513          	addi	a0,s0,-144
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	778080e7          	jalr	1912(ra) # 800052e4 <create>
     argint(2, &minor) < 0 ||
    80005b74:	c919                	beqz	a0,80005b8a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	06a080e7          	jalr	106(ra) # 80003be0 <iunlockput>
  end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	83c080e7          	jalr	-1988(ra) # 800043ba <end_op>
  return 0;
    80005b86:	4501                	li	a0,0
    80005b88:	a031                	j	80005b94 <sys_mknod+0x80>
    end_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	830080e7          	jalr	-2000(ra) # 800043ba <end_op>
    return -1;
    80005b92:	557d                	li	a0,-1
}
    80005b94:	60ea                	ld	ra,152(sp)
    80005b96:	644a                	ld	s0,144(sp)
    80005b98:	610d                	addi	sp,sp,160
    80005b9a:	8082                	ret

0000000080005b9c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b9c:	7135                	addi	sp,sp,-160
    80005b9e:	ed06                	sd	ra,152(sp)
    80005ba0:	e922                	sd	s0,144(sp)
    80005ba2:	e526                	sd	s1,136(sp)
    80005ba4:	e14a                	sd	s2,128(sp)
    80005ba6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	f8c080e7          	jalr	-116(ra) # 80001b34 <myproc>
    80005bb0:	892a                	mv	s2,a0
  
  begin_op();
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	788080e7          	jalr	1928(ra) # 8000433a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bba:	08000613          	li	a2,128
    80005bbe:	f6040593          	addi	a1,s0,-160
    80005bc2:	4501                	li	a0,0
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	242080e7          	jalr	578(ra) # 80002e06 <argstr>
    80005bcc:	04054b63          	bltz	a0,80005c22 <sys_chdir+0x86>
    80005bd0:	f6040513          	addi	a0,s0,-160
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	55a080e7          	jalr	1370(ra) # 8000412e <namei>
    80005bdc:	84aa                	mv	s1,a0
    80005bde:	c131                	beqz	a0,80005c22 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	d9e080e7          	jalr	-610(ra) # 8000397e <ilock>
  if(ip->type != T_DIR){
    80005be8:	04449703          	lh	a4,68(s1)
    80005bec:	4785                	li	a5,1
    80005bee:	04f71063          	bne	a4,a5,80005c2e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bf2:	8526                	mv	a0,s1
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	e4c080e7          	jalr	-436(ra) # 80003a40 <iunlock>
  iput(p->cwd);
    80005bfc:	15093503          	ld	a0,336(s2)
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	f38080e7          	jalr	-200(ra) # 80003b38 <iput>
  end_op();
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	7b2080e7          	jalr	1970(ra) # 800043ba <end_op>
  p->cwd = ip;
    80005c10:	14993823          	sd	s1,336(s2)
  return 0;
    80005c14:	4501                	li	a0,0
}
    80005c16:	60ea                	ld	ra,152(sp)
    80005c18:	644a                	ld	s0,144(sp)
    80005c1a:	64aa                	ld	s1,136(sp)
    80005c1c:	690a                	ld	s2,128(sp)
    80005c1e:	610d                	addi	sp,sp,160
    80005c20:	8082                	ret
    end_op();
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	798080e7          	jalr	1944(ra) # 800043ba <end_op>
    return -1;
    80005c2a:	557d                	li	a0,-1
    80005c2c:	b7ed                	j	80005c16 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c2e:	8526                	mv	a0,s1
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	fb0080e7          	jalr	-80(ra) # 80003be0 <iunlockput>
    end_op();
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	782080e7          	jalr	1922(ra) # 800043ba <end_op>
    return -1;
    80005c40:	557d                	li	a0,-1
    80005c42:	bfd1                	j	80005c16 <sys_chdir+0x7a>

0000000080005c44 <sys_exec>:

uint64
sys_exec(void)
{
    80005c44:	7145                	addi	sp,sp,-464
    80005c46:	e786                	sd	ra,456(sp)
    80005c48:	e3a2                	sd	s0,448(sp)
    80005c4a:	ff26                	sd	s1,440(sp)
    80005c4c:	fb4a                	sd	s2,432(sp)
    80005c4e:	f74e                	sd	s3,424(sp)
    80005c50:	f352                	sd	s4,416(sp)
    80005c52:	ef56                	sd	s5,408(sp)
    80005c54:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c56:	08000613          	li	a2,128
    80005c5a:	f4040593          	addi	a1,s0,-192
    80005c5e:	4501                	li	a0,0
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	1a6080e7          	jalr	422(ra) # 80002e06 <argstr>
    return -1;
    80005c68:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c6a:	0c054a63          	bltz	a0,80005d3e <sys_exec+0xfa>
    80005c6e:	e3840593          	addi	a1,s0,-456
    80005c72:	4505                	li	a0,1
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	170080e7          	jalr	368(ra) # 80002de4 <argaddr>
    80005c7c:	0c054163          	bltz	a0,80005d3e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c80:	10000613          	li	a2,256
    80005c84:	4581                	li	a1,0
    80005c86:	e4040513          	addi	a0,s0,-448
    80005c8a:	ffffb097          	auipc	ra,0xffffb
    80005c8e:	06e080e7          	jalr	110(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c92:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c96:	89a6                	mv	s3,s1
    80005c98:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c9a:	02000a13          	li	s4,32
    80005c9e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ca2:	00391793          	slli	a5,s2,0x3
    80005ca6:	e3040593          	addi	a1,s0,-464
    80005caa:	e3843503          	ld	a0,-456(s0)
    80005cae:	953e                	add	a0,a0,a5
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	078080e7          	jalr	120(ra) # 80002d28 <fetchaddr>
    80005cb8:	02054a63          	bltz	a0,80005cec <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cbc:	e3043783          	ld	a5,-464(s0)
    80005cc0:	c3b9                	beqz	a5,80005d06 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cc2:	ffffb097          	auipc	ra,0xffffb
    80005cc6:	e4a080e7          	jalr	-438(ra) # 80000b0c <kalloc>
    80005cca:	85aa                	mv	a1,a0
    80005ccc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cd0:	cd11                	beqz	a0,80005cec <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cd2:	6605                	lui	a2,0x1
    80005cd4:	e3043503          	ld	a0,-464(s0)
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	0a2080e7          	jalr	162(ra) # 80002d7a <fetchstr>
    80005ce0:	00054663          	bltz	a0,80005cec <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ce4:	0905                	addi	s2,s2,1
    80005ce6:	09a1                	addi	s3,s3,8
    80005ce8:	fb491be3          	bne	s2,s4,80005c9e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cec:	10048913          	addi	s2,s1,256
    80005cf0:	6088                	ld	a0,0(s1)
    80005cf2:	c529                	beqz	a0,80005d3c <sys_exec+0xf8>
    kfree(argv[i]);
    80005cf4:	ffffb097          	auipc	ra,0xffffb
    80005cf8:	d1c080e7          	jalr	-740(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfc:	04a1                	addi	s1,s1,8
    80005cfe:	ff2499e3          	bne	s1,s2,80005cf0 <sys_exec+0xac>
  return -1;
    80005d02:	597d                	li	s2,-1
    80005d04:	a82d                	j	80005d3e <sys_exec+0xfa>
      argv[i] = 0;
    80005d06:	0a8e                	slli	s5,s5,0x3
    80005d08:	fc040793          	addi	a5,s0,-64
    80005d0c:	9abe                	add	s5,s5,a5
    80005d0e:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005d12:	e4040593          	addi	a1,s0,-448
    80005d16:	f4040513          	addi	a0,s0,-192
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	178080e7          	jalr	376(ra) # 80004e92 <exec>
    80005d22:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d24:	10048993          	addi	s3,s1,256
    80005d28:	6088                	ld	a0,0(s1)
    80005d2a:	c911                	beqz	a0,80005d3e <sys_exec+0xfa>
    kfree(argv[i]);
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	ce4080e7          	jalr	-796(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d34:	04a1                	addi	s1,s1,8
    80005d36:	ff3499e3          	bne	s1,s3,80005d28 <sys_exec+0xe4>
    80005d3a:	a011                	j	80005d3e <sys_exec+0xfa>
  return -1;
    80005d3c:	597d                	li	s2,-1
}
    80005d3e:	854a                	mv	a0,s2
    80005d40:	60be                	ld	ra,456(sp)
    80005d42:	641e                	ld	s0,448(sp)
    80005d44:	74fa                	ld	s1,440(sp)
    80005d46:	795a                	ld	s2,432(sp)
    80005d48:	79ba                	ld	s3,424(sp)
    80005d4a:	7a1a                	ld	s4,416(sp)
    80005d4c:	6afa                	ld	s5,408(sp)
    80005d4e:	6179                	addi	sp,sp,464
    80005d50:	8082                	ret

0000000080005d52 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d52:	7139                	addi	sp,sp,-64
    80005d54:	fc06                	sd	ra,56(sp)
    80005d56:	f822                	sd	s0,48(sp)
    80005d58:	f426                	sd	s1,40(sp)
    80005d5a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d5c:	ffffc097          	auipc	ra,0xffffc
    80005d60:	dd8080e7          	jalr	-552(ra) # 80001b34 <myproc>
    80005d64:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d66:	fd840593          	addi	a1,s0,-40
    80005d6a:	4501                	li	a0,0
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	078080e7          	jalr	120(ra) # 80002de4 <argaddr>
    return -1;
    80005d74:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d76:	0e054063          	bltz	a0,80005e56 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d7a:	fc840593          	addi	a1,s0,-56
    80005d7e:	fd040513          	addi	a0,s0,-48
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	de0080e7          	jalr	-544(ra) # 80004b62 <pipealloc>
    return -1;
    80005d8a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d8c:	0c054563          	bltz	a0,80005e56 <sys_pipe+0x104>
  fd0 = -1;
    80005d90:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d94:	fd043503          	ld	a0,-48(s0)
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	50a080e7          	jalr	1290(ra) # 800052a2 <fdalloc>
    80005da0:	fca42223          	sw	a0,-60(s0)
    80005da4:	08054c63          	bltz	a0,80005e3c <sys_pipe+0xea>
    80005da8:	fc843503          	ld	a0,-56(s0)
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	4f6080e7          	jalr	1270(ra) # 800052a2 <fdalloc>
    80005db4:	fca42023          	sw	a0,-64(s0)
    80005db8:	06054863          	bltz	a0,80005e28 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dbc:	4691                	li	a3,4
    80005dbe:	fc440613          	addi	a2,s0,-60
    80005dc2:	fd843583          	ld	a1,-40(s0)
    80005dc6:	68a8                	ld	a0,80(s1)
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	8e2080e7          	jalr	-1822(ra) # 800016aa <copyout>
    80005dd0:	02054063          	bltz	a0,80005df0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dd4:	4691                	li	a3,4
    80005dd6:	fc040613          	addi	a2,s0,-64
    80005dda:	fd843583          	ld	a1,-40(s0)
    80005dde:	0591                	addi	a1,a1,4
    80005de0:	68a8                	ld	a0,80(s1)
    80005de2:	ffffc097          	auipc	ra,0xffffc
    80005de6:	8c8080e7          	jalr	-1848(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dec:	06055563          	bgez	a0,80005e56 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005df0:	fc442783          	lw	a5,-60(s0)
    80005df4:	07e9                	addi	a5,a5,26
    80005df6:	078e                	slli	a5,a5,0x3
    80005df8:	97a6                	add	a5,a5,s1
    80005dfa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dfe:	fc042503          	lw	a0,-64(s0)
    80005e02:	0569                	addi	a0,a0,26
    80005e04:	050e                	slli	a0,a0,0x3
    80005e06:	9526                	add	a0,a0,s1
    80005e08:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e0c:	fd043503          	ld	a0,-48(s0)
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	9fc080e7          	jalr	-1540(ra) # 8000480c <fileclose>
    fileclose(wf);
    80005e18:	fc843503          	ld	a0,-56(s0)
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	9f0080e7          	jalr	-1552(ra) # 8000480c <fileclose>
    return -1;
    80005e24:	57fd                	li	a5,-1
    80005e26:	a805                	j	80005e56 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e28:	fc442783          	lw	a5,-60(s0)
    80005e2c:	0007c863          	bltz	a5,80005e3c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e30:	01a78513          	addi	a0,a5,26
    80005e34:	050e                	slli	a0,a0,0x3
    80005e36:	9526                	add	a0,a0,s1
    80005e38:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e3c:	fd043503          	ld	a0,-48(s0)
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	9cc080e7          	jalr	-1588(ra) # 8000480c <fileclose>
    fileclose(wf);
    80005e48:	fc843503          	ld	a0,-56(s0)
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	9c0080e7          	jalr	-1600(ra) # 8000480c <fileclose>
    return -1;
    80005e54:	57fd                	li	a5,-1
}
    80005e56:	853e                	mv	a0,a5
    80005e58:	70e2                	ld	ra,56(sp)
    80005e5a:	7442                	ld	s0,48(sp)
    80005e5c:	74a2                	ld	s1,40(sp)
    80005e5e:	6121                	addi	sp,sp,64
    80005e60:	8082                	ret
	...

0000000080005e70 <kernelvec>:
    80005e70:	7111                	addi	sp,sp,-256
    80005e72:	e006                	sd	ra,0(sp)
    80005e74:	e40a                	sd	sp,8(sp)
    80005e76:	e80e                	sd	gp,16(sp)
    80005e78:	ec12                	sd	tp,24(sp)
    80005e7a:	f016                	sd	t0,32(sp)
    80005e7c:	f41a                	sd	t1,40(sp)
    80005e7e:	f81e                	sd	t2,48(sp)
    80005e80:	fc22                	sd	s0,56(sp)
    80005e82:	e0a6                	sd	s1,64(sp)
    80005e84:	e4aa                	sd	a0,72(sp)
    80005e86:	e8ae                	sd	a1,80(sp)
    80005e88:	ecb2                	sd	a2,88(sp)
    80005e8a:	f0b6                	sd	a3,96(sp)
    80005e8c:	f4ba                	sd	a4,104(sp)
    80005e8e:	f8be                	sd	a5,112(sp)
    80005e90:	fcc2                	sd	a6,120(sp)
    80005e92:	e146                	sd	a7,128(sp)
    80005e94:	e54a                	sd	s2,136(sp)
    80005e96:	e94e                	sd	s3,144(sp)
    80005e98:	ed52                	sd	s4,152(sp)
    80005e9a:	f156                	sd	s5,160(sp)
    80005e9c:	f55a                	sd	s6,168(sp)
    80005e9e:	f95e                	sd	s7,176(sp)
    80005ea0:	fd62                	sd	s8,184(sp)
    80005ea2:	e1e6                	sd	s9,192(sp)
    80005ea4:	e5ea                	sd	s10,200(sp)
    80005ea6:	e9ee                	sd	s11,208(sp)
    80005ea8:	edf2                	sd	t3,216(sp)
    80005eaa:	f1f6                	sd	t4,224(sp)
    80005eac:	f5fa                	sd	t5,232(sp)
    80005eae:	f9fe                	sd	t6,240(sp)
    80005eb0:	d2dfc0ef          	jal	ra,80002bdc <kerneltrap>
    80005eb4:	6082                	ld	ra,0(sp)
    80005eb6:	6122                	ld	sp,8(sp)
    80005eb8:	61c2                	ld	gp,16(sp)
    80005eba:	7282                	ld	t0,32(sp)
    80005ebc:	7322                	ld	t1,40(sp)
    80005ebe:	73c2                	ld	t2,48(sp)
    80005ec0:	7462                	ld	s0,56(sp)
    80005ec2:	6486                	ld	s1,64(sp)
    80005ec4:	6526                	ld	a0,72(sp)
    80005ec6:	65c6                	ld	a1,80(sp)
    80005ec8:	6666                	ld	a2,88(sp)
    80005eca:	7686                	ld	a3,96(sp)
    80005ecc:	7726                	ld	a4,104(sp)
    80005ece:	77c6                	ld	a5,112(sp)
    80005ed0:	7866                	ld	a6,120(sp)
    80005ed2:	688a                	ld	a7,128(sp)
    80005ed4:	692a                	ld	s2,136(sp)
    80005ed6:	69ca                	ld	s3,144(sp)
    80005ed8:	6a6a                	ld	s4,152(sp)
    80005eda:	7a8a                	ld	s5,160(sp)
    80005edc:	7b2a                	ld	s6,168(sp)
    80005ede:	7bca                	ld	s7,176(sp)
    80005ee0:	7c6a                	ld	s8,184(sp)
    80005ee2:	6c8e                	ld	s9,192(sp)
    80005ee4:	6d2e                	ld	s10,200(sp)
    80005ee6:	6dce                	ld	s11,208(sp)
    80005ee8:	6e6e                	ld	t3,216(sp)
    80005eea:	7e8e                	ld	t4,224(sp)
    80005eec:	7f2e                	ld	t5,232(sp)
    80005eee:	7fce                	ld	t6,240(sp)
    80005ef0:	6111                	addi	sp,sp,256
    80005ef2:	10200073          	sret
    80005ef6:	00000013          	nop
    80005efa:	00000013          	nop
    80005efe:	0001                	nop

0000000080005f00 <timervec>:
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	e10c                	sd	a1,0(a0)
    80005f06:	e510                	sd	a2,8(a0)
    80005f08:	e914                	sd	a3,16(a0)
    80005f0a:	710c                	ld	a1,32(a0)
    80005f0c:	7510                	ld	a2,40(a0)
    80005f0e:	6194                	ld	a3,0(a1)
    80005f10:	96b2                	add	a3,a3,a2
    80005f12:	e194                	sd	a3,0(a1)
    80005f14:	4589                	li	a1,2
    80005f16:	14459073          	csrw	sip,a1
    80005f1a:	6914                	ld	a3,16(a0)
    80005f1c:	6510                	ld	a2,8(a0)
    80005f1e:	610c                	ld	a1,0(a0)
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	30200073          	mret
	...

0000000080005f2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f2a:	1141                	addi	sp,sp,-16
    80005f2c:	e422                	sd	s0,8(sp)
    80005f2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f30:	0c0007b7          	lui	a5,0xc000
    80005f34:	4705                	li	a4,1
    80005f36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f38:	c3d8                	sw	a4,4(a5)
}
    80005f3a:	6422                	ld	s0,8(sp)
    80005f3c:	0141                	addi	sp,sp,16
    80005f3e:	8082                	ret

0000000080005f40 <plicinithart>:

void
plicinithart(void)
{
    80005f40:	1141                	addi	sp,sp,-16
    80005f42:	e406                	sd	ra,8(sp)
    80005f44:	e022                	sd	s0,0(sp)
    80005f46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	bc0080e7          	jalr	-1088(ra) # 80001b08 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f50:	0085171b          	slliw	a4,a0,0x8
    80005f54:	0c0027b7          	lui	a5,0xc002
    80005f58:	97ba                	add	a5,a5,a4
    80005f5a:	40200713          	li	a4,1026
    80005f5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f62:	00d5151b          	slliw	a0,a0,0xd
    80005f66:	0c2017b7          	lui	a5,0xc201
    80005f6a:	953e                	add	a0,a0,a5
    80005f6c:	00052023          	sw	zero,0(a0)
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret

0000000080005f78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f78:	1141                	addi	sp,sp,-16
    80005f7a:	e406                	sd	ra,8(sp)
    80005f7c:	e022                	sd	s0,0(sp)
    80005f7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	b88080e7          	jalr	-1144(ra) # 80001b08 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f88:	00d5179b          	slliw	a5,a0,0xd
    80005f8c:	0c201537          	lui	a0,0xc201
    80005f90:	953e                	add	a0,a0,a5
  return irq;
}
    80005f92:	4148                	lw	a0,4(a0)
    80005f94:	60a2                	ld	ra,8(sp)
    80005f96:	6402                	ld	s0,0(sp)
    80005f98:	0141                	addi	sp,sp,16
    80005f9a:	8082                	ret

0000000080005f9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f9c:	1101                	addi	sp,sp,-32
    80005f9e:	ec06                	sd	ra,24(sp)
    80005fa0:	e822                	sd	s0,16(sp)
    80005fa2:	e426                	sd	s1,8(sp)
    80005fa4:	1000                	addi	s0,sp,32
    80005fa6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	b60080e7          	jalr	-1184(ra) # 80001b08 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fb0:	00d5151b          	slliw	a0,a0,0xd
    80005fb4:	0c2017b7          	lui	a5,0xc201
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	c3c4                	sw	s1,4(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6105                	addi	sp,sp,32
    80005fc4:	8082                	ret

0000000080005fc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fc6:	1141                	addi	sp,sp,-16
    80005fc8:	e406                	sd	ra,8(sp)
    80005fca:	e022                	sd	s0,0(sp)
    80005fcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fce:	479d                	li	a5,7
    80005fd0:	04a7cc63          	blt	a5,a0,80006028 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fd4:	0001e797          	auipc	a5,0x1e
    80005fd8:	02c78793          	addi	a5,a5,44 # 80024000 <disk>
    80005fdc:	00a78733          	add	a4,a5,a0
    80005fe0:	6789                	lui	a5,0x2
    80005fe2:	97ba                	add	a5,a5,a4
    80005fe4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fe8:	eba1                	bnez	a5,80006038 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005fea:	00451713          	slli	a4,a0,0x4
    80005fee:	00020797          	auipc	a5,0x20
    80005ff2:	0127b783          	ld	a5,18(a5) # 80026000 <disk+0x2000>
    80005ff6:	97ba                	add	a5,a5,a4
    80005ff8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ffc:	0001e797          	auipc	a5,0x1e
    80006000:	00478793          	addi	a5,a5,4 # 80024000 <disk>
    80006004:	97aa                	add	a5,a5,a0
    80006006:	6509                	lui	a0,0x2
    80006008:	953e                	add	a0,a0,a5
    8000600a:	4785                	li	a5,1
    8000600c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006010:	00020517          	auipc	a0,0x20
    80006014:	00850513          	addi	a0,a0,8 # 80026018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	5fe080e7          	jalr	1534(ra) # 80002616 <wakeup>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret
    panic("virtio_disk_intr 1");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	78050513          	addi	a0,a0,1920 # 800087a8 <syscalls+0x330>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	78850513          	addi	a0,a0,1928 # 800087c0 <syscalls+0x348>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	500080e7          	jalr	1280(ra) # 80000540 <panic>

0000000080006048 <virtio_disk_init>:
{
    80006048:	1101                	addi	sp,sp,-32
    8000604a:	ec06                	sd	ra,24(sp)
    8000604c:	e822                	sd	s0,16(sp)
    8000604e:	e426                	sd	s1,8(sp)
    80006050:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006052:	00002597          	auipc	a1,0x2
    80006056:	78658593          	addi	a1,a1,1926 # 800087d8 <syscalls+0x360>
    8000605a:	00020517          	auipc	a0,0x20
    8000605e:	04e50513          	addi	a0,a0,78 # 800260a8 <disk+0x20a8>
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	b0a080e7          	jalr	-1270(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	4398                	lw	a4,0(a5)
    80006070:	2701                	sext.w	a4,a4
    80006072:	747277b7          	lui	a5,0x74727
    80006076:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000607a:	0ef71163          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	43dc                	lw	a5,4(a5)
    80006084:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006086:	4705                	li	a4,1
    80006088:	0ce79a63          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	479c                	lw	a5,8(a5)
    80006092:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006094:	4709                	li	a4,2
    80006096:	0ce79363          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	47d8                	lw	a4,12(a5)
    800060a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060a2:	554d47b7          	lui	a5,0x554d4
    800060a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060aa:	0af71963          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	4705                	li	a4,1
    800060b4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b6:	470d                	li	a4,3
    800060b8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060bc:	c7ffe737          	lui	a4,0xc7ffe
    800060c0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800060c4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060c6:	2701                	sext.w	a4,a4
    800060c8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ca:	472d                	li	a4,11
    800060cc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	473d                	li	a4,15
    800060d0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060d2:	6705                	lui	a4,0x1
    800060d4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060d6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060da:	5bdc                	lw	a5,52(a5)
    800060dc:	2781                	sext.w	a5,a5
  if(max == 0)
    800060de:	c7d9                	beqz	a5,8000616c <virtio_disk_init+0x124>
  if(max < NUM)
    800060e0:	471d                	li	a4,7
    800060e2:	08f77d63          	bgeu	a4,a5,8000617c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e6:	100014b7          	lui	s1,0x10001
    800060ea:	47a1                	li	a5,8
    800060ec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060ee:	6609                	lui	a2,0x2
    800060f0:	4581                	li	a1,0
    800060f2:	0001e517          	auipc	a0,0x1e
    800060f6:	f0e50513          	addi	a0,a0,-242 # 80024000 <disk>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	bfe080e7          	jalr	-1026(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006102:	0001e717          	auipc	a4,0x1e
    80006106:	efe70713          	addi	a4,a4,-258 # 80024000 <disk>
    8000610a:	00c75793          	srli	a5,a4,0xc
    8000610e:	2781                	sext.w	a5,a5
    80006110:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006112:	00020797          	auipc	a5,0x20
    80006116:	eee78793          	addi	a5,a5,-274 # 80026000 <disk+0x2000>
    8000611a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000611c:	0001e717          	auipc	a4,0x1e
    80006120:	f6470713          	addi	a4,a4,-156 # 80024080 <disk+0x80>
    80006124:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006126:	0001f717          	auipc	a4,0x1f
    8000612a:	eda70713          	addi	a4,a4,-294 # 80025000 <disk+0x1000>
    8000612e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006130:	4705                	li	a4,1
    80006132:	00e78c23          	sb	a4,24(a5)
    80006136:	00e78ca3          	sb	a4,25(a5)
    8000613a:	00e78d23          	sb	a4,26(a5)
    8000613e:	00e78da3          	sb	a4,27(a5)
    80006142:	00e78e23          	sb	a4,28(a5)
    80006146:	00e78ea3          	sb	a4,29(a5)
    8000614a:	00e78f23          	sb	a4,30(a5)
    8000614e:	00e78fa3          	sb	a4,31(a5)
}
    80006152:	60e2                	ld	ra,24(sp)
    80006154:	6442                	ld	s0,16(sp)
    80006156:	64a2                	ld	s1,8(sp)
    80006158:	6105                	addi	sp,sp,32
    8000615a:	8082                	ret
    panic("could not find virtio disk");
    8000615c:	00002517          	auipc	a0,0x2
    80006160:	68c50513          	addi	a0,a0,1676 # 800087e8 <syscalls+0x370>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	3dc080e7          	jalr	988(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	69c50513          	addi	a0,a0,1692 # 80008808 <syscalls+0x390>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	3cc080e7          	jalr	972(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	6ac50513          	addi	a0,a0,1708 # 80008828 <syscalls+0x3b0>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3bc080e7          	jalr	956(ra) # 80000540 <panic>

000000008000618c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000618c:	7175                	addi	sp,sp,-144
    8000618e:	e506                	sd	ra,136(sp)
    80006190:	e122                	sd	s0,128(sp)
    80006192:	fca6                	sd	s1,120(sp)
    80006194:	f8ca                	sd	s2,112(sp)
    80006196:	f4ce                	sd	s3,104(sp)
    80006198:	f0d2                	sd	s4,96(sp)
    8000619a:	ecd6                	sd	s5,88(sp)
    8000619c:	e8da                	sd	s6,80(sp)
    8000619e:	e4de                	sd	s7,72(sp)
    800061a0:	e0e2                	sd	s8,64(sp)
    800061a2:	fc66                	sd	s9,56(sp)
    800061a4:	f86a                	sd	s10,48(sp)
    800061a6:	f46e                	sd	s11,40(sp)
    800061a8:	0900                	addi	s0,sp,144
    800061aa:	8aaa                	mv	s5,a0
    800061ac:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061ae:	00c52c83          	lw	s9,12(a0)
    800061b2:	001c9c9b          	slliw	s9,s9,0x1
    800061b6:	1c82                	slli	s9,s9,0x20
    800061b8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061bc:	00020517          	auipc	a0,0x20
    800061c0:	eec50513          	addi	a0,a0,-276 # 800260a8 <disk+0x20a8>
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	a38080e7          	jalr	-1480(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    800061cc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061ce:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061d0:	0001ec17          	auipc	s8,0x1e
    800061d4:	e30c0c13          	addi	s8,s8,-464 # 80024000 <disk>
    800061d8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061da:	4b0d                	li	s6,3
    800061dc:	a0ad                	j	80006246 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061de:	00fc0733          	add	a4,s8,a5
    800061e2:	975e                	add	a4,a4,s7
    800061e4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061e8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061ea:	0207c563          	bltz	a5,80006214 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061ee:	2905                	addiw	s2,s2,1
    800061f0:	0611                	addi	a2,a2,4
    800061f2:	19690d63          	beq	s2,s6,8000638c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061f6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061f8:	00020717          	auipc	a4,0x20
    800061fc:	e2070713          	addi	a4,a4,-480 # 80026018 <disk+0x2018>
    80006200:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006202:	00074683          	lbu	a3,0(a4)
    80006206:	fee1                	bnez	a3,800061de <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	0705                	addi	a4,a4,1
    8000620c:	fe979be3          	bne	a5,s1,80006202 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006210:	57fd                	li	a5,-1
    80006212:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006214:	01205d63          	blez	s2,8000622e <virtio_disk_rw+0xa2>
    80006218:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000621a:	000a2503          	lw	a0,0(s4)
    8000621e:	00000097          	auipc	ra,0x0
    80006222:	da8080e7          	jalr	-600(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006226:	2d85                	addiw	s11,s11,1
    80006228:	0a11                	addi	s4,s4,4
    8000622a:	ffb918e3          	bne	s2,s11,8000621a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000622e:	00020597          	auipc	a1,0x20
    80006232:	e7a58593          	addi	a1,a1,-390 # 800260a8 <disk+0x20a8>
    80006236:	00020517          	auipc	a0,0x20
    8000623a:	de250513          	addi	a0,a0,-542 # 80026018 <disk+0x2018>
    8000623e:	ffffc097          	auipc	ra,0xffffc
    80006242:	22c080e7          	jalr	556(ra) # 8000246a <sleep>
  for(int i = 0; i < 3; i++){
    80006246:	f8040a13          	addi	s4,s0,-128
{
    8000624a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000624c:	894e                	mv	s2,s3
    8000624e:	b765                	j	800061f6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006250:	00020717          	auipc	a4,0x20
    80006254:	db073703          	ld	a4,-592(a4) # 80026000 <disk+0x2000>
    80006258:	973e                	add	a4,a4,a5
    8000625a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000625e:	0001e517          	auipc	a0,0x1e
    80006262:	da250513          	addi	a0,a0,-606 # 80024000 <disk>
    80006266:	00020717          	auipc	a4,0x20
    8000626a:	d9a70713          	addi	a4,a4,-614 # 80026000 <disk+0x2000>
    8000626e:	6314                	ld	a3,0(a4)
    80006270:	96be                	add	a3,a3,a5
    80006272:	00c6d603          	lhu	a2,12(a3)
    80006276:	00166613          	ori	a2,a2,1
    8000627a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000627e:	f8842683          	lw	a3,-120(s0)
    80006282:	6310                	ld	a2,0(a4)
    80006284:	97b2                	add	a5,a5,a2
    80006286:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000628a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000628e:	0612                	slli	a2,a2,0x4
    80006290:	962a                	add	a2,a2,a0
    80006292:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006296:	00469793          	slli	a5,a3,0x4
    8000629a:	630c                	ld	a1,0(a4)
    8000629c:	95be                	add	a1,a1,a5
    8000629e:	6689                	lui	a3,0x2
    800062a0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800062a4:	96ca                	add	a3,a3,s2
    800062a6:	96aa                	add	a3,a3,a0
    800062a8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800062aa:	6314                	ld	a3,0(a4)
    800062ac:	96be                	add	a3,a3,a5
    800062ae:	4585                	li	a1,1
    800062b0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062b2:	6314                	ld	a3,0(a4)
    800062b4:	96be                	add	a3,a3,a5
    800062b6:	4509                	li	a0,2
    800062b8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062bc:	6314                	ld	a3,0(a4)
    800062be:	97b6                	add	a5,a5,a3
    800062c0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062c4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800062c8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062cc:	6714                	ld	a3,8(a4)
    800062ce:	0026d783          	lhu	a5,2(a3)
    800062d2:	8b9d                	andi	a5,a5,7
    800062d4:	0789                	addi	a5,a5,2
    800062d6:	0786                	slli	a5,a5,0x1
    800062d8:	97b6                	add	a5,a5,a3
    800062da:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800062de:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062e2:	6718                	ld	a4,8(a4)
    800062e4:	00275783          	lhu	a5,2(a4)
    800062e8:	2785                	addiw	a5,a5,1
    800062ea:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062f6:	004aa783          	lw	a5,4(s5)
    800062fa:	02b79163          	bne	a5,a1,8000631c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062fe:	00020917          	auipc	s2,0x20
    80006302:	daa90913          	addi	s2,s2,-598 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006306:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006308:	85ca                	mv	a1,s2
    8000630a:	8556                	mv	a0,s5
    8000630c:	ffffc097          	auipc	ra,0xffffc
    80006310:	15e080e7          	jalr	350(ra) # 8000246a <sleep>
  while(b->disk == 1) {
    80006314:	004aa783          	lw	a5,4(s5)
    80006318:	fe9788e3          	beq	a5,s1,80006308 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000631c:	f8042483          	lw	s1,-128(s0)
    80006320:	20048793          	addi	a5,s1,512
    80006324:	00479713          	slli	a4,a5,0x4
    80006328:	0001e797          	auipc	a5,0x1e
    8000632c:	cd878793          	addi	a5,a5,-808 # 80024000 <disk>
    80006330:	97ba                	add	a5,a5,a4
    80006332:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006336:	00020917          	auipc	s2,0x20
    8000633a:	cca90913          	addi	s2,s2,-822 # 80026000 <disk+0x2000>
    8000633e:	a019                	j	80006344 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006340:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006344:	8526                	mv	a0,s1
    80006346:	00000097          	auipc	ra,0x0
    8000634a:	c80080e7          	jalr	-896(ra) # 80005fc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000634e:	0492                	slli	s1,s1,0x4
    80006350:	00093783          	ld	a5,0(s2)
    80006354:	94be                	add	s1,s1,a5
    80006356:	00c4d783          	lhu	a5,12(s1)
    8000635a:	8b85                	andi	a5,a5,1
    8000635c:	f3f5                	bnez	a5,80006340 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000635e:	00020517          	auipc	a0,0x20
    80006362:	d4a50513          	addi	a0,a0,-694 # 800260a8 <disk+0x20a8>
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	94a080e7          	jalr	-1718(ra) # 80000cb0 <release>
}
    8000636e:	60aa                	ld	ra,136(sp)
    80006370:	640a                	ld	s0,128(sp)
    80006372:	74e6                	ld	s1,120(sp)
    80006374:	7946                	ld	s2,112(sp)
    80006376:	79a6                	ld	s3,104(sp)
    80006378:	7a06                	ld	s4,96(sp)
    8000637a:	6ae6                	ld	s5,88(sp)
    8000637c:	6b46                	ld	s6,80(sp)
    8000637e:	6ba6                	ld	s7,72(sp)
    80006380:	6c06                	ld	s8,64(sp)
    80006382:	7ce2                	ld	s9,56(sp)
    80006384:	7d42                	ld	s10,48(sp)
    80006386:	7da2                	ld	s11,40(sp)
    80006388:	6149                	addi	sp,sp,144
    8000638a:	8082                	ret
  if(write)
    8000638c:	01a037b3          	snez	a5,s10
    80006390:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006394:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006398:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000639c:	f8042483          	lw	s1,-128(s0)
    800063a0:	00449913          	slli	s2,s1,0x4
    800063a4:	00020997          	auipc	s3,0x20
    800063a8:	c5c98993          	addi	s3,s3,-932 # 80026000 <disk+0x2000>
    800063ac:	0009ba03          	ld	s4,0(s3)
    800063b0:	9a4a                	add	s4,s4,s2
    800063b2:	f7040513          	addi	a0,s0,-144
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	d02080e7          	jalr	-766(ra) # 800010b8 <kvmpa>
    800063be:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800063c2:	0009b783          	ld	a5,0(s3)
    800063c6:	97ca                	add	a5,a5,s2
    800063c8:	4741                	li	a4,16
    800063ca:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063cc:	0009b783          	ld	a5,0(s3)
    800063d0:	97ca                	add	a5,a5,s2
    800063d2:	4705                	li	a4,1
    800063d4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063d8:	f8442783          	lw	a5,-124(s0)
    800063dc:	0009b703          	ld	a4,0(s3)
    800063e0:	974a                	add	a4,a4,s2
    800063e2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063e6:	0792                	slli	a5,a5,0x4
    800063e8:	0009b703          	ld	a4,0(s3)
    800063ec:	973e                	add	a4,a4,a5
    800063ee:	058a8693          	addi	a3,s5,88
    800063f2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800063f4:	0009b703          	ld	a4,0(s3)
    800063f8:	973e                	add	a4,a4,a5
    800063fa:	40000693          	li	a3,1024
    800063fe:	c714                	sw	a3,8(a4)
  if(write)
    80006400:	e40d18e3          	bnez	s10,80006250 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006404:	00020717          	auipc	a4,0x20
    80006408:	bfc73703          	ld	a4,-1028(a4) # 80026000 <disk+0x2000>
    8000640c:	973e                	add	a4,a4,a5
    8000640e:	4689                	li	a3,2
    80006410:	00d71623          	sh	a3,12(a4)
    80006414:	b5a9                	j	8000625e <virtio_disk_rw+0xd2>

0000000080006416 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006416:	1101                	addi	sp,sp,-32
    80006418:	ec06                	sd	ra,24(sp)
    8000641a:	e822                	sd	s0,16(sp)
    8000641c:	e426                	sd	s1,8(sp)
    8000641e:	e04a                	sd	s2,0(sp)
    80006420:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006422:	00020517          	auipc	a0,0x20
    80006426:	c8650513          	addi	a0,a0,-890 # 800260a8 <disk+0x20a8>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	7d2080e7          	jalr	2002(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006432:	00020717          	auipc	a4,0x20
    80006436:	bce70713          	addi	a4,a4,-1074 # 80026000 <disk+0x2000>
    8000643a:	02075783          	lhu	a5,32(a4)
    8000643e:	6b18                	ld	a4,16(a4)
    80006440:	00275683          	lhu	a3,2(a4)
    80006444:	8ebd                	xor	a3,a3,a5
    80006446:	8a9d                	andi	a3,a3,7
    80006448:	cab9                	beqz	a3,8000649e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000644a:	0001e917          	auipc	s2,0x1e
    8000644e:	bb690913          	addi	s2,s2,-1098 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006452:	00020497          	auipc	s1,0x20
    80006456:	bae48493          	addi	s1,s1,-1106 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000645a:	078e                	slli	a5,a5,0x3
    8000645c:	97ba                	add	a5,a5,a4
    8000645e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006460:	20078713          	addi	a4,a5,512
    80006464:	0712                	slli	a4,a4,0x4
    80006466:	974a                	add	a4,a4,s2
    80006468:	03074703          	lbu	a4,48(a4)
    8000646c:	ef21                	bnez	a4,800064c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000646e:	20078793          	addi	a5,a5,512
    80006472:	0792                	slli	a5,a5,0x4
    80006474:	97ca                	add	a5,a5,s2
    80006476:	7798                	ld	a4,40(a5)
    80006478:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000647c:	7788                	ld	a0,40(a5)
    8000647e:	ffffc097          	auipc	ra,0xffffc
    80006482:	198080e7          	jalr	408(ra) # 80002616 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006486:	0204d783          	lhu	a5,32(s1)
    8000648a:	2785                	addiw	a5,a5,1
    8000648c:	8b9d                	andi	a5,a5,7
    8000648e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006492:	6898                	ld	a4,16(s1)
    80006494:	00275683          	lhu	a3,2(a4)
    80006498:	8a9d                	andi	a3,a3,7
    8000649a:	fcf690e3          	bne	a3,a5,8000645a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000649e:	10001737          	lui	a4,0x10001
    800064a2:	533c                	lw	a5,96(a4)
    800064a4:	8b8d                	andi	a5,a5,3
    800064a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064a8:	00020517          	auipc	a0,0x20
    800064ac:	c0050513          	addi	a0,a0,-1024 # 800260a8 <disk+0x20a8>
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	800080e7          	jalr	-2048(ra) # 80000cb0 <release>
}
    800064b8:	60e2                	ld	ra,24(sp)
    800064ba:	6442                	ld	s0,16(sp)
    800064bc:	64a2                	ld	s1,8(sp)
    800064be:	6902                	ld	s2,0(sp)
    800064c0:	6105                	addi	sp,sp,32
    800064c2:	8082                	ret
      panic("virtio_disk_intr status");
    800064c4:	00002517          	auipc	a0,0x2
    800064c8:	38450513          	addi	a0,a0,900 # 80008848 <syscalls+0x3d0>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	074080e7          	jalr	116(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
