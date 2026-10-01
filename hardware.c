#include <stdint.h>
static inline uint8_t inb(uint16_t p){uint8_t v;__asm__ volatile("inb %w1,%0":"=a"(v):"Nd"(p));return v;}
static inline uint16_t inw(uint16_t p){uint16_t v;__asm__ volatile("inw %w1,%0":"=a"(v):"Nd"(p));return v;}
static inline void outb(uint16_t p,uint8_t v){__asm__ volatile("outb %0,%w1"::"a"(v),"Nd"(p));}
static inline void outl(uint16_t p,uint32_t v){__asm__ volatile("outl %0,%w1"::"a"(v),"Nd"(p));}
static uint32_t pci_read32(uint8_t bus,uint8_t dev,uint8_t fn,uint8_t off){
 uint32_t a=0x80000000u|((uint32_t)bus<<16)|((uint32_t)dev<<11)|((uint32_t)fn<<8)|(off&0xFC);
 outl(0xCF8,a);uint32_t v;__asm__ volatile("inl %w1,%0":"=a"(v):"Nd"((uint16_t)0xCFC));return v;
}
void pci_scan(void){
 volatile uint32_t *log=(volatile uint32_t*)0x90000;uint32_t n=0;
 for(uint16_t bus=0;bus<8;bus++)for(uint8_t dev=0;dev<32;dev++){
  uint32_t id=pci_read32(bus,dev,0,0);if(id==0xFFFFFFFF)continue;
  uint32_t cls=pci_read32(bus,dev,0,8);
  if(n<127)log[n++]=((uint32_t)bus<<24)|((uint32_t)dev<<16)|(cls&0xFFFFFF);
 }
 log[127]=n;
}
static int ata_wait(uint8_t mask,uint8_t val){for(uint32_t i=0;i<100000;i++){uint8_t s=inb(0x1F7);if((s&mask)==val)return 1;}return 0;}
int ata_identify(uint16_t *buf){
 outb(0x1F6,0xA0);outb(0x1F2,0);outb(0x1F3,0);outb(0x1F4,0);outb(0x1F5,0);outb(0x1F7,0xEC);
 if(!ata_wait(0x80,0))return 0;if(inb(0x1F7)&1)return 0;if(!ata_wait(0x08,0x08))return 0;
 for(int i=0;i<256;i++)buf[i]=inw(0x1F0);return 1;
}
int ata_read28(uint32_t lba,uint8_t count,uint16_t *buf){
 outb(0x1F6,0xE0|((lba>>24)&0x0F));outb(0x1F2,count);outb(0x1F3,(uint8_t)lba);outb(0x1F4,(uint8_t)(lba>>8));outb(0x1F5,(uint8_t)(lba>>16));outb(0x1F7,0x20);
 for(uint8_t s=0;s<count;s++){if(!ata_wait(0x80,0))return 0;if(inb(0x1F7)&1)return 0;for(int i=0;i<256;i++)*buf++=inw(0x1F0);}return 1;
}
void hardware_init(void){pci_scan();uint16_t id[256];(void)ata_identify(id);}
