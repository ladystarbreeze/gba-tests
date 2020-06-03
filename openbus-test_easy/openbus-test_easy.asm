;----------------------------------------------------------------------------------
; openbus-test_easy.asm - very basic open bus test.
; Copyright (C) 2020  Michelle-Marie Schiller
;----------------------------------------------------------------------------------

format binary as 'gba'

;----------------------------------------------------------------------------------
lab_header:
;----------------------------------------------------------------------------------
		include '../lib/header_gen.asm'

;----------------------------------------------------------------------------------
; void main(void) - main()
;----------------------------------------------------------------------------------
func_main:
		; set up print_utils
		mov     r0, 0x7C00                ; background color
		mov     r1, 0xFF                  ; text color
		orr     r1, r1, 0x0300
		mov     r2, 0                     ; don't install default ISR
		bl      func_print_init
		
		bl      func_install_isr          ; install custom ISR
		bl      func_copy_ewram_routine   ; copies __lab_ewram_routine to EWRAM
		
		; enable VBLANK interrupts, clear VBLANK IRQ flag
		mov     r4, IO
		mov     r5, 8
		strh    r5, [r4, 4]
		add     r4, r4, 0x0200
		mov     r5, 1
		str     r5, [r4]
		strh    r5, [r4, 8]
		strh    r5, [r4, 2]
		
		; store pointer to __lab_print_result
		adr     r6, __lab_print_result
		mov     r7, IWRAM
		add     r7, r7, 0x200
		str     r6, [r7, 4]
		
		; jump to open bus
		adr     r8, __lab_branch_ewram
		mov     r9, EWRAM                 ; loading r15 with "bx r9" puts the
		ldr     r15, [r8]                 ; instruction on open bus!!
		
__lab_print_result:
		; disable interrupts
		mov     r3, IO
		mov     r4, 0
		add     r3, r3, 0x200
		strh    r4, [r3]
		
		; install default VBLANK ISR
		bl      __func_install_vblank_isr
		
		; re-enable interrupts, compare IWRAM variable
		mov     r3, IO
		mov     r4, 1
		add     r3, r3, 0x200
		strh    r4, [r3]
		
		mov     r1, IWRAM                 ; load variable from IWRAM
		mov     r0, 0xF000000F            ; compare to F000000Fh
		add     r1, r1, 0x200
		ldr     r2, [r1]
		cmp     r0, r2
		adreq   r0, __lab_str_passed
		beq     __lab_puts
		
		; print error message
		adr     r0, __lab_str_err
		bl      func_puts
		mov     r0, r2
		mov     r1, 8
		bl      func_print_hex
		adr     r0, __lab_str_hex
		bl      func_puts
		adr     r0, __lab_str_failed
		
__lab_puts:
		bl      func_puts
		
lab_forever:
		b       lab_forever
		
__lab_branch_ewram:
		bx      r9
		
__lab_str_passed:
		db      0x0A, "  Passed!", 0
		
		align   4

__lab_str_failed:
		db      0x0A, 0x0A, 0x0A, "  Failed!", 0
		
		align   4
		
__lab_str_err:
		db      0x0A, 0x0A, "  Expected: F000000Fh", 0x0A, "  Got:      ", 0
		
		align   4

__lab_str_hex:
		db      "h", 0
		
		align   4
;----------------------------------------------------------------------------------
; end of main()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void install_isr(void) - copies ISR to IWRAM, installs it
;----------------------------------------------------------------------------------
func_install_isr:
		stmdb   r13!, {r4-r11}
		
		; install ISR, then transfer ISR to IWRAM
		mov     r1, IWRAM
		mov     r0, IO
		str     r1, [r0, -4]
		adr     r0, __lab_isr
		ldmia   r0!, {r2-r8}
		stmia   r1!, {r2-r8}
		ldmia   r0!, {r2-r9}
		stmia   r1!, {r2-r9}
		
		ldmia   r13!, {r4-r11}
		bx      r14
		
__lab_isr:
		mov     r1, IO                    ; acknowledge all IRQs
		mvn     r0, 0
		add     r1, r1, 0x200
		strh    r0, [r1, 2]
		mov     r2, r14                   ; point saved r14 at __lab_print_result
		add     r13, r13, 20
		ldmia   r13!, {r14}
		mov     r1, IWRAM
		add     r1, r1, 0x200
		ldr     r14, [r1, 4]
		add     r14, r14, 4
		stmdb   r13!, {r14}
		sub     r13, r13, 20
		mov     r14, r2
		
		bx      r14
;----------------------------------------------------------------------------------
; end of install_isr()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void copy_ewram_routine(void) - copies EWRAM routine to EWRAM
;----------------------------------------------------------------------------------
func_copy_ewram_routine:
		stmdb   r13!, {r4-r11}
		
		adr     r4, __lab_ewram_routine
		mov     r5, EWRAM
		
		ldmia   r4, {r6-r10}
		stmia   r5, {r6-r10}
		
		ldmia   r13!, {r4-r11}
		bx      r14

__lab_ewram_routine:
		mov     r1, IWRAM                 ; [3000200h] = F000000Fh
		mov     r0, 0xF000000F
		add     r1, r1, 0x200
		str     r0, [r1]
		
		; loop until VBLANK IRQ happens
__lab_loop_ewram:
		b       __lab_loop_ewram
;----------------------------------------------------------------------------------
; end of copy_ewram_routine()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------

        include '../lib/print_utils.asm'
;----------------------------------------------------------------------------------
