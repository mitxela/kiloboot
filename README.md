# kiloboot
1kB TFTP Ethernet bootloader for ATmega328P and ENC28J60

Main writeup and lots more info here: https://mitxela.com/projects/kiloboot

You will need an ATmega328p and an ENC28J60, wired up as follows:

`PB1 <--> INT (optional)`  
`PB2 <--> CS`  
`PB3 <--> MOSI`  
`PB4 <--> MISO`  
`PB5 <--> SCK`  

I've only tested this with the ATmega chip running at 16MHz. Running faster than that, you may need to alter the wait routine, and possibly the SPI prescaler. If anyone wants help porting this to another chip, let me know.

I've included a compiled hex file, which if you're planning to use the EEPROM settings, may be usable without changing the config. 

By default, the bootloader will try to load the settings from the EEPROM, but if it's empty, it will use the hard-coded backup settings. The first few lines of the .asm file are the configuration. You need to give it a MAC address, an IP address, the addresses of the TFTP server, default gateway and the subnet mask. If you want it to have hard-coded settings, and you're using this on a home router with NAT, it's easiest to check the router settings to see what the DHCP pool is, and give the device an IP outside of that range. 

You can optionally change the filename that it requests, this can be up to 31 chars. You can also set the number of reattempts if it can't immediately contact the server. Just after powering on, it may take a few seconds for the ethernet link to establish, so the first few packets may be lost. But too many reattempts means a longer delay before giving up and starting the old application, if the server is actually unavailable. 

To use the EEPROM settings, simply fill in the first 16 bytes of the EEPROM with the device IP, server IP, default gateway IP and subnet mask, in that order. You could do this by creating a binary file in a hex editor and writing it to the EEPROM using avrdude, eg `-U eeprom:w:"IPs.bin":r`  with the 'r' type for raw binary. You could also do this by adding an .eseg section to the assembly file which should produce an .eep file in hex format. But the main anticipated method of setting the EEPROM addresses is by writing to them from the application itself, for instance, if it's running a DHCP client. 

Beware, if your application uses the EEPROM for something else, the bootloader has no way of knowing if the data there is valid, it only checks that it's not erased. If you don't want to use the EEPROM for these settings, I would recommend disabling it.

If you've never used AVR assembler before, I think the easiest way to build is to use AVR Studio (or Atmel Studio, as the later versions are called). You can simply select new project, 8-bit AVR assembly. The single .asm file is all you need, there are no dependencies. You can also assemble from the command line with something like

`avrasm2 -fI -o "kiloboot.hex" kiloboot.asm`

You then need to burn this hex file onto the chip and set the correct fuses. The important one is to set the high fuse to 0xDC, with the avrdude command `-U hfuse:w:0xdc:m` This configures the reset vector and the bootloader section to be 512 words.

Next you need to set up a TFTP server. For windows I recommend tftpd32, for linux I used tftpd-hpa. It's straight forward if you only want to boot from the local network, but making the server publicly accessible is not trivial. See my description [here](https://mitxela.com/projects/kiloboot#tftp-server).

The server needs to host a binary image of your application, not an intel hex file. There will be an option to configure your compiler to output a binary file, but if you've already produced a hex file, you can convert it using objcopy:

`avr-objcopy.exe -I ihex program.hex -O binary program.bin`

The last consideration is triggering the bootloader. This is up to your application to manage. The bootloader will run once on powerup, and after each reset, but not while the application is running. The two obvious methods would be to either run the bootloader on a timer, or have some user-driven aspect of the application trigger it. For the timer, beware that if the server is unavailable, it has to wait the full timeout period (default is 16 seconds) before returning to the application. If the server is up, the whole download should take a split second as it's only a few kB. If the file hasn't changed, it's still downloaded but not written to flash, to avoid unnecessary wear.  

I think the simplest way to jump to the bootloader in C would be 

`asm("jmp 0x3e00");`

There's probably a fancy C way of doing it, but this is the only way to be certain of what it's generating.

## Update
The INT pin is no longer needed in this version. If you uncomment line 19 to define INT_PIN it will conditionally assemble to be identical to the first version. Assembling the INT-free version is 16 bytes longer than the original, so the maximum filename length is now 19 bytes. Some more bytes could be freed up by not configuring the LEDs. 

I also added a define to make it easier to change the pin used for CS, any unused pin on PORTB should work just by changing the define. 
