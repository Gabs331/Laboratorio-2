;
; Laboratorio2.asm
;
; Created: 11/02/2025 15:08:25
; Author : Gabriela
;********************************************************************************
; Contador Binario de 4 Bits con Timer0
; MCU: ATmega328P
; Autor: Gabriela Yoc
; Descripción: Contador de 4 bits que incrementa cada 100ms utilizando Timer0
;********************************************************************************
.include "M328PDEF.inc"

.cseg
.org 0x0000

;********************************************************************************
; Configuración 
;********************************************************************************
SETUP:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
	LDI R22, 0x00
	STS UCSR0B, R22         ; Deshabilita completamente USART
;********************************************************************************
;Configuración
;********************************************************************************
	MT: .DB 0x03F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

	LDI R16, 0x00
    OUT DDRC, R16          ; Configurar PORTD como entrada (botones)
    LDI R16, 0x03
    OUT PORTC, R16         

    LDI R16, 0xFF
    OUT DDRD, R16          ; Configurar PORTD como salida (contador)
	LDI ZL, LOW(MT<<1)
	LDI ZH, HIGh(MT<<1)
	LPM R20, Z
	OUT PORTD, R20

;*******************************************************************
; LOOP INFINITO
;****************************************************************
LOOP:
    IN R16, PINC           ; Leer estado de botones
    SBIS PINC, 0           ; Si PD2 está en bajo, llamar a incremento
    rcall CHECK_INC        
    SBIS PINC, 1           ; Si PD3 está en bajo, llamar a decremento
    rcall CHECK_DEC        
    rjmp LOOP              ; Repetir ciclo
;*********************************************
; Subrutina: Botones de contador 
;*********************************************
CHECK_INC:
    rcall DELAY            ; Llamar al retardo (antirrebote)
    IN R16, PINC           ; Leer nuevamente
    SBIS PINC, 0           ; Verificar si sigue presionado
    ret
    rcall INC_COUNTER      ; Incrementar si la señal sigue activa
    ret
CHECK_DEC:
    rcall DELAY            ; Llamar al retardo (antirrebote)
    IN R16, PINC           ; Leer nuevamente
    SBIS PINC, 1           ; Verificar si sigue presionado
    ret
    rcall DEC_COUNTER      ; Decrementar si la señal sigue activa
    ret
;*********************************************
; Subrutina: Botón de incremento y decremento contador 
;*********************************************
INC_COUNTER:
	ADIW Z, 1			   ; Incrementar 1 al contador
    INC R17                ; Incrementar contador
    CPI R17, 16            ; Si llega a 16, reiniciar a 0
    BRLT SKIP_RESET_INC
	LDI R17, 0x00
	LDI ZL, LOW(MT<<1)
	LDI ZH, HIGh(MT<<1)
	LPM R20, Z
	OUT PORTD, R20
SKIP_RESET_INC:
	LPM R20, Z
	OUT PORTD, R20        ; Mostrar en LEDs
    ret
DEC_COUNTER:
    TST R17                ; Verificar si es 0
    BRNE SKIP_UNDERFLOW    ; Si no es 0, continuar con decremento
    LDI R17, 0x0F          ; Si es 0, reiniciar a 0x0F
	ADIW Z, 15			   ; Incrementar 15 al contador
    RJMP NO_DEC            ; Saltar decremento normal
SKIP_UNDERFLOW:
	SBIW Z, 1
    DEC R17                ; Decrementar contador normalmente
NO_DEC:
	LPM R20, Z
	OUT PORTD, R20
    ret
;*********************************************
; Subrutina: Retardo 
;*********************************************
DELAY:
    LDI R19, 0xFF          ; Cargar un valor grande
    LDI R18, 0x20          ; Segundo bucle para hacer un delay más largo
DELAY_LOOP:
    DEC R19
    BRNE DELAY_LOOP
    DEC R18
    BRNE DELAY_LOOP
    ret