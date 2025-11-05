#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
#
# INFORMATION ON HOW TO USE THIS SCRIPT IS AT THE BOTTOM OF THE FILE
#
#   

''' STUSB4500 NVM Programmer
'''

import time

from basil.dut import Dut

dut = Dut('arduino_serial_to_i2c.yaml')
dut.init()

time.sleep(2)  # Allow tranfer layer to initialize / arduino to boot

dut['SerialToI2C'].communication_delay = 5  # Set delay between two commands to 5 milli seconds
print(f"Communication delay after command to Arduino is {dut['SerialToI2C'].communication_delay} ms")

dut['SerialToI2C'].i2c_address = 0x28  # Set I2C address
print(f"I2C bus address to write to is {dut['SerialToI2C'].i2c_address}")

dut['SerialToI2C'].check_i2c_connection()  # Check if connection is established on I2C bus with given address
#print("{:#101b}".format(dut['SerialToI2C'].read_register(reg=0x0E)))  # PORT_STATUS_1 register

''' The following two functions can be changed to use any other I2C device while maintaining 
    full functionality of the script.
'''
def write(reg, data):
    dut['SerialToI2C'].write_register(reg=reg, data = data)
def read(reg):
    return dut['SerialToI2C'].read_register(reg=reg)

''' The following functions implement setting and reading of individual registers.
    Information on all of these procedures can be found in the STUSB documentation
    found in the same directory as the script
'''
def read_max_current():
    RDO_reg_lsb = read(reg=0x91)
    RDO_reg_msb = read(reg=0x92)
    print(RDO_reg_msb)
    int_max_current = ( ( RDO_reg_msb << 8 ) + RDO_reg_lsb ) & 0b111111111
    return 10*int_max_current

def reg_data_change_amps(data, amps):
    # amperage must be at most 10 bits
    # in unit of 10mA
    data = data & ~0b1111111111
    return data + int(amps)

def reg_data_change_voltage(data, volts):
    # coltage must be at most 10 bits
    # in units of 50mV
    data = data &  ~(0b1111111111 << 10)
    return data + (int(volts) << 10)

def read_pdo_reg(first_reg_address):
    data = 0
    for i in range(4):
        data += read(reg=first_reg_address + i) << i*8
    return data

def write_pdo_reg(first_reg_address, data):
    for i in range(4):
        i8 = i*8
        out = (data & (0xFF << i8 ) ) >> i8
        write(reg=first_reg_address + i, data = out)


def set_pdo(pdo_number, v, a):
    reg_base_address = 0x85
    data = read_pdo_reg(reg_base_address + (pdo_number-1)*4)
    data = reg_data_change_amps(data, a*100)
    data = reg_data_change_voltage(data, v*1000/50)
    write_pdo_reg(reg_base_address + (pdo_number-1)*4, data)

def init_stusb():
    for i in range(10):
        read(reg=0x0D + i)

def soft_reset():
    # write(reg=0x51, data = 0x0D) ???
    # write(reg=0x1a, data = 0x26)
    write(reg=0x23, data=0x01)
    time.sleep(0.1)
    write(reg=0x23, data=0x00)

def print_pdo_settings():
    print("Sink PDO settings:")
    for i in range(3):
        raw_string = "{:#034b}".format(read_pdo_reg(0x85 + 4*i))[2:]
        print(f"PDO {i+1}:", end="")
        print('-'.join(raw_string[j:j+8] for j in range(0, len(raw_string),  8)))
        print(f"{int(raw_string[-20:-10],2)*50/1000} V {int(raw_string[-10:],2)*10/1000} A")
        print("")

def NVM_unlock():
    write(0x95,0x47)

def NVM_lock():
    write(0x95,0x00)
    time.sleep(0.01)

def NVM_power_up_write():
    write(reg=0x53,data=0x00)
    write(reg=0x96,data=0x00)
    time.sleep(0.01)
    write(reg=0x96,data=0x40)

def NVM_power_up():
    write(reg=0x96,data=0x00)
    time.sleep(0.01)
    write(reg=0x96,data=0x40)

def NVM_power_down():
    write(reg=0x96,data=0x40)
    time.sleep(0.01)
    write(reg=0x96,data=0x00)
    time.sleep(0.01)

def NVM_read_sector(i):
    write(reg=0x96,data=0x50+i) #read ith sector, result will be in 0x53 ++
    time.sleep(0.01)
    data = []
    for j in range(8):
        data.append(read(reg=0x53+j))
    return data

def NVM_data_dump():
    sectors = []
    try:
        NVM_unlock()
        NVM_power_up()
        write(reg=0x97,data=0x00)
        for i in range(5):
            sectors.append(NVM_read_sector(i))
    finally:
        NVM_power_down()
        NVM_lock()
    return sectors

def NVM_full_erase():
    write(reg=0x97,data=0xFA)
    write(reg=0x96,data=0x50)
    time.sleep(0.01)
    write(reg=0x97,data=0x07)
    write(reg=0x96,data=0x50)
    time.sleep(0.02)
    write(reg=0x97,data=0x05)
    write(reg=0x96,data=0x50)
    time.sleep(0.02)

def print_sectors(sectors):
    for i in range(5):
        print(f"Sector{i}: ", end="")
        for j in range(8):
            print(f"{sectors[i][j]:#04x} ", end="")
        print(" ")

def NVM_write_sector(sector_n, data):
    for byte_n in range(8):
        write(reg=0x53+byte_n,data=int(data[byte_n]))
    time.sleep(0.01)
    write(reg=0x97,data=0x01)
    write(reg=0x96,data=0x50)
    time.sleep(0.01)
    write(reg=0x97,data=0x06)
    write(reg=0x96,data=0x50+sector_n)
    time.sleep(0.05)

def NVM_write_sectors(sectors):
    try:
        NVM_unlock()
        NVM_power_up_write()
        NVM_full_erase()
        for i in range(5):
            NVM_write_sector(i, sectors[i])
    finally:
        NVM_power_down()
        NVM_lock()



# modify pdo settings within NVM data. 
# Arguments:
#   sectors is the NVM data to be manipulated.
#   pdo_nr specifies which pdo you want to modify, can be 1, 2 or 3.
#   v is the voltage in volts to be set.
#   a is the desired current for the pdo. Note that this must be within the values in the stusb current lookup table, flex current is not implemented.
# Returns the updated NVM data.
def modify_PDO(sectors, pdo_nr, v, a):
    i_lut = {500: 1, 750: 2, 1000: 3, 1250: 4, 1500: 5, 1750: 6, 2000: 7, 2250: 8, 2500: 9, 2750: 10, 3000: 11, 3500: 12, 4000: 13, 4500: 14, 5000: 15}
    mili_a = a*1000
    rounded_mili_a = mili_a - (mili_a % 250) if a < 3 else mili_a - (mili_a % 500)
    if rounded_mili_a not in i_lut:
        raise f"specified rounded current {rounded_mili_a} not within LUT spec"
    i_bits = i_lut[rounded_mili_a]
    v_value = v*20 # = 1000/50. I.e. convert to mv and use stusb unit
    if (pdo_nr == 1) & (v != 5):
        raise "Can´t set pdo 1 to other voltage than 5"
    if pdo_nr == 1 :
        sectors[3][2] = (sectors[3][2] & 0x0F) + ( i_bits << 4)
    elif pdo_nr == 2:
        sectors[4][0] = (sectors[4][0] & 0b00111111) + ( (v_value & 0b11) << 6)
        sectors[4][1] = (v_value & 0b1111111100) >> 2

        sectors[3][4] = (sectors[3][4] & 0xF0) + (i_bits)
    elif pdo_nr == 3:
        sectors[4][2] = (v_value & 0b11111111) 
        sectors[4][3] = (sectors[4][3] & 0b11111100 ) + ( (v_value & 0b1100000000) >> 8)

        sectors[3][5] = (sectors[3][5] & 0x0F) + ( i_bits << 4)
    print(f"PDO {pdo_nr} will be set to {v}V and {rounded_mili_a}mA")
    return sectors

# modify the POWER_OK_CFG register in NVM data
#Arguments:
#   sectors are the NVM data to be modified.
#   setting is the new POWER_OK_CFG value to be set, either 0, 2 or 3.
# Returns the updated NVM data.
def set_POWER_OK_CFG(sectors, setting):
    if (setting not in range(4)) | (setting == 1):
        raise "POWER_OK_CFG can only be 0,2 or 3"
    sectors[4][4] = (sectors[4][4] & 0b10011111) + (setting << 5)
    print(f"POWER_OK_CFG will be set to {setting}")
    return sectors

# modify the POWER_ONLY_ABOVE_5V register in NVM data
#Arguments:
#   sectors are the NVM data to be modified.
#   setting is the new POWER_ONLY_ABOVE_5V value, either 1 or 0
# Returns the updated NVM data.
def set_POWER_ONLY_ABOVE_5V(sectors, setting):
    if setting not in range(2):
        raise "POWER_ONLY_ABOVE_5V can only be 0, 1"
    sectors[4][6] = (sectors[4][6] & 0b11110111) + (setting << 3)
    print(f"POWER_ONLY_ABOVE_5V will be set to {setting}")
    return sectors


# modify the GPIO_CTRL register in NVM data
#Arguments:
#   sectors are the NVM data to be modified.
#   setting is the new GPIO_CTRL value, between 0 and 3 (SW controlled, FAULT detection, DEBUG detection, or 5 V / 3 A capability detection)
#   GPIO pin is always active low
# Returns the updated NVM data.
def set_GPIO_CTRL(sectors, setting):
    if setting not in range(4):
        raise "GPIO_CTRL can only be 0, 1, 2 or 3"
    sectors[1][1] = (sectors[1][1] & 0b11001111) + (setting << 4)
    print(f"GPIO_CTRL will be set to {setting}")
    return sectors



''' Start of the actual script.
    The configuration as is will only print the current pdo configuration of the volatile registers of the STUSB as well as print the contents of the NVM.
'''

# Factory defaults:
default_sectors = [[0x0, 0x0, 0xb0, 0xaa, 0x0, 0x45, 0x0, 0x0],[ 0x10, 0x40, 0x9c, 0x1c, 0xff, 0x1, 0x3c, 0xdf],[ 0x2, 0x40, 0xf, 0x0, 0x32, 0x0, 0xfc, 0xf1],[ 0x0, 0x19, 0x36, 0xaf, 0xf3, 0x35, 0x5f, 0x0],[ 0x0, 0x2d, 0xb4, 0x20, 0x43, 0x0, 0x40, 0xfb]] #Factory NVM contents.
soft_reset()
init_stusb()
print_pdo_settings()
sectors = NVM_data_dump()
print("Old NVM")
print_sectors(sectors)
sectors = modify_PDO(sectors,1,5,3)   # Set PDO 1 to 5V and 3A, 15 W "low power"
sectors = modify_PDO(sectors,2,9,3)   # Set PDO 2 to 9V and 3A, 27 W 
sectors = modify_PDO(sectors,3,15,2)  # Set PDO 3 to 15V and 2A, 30 W
sectors = set_POWER_OK_CFG(sectors,2) # Set POWER_OK_CFG to 2 (default is 2)
sectors = set_POWER_ONLY_ABOVE_5V(sectors,1) # Set POWER_ONLY_ABOVE_5V to 1 (default is 0), allow 5 V operation
sectors = set_GPIO_CTRL(sectors,3)    # Set GPIO_CTRL to 3 (5 V / 3 A capability detection)
inputstr = input("Do you want to write this configuration to NVM? NO/yes")
if inputstr == "yes":
    print("New NVM to be written")
    print_sectors(sectors)
    print("Writing...")
    NVM_write_sectors(sectors)
    print("Writing done. NVM will be loaded upon next STUSB hard reset.")
else:
    print("Nothing written.") 
soft_reset()
