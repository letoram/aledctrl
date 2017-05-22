#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
	char rgb[3] = {'r', 'g', 'b'};
	int i;

	while(1){
/* reset all, buffer/apply immediately randomly */
		putchar('A'); putchar(0x00); putchar('i');
		putchar(0x00); putchar('c'); putchar(rand() % 2);

/* set one random channel to one random value */
		for (i=0;i<127;i++){
			putchar('a'); putchar(i); putchar(rgb[rand() % 3]);
			putchar(rand() % 255); putchar('c'); putchar(rand() % 2);
		}
		fflush(stdout);
//		sleep(1);
	}
	return EXIT_SUCCESS;
}
