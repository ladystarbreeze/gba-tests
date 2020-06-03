# openbus-test (easy)

openbus-test is a very basic open bus test written in ARM assembly.

## __Prerequisites__
In order to run openbus-test, you need:

* A **GBA** :) (real hardware or emulator)
* Hardware **(IRQ)** and software **(SWI)** interrupts
* Basic **open bus** implementation
* Memory mirroring (especially **EWRAM** and **IWRAM**)

## __What is an "open bus"?__
On the GBA, reading from invalid memory usually returns a value that is often referred to as an "open bus" value. Addresses like **1000000h** or **EEEEFFFFh** do not connect to any peripheral/valid memory, this is called "open bus"; while open bus behavior is generally unpredictable, results are predictable on a GBA: reading from invalid memory returns the last value that was put on the memory bus. (i.e. the last read or written value; do note that this is not a 100% correct explanation, but it will suffice for now)

## ___Test results___
This test ROM will print out one of the following messages:

***Expected: F000000Fh, Got: XXXXXXXXh***

This test ROM uses **ldr r15, [r8]** to put **bx r9** (i.e. the instruction that is being pointed to by r8) on open bus. The CPU now jumps to invalid memory and executes open bus values - that's right, it will execute **bx r9**! **bx r9** causes the CPU to branch to a short routine (which sets the word at address **3000200h** to **F000000Fh**) in EWRAM. Incorrectly emulating basic open bus behavior means the CPU will not branch to EWRAM; while this shouldn't cause a crash (the VBLANK interrupt service routine should "rescue" the CPU and make it jump back to ROM), it will print out this error message. (Hint: **Putting prefetched instructions on open bus is not enough to pass this test!**)

***Passed!***

:)

***Blue screen***

In rare cases, you might only get a blue screen; this usually indicates buggy interrupt handling. Do note that you won't get a blue screen on real hardware (obviously); it's an indicator for interrupt bugs in emulators!

## __Assembling the source__

To assemble the source code, you can use the ARM assembler **FASMARM**.
