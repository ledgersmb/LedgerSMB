use LedgerSMB::Sysconfig;

# This sets up the settings for the POS hardware.  You can use it to override
# printing commands etc. as well.

# Chris Travers
# Chris@metatrontech.com
# 2004-02-07

# Begin Editing Here

$pos_config{'rem_host'} = $ENV{'REMOTE_ADDR'};

$pos_config{'pd_host'}  = $pos_config{'rem_host'};
$pos_config{'pd_port'}  = 6601;
$pos_config{'pd_proto'} = 'tcp';

require "drivers/pd3000.pl";    # Use the PD3000 driver

# Some businesses may want to Override this for custom apps
$pos_config{'pd_host'} = $pos_config{'rem_host'};

$pos_config{'rp_port'}  = 6602;
$pos_config{'rp_proto'} = 'tcp';

$pos_config{'rp_netdirect'} = 'yes';

# Some businesses may want to Override this for custom apps
$pos_config{'rp_host'} = $pos_config{'rem_host'};
$pos_config{'rp_cash_open'} = pack( "CCCCC", 27, 112, 0, 25, 250 );

$pos_config{'coa_prefix'} = 1300;

$pos_config{'close_cash_accno'} = 1060;
$pos_config{till_cash} = 200;

# Add your sources here.

$pos_sources{'visa'}  = $locale->text("Visa/MC");
$pos_sources{'disc'}  = $locale->text("Discover");
$pos_sources{'check'} = $locale->text('Check');
$pos_sources{'cash'}  = $locale->text('Cash');
$pos_sources{'gcert'} = $locale->text('Gift Cert');

$pos_source_default = 'cash';

# 1 for source = memo
# 2 for credit card handling
%pos_source_type = {
    visa  => 2,
    cash  => 1,
    check => 1,
    disc  => 2
};

${ $pos_config{'source_accno_override'}{'gcert'} } = '2105';

# Define your till accno scheme here.  Current supported values are 'terminal'
# and 'cashier'

$pos_config{'till_type'} = 'cashier';

# FLAGS: 1 = projects, 2 = departments
$pos_config{'disable_tables'} = 3;

# HTML for the appropriate currency symbol for your tills
$pos_config{'curren'} = '$';

# Number format to use
$pos_config{'numberformat'} = '1,000.00';

# Units of currency to use in the till closing cash breakdown relative to
# your base unit of currency, formatted in your chosen format
@{ $pos_config{'breakdown'} } =
  ( '100', '50', '20', '10', '5', '2', '1', '0.25', '0.10', '0.05', '0.01' );

# Stop Editing Here

if ( lc( $pos_config{'till_type'} ) eq 'terminal' ) {
    $pos_config{'till'} = ( split( /\./, $pos_config{'rem_host'} ) )[3];
}
elsif ( lc( $pos_config{'till_type'} ) eq 'cashier' ) {
    use LedgerSMB::User;
    $pos_config{'till'} = $form->get_my_emp_num( \%myconfig, \%$form );
}
else {
    $form->error("No till type defined in pos.conf.pl!");
}
$pos_config{till_accno} = "$pos_config{coa_prefix}.$pos_config{till}";
$pos_config{'pd_dest'} = pack( 's n a4 x8',
    2, $pos_config{'pd_port'},
    pack( 'CCCC', split( /\./, $pos_config{'pd_host'} ) ) );

$form->{pos_config}  = \%pos_config;
$form->{pos_sources} = \%pos_sources;

# Due to the architecture of SL, we need to use netcat to print.
# Otherwise the document gets spooled twice and this interferes with timeliness.

${'LedgerSMB::Sysconfig::printer'}{'Printer'} =
"utils/pos/directnet.pl $pos_config{rp_host} $pos_config{rp_proto} $pos_config{rp_port}";

1;
