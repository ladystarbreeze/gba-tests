;----------------------------------------------------------------------------------
; dma-test.asm - small GBA Direct Memory Access test suite.
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
		
		bl      func_test1                ; start first test
		bl      func_install_isr          ; install copied ISR
		bl      func_test2                ; start second test
		
		mov     r4, OAM
		mov     r14, r15                  ; jump to OAM
		bx      r4
		
		; verify data from OAM transfers
__lab_main_verify1:
		adr     r0, __dat_data32
		mov     r1, EWRAM
		mov     r2, 16
		mov     r3, 3
		bl      func_verify_data
		
		cmp     r3, 0                     ; transfers successful?
		beq     __lab_main_verify2
		
		mov     r0, r3
		adr     r1, __dat_str_test3_err
		bl      func_print_errcode        ; print errorcode
		
__lab_main_verify2:
		adr     r0, __dat_data32
		mov     r1, VRAM
		add     r1, r1, 0x8000
		mov     r2, 16
		mov     r3, 4
		bl      func_verify_data
		
		cmp     r3, 0                     ; transfers successful?
		beq     __lab_main_verify3
		
		mov     r0, r3
		adr     r1, __dat_str_test4_err
		bl      func_print_errcode        ; print errorcode
		
__lab_main_verify3:                       ; verify byte stored in RAM
		mov     r4, IWRAM ; TEST 5
		add     r4, r4, 0x200
		ldrb    r5, [r4]
		cmp     r5, 2
		beq     __lab_passed
		
__lab_err_var:
		adr     r0, __dat_str_expected_err
		bl      func_puts
		
		mov     r0, r5
		mov     r1, 1
		bl      func_print_hex
		
		adr     r0, __dat_str_empty
		bl      func_puts
		
		mov     r0, 5
		adr     r1, __dat_str_test5_err
		bl      func_print_errcode

__lab_passed:
		adr     r0, __dat_str_passed
		bl      func_puts
		
		b       lab_forever
		
__dat_str_passed:
		db      0x0A, "  Passed!", 0
		
		align   4

__dat_str_test3_err:
		db      0x0A, 0x0A, 0x0A, "  Failed to copy data from", 0x0A, "  OAM to EWRAM!", 0
		
		align   4
		
__dat_str_test4_err:
		db      0x0A, 0x0A, 0x0A, "  Failed to copy data from", 0x0A, "  OAM to VRAM!", 0
		
		align   4
		
__dat_str_test5_err:
		db      0x0A, 0x0A, 0x0A, "  Byte variable is not 2!", 0
		
		align   4

__dat_str_expected_err:
		db      0x0A, 0x0A, "  Expected: 2   Got: ", 0
		
		align   4
		
__dat_str_empty:
		db      0x0A, 0x0A, 0x0A, 0
		
lab_forever:
		b       lab_forever
;----------------------------------------------------------------------------------
; end of main()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void install_isr(void) - installs transferred ISR
;----------------------------------------------------------------------------------
func_install_isr:
		stmdb   r13!, {r4-r11}
		
		mov     r4, IO
		mov     r5, IWRAM
		str     r5, [r4, -4]
		
		; enable VBLANK and DMA1 interrupts
		mov     r5, 8
		strh    r5, [r4, 4]
		add     r4, r4, 0x0200
		mov     r5, 1
		orr     r5, r5, 0x0200
		str     r5, [r4], 8
		strh    r5, [r4]
		
		ldmia   r13!, {r4-r11}
		bx      r14
;----------------------------------------------------------------------------------
; end of install_isr()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void start_dma(u32 sad, u32 dad, u32 cnt, u32 sad_off) - initiate DMA transfer
; Parameters: r0 - DMASAD, r1 - DMADAD, r2 - DMACNT, r3 - offset to DMASAD register
;----------------------------------------------------------------------------------
func_start_dma:
		stmdb   r13!, {r4-r11}
		
		mov     r4, IO                    ; calculate reg from IO + offset
		add     r4, r4, r3
		stmia   r4, {r0-r2}               ; load DMA registers, start transfer
		
		ldmia   r13!, {r4-r11}
		bx      r14
;----------------------------------------------------------------------------------
; end of start_dma()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; u32 verify_data(u32 *src, u32 *dest, u32 count, u32 errcode)
; Description: - verifies transferred data, returns errorcode or 0
; Parameters: r0 - source pointer, r1 - dest pointer, r2 - word count, r3 - errcode
;----------------------------------------------------------------------------------
func_verify_data:
		stmdb   r13!, {r4-r11}
		
__lab_loop_verify:
		ldr     r4, [r0], 4               ; load source data
		ldr     r5, [r1], 4               ; load transferred data
		cmp     r4, r5                    ; compare data
		bne     __lab_end_verify_data     ; terminate function if unequal
		subs    r2, r2, 1                 ; decrement loop counter
		bne     __lab_loop_verify
		mov     r3, 0
		
__lab_end_verify_data:
		ldmia   r13!, {r4-r11}
		bx      r14
;----------------------------------------------------------------------------------
; end of verify_data()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void print_errcode(u32 errcode, const char *errmsg)
; Description: print errorcode and error message!
; Parameters: r0 - errcode, r1 - error message
;----------------------------------------------------------------------------------
func_print_errcode:
		mov     r4, r0                    ; save errorcode
		mov     r5, r1                    ; save pointer to string
		adr     r0, __dat_str_errcode     ; load pointer to errcode string
		bl      func_puts
		
		mov     r0, r4                    ; restore errcode
		mov     r1, 1
		bl      func_print_hex
		
		mov     r0, r5                    ; print error message
		bl      func_puts
		
		b       lab_forever
__dat_str_errcode:
		db      0x0A, "  Errcode: ", 0
		
		align   4
;----------------------------------------------------------------------------------
; end of print_errcode()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void test1(void) - copy ISR to different memory locations
;----------------------------------------------------------------------------------
func_test1:
		stmdb   r13!, {r4-r11, r14}
		
		; copy ISR to OAM (DMA3) ; TEST 1
		adr     r0, __lab_isr             ; DMA3SAD
		mov     r1, OAM                   ; DMA3DAD
		mov     r2, 0x84000000            ; DMA3CNT_H
		orr     r2, r2, 24                ; DMA3CNT_L
		mov     r3, 0xD4
		bl      func_start_dma            ; start transfer
		
		; copy ISR from OAM to EWRAM (DMA0, 32-bit, malformed DAD)
		mov     r0, r1                    ; DMA0SAD
		mov     r1, EWRAM                 ; DMA0DAD
		orr     r1, r1, 0xF0000000
		mov     r3, 0xB0
		bl      func_start_dma            ; start transfer
		
		; copy ISR from EWRAM to IWRAM (DMA1, 16-bit)
		mov     r0, r1                    ; DMA1SAD
		mov     r1, IWRAM                 ; DMA1DAD
		mov     r2, 0x80000000            ; DMA1CNT_H
		orr     r2, r2, 48                ; DMA1CNT_L
		mov     r3, 0xBC
		bl      func_start_dma            ; start transfer
		
		; verify copied data
		adr     r0, __lab_isr
		mov     r2, 24
		mov     r3, 1
		bl      func_verify_data          ; verify data, get errorcode
		
		cmp     r3, 0                     ; transfers successful?
		beq     __lab_end_test1
		mov     r4, r3                    ; save errorcode
		
		; install default ISR
		bl      __func_install_vblank_isr
		mov     r0, r4
		adr     r1, __dat_str_test1_err
		bl      func_print_errcode        ; print errorcode
		
__lab_end_test1:
		ldmia   r13!, {r4-r11, r14}
		bx      r14

__lab_isr:                                ; ISR - 24 words
		mov     r1, IO
		add     r2, r1, 0x200
		ldrh    r0, [r2, 2]!
		ands    r3, r0, 1                 ; VBLANK interrupt?
		bne     __lab_isr_vblank
		ands    r3, r0, 0x0200            ; DMA1 interrupt?
		bne     __lab_isr_dma1
		mvn     r0, 0                     ; spurious IRQ, clear flags + return
		strh    r0, [r2]
		
		bx      r14
		
__lab_isr_vblank:
		strh    r3, [r2]                  ; clear IF + BIOS IF
		ldrh    r3, [r1, -8]!
		orr     r3, r3, 1
		strh    r3, [r1]
		
		bx      r14
		
__lab_isr_dma1:
		stmdb   r13!, {r4-r5}
		
		mov     r4, IWRAM                 ; decrement variable in RAM, return
		add     r4, r4, 0x200
		ldrb    r5, [r4]
		sub     r5, r5, 1
		strb    r5, [r4]
		strh    r3, [r2]
		
		ldmia   r13!, {r4-r5}
		bx      r14
		
__dat_str_test1_err:
		db      0x0A, 0x0A, 0x0A, "  Failed to copy ISR!", 0
		
		align   4
;----------------------------------------------------------------------------------
; end of test1()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void test2(void) - copy DMA1 transfer routine to OAM
;----------------------------------------------------------------------------------
func_test2:
		stmdb   r13!, {r4-r11, r14}
		
		; transfer DMA1 routine to OAM (DMA3, 32-bit, malformed SAD) ; TEST 2
		adr     r0, __lab_dma1_routine    ; DMA3SAD
		orr     r0, r0, 0xF0000000
		mov     r1, OAM                   ; DMA3DAD
		adr     r4, __lab_dma1_routine
		adr     r5, __lab_get_size
		sub     r6, r5, r4
		mov     r6, r6, lsr 2
		mov     r2, 0x84000000            ; DMA3CNT_H
		orr     r2, r2, r6                ; DMA3CNT_L
		mov     r3, 0xD4
		bl      func_start_dma            ; start DMA transfer
		
		; verify copied data
		adr     r0, __lab_dma1_routine
		mov     r2, r6
		mov     r3, 2
		bl      func_verify_data          ; verify data, get errorcode
		
		cmp     r3, 0                     ; transfers successful?
		beq     __lab_end_test2
		
		mov     r0, r3
		adr     r1, __dat_str_test2_err
		bl      func_print_errcode        ; print errorcode
		
__lab_end_test2:
		ldmia   r13!, {r4-r11, r14}
		bx      r14
		
__dat_str_test2_err:
		db      0x0A, 0x0A, 0x0A, "  Failed to copy DMA1 transfer", 0x0A, "  routine to OAM!", 0
		
		align   4
		
__lab_dma1_routine:                       ; test 3 + 4
		stmdb   r13!, {r4-r11, r14}
		
		mov     r4, IWRAM                 ; initialize variable in RAM
		add     r4, r4, 0x200
		mov     r5, 5
		strb    r5, [r4]
		
		; transfer data32 to EWRAM (DMA1, 16-bit, Immediate Mode + Repeat) ; TEST 3
		adr     r0, __dat_data32          ; DMA1SAD
		mov     r1, EWRAM                 ; DMA1DAD
		mov     r2, 0xC2000000            ; DMA1CNT_H
		orr     r2, r2, 32                ; DMA1CNT_L
		mov     r3, 0xBC
		mov     r4, IO                    ; calculate reg from IO + offset
		add     r4, r4, r3
		stmia   r4, {r0-r2}               ; load DMA registers, start transfer
		
		; transfer data32 to VRAM (DMA1, 32-bit, Immediate Mode + Repeat) ; TEST 4
		adr     r0, __dat_data32          ; DMA1SAD
		mov     r1, VRAM                  ; DMA1DAD
		add     r1, r1, 0x8000
		mov     r2, 0xC6000000            ; DMA1CNT_H
		orr     r2, r2, 16
		mov     r3, 0xBC
		mov     r4, IO                    ; calculate reg from IO + offset
		add     r4, r4, r3
		stmia   r4, {r0-r2}               ; load DMA registers, start transfer
		
__lab_end_dma1:
		ldmia   r13!, {r4-r11, r14}
		bx      r14
		
__dat_data32:
		dw      0x12341234, 0x12345678, 0x98765432, 0x12347543
		dw      0x12342345, 0x12543423, 0xFFFFFFFF, 0xEEEEEEEE
		dw      0xAAAABBBB, 0xCCCCCCCC, 0x00000000, 0xABCDABCD
		dw      0xFFFFEFFF, 0x23743283, 0xABABABAB, 0xDEADBEEF
		
__lab_get_size:
		dw      0x00000000
;----------------------------------------------------------------------------------
; end of test2()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------

        include '../lib/print_utils.asm'
;----------------------------------------------------------------------------------
