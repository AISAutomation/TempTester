#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#if defined(OS_LINUX) || defined(OS_MACOSX)
  #include <sys/ioctl.h>
  #include <termios.h>
#elif defined(OS_WINDOWS)
  #include <conio.h>
#endif

#include "hid.h"
//*----------------------------------------------------------------------------
static char getkey(void);
//*----------------------------------------------------------------------------
int main()
{
	int i, r, num, temp;
	char c, buf[64], *pwr;

	r = rawhid_open(1, 0x16C0, 0x0480, 0xFFAB, 0x0200);
	if (r <= 0) {
		fprintf(stdout, "No Temp-Sensor found\n");
		return r;
	}
	// fprintf(stdout, "Found Temp-Sensor\n");

	while (1) {
		//....................................
		// check if any Raw HID packet has arrived
		//....................................
		num = rawhid_recv(0, buf, 64, 220);
		if (num < 0) {
			fprintf(stdout, "\nError Reading\n");
			rawhid_close(0);
			return num;
		}
		
		if (num == 64) {
		  temp = *(short *)&buf[4];
		  if(buf[2]) { pwr = "Extern"; }
		        else { pwr = "Parasite"; }
		  fprintf(stdout, "Sensor #%d of %d: %+.1f\xF8""C Power: %-10s ID: ", 
		          buf[1], buf[0], temp / 10.0, pwr);
		  
			for (i = 0x08; i < 0x10; i++) {
				fprintf(stdout, "%02X ", (unsigned char)buf[i]);
			}
			fprintf(stdout, "\n");
			break;
		}
		//....................................
		// check if any input on stdin
		//....................................
		c = getkey();
		if(c == 0x1B) { break; }   // ESC
		if(c >= 32) {
			fprintf(stdout, "\ngot key '%c', sending...\n", c);
			buf[0] = c;
			for (i=1; i<64; i++) {
				buf[i] = 0;
			}
			rawhid_send(0, buf, 64, 100);
		}
	}
	rawhid_close(0);
}
//*----------------------------------------------------------------------------
#if defined(OS_LINUX) || defined(OS_MACOSX)
// Linux (POSIX) implementation of _kbhit().
// Morgan McGuire, morgan@cs.brown.edu
static int _kbhit() {
	static const int STDIN = 0;
	static int initialized = 0;
	int bytesWaiting;

	if (!initialized) {
		// Use termios to turn off line buffering
		struct termios term;
		tcgetattr(STDIN, &term);
		term.c_lflag &= ~ICANON;
		tcsetattr(STDIN, TCSANOW, &term);
		setbuf(stdin, NULL);
		initialized = 1;
	}
	ioctl(STDIN, FIONREAD, &bytesWaiting);
	return bytesWaiting;
}
static char _getch(void) {
	char c;
	if (fread(&c, 1, 1, stdin) < 1) return 0;
	return c;
}
#endif
//*----------------------------------------------------------------------------
static char getkey(void)
{
	if (_kbhit()) {
		char c = _getch();
		if (c != 0) return c;
	}
	return 0;
}
//*----------------------------------------------------------------------------
