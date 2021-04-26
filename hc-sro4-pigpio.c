#include <time.h>
#include <stdio.h>
#include <pigpio.h>
#include "config.h"

static void _start(int gpio, int level, uint32_t tick, void* user)
{
	uint32_t *millis;
	millis = user;
	if (1 == level)
       	{
		(*millis) = tick;
	} else if (0 == level && *millis != 0)
	{
		*millis = tick - *millis;
	}
}

void sense(uint32_t *millis)
{
	struct timespec ts;
	ts.tv_sec = 0;
	ts.tv_nsec = 20000;

	gpioWrite(PIN_TRIG, 1);
	nanosleep(&ts, NULL);
	gpioSetAlertFuncEx(PIN_ECHO, _start, (void*)millis);
	gpioWrite(PIN_TRIG, 0);
}

int main(int argc, char *argv[])
{
	uint32_t millis = 0;
	int distance, liters;
	time_t rawtime;
	struct tm * timeinfo;
	struct timespec ts;
	int t;
	char datestr[200];
	ts.tv_sec = 1;
	ts.tv_nsec = 0;
	if (gpioInitialise() < 0) return 1;
	gpioSetMode(PIN_TRIG, PI_OUTPUT);
	gpioSetMode(PIN_ECHO, PI_INPUT);
	
	for (t = 0; t<10; t++) {
		sense(&millis);
		nanosleep(&ts, NULL);
		gpioSetAlertFunc(PIN_ECHO, NULL);
		if (millis > 0) break;
	}

	time(&rawtime);
	timeinfo = localtime(&rawtime);
	strftime(datestr, sizeof(datestr), "%Y-%m-%d %T", timeinfo);
	distance = millis*0.1715;
	liters = BARREL_VOLUME - millis * 0.1715 * BARREL_LITERS_PER_MM;
	printf("%s\t%i\t%i\n", datestr, distance, liters);

	return 0;
}
