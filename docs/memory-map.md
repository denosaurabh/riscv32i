~~ 16kb memory ~~
~~ 4kb pages = 4 pages ~~

--

[MEMORY MAP]

- BOOT-LOADER

- OPERATING SYSTEM KERNEL

  - INSTRUCTIONS
  - PCBs DATA
  - SCHEDULAR & PROCESSES QUEUE
  - INTERRUPT VECTOR TABLE

  - STANDARD LIBRARY TABLE
  - SYSTEM CALLS TABLE

- PROGRAMS

- I/O
  - KEYBOARD
  - DISPLAY

--

[PAGE MEMORY]

- INSTRUCTIONS
- STATIC DATA
- STACK
- HEAP

--

[PCB - Program Control Memory]

- process id
- process state
- 32 CPU registers
- MMU Page ID
- heap pointer
- stack pointer
- instruction pointer (pc)

--

[MMU - Pages]

- Page Table Entry
  - FRAME POINTER / PHYSICAL ADDRESS
  - PERMISSION (READ/READ-WRITE)
  - DIRTY BIT (weather it's written)
  - RESERVED BIT (reserved for future use)
