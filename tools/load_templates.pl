#!/usr/bin/perl
#
# load_templates.pl
use LedgerSMB::App_State;
use LedgerSMB::Template::DB;
use DBI;

my $help_msg = "

perl load_templates.pl file_or_directory [language] [database]

This is a simple script to load templates into the database from the 
filesystem.  It loads them into the database via the LedgerSMB::Template::DB
module.

This can be run either on a single file or on a directory which is given in the 
first argument.  The arguments are as follows:

file_or_directory:  the file or directory to be loaded.  This is not done 
recursively.  If you want to load recursively, use with find.  This decision was
made because it makes some sense to store language-specific templates in 
subdirectories.

language:  This is the language code (i.e. en or en_US) to attach to the 
template.  If omitted the templates are assumed not to be language specific.  
You would use this if you wanted to change the layout for a specific language.

database:  The database to connect to.  If PGDATABASE is set this takes 
precedence only in the 3 arg form.  Use '' to indicate a missing language code 
in that case.

Examples:

PGDATABASE=lsmbdemo perl load_templates.pl templates/demo
perl load_templates.pl templates/demo/en en lsmbdemo
PGDATABASE=lsmbdemo perl load_templates.pl templates/demo/en en
perl load_templates.pl file_or_directory templates/demo '' lsmbdemo

";



#### ARG HANDLING (before functions because it should be read first)
#
my ($script, $to_load, $language, $database) = @_;

# handle 2-arg form:

if (!$database){
   $database = $ENV{PGDATABASE};
   if (!$database){
       $database = $language;
       $language = undef;
   }
}

$language  ||= undef; # false values used as placeholders only.

if ($to_load eq '--help' or $to_load =~ /^-/ or !$to_load){
    print $help_msg;
    exit 0;
}

### FUNCTIONS

sub load_template {
    my ($path) = @_;
    my $fname = $path;
    if ($path =~ m|/.*:| ){
       die 'Cannot run on NTFS alternate data stream!';
    }
    $fname =~ s|.*/?([^/]+)|$1|;
    my ($template_name, $format) = split /./, $fname;
    my $content = '';
    open TEMP, '<', $path;
    $content .= $_ while <TEMP>;
    my %args = (
           template_name => $template_name,
           format => $format,
           template => $template,
    );
    $args{language_code} = $language_code if $language_code;
    my $dbtemp = LedgerSMB::Template::DB->new(%args);
    $dbtemp->save;
}

### SETUP

# db connection

my $dbh = DBI->connect("dbi:Pg:dbname=$database") 
  or die "Unable to connect to database!"; # autocommit on, no need to turn off

$LedgerSMB::App_State::DBH = $dbh;

### LOADING LOGIC

# is file or directory?

my $type = undef;

$type = 'file' if -f $to_load;
$type = 'dir' if -d $to_load;

die 'Bad file type: Must be a file or directory or file does not exist' 
   unless defined $type;

# load

if ($type eq 'file'){
   load_template($to_load);
} else {
   opendir(DIR, $to_load);
   while (readdir(DIR)){
      load_template("$to_load/$_") if -f "$to_load/$_";
   }
}

exit 0;
