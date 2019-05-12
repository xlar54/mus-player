;==============================================================
; COMPUTE SID PLAYER - CRAIG CHAMBERLAIN
;
; Reconstrcuted for U64 by Scott Hutter - 4/17/2019
;
; load"this file",8,1
; sys 49152
;==============================================================

FAC1		= $61
IRQVECT 	= $0314
SID_BASE	= $D400
CIA1_BASE	= $DC00
VICII_BASE	= $D000	
CHROUT		= $FFD2
SETLFS		= $FFBA
SETNAM		= $FFBD
LOAD		= $FFD5
CLOSE		= $FFC3
STOP		= $FFE1
musicdata	= $4100
usedos		= 1

.if usedos == 0
filename 	= $4000
.fi


* = $0801                               ; BASIC start address (#2049) 
.byte $0d,$08,$dc,$07,$9e,$20           ; 2049 SYS
;.byte $34,$39,$31,$35,$32,$00,$00,$00   ; 49152
.byte $32,$30,$36,$32,$00,$00,$00		; 2062

; init interface
init:
		lda #$00
		sta VICII_BASE + $20
		sta VICII_BASE + $21
		
		; print screen
		ldy #$00
loop0:	lda inittxt,y
		cmp #$00
		beq printtitle
		jsr CHROUT
		iny
		jmp loop0
		
printtitle:
		ldy #$00
loop5:	lda filename,y
		cmp #$00
		beq printendtxt
		jsr CHROUT
		iny
		jmp loop5
		
printendtxt:
		ldy #$00
loop6:	lda endtxt,y
		cmp #$00
		beq playsong
		jsr CHROUT
		iny
		jmp loop6
		
playsong:
		; create irq handler
		jsr hook		

.if usedos == 1
		; set logical file params  (OPEN 1,8,0)
		lda #$01
		ldx #$08
		ldy #$00
		jsr SETLFS	
		
		; get filename length
		ldy #$00
loop1:	lda filename,y
		cmp #$00
		beq done1
		iny
		jmp loop1
done1:
		tya				; filename length
		ldx #<filename
		ldy #>filename
		jsr SETNAM		; SETNAM

		; load into RAM
		lda #$00
		ldx #<musicdata
		ldy #>musicdata
		jsr LOAD		; LOAD

		; close the file
		lda #$01
		jsr CLOSE
.fi


; prepare to play
		ldx #<musicdata
		ldy #>musicdata
		jsr set		; Setup routine

		; display file text
disptxt:
		stx $fb
		sty $fc
		ldy #$00
		lda #$0d
		jsr CHROUT
loop4	lda ($fb),y
		cmp #$00
		beq startplaying
		jsr CHROUT
		iny
		jmp loop4

		; start playing
startplaying:
		lda #$07
		sta data
		
		; quit if stop key is pressed
loop2:	jsr STOP
		bne loop2
		lda #$00
		sta data		; silence the voices
		jsr stopplaying
		jsr restore
quit:	lda #$05
		jsr CHROUT
		rts


		ldy #$00
hook:	lda #$00
		sta data
		ldx #$95
		ldy #$42
		lda $02a6
		beq Lc1e1
		ldx #$25
		ldy #$40
Lc1e1:	stx data + $15b
		sty data + $15c
		lda IRQVECT
		sta data + $15d
		lda IRQVECT+1
		sta data + $15e
		sei 
		lda #<newirq				; set up new IRQVECT
		sta IRQVECT
		lda #>newirq
		sta IRQVECT+1
		cli 
		rts

Lc200:		 
set:	lda #$00
		sta data
		stx FAC1
		sty FAC1 + 1
		ldy #$bc
Lc20b:	sta data,y
		dey 
		bne Lc20b
		ldy #$72
Lc213:	sta data + $bc,y
		dey 
		bne Lc213
		sta SID_BASE + $15
		sta SID_BASE + $16
		lda #$08
		sta data + $25
		sta SID_BASE + $17
		sta data + $26
		sta SID_BASE + $18
		lda #$90
		sta data + $27
		lda #$60
		sta data + $28
		lda #$0c
		sta data + $29
		lda data + $15b
		sta data + $2d
		lda data + $15c
		sta data + $2e
		lda #$ff
		sta data + $cc
		lda #$d4
		sta FAC1+3
		ldx #$02
Lc253:	lda #$ff
		sta data + $0b,x
		lda #$01
		sta data + $30,x
		sta data + $2a,x
		txa 
		sta data + $33,x
		sta data + $ae,x
		lda #$04
		sta data + $39,x
		lda data + $1a8,x
		sta data + $ba,x
		lda #$5b
		sta data + $7e,x
		lda data + $165,x
		sta FAC1+2
		lda #$00
		tay 
		sta (FAC1+2),y
		iny 
		sta (FAC1+2),y
		iny 
		sta (FAC1+2),y
		lda #$08
		sta data + $17,x
		sta data + $9c,x
		iny 
		sta (FAC1+2),y
		iny 
		sta (FAC1+2),y
		lda #$40
		sta data + $1a,x
		sta (FAC1+2),y
		lda #$20
		sta data + $1d,x
		iny 
		sta (FAC1+2),y
		lda #$f5
		sta data + $20,x
		iny 
		sta (FAC1+2),y
		dex 
		bpl Lc253
		txa 
		ldx #$17
Lc2b2:	sta data + $13e,x
		dex 
		bpl Lc2b2
		lda FAC1
		clc 
		adc #$06
		sta FAC1+2
		lda #$00
		tax 
		tay 
		adc FAC1+1
Lc2c5:	sta FAC1+3
		sta data + $ab,x
		sta data + $b4,x
		lda FAC1+2
		sta data + $a8,x
		sta data + $b1,x
		clc 
		adc (FAC1),y
		sta FAC1+2
		lda FAC1+3
		iny 
		adc (FAC1),y
		iny 
		inx 
		cpx #$03
		bne Lc2c5
		ldx FAC1+2
		tay 
		rts 

;$c2e9
stopplaying:
		lda #$00
		sta SID_BASE + $04
		sta SID_BASE + $0b
		sta SID_BASE + $12
		sta SID_BASE + $01
		sta SID_BASE + $08
		sta SID_BASE + $0f
		lda #$08
		sta SID_BASE + $17
		lda data + $15b
		sta CIA1_BASE + $04
		lda data + $15c
		sta CIA1_BASE + $05
		rts 

;$c30f
restore:
		sei 
		lda data + $15d
		sta IRQVECT
		lda data + $15e
		sta IRQVECT + 1
		cli 
		rts 

Lc31e:	lda #$08
		sta data
cback:	jmp (data + $15d)

newirq:
		lda CIA1_BASE + $0d		; new interrupt
		lda data
		bmi Lc31e
		ora #$80
		tay 
		and #$07
		beq cback
		cld 
		sty data
		cli 
		lda $fb
		sta data + $156
		lda $fc
		sta data + $157
		lda $fd
		sta data + $158
		lda $fe
		sta data + $159
		lda $ff
		sta data + $15a
		lda data + $23
		clc 
		adc data + $d9
		pha 
		and #$07
		tay 
		lda data + $dc
		adc #$00
		sta $ff
		pla 
		lsr $ff
		ror a
		lsr $ff
		ror a
		lsr $ff
		ror a
		clc 
		adc data + $24
		sty SID_BASE + $15
		sta SID_BASE + $16
		lda data + $25
		sta SID_BASE + $17
		lda data + $26
		sta SID_BASE + $18
		lda #$d4
		sta $fc
		ldx #$00
Lc38b:	lda data
		and data + $162,x
		beq Lc3e4
		lda data + $165,x
		sta $fb
		lda data + $0e,x
		clc 
		adc data + $51,x
		tay 
		lda data + $11,x
		adc data + $54,x
		pha 
		tya 
		clc 
		adc data + $cd,x
		ldy #$00
		sta ($fb),y
		pla 
		adc data + $d0,x
		iny 
		sta ($fb),y
		lda data + $14,x
		clc 
		adc data + $69,x
		sta $ff
		lda data + $17,x
		adc data + $6c,x
		pha 
		lda $ff
		clc 
		adc data + $d3,x
		iny 
		sta ($fb),y
		pla 
		adc data + $d6,x
		iny 
		sta ($fb),y
		lda data + $1d,x
		iny 
		iny 
		sta ($fb),y
		lda data + $20,x
		iny 
		sta ($fb),y
Lc3e4:	inx 
		cpx #$03
		bne Lc38b
		ldy data + $1a
		ldx data + $1b
		lda data + $1c
		sty SID_BASE + $04
		stx SID_BASE + $0b
		sta SID_BASE + $12
		ldx data + $2d
		ldy data + $2e
		stx CIA1_BASE + $04
		sty CIA1_BASE + $05
		lda SID_BASE + $1b
		sta data + $be
		lda SID_BASE + $1c
		sta data + $bf
		ldx #$00
Lc415:	lda data
		and data + $162,x
		beq Lc42d
		stx data + $2f
		jsr Lc536
		lda data
		and #$78
		beq Lc42d
		jmp Lc50c
Lc42d:	inx 
		cpx #$03
		bne Lc415
		lda data + $c9
		bne Lc489
		lda data + $ca
		ora data + $cb
		beq Lc4b7
		lda data + $df
		bne Lc46c
Lc444:	lda data + $ca
		beq Lc471
		clc 
		adc data + $bd
		bcs Lc456
		cmp data + $cc
		bcc Lc4b4
		beq Lc4b4
Lc456:	lda #$00
		sta data + $df
		lda data + $cb
		beq Lc4b4
		inc data + $df
		lda data + $bd
		sbc data + $cb
		jmp Lc4b4
Lc46c:	lda data + $cb
		beq Lc444
Lc471:	lda data + $bd
		sec 
		sbc data + $cb
		bcs Lc4b4
		lda #$00
		sta data + $df
		lda data + $ca
		bne Lc4b4
		inc data + $df
		bne Lc4b1
Lc489:	dec data + $e0
		bne Lc4b7
		lda data + $df
		bne Lc4a4
		inc data + $df
		lda data + $cb
		bne Lc49d
		lda #$20
Lc49d:	sta data + $e0
		lda #$00
		beq Lc4b4
Lc4a4:	dec data + $df
		lda data + $ca
		bne Lc4ae
		lda #$20
Lc4ae:	sta data + $e0
Lc4b1:	lda data + $cc
Lc4b4:	sta data + $bd
Lc4b7:	ldx #$00
Lc4b9:	lda data + $c3,x
		beq Lc502
		lda #$00
		sta $ff
		ldy data + $c0,x
		lda data + $bd,y
		ldy data + $c6,x
		beq Lc4db
		bmi Lc4d7
Lc4cf:	asl a
		rol $ff
		dey 
		bne Lc4cf
		beq Lc4db
Lc4d7:	lsr a
		iny 
		bne Lc4d7
Lc4db:	ldy data + $c3,x
		dey 
		bne Lc4ec
		sta data + $cd,x
		lda $ff
		sta data + $d0,x
		jmp Lc502
Lc4ec:	dey 
		bne Lc4fa
		sta data + $d3,x
		lda $ff
Lc4fa:	sta data + $d6,x
		jmp Lc502
		sta data + $d9
		lda $ff
		sta data + $dc
Lc502:	inx 
		cpx #$03
		bne Lc4b9
		lda data
		and #$7f
Lc50c:	sta data
		lda data + $156
		sta $fb
		lda data + $157
		sta $fc
		lda data + $158
		sta $fd
		lda data + $159
		sta $fe
		lda data + $15a
		sta $ff
		jmp (data + $15d)
Lc52b:	lda data + $60,x
		bne Lc533
		jmp Lc69f
Lc533:	jmp Lc5ba
Lc536:	dec data + $30,x
		bne Lc53e
		jmp Lc6a0
Lc53e:	lda data + $36,x
		bmi Lc52b
		bne Lc55f
		lda data + $3f,x
		beq Lc54f
		dec data + $3f,x
		bne Lc55f
Lc54f:	lda data + $39,x
		cmp data + $30,x
		bcc Lc55f
		lda data + $1a,x
		and #$fe
		sta data + $1a,x
Lc55f:	lda data + $42,x
		beq Lc5ba
		asl a
		lda data + $0e,x
		bcs Lc587
		adc data + $45,x
		sta data + $0e,x
		tay 
		lda data + $11,x
		adc data + $48,x
		sta data + $11,x
		pha 
		tya 
		cmp data + $8d,x
		pla 
		sbc data + $90,x
		bcs Lc5a4
		bcc Lc5b5
Lc587:	sbc data + $45,x
		sta data + $0e,x
		lda data + $11,x
		sbc data + $48,x
		sta data + $11,x
		lda data + $8d,x
		cmp data + $0e,x
		lda data + $90,x
		sbc data + $11,x
		bcc Lc5b5
Lc5a4:	lda data + $8d,x
		sta data + $0e,x
		lda data + $90,x
		sta data + $11,x
		lda #$00
		sta data + $42,x
Lc5b5:	lda data + $60,x
		beq Lc60f
Lc5ba:	lda data + $4b,x
		beq Lc60a
		ldy #$00
		dec data + $4e,x
		bne Lc5f7
		lda data + $51,x
		ora data + $54,x
		bne Lc5e9
		lda data + $5d,x
		sta data + $57,x
		sta data + $4e,x
		lda data + $4b,x
		asl a
		lda data + $5a,x
		bcc Lc5e4
		eor #$ff
		adc #$00
Lc5e4:	sta data + $4b,x
		bne Lc5f9
Lc5e9:	lda data + $57,x
		sta data + $4e,x
		tya 
		sec 
		sbc data + $4b,x
		sta data + $4b,x
Lc5f7:	cmp #$00
Lc5f9:	bpl Lc5fc
		dey 
Lc5fc:	clc 
		adc data + $51,x
		sta data + $51,x
		tya 
		adc data + $54,x
		sta data + $54,x
Lc60a:	lda data + $36,x
		bmi Lc624
Lc60f:	lda data + $93,x
		beq Lc624
		clc 
		adc data + $14,x
		sta data + $14,x
		lda data + $96,x
		adc data + $17,x
		sta data + $17,x
Lc624:	lda data + $63,x
		beq Lc674
		ldy #$00
		dec data + $66,x
		bne Lc661
		lda data + $69,x
		ora data + $6c,x
		bne Lc653
		lda data + $72,x
		sta data + $6f,x
		sta data + $66,x
		lda data + $63,x
		asl a
		lda data + $75,x
		bcc Lc64e
		eor #$ff
		adc #$00
Lc64e:	sta data + $63,x
		bne Lc663
Lc653:	lda data + $6f,x
		sta data + $66,x
		tya 
		sec 
		sbc data + $63,x
		sta data + $63,x
Lc661:	cmp #$00
Lc663:	bpl Lc666
		dey 
Lc666:	clc 
		adc data + $69,x
		sta data + $69,x
		tya 
		adc data + $6c,x
		sta data + $6c,x
Lc674:	lda data + $36,x
		bpl Lc67c
		jmp Lc69f
Lc67c:	ldy #$00
		lda data + $a2,x
		beq Lc69f
		bpl Lc686
		iny 
Lc686:	clc 
		adc data + $23
		pha 
		and #$07
		sta data + $23
		pla 
		ror a
		lsr a
		lsr a
		clc 
		adc data + $1a6,y
		clc 
		adc data + $24
		sta data + $24
Lc69f:	rts 

Lc6a0:	lda data + $a8,x
		sta $fd
		lda data + $ab,x
		sta $fe
		bne Lc6b0
Lc6ac:	rts 

Lc6ad:	jsr Lc898
Lc6b0:	lda data
		and data + $162,x
		beq Lc6ac
		ldy #$00
		lda ($fd),y
		sta $ff
		iny 
		lda ($fd),y
		tay 
		lda $fd
		clc 
		adc #$02
		sta $fd
		sta data + $a8,x
		lda $fe
		adc #$00
		sta $fe
		sta data + $ab,x
		lda $ff
		and #$03
		bne Lc6ad
		lda data + $8d,x
		sta data + $0e,x
		lda data + $90,x
		sta data + $11,x
		lda $ff
		sta data + $05,x
		tya 
		sta data + $02,x
		and #$07
		tay 
		lda data + $167,y
		sta data + $16f
		lda data + $02,x
		and #$38
		lsr a
		lsr a
		lsr a
		adc data + $81,x
		sta $fd
		lda data + $02,x
		and #$c0
		asl a
		rol a
		rol a
		tay 
		lda data + $16f,y
		sta $fe
		lda data + $02,x
		and #$07
		beq Lc77d
		tay 
		lda data + $172,y
		adc $fe
		clc 
		adc data + $84,x
		bpl Lc72c
		clc 
		adc #$0c
		inc $fd
Lc72c:	cmp #$0c
		bcc Lc734
		sbc #$0c
		dec $fd
Lc734:	sta $fe
		tay 
		lda data + $186,y
		sta $ff
		lda data + $17a,y
		ldy $fd
		dey 
		bmi Lc74a
Lc744:	lsr $ff
		ror a
		dey 
		bpl Lc744
Lc74a:	clc 
		adc data + $87,x
		sta data + $8d,x
		lda $ff
		adc data + $8a,x
		sta data + $90,x
		lda data + $05,x
		bne Lc761
		jmp Lc6a0
Lc761:	lda data + $45,x
		ora data + $48,x
		beq Lc77f
		lda data + $0e,x
		cmp data + $8d,x
		lda data + $11,x
		sbc data + $90,x
		lda #$fe
		ror a
		sta data + $42,x
		bcc Lc78e
Lc77d:	beq Lc7c9
Lc77f:	sta data + $42,x
		lda data + $8d,x
		sta data + $0e,x
		lda data + $90,x
		sta data + $11,x
Lc78e:	lda data + $36,x
		asl a
		bne Lc7c9
		lda data + $93,x
		beq Lc7a5
		lda data + $99,x
		sta data + $14,x
		lda data + $9c,x
		sta data + $17,x
Lc7a5:	lda data + $9f,x
		beq Lc7b9
		ldy $fd
		clc 
		adc data + $192,y
		ldy $fe
		clc 
		adc data + $19a,y
		clc 
		bcc Lc7c1
Lc7b9:	lda data + $a2,x
		beq Lc7c9
		lda data + $a5,x
Lc7c1:	sta data + $24
		lda #$00
		sta data + $23
Lc7c9:	lda data + $3c,x
		sta data + $3f,x
		lda data + $05,x
		and #$40
		sta data + $36,x
		lda data + $05,x
		lsr a
		lsr a
		and #$07
		bne Lc810
		lda data + $05,x
		bmi Lc7f9
		lda data + $27
		and #$3c
		bne Lc80a
		lda data + $27
		asl a
		rol a
		rol a
		bne Lc7f6
		lda #$04
Lc7f6:	jmp Lc870
Lc7f9:	lda data + $28
		beq Lc80a
		and #$3f
		bne Lc80a
		lda data + $28
		asl a
		rol a
		rol a
		bne Lc870
Lc80a:	lda #$10
		sta data
		rts

Lc810:	cmp #$01
		bne Lc827
		lda data + $05,x
		and #$20
		bne Lc821
		lda data + $29
		jmp Lc870
Lc821:	lda data + $2a,x
		jmp Lc870
Lc827:	tay 
		lda data + $05,x
		and #$a0
		cmp #$80
		beq Lc861
		sta $ff
		clc 
		lda data + $27
		bne Lc83a
		sec 
Lc83a:	dey 
		dey 
		beq Lc844
Lc83e:	ror a
		bcs Lc88f
		dey 
		bne Lc83e
Lc844:	ldy $ff
		sta $ff
		beq Lc870
		lsr $ff
		bcs Lc88f
		beq Lc892
		adc $ff
		bcs Lc892
		iny 
		bpl Lc870
		lsr $ff
		bcs Lc88f
		adc $ff
		bcc Lc870
		bcs Lc892
Lc861:	lda data + $28
		beq Lc88f
		dey 
		dey 
		beq Lc870
Lc86a:	lsr a
		bcs Lc88f
		dey 
		bne Lc86a
Lc870:	sta data + $30,x
		lda data + $1a,x
		and #$f6
		sta data + $1a,x
		sec 
		lda data + $02,x
		and #$07
		bne Lc886
		ror data + $36,x
Lc886:	lda data + $1a,x
		adc #$00
		sta data + $1a,x
		rts 

Lc88f:	lda #$10
		.byte $2C
Lc892:	lda #$18
		sta data
		rts

Lc898:	tya 
		pha 
		lda $ff
		lsr a
		bcc Lc8a2
		jmp Lca42
Lc8a2:	lsr a
		lsr a
		bcs Lc8c4
		lsr a
		bcs Lc8b7
		sta data + $9c,x
		sta data + $17,x
		pla 
		sta data + $99,x
		sta data + $14,x
		rts 

Lc8b7:	lsr a
		bcc Lc8bc
		ora #$f8
Lc8bc:	sta data + $8a,x
		pla 
		sta data + $87,x
		rts 

Lc8c4:	lsr a
		bcs Lc8ca
		jmp Lc94a
Lc8ca:	lsr a
		bcs Lc92e
		lsr a
		bcs Lc8df
		bne Lc8da
		pla 
		sta data + $a5,x
		sta data + $24
		rts 

Lc8da:	pla 
		sta data + $3c,x
		rts 

Lc8df:	bne Lc929
		pla 
		sta data + $7e,x
		cmp #$5b
		beq Lc91c
		tay 
		lsr a
		lsr a
		lsr a
		sec 
		sbc #$0b
		clc 
		adc data + $84,x
		bmi Lc902
		cmp #$0c
		bcc Lc90b
		sbc #$0c
		dec data + $81,x
		jmp Lc90b
Lc902:	cmp #$f5
		bcs Lc90b
		adc #$0c
		inc data + $81,x
Lc90b:	sta data + $84,x
		tya 
		and #$07
		sec 
		sbc #$03
		clc 
		adc data + $81,x
		sta data + $81,x
		rts 

Lc91c:	lda data + $78,x
		sta data + $81,x
		lda data + $7b,x
		sta data + $84,x
		rts 

Lc929:	pla 
		sta data + $c6,x
		rts 

Lc92e:	lsr a
		bcs Lc939
		sta data + $0b,x
		pla 
		sta data + $08,x
		rts 

Lc939:	lsr a
		ror a
		ror a
		adc data + $15b
		sta data + $2d
		pla 
		adc data + $15c
		sta data + $2e
		rts 

Lc94a:	lsr a
		bcc Lc950
		jmp Lc9d3
Lc950:	lsr a
		bcs Lc993
		lsr a
		bcs Lc96d
		lsr a
		bcs Lc968
		pla 
		sta data + $27
		lsr a
		lsr a
		lsr a
		tay 
		lda data + $1af,y
		sta data + $28
		rts 

Lc968:
		pla 
		sta data + $5d,x
		rts

Lc96d:
		lsr a
		bcs Lc975
		pla 
		sta data + $01
		rts 

Lc975:	pla 
		beq Lc989
		sta data + $75,x
		ldy data + $63,x
		bne Lc988
		sta data + $63,x
		lda #$01
		sta data + $66,x
Lc988:	rts 

Lc989:	sta data + $63,x
		sta data + $69,x
		sta data + $6c,x
		rts 

Lc993:	lsr a
		bcs Lc9c6
		lsr a
		bcs Lc99e
		pla 
		sta data + $39,x
		rts 

Lc99e:	pla 
		ldy #$00
		lsr a
		bcc Lc9a6
		iny 
		clc 
Lc9a6:	pha 
		and #$07
		adc data + $1ac,y
		sta data + $78,x
		sta data + $81,x
		pla 
		lsr a
		lsr a
		lsr a
		clc 
		adc data + $1ad,y
		sta data + $7b,x
		sta data + $84,x
		lda #$5b
		sta data + $7e,x
		rts 

Lc9c6:	lsr a
		bcs Lc9ce
		pla 
		sta data + $a2,x
		rts 

Lc9ce:	pla 
		sta data + $cc
		rts 

Lc9d3:	lsr a
		bcs Lc9fd
		lsr a
		bcs Lc9e6
		lsr a
		bcs Lc9e1
		pla 
		sta data + $29
		rts 

Lc9e1:	pla 
		sta data + $9f,x
		rts 

Lc9e6:	lsr a
		bcs Lc9f8
		pla 
		sta data + $93,x
		ldy #$00
		asl a
		bcc Lc9f3
		dey 
Lc9f3:	tya 
		sta data + $96,x
		rts 

Lc9f8:	pla 
		sta data + $72,x
		rts 

Lc9fd:	lsr a
		bcs Lca1c
		lsr a
		bcs Lca18
		pla 
		sta data + $b7,x
		lda $fd
		sta data + $b1,x
		lda $fe
		sta data + $b4,x
		lda data + $33,x
		sta data + $ae,x
		rts 

Lca18:	pla 
		jmp (data + $15f)
Lca1c:	lsr a
		bcs Lca3d
		pla 
		bne Lca2c
		sta data + $4b,x
		sta data + $51,x
		sta data + $54,x
		rts 

Lca2c:	sta data + $5a,x
		ldy data + $4b,x
		bne Lca3c
		sta data + $4b,x
		lda #$01
		sta data + $4e,x
Lca3c:	rts 

Lca3d:	pla 
		sta data + $2a,x
		rts 

Lca42:	lsr a
		bcc Lca4d
		sta data + $48,x
		pla 
		sta data + $45,x
		rts 

Lca4d:	pla 
		lsr a
		bcs Lcab2
		lsr a
		bcs Lca79
		lsr a
		bcs Lca5c
		lsr a
		ldy #$f0
		bne Lca62
Lca5c:	asl a
		asl a
		asl a
		asl a
		ldy #$0f
Lca62:	sta $ff
		tya 
		bcs Lca70
		and data + $1d,x
		ora $ff
		sta data + $1d,x
		rts 

Lca70:	and data + $20,x
		ora $ff
		sta data + $20,x
		rts 

Lca79:	lsr a
		bcs Lcab4
		lsr a
		bcs Lcae3
Lca7f:	sta $ff
		lda data + $ba,x
		cmp data + $a9,x
		beq Lcadd
		inc data + $ba,x
		tay 
		lda $fd
		sta data + $e1,y
		lda $fe
		sta data + $f0,y
		lda data + $33,x
		sta data + $12f,y
		ldy $ff
		lda data + $117,y
		beq Lcada
		sta $fe
		lda data + $ff,y
		sta $fd
		lda data + $13e,y
		sta data + $33,x
		rts 

Lcab2:	bcs Lcaff
Lcab4:	lsr a
		bcs Lcaf3
Lcab7:	tay 
		lda $fd
		sta data + $ff,y
		lda $fe
		sta data + $117,y
		lda data + $33,x
		sta data + $13e,y
		lda data + $ba,x
		cmp data + $1a9,x
		beq Lcadd
		inc data + $ba,x
		tay 
		lda #$00
		sta data + $f0,y
		rts 

Lcada:	lda #$30
		.byte $2C
Lcadd:	lda #$28
		sta data
		rts 

Lcae3:	asl a
		asl a
		asl a
		asl a
		eor data + $25
		and #$f0
		eor data + $25
		sta data + $25
		rts 

Lcaf3:	eor data + $26
		and #$0f
		eor data + $26
		sta data + $26
		rts 

Lcaff:	lsr a
		bcs Lcb0d
		lsr a
		bcs Lcb09
		sta data + $ca
		rts 

Lcb09:	sta data + $cb
		rts 

Lcb0d:
		lsr a
		bcc Lcb13
		jmp Lcba5
Lcb13:	lsr a
		tay 
		beq Lcb38
		dey 
		beq Lcb4e
		dey 
		beq Lcb5f
		dey 
		beq Lcb6a
		dey 
		beq Lcb75
		dey 
		beq Lcb82
		dey 
		beq Lcb8f
		dey 
		beq Lcb9f
		and #$07
		ora #$10
		bcs Lcb35
		jmp Lcab7
Lcb35:	jmp Lca7f
Lcb38:	ldy data + $26
		bcs Lcb44
		iny 
		tya 
		and #$0f
		bne Lcb4a
		rts 

Lcb44:	tya 
		and #$0f
		beq Lcb4d
		dey 
Lcb4a:	sty data + $26
Lcb4d:	rts 

Lcb4e:	lda data + $162,x
		eor #$ff
		and data + $25
		bcc Lcb5b
		ora data + $162,x
Lcb5b:	sta data + $25
		rts 

Lcb5f:	lda data + $1a,x
		and #$fb
		bcc Lcbbb
		ora #$04
		bcs Lcbbb
Lcb6a:	lda data + $1a,x
		and #$fd
		bcc Lcbbb
		ora #$02
		bcs Lcbbb
Lcb75:	lda data + $25
		and #$f7
		bcc Lcb7e
		ora #$08
Lcb7e:	sta data + $25
		rts 

Lcb82:	lda data + $26
		and #$7f
		bcc Lcb8b
		ora #$80
Lcb8b:	sta data + $26
		rts 

Lcb8f:	tya 
		sta data + $bd
		sta data + $df
		iny 
		sty data + $e0
		rol a
		sta data + $c9
		rts 

Lcb9f:	tya 
		rol a
		sta data + $60,x
		rts 

Lcba5:	lsr a
		bcs Lcbcf
		lsr a
		bcs Lcbbf
		bne Lcbaf
		lda #$08
Lcbaf:	asl a
		asl a
		asl a
		asl a
		eor data + $1a,x
		and #$f0
		eor data + $1a,x
Lcbbb:	sta data + $1a,x
		rts 

Lcbbf:	asl a
		asl a
		asl a
		asl a
		eor data + $26
		and #$70
		eor data + $26
		sta data + $26
		rts 

Lcbcf:	lsr a
		bcc Lcbd6
		sta data + $c0,x
		rts 

Lcbd6:	tay 
		beq Lcbf9
		dey 
		beq Lcc1c
		dey 
		beq Lcc42
		and #$03
		sta data + $c3,x
		lda #$00
		sta data + $cd,x
		sta data + $d0,x
		sta data + $d3,x
		sta data + $d6,x
		sta data + $d9
		sta data + $dc
		rts 

Lcbf9:	lda data + $b7,x
		beq Lcc03
		dec data + $b7,x
		beq Lcc15
Lcc03:	lda data + $33,x
		cmp data + $ae,x
		bne Lcc16
		lda data + $b1,x
		sta $fd
		lda data + $b4,x
		sta $fe
Lcc15:	rts 

Lcc16:	lda #$38
		sta data
		rts 

Lcc1c:	lda data + $ba,x
		cmp data + $1a8,x
		beq Lcc3c
		dec data + $ba,x
		tay 
		dey 
		lda data + $f0,y
		beq Lcc3b
		sta $fe
		lda data + $e1,y
		sta $fd
		lda data + $12f,y
		sta data + $33,x
Lcc3b:	rts 

Lcc3c:	lda #$20
		sta data
		rts 

Lcc42:	lda data
		eor data + $162,x
		sta data
		lda #$01
		sta data + $30,x
		rts 


inittxt:
		.byte $93
		.text $05, $14, "  *** the ultimate c-64 mus player ***", $0D
		.fill 40, $C3
		.byte $0D
		.text $9E, "title :",$9B, " ", $00

endtxt:
		.byte $0D, $90
		.byte $00

.if usedos == 1
filename:
		.text "footloose.mus"
		.byte 0
.fi

data:
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $61
.byte $c1, $60, $01, $02, $04, $00, $07, $0e, $02, $02, $fe, $02, $02, $fe, $fe, $00
.byte $01, $00, $ff, $00, $02, $04, $05, $07, $09, $0b, $1e, $18, $8b, $7e, $fa, $06
.byte $ac, $f3, $e6, $8f, $f8, $2e, $86, $8e, $96, $9f, $a8, $b3, $bd, $c8, $d4, $e1
.byte $ee, $fd, $8c, $78, $64, $50, $3c, $28, $14, $00, $00, $02, $03, $05, $07, $08
.byte $0a, $0c, $0d, $0f, $11, $12, $00, $e0, $00, $05, $0a, $0f, $f9, $00, $f5, $00
.byte $00, $00, $10, $00, $00, $20, $00, $00, $30, $00, $00, $40, $00, $00, $50, $00
.byte $00, $60, $00, $00, $70, $00, $00, $80, $00, $00, $90, $00, $00