This was originally developed for a HC-SR04 but works fine with HY-SRF05.

# Connect
As the pi can only handle 3.3 V on the gpio pins the voltage needs to be steped
down from the 5V provided on the echo pin. This is done through soldering two
resistors in the circuit connect a 470 ohm resistor between ground and the 
pi-pin for echo and a 330 ohm resistor between the pi-pin and the echo pin on
the sensor. Other connections are connected straight through.

# Dependancies
`apt install pigpio`

# Configure
Change the constants in config.h to account for

* gpio pins used for trig and echo
* the volume of the barrel
* the width of the barrel

# Compile
`gcc -Wall -pthread -o hc-sro4-pigpio hc-sro4-pigpio.c -lpigpio -lrt`

## Optional:
```
sudo chown root hc-sro4-pigpio 
sudo chmod 4755 hc-sro4-pigpio
```
# Run
`./hc-sro4-pigpio`
