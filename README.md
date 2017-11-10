# kiloboot
1kB TFTP Ethernet bootloader for ATmega328P and ENC28J60

## Custom MAC address and Bootskip flag branch

This is a specific branch of the kiloboot project, see the master branch for more info about kiloboot. It adds some different features, at the expensive of hard-coding the subnet mask. 

Main writeup and lots more info here: https://mitxela.com/projects/kiloboot

### Changes from master

- The subnet mask is now hard coded to be `255.255.255.0`. This frees up some space.
- The first two bytes of EEPROM after the gateway IP now represent the last two bytes of the MAC address. This allows automatic configuration in an environment where hundreds of boards are all running kiloboot.
- The twelfth byte of EEPROM, which used to be the last byte of the subnet mask, is now the boot skip flag, set it to 1 to skip the bootloader, 0 to run the bootloader.