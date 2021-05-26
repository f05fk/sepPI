#########################################################################
# Copyright (C) Claus Schrammel <claus@f05fk.net>                       #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#                                                                       #
# SPDX-License-Identifier: GPL-3.0-or-later                             #
#########################################################################

package SepPI::MFRC522;

use strict;
use warnings;

use Device::BCM2835;
use Time::HiRes qw(usleep gettimeofday tv_interval);

use constant
{
    GPIO_RST       => &Device::BCM2835::RPI_GPIO_P1_22,
    GPIO_SDA       => &Device::BCM2835::RPI_GPIO_P1_24,

    GPIO_INPUT     => &Device::BCM2835::BCM2835_GPIO_FSEL_INPT,
    GPIO_OUTPUT    => &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP,
    GPIO_LOW       => &Device::BCM2835::LOW,
    GPIO_HIGH      => &Device::BCM2835::HIGH,

    PCD_IDLE       => 0x00,
    PCD_AUTHENT    => 0x0E,
    PCD_RECEIVE    => 0x08,
    PCD_TRANSMIT   => 0x04,
    PCD_TRANSCEIVE => 0x0C,
    PCD_RESETPHASE => 0x0F,
    PCD_CALCCRC    => 0x03,

    PICC_REQA      => 0x26,
    PICC_WUPA      => 0x52,
    PICC_ANTICOLL1 => 0x93,
    PICC_ANTICOLL2 => 0x95,
    PICC_ANTICOLL3 => 0x97,
    PICC_SELECTTAG => 0x93,
    PICC_AUTHENT1A => 0x60,
    PICC_AUTHENT1B => 0x61,
    PICC_READ      => 0x30,
    PICC_WRITE     => 0xA0,
    PICC_DECREMENT => 0xC0,
    PICC_INCREMENT => 0xC1,
    PICC_RESTORE   => 0xC2,
    PICC_TRANSFER  => 0xB0,
    PICC_HALT      => 0x50,

    MI_OK       => 0,
    MI_NOTAGERR => 1,
    MI_ERR      => 2,

    CASCADE_TAG => 0x88,

    RECEIVER_GAIN_0_18dB => 0,
    RECEIVER_GAIN_1_23dB => 1,
    RECEIVER_GAIN_2_18dB => 2,
    RECEIVER_GAIN_3_23dB => 3,
    RECEIVER_GAIN_4_33dB => 4,
    RECEIVER_GAIN_5_38dB => 5,
    RECEIVER_GAIN_6_43dB => 6,
    RECEIVER_GAIN_7_48dB => 7,
    RECEIVER_GAIN_MIN => 0,
    RECEIVER_GAIN_AVG => 4,
    RECEIVER_GAIN_MAX => 7,

    Reserved00     => 0x00,
    CommandReg     => 0x01,
    ComIEnReg      => 0x02,
    DivIEnReg      => 0x03,
    ComIrqReg      => 0x04,
    DivIrqReg      => 0x05,
    ErrorReg       => 0x06,
    Status1Reg     => 0x07,
    Status2Reg     => 0x08,
    FIFODataReg    => 0x09,
    FIFOLevelReg   => 0x0A,
    WaterLevelReg  => 0x0B,
    ControlReg     => 0x0C,
    BitFramingReg  => 0x0D,
    CollReg        => 0x0E,
    Reserved0F     => 0x0F,

    Reserved10     => 0x10,
    ModeReg        => 0x11,
    TxModeReg      => 0x12,
    RxModeReg      => 0x13,
    TxControlReg   => 0x14,
    TxASKReg       => 0x15,
    TxSelReg       => 0x16,
    RxSelReg       => 0x17,
    RxThresholdReg => 0x18,
    DemodReg       => 0x19,
    Reserved1A     => 0x1A,
    Reserved1B     => 0x1B,
    MfTxReg        => 0x1C,
    MfRxReg        => 0x1D,
    Reserved1E     => 0x1E,
    SerialSpeedReg => 0x1F,

    Reserved20      => 0x20,
    CRCResultRegH   => 0x21,
    CRCResultRegL   => 0x22,
    Reserved23      => 0x23,
    ModWidthReg     => 0x24,
    Reserved25      => 0x25,
    RFCfgReg        => 0x26,
    GsNReg          => 0x27,
    CWGsPReg        => 0x28,
    ModGsPReg       => 0x29,
    TModeReg        => 0x2A,
    TPrescalerReg   => 0x2B,
    TReloadRegH     => 0x2C,
    TReloadRegL     => 0x2D,
    TCounterValRegH => 0x2E,
    TCounterValRegL => 0x2F,

    Reserved30      => 0x30,
    TestSel1Reg     => 0x31,
    TestSel2Reg     => 0x32,
    TestPinEnReg    => 0x33,
    TestPinValueReg => 0x34,
    TestBusReg      => 0x35,
    AutoTestReg     => 0x36,
    VersionReg      => 0x37,
    AnalogTestReg   => 0x38,
    TestDAC1Reg     => 0x39,
    TestDAC2Reg     => 0x3A,
    TestADCReg      => 0x3B,
    Reserved3C      => 0x3C,
    Reserved3D      => 0x3D,
    Reserved3E      => 0x3E,
    Reserved3F      => 0x3F,
};

sub new
{
    my $class = shift;
    my %options = @_;

    my $self = {};
    bless $self;

    $self->{debug} = 1 if ($options{debug});
    print "MFRC522::new\n" if ($self->{debug});

    $self->bcm2835_init();
    $self->pcd_hardreset();
    $self->spi_begin();
    $self->pcd_softreset();
    $self->pcd_init();
    $self->pcd_antenna_on();
    $self->pcd_setReceiverGain(RECEIVER_GAIN_MAX);

    return $self;
}

sub close
{
    my $self = shift;

    print "MFRC522::close\n" if ($self->{debug});

    $self->pcd_antenna_off();
    $self->spi_end();
    $self->bcm2835_close();

    return;
}

sub bcm2835_init
{
    my $self = shift;

    print "MFRC522::bcm2835_init\n" if ($self->{debug});

    Device::BCM2835::init() || die "Could not init library";

    return;
}

sub bcm2835_close
{
    my $self = shift;

    print "MFRC522::bcm2835_close\n" if ($self->{debug});

    Device::BCM2835::close();

    return;
}

sub pcd_hardreset
{
    my $self = shift;

    print "MFRC522::pcd_hardreset\n" if ($self->{debug});

    # do not select the slave yet
    Device::BCM2835::gpio_fsel(GPIO_SDA, GPIO_OUTPUT);
    Device::BCM2835::gpio_write(GPIO_SDA, GPIO_HIGH);

    # if MFRC522 is in power down mode
    Device::BCM2835::gpio_fsel(GPIO_RST, GPIO_INPUT);
    if (Device::BCM2835::gpio_lev(GPIO_RST) == GPIO_LOW)
    {
        print "MFRC522::bcm2835_hardreset - do the hard reset\n" if ($self->{debug});

        # hard reset
        Device::BCM2835::gpio_fsel(GPIO_RST, GPIO_OUTPUT);
        Device::BCM2835::gpio_write(GPIO_RST, GPIO_LOW);
	usleep 2;
        Device::BCM2835::gpio_write(GPIO_SDA, GPIO_HIGH);
	usleep 50000;
    }

    return;
}

sub spi_begin
{
    my $self = shift;

    print "MFRC522::spi_begin\n" if ($self->{debug});

    Device::BCM2835::spi_begin();
    Device::BCM2835::spi_setBitOrder(Device::BCM2835::BCM2835_SPI_BIT_ORDER_MSBFIRST); # default
    Device::BCM2835::spi_setDataMode(Device::BCM2835::BCM2835_SPI_MODE0); # default

    Device::BCM2835::spi_setClockDivider(Device::BCM2835::BCM2835_SPI_CLOCK_DIVIDER_65536); # default
#    Device::BCM2835::spi_setClockDivider(Device::BCM2835::BCM2835_SPI_CLOCK_DIVIDER_32);

    Device::BCM2835::spi_chipSelect(Device::BCM2835::BCM2835_SPI_CS0); # default
    Device::BCM2835::spi_setChipSelectPolarity(Device::BCM2835::BCM2835_SPI_CS0, Device::BCM2835::LOW); # default

    return;
}

sub spi_end
{
    my $self = shift;

    print "MFRC522::spi_end\n" if ($self->{debug});

    Device::BCM2835::spi_end();

    return;
}

sub pcd_softreset
{
    my $self = shift;

    print "MFRC522::pcd_softreset\n" if ($self->{debug});
    printf "MFRC522::pcd_softreset - CommandReg = %08b\n", $self->pcd_read(CommandReg) if ($self->{debug});

    # reset
    $self->pcd_write(CommandReg, PCD_RESETPHASE);

    # wait max 3x50ms for the PowerDown bit to be cleared
    my $count = 0;
    while (1)
    {
        $count++;
        printf "MFRC522::pcd_softreset - CommandReg = %08b, count = %d\n",
       	        $self->pcd_read(CommandReg), $count if ($self->{debug});
        last if (!($self->pcd_read(CommandReg) & 0b00010000) || $count == 3);
        usleep 50000;
    }

    return;
}

sub pcd_init
{
    my $self = shift;

    print "MFRC522::pcd_init\n" if ($self->{debug});

    # baud rates
    $self->pcd_write(TxModeReg, 0x00); # default
    $self->pcd_write(RxModeReg, 0x00); # default

    # modulation width
    $self->pcd_write(ModWidthReg, 0x26); # default

    # timer: 0x0A9 = 40kHz = 25us; 0x03E8 = 1000 = 25ms
    $self->pcd_write(TModeReg, 0x80);
    $self->pcd_write(TPrescalerReg, 0xA9);
    $self->pcd_write(TReloadRegH, 0x03);
    $self->pcd_write(TReloadRegL, 0xE8);

    # force ASK modulation
    $self->pcd_write(TxASKReg, 0x40);

    # CRC preset
    $self->pcd_write(ModeReg, 0x3D);

    return;
}

sub pcd_antenna_on
{
    my $self = shift;

    print "MFRC522::pcd_antenna_on\n" if ($self->{debug});
    printf "MFRC522::pcd_antenna_on - TxControlReg = %08b\n", $self->pcd_read(TxControlReg) if ($self->{debug});

    my $value = $self->pcd_read(TxControlReg);
    if (($value & 0x03) != 0x03)
    {
        $self->pcd_setBitMask(TxControlReg, 0x03);
    }

    printf "MFRC522::pcd_antenna_on - TxControlReg = %08b\n", $self->pcd_read(TxControlReg) if ($self->{debug});
    printf "MFRC522::pcd_antenna_on - CommandReg = %08b\n", $self->pcd_read(CommandReg) if ($self->{debug});

    return;
}

sub pcd_antenna_off
{
    my $self = shift;

    print "MFRC522::pcd_antenna_off\n" if ($self->{debug});
    printf "MFRC522::pcd_antenna_off - TxControlReg = %08b\n", $self->pcd_read(TxControlReg) if ($self->{debug});

    $self->pcd_clearBitMask(TxControlReg, 0x03);

    printf "MFRC522::pcd_antenna_off - TxControlReg = %08b\n", $self->pcd_read(TxControlReg) if ($self->{debug});

    return;
}

sub pcd_setReceiverGain
{
    my $self = shift;
    my $receiverGain = shift;

    printf "MFRC522::pcd_setReceiverGain(0b%03b)\n", $receiverGain if ($self->{debug});
    printf "MFRC522::pcd_setReceiverGain - RFCfgReg = %08b\n", $self->pcd_read(RFCfgReg) if ($self->{debug});

    $self->pcd_clearBitMask(RFCfgReg, 0x70);
    $self->pcd_setBitMask(RFCfgReg, ($receiverGain & 0x07) << 4);

    printf "MFRC522::pcd_setReceiverGain - RFCfgReg = %08b\n", $self->pcd_read(RFCfgReg) if ($self->{debug});

    return;
}

sub spi_transfern
{
    my $self = shift;
    my @data = @_;

    printf "MFRC522::spi_transfern - tx " . join(':', map {sprintf "%02x", $_} @data) . "\n" if ($self->{trace});
    my $data = pack('C*', @data);
    Device::BCM2835::spi_transfern($data);
    @data = unpack('C*', $data);
    printf "MFRC522::spi_transfern - rx " . join(':', map {sprintf "%02x", $_} @data) . "\n" if ($self->{trace});

    return @data;
}

sub pcd_read
{
    my $self = shift;
    my $register = shift;
    my $length = shift || 1;

    my @data = $self->spi_transfern(((($register << 1) & 0x7E) | 0x80) x $length, 0);
    shift @data;

    return wantarray ? @data : $data[0];
}

sub pcd_write
{
    my $self = shift;
    my $register = shift;
    my @data = @_;

    $self->spi_transfern(($register << 1) & 0x7E, @data);

    return @data;
}

sub pcd_clearBitMask
{
    my $self = shift;
    my $register = shift;
    my $mask = shift;

    my $oldvalue = $self->pcd_read($register);
    my $newvalue = $oldvalue & (~$mask);
    $self->pcd_write($register, $newvalue);

    return $newvalue;
}

sub pcd_setBitMask
{
    my $self = shift;
    my $register = shift;
    my $mask = shift;

    my $oldvalue = $self->pcd_read($register);
    my $newvalue = $oldvalue | $mask;
    $self->pcd_write($register, $newvalue);

    return $newvalue;
}

sub pcd_transceive
{
    my $self = shift;
    my @data = @_;

    print "MFRC522::pcd_transceive\n" if ($self->{debug});

    $self->pcd_write(CommandReg, PCD_IDLE);
    $self->pcd_write(ComIrqReg, 0x7F);
    $self->pcd_setBitMask(FIFOLevelReg, 0x80);
    $self->pcd_write(FIFODataReg, @data);
    $self->pcd_write(CommandReg, PCD_TRANSCEIVE);
    $self->pcd_setBitMask(BitFramingReg, 0x80);

    my $irqs;
    my $wait;
    my $start = [gettimeofday()];
    do
    {
        $wait = tv_interval($start) < 0.050;   # wait at least 50ms for the PCD/PICC to respond
        $irqs = $self->pcd_read(ComIrqReg);
        printf "MFRC522::pcd_transceive - ComIrqReg = %08b\n", $irqs if ($self->{debug});
    }
    while ($wait && !($irqs & 0x31));
    my $end = [gettimeofday()];

    $self->pcd_clearBitMask(BitFramingReg, 0x80);

    printf "MFRC522::pcd_transceive - duration = %.6f\n", tv_interval($start, $end) if ($self->{debug});
    printf "MFRC522::pcd_transceive - ComIrqReg = %08b\n", $self->pcd_read(ComIrqReg) if ($self->{debug});
    printf "MFRC522::pcd_transceive - ErrorReg = %08b\n", $self->pcd_read(ErrorReg) if ($self->{debug});

    return MI_ERR if (!$wait);
    return MI_ERR if ($self->pcd_read(ErrorReg) & 0x1B);   # BufferOvfl CollErr ParityErr ProtocolErr
    return MI_NOTAGERR if ($irqs & 0x01);

    my $bytes = $self->pcd_read(FIFOLevelReg);
    my $lastBits = $self->pcd_read(ControlReg) & 0x07;
    my $bits = ($lastBits ? ($bytes-1) : $bytes) * 8 + $lastBits;

    my @result = $self->pcd_read(FIFODataReg, $bytes);

    return (MI_OK, $bytes, $lastBits, $bits, @result);
}

sub pcd_calculateCRC
{
    my $self = shift;
    my @data = @_;

    print "MFRC522::pcd_calculateCRC\n" if ($self->{debug});

#    printf "CRC data: " . join(':', map {sprintf "%02x", $_} @data) . "\n";

#    $self->pcd_write(DivIEnReg, 0xXX);
    $self->pcd_clearBitMask(DivIrqReg, 0x04);
    $self->pcd_setBitMask(FIFOLevelReg, 0x80);
    $self->pcd_write(CommandReg, PCD_IDLE);
    $self->pcd_write(FIFODataReg, @data);
    $self->pcd_write(CommandReg, PCD_CALCCRC);

    my $irqs;
    my $i = 0xFF;
    do
    {
        $irqs = $self->pcd_read(DivIrqReg);
        $i--;
    }
    while ($i != 0 && !($irqs & 0x04));

#    print "\ni = $i\n";
#    printf "irqs = %08b\n", $irqs;
#    printf "error = %08b\n", $self->pcd_read(ErrorReg);

    my $crcL = $self->pcd_read(CRCResultRegL);
    my $crcH = $self->pcd_read(CRCResultRegH);

#    printf "CRC result: %02x %02x\n", $crcL, $crcH;

    return ($crcL, $crcH);
}

sub picc_wakeup
{
    my $self = shift;

    print "MFRC522::picc_wakeup\n" if ($self->{debug});

    $self->pcd_clearBitMask(CollReg, 0x80);
    $self->pcd_write(BitFramingReg, 0x07);

    my ($status, $bytes, $lastBits, $bits, @result) = $self->pcd_transceive(PICC_WUPA);

    $self->pcd_write(BitFramingReg, 0x00);

    if ($self->{debug}) {
        if ($status == MI_OK) {
            my $datahex = join(':', map {sprintf "%02x", $_} @result);
            my $databin = join(' ', map {sprintf "%08b", $_} @result);
            print "MFRC522::picc_wakeup - status [$status] bytes [$bytes] [$lastBits] [$bits] data [$datahex] [$databin]\n";
        }
        else
        {
            print "MFRC522::picc_wakeup - status [$status]\n";
        }
    }

    return $status;
}

sub picc_anticoll
{
    my $self = shift;
    my $cascade = shift;
    my @uid = @_;

    print "MFRC522::picc_anticoll\n" if ($self->{debug});

    my @buffer = ($cascade, 0x20);

#    print "picc_anticoll: " . join(':', map {sprintf "%02x", $_} (@buffer)) . "\n";
    my ($status, $bytes, $lastBits, $bits, @result) = $self->pcd_transceive(@buffer);

    return MI_ERR if (($result[0] ^ $result[1] ^ $result[2] ^ $result[3]) != $result[4]);

#    my $datahex = join(':', map {sprintf "%02x", $_} @result);
#    my $databin = join(' ', map {sprintf "%08b", $_} @result);
#    print "picc_anticoll: status [$status] bytes [$bytes] [$lastBits] [$bits] data [$datahex] [$databin]\n";

    return ($status, @result);
}

sub picc_select
{
    my $self = shift;
    my $cascade = shift;
    my @uid = @_;

    print "MFRC522::picc_select\n" if ($self->{debug});

    my @buffer = ($cascade, 0x70, @uid);
    push @buffer, $self->pcd_calculateCRC(@buffer);

#    print "picc_select: " . join(':', map {sprintf "%02x", $_} (@buffer)) . "\n";

    my ($status, $bytes, $lastBits, $bits, @result) = $self->pcd_transceive(@buffer);

#    my $datahex = join(':', map {sprintf "%02x", $_} @result);
#    my $databin = join(' ', map {sprintf "%08b", $_} @result);
#    print "picc_select: status [$status] bytes [$bytes] [$lastBits] [$bits] data [$datahex] [$databin]\n";

    return $status;
}

sub picc_halt
{
    my $self = shift;

    print "MFRC522::picc_halt\n" if ($self->{debug});

    my @buffer = (PICC_HALT, 0);
    push @buffer, $self->pcd_calculateCRC(@buffer);

    my ($status, $bytes, $lastBits, $bits, @result) = $self->pcd_transceive(@buffer);

    return $status;
}

sub picc_readUID
{
    my $self = shift;

    print "MFRC522::picc_readUID\n" if ($self->{debug});

    my $status;
    my @uid;

    $status = $self->picc_wakeup();
    return $status if ($status != MI_OK);

    ($status, @uid) = $self->picc_anticollSelectCascade();
    return $status if ($status != MI_OK);

    $status = $self->picc_halt();
#    return $status if ($status != MI_OK);

    return (MI_OK, @uid);
}

sub picc_anticollSelectCascade
{
    my $self = shift;

    print "MFRC522::picc_anticollSelectCascade\n" if ($self->{debug});

    my $status;
    my @data;
    my @uidpart;
    my @uid;

    # Anticollision does not work anyway. With my hardware I already get an error in picc_wakeup when
    # two PICCs are in range of PCD. Therefore I never get a collision.

    ($status, @data) = $self->picc_anticoll(PICC_ANTICOLL1);
    return $status if ($status != MI_OK);
    @uidpart = @data[0..3];
    ($status, @data) = $self->picc_select(PICC_ANTICOLL1, @data);
    return $status if ($status != MI_OK);

    if ($uidpart[0] != CASCADE_TAG)
    {
        @uid = @uidpart;
        return ($status, @uid);
    }
    @uid = @uidpart[1..3];

    ($status, @data) = $self->picc_anticoll(PICC_ANTICOLL2);
    return $status if ($status != MI_OK);
    @uidpart = @data[0..3];
    ($status, @data) = $self->picc_select(PICC_ANTICOLL2, @data);
    return $status if ($status != MI_OK);

    if ($uidpart[0] != CASCADE_TAG)
    {
        @uid[3..6] = @uidpart;
        return ($status, @uid);
    }
    @uid[3..5] = @uidpart[1..3];

    ($status, @data) = $self->picc_anticoll(PICC_ANTICOLL3);
    return $status if ($status != MI_OK);
    ($status, @data) = $self->picc_select(PICC_ANTICOLL3, @data);
    return $status if ($status != MI_OK);

    @uid[6..9] = @uidpart;
    return ($status, @uid);
}

1;

__END__
