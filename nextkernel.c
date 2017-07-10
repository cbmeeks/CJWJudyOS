//This code is compiler-specific (cc65).
#include <stdlib.h>
#include <stdio.h>
//Define hardware memory io macros.
#define POKE(addr,val)     (*(unsigned char*) (addr) = (val))
#define POKEW(addr,val)    (*(unsigned*) (addr) = (val))
#define PEEK(addr)         (*(unsigned char*) (addr))
#define PEEKW(addr)        (*(unsigned*) (addr))
unsigned char mem[16384];
const unsigned progaddr = &mem;
unsigned char progname[16];

void main (void)
{
  FILE *f;
  char buf[0x10];
  POKEW(0x8FFE, &progname);
  POKEW(0x8FFC, &mem);
  f = fopen("initprog,seq","r");
  fread(progname, 1, 16, f);
  fclose(f);

  while (progname[0] != 0x00)
  {
    snprintf(buf, sizeof(buf), "%s,prg", progname);
    f = fopen(buf, "r");
    fread(mem, 1, 16384, f);
    fclose(f);
    //Please help!  Need a program translator (actual-opcode-address-mover) to help programs execute!
    //I need each opcode that uses an "actual" address to have its addresses moved forward so it is within the range of $19c2 to $59c1, not $07ff!
    asm("jsr %w", &mem[0]);
  }
  
  printf("Session closed.");
}
