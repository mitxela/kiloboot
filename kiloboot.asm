.include "m328pdef.inc"

; 512-word TFTP ethernet bootloader
; written by mitxela
; mitxela.com/projects/kiloboot

; For ATmega328p and ENC28J60 

; Wiring: 
; SPI pins are enforced by hardware and cannot be changed.
; PB3 MOSI
; PB4 MISO
; PB5 SCK

; CS, INT pins can be trivially changed here to any unused pin on PORTB
#define CS_PIN PB2

; Leave INT_PIN undefined to detect received packets by polling EPKTCNT 
;#define INT_PIN PB1


; First byte of the MAC address must be an even number
; (LSB of MAC0 is a flag for "broadcast address")
.equ myMAC0 = 0x04
.equ myMAC1 = 0x02
.equ myMAC2 = 0x03
.equ myMAC3 = 0x04
.equ myMAC4 = 0x05
.equ myMAC5 = 0x06

#define FILENAME "program.bin"
#define MAX_REATTEMPTS 3

; Hard coded fallback addresses. If EEPROM is empty, use these instead.
; Note: comma separated, not dots!
#define myIP        192,168,1,22
#define serverIP    192,168,1,23
#define gatewayIP   192,168,1,254
#define subnetMask  255,255,255,0


;//////////////////////////////////////////////////////////////


; My IP
.def rMyIP0 = r0
.def rMyIP1 = r1
.def rMyIP2 = r2
.def rMyIP3 = r3
; TFTP server address
.def rSvIP0 = r4
.def rSvIP1 = r5
.def rSvIP2 = r6
.def rSvIP3 = r7
; Default Gateway IP
.def rGwIP0 = r8
.def rGwIP1 = r9
.def rGwIP2 = r10
.def rGwIP3 = r11
; Subnet Mask
.def rSubMask0 = r12
.def rSubMask1 = r13
.def rSubMask2 = r14
.def rSubMask3 = r15



; ENC28J60 definitions

; SPI operation codes
.equ ENC28J60_READ_CTRL_REG      = 0x00
.equ ENC28J60_READ_BUF_MEM       = 0x3A
.equ ENC28J60_WRITE_CTRL_REG     = 0x40
.equ ENC28J60_WRITE_BUF_MEM      = 0x7A
.equ ENC28J60_BIT_FIELD_SET      = 0x80
.equ ENC28J60_BIT_FIELD_CLR      = 0xA0
.equ ENC28J60_SOFT_RESET         = 0xFF

; All-bank registers 
.equ EIE            = 0x1B
.equ EIR            = 0x1C
.equ ESTAT          = 0x1D
.equ ECON2          = 0x1E
.equ ECON1          = 0x1F
; Bank 0 registers   
.equ ERDPTL         = (0x00|0x00)
.equ ERDPTH         = (0x01|0x00)
.equ EWRPTL         = (0x02|0x00)
.equ EWRPTH         = (0x03|0x00)
.equ ETXSTL         = (0x04|0x00)
.equ ETXSTH         = (0x05|0x00)
.equ ETXNDL         = (0x06|0x00)
.equ ETXNDH         = (0x07|0x00)
.equ ERXSTL         = (0x08|0x00)
.equ ERXSTH         = (0x09|0x00)
.equ ERXNDL         = (0x0A|0x00)
.equ ERXNDH         = (0x0B|0x00)
.equ ERXRDPTL       = (0x0C|0x00)
.equ ERXRDPTH       = (0x0D|0x00)
.equ ERXWRPTL       = (0x0E|0x00)
.equ ERXWRPTH       = (0x0F|0x00)
.equ EDMASTL        = (0x10|0x00)
.equ EDMASTH        = (0x11|0x00)
.equ EDMANDL        = (0x12|0x00)
.equ EDMANDH        = (0x13|0x00)
.equ EDMADSTL       = (0x14|0x00)
.equ EDMADSTH       = (0x15|0x00)
.equ EDMACSL        = (0x16|0x00)
.equ EDMACSH        = (0x17|0x00)
; Bank 1 registers   
.equ EHT0           = (0x00|0x20)
.equ EHT1           = (0x01|0x20)
.equ EHT2           = (0x02|0x20)
.equ EHT3           = (0x03|0x20)
.equ EHT4           = (0x04|0x20)
.equ EHT5           = (0x05|0x20)
.equ EHT6           = (0x06|0x20)
.equ EHT7           = (0x07|0x20)
.equ EPMM0          = (0x08|0x20)
.equ EPMM1          = (0x09|0x20)
.equ EPMM2          = (0x0A|0x20)
.equ EPMM3          = (0x0B|0x20)
.equ EPMM4          = (0x0C|0x20)
.equ EPMM5          = (0x0D|0x20)
.equ EPMM6          = (0x0E|0x20)
.equ EPMM7          = (0x0F|0x20)
.equ EPMCSL         = (0x10|0x20)
.equ EPMCSH         = (0x11|0x20)
.equ EPMOL          = (0x14|0x20)
.equ EPMOH          = (0x15|0x20)
.equ EWOLIE         = (0x16|0x20)
.equ EWOLIR         = (0x17|0x20)
.equ ERXFCON        = (0x18|0x20)
.equ EPKTCNT        = (0x19|0x20)
; Bank 2 registers   
.equ MACON1         = (0x00|0x40|0x80)
.equ MACON2         = (0x01|0x40|0x80)
.equ MACON3         = (0x02|0x40|0x80)
.equ MACON4         = (0x03|0x40|0x80)
.equ MABBIPG        = (0x04|0x40|0x80)
.equ MAIPGL         = (0x06|0x40|0x80)
.equ MAIPGH         = (0x07|0x40|0x80)
.equ MACLCON1       = (0x08|0x40|0x80)
.equ MACLCON2       = (0x09|0x40|0x80)
.equ MAMXFLL        = (0x0A|0x40|0x80)
.equ MAMXFLH        = (0x0B|0x40|0x80)
.equ MAPHSUP        = (0x0D|0x40|0x80)
.equ MICON          = (0x11|0x40|0x80)
.equ MICMD          = (0x12|0x40|0x80)
.equ MIREGADR       = (0x14|0x40|0x80)
.equ MIWRL          = (0x16|0x40|0x80)
.equ MIWRH          = (0x17|0x40|0x80)
.equ MIRDL          = (0x18|0x40|0x80)
.equ MIRDH          = (0x19|0x40|0x80)
; Bank 3 registers   
.equ MAADR1         = (0x00|0x60|0x80)
.equ MAADR0         = (0x01|0x60|0x80)
.equ MAADR3         = (0x02|0x60|0x80)
.equ MAADR2         = (0x03|0x60|0x80)
.equ MAADR5         = (0x04|0x60|0x80)
.equ MAADR4         = (0x05|0x60|0x80)
.equ EBSTSD         = (0x06|0x60)
.equ EBSTCON        = (0x07|0x60)
.equ EBSTCSL        = (0x08|0x60)
.equ EBSTCSH        = (0x09|0x60)
.equ MISTAT         = (0x0A|0x60|0x80)
.equ EREVID         = (0x12|0x60)
.equ ECOCON         = (0x15|0x60)
.equ EFLOCON        = (0x17|0x60)
.equ EPAUSL         = (0x18|0x60)
.equ EPAUSH         = (0x19|0x60)
; PHY registers      
.equ PHCON1         = 0x00
.equ PHSTAT1        = 0x01
.equ PHHID1         = 0x02
.equ PHHID2         = 0x03
.equ PHCON2         = 0x10
.equ PHSTAT2        = 0x11
.equ PHIE           = 0x12
.equ PHIR           = 0x13
.equ PHLCON         = 0x14

; ENC28J60 ERXFCON Register Bit Definitions
.equ ERXFCON_UCEN   = 0x80
.equ ERXFCON_ANDOR  = 0x40
.equ ERXFCON_CRCEN  = 0x20
.equ ERXFCON_PMEN   = 0x10
.equ ERXFCON_MPEN   = 0x08
.equ ERXFCON_HTEN   = 0x04
.equ ERXFCON_MCEN   = 0x02
.equ ERXFCON_BCEN   = 0x01
; ENC28J60 EIE Register Bit Definitions
.equ EIE_INTIE      = 0x80
.equ EIE_PKTIE      = 0x40
.equ EIE_DMAIE      = 0x20
.equ EIE_LINKIE     = 0x10
.equ EIE_TXIE       = 0x08
.equ EIE_WOLIE      = 0x04
.equ EIE_TXERIE     = 0x02
.equ EIE_RXERIE     = 0x01
; ENC28J60 EIR Register Bit Definitions
.equ EIR_PKTIF      = 0x40
.equ EIR_DMAIF      = 0x20
.equ EIR_LINKIF     = 0x10
.equ EIR_TXIF       = 0x08
.equ EIR_WOLIF      = 0x04
.equ EIR_TXERIF     = 0x02
.equ EIR_RXERIF     = 0x01
; ENC28J60 ESTAT Register Bit Definitions
.equ ESTAT_INT      = 0x80
.equ ESTAT_LATECOL  = 0x10
.equ ESTAT_RXBUSY   = 0x04
.equ ESTAT_TXABRT   = 0x02
.equ ESTAT_CLKRDY   = 0x01
; ENC28J60 ECON2 Register Bit Definitions
.equ ECON2_AUTOINC  = 0x80
.equ ECON2_PKTDEC   = 0x40
.equ ECON2_PWRSV    = 0x20
.equ ECON2_VRPS     = 0x08
; ENC28J60 ECON1 Register Bit Definitions
.equ ECON1_TXRST    = 0x80
.equ ECON1_RXRST    = 0x40
.equ ECON1_DMAST    = 0x20
.equ ECON1_CSUMEN   = 0x10
.equ ECON1_TXRTS    = 0x08
.equ ECON1_RXEN     = 0x04
.equ ECON1_BSEL1    = 0x02
.equ ECON1_BSEL0    = 0x01
; ENC28J60 MACON1 Register Bit Definitions
.equ MACON1_LOOPBK  = 0x10
.equ MACON1_TXPAUS  = 0x08
.equ MACON1_RXPAUS  = 0x04
.equ MACON1_PASSALL = 0x02
.equ MACON1_MARXEN  = 0x01
; ENC28J60 MACON2 Register Bit Definitions
.equ MACON2_MARST   = 0x80
.equ MACON2_RNDRST  = 0x40
.equ MACON2_MARXRST = 0x08
.equ MACON2_RFUNRST = 0x04
.equ MACON2_MATXRST = 0x02
.equ MACON2_TFUNRST = 0x01
; ENC28J60 MACON3 Register Bit Definitions
.equ MACON3_PADCFG2 = 0x80
.equ MACON3_PADCFG1 = 0x40
.equ MACON3_PADCFG0 = 0x20
.equ MACON3_TXCRCEN = 0x10
.equ MACON3_PHDRLEN = 0x08
.equ MACON3_HFRMLEN = 0x04
.equ MACON3_FRMLNEN = 0x02
.equ MACON3_FULDPX  = 0x01
; ENC28J60 MICMD Regster Bit Definitions
.equ MICMD_MIISCAN  = 0x02
.equ MICMD_MIIRD    = 0x01
; ENC28J60 MISTAT Register Bit Definitions
.equ MISTAT_NVALID  = 0x04
.equ MISTAT_SCAN    = 0x02
.equ MISTAT_BUSY    = 0x01
; ENC28J60 PHY PHCON1 Register Bit Definitions
.equ PHCON1_PRST    = 0x8000
.equ PHCON1_PLOOPBK = 0x4000
.equ PHCON1_PPWRSV  = 0x0800
.equ PHCON1_PDPXMD  = 0x0100
; ENC28J60 PHY PHSTAT1 Register Bit Definitions
.equ PHSTAT1_PFDPX  = 0x1000
.equ PHSTAT1_PHDPX  = 0x0800
.equ PHSTAT1_LLSTAT = 0x0004
.equ PHSTAT1_JBSTAT = 0x0002
; ENC28J60 PHY PHCON2 Register Bit Definitions
.equ PHCON2_FRCLINK = 0x4000
.equ PHCON2_TXDIS   = 0x2000
.equ PHCON2_JABBER  = 0x0400
.equ PHCON2_HDLDIS  = 0x0100

; ENC28J60 Packet Control Byte Bit Definitions
.equ PKTCTRL_PHUGEEN    = 0x08
.equ PKTCTRL_PPADEN     = 0x04
.equ PKTCTRL_PCRCEN     = 0x02
.equ PKTCTRL_POVERRIDE  = 0x01


.equ MAX_FRAMELEN    = 580


#define ctrlReg(addr)    ENC28J60_WRITE_CTRL_REG | (addr & 0x1F)
#define readCtrlReg(addr) ENC28J60_READ_CTRL_REG | (addr & 0x1F)
#define setBF(addr)       ENC28J60_BIT_FIELD_SET | (addr & 0x1F)
#define clrBF(addr)       ENC28J60_BIT_FIELD_CLR | (addr & 0x1F)




.dseg
packetBuffer: 
  destMAC:   .byte 6
  sourceMAC: .byte 6
  ethType:   .byte 2
    ethPayload: .byte 568

.cseg


.org 0x3e00 ; 1kB from the end

; Mostly redunant reset code. The bootloader may be started by a jump from 
; the main application, so disable interrupts and reset the stack.
; Power-on and watchdog reset does this automatically
    cli
    ldi r16,low(RAMEND)
    out SPL,r16
    ldi r16,high(RAMEND)
    out SPH,r16


    rcall loadIPs

; is the server on same subnet as me?

    and rMyIP0, rSubMask0
    and rMyIP1, rSubMask1
    and rMyIP2, rSubMask2
    and rMyIP3, rSubMask3

    and rSvIP0, rSubMask0
    and rSvIP1, rSubMask1
    and rSvIP2, rSubMask2
    and rSvIP3, rSubMask3

    cp  rMyIP0, rSvIP0
    cpc rMyIP1, rSvIP1
    cpc rMyIP2, rSvIP2
    cpc rMyIP3, rSvIP3
    in r19, SREG  ; store result of comparison
    rcall loadIPs ; undo the ANDing
    out SREG, r19
    brne differentSubnets

    ; rGwIP is the IP we send ARP request for
    ; If on the same subnet, send ARP for server IP instead
    movw rGwIP1:rGwIP0,rSvIP1:rSvIP0
    movw rGwIP3:rGwIP2,rSvIP3:rSvIP2

differentSubnets:





; ephemeral port counter. Don't initialize, will hold value after reset.
.def ephReg = r22
.def attempts = r23

.undef rSubMask0
.undef rSubMask1
.undef rSubMask2
.undef rSubMask3
.def nextPacketL = r14
.def nextPacketH = r15
.def zeroReg = r13

    

    clr nextPacketL
    clr nextPacketH
    clr zeroReg


; Limit range to avoid having to do 16bit calcs where possible
    andi ephReg, $3F


#ifdef DEBUG
    ldi r16, 1<<PD1
    out DDRD,r16

    ldi r16,0
    sts UBRR0H, r16
    ldi r16,3
    sts UBRR0L, r16
    ldi r16, (1<<TXEN0)
    sts UCSR0B,r16
    ldi r16, (3<<UCSZ00)
    sts UCSR0C,r16

    ldi r16, 'X'
    rcall UARTsend
#endif


  in r16, MCUSR
  sbrs r16,WDRF
    clr attempts ; this will only run on power on / external reset

handleWatchdog:
  wdr
  out MCUSR, zeroReg

  ldi r18, MAX_REATTEMPTS
  clr r17 ; disable watchdog if about to give up

  ldi r16, (1<<WDCE) | (1<<WDE)
  cpse attempts, r18
  ldi r17, (1<<WDE) | (1<<WDP3) ; 4s
  
  sts WDTCSR, r16
  sts WDTCSR, r17

  cpi attempts, MAX_REATTEMPTS
  brne dontgiveup
  
;  t: rjmp t ;hang

; Run application, run!
  jmp 0

  
  
dontgiveup:
  inc attempts


  inc ephReg ; Count number of resets since power on

  ldi r16, (1<<CS_PIN)|(1<<PB2)|(1<<PB3)|(1<<PB5)
  out DDRB,r16
  sbi PORTB,CS_PIN

#ifdef INT_PIN
  sbi PORTB,INT_PIN
#endif

; Init SPI
  ldi r16,(1<<SPE)|(1<<MSTR)
  out SPCR,r16
  ldi r16,(1<<SPI2X)
  out SPSR,r16





; enc28j60 startup

  ldi r16,ENC28J60_SOFT_RESET
  ldi r17,0
  rcall enc28j60write


; wait for startup time ~300ms
  ldi xh, 32
waitStartupTime:
  rcall wait2
  sbiw x,1
  brne waitStartupTime


  ldi ZL, low(initCode*2)
  ldi ZH, high(initCode*2)
  ldi r20, (initCodeEnd - initCode) ;length in words

loadParams:
  lpm r16,Z+
  lpm r17,Z+
  rcall enc28j60write
  rcall wait2
  dec r20
  brne loadParams
  





;findGateway:

    ldi YH, HIGH(packetBuffer)
    ldi YL,  LOW(packetBuffer)
    ldi r16,12
    ldi r17,$ff ; FFReg?
arpBroadcastFill:
    std Y+32, zeroReg
    st Y+,r17
    dec r16
    brne arpBroadcastFill
    ;ldi ZL, LOW()
    ;ldi ZH, HIGH() ; data is immediately after loadparams
    
    ldi r17, 16
    rcall loadPMtoSRAM
    rcall writeIPtoSram
    adiw Y,6
    ; now load gateway IP
    st Y+,rGwIP0
    st Y+,rGwIP1
    st Y+,rGwIP2
    st Y+,rGwIP3


    ldi r19, 42
    rcall transmitPacket

waitForArpResponse:
    rcall readPacket
    cpi r19, $08        ; maybe put brne readPacket in the subroutine?
    brne waitForArpResponse
    cpi r20, $06
    brne waitForArpResponse

    adiw Y,14 

    movw r17:r16, rGwIP1:rGwIP0
    rcall cpMem2
    movw r17:r16, rGwIP3:rGwIP2
    rcall cpMem2c

    brne waitForArpResponse

    ; note - this may have been an ARP request from the gateway looking for someone else, but it's still valid
    ; We now have the mac address for the gateway IP.

    ; last z operation was loading myMAC, in transmit subroutine
    ; z is now pointing at IPprototype
    
    ; Y needs to rewind to eth type
    sbiw Y, 20
    ldi r17, 12
    rcall loadPMtoSRAM

; Work out the constant part of the checksum
#define IPmsg1ChecksumA (($45+$e6+$40+$40)<<8) + $11 + low(37+strlen(FILENAME))
#define IPmsg1ChecksumB (lwrd(IPmsg1ChecksumA) + byte3(IPmsg1ChecksumA))
#define IPmsg1Checksum ~(lwrd(IPmsg1ChecksumB) + byte3(IPmsg1ChecksumB))

    ldi r25, high(IPmsg1Checksum)
    ldi r24,  low(IPmsg1Checksum)

    sub r24, rMyIP1
    sbc r25, rMyIP0
    sbc r24, rMyIP3
    sbc r25, rMyIP2
    sbc r24, rSvIP1
    sbc r25, rSvIP0
    sbc r24, rSvIP3
    sbc r25, rSvIP2
    sbc r24, ephReg ; 0:ephReg is IP ID field
    sbc r25, zeroReg
    sbc r24, zeroReg
    
    st Y+, r25
    st Y+, r24

    rcall writeIPtoSram ; source IP
    st Y+,rSvIP0  ; destination IP
    st Y+,rSvIP1
    st Y+,rSvIP2
    st Y+,rSvIP3

    ldi r17, (17+strlen(FILENAME)) ; rest of the preformed packet
    rcall loadPMtoSRAM
    
    sbiw Y, (32+strlen(FILENAME)) ; move to IP ID low byte
    st Y, ephReg
    std Y+16, ephReg ; UDP source port (is also transaction ID for tftp)

    ldi r19, (51 + strlen(FILENAME))
    rcall transmitPacket
    




main:
    
    rcall readPacket
; check packet length? otherwise, no point filtering for packet length in readPacket


  ;  ARP eth type is 0x0806
  ; IPv4 eth type is 0x0800

    cpi r19, $08
    brne main ; Not Arp or Ip - ignore completely.
    
    cpi r20,$06
    brne packetIsNotARP
    

    ;Should we check the hardware and protocol type and length bytes?

    adiw Y,24 ; move ahead to  dest ip field
    
    rcall isItMyIP
    brne main

    sbiw Y, 21 ; rewind to the req/resp field
    ld r16,Y
    cpi r16, 1 ; 1=request, 2=reply
    brne main

    ldi r16,2
    st Y+,r16 ; write response
    ; Swap  source/dest mac & ip addresses
    ldi XH, HIGH(ethPayload + 18)
    ldi XL,  LOW(ethPayload + 18)
    ldi r18,10
    rcall swapData
    
    sbiw Y, 10
    rcall writeMacToSram

    ldi r19,42-1
    rcall transmitPacket
backToMain:
    rjmp main



packetIsNotARP:
    cpi r20,$00
    brne backToMain ; not IPv4

    adiw Y,16 ; move ahead to  dest ip field
    
    rcall isItMyIP
    brne backToMain


    ; Swap source/dest ip addresses
    sbiw Y, 4
    ldi XH, HIGH(ethPayload + 12)
    ldi XL,  LOW(ethPayload + 12)
    ldi r18,4
    rcall swapData


    ;ip type
    sbiw X,7
    ld r16,X
/*
////// uncomment for ICMP echo ///////

    cpi r16,$01
    brne notICMP
        
    ;is it echo request?
    ld r16,Y
    cpi r16,$08
    brne backToMain

    ; zero the type to turn it into a response
    st Y, zeroReg
    
    ;checksum will only have changed by 8, so add it on.
    ldd XL, Y+2 ; high byte
    ldd XH, Y+3 ; low byte, for wrapping carry
    adiw X, 8
    adc XL, zeroReg ; carry again, in case checksum was near 0xffff
    std Y+2, XL
    std Y+3, XH

    mov r19, r24 ; packet length
    rcall transmitPacket ; or rjmp?
    rjmp main

notICMP:*/
    cpi r16,$11
    brne backToMain ; not UDP

    ldd r16, Y+9
    cpi r16,$03 ; is it tftp opcode 03 = data?  
    ldd r16,Y+3
    cpc r16,ephReg ;is it our current port number? 
    brne backToMain

    ; It's a UDP message with the right port number/transaction id. 
    ; should we check it's from the right source IP? 

    ; swap port numbers
    adiw X, 13
    ldi r18,2
    rcall swapData

    ; X is now pointing to the UDP length field
    ld r25,X+
    ld r24,X+
    sbiw r25:r24, 12 ; remove UDP header



; send ACK
;opcode = 04
    ldi r16,$04
    std Y+7,r16
;udp length = 0c
    ldi r16,$0c
    std Y+3,r16
    std Y+2,zeroReg
;zero udp checksum
    std Y+4,zeroReg
    std Y+5,zeroReg
;ip length = $00,$20
    sbiw Y,20
    st Y,zeroReg
    ldi r16, $20
    std Y+1, r16
;correct ip checksum (add r25:r24)
    ldd XH, Y+8 
    ldd XL, Y+9 
    add XL, r24
    adc XH, r25
    adc XL, zeroReg
    std Y+9, XL
    std Y+8, XH

    adiw Y,29
    ld ZH,Y+;block number
    ; Y now points to first byte of data.

    cpi ZH, 63  ; ignore block numbers above 62 = 31kB
    brcc skipSPM 

    dec ZH   ; block number starts at 1
    lsl ZH   ; blocks are 512 bytes
    clr ZL
    ; Z now points to the first page of this block
  
    sbiw r25:r24, 0 ; test zero
    breq skipSPM

    ; check existing data against new data, avoid rewriting if possible
    mov r19,ZH
    subi r19,-2 ; count 512 bytes
checkDataLoop:
    lpm r20, Z+
    ld r17, Y+
    cpse r17,r20
    ldi r16,0       ; we know that r16 is non-zero at this point
    cp ZH,r19
    brne checkDataLoop
    tst r16
    breq dataDifferent
    rjmp skipSPM

dataDifferent:
    subi ZH,2
    subi YH,2

    ; One we've started writing to PM, we don't want
    ; to give up, even if it times out
    ldi attempts, MAX_REATTEMPTS+1

    rcall SPMfourpages
    

skipSPM:
    ; send ACK
    ldi r19,46
    rcall transmitPacket

    ; if r25:r24 != 512, end loading seq

    cpi r25, $02
    cpc r24, zeroReg
    ;brne tftpDataEnd
    brne noMoreData
    rjmp main

noMoreData:
    ; reuse attempt code to disable watchdog and jmp 0.
    ldi attempts, MAX_REATTEMPTS
    rjmp handleWatchdog

    ; the end!









SPMfourpages:
    rcall SPMtwopages
SPMtwopages:
    rcall SPMwritePage

; Z =  page of PM to write
; Y = SRAM with data to write

SPMwritePage:
  ; Page Erase
  ldi r16, (1<<PGERS)|(1<<SPMEN)
  rcall doSPM
  rcall SPMenableRWW

  ; ATmega328p page size = 64 words = 128 bytes
  ldi r18, 64
  movw XH:XL, r1:r0 ; save r0,r1

SPMwritePageLoop:
  ld r0, Y+
  ld r1, Y+

  ldi r16, (1<<SPMEN)
  rcall doSPM
  adiw ZH:ZL, 2

  dec r18
  brne SPMwritePageLoop
  
  subi ZL, 128
  sbci ZH, 0

  ; Execute page write
  ldi r16, (1<<PGWRT)|(1<<SPMEN)
  rcall doSPM

  subi ZL, -128
  sbci ZH, -1

  movw r1:r0, XH:XL ;restore r0,r1

SPMenableRWW:
  ldi r16, (1<<RWWSRE)|(1<<SPMEN)
  rcall doSPM  
  ret


doSPM:
  in r17, SPMCSR
  sbrc r17, SPMEN
  rjmp doSPM

  out SPMCSR, r16
  spm

  ret








; length = r19+1...  will we want to transmit bigger packets than 255 bytes?
transmitPacket:
    wdr
#ifdef DEBUG
    ldi r16,13
    rcall UARTsend
    ldi r16,'T'
    rcall UARTsend
    ldi r16,' '
    rcall UARTsend  
#endif

    ;Check no transmit in progress
waitForTransmitReady:
    clr r17 ; write zero does a read
    ldi r16, readCtrlReg(ECON1)
    rcall enc28j60write
    sbrs r16, 3 ; ECON1_TXRTS
    rjmp startTransmit
        
    ldi r16, readCtrlReg(EIR)
    rcall enc28j60write
    sbrs r16, 1 ;EIR_TXERIF
    rjmp waitForTransmitReady

    ; Reset transmit logic
    ldi r16, setBF(ECON1)
    ldi r17, ECON1_TXRST
    rcall enc28j60write
    ldi r16, clrBF(ECON1)
    ;ldi r17, ECON1_TXRST
    rcall enc28j60write

    rjmp waitForTransmitReady

startTransmit:


; Set the write pointer to start of transmit buffer area
  ldi r16, ctrlReg(EWRPTL)
  ldi r17, LOW(0x1FFF-0x0600)
  ldi r18, HIGH(0x1FFF-0x0600)
  rcall enc28j60writeWord

  ; Set the TXND pointer to correspond to the packet size given
  ldi r16, ctrlReg(ETXNDL)
  mov r17, r19
  dec r17
  ldi r18, HIGH((0x1FFF-0x0600) +1) ; Align to page to save adding length
  rcall enc28j60writeWord

  ; copy the packet into the transmit buffer

  cbi PORTB,CS_PIN ;keep cs low for entire write
  ldi r16,ENC28J60_WRITE_BUF_MEM
  rcall doSPI
  ; packet control byte = 0
  rcall doSPIzero


  inc r19
  ldi YH, HIGH(packetBuffer+6)
  ldi YL,  LOW(packetBuffer+6)
  rcall writeMacToSram
  sbiw Y,12
txLoop:
  ld r16,Y+
#ifdef DEBUG
    rcall sendHex
#endif
  rcall doSPI

  dec r19
  brne txLoop
  sbi PORTB,CS_PIN



  ; transmit!
  ldi r16,setBF(ECON1)
  ldi r17,ECON1_TXRTS
  ;rcall enc28j60write
  ;ret
  rjmp enc28j60write















readPacket:

#ifdef INT_PIN

  sbic PINB, INT_PIN
  rjmp readPacket

#else

  ; Set bank 1
  ldi r16, setBF(ECON1)
  ldi r17, ECON1_BSEL0
  rcall enc28j60write

  ldi r16, readCtrlReg(EPKTCNT)
  ;clr r17 ;probably not needed
  rcall enc28j60write
  tst r16
  breq readPacket

  ; Set bank 0
  ldi r16, clrBF(ECON1)
  ldi r17, ECON1_BSEL0
  rcall enc28j60write


#endif



#ifdef DEBUG
  ldi r16,13
  rcall UARTsend
  ldi r16,'R'
  rcall UARTsend
  ldi r16,' '
  rcall UARTsend
#endif


; After init code, we are left on bank 0

; Set the read pointer to the start of the received packet

  ldi r16, ctrlReg(ERDPTL)
  mov r17, nextPacketL
  mov r18, nextPacketH
  rcall enc28j60writeWord


  cbi PORTB,CS_PIN ;keep cs low for entire read
  ldi r16,ENC28J60_READ_BUF_MEM
  rcall doSPI

; read the next packet pointer
  rcall doSPIzero
  mov nextPacketL,r16
  rcall doSPIzero
  mov nextPacketH,r16
; read packet length
  rcall doSPIzero
  mov XL,r16
  rcall doSPIzero
  mov XH,r16 


  sbiw X,4 ; remove CRC
  movw r25:r24, XH:XL ; Store length for later


  
  ; ignore zero-length messages
  ;cpi XL, 0
  ;cpc XH, XL
  sbiw X, 0
  breq rxDone
  
  ;limit to 768 bytes
  ldi YH, HIGH(768)
  ldi YL,  LOW(768)
  cp XH, YH
  cpc XL, YL
  brcc under768
  movw X, Y
under768:

  ldi YH, HIGH(packetBuffer)
  ldi YL,  LOW(packetBuffer)

  ; read the receive status (see datasheet page 43)
  rcall doSPIzero
  rcall doSPIzero

rxLoop:
  rcall doSPIzero
#ifdef DEBUG
rcall sendHex
#endif
  st Y+,r16
  sbiw X,1
  brne rxLoop

rxDone:
  sbi PORTB,CS_PIN
  

; Is there any situation where we wouldn't want to swap the mac addresses?
    ldi YH, HIGH(sourceMAC)
    ldi YL,  LOW(sourceMAC)
    ldi XH, HIGH(destMAC)
    ldi XL,  LOW(destMAC)
    ldi r18,6
    rcall swapData

    ;ldi YH, HIGH(ethType) ; already set as a result of swapping macs
    ;ldi YL,  LOW(ethType)
    ld r19,Y+ ; 
    ld r20,Y+


  ldi r16, ctrlReg(ERXRDPTL)
  mov r17, nextPacketL
  mov r18, nextPacketH
  rcall enc28j60writeWord

    ; decrease packet count
  ldi r16,setBF(ECON2)
  ldi r17,ECON2_PKTDEC
;  rcall enc28j60write
  ;ret
  rjmp enc28j60write
  













doSPIzero:
  clr r16

doSPI:
  out SPDR,r16
SPIwait:
  in r16, SPSR
  sbrs r16, SPIF
  rjmp SPIwait
  in r16, SPDR
  ret



; r16 = op | (address & 0x1F) [L register]
; r17 = dataL
; r18 = dataH
enc28j60writeWord:
  push r16
  rcall enc28j60write
  pop r16
  inc r16
  mov r17, r18
  ;rcall enc28j60write


; r16 = op | (address & 0x1F)
; r17 = data
enc28j60write:
  cbi PORTB,CS_PIN
  rcall doSPI
  mov r16,r17
  rcall doSPI
  sbi PORTB,CS_PIN

  ret












; X = somewhere in sram
; Y = another bit of sram
; r18 = amount to copy
swapData:
  ld r16, X
  ld r17, Y
  st Y+,r16
  st X+,r17
  dec r18
  brne swapData
  ret


; compare Y,Y+1 against r16,r17
cpMem2:
  sez
; compare Y,Y+1 against r16,r17, with carry
cpMem2c:
  ld r18,Y+
  cpc r18, r16
  ld r18,Y+
  cpc r18, r17
  ret


; check Y against my IP
isItMyIP:
    movw r17:r16, rMyIP1:rMyIP0
    rcall cpMem2
    movw r17:r16, rMyIP3:rMyIP2
    ;rcall cpMem2c
    ;ret
    rjmp cpMem2c




writeIPtoSram:
  st Y+,rMyIP0
  st Y+,rMyIP1
  st Y+,rMyIP2
  st Y+,rMyIP3
  ret

writeMacToSram:
  ldi ZL, low(myMAC*2)
  ldi ZH, high(myMAC*2)
  ldi r17, 6

loadPMtoSRAM:
  lpm r16, Z+
  st Y+,r16
  dec r17
  brne loadPMtoSRAM
  ret



wait2:
  dec zeroReg
  brne wait2
  ret







loadIPs:
    clr XL
    clr XH
    movw Y, X
EEPROM_read:
    ; Wait for completion of previous write
    sbic EECR,EEPE
    rjmp EEPROM_read
    ; Set up address
    out EEARH, XH
    out EEARL, XL
    ; Start eeprom read by writing EERE
    sbi EECR,EERE
    ; Read data from Data Register
    in r16,EEDR

    st X+,r16 ; store in r0...r15

    cpi XL, 16
    brne EEPROM_read

    ; The last byte of the subnet mask will never be 255
    ; if it read 255, assume eeprom data is invalid and resort to pm
    cpi r16, 255
    breq loadIpsFromPm
    ret
loadIpsFromPm:
    ldi ZL, low(hardIPs*2)
    ldi ZH, high(hardIPs*2)
    ldi r17, 16
    rjmp loadPMtoSRAM 












; debug functions

#ifdef DEBUG
UARTsend:
  lds r17, UCSR0A
  sbrs r17, UDRE0
  rjmp UARTsend
  sts UDR0,r16
  ret



sendHex:
  push r16
  swap r16
  mov r18,r16
  rcall sendHalfHex
  swap r18
  rcall sendHalfHex
  ldi r16,' '
  rcall UARTsend
  pop r16
  ret
  

sendHalfHex:
  mov r16, r18
  andi r16, $0F
  subi r16,10
  brcc sHHA
  subi r16,-'0'-10
  rcall UARTsend
  ret

sHHA:
  subi r16,-'A'
  rcall UARTsend
  ret

#endif




hardIPs:
.db myIP, serverIP, gatewayIP, subnetMask


initCode:

; select bank 0
.db clrBF(ECON1), (ECON1_BSEL1|ECON1_BSEL0)

.db ctrlReg(ERXSTL), 0
.db ctrlReg(ERXSTH), 0
.db ctrlReg(ERXRDPTL),  low(0x1FFF-0x0600-1)
.db ctrlReg(ERXRDPTH), high(0x1FFF-0x0600-1)
.db ctrlReg(ERXNDL),    low(0x1FFF-0x0600-1)
.db ctrlReg(ERXNDH),   high(0x1FFF-0x0600-1)
.db ctrlReg(ETXSTL),    low(0x1FFF-0x0600)
.db ctrlReg(ETXSTH),   high(0x1FFF-0x0600)
.db ctrlReg(ETXNDL),    low(0x1FFF)             ; redundant?
.db ctrlReg(ETXNDH),   high(0x1FFF)
  


;select bank 1
.db setBF(ECON1), ECON1_BSEL0
; packet filter stuff
.db ctrlReg(ERXFCON), ERXFCON_UCEN|ERXFCON_CRCEN|ERXFCON_PMEN
.db ctrlReg(EPMM0),  0x3f
.db ctrlReg(EPMM1),  0x30
.db ctrlReg(EPMCSL), 0xf9
.db ctrlReg(EPMCSH), 0xf7


; select bank 3 (minimize bit changes)
.db setBF(ECON1), ECON1_BSEL1

; NOTE: MAC address in ENC28J60 is byte-backward
.db ctrlReg(MAADR5) , myMAC0
.db ctrlReg(MAADR4) , myMAC1
.db ctrlReg(MAADR3) , myMAC2
.db ctrlReg(MAADR2) , myMAC3
.db ctrlReg(MAADR1) , myMAC4
.db ctrlReg(MAADR0) , myMAC5



;select bank 2
.db clrBF(ECON1), ECON1_BSEL0

; enable MAC receive
.db ctrlReg(MACON1), MACON1_MARXEN|MACON1_TXPAUS|MACON1_RXPAUS
; bring MAC out of reset
.db ctrlReg(MACON2), 0x00

; enable automatic padding to 60bytes and CRC operations
.db setBF(MACON3), MACON3_PADCFG0|MACON3_TXCRCEN ;|MACON3_FRMLNEN

; set inter-frame gap (non-back-to-back)
.db ctrlReg(MAIPGL), 0x12
.db ctrlReg(MAIPGH), 0x0C
; set inter-frame gap (back-to-back)
.db ctrlReg(MABBIPG), 0x12
; Set the maximum packet size which the controller will accept
; Do not send packets longer than MAX_FRAMELEN:
.db ctrlReg(MAMXFLL), low(MAX_FRAMELEN)
.db ctrlReg(MAMXFLH),high(MAX_FRAMELEN)


; set PHY register

.db ctrlReg(MIREGADR),PHCON2

.db ctrlReg(MIWRL), low(PHCON2_HDLDIS)
.db ctrlReg(MIWRH),high(PHCON2_HDLDIS)


;LEDs: flash orange on receive, flash green on transmit
.db ctrlReg(MIREGADR),PHLCON

.db ctrlReg(MIWRL),0b00100010
.db ctrlReg(MIWRH),0b00110001

; then wait 10.24us until the PHY write completes... can we still do other stuff though?

;enable interrupts - needed?
.db setBF(EIE), EIE_INTIE|EIE_PKTIE

;enable packet reception
.db setBF(ECON1), ECON1_RXEN


; select bank 0
.db clrBF(ECON1), (ECON1_BSEL1|ECON1_BSEL0)
; select bank 1
;.db setBF(ECON1), (ECON1_BSEL0)

initCodeEnd:


ARPprototype:
;.db $FF,$FF,$FF,$FF,$FF,$FF, myMAC0..5

.db $08, $06, $00, $01, $08, $00, $06, $04, $00, $01
    myMAC: 
    .db myMAC0, myMAC1, myMAC2, myMAC3, myMAC4, myMAC5
    myMACend:
    ;.db myIP0, myIP1, myIP2, myIP3
;    six zeros
;    gateway ip
    ;.db gwIP0, gwIP1, gwIP2, gwIP3






IPprototype:
;                                                                                                                                      t  e  m  p  .  t  x  t     o  c  t  e  t
;TFTP read request:  a44e313cc814 28f36626f64b 08 00 45 00 00 2d e6 97 40 00 40 11 d0 27 c0a8015d c0a80153 e2bd 0045 00 19 46 a1 00 01 74 65 6d 70 2e 74 78 74 00 6f 63 74 65 74 00

; need to generate: IP id, checksum, source port

  .db $08, $00 ; eth type
  .db $45, $00 ; ipv4, header length 20 bytes
  .db 0, low(37+strlen(FILENAME)) ; total length (filename length<31 chars)
IPprotoID:
  .db $e6, $97 ; identification
  .db $40, $00 ; flags, fragment offset - don't fragment.
  .db $40, $11 ; TTL, protocol = udp (17)
;IPprotoChecksum:
  ;.db high(IPmsg1Checksum), low(IPmsg1Checksum) ; header checksum
  ;source IP
  ;.db myIP0, myIP1, myIP2, myIP3 ; duplicate again...
  ;dest IP
  ;.db svIP0, svIP1, svIP2, svIP3
  ;options (none)

;UDPheader:
  .db $e2, $bd ;source port (ephemeral)
  .db $00, $45 ;dest port
  .db $00, $11+strlen(FILENAME) ;length (header+data)
  .db $00, $00 ;checksum (0 = don't use)
;tftp
  .db $00, $01 ; opcode = read request
  .db FILENAME, 0, "octet",0






