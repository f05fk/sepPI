# sepPI
Simple audio player for kids based on RaspberryPI


## Datasheets
https://www.nxp.com/docs/en/data-sheet/MFRC522.pdf
http://wg8.de/wg8n1496_17n3613_Ballot_FCD14443-3.pdf


## Amplifier
https://learn.adafruit.com/adafruit-max98357-i2s-class-d-mono-amp/


## References
https://tutorials-raspberrypi.de/raspberry-pi-rfid-rc522-tueroeffner-nfc/
https://github.com/mxgxw/MFRC522-python
https://metacpan.org/pod/Device::BCM2835
https://github.com/miguelbalboa/rfid
https://github.com/miguelbalboa/rfid/tree/master/src
https://github.com/miguelbalboa/rfid/blob/master/src/MFRC522.cpp
https://github.com/miguelbalboa/rfid/blob/master/src/MFRC522.h
http://code.google.com/p/rpi-rc522
https://github.com/codepope/rpi-rc522


## Wiring

                                 RaspberryPI
                         +------------+------------+
                         | GPIO   PIN | PIN   GPIO |
                         +------------+------------+
      common buttons <-- | PWR 3V3  1 | 2   5V PWR |
      button volume+ <-- | 2        3 | 4   5V PWR | --> MAX98357.Vin
      button volume- <-- | 3        5 | 6   GROUND | --> MAX98357.GND
      button track+  <-- | 4        7 | 8       14 |
                         | GROUND   9 | 10      15 |
      button track-  <-- | 17      11 | 12 CLK  18 | --> MAX98357.BCLK
                         | 27      13 | 14  GROUND |
                         | 22      15 | 16      23 |
          RC522.3.3V <-- | PWR 3V3 17 | 18      24 |
          RC522.MOSI <-- | 10 MOSI 19 | 20  GROUND |
          RC522.MISO <-- | 9  MISO 21 | 22      25 | --> RC522.RST
          RC522.SCK  <-- | 11 SCLK 23 | 24 CE0   8 | --> RC522.SDA
          RC522.GND  <-- | GROUND  25 | 26 CE1   7 |
                         | 0       27 | 28       1 |
                         | 5       29 | 30  GROUND |
                         | 6       31 | 32      12 |
                         | 13      33 | 34  GROUND |
      MAX98357.LRCLK <-- | 19   FS 35 | 36      16 |
                         | 26      37 | 38 DIN  20 |
                         | GROUND  39 | 40 DOUT 21 | --> MAX98357.DIN
                         +------------+------------+


                                 RFID-RC522
                         +--------+----------------+
    RPI.24 (CE0)     <-- | SDA    |    ________    |
    RPI.23 (SCK)     <-- | SCK    |   / ______ \   |
    RPI.19 (MOSI)    <-- | MOSI   |  / /      \ \  |
    RPI.21 (MISO)    <-- | MISO   | | |        | | |
                         | IRQ    | | |        | | |
    RPI.25 (GROUND)  <-- | GND    |  \ \______/ /  |
    RPI.22 (GPIO 25) <-- | RST    |   \________/   |
    RPI.17 (PWR 3V3) <-- | 3.3V   |                |
                         +--------+----------------+


                                  MAX98357
                            +------------------+
      RPI.19 (FS)      <--  | LRCLK            |
      RPI.18 (CLK)     <--  | BCLK             |
      RPI.21 (DOUT)    <--  | DIN     OUTPUT - |  -->  SPEAKER -
                            | GAIN             |
                            | SD      OUTPUT + |  -->  SPEAKER +
      RPI.6  (GROUND)  <--  | GND              |
      RPI.4  (PWR 5V)  <--  | Vin              |
                            +------------------+

