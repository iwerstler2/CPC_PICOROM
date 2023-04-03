CPC ROM Emulator using Pi Pico

|Signal     |GPIO         |CPC Pin|Pico Pin          |
|-----------|-------------|-------|------------------|
|A0-A13     |GPIO0-GPIO13 |18-5   |1-2,4-7,9-12,14-17|
|D0-D7      |GPIO14-GPIO21|26-19  |19-22,24-27       |
|~ROMEN     |GPIO22       |42     |29                |
|ROMDIS     |-            |43     |-                 |
|A15        |GPIO26       |3      |31|
|WRITE_LATCH|GPIO27       |-      |32|
|Button     |GPIO28       |-      |34|
|CPC RESET  |-            |40     |-|
|Pico RESET |-            |-      |30|


WRITE_LATCH signal is created using a Diode-OR gate:
```
  A13 __|\|___
        |/|  |
             |
  ~WR __|\|__|____  WRITE_LATCH
        |/|  |
             |
~IORQ __|\|__|
        |/|
```
All diodes IN4148 or similar. Pulldown provided by GPIO pin.

ROMDIS is connected to 5V

Pico is powered from 5V via a IN4148 diode to VSYS

Button is a push button to 0V, with 1K pull up to 3V3

CPC Reset is a push button to 0V

Pico Reset is a push button to 0V

## Notes

Since the pico is overclocked, everything is read into RAM at startup.
```
set(PICO_DEFAULT_BINARY_TYPE copy_to_ram)
```
There seems to be a limit on the number or ROMs that can be loaded (it's less than 8) before the CPC won't boot because the Pico is not ready. I think this delay is caused by the time it takes to copy the whole program + data into RAM at startup. I don't think overclocking would fix that.


## Code

### Startup: 
* Load ROMs into arrays.
* Set all GPIO as inputs
* set pulldown on WRITE_LATCH
* if diag rom enabled, set pullup on Button, then
  * if button pressed, load diag rom
  * else basic rom
* else load basic rom
* enable overclock

### Loop:
  - read all gpio
  - if ROMEN is low:
    - if A15 is low, get data from lower ROM
    - else get data from upper ROM
    - write data to GPIO
    - set data lines as output
  - else:
    - set data lines as input
    - if WRITE_LATCH is low, latch ROM bank from data lines


