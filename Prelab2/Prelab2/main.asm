;
; Prelab2.asm
;
; Created: 10/02/2025 19:56:08
; Author : Gabriela
;

;********************************************************************************
; Contador Binario de 4 Bits con Timer0
; MCU: ATmega328P
; Autor: Gabriela Yoc
; Descripción: Contador de 4 bits que incrementa cada 100ms utilizando Timer0
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

;********************************************************************************
; Configuración del Timer0 y Prescaler
;********************************************************************************
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16          ; Habilitar cambio de prescaler
    LDI R16, 0b00000100     ; Configurar prescaler a 16 (F_cpu = 1MHz)
    STS CLKPR, R16

    CALL INIT_TMR0           ; Inicializar Timer0

;********************************************************************************
; Configuración de Puertos
;********************************************************************************
    LDI R16, 0x0F
    OUT DDRB, R16          ; Configurar PB0-PB3 como salida (contador)
    LDI R17, 0x00          ; Inicializar contador en 0
    OUT PORTB, R17         ; Mostrar el contador en LEDs

;********************************************************************************
; Loop Principal
;********************************************************************************
MAIN_LOOP:
    IN R16, TIFR0         ; Leer registro de interrupción de TIMER 0
    SBRS R16, TOV0        ; Saltar si el bit de desbordamiento (TOV0) no está activo
    RJMP MAIN_LOOP        ; Repetir ciclo hasta que ocurra desbordamiento

    SBI TIFR0, TOV0       ; Limpiar bandera de desbordamiento
    LDI R16, 100
    OUT TCNT0, R16        ; Recargar valor en TCNT0

    INC R17               ; Incrementar contador
    CPI R17, 16           ; Si llega a 16, reiniciar a 0
    BRLT SKIP_RESET
    LDI R17, 0x00
SKIP_RESET:
    OUT PORTB, R17        ; Mostrar en LEDs

    RJMP MAIN_LOOP        ; Repetir ciclo

;********************************************************************************
; Subrutina de inicialización del Timer0
;********************************************************************************
INIT_TMR0:
    LDI R16, (1<<CS01) | (1<<CS00) ; Prescaler de 64
    OUT TCCR0B, R16
    LDI R16, 100                   ; Cargar valor inicial en TCNT0
    OUT TCNT0, R16
    RET

