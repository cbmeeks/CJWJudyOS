# OldieOS
A new GEOS-like Unix-like Operating System for Commodore 64!
Kernel usage rules:
First, run the kernel in a c64 emulator.
Then, get the task space's first byte address by PEEK-ing 36860 (lo byte) and 36861 (hi byte).
Next, get the task file's name's first byte address by PEEK-ing 36862 (lo byte) and 36863 (hi byte) as well.
Use the task space first byte address to organize your assembler.
Somewhere in your code, don't forget to switch the task by storing the 16-byte long file-to-be-loaded's name to where the file's name's first byte is at!
Thanks!
