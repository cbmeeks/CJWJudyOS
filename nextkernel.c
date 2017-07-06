#include <stdlib.h>
#include <stdio.h>
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
  POKEW(0x9FFE, &progname);
  POKEW(0x9FFC, &mem);
  f = fopen("initprog.seq","r");
  fread(progname, 1, 16, f);
  fclose(f);

  while (progname[0] != 0x00)
  {
    snprintf(buf, sizeof(buf), "%s.prg", progname);
    f = fopen(buf, "r");
    fread(mem, 1, 16384, f);
    fclose(f);
    asm("jsr $19c0");
  }
  
  printf("Session closed.");
}
