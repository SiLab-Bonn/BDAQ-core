# STUSB4500 NVM programming script

## Installation

To use this script you will need an installation of [Basil](https://github.com/SiLab-Bonn/basil) and the [Arduino IDE](https://www.arduino.cc/en/software). Development was done with Basil version `3.2.1dev0`. In `basil/firmware/arduino/SerialToI2C` you will find the sketch necessary to be flashed to the arduino to use it as an I2C interface. You might need to additionally install pySerial (i.e. `pip install pySerial`).

The default pins are `A4` for SDA and `A5` for SCL. Make sure to take note of the com port of the arduino as seen in the IDE which needs to match the port in `arduino_serial_to_i2c.yaml`. Also, the I2C address of the STUSB4500 device needs to be set in `stusb-program.py`, the default address `0x28` corresponds to both adress pins of the STUSB4500 being zero as implemented on the BDAQ Rev 2.0 boards.

To test your instalation of Basil, you may want to run the `arduino_serial_to_i2c.py` found in  `basil/examples/lab_devices/`. You might have to add yourself to the tty group, i.e. run `sudo usermod -a -G tty yourname` with your username in the terminal. If that doesn't work, you can find out which /dev/ttyX the arduino is connected to by running `dmesg | grep tty`.

## Usage

See contents of `stusb-program.py` for information.

