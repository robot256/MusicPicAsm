;   This file is a basic code template for assembly code generation   *
;   on the PIC16F819. This file contains the basic code               *
;   building blocks to build upon.                                    *
;                                                                     *
;   If interrupts are not used all code presented between the ORG     *
;   0x004 directive and the label main can be removed. In addition    *
;   the variable assignments for 'w_temp' and 'status_temp' can       *
;   be removed.                                                       *
;                                                                     *
;   Refer to the MPASM User's Guide for additional information on     *
;   features of the assembler (Document DS33014).                     *
;                                                                     *
;   Refer to the respective PIC data sheet for additional            *
;   information on the instruction set.                               *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Filename:	    xxx.asm                                           *
;    Date:                                                            *
;    File Version:                                                    *
;                                                                     *
;    Author:                                                          *
;    Company:                                                         *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;                                                                     *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;                                                                     *
;                                                                     *
;                                                                     *
;**********************************************************************

	list      p=16f819           ; list directive to define processor
	#include <p16F819.inc>        ; processor specific variable definitions

	errorlevel  -302              ; suppress message 302 from list file

	__CONFIG   _CP_OFF & _WRT_ENABLE_OFF & _CPD_OFF & _CCP1_RB2 & _DEBUG_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _WDT_OFF & _PWRTE_ON & _HS_OSC 

; '__CONFIG' directive is used to embed configuration word within .asm file.
; The lables following the directive are located in the respective .inc file.
; See data sheet for additional information on configuration word settings.



;***** VARIABLE DEFINITIONS

	CBLOCK	0x20
	freq0
	freq1
	freq2
	freq3
	
	cntr0
	cntr1
	cntr2
	cntr3
	
	state		; bytecode interpreter state variable
	counter		; TMR0 overflows until next eeprom read
	interval	; TMR0 reset value
	temp		; current eeprom byte to decode
	
	ENDC
	
	CBLOCK	0x70
	
	flags		; bit 0 - indicates current byte is "interval" value
	
	ENDC




;**********************************************************************
	ORG     0x000             ; processor reset vector
	goto    main              ; go to beginning of program
	
	
	
	ORG 0x005
main

; Initialization code
	clrf	PORTA
	clrf	PORTB
	
	clrf	INTCON
	
	banksel TRISA
	movlw	0x00
	movwf	TRISA
	movlw	0x0F
	movwf	TRISB
	movlw	0x06
	movwf	ADCON1
	movlw	0x86		; 1:128 prescaler
	movwf	OPTION_REG
	
	banksel	PORTA
	
	clrf	T1CON
	clrf	T2CON
	clrf	CCP1CON
	clrf	SSPCON
	clrf	ADCON0
	
	; Set up eeprom
	banksel	EEADR
	clrf	EEADR
	clrf	EECON1
	banksel PORTA

	; Set up data table
	clrf	PCLATH
	
	; Set up control registers
	clrf	state
	clrf	flags
	movlw	0x01
	movwf	counter
	movlw	freq0
	movwf	FSR
	
	clrf	interval
	movlw	0xFF
	movwf	TMR0
	
	; Set up frequency registers
	clrf	freq0
	clrf	freq1
	clrf	freq2
	clrf	freq3	
	; Load all the frequency counters
	clrf	cntr0
	clrf	cntr1
	clrf	cntr2
	clrf	cntr3
	
	
	
	
		
	
	


mainloop:

	; Run the sounds
	; NOTE:  cntr0H is actuall +1 its normal value due to this logic
	decfsz	cntr0,f
	goto	_cntr0wait1
	; Counter expired, reload counter and toggle output pin
	movf	freq0,w
	movwf	cntr0
	movlw	0x01
	xorwf	PORTB,f
_cntr0done
	
	decfsz	cntr1,f
	goto	_cntr1wait1
	; Counter expired, reload counter and toggle output pin
	movf	freq1,w
	movwf	cntr1
	movlw	0x02
	xorwf	PORTB,f
_cntr1done

	decfsz	cntr2,f
	goto	_cntr2wait1
	; Counter expired, reload counter and toggle output pin
	movf	freq2,w
	movwf	cntr2
	movlw	0x04
	xorwf	PORTB,f
_cntr2done

	decfsz	cntr3,f
	goto	_cntr3wait1
	; Counter expired, reload counter and toggle output pin
	movf	freq3,w
	movwf	cntr3
	movlw	0x08
	xorwf	PORTB,f
_cntr3done



	; Decoding state machine
	movf	state,w
	addwf	PCL,f
	goto	State0
	goto	State1
	goto	State2
	goto	State3
	goto	State4
	goto	State5
	
	
	
freq_table:
	addwf	PCL,f
	; Starts on the second B flat below middle C
	; Ends (awfully) on the fourth C above middle C
	DT		0x00,d'249',d'235',d'222',d'210',d'198',d'187',d'176'
	DT		d'166',d'157',d'148',d'140',d'132',d'125',d'118',d'111'
	DT		d'105',d'99',d'93',d'88',d'83',d'79',d'74',d'70'
	DT		d'66',d'62',d'59',d'56',d'52',d'49',d'47',d'44'
	DT		d'42',d'39',d'37',d'35',d'33',d'31',d'29',d'28'
	DT		d'26',d'25',d'23',d'22',d'21',d'20',d'19',d'17'
	DT		d'17',d'16',d'15',d'14',d'13',d'12',d'12',d'11'
	DT		d'10',d'10',d'9',d'9',d'8',d'8',d'7',d'7'
	

	
	
State0:
	; Waiting for timer to finish
	movlw	freq0			; reset channel flag
	movwf	FSR				;   for next read
	btfss	INTCON,TMR0IF
	goto	_s0_wait		; timer not finished
	; timer finished
	movf	interval,w		; reload TMR0
	movwf	TMR0
	bcf		INTCON,TMR0IF	; clear timer flag
	decf	counter,f		; decrement counter
	btfsc	STATUS,Z		; check if counter = 0
	incf	state,f			; counter = 0, goto state1
	nop
	nop
	goto	mainloop		; 12 inst
_s0_wait
	call	nop_wait7
	goto	mainloop		; 7 inst
	
	
State1:
	; We are at the end of a counter period
	; Retrieve the next eeprom byte
	bsf		STATUS,RP0
	bsf		STATUS,RP1
	bsf		EECON1,RD
	bcf		STATUS,RP0
	movf	EEADR,f
	btfsc	STATUS,Z		; check if this is address 0
	bsf		flags,0			; set flag for interval decoding
	movf	EEDATA,w
	incf	EEADR,f			; increment to next eeprom byte
	bcf		STATUS,RP1
	movwf	temp			; store byte in temp
	incf	state,f
	goto	mainloop		; 14 inst
	
	
State2:
	; Choose which type to decode
	; check if it's an interval byte
	btfss	flags,0
	goto	_s2_ch1
	; it is an interval
	movf	temp,w
	movwf	interval
	bcf		flags,0
	movlw	0x01
	movwf	state
	call	nop_wait5
	goto	mainloop		; 9 inst
	
_s2_ch1
	; check if it is a counter
	btfsc	temp,7
	goto	_s2_ch2
	movf	temp,w			; it is a counter
	btfss	STATUS,Z
	goto	_s2_ch1_done
	bsf		STATUS,RP1		; it is a repeat command
	clrf	EEADR
	bcf		STATUS,RP1
	decf	state,f			; set address to 0, then read next eeprom byte
	goto	mainloop		; 14 inst
_s2_ch1_done
	movwf	counter			; store new counter
	clrf	state			; wait for counter to elapse
	nop
	goto	mainloop		; 13 inst
	
_s2_ch2
	; check if it is a flag command
	btfss	temp,6
	goto	_s2_ch3
	incf	state,f		; on/off command
	btfsc	temp,5	
	incf	state,f		; volume command
	nop
	goto	mainloop		; 13 inst
	
_s2_ch3
	; it is a tone command
	movlw	0x05
	movwf	state
	nop
	goto	mainloop		; 13 inst
	
	
State3:
	; Decode on/off command
	comf	temp,w		; encoded '1' enables channel
	andlw	0x0F
	bsf		STATUS,RP0
	movwf	TRISB
	bcf		STATUS,RP0
	movlw	0x01
	movwf	state
	call	nop_wait5
	goto	mainloop		; 9 inst


State4:
	; Decode volume command
	movlw	0x0F
	andwf	PORTB,f
	swapf	temp,w
	andlw	0xF0
	iorwf	PORTB,f
	movlw	0x01
	movwf	state
	call	nop_wait5
	goto	mainloop		; 9 inst


State5:
	; Decode tone command
	; look up tone byte
	movf	temp,w
	andlw	0x3F
	call	freq_table		; 6 inst
	movwf	INDF
	incf	FSR,f
	movlw	0x01
	movwf	state
	goto	mainloop		; 14 inst



_cntr0wait1
	nop
	goto	_cntr0done

_cntr1wait1
	nop
	goto	_cntr1done
	
_cntr2wait1
	nop
	goto	_cntr2done

_cntr3wait1
	nop
	goto	_cntr3done
	
	
nop_wait7:
	nop
	nop
nop_wait5:
	nop
	return




;*****************************
; Stores music notes
; Format:
;   Set Tempo Interval:  0x00
;   Set Delay counter (end of note):  	0b0xxxxxxx
;   Set Tone (sequential channel):  	0b10xxxxxx
;   Set On/Off states:					0b110-xxxx
;   Set Volume states:					0b111-xxxx


	ORG	0x2100

; middle C scale
;	DE	0x80,0x80,0x7F
;	DE	0x8F,0x8F,0x40
;	DE	0x91,0x8E,0x20
;	DE	0x93,0x8F,0x20
;	DE	0x94,0x91,0x20
;	DE	0x96,0x93,0x20
;	DE	0x98,0x94,0x20
;	DE	0x9A,0x96,0x20
;	DE	0x9B,0x98,0x7F
;	DE	0x00

; 0x10 = 32nd note
; 0x20 = 16th note
; 0x40 = 8th note
; 0x7F = 1/4 note
; 0x2A = 1/4 note triplet

#ifndef NOTME

	DE	0x20		; tempo

	DE	0xC0,0x40	; silence
	DE	0x7F
	
	; bar 1
	DE	0x94,0xC1,0x20
	DE	0xC0,0x0A
	DE	0xC1,0x20
	DE	0xC0,0x0A
	DE	0xC1,0x20
	DE	0xC0,0x0A
	
	; bar 2
	DE	0x99,0xC1,0x60
	DE	0x99,0x8D,0x88,0xC7,0xEE,0x08
	DE	0xC1,0x08
	DE	0xC7,0x08
	DE	0xC1,0x08
	DE	0xC7,0x7F
	DE	0xA0,0x20
	DE	0xC1,0x20
	DE	0xC7,0x18
	DE	0xC1,0x08
	DE	0xC7,0x08
	DE	0xC1,0x08
	DE	0xC7,0x08
	DE	0xC1,0x08
	DE	0xC7,0x40
	DE	0xA0,0x8B,0x86,0x8D,0xCF,0x40
	
	; bar 3
	DE	0x9E,0xC1,0x2A
	DE	0x9D,0x16
	DE	0xCF,0x0F
	DE	0x9B,0x2B
	DE	0xA5,0x91,0xC1,0x40
	DE	0xCF,0x38
	DE	0xC1,0x08
	DE	0xCF,0x28
	DE	0xC1,0x08
	DE	0xCF,0x08
	DE	0xC1,0x08
	DE	0xCF,0x18
	DE	0xC1,0x08
	DE	0xCF,0x18
	DE	0xC1,0x08
	DE	0xA0,0x88,0xCB,0x20
	DE	0xC1,0x0A
	DE	0xCB,0x20
	DE	0xC1,0x0A
	DE	0xCB,0x20
	DE	0xC1,0x0A
	
	; bar 4
	DE	0x9E,0x2A
	DE	0x9D,0x16
	DE	0x9D,0x8B,0xCF,0x0F
	DE	0x9B,0x2B
	DE	0xA5,0x91,0xC1,0x40
	DE	0xCF,0x38
	DE	0xC1,0x08
	DE	0xCF,0x28
	DE	0xC1,0x08
	DE	0xCF,0x08
	DE	0xC1,0x08
	DE	0xCF,0x18
	DE	0xC1,0x08
	DE	0xCF,0x18
	DE	0xC1,0x08
	DE	0xA0,0x88,0xCB,0x20
	DE	0xC1,0x0A
	DE	0xCB,0x20
	DE	0xC1,0x0A
	DE	0xCB,0x20
	DE	0xC1,0x0A
		
	; bar 5
	DE	0x9E,0x92,0x8F,0x8B,0xCF,0x2A
	DE	0x9D,0x91,0x8D,0x8A,0x2A
	DE	0x9E,0x92,0x8F,0x8B,0x2A
	DE	0x9B,0x8F,0x8C,0x88,0x7F
	DE	0x40
	
	DE	0x00


	
	
#endif

#ifdef NOTME

; Fanfare from mahler's 1st symphony
; 0x10 = 32nd note
; 0x20 = 16th note
; 0x40 = 8th note
; 0x7F = 1/4 note
; 0x2A = 1/4 note triplet
	DE	0x54					; tempo
	
	DE	0x80,0x80,0x80,0x7F		; initial pause
	DE	0xDF,0x98,0x7F			; E+G, .25
	DE	0x7F					; E+G, .25
	DE	0x50					; E+G, short dotted 1/8th note
	DE	0x80,0x80,0x10			; internote gap
	DE	0xDF,0x98,0x08			; E+G, 32nd note
	DE	0x80,0x80,0x08			; internote gap
	DE	0xDF,0x98,0x08			; E+G 32nd note
	DE	0x80,0x80,0x08			; internote gap
	DE	0xDF,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C			; internote gap
	DE	0xDF,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C			; internote gap
	DE	0xDF,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C			; internote gap
	DE	0xDF,0x98,0x50			; E+G dotted eigth
	DE	0x98,0xD8,0xDF,0x08		; E+G+G 32nd (swap voices 1 and 3)
	DE	0x80,0x08		; internote lower
	DE	0x98,0x08		; E+G+G 32nd
	DE	0x80,0x08		; internote lower
	DE	0x98,0x20		; E+G+G triplet
	DE	0x80,0x0C		; E+G triplet internote
	DE	0x93,0x20		; E+G+D triplet
	DE	0x80,0x0C		; E+G triplet internote
	DE	0x98,0x20		; E+G+G triplet
	DE	0x80,0x0C		; E+G triplet internote
	DE	0xDF,0x98,0xD8,0x50		; E+G+G dotted 8th (swap back voices 1 and 3)
	DE	0x80,0x80,0x10			; internote
	DE	0xDF,0x98,0x08			; E+G, 32nd note
	DE	0x80,0x80,0x08			; internote gap
	DE	0xDF,0x98,0x08			; E+G 32nd note
	DE	0x80,0x80,0x08			; internote gap
	DE	0xDF,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C			; internote gap
	DE	0xDF,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C			; internote gap
	DE	0xDF,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C			; internote gap
	DE	0xA1,0x9D,0x50			; F#+D dotted 8th
	DE	0x80,0x80,0x10			; internote
	DE	0x9F,0x98,0x10			; E+G 16th
	DE	0x80,0x80,0x10
	DE	0x9F,0x98,0x50			; E+G dot 8
	DE	0x80,0x80,0x10
	DE	0x9D,0x95,0x10			; D+F# 16th
	DE	0x80,0x80,0x10
	DE	0x9D,0x95,0x50			; D+F# dot 8
	DE	0x80,0x80,0x10
	DE	0x9F,0x98,0x10			; E+G 16th
	DE	0x80,0x80,0x10
	DE	0x9F,0x98,0x50			; E+G dot 8
	DE	0x80,0x80,0x10
	DE	0xA1,0x9D,0x10			; F#+D 16th
	DE	0x80,0x80,0x10
	DE	0xA1,0x9D,0x80,0x20		; F#+D triplet
	DE	0x80,0x80,0x0C
	DE	0x9F,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C
	DE	0x9D,0x95,0x20			; D+F# triplet
	DE	0x80,0x80,0x0C
	DE	0xA1,0x9D,0x20			; F#+D triplet
	DE	0x80,0x80,0x0C
	DE	0x9F,0x98,0x20			; E+G triplet
	DE	0x80,0x80,0x0C
	DE	0x9D,0x95,0x20			; D+F# triplet
	DE	0x80,0x80,0x0C
	DE	0x9F,0x98,0x40			; E+G 8th
	DE	0x80,0x80,0x20			; 16th rest
	DE	0x93,0xD8,0xDF,0x08		; E+G 16th, D 32nd (swap13)
	DE	0x80,0x08
	DE	0x93,0x80				; D 32nd
	DE	0x80,0x80,0x80,0x08
	DE	0x93,0xD8,0xDF,0x20		; D triplet
	DE	0x80,0x0C
	DE	0x8C,0x20				; low A triplet
	DE	0x80,0x0C
	DE	0x93,0x20				; D triplet
	DE	0x80,0x0C
	DE	0x98,0x20				; G triplet
	DE	0x80,0x0C
	DE	0x93,0x20				; D triplet
	DE	0x80,0x0C
	DE	0x98,0x20				; G triplet
	DE	0x80,0x0C
	DE	0x98,0x20				; G triplet
	DE	0x80,0x0C
	DE	0x93,0x20				; D triplet
	DE	0x80,0x0C
	DE	0x98,0x20				; G triplet
	DE	0x80,0x80,0x80,0x0C
	DE	0xD8,0x7F				; G whole note
	DE	0x7F
	DE	0x7F
	DE	0x7F
	DE	0x80,0x7F
	DE	0x7F
#endif
	

	END                       ; directive 'end of program'

