;----------------------------------------------------------------------------------
; print_utils.asm - GBA text routines written in assembly.
; Copyright (C) 2020  Michelle-Marie Schiller
;----------------------------------------------------------------------------------

		include 'memory.inc'
		
;----------------------------------------------------------------------------------
; void print_init(u16 bg_col, u16 text_col, bool install_isr)
; Description: initializes the print_utils library.
; Parameters: r0 - background color, r1 - text color, r2 - install default ISR
;----------------------------------------------------------------------------------
func_print_init:
		stmdb   r13!, {r4-r11, r14}       ; save variable registers + lr
		
		mov     r6, r2                    ; save bool
		
		; load palette
		mov     r4, PALETTE
		strh    r0, [r4], 2               ; function args = palette
		strh    r1, [r4]
		
		bl      __func_load_chr_data      ; load character data
		cmp     r6, 1
		blhs    __func_install_vblank_isr ; install VBLANK IRQ handler if r1/6 >= 1
		
		; set up LCD registers
		mov     r4, IO
		mov     r5, 0x84                  ; BG0: SBB(0), CBB(1), 8BPP
		strh    r5, [r4, BG0CNT]
		mov     r5, 0x0100                ; DISPCNT: Mode 0, enable BG0
		strh    r5, [r4, DISPCNT]
		
		ldmia   r13!, {r4-r11, r14}
		bx      r14
;----------------------------------------------------------------------------------
; end of print_init()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void puts(const char *str) - print string
; Parameters: r0 - pointer to NULL-terminated string
;----------------------------------------------------------------------------------
func_puts:
		stmdb   r13!, {r4-r11, r14}
		
		mov     r6, r0                    ; save pointer, __vsync() destroys r0
		bl      __func_vsync              ; vertical synchronization
		mov     r5, IWRAM                 ; load pointer to EWRAM
		mov     r10, VRAM                 ; load pointer to VRAM
		mov     r11, 64                   ; load map offset
		sub     r5, r5, 0x100
		ldmia   r5, {r7-r8}               ; load column/row
		
__lab_puts_loop:
		ldrb    r4, [r6], 1               ; load character
		cmp     r4, 0x00                  ; NULL terminator???
		beq     __lab_puts_end
		cmp     r4, 0x0A                  ; line feed????
		bleq    __func_line_feed
		cmp     r4, 0x0A                  ; line_feed() overwrites flags
		beq     __lab_puts_loop           ; , so redo the check
		sub     r4, r4, 0x20
		cmp     r4, 0x5F                  ; invalid character?????
		bhi     __lab_puts_end
		mul     r9, r8, r11               ; calculate VRAM offset
		add     r9, r9, r7
		strh    r4, [r10, r9]             ; print character
		add     r7, r7, 2
		cmp     r7, 60                    ; end of line???
		bleq    __func_line_feed
		b       __lab_puts_loop
		
__lab_puts_end:
		stmia   r5, {r7, r8}
		
		ldmia   r13!, {r4-r11, r14}
		bx      r14
;----------------------------------------------------------------------------------
; end of puts()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void print_hex(u32 num, u32 n) - prints hex number
; Parameters: r0 - hex number to print, r1 - number of digits to print
;----------------------------------------------------------------------------------
func_print_hex:
		stmdb   r13!, {r4-r11, r14}
		
		mov     r4, 0
		mov     r5, IWRAM                 ; load pointer to EWRAM
		mov     r6, r1                    ; load loop counter
		cmp     r6, 8
		movhi   r6, 8
		sub     r5, r5, 0xF0
		strb    r4, [r5], -1              ; store NULL terminator
		
__lab_print_hex_loop:
		and     r7, r0, 0x0F              ; get hex digit
		cmp     r7, 9
		addls   r7, r7, 0x30
		addhi   r7, r7, 0x37
		strb    r7, [r5], -1
		mov     r0, r0, lsr 4             ; get next digit
		subs    r6, r6, 1
		bne     __lab_print_hex_loop
		
		mov     r0, r5
		add     r0, r0, 1
		bl      func_puts
		
		ldmia   r13!, {r4-r11, r14}
		bx      r14
;----------------------------------------------------------------------------------
; end of print_hex()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void __line_feed(void) - line feed
; Parameters: implicitly takes r7 and r8
;----------------------------------------------------------------------------------
__func_line_feed:
		stmdb   r13!, {r14}
		
		; move to next line, clear screen if row overflows
		add     r8, r8, 1
		mov     r7, 0
		cmp     r8, 20
		moveq   r8, 0
		bleq    __func_clear_screen
		
		ldmia   r13!, {r14}
		bx      r14
;----------------------------------------------------------------------------------
; end of __line_feed()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void __clear_screen(void) - clears screen
;----------------------------------------------------------------------------------
__func_clear_screen:
		stmdb   r13!, {r4-r11}

		mov     r4, VRAM                  ; load pointer to VRAM
		mov     r5, 0x400                 ; load loop counter
		mov     r6, 0
		
__lab_clear_screen_loop:
		strh    r6, [r4], 2
		subs    r5, r5, 1
		bne     __lab_clear_screen_loop
		
		ldmia   r13!, {r4-r11}
		bx      r14
;----------------------------------------------------------------------------------
; end of clear_screen()
;----------------------------------------------------------------------------------	
		
;----------------------------------------------------------------------------------
; void __vsync(void) - synchronize video to VBLANK
;----------------------------------------------------------------------------------
__func_vsync:
		stmdb   r13!, {r4-r11}
		
		; clear VBLANK IRQ flag in IF
		mov     r4, IO
		add     r4, r4, 0x200
		mov     r5, 1
		strh    r5, [r4, 2]
		
		swi     0x050000                  ; call VBlankIntrWait() (swi(5))
		
		ldmia   r13!, {r4-r11}
		bx      r14
;----------------------------------------------------------------------------------
; end of __vsync()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void __install_vblank_isr(void) - installs generic VBLANK IRQ handler
;----------------------------------------------------------------------------------
__func_install_vblank_isr:
		stmdb   r13!, {r4-r11}
		
		adr     r4, __lab_vblank_isr      ; load pointer to ISR
		mov     r5, IWRAM
		ldmia   r4, {r0-r3, r6-r10}       ; load ISR
		stmia   r5, {r0-r3, r6-r10}       ; store ISR in IWRAM
		
		mov     r4, IO                    ; install ISR
		str     r5, [r4, -4]
		
		; enable VBLANK interrupts
		mov     r5, 8
		strh    r5, [r4, 4]
		add     r4, r4, 0x0200
		mov     r5, 1
		str     r5, [r4], 8
		strh    r5, [r4]
		
		ldmia   r13!, {r4-r11}
		bx      r14
		
__lab_vblank_isr:
		; generic VBLANK ISR - acknowledge VBLANK IRQ, return
		mov     r1, IO
		add     r2, r1, 0x200
		ldrh    r0, [r2, 2]!
		and     r0, r0, 1
		strh    r0, [r2]
		ldrh    r0, [r1, -8]!
		orr     r0, r0, 1
		strh    r0, [r1]
		
		bx      r14
;----------------------------------------------------------------------------------
; end of __install_vblank_isr()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; void __load_chr_data(void) - loads character data into VRAM
;----------------------------------------------------------------------------------
__func_load_chr_data:
		stmdb   r13!, {r4-r11}
		
		adr     r4, __dat_chr_data        ; load pointer to character data
		ldrb    r5, [r4, -4]              ; load number of tiles to store
		mov     r6, VRAM                  ; load pointer to char block
		orr     r6, r6, 0x4000 
		
__lab_transfer_loop:
		ldmia   r4!, {r0-r3, r7-r10}
		stmia   r6!, {r0-r3, r7-r10}
		ldmia   r4!, {r0-r3, r7-r10}
		stmia   r6!, {r0-r3, r7-r10}
		subs    r5, r5, 1
		bne     __lab_transfer_loop
		
		ldmia   r13!, {r4-r11}
		bx      r14
;----------------------------------------------------------------------------------
; end of __load_chr_data()
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
; chr_data - character data (8BPP, 64 Bytes/16 Words per Tile)
;----------------------------------------------------------------------------------

		include 'print_utils_font.asm'
;----------------------------------------------------------------------------------
