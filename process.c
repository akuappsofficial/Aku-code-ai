#include <stdint.h>
typedef void (*task_fn)(void);
typedef struct{uint32_t pid;const char*name;task_fn entry;uint8_t state;uint32_t ticks;}task_t;
#define MAX_TASKS 8
static task_t tasks[MAX_TASKS];static uint32_t task_count,current;
int process_create(const char*name,task_fn fn){if(task_count>=MAX_TASKS)return -1;tasks[task_count]=(task_t){task_count+1,name,fn,1,0};return (int)task_count++;}
void process_tick(void){if(!task_count)return;for(uint32_t n=0;n<task_count;n++){current=(current+1)%task_count;if(tasks[current].state){tasks[current].ticks++;tasks[current].entry();break;}}}
uint32_t process_count(void){return task_count;}
const task_t*process_list(void){return tasks;}
