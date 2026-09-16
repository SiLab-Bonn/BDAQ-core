# ------------------------------------------------------------
#  Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
#  Constraints for the BDAQCore PCB with the Mercury+ KX2(160T-2) FPGA board
#

# Clock domains
# CLK_SYS: 100 MHz, from xtal oscillator
# -> PLL2: CLK8_PLL
#          CLK16_PLL: RX
#          CLK32_PLL: RX
#          CLK40_PLL: PULSER, TDC, TLU
#          CLK160_PLL: TLU, TDC
#          CLK320_PLL: TLU, TDC
# -> PLL1: BUS_CLK_PLL: 142.86 MHz, main system clock (7 ns)
#          CLK125PLLTX, Ethernet
#          CLK125PLLTX90: Ethernet
# CLK_MGT_REF: 160 MHz, from Si570 programmable oscilaltor
# ->       CMDCLK: 160 MHz, command encoder
# CLK_RGMII_RX: 125 MHz, from Ethernet chip

# Clock inputs
create_clock -period 10.000 -name CLK_SYS -add [get_ports FCLK_IN]
create_clock -period 8.000 -name CLK_RGMII_RX -add [get_ports rgmii_rxc]
create_clock -period 6.250 -name CLK_MGT_REF -add [get_ports MGT_REFCLK0_P]
create_clock -period 25.000 -name CLK_SMA -add [get_ports MGT_REFCLK1_P]

# Derived clocks
create_generated_clock -name I2C_CLK -source [get_pins {PLLE2_BASE_inst_comm/CLKOUT0}] -divide_by 1600 [get_pins {i_tjmonopix2_core/i_clock_divisor_i2c/CLOCK_reg/Q}]
create_generated_clock -name rgmii_txc -source [get_pins {rgmii/ODDR_inst/C}] -divide_by 1 [get_ports {rgmii_txc}]

# Exclude asynchronous clock domains from timing (handled by CDCs)
set_clock_groups -asynchronous -group BUS_CLK_PLL -group I2C_CLK -group {CLK125PLLTX CLK125PLLTX90} -group {CLK640_PLL CLK320_PLL CLK160_PLL CLK40_PLL CLK32_PLL CLK16_PLL} -group [get_clocks -include_generated_clocks CLK_MGT_REF] -group [get_clocks -include_generated_clocks CLK_SMA] -group CLK_RGMII_RX

# SiTCP
set_max_delay -datapath_only -from [get_clocks CLK125PLLTX] -to [get_ports {rgmii_txd[*]}] 4.000
set_max_delay -datapath_only -from [get_clocks CLK125PLLTX] -to [get_ports rgmii_tx_ctl] 4.000
set_max_delay -datapath_only -from [get_clocks CLK125PLLTX90] -to [get_ports rgmii_txc] 4.000
set_property ASYNC_REG true [get_cells sitcp/SiTCP/GMII/GMII_TXCNT/irMacPauseExe_0]
set_property ASYNC_REG true [get_cells sitcp/SiTCP/GMII/GMII_TXCNT/irMacPauseExe_1]

# LED
# LED 0..3 are onboard LEDs: Bank 32, 33 running at 1.5 V)
set_property PACKAGE_PIN U9 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[0]}]
set_property PACKAGE_PIN V12 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[1]}]
set_property PACKAGE_PIN V13 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[2]}]
set_property PACKAGE_PIN W13 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {LED[3]}]
# LED 4..7 are LEDs on the BDAQ53 base board. They have pull-ups to 3.3 V.
set_property PACKAGE_PIN AF23 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[4]}]
set_property PACKAGE_PIN AF24 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[5]}]
set_property PACKAGE_PIN AF25 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[6]}]
set_property PACKAGE_PIN Y22 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[7]}]
set_property SLEW SLOW [get_ports LED*]

# PMOD
# ! Different to BDAQ53 (naming and pullup)
#  _______
# |0 1 2 3|  First PMOD channel (4 signal lines)
# |G_G_G_G|  Second PMOD channel (GND)
#
# PMOD connector Pin3-->PMOD3; Pin2-->PMOD2; Pin1-->PMOD1; Pin0-->PMOD0;
set_property PACKAGE_PIN W25 [get_ports {PMOD[0]}]
set_property PACKAGE_PIN W26 [get_ports {PMOD[1]}]
set_property PACKAGE_PIN U26 [get_ports {PMOD[2]}]
set_property PACKAGE_PIN V26 [get_ports {PMOD[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports PMOD*]
# Pull up the PMOD pins which are used as inputs, other pins connected to GND on PCB
set_property PULLUP true [get_ports {PMOD[3]}]
set_property PULLUP true [get_ports {PMOD[2]}]
set_property PULLUP true [get_ports {PMOD[1]}]
set_property PULLUP true [get_ports {PMOD[0]}]

# ------ Si570 / TLU RX CLK (TLU P / N inverted w.r.t Si570)
set_property PACKAGE_PIN H6 [get_ports MGT_REFCLK0_P]
set_property PACKAGE_PIN H5 [get_ports MGT_REFCLK0_N]

# ------ SMA CLK
set_property PACKAGE_PIN K6 [get_ports MGT_REFCLK1_P]
set_property PACKAGE_PIN K5 [get_ports MGT_REFCLK1_N]

# ------ Si511 (P / N inverted w.r.t. IC output)
set_property PACKAGE_PIN F6 [get_ports MGT_REFCLK3_P]
set_property PACKAGE_PIN F5 [get_ports MGT_REFCLK3_N]

# ------ CLK MUX
set_property PACKAGE_PIN AC24 [get_ports CLK_SEL]
set_property IOSTANDARD LVCMOS25 [get_ports CLK_SEL]
set_property PULLUP true [get_ports CLK_SEL]

# ------ FCLK (100 MHz)
set_property PACKAGE_PIN AA4 [get_ports FCLK_IN]
set_property IOSTANDARD LVCMOS15 [get_ports FCLK_IN]

# ------ Button & Spare & more
set_property PACKAGE_PIN AC23 [get_ports SW_RESET_B]
set_property IOSTANDARD LVCMOS25 [get_ports SW_RESET_B]
set_property PULLUP true [get_ports SW_RESET_B]

# User push button
set_property PACKAGE_PIN AC21 [get_ports SW_USER_B]
set_property IOSTANDARD LVCMOS25 [get_ports SW_USER_B]
set_property PULLUP true [get_ports SW_USER_B]

# I2C
set_property PACKAGE_PIN L23 [get_ports I2C_SCL]
set_property PACKAGE_PIN C24 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_*]
set_property SLEW SLOW [get_ports I2C_*]

# EEPROM (SPI for SiTCP)
set_property PACKAGE_PIN AF22 [get_ports EEPROM_CLK]
set_property PACKAGE_PIN AE22 [get_ports EEPROM_SK]
set_property PACKAGE_PIN AE21 [get_ports EEPROM_DI]
set_property PACKAGE_PIN AD21 [get_ports EEPROM_DO]
set_property IOSTANDARD LVCMOS25 [get_ports EEPROM_*]

# LEMO
set_property PACKAGE_PIN G11 [get_ports LEMO_TX0]
set_property PACKAGE_PIN F19 [get_ports LEMO_TX1]
set_property IOSTANDARD LVCMOS25 [get_ports LEMO_TX*]
set_property SLEW FAST [get_ports LEMO_TX*]
set_property PACKAGE_PIN F10 [get_ports LEMO_RX0]
set_property PACKAGE_PIN E20 [get_ports LEMO_RX1]
set_property IOSTANDARD LVCMOS25 [get_ports LEMO_RX*]

# TLU
# TLU RX CLK to MGT_REFCLK_0 (P / N inverted!) via CLK_SEL = 1
set_property PACKAGE_PIN C21 [get_ports TLU_SPARE_P]
set_property PACKAGE_PIN B21 [get_ports TLU_SPARE_N]
set_property PACKAGE_PIN A23 [get_ports TLU_BUSY_P]
set_property PACKAGE_PIN A24 [get_ports TLU_BUSY_N]
set_property PACKAGE_PIN B15 [get_ports TLU_CONT_P]
set_property PACKAGE_PIN A15 [get_ports TLU_CONT_N]
set_property PACKAGE_PIN B20 [get_ports TLU_TRIG_P]
set_property PACKAGE_PIN A20 [get_ports TLU_TRIG_N]
set_property PACKAGE_PIN D26 [get_ports TLU_CLK_TX_P]
set_property PACKAGE_PIN C26 [get_ports TLU_CLK_TX_N]

set_property PACKAGE_PIN V21 [get_ports TLU_SE0]
set_property PACKAGE_PIN W21 [get_ports TLU_SE1]
set_property PACKAGE_PIN V23 [get_ports TLU_SE2]

set_property IOSTANDARD LVDS_25 [get_ports TLU_SPARE_*]
set_property IOSTANDARD LVDS_25 [get_ports TLU_BUSY_*]
set_property IOSTANDARD LVDS_25 [get_ports TLU_CONT_*]
set_property IOSTANDARD LVDS_25 [get_ports TLU_TRIG_*]
set_property IOSTANDARD LVDS_25 [get_ports TLU_CLK_TX_*]
set_property IOSTANDARD LVCMOS25 [get_ports TLU_SE*]

# SITCP
set_property SLEW FAST [get_ports mdio_phy_mdc]
set_property IOSTANDARD LVCMOS25 [get_ports mdio_phy_mdc]
set_property PACKAGE_PIN B25 [get_ports mdio_phy_mdc]

set_property SLEW FAST [get_ports mdio_phy_mdio]
set_property IOSTANDARD LVCMOS25 [get_ports mdio_phy_mdio]
set_property PACKAGE_PIN B26 [get_ports mdio_phy_mdio]

set_property SLEW FAST [get_ports phy_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rst_n]
#M20 is routed to Connector C. The Ethernet PHY on th KX2 board has NO reset connection to an FPGA pin
set_property PACKAGE_PIN M20 [get_ports phy_rst_n]

set_property IOSTANDARD LVCMOS25 [get_ports rgmii_rxc]
set_property PACKAGE_PIN G22 [get_ports rgmii_rxc]

set_property IOSTANDARD LVCMOS25 [get_ports rgmii_rx_ctl]
set_property PACKAGE_PIN F23 [get_ports rgmii_rx_ctl]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[0]}]
set_property PACKAGE_PIN H23 [get_ports {rgmii_rxd[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[1]}]
set_property PACKAGE_PIN H24 [get_ports {rgmii_rxd[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[2]}]
set_property PACKAGE_PIN J21 [get_ports {rgmii_rxd[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_rxd[3]}]
set_property PACKAGE_PIN H22 [get_ports {rgmii_rxd[3]}]

set_property SLEW FAST [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS25 [get_ports rgmii_txc]
set_property PACKAGE_PIN K23 [get_ports rgmii_txc]

set_property SLEW FAST [get_ports rgmii_tx_ctl]
set_property IOSTANDARD LVCMOS25 [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN J23 [get_ports rgmii_tx_ctl]

set_property SLEW FAST [get_ports {rgmii_txd[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[0]}]
set_property PACKAGE_PIN J24 [get_ports {rgmii_txd[0]}]
set_property SLEW FAST [get_ports {rgmii_txd[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[1]}]
set_property PACKAGE_PIN J25 [get_ports {rgmii_txd[1]}]
set_property SLEW FAST [get_ports {rgmii_txd[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[2]}]
set_property PACKAGE_PIN L22 [get_ports {rgmii_txd[2]}]
set_property SLEW FAST [get_ports {rgmii_txd[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_txd[3]}]
set_property PACKAGE_PIN K22 [get_ports {rgmii_txd[3]}]

# DP ("DP0" on base board) connected to SelectIOs
set_property PACKAGE_PIN C16 [get_ports {LANE_P0}]
set_property PACKAGE_PIN B16 [get_ports {LANE_N0}]
set_property PACKAGE_PIN B17 [get_ports {LANE_P1}]
set_property PACKAGE_PIN A17 [get_ports {LANE_N1}]
set_property PACKAGE_PIN E18 [get_ports {LANE_P2}]
set_property PACKAGE_PIN D18 [get_ports {LANE_N2}]
set_property PACKAGE_PIN C19 [get_ports {LANE_P3}]
set_property PACKAGE_PIN B19 [get_ports {LANE_N3}]
set_property PACKAGE_PIN A18 [get_ports {AUX_P}]
set_property PACKAGE_PIN A19 [get_ports {AUX_N}]

set_property IOSTANDARD LVDS_25 [get_ports LANE_*]
set_property IOSTANDARD LVDS_25 [get_ports AUX_*]

#LVDS
set_property PACKAGE_PIN H17 [get_ports {LVDS_P0}]
set_property PACKAGE_PIN H18 [get_ports {LVDS_N0}]
set_property PACKAGE_PIN G19 [get_ports {LVDS_P1}]
set_property PACKAGE_PIN F20 [get_ports {LVDS_N1}]
set_property PACKAGE_PIN L19 [get_ports {LVDS_P2}]
set_property PACKAGE_PIN L20 [get_ports {LVDS_N2}]
set_property PACKAGE_PIN K20 [get_ports {LVDS_P3}]
set_property PACKAGE_PIN J20 [get_ports {LVDS_N3}]
set_property PACKAGE_PIN M17 [get_ports {LVDS_P4}]
set_property PACKAGE_PIN L18 [get_ports {LVDS_N4}]
set_property PACKAGE_PIN L17 [get_ports {LVDS_P5}]
set_property PACKAGE_PIN K18 [get_ports {LVDS_N5}]
set_property PACKAGE_PIN K16 [get_ports {LVDS_P6}]
set_property PACKAGE_PIN K17 [get_ports {LVDS_N6}]
set_property PACKAGE_PIN J18 [get_ports {LVDS_P7}]
set_property PACKAGE_PIN J19 [get_ports {LVDS_N7}]
set_property PACKAGE_PIN H19 [get_ports {LVDS_P8}]
set_property PACKAGE_PIN G20 [get_ports {LVDS_N8}]
set_property PACKAGE_PIN D19 [get_ports {LVDS_P9}]
set_property PACKAGE_PIN D20 [get_ports {LVDS_N9}]
set_property PACKAGE_PIN G17 [get_ports {LVDS_P10}]
set_property PACKAGE_PIN F18 [get_ports {LVDS_N10}]
set_property PACKAGE_PIN C17 [get_ports {LVDS_P11}]
set_property PACKAGE_PIN C18 [get_ports {LVDS_N11}]
set_property PACKAGE_PIN C14 [get_ports {LVDS_P12}]
set_property PACKAGE_PIN C13 [get_ports {LVDS_N12}]
set_property PACKAGE_PIN D14 [get_ports {LVDS_P13}]
set_property PACKAGE_PIN D13 [get_ports {LVDS_N13}]
set_property PACKAGE_PIN J13 [get_ports {LVDS_P14}]
set_property PACKAGE_PIN H13 [get_ports {LVDS_N14}]
set_property PACKAGE_PIN F14 [get_ports {LVDS_P15}]
set_property PACKAGE_PIN F13 [get_ports {LVDS_N15}]
set_property PACKAGE_PIN E13 [get_ports {LVDS_P16}]
set_property PACKAGE_PIN E12 [get_ports {LVDS_N16}]
set_property PACKAGE_PIN G12 [get_ports {LVDS_P17}]
set_property PACKAGE_PIN F12 [get_ports {LVDS_N17}]
set_property PACKAGE_PIN J11 [get_ports {LVDS_P18}]
set_property PACKAGE_PIN J10 [get_ports {LVDS_N18}]
set_property PACKAGE_PIN H12 [get_ports {LVDS_P19}]
set_property PACKAGE_PIN H11 [get_ports {LVDS_N19}]
set_property PACKAGE_PIN G10 [get_ports {LVDS_P20}]
set_property PACKAGE_PIN G9 [get_ports {LVDS_N20}]
set_property PACKAGE_PIN E11 [get_ports {LVDS_P21}]
set_property PACKAGE_PIN D11 [get_ports {LVDS_N21}]
set_property PACKAGE_PIN A13 [get_ports {LVDS_P22}]
set_property PACKAGE_PIN A12 [get_ports {LVDS_N22}]
set_property PACKAGE_PIN B10 [get_ports {LVDS_P23}]
set_property PACKAGE_PIN A10 [get_ports {LVDS_N23}]

set_property IOSTANDARD LVDS_25 [get_ports LVDS_*]

# LVCMOS
set_property PACKAGE_PIN B12 [get_ports {LVCMOS0}]
set_property PACKAGE_PIN B11 [get_ports {LVCMOS1}]
set_property PACKAGE_PIN H14 [get_ports {LVCMOS2}]
set_property PACKAGE_PIN G14 [get_ports {LVCMOS3}]
set_property PACKAGE_PIN C12 [get_ports {LVCMOS4}]
set_property PACKAGE_PIN C11 [get_ports {LVCMOS5}]
set_property PACKAGE_PIN B14 [get_ports {LVCMOS6}]
set_property PACKAGE_PIN A14 [get_ports {LVCMOS7}]

set_property IOSTANDARD LVCMOS25 [get_ports {LVCMOS*}]

#CMOS
set_property PACKAGE_PIN V24 [get_ports {CMOS0}]
set_property PACKAGE_PIN Y26 [get_ports {CMOS1}]
set_property PACKAGE_PIN AA24 [get_ports {CMOS2}]
set_property PACKAGE_PIN Y23 [get_ports {CMOS3}]
set_property PACKAGE_PIN Y25 [get_ports {CMOS4}]
set_property PACKAGE_PIN Y20 [get_ports {CMOS5}]
set_property PACKAGE_PIN U21 [get_ports {CMOS6}]
set_property PACKAGE_PIN AE26 [get_ports {CMOS7}]
set_property PACKAGE_PIN AD26 [get_ports {CMOS8}]
set_property PACKAGE_PIN AB25 [get_ports {CMOS9}]
set_property PACKAGE_PIN W24 [get_ports {CMOS10}]
set_property PACKAGE_PIN W23 [get_ports {CMOS11}]
set_property PACKAGE_PIN V22 [get_ports {CMOS12}]
set_property PACKAGE_PIN U22 [get_ports {CMOS13}]
set_property PACKAGE_PIN AD24 [get_ports {CMOS14}]
set_property PACKAGE_PIN AD23 [get_ports {CMOS15}]
set_property PACKAGE_PIN U25 [get_ports {CMOS16}]
set_property PACKAGE_PIN AE25 [get_ports {CMOS17}]
set_property PACKAGE_PIN AD25 [get_ports {CMOS18}]
set_property PACKAGE_PIN AA22 [get_ports {CMOS19}]
set_property PACKAGE_PIN U24 [get_ports {CMOS20}]
set_property PACKAGE_PIN AB21 [get_ports {CMOS21}]

set_property IOSTANDARD LVCMOS25 [get_ports {CMOS*}]

# NTC_MUX
set_property PACKAGE_PIN AE23 [get_ports {NTC_MUX[0]}]
set_property PACKAGE_PIN AC22 [get_ports {NTC_MUX[1]}]
set_property PACKAGE_PIN AB22 [get_ports {NTC_MUX[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {NTC_MUX*}]
set_property SLEW SLOW [get_ports NTC*]

# SPI configuration flash
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
