/*
 * Copyright (c) 2014, ARM Limited and Contributors. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of ARM nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#include <cci.h>
#include <gic_v2.h>
#include <plat_config.h>
#include "../fvp_def.h"

.section .rodata.gic_reg_name, "aS"
gicc_regs:
	.asciz "gicc_hppir", "gicc_ahppir", "gicc_ctlr", ""
gicd_pend_reg:
	.asciz "gicd_ispendr regs (Offsets 0x200 - 0x278)\n Offset:\t\t\tvalue\n"
newline:
	.asciz "\n"
spacer:
	.asciz ":\t\t0x"

	/* ---------------------------------------------
	 * The below macro prints out relevant GIC
	 * registers whenever an unhandled exception is
	 * taken in BL3-1.
	 * Clobbers: x0 - x10, x16, x17, sp
	 * ---------------------------------------------
	 */
	.macro plat_print_gic_regs
	mov_imm	x0, (VE_SYSREGS_BASE + V2M_SYS_ID)
	ldr	w16, [x0]
	/* Extract BLD (12th - 15th bits) from the SYS_ID */
	ubfx	x16, x16, #SYS_ID_BLD_SHIFT, #4
	/* Check if VE mmap */
	cmp	w16, #BLD_GIC_VE_MMAP
	b.eq	use_ve_mmap
	/* Check if Cortex-A53/A57 mmap */
	cmp	w16, #BLD_GIC_A53A57_MMAP
	b.ne	exit_print_gic_regs
	mov_imm	x17, BASE_GICC_BASE
	mov_imm	x16, BASE_GICD_BASE
	b	print_gicc_regs
use_ve_mmap:
	mov_imm	x17, VE_GICC_BASE
	mov_imm	x16, VE_GICD_BASE
print_gicc_regs:
	/* gicc base address is now in x17 */
	adr	x6, gicc_regs	/* Load the gicc reg list to x6 */
	/* Load the gicc regs to gp regs used by str_in_crash_buf_print */
	ldr	w8, [x17, #GICC_HPPIR]
	ldr	w9, [x17, #GICC_AHPPIR]
	ldr	w10, [x17, #GICC_CTLR]
	/* Store to the crash buf and print to console */
	bl	str_in_crash_buf_print

	/* Print the GICD_ISPENDR regs */
	add	x7, x16, #GICD_ISPENDR
	adr	x4, gicd_pend_reg
	bl	asm_print_str
gicd_ispendr_loop:
	sub	x4, x7, x16
	cmp	x4, #0x280
	b.eq	exit_print_gic_regs
	bl	asm_print_hex
	adr	x4, spacer
	bl	asm_print_str
	ldr	x4, [x7], #8
	bl	asm_print_hex
	adr	x4, newline
	bl	asm_print_str
	b	gicd_ispendr_loop
exit_print_gic_regs:
	.endm

.section .rodata.cci_reg_name, "aS"
cci_iface_regs:
	.asciz "cci_snoop_ctrl_cluster0", "cci_snoop_ctrl_cluster1" , ""

	/* ------------------------------------------------
	 * The below macro prints out relevant interconnect
	 * registers whenever an unhandled exception is
	 * taken in BL3-1.
	 * Clobbers: x0 - x9, sp
	 * ------------------------------------------------
	 */
	.macro plat_print_interconnect_regs
	adr	x6, cci_iface_regs
	/* Store in x7 the base address of the first interface */
	mov_imm	x7, (CCI400_BASE + SLAVE_IFACE3_OFFSET)
	ldr	w8, [x7, #SNOOP_CTRL_REG]
	/* Store in x7 the base address of the second interface */
	mov_imm	x7, (CCI400_BASE + SLAVE_IFACE4_OFFSET)
	ldr	w9, [x7, #SNOOP_CTRL_REG]
	/* Store to the crash buf and print to console */
	bl	str_in_crash_buf_print
	.endm
