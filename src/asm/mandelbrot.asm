%include 'io.inc'
%include 'gfx.inc'
%include 'util.inc'

%define	ResX	1024
%define	ResY	768

global main

section .text
;
;

GET_USER_INFO:
	mov		eax, infomsg
	call	io_writestr
	mov		eax, kerdes
	call	io_writestr
	call	io_readint
	test	eax, eax
	jz		.mandel
	mov		[MANDEL_OR_JULIA], dword 1
	mov		eax, melyikJulia
	call	io_writestr
	call	io_readint
	cmp		eax, 1
	jne		.ketto
	movss	xmm0, [defaultRe1]
	movss	[k_c_re], xmm0
	movss	xmm0, [defaultIm1]
	movss	[k_c_im], xmm0
	jmp		.vege
.ketto:
	cmp		eax, 2
	jne		.harom
	movss	xmm0, [defaultRe2]
	movss	[k_c_re], xmm0
	movss	xmm0, [defaultIm2]
	movss	[k_c_im], xmm0
	jmp		.vege
.harom:
	movss	xmm0, [defaultRe3]
	movss	[k_c_re], xmm0
	movss	xmm0, [defaultIm3]
	movss	[k_c_im], xmm0
	jmp		.vege
.mandel:
	mov		[MANDEL_OR_JULIA], dword 0
.vege:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteBorderValues:
	sub		esp, 16
	movdqu	[esp], xmm0
	
	movss	xmm0, [leftValue]
	call	io_writeflt
	call	io_writeln
	movss	xmm0, [rightValue]
	call	io_writeflt
	call	io_writeln
	movss	xmm0, [topValue]
	call	io_writeflt
	call	io_writeln
	movss	xmm0, [bottomValue]
	call	io_writeflt
	call	io_writeln
	call	io_writeln
	movdqu	xmm0, [esp]
	add		esp, 16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitLimits:
	push	eax
	sub		esp, 16
	movdqu	[esp], xmm0
	
	movss	xmm0, [LeftLimit]
	movss	[leftValue], xmm0
	
	movss	xmm0, [RightLimit]
	movss	[rightValue], xmm0
	
	movss	xmm0, [TopLimit]
	movss	[topValue], xmm0
	
	movss	xmm0, [BottomLimit]
	movss	[bottomValue], xmm0
	
	
	pop		eax
	movdqu	xmm0, [esp]
	add		esp, 16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bitmaszFeldolgozas:
;(xmm2) -> esi
; megkapja xmm2-ben a bitmaszkot, ezt feldolgozza, kiloki esi-ben az uj iteraciok szamat
	xor		edi, edi		; minden iteracioban megszamolom, hogy hany futott ki; eddig 0
	
	movd	edx, xmm2		;bitenkenti masolas; elso szam
	test 	edx, edx		; ha 0 => erre NEM teljesult az osszehasonlitas => ez >>> 2 => ez mar kifutott
	jz		.kifutott_1	
	inc		al				; ha NEM 0 => ez meg kisebb mint 2 => meg szamolom az iteraciot
	jmp		.nemfutottki_1
.kifutott_1:
	inc		edi
.nemfutottki_1:
	shufps	xmm2, xmm2, 0x39;lehozom a kovetkezo osszehasonlitas-eredmenyt
	movd	edx, xmm2
	test	edx, edx
	jz		.kifutott_2
	inc		ah
	jmp		.nemfutottki_2
.kifutott_2:
	inc		edi
.nemfutottki_2:
	shufps	xmm2, xmm2, 0x39
	movd	edx, xmm2
	test	edx, edx
	jz		.kifutott_3
	inc		bl
	jmp		.nemfutottki_3
.kifutott_3:
	inc		edi
.nemfutottki_3:
	shufps	xmm2, xmm2, 0x39
	movd	edx, xmm2
	test	edx, edx
	jz		.kifutott_4
	inc		bh
	jmp		.nemfutottki_4
.kifutott_4:
	inc		edi
.nemfutottki_4:
	cmp		edi, 4
	je		.mindkifutottak
	
	clc		;meg van, ami nem futott ki
	jmp		.vege
.mindkifutottak:
	stc
.vege:
	ret
veglegesitIteraciotUtolsoErtekekAlapjan:
	movd	edi, xmm2
	test	edi, edi
	jz		.ezmarad1
	xor		al, al		; ha nem nulla, akkor 1 => teljesul a kovetelmeny =>  kisebb marad 2-nel => resze a halmaznak => nem szamit az iteracio, a szinkeplethez viszont le kell nullazni	
.ezmarad1:
	shufps	xmm2, xmm2, 0x39
	movd	edi, xmm2
	test	edi, edi
	jz		.ezmarad2
	xor		ah, ah
.ezmarad2:
	shufps	xmm2, xmm2, 0x39
	movd	edi, xmm2
	test	edi, edi
	jz		.ezmarad3
	xor		bl, bl
.ezmarad3:
	shufps	xmm2, xmm2, 0x39
	movd	edi, xmm2
	test	edi, edi
	jz		.ezmarad4
	xor		bh, bh
.ezmarad4:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Megfelel(xmm0, xmm1, esi)(esi) - xmm0: Re z1,  Re z4, xmm1: Im z, esi - iterationCount | esi: depth - hany lepes kell, hogy divergens legyen a sorozat
; fc(z) = z*z + c ahol z = a+ib => z*z = a*a-b*b +i2ab
Megfelel:
	push	eax		;al: elso szam iteracioja; ah : II
	push	ebx		;bl : III ; bh : IV
	push	ecx
	push	edx
	
	mov		ecx, esi		;ciklus szamlalo
	xor		eax, eax
	xor 	ebx, ebx
	xor		esi, esi
	
	; KONSTANSOK ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movaps	xmm6, xmm0		;kimentjuk a valos reszt
	movaps	xmm7, xmm1		;kimentjuk az imag. reszt
	
	mov		eax, [MANDEL_OR_JULIA]
	test	eax, eax
	jz		.mandel
	; JULIA ;
	movss	xmm6, [k_c_re]
		shufps	xmm6, xmm6, 0
	movss	xmm7, [k_c_im]
		shufps	xmm7, xmm7, 0
.mandel:
	xor		eax, eax
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; xmm0 - aktualis valos resz
	; xmm1 - aktualis imag. resz
.ciklus:
	movaps	xmm4, xmm0		;kimentjuk a valos reszt
	movaps	xmm5, xmm1		;kimentjuk az imag. reszt
	
	mulps	xmm0, xmm0		;a^2
	mulps	xmm1, xmm1		;b^2
	subps	xmm0, xmm1		;a^2 - b^2
	addps	xmm0, xmm6		; UJ VALOS RESZ
	
	mulps	xmm4, xmm5
		movss	xmm3, [k_2_0]
		shufps	xmm3, xmm3, 0x0
	mulps	xmm4, xmm3	;2ab
	addps	xmm4, xmm7
	movaps	xmm1, xmm4		; UJ IMAG. RESZ
	
	; kiszamituk: |z| ?<=? 2 ha nagyobb, akkor divergens, kifut
	movaps	xmm2, xmm0
	movaps	xmm3, xmm1
	
	mulps	xmm2, xmm2
	mulps	xmm3, xmm3
	addps	xmm2, xmm3
	sqrtps	xmm2, xmm2
	
	cmpps	xmm2, [k_2_vector], 2		; xmm2 <? 2
	
	; megvan a bitmaszk
	; xmm2 : 1111 0000 1111 0000 <=> elso < 2, masodik >= 2 ...
	cmp		ecx, 1
	je		.ide
	call	bitmaszFeldolgozas		;if carry => mind a 4 kifutott
	jc		.vege
	
	loop	.ciklus
	
.ide:
;.befejezCiklus:
	; push	ebx		;kinyer bh -> negyedik pixel kifutasa
	; and		ebx, 0xFFFF0000	; bh
	; cvtsi2ss	xmm3, ebx	; xmm3 := __ __ __ it_4
	; shufps	xmm3, xmm3, 0x930;xmm3 := __ __ it4 __
	; pop		ebx
	; and		ebx, 0x0000FFFF	; bl
	; cvtsi2ss	xmm4, ebx
	; addps	xmm3, xmm4		; xmm3 := __ __ it4 it3
	; shufps	xmm3, xmm3, 0x93; xmm3 := __ it4 it3 __
	; push	eax
	; and		eax, 0xFFFF0000	; ah
	; cvtsi2ss	xmm4, eax
	; addps	xmm3, xmm4		; xmm3 := __ it4 it3 it2
	; shufps	xmm3, xmm3, 0x93; xmm3 := it4 it3 it2 __
	; pop		eax
	; and		eax, 0x0000FFFF
	; cvtsi2ss	xmm4, eax
	; addps	xmm3, xmm4		; xmm3 := it4 it3 it2 it1
	; visszaadjuk esi-ben: 
	; eax : ... es ax 
	;				-> ah es al
	;		-> 				
	;=> z4 z3 z2 z1 iteraciok, little endian szerint
	; majd mov esi, eax
	call	veglegesitIteraciotUtolsoErtekekAlapjan
	
.vege:
	; cmp		al, 1
	; ja		.hagyjuk1
	; xor		al, al
; .hagyjuk1:
	; cmp		ah, 1
	; ja		.hagyjuk2
	; xor		al, al
; .hagyjuk2:
	; cmp		bl, 1
	; ja		.hagyjuk3
	; xor		bl, bl
; .hagyjuk3:
	; cmp		bh, 1
	; ja		.hagyjuk4
	; xor		bh, bh

; .hagyjuk4:
	shl		ebx, 16		; ebx := z4 z3 __ __
		and		eax, 0x0000FFFF
	or		eax, ebx
	mov		esi, eax	; KESZ!
	
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	movaps	xmm0, xmm6
	movaps	xmm1,xmm7	;visszaallitas
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;																	;;;;;;;;;;
;;;; valos resz: (dx-ResX/2) * leftValue / (ResX/2) ahol dx-oszlopindex ;;;;;;;;;;
;;;; imag. resz: (ResY/2-cx) * topValue  / (ResY/2)						;;;;;;;;;;
;;;;																	;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RealPart(xmm0)(xmm0) - xmm0-ben megkap 4 oszlopindexet; xmm0 -ban valos reszek
; xmm0 = f(edx) = (R-L) / ResX  * dx + L
RealPartVector:
	sub		esp, 16
	movdqu	[esp], xmm7
	sub		esp, 16
	movdqu	[esp], xmm1
	
	push	eax
	mov		eax, ResX
	cvtsi2ss	xmm7, eax
	pop		eax				; xmm7 := ResX
	
		shufps	xmm7, xmm7, 0x0	; broadcast vector; xmm7 := ResX ResX ResX ResX 
	movss	xmm1, [rightValue]
		shufps	xmm1, xmm1, 0x0	; broadcast vector
	movss	xmm2, [leftValue]
		shufps	xmm2, xmm2, 0x0	; broadcast vector
	subps	xmm1, xmm2		; (R-L)
	divps	xmm1, xmm7		; (R-L) / ResX 
	
	mulps	xmm1, xmm0		; (R-L) / ResX  * dx dx dx dx
	addps	xmm1, xmm2
	movaps	xmm0, xmm1		; itt a negy valos resz	
	
	movdqu	xmm1, [esp]
	add		esp, 16
	movdqu	xmm7, [esp]
	add		esp, 16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RealPart(edx)(xmm0) - edx-ben megkapja az oszlopindexet; xmm0 -ban valos resz
; xmm0 = f(edx) = (R-L) / ResX  * dx + L
RealPart:
	sub		esp, 16
	movdqu	[esp], xmm7
	
	push	eax
	mov		eax, ResX
	cvtsi2ss	xmm7, eax
	pop		eax				; xmm7 := ResX
	
	movss	xmm0, [rightValue]
	subss	xmm0, [leftValue]
	divss	xmm0, xmm7		; (R-L) / ResX
	cvtsi2ss	xmm7, edx
	mulss	xmm0, xmm7		; (R-L) / ResX  * dx
	addss	xmm0, [leftValue]
	
	movdqu	xmm7, [esp]
	add		esp, 16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ImaginaryPart(ecx)(xmm1) - ecx-ben megkapja a sorindexet; xmm1 -ban imag. resz
; xmm1 = f(ecx) = (B - T) / ResY  * cx + T
ImaginaryPart:
	sub		esp, 16
	movdqu	[esp], xmm7
	
	push	eax
	mov		eax, ResY
	cvtsi2ss	xmm7, eax	; xmm7 := ResY
	pop		eax
	
	movss	xmm1, [bottomValue]
	subss	xmm1, [topValue]
	divss	xmm1, xmm7		; (B - T) / ResY
	cvtsi2ss	xmm7, ecx
	mulss	xmm1, xmm7		; (B - T) / ResY  * cx
	addss	xmm1, [topValue]
	
	movdqu	xmm7, [esp]
	add		esp, 16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;MAIN;;MAIN;;MAIN;;MAIN;;MAIN;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:
	call	GET_USER_INFO
	; Create the graphics window
    mov		eax, ResX		; window ResX (X)
	mov		ebx, ResY		; window hieght (Y)
	mov		ecx, 0		; window mode (NOT fullscreen!)
	mov		edx, caption	; window caption
	call	gfx_init
	
	test	eax, eax		; if the return value is 0, something went wrong
	jnz		.init
	; Print error message and exit
	mov		eax, errormsg
	call	io_writestr
	call	io_writeln
	ret
	
.init:
	call	InitLimits
	
	;xor		ebx, ebx		; zoom - ratio
	xor		esi, esi		; deltax (used for moving the image)
	xor		edi, edi		; deltay (used for moving the image)
	
	; Main loop
.mainloop:
	; Draw something
	mov		dword [activity], 0
	call	gfx_map			; map the framebuffer -> EAX will contain the pointer
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; SET BORDER VALUES: leftValue, rightValue, ...
	movss	xmm0, [leftValue]
	movss	xmm1, [rightValue]
	movss	xmm2, [topValue]
	movss	xmm3, [bottomValue]
	;;;;;
	addss	xmm0, [offsetx]
	addss	xmm1, [offsetx]	; megprobalom hozzaadni az offset-et; ha LIMIT-en belul maradok, akkor ok; kulonben visszaallitom

	;comiss	xmm0, [LeftLimit]
	;jb		.xaxisOverflow
	;itt lehet jo lesz, meg meg kell viszgalni a jobb reszt
	;comiss	xmm1, [RightLimit]
	;ja		.xaxisOverflow
	;itt ez ok
	jmp		.xaxisOk
.xaxisOverflow:
	subss	xmm0, [offsetx]
	subss	xmm1, [offsetx]
	jmp		.doYAxis
.xaxisOk:
	movss	[leftValue], xmm0
	movss	[rightValue], xmm1
	;mov		dword [offsetx], 0
.doYAxis:
	;;;;;	ugyanez, csak Y tengelyre
	addss	xmm2, [offsety]
	addss	xmm3, [offsety]
	
	;comiss	xmm2, [TopLimit]
	;ja		.yaxisOverflow
	;itt lehet jo lesz, meg meg kell vizsgalni a bottom reszt
	;comiss	xmm3, [BottomLimit]
	;jb		.yaxisOverflow
	;itt ez is ok
	jmp		.yaxisOk
.yaxisOverflow:
	subss	xmm2, [offsety]
	subss	xmm3, [offsety]
	jmp		.doneWithAxess
.yaxisOk:
	movss	[topValue], xmm2
	movss	[bottomValue], xmm3
	;mov		dword [offsety], 0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.doneWithAxess:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;call	WriteBorderValues
	; Loop over the lines
	xor		ecx, ecx		; START FROM 0. line
.yloop:
	
	cmp		ecx, ResY
	jge		.yend	
	
	; Loop over the columns
	xor		edx, edx		; START FROM 0. col
.xloop:
	cmp		edx, ResX
	jge		.xend
	
	
	;;;;;;_ z = a + ib <-> (ecx, edx);;;;;;;;;
	; xmm0 - Re z
	; xmm1 - Im z
	; ResY ... bottomValue
	; ecx	 ... ?
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; aktualis pozicionak megfelelo komplex szam:
	; add		edx, 3
	; cvtsi2ss	xmm0, edx
		; shufps	xmm0, xmm0, 0x93	;to left   <---- xmm0 := __ __ a+3 __
	; dec		edx
	; cvtsi2ss	xmm2, edx
		; addps	xmm0, xmm2
		; shufps	xmm0, xmm0, 0x93	;to left   <---- xmm0 := __ a+3 a+2 __
	; dec		edx
	; cvtsi2ss	xmm2, edx
		; addps	xmm0, xmm2
		; shufps	xmm0, xmm0, 0x93	;to left   <---- xmm0 := a+3 a+2 a+1 __
	; dec		edx
	; cvtsi2ss	xmm2, edx
		; addps	xmm0, xmm2
	cvtsi2ss	xmm0, edx
	shufps	xmm0, xmm0, 0x0
	addps	xmm0, [k_make4real]
		
	call	RealPartVector		;xmm0 := valos resz edx szerint
	call	ImaginaryPart	;xmm1 := imag. resz ecx szerint
		shufps	xmm1, xmm1, 0x0
	
	;most (xmm0, xmm1) 4 komplex szamot tartalmaz, a megfelelo (ecx, edx) pixelnek 
	
		push	esi
		push	edi			; le kell oket menteni, mert az offset-et tartalmazzak
	mov		esi, [precision]
	call	Megfelel		;esi: sorozat-hossz, vagy -1, ha a pont Megfelel
	
	mov		ebx, esi	
		pop		edi
		pop		esi
	
	; ebx := kilepesi szam, (edi szerepe)
	push	ecx
	mov		ecx, 4
	
	push	edi
.megEgyPixel:
	push	ebx
	
	and		ebx, 0x000000FF		;nekem csak 1 iteraciot kell vizsgalnom, egy pixelre asszerint allitom be a szineket
	mov		edi, ebx			;mentes
.szin:
	;--RED--;
	imul	ebx, 10
	mov		[eax+2], bl
	
	mov		ebx, edi
	;--GREEN--;
	imul	ebx, ebx
	imul	ebx, 2
	mov		[eax+1], bl
	
	mov		ebx, edi
	;--BLUE--;
	imul	ebx, 12
	mov		[eax], bl
	
	; zero
	xor		ebx, ebx
	mov		[eax+3], bl

	add		eax, 4		    ; next pixel
	
	pop		ebx
	shr		ebx, 8
	loop	.megEgyPixel
	
	pop		edi
	pop		ecx
	add		edx, 4
	jmp		.xloop
.xend:
	inc		ecx
	jmp		.yloop
	
.yend:
	call	gfx_unmap		; unmap the framebuffer
	call	gfx_draw		; draw the contents of the framebuffer (*must* be called once in each iteration!)
	
	; Movement constants: 0 - none, -1: negative direction, 1: positive direction
	;xor		esi, esi
	;xor		edi, edi
	
	xor		ebx, ebx	; ebx := none
	mov		ecx, -1		; ecx := negative dir.
	mov		edx, 1		; edx := positive dir.
	
.eventloop:
	call	gfx_getevent	;get last event
	test	eax, eax
	jz		.noEventMark
.noEventMark:
	
	; Handle movement: keyboard
	cmp		eax, 'w'	; w key pressed
	cmove	edi, edx	; deltay = 1 (if equal)		<-> positive Oy dir, move towards top
	cmp		eax, -'w'	; w key released
	cmove	edi, ebx	; deltay = 0 (if equal)		<-> STOP
	cmp		eax, 's'	; s key pressed
	cmove	edi, ecx	; deltay = -1 (if equal)	<-> negative Oy dir, move towards bottom
	cmp		eax, -'s'	; s key released
	cmove	edi, ebx	; deltay = 0				<-> STOP
	cmp		eax, 'a'	; a key pressed
	cmove	esi, ecx	; deltax = -1				<-> negative Ox dir, move left
	cmp		eax, -'a'	; a key released
	cmove	esi, ebx	; deltax = 0				<-> STOP
	cmp		eax, 'd'	; d key pressed
	cmove	esi, edx	; deltax = 1				<-> positive Ox dir, move right
	cmp		eax, -'d'	; d key released
	cmove	esi, ebx	; deltax = 0				<-> STOP
	
	; Handle movement: mouse
	cmp		eax, 1			; left button pressed
	jne		.mousePossiblyReleased
	mov		dword [movemouse], 1
	call	gfx_getmouse
	mov		[prevmousex], eax
	mov		[prevmousey], ebx
	jmp		.eventloop

.mousePossiblyReleased:
	cmp		eax, -1			; left button released
	jne		.possibleZoomIn
	mov		dword [movemouse], 0
	jmp		.eventloop
.possibleZoomIn:
	cmp		eax, 4
	jne		.possibleZoomOut
	mov		dword [activity], 1
	mov		dword [activity_cooldown], 6
	; zoom in ->
	call	gfx_getmouse	; eax := x ; ebx := y
	mov		edx, eax		; edx := oszlop koord.
	mov		ecx, ebx		; ecx := sor koord.
	call	RealPart		; xmm0 := kurzornak megfelelo komplex szam valos resze
	call	ImaginaryPart	; xmm1 := -- = --
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; a jelenlegi koord. rendszer osszes pontjat el kell tolni egy olyan koord.
	; rendszerbe, melynek kozeppontja a kurzor 
	; majd zoom-tol fuggoen ezeket behuzzuk, vagy kitoljuk-ha ez lehetseges
	; vegul visszaallitjuk a koord. rendszert ugy, hogy kozeppontja a kepernyo kozeppontjaba essen
	; =>
	; v' = (v + kz) * zoomRatio - kz
	; ezt elvegezzuk a 4 szelsoertekre
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; movss	xmm7, [leftValue]	;imag. resz = 0
	; subss	xmm7, xmm0			; eltoljuk kurzo vektora szerint x-tengelyen
	; mulss	xmm7, [zoomIn]
	; addss	xmm7, xmm0			; visszaallit
	; movss	[leftValue], xmm7
	
	; movss	xmm7, [rightValue]
	; subss	xmm7, xmm0
	; mulss	xmm7, [zoomIn]
	; addss	xmm7, xmm0
	; movss	[rightValue], xmm7
	
	; movss	xmm7, [topValue]
	; subss	xmm7, xmm1
	; mulss	xmm7, [zoomIn]
	; addss	xmm7, xmm1
	; movss	[topValue], xmm7
	
	; movss	xmm7, [bottomValue]
	; subss	xmm7, xmm1
	; mulss	xmm7, [zoomIn]
	; addss	xmm7, xmm1
	; movss	[bottomValue], xmm7
	
	;VEKTOROS OPTIMALIZALAS:
	shufps	xmm0, xmm0, 0x0		; broadcast xmm0
	shufps	xmm1, xmm1, 0x0		; broadcast xmm1
	
	movaps	xmm7, [leftValue]	; xmm7 := B T R L
	subps	xmm7, xmm0
	mulps	xmm7, [zoomIn]
	addps	xmm7, xmm0			; xmm7 := __ __ R L
	shufps	xmm7, xmm7, 0x93	; xmm7 := __ R L __
	shufps	xmm7, xmm7, 0x93	; xmm7 := R L __ __
	
	movaps	xmm6, [leftValue]	; xmm6 := B T R L	
	subps	xmm6, xmm1
	mulps	xmm6, [zoomIn]
	addps	xmm6, xmm1			; xmm6 := B T __ __
	
	movhlps	xmm6, xmm7			; xmm6 := B T R L
	
	movaps	[leftValue], xmm6
	
	movss	xmm7, [k_tiny]
	mulss	xmm7, [zoomIn]
	movss	[k_tiny], xmm7
	; CHANGE ZOOM RATIO ;;;;;;;;;;;;;;;;;;;;;;;;
	; movss	xmm0, [zoomIn]
	; mulss	xmm0, [zoomInInc]
	; movss	[zoomIn], xmm0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.possibleZoomOut:
	cmp		eax, 5	
	jne		.possibleRestoreInitialZoom
	; zoom out ->
.doit_zoomOut:
	mov		dword [activity], 1
	mov		dword [activity_cooldown], 6
	call	gfx_getmouse	; eax := x ; ebx := y
	mov		edx, eax		; edx := oszlop koord.
	mov		ecx, ebx		; ecx := sor koord.
	call	RealPart		; xmm0 := kurzornak megfelelo komplex szam valos resze
	call	ImaginaryPart	; xmm1 := -- = --
	
	;movss	xmm7, [leftValue]	;imag. resz = 0
	;subss	xmm7, xmm0			; eltoljuk kurzo vektora szerint x-tengelyen
	;mulss	xmm7, [zoomOut]
	;addss	xmm7, xmm0			; visszaallit
	;;comiss	xmm7, [LeftLimit]	; ha az uj hatar kifutna, akkor no thanks :))
	;;jb		.skipThisZoomOut
	;
	;movss	xmm6, [rightValue]
	;subss	xmm6, xmm0
	;mulss	xmm6, [zoomOut]
	;addss	xmm6, xmm0
	;;comiss	xmm6, [RightLimit]
	;;ja		.skipThisZoomOut
	;
	;movss	xmm5, [topValue]
	;subss	xmm5, xmm1
	;mulss	xmm5, [zoomOut]
	;addss	xmm5, xmm1
	;;comiss	xmm5, [TopLimit]
	;;ja		.skipThisZoomOut
	;
	;movss	xmm4, [bottomValue]
	;subss	xmm4, xmm1
	;mulss	xmm4, [zoomOut]
	;addss	xmm4, xmm1
	;;comiss	xmm4, [BottomLimit]
	;;jb		.skipThisZoomOut
	;
	;movss	[leftValue], xmm7
	;movss	[rightValue], xmm6
	;movss	[topValue], xmm5
	;movss	[bottomValue], xmm4
	;VEKTOROS OPTIMALIZALAS:
	shufps	xmm0, xmm0, 0x0		; broadcast xmm0
	shufps	xmm1, xmm1, 0x0		; broadcast xmm1
	
	movaps	xmm7, [leftValue]	; xmm7 := B T R L
	subps	xmm7, xmm0
	mulps	xmm7, [zoomOut]
	addps	xmm7, xmm0			; xmm7 := __ __ R L
	shufps	xmm7, xmm7, 0x93	; xmm7 := __ R L __
	shufps	xmm7, xmm7, 0x93	; xmm7 := R L __ __
	
	movaps	xmm6, [leftValue]	; xmm6 := B T R L	
	subps	xmm6, xmm1
	mulps	xmm6, [zoomOut]
	addps	xmm6, xmm1			; xmm6 := B T __ __
	
	movhlps	xmm6, xmm7			; xmm6 := B T R L
	
	movaps	[leftValue], xmm6
	
	movss	xmm7, [k_tiny]
	mulss	xmm7, [zoomOut]
	movss	[k_tiny], xmm7
	; CHANGE ZOOM RATIO ;;;;;;;;;;;;;;;;;;;;;;;;
	; movss	xmm0, [zoomOut]
	; mulss	xmm0, [zoomOutDec]
	; movss	[zoomOut], xmm0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.skipThisZoomOut:
.possibleRestoreInitialZoom:
	cmp		eax, 'r'
	jne		.exitEvents
	; restore initial zoom
	;mov		esi, 42
	; igy jelzem a mainLoop - nak, hogy zoomOut kovetkezik eredeti allapotig
	;jmp		.doit_zoomOut
	
	; movss	xmm0, [LeftLimit]
	; movss	[leftValue], xmm0
	
	; movss	xmm0, [RightLimit]
	; movss	[rightValue], xmm0
	
	; movss	xmm0, [TopLimit]
	; movss	[topValue], xmm0
	
	; movss	xmm0, [BottomLimit]
	; movss	[bottomValue], xmm0
	;VEKTOROS OPTIMALIZALAS
	movaps	xmm0, [LeftLimit]
	movaps	[leftValue], xmm0
	movss	xmm0, [k_tiny_save]
	movss	[k_tiny], xmm0
.exitEvents:
	cmp		eax, 23			; the window close button was pressed: exit
	je		.end
	cmp		eax, 27			; ESC: exit
	je		.end
	test	eax, eax		; 0: no more events
	jnz		.eventloop
	
	; NO MORE EVENT ;
	
	; Query the mouse position if the left button IS pressed, and update the offset
	cmp		dword [movemouse], 0
	je		.updateoffset
	; now left button is still clicked, so moving the image
	call	gfx_getmouse	; EAX - x, EBX - y
		push	eax
		push	ebx
	mov		edx, eax
	call	RealPart
	mov		ecx, ebx	
	call	ImaginaryPart	; aktualis kurzor komplex szama

	movss	xmm2, xmm0
	movss	xmm3, xmm1
	
	mov		edx, [prevmousex]
	mov		ecx, [prevmousey]
	
	call	RealPart
	call	ImaginaryPart	; a lenyomas helyen levo komplex szam: xmm0 + xmm1 * i	
	
	subss	xmm2, xmm0
		mulss	xmm2, [k__1]
	subss	xmm3, xmm1		; eltolas vektor ; ezt adjuk hozza a 4 szelsoertekhez
		mulss	xmm3, [k__1]
	movss	[offsetx], xmm2
	movss	[offsety], xmm3
	
		pop		ebx
		pop		eax
	mov		[prevmousex], eax
	mov		[prevmousey], ebx
	
	jmp		.stopCalc
	; mov		ecx, eax
	; mov		edx, ebx		; ahol most a kurzor van
	; sub		eax, [prevmousex]
	; sub		ebx, [prevmousey] ; elmozdulas
	; cvtsi2ss	xmm0, eax
		; subss	xmm0, [offsetx]
		; mulss	xmm0, [k__1]
		; movss	[offsetx], xmm0	; offsetx -= eax
	; cvtsi2ss	xmm0, ebx
		; subss	xmm0, [offsety]
		; mulss	xmm0, [k__1]
		; movss	[offsety], xmm0
	; mov		[prevmousex], ecx
	; mov		[prevmousey], edx
	
.updateoffset:
	cmp		dword [movemouse], 0
	je		.noDragActivity
	mov		dword [activity], 1
	mov		dword [activity_cooldown], 6
.noDragActivity:
	cvtsi2ss	xmm0, esi
	mulss		xmm0, [k_tiny]	; -1 v. 0 v. 1 * e
	;addss	xmm0, [offsetx]
	movss	[offsetx], xmm0
	
	cvtsi2ss	xmm0, edi
	mulss		xmm0, [k_tiny]
	;addss	xmm0, [offsety]
	movss	[offsety], xmm0
	
.stopCalc:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; SPEC ANIMACIO: novekvo pontossag:
	; try this out 
.precisionControl:
	cmp		dword [activity_cooldown], 0
	je		.activityCooldownDone
	mov		dword [activity], 1
	dec		dword [activity_cooldown]
.activityCooldownDone:
	cmp		dword [activity], 0
	je		.precisionIdle
	mov		dword [precision], 20
	jmp		.enough
.precisionIdle:
	cmp		dword [precision], 100
	je		.enough
	inc		dword [precision]
.enough:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp 	.mainloop
    
	; Exit
.end:
	call	gfx_destroy
    ret
    
	
section .data
	;;__BASIC BACKGROUND CONSTANTS__;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	k__1		dd	-1.0
	k_2_0		dd	2.0
	k_little	dd	0.01
	
	precision	dd	20	;iteraciok szama
	
	; screen ratio : 1.777777..8
	; -left -> right: 5.68..9
	; 2.8444444445
	align 16
	LeftLimit	dd	-2.5
	RightLimit	dd	1.5	; dx = 4k
	TopLimit	dd	1.5
	BottomLimit	dd	-1.5	; dy = 3k	dy := 3/4 * dx
	; -2.5 1.5 1.5 -1.5 for 1280*1024 ;
	; These are used for moving the image
	offsetx 	dd	0.0
	offsety 	dd 	0.0
	movemouse 	dd 	0  ; bool (true while the left button is pressed)
	
	prevmousex 	dd 	0
	
	align 16
		zoomIn		dd	0.8, 0.8, 0.8, 0.8
		zoomOut		dd	1.25, 1.25, 1.25, 1.25
		
	prevmousey 	dd 	0
	
	
	zoomInInc	dd	0.9
	zoomOutDec	dd	1.1
	
	k_0			dd	0.0
	align 16
	k_1_vector	dd	1.0, 1.0, 1.0, 1.0
	k_2_vector	dd	2.0, 2.0, 2.0, 2.0
	k_0_vector	dd	0.0, 0.0, 0.0, 0.0
	
	align 16
	k_make4real	dd	0.0,1.0,2.0,3.0
	
	k_tiny		dd	0.1	
	k_tiny_save	dd	0.1
		
	k_little_save dd 0.01
	
	k_c_re		dd	-0.835
	k_c_im		dd	0.2321
	
	defaultRe1	dd	-0.835
	defaultIm1	dd	0.2321
	defaultRe2	dd	-0.70176
	defaultIm2	dd	-0.3842
	defaultRe3	dd	-0.8
	defaultIm3	dd	0.156
	
	;;__MESSAGES__;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	caption 	db 	"Mandelbrot Set", 0
	infomsg 	db 	"-> Use WASD and mouse (drag) to move the image", 10, 13, "-> Use mouse to zoom in/out", 10, 13, "-> Use r to reset", 0
	errormsg 	db 	"ERROR: could not initialize graphics!", 0

	vonal	db	'_', 0
	kerdes	db	"Mandelbrot or Julia set?", 10, 13, "Mandelbrot := 0 ; Julia := 1", 10, 13, "OPTION:", 0
	melyikJulia	db	"Built-in Julia fractals: 1, 2, 3", 10, 13, "OPTION:", 0
section .bss
	;;__COORDINATE-SYSTEM's 4 limit value__;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	align 16
	leftValue		resd	1
	rightValue		resd	1
	topValue		resd	1
	bottomValue		resd	1
	MANDEL_OR_JULIA resd	1
	activity		resd	1
	activity_cooldown resd	1