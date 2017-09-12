package MFRC522;

use strict;
use warnings;

use Device::BCM2835;

use constant
{
    MAX_LEN => 16,

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
    Reserved3F      => 0x3F
};

sub new
{
    my $class = shift;

    my $self = {};
    bless $self;

    $self->spi_begin();
    $self->pcd_reset();
    $self->pcd_antenna_on();

    return $self;
}

sub spi_begin
{
    my $self = shift;

#    Device::BCM2835::set_debug(1);
    print "spi_begin: init()\n";
    Device::BCM2835::init() || die "Could not init library";

    print "spi_begin: spi_begin()\n";
    Device::BCM2835::spi_begin();
    print "spi_begin: spi_setBitOrder(Device::BCM2835::BCM2835_SPI_BIT_ORDER_MSBFIRST)\n";
    Device::BCM2835::spi_setBitOrder(Device::BCM2835::BCM2835_SPI_BIT_ORDER_MSBFIRST);
    print "spi_begin: spi_setDataMode(Device::BCM2835::BCM2835_SPI_MODE0)\n";
    Device::BCM2835::spi_setDataMode(Device::BCM2835::BCM2835_SPI_MODE0);

#    print "spi_begin: spi_setClockDivider(Device::BCM2835::BCM2835_SPI_CLOCK_DIVIDER_65536)\n";
#    Device::BCM2835::spi_setClockDivider(Device::BCM2835::BCM2835_SPI_CLOCK_DIVIDER_65536);
    print "spi_begin: spi_setClockDivider(Device::BCM2835::BCM2835_SPI_CLOCK_DIVIDER_32)\n";
    Device::BCM2835::spi_setClockDivider(Device::BCM2835::BCM2835_SPI_CLOCK_DIVIDER_32);

    print "spi_begin: spi_chipSelect(Device::BCM2835::BCM2835_SPI_CS0)\n";
    Device::BCM2835::spi_chipSelect(Device::BCM2835::BCM2835_SPI_CS0);

#    print "spi_begin: spi_setChipSelectPolarity(Device::BCM2835::BCM2835_SPI_CS0, 0)\n";
#    Device::BCM2835::spi_setChipSelectPolarity(Device::BCM2835::BCM2835_SPI_CS0, 0);
    print "spi_begin: spi_setChipSelectPolarity(Device::BCM2835::BCM2835_SPI_CS0, Device::BCM2835::LOW)\n";
    Device::BCM2835::spi_setChipSelectPolarity(Device::BCM2835::BCM2835_SPI_CS0, Device::BCM2835::LOW);

    return;
}

sub spi_transfern
{
    my $self = shift;
    my @data = @_;

    my $data = pack('C*', @data);
    Device::BCM2835::spi_transfern($data);
    @data = unpack('C*', $data);

    return @data;
}

sub spi_end
{
    my $self = shift;

    Device::BCM2835::spi_end();
    Device::BCM2835::close();

    return;
}

sub pcd_read
{
    my $self = shift;
    my $register = shift;

    my ($dummy, $value) = $self->spi_transfern((($register << 1) & 0x7E) | 0x80, 0);

    return $value;
}

sub pcd_write
{
    my $self = shift;
    my $register = shift;
    my $value = shift;

    $self->spi_transfern(($register << 1) & 0x7E, $value);

    return $value;
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

sub pcd_reset
{
    my $self = shift;

    # reset
    print "pcd_reset: pcd_write(CommandReg, PCD_RESETPHASE)\n";
    $self->pcd_write(CommandReg, PCD_RESETPHASE);

    # timer
    print "pcd_reset: pcd_write(TModeReg, 0x8D)\n";
    $self->pcd_write(TModeReg, 0x8D);
    print "pcd_reset: pcd_write(TPrescalerReg, 0x3E)\n";
    $self->pcd_write(TPrescalerReg, 0x3E);
    print "pcd_reset: pcd_write(TReloadRegL, 30)\n";
    $self->pcd_write(TReloadRegL, 30);
    print "pcd_reset: pcd_write(TReloadRegH, 0)\n";
    $self->pcd_write(TReloadRegH, 0);

    # modulation
    print "pcd_reset: pcd_write(TxASKReg, 0x40)\n";
    $self->pcd_write(TxASKReg, 0x40);
    # general mode for transmit and receive
    print "pcd_reset: pcd_write(ModeReg, 0x3D)\n";
    $self->pcd_write(ModeReg, 0x3D);

    return;
}

sub pcd_antenna_on
{
    my $self = shift;

    print "pcd_antenna_on: pcd_read(TxControlReg)\n";
    my $value = $self->pcd_read(TxControlReg);
    if (!($value & 0x03))
    {
        print "pcd_antenna_on: pcd_setBitMask(TxControlReg, 0x03)\n";
        $self->pcd_setBitMask(TxControlReg, 0x03);
    }

    return;
}

sub pcd_antenna_off
{
    my $self = shift;

    print "pcd_antenna_off: pcd_clearBitMask(TxControlReg, 0x03)\n";
    $self->pcd_clearBitMask(TxControlReg, 0x03);

    return;
}

sub pcd_transceive
{
    my $self = shift;
    my @data = @_;

    $self->pcd_write(ComIEnReg, 0xF7);
    $self->pcd_clearBitMask(ComIrqReg, 0x80);
    $self->pcd_setBitMask(FIFOLevelReg, 0x80);
    $self->pcd_write(CommandReg, PCD_IDLE);

    foreach my $data (@data)
    {
        $self->pcd_write(FIFODataReg, $data);
    }

    $self->pcd_write(CommandReg, PCD_TRANSCEIVE);
    $self->pcd_setBitMask(BitFramingReg, 0x80);

    my $irqs;
    my $i = 200000;
    do
    {
        $irqs = $self->pcd_read(ComIrqReg);
        $i--;
    }
    while ($i != 0 && !($irqs & 0x31));

#    print "\ni = $i\n";
#    printf "irqs = %08b\n", $irqs;
#    printf "error = %08b\n", $self->pcd_read(ErrorReg);

    $self->pcd_clearBitMask(BitFramingReg, 0x80);

    return MI_ERR if ($i == 0);
    return MI_ERR if ($self->pcd_read(ErrorReg) & 0x1B);
    return MI_NOTAGERR if ($irqs & 0x01);

    my $bytes = $self->pcd_read(FIFOLevelReg);
    my $lastBits = $self->pcd_read(ControlReg) & 0x07;
    my $bits = ($lastBits ? ($bytes-1) : $bytes) * 8 + $lastBits; 

    my @result;
    for ($i = 0; $i < $bytes; $i++)
    {
        push @result, $self->pcd_read(FIFODataReg);
    }

    return (MI_OK, $bytes, $lastBits, $bits, @result);
}

sub picc_wakeup
{
    my $self = shift;
    my @data = @_;

    $self->pcd_write(BitFramingReg, 0x07);

    my ($status, $bytes, $lastBits, $bits, @result) = $self->pcd_transceive(PICC_WUPA);

    my $datahex = join(':', map {sprintf "%02x", $_} @result);
    my $databin = join(' ', map {sprintf "%08b", $_} @result);
    print "picc_wakeup: status [$status] bytes [$bytes] [$lastBits] [$bits] data [$datahex] [$databin]\n";

    return $status;
}

sub picc_anticoll
{
    my $self = shift;
    my @uid = @_;

    $self->pcd_write(BitFramingReg, 0x00);

    my ($status, $bytes, $lastBits, $bits, @result) = $self->pcd_transceive(PICC_ANTICOLL1, 0x20);

    printf "check: %02x %02x\n", $result[0] ^ $result[1] ^ $result[2] ^ $result[3], $result[4];
    return MI_ERR if (($result[0] ^ $result[1] ^ $result[2] ^ $result[3]) != $result[4]);

    my $datahex = join(':', map {sprintf "%02x", $_} @result);
    my $databin = join(' ', map {sprintf "%08b", $_} @result);
    print "picc_anticoll1: status [$status] bytes [$bytes] [$lastBits] [$bits] data [$datahex] [$databin]\n";

    return $status;
}

1;

__END__
