# audio-demo

audio-demo is a demo using GBA Direct Sound, written in ARM assembly.

## __Prerequisites__
In order to run dma-test, you need:

* A **GBA** :) (real hardware or emulator)
* Hardware **(IRQ)** interrupts
* Timers
* Direct Memory Access **(DMA)**
* Memory mirroring (especially **EWRAM** and **IWRAM**)
* Direct Sound (PCM audio channels)

## __What is Direct Sound, and how does it work?__
The GBA's capability of playing back **(8-bit signed) PCM audio** is what's generally referred to as "Direct Sound". The two Direct Sound channels consist of **FIFOs**; it is possible to manually write to these FIFOs, or use sound DMA (a special DMA configuration) to feed them with raw PCM samples. To be continued...

## __What does this demo do?__
This demo uses sound DMA to play back my favorite theme from Rhyme Star. (thank you, Takeshi Abo, for composing this wonderful piece of music)

**Audio format: 8-bit signed PCM, mono, 16384 Hz**

## __Assembling the source__

I'll add the source code soon... ish.
