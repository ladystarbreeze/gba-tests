# dma-test

dma-test is a small Direct Memory Access test suite written in ARM assembly.

## __Prerequisites__
In order to run dma-test, you need:

* A **GBA** :) (real hardware or emulator)
* Hardware **(IRQ)** and software **(SWI)** interrupts
* Direct Memory Access **(DMA)**
* Memory mirroring (especially **EWRAM** and **IWRAM**) 

## ___Test results___
Running dma-test will give you one of these five error codes:

***Error code 1: "Failed to copy ISR!"***

This error code indicates the inability to copy the **interrupt service routine** to IWRAM. **Test 1** uses three different kinds of DMA configurations to eventually copy the ISR to IWRAM:
* 32-bit DMA (DMA3, GamePak -> OAM).
* 32-bit DMA with a malformed destination address (DMA0, OAM -> EWRAM). (Hint: the DMA controller ignores the upper 4-5 bits of DMA addresses!)
* 16-bit DMA (DMA1, EWRAM -> IWRAM)

**verify_data()** does then compare the original source data with the ISR that should now reside in IWRAM. In case of an error, **Test 1** will install a default VBLANK ISR and print **error code 1**.

***Error code 2: "Failed to copy DMA1 transfer routine to OAM!"***

**Test 2** will print out **error code 2** if it was unable to move the routine that executes **Test 3 and 4** to OAM. **Test 2** uses the following DMA configuration:
* 32-bit DMA with a malformed source address (DMA3, GamePak -> OAM). (Hint: see **Test 1**)

***Error code 3: "Failed to copy data from OAM to EWRAM!***

**Error code 3** indicates that **Test 3** was unable to copy 16 words from OAM to EWRAM. **Test 3** uses the following DMA configuration:

* 16-bit DMA (DMA1, OAM -> EWRAM, Immediate Mode + Repeat). (Hint: Immediate Mode + Repeat is an invalid configuration; this DMA configuration will **not** re-enable the DMA Enable bit and thus not repeat!)

***Error code 4: "Failed to copy data from OAM to VRAM!***

**Test 4** will report **error code 4** if it was unable to move the same 16 words of data from OAM to VRAM, using a slightly different DMA configuration:

* 32-bit DMA (DMA1, OAM -> VRAM, Immediate Mode + Repeat). (Hint: see **Test 3**)

***Error code 5: "Byte variable is not 2!"***

You can pretty much ignore this error message. The DMA1 transfer routine is supposed to invoke the ISR twice, which doesn't happen on real hardware for whatever reason. Instead, you will get the error message "***Expected: 2   Got: 3***" on a real GBA and/or some emulators. If you happen to get this error message, you're good.

***Blue screen***

In rare cases, you might only get a blue screen. This indicates that the text library failed to write text due to buggy (hardware/software) interrupt handling. Do note that you won't get a blue screen on real hardware; it's an indicator for interrupt bugs in emulators!

## __Assembling the source__

To assemble the source code, you can use the ARM assembler **FASMARM**.
