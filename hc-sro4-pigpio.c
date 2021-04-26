#include <time.h>
#include <stdio.h>
#include <pigpio.h>

// Change these to the pins you actually connected to.
static const int _pin_trig = 18;
static const int _pin_echo = 23;

// Change these variables for the size of your barrel
static const int _barrel_volume = 250;
static const int _barrel_liters_per_mm = 0.267;

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

	gpioWrite(_pin_trig, 1);
	nanosleep(&ts, NULL);
	gpioSetAlertFuncEx(_pin_echo, _start, (void*)millis);
	gpioWrite(_pin_trig, 0);
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
	gpioSetMode(_pin_trig, PI_OUTPUT);
	gpioSetMode(_pin_echo, PI_INPUT);
	
	for (t = 0; t<10; t++) {
		sense(&millis);
		nanosleep(&ts, NULL);
		gpioSetAlertFunc(_pin_echo, NULL);
		if (millis > 0) break;
	}

	time(&rawtime);
	timeinfo = localtime(&rawtime);
	strftime(datestr, sizeof(datestr), "%Y-%m-%d %T", timeinfo);
	distance = millis*0.1715;
	liters = _barrel_volume - millis * 0.1715 * _barrel_liters_per_mm;
	printf("%s\t%i\t%i\n", datestr, distance, liters);

	return 0;
}
