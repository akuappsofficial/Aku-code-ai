#include <stdint.h>

typedef struct {
    uint32_t flags, mem_lower, mem_upper, boot_device, cmdline, mods_count, mods_addr;
    uint32_t syms[4];
    uint32_t mmap_length, mmap_addr, drives_length, drives_addr, config_table, boot_loader_name, apm_table;
    uint64_t framebuffer_addr;
    uint32_t framebuffer_pitch, framebuffer_width, framebuffer_height;
    uint8_t framebuffer_bpp, framebuffer_type;
    uint16_t color_info[6];
} __attribute__((packed)) multiboot_info_t;

static volatile uint32_t *fb;
static uint32_t pitch, sw, sh;
static int graphical;

static uint8_t inb(uint16_t port) {
    uint8_t v;
    __asm__ volatile ("inb %1,%0" : "=a"(v) : "Nd"(port));
    return v;
}
static void px(int x,int y,uint32_t c){if(!graphical||x<0||y<0||(uint32_t)x>=sw||(uint32_t)y>=sh)return;fb[y*pitch/4+x]=c;}
static void rect(int x,int y,int w,int h,uint32_t c){for(int j=0;j<h;j++)for(int i=0;i<w;i++)px(x+i,y+j,c);}
static void line(int x0,int y0,int x1,int y1,uint32_t c){int dx=x1-x0,sx=dx<0?-1:1,dy=-(y1-y0),sy=dy<0?-1:1,e=dx+dy;for(;;){px(x0,y0,c);if(x0==x1&&y0==y1)break;int e2=2*e;if(e2>=dy){e+=dy;x0+=sx;}if(e2<=dx){e+=dx;y0+=sy;}}}

static uint8_t glyph(char c,int r){
static const uint8_t A[26][7]={
{14,17,17,31,17,17,17},{30,17,17,30,17,17,30},{14,17,16,16,16,17,14},{30,17,17,17,17,17,30},
{31,16,16,30,16,16,31},{31,16,16,30,16,16,16},{14,17,16,23,17,17,15},{17,17,17,31,17,17,17},
{14,4,4,4,4,4,14},{7,2,2,2,18,18,12},{17,18,20,24,20,18,17},{16,16,16,16,16,16,31},
{17,27,21,21,17,17,17},{17,25,21,19,17,17,17},{14,17,17,17,17,17,14},{30,17,17,30,16,16,16},
{14,17,17,17,21,18,13},{30,17,17,30,20,18,17},{15,16,16,14,1,1,30},{31,4,4,4,4,4,4},
{17,17,17,17,17,17,14},{17,17,17,17,17,10,4},{17,17,17,21,21,21,10},{17,17,10,4,10,17,17},
{17,17,10,4,4,4,4},{31,1,2,4,8,16,31}};
if(c>='a'&&c<='z')c-=32;if(c>='A'&&c<='Z')return A[c-'A'][r];
switch(c){
case '0':{static const uint8_t g[]={14,17,19,21,25,17,14};return g[r];}
case '1':{static const uint8_t g[]={4,12,4,4,4,4,14};return g[r];}
case '2':{static const uint8_t g[]={14,17,1,2,4,8,31};return g[r];}
case '3':{static const uint8_t g[]={30,1,1,14,1,1,30};return g[r];}
case '4':{static const uint8_t g[]={2,6,10,18,31,2,2};return g[r];}
case '5':{static const uint8_t g[]={31,16,16,30,1,1,30};return g[r];}
case '6':{static const uint8_t g[]={14,16,16,30,17,17,14};return g[r];}
case '7':{static const uint8_t g[]={31,1,2,4,8,8,8};return g[r];}
case '8':{static const uint8_t g[]={14,17,17,14,17,17,14};return g[r];}
case '9':{static const uint8_t g[]={14,17,17,15,1,1,14};return g[r];}
case ':':{static const uint8_t g[]={0,4,4,0,4,4,0};return g[r];}
case '.':{static const uint8_t g[]={0,0,0,0,0,6,6};return g[r];}
case '-':{static const uint8_t g[]={0,0,0,31,0,0,0};return g[r];}
case '/':{static const uint8_t g[]={1,2,2,4,8,8,16};return g[r];}
case '+':{static const uint8_t g[]={0,4,4,31,4,4,0};return g[r];}
default:return 0;}}

static void text(int x,int y,const char*s,uint32_t c,int z){while(*s){for(int r=0;r<7;r++){uint8_t b=glyph(*s,r);for(int k=0;k<5;k++)if(b&(1<<(4-k)))rect(x+k*z,y+r*z,z,z,c);}x+=6*z;s++;}}

static void folder(int x,int y,uint32_t c){rect(x,y+7,34,25,c);rect(x+4,y+2,16,9,c);}
static void terminal_icon(int x,int y,uint32_t c){rect(x,y,38,30,c);line(x+7,y+9,x+15,y+15,c);line(x+15,y+15,x+7,y+21,c);line(x+19,y+23,x+30,y+23,c);}
static void settings_icon(int x,int y,uint32_t c){rect(x+13,y+2,12,26,c);rect(x+2,y+13,34,4,c);rect(x+8,y+8,22,14,c);rect(x+14,y+11,10,8,0x172033);}
static void game_icon(int x,int y,uint32_t c){rect(x+4,y+10,30,16,c);rect(x+10,y+6,18,6,c);rect(x+9,y+15,4,12,0x172033);rect(x+5,y+19,12,4,0x172033);rect(x+25,y+16,3,3,0x172033);rect(x+30,y+20,3,3,0x172033);}

static void desktop(void){
rect(0,0,sw,sh,0x08111F);
for(int y=0;y<(int)sh;y+=80)rect(0,y,sw,1,0x14243A);
rect(0,0,sw,58,0x101C2E);rect(18,14,30,30,0x4F8CFF);text(25,22,"A",0xFFFFFF,2);
text(62,20,"AKU OS",0xFFFFFF,2);text(sw-230,22,"SYSTEM READY",0x7FD7FF,1);
rect(55,95,sw-110,145,0x101C2E);rect(55,95,6,145,0x4F8CFF);
text(85,120,"WELCOME TO AKU OS",0xFFFFFF,3);text(87,170,"A TINY DESKTOP BUILT FROM SCRATCH",0x9BB4D1,1);text(87,196,"V1.0 / VENTOY READY",0x6EE7B7,1);
int y=280,g=22,w=190;uint32_t card=0x101C2E,white=0xEAF2FF;
rect(55,y,w,120,card);folder(78,y+20,0x4F8CFF);text(78,y+70,"FILES",white,2);
rect(55+w+g,y,w,120,card);terminal_icon(78+w+g,y+18,0x6EE7B7);text(78+w+g,y+70,"TERMINAL",white,2);
rect(55+2*(w+g),y,w,120,card);settings_icon(78+2*(w+g),y+18,0xF5C451);text(78+2*(w+g),y+70,"SETTINGS",white,2);
if(sw>850){rect(55+3*(w+g),y,w,120,card);game_icon(78+3*(w+g),y+18,0xFF7A90);text(78+3*(w+g),y+70,"GAMES",white,2);}
int py=435;rect(55,py,sw-110,130,0x0E1828);text(78,py+22,"SYSTEM",0xFFFFFF,2);
text(78,py+60,"CPU X86 / MEMORY AVAILABLE / DISPLAY FRAMEBUFFER",0x9BB4D1,1);
text(78,py+88,"KEYS: 1 FILES  2 TERMINAL  3 SETTINGS  4 GAMES",0x6EE7B7,1);
rect(0,sh-58,sw,58,0x101C2E);text(24,sh-39,"AKU",0x4F8CFF,2);text(sw-160,sh-38,"V1.0",0x9BB4D1,1);
}
static void terminal_screen(void){rect(0,0,sw,sh,0x050A12);rect(0,0,sw,48,0x101C2E);text(20,18,"AKU TERMINAL",0xFFFFFF,2);text(20,85,"AKU OS V1.0",0x6EE7B7,2);text(20,125,"TYPE HELP FOR COMMANDS",0x9BB4D1,1);text(20,165,"AKU@OS:~$",0x4F8CFF,2);}

void kmain(uint32_t magic,uint32_t mbi_addr){
if(magic==0x2BADB002){multiboot_info_t*m=(multiboot_info_t*)mbi_addr;if((m->flags&(1<<12))&&m->framebuffer_type==1&&m->framebuffer_bpp==32){fb=(volatile uint32_t*)(uintptr_t)m->framebuffer_addr;pitch=m->framebuffer_pitch;sw=m->framebuffer_width;sh=m->framebuffer_height;graphical=1;}}
if(!graphical){volatile uint16_t*v=(volatile uint16_t*)0xB8000;const char*s="AKU OS V1.0 - FRAMEBUFFER UNAVAILABLE";for(int i=0;s[i];i++)v[i]=(0x0F<<8)|s[i];for(;;)__asm__ volatile("hlt");}
desktop();
for(;;){if(!(inb(0x64)&1))continue;uint8_t s=inb(0x60);if(s&0x80)continue;
if(s==0x02)desktop();else if(s==0x03)terminal_screen();else if(s==0x04){desktop();rect(120,620,sw-240,90,0x16243A);text(145,642,"SETTINGS",0xFFFFFF,2);text(145,674,"DISPLAY AUDIO INPUT ABOUT",0x9BB4D1,1);}
else if(s==0x05){desktop();rect(120,620,sw-240,90,0x16243A);text(145,642,"GAMES",0xFFFFFF,2);text(145,674,"GAME RUNTIME NOT INSTALLED",0xFFB4C0,1);}
else if(s==0x01)desktop();}}
