; Postlab2.asm
;
; Created: 10/02/2025 19:56:08
; Author : Gabriela Yoc
;
;********************************************************************************
; Contador de Segundos con Timer0
; MCU: ATmega328P
; Autor: Gabriela Yoc
; Descripción: Contador de 4 bits que incrementa cada 1 segundo utilizando Timer0
;********************************************************************************
.include "M328PDEF.inc"

.cseg
.org 0x0000
    rjmp SETUP

;********************************************************************************
; Configuración de la pila
;********************************************************************************
SETUP:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
	LDI R22, 0x00
	STS UCSR0B, R22         ; Deshabilita completamente USART

;********************************************************************************
; Configuración del Timer0 y Prescaler
;********************************************************************************
    CALL INIT_TMR0           ; Inicializar Timer0   
    LDI R21, (1 << CLKPCE)
    STS CLKPR, R21          ; Habilitar cambio de prescaler
    LDI R21, 7     
    STS CLKPR, R21


;********************************************************************************
; Configuración de Puertos
;********************************************************************************
    MT: .DB 0x03F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

    LDI R21, 0x1F
	OUT DDRC, R21          ; Configurar PORTD como entrada (botones)
	LDI R16, 0x13
    OUT PORTC, R16  
    LDI R24, 0x00          ; Inicializar contador de desbordes (contador de 100ms)

	LDI R16, 0xFF
    OUT DDRB, R16          ; Configurar PB0-PB3 como salida (contador) y PB4 como salida (alarrma) 
    LDI R16, 0x00
    OUT PORTB, R16         

    LDI R16, 0xFF
    OUT DDRD, R16          ; Configurar PORTD como salida (contador)
	LDI ZL, LOW(MT<<1)
	LDI ZH, HIGh(MT<<1)
	LPM R20, Z
	OUT PORTD, R20

	LDI R25, 0
	LDI R26, 0

;********************************************************************************
; Loop Principal
;********************************************************************************
MAIN_LOOP:

	IN R16, PINC           ; Leer estado de botones
    SBIS PINC, 0           ; Si PD2 está en bajo, llamar a incremento
    rcall CHECK_INC        
    SBIS PINC, 1           ; Si PD3 está en bajo, llamar a decremento
    rcall CHECK_DEC    
	    

    IN R21, TIFR0         ; Leer registro de interrupción de TIMER 0
    SBRS R21, TOV0        ; Saltar si el bit de desbordamiento (TOV0) no está activo
    RJMP MAIN_LOOP        ; Repetir ciclo hasta que ocurra desbordamiento

    SBI TIFR0, TOV0       ; Limpiar bandera de desbordamiento
    LDI R21, 2
    OUT TCNT0, R21        ; Recargar valor en TCNT0

    ; Incrementar el contador de desbordes
    INC R24               ; Incrementar contador de desbordes
    CPI R24, 10           ; Si llegan a 10 desbordes (1 segundo)
    BRLT SKIP_INCREMENT   ; Si no han pasado 10 desbordes, saltar incremento

    INC R23               ; Incrementar contador de 4 bits
    CPI R23, 16           ; Si el contador llega a 16, reiniciar
    BRLT SKIP_RESET
    LDI R23, 0x00



SKIP_RESET:
    OUT PORTB, R23        ; Mostrar en LEDs
    LDI R24, 0x00         ; Reiniciar el contador de desbordes
	CP R23, R17           ; Comparar contador de segundos con contador de botones
    BRNE MAIN_LOOP        ; Si no son iguales, seguir en el loop
    CALL ALARMA           ; Si son iguales, alternar LED en PB4

SKIP_INCREMENT:
    RJMP MAIN_LOOP        ; Repetir ciclo
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
    RET
;********************************************************************************
; Subrutina de inicialización de la Alarma
;********************************************************************************
ALARMA:
    CPSE R26,R25
    CALL TURN_OFF         ; Si está encendido (1), apagar
	LDI R26, 0x0F
    SBI PORTC, PC4          ; Si está apagado (0), encender
	LDI R23, 0x0F
    RJMP MAIN_LOOP
TURN_OFF:
	LDI R23, 0x0F
	LDI R26, 0x00
    CBI PORTC, PC4          ; Apagar el LED
    RJMP MAIN_LOOP
;********************************************************************************
; Subrutina de inicialización del Timer0
;********************************************************************************
INIT_TMR0:
    LDI R21, (1<<CS01) | (1<<CS00) ; Prescaler de 64
    OUT TCCR0B, R21
    LDI R21, 2                  ; Cargar valor inicial en TCNT0
    OUT TCNT0, R21
    RET