#!/usr/bin/perl

# -n do not include custom_ scripts
# -a build all file
# -m do not generate missing files

use FileHandle;
use Getopt::Long;
Getopt::Long::Configure('bundling');

$basedir   = "../..";
$bindir    = "$basedir/bin";
$customdir = "$bindir/custom";
$menufile  = "menu.ini";

my $excludeCustom = 0;
my $buildAll      = 0;
my $noMissing     = 0;
my $goodOpt       = 0;
$goodOpt = GetOptions(
    'n'          => \$excludeCustom,
    'no-custom'  => \$excludeCustom,
    'a'          => \$buildAll,
    'build-all'  => \$buildAll,
    'm'          => \$noMissing,
    'no-missing' => \$noMissing
);

if ( !$goodOpt ) {
    printf "Invalid options\n";
    exit 1;
}

open( FH, "LANGUAGE" );
$language = <FH>;
close(FH);
chomp $language;
$language =~ s/\((.*)\)/$1/;
$charset = $1;

opendir DIR, "$bindir" or die "$!";
@progfiles = grep { /\.pl/; !/(_|^\.)/ } readdir DIR;
seekdir DIR, 0;
@customfiles = grep /_/, readdir DIR;
closedir DIR;

# put customized files into @customfiles
@customfiles = () if ($excludeCustom);

if ($excludeCustom) {
    @menufiles = ($menufile);
}
else {
    opendir DIR, "$bindir" or die "$!";
    @menufiles = grep { /.*?_$menufile$/ } readdir DIR;
    closedir DIR;
##  unshift @menufiles, $menufile;
##  opendir DIR, "$customdir" or die "$!";
##  @menufiles = grep { /^$menufile$/ } readdir DIR;
##  closedir DIR;
    unshift @menufiles, $menufile;
}

if ( -f "all" ) {
    eval { require "all"; };
    %all = %{ $self{texts} };
    %{ $self{texts} } = ();
}
else {

    # build %all file from individual files
    foreach $file (@progfiles) {
        &scanfile("$bindir/$file");
    }
}

# remove the old missing file
if ( -f 'missing' ) {
    unlink "missing";
}

foreach $file (@progfiles) {

    next if -d "$bindir/$file";
    %locale  = ();
    %submit  = ();
    %subrt   = ();
    @missing = ();
    %missing = ();

    &scanfile("$bindir/$file");

    # scan custom_{module}.pl or {login}_{module}.pl files
    foreach $customfile (@customfiles) {
        if ( $customfile =~ /_$file/ ) {
            if ( -f "$bindir/$customfile" ) {
                &scanfile("$bindir/$customfile");
            }
        }
    }

    # if this is the menu.pl file
    if ( $file eq 'menu.pl' ) {
        foreach $item (@menufiles) {
            &scanmenu("$basedir/$item");
        }
    }

    $file =~ s/\.pl//;

    if ( -f "$file.missing" ) {
        eval { require "$file.missing"; };
        unlink "$file.missing";

        for ( keys %$missing ) {
            $self{texts}{$_} ||= $missing->{$_};
        }
    }

    open FH, '>', "$file" or die "$! : $file";

    if ($charset) {
        print FH qq|\$self{charset} = '$charset';\n\n|;
    }

    print FH q|$self{texts} = {
|;

    foreach $key ( sort keys %locale ) {
        $text = ( $self{texts}{$key} ) ? $self{texts}{$key} : $all{$key};
        $count++;

        $text =~ s/'/\\'/g;
        $text =~ s/\\$/\\\\/;

        $keytext = $key;
        $keytext =~ s/'/\\'/g;
        $keytext =~ s/\\$/\\\\/;

        if ( !$text ) {
            $notext++;
            push @missing, $keytext;
            next;
        }

        print FH qq|  '$keytext'|
          . ( ' ' x ( 27 - length($keytext) ) )
          . qq| => '$text',\n|;
    }

    print FH q|};

$self{subs} = {
|;

    foreach $key ( sort keys %subrt ) {
        $text = $key;
        $text =~ s/'/\\'/g;
        $text =~ s/\\$/\\\\/;
        print FH qq|  '$text'|
          . ( ' ' x ( 27 - length($text) ) )
          . qq| => '$text',\n|;
    }

    foreach $key ( sort keys %submit ) {
        $text = ( $self{texts}{$key} ) ? $self{texts}{$key} : $all{$key};
        next unless $text;

        $text =~ s/'/\\'/g;
        $text =~ s/\\$/\\\\/;

        $english_sub = $key;
        $english_sub =~ s/'/\\'/g;
        $english_sub =~ s/\\$/\\\\/;
        $english_sub = lc $key;

        $translated_sub = lc $text;
        $english_sub    =~ s/( |-|,|\/|\.$)/_/g;
        $translated_sub =~ s/( |-|,|\/|\.$)/_/g;
        print FH qq|  '$translated_sub'|
          . ( ' ' x ( 27 - length($translated_sub) ) )
          . qq| => '$english_sub',\n|;
    }

    print FH q|};

1;

|;

    close FH;

    if ( !$noMissing ) {
        if (@missing) {
            open FH, '>', "$file.missing" or die "$! : missing";

            print FH qq|# module $file
# add the missing texts and run locales.pl to rebuild

\$missing = {
|;

            foreach $text (@missing) {
                $text =~ s/'/\\'/g;
                $text =~ s/\\$/\\\\/;
                print FH qq|  '$text'|
                  . ( ' ' x ( 27 - length($text) ) )
                  . qq| => '',\n|;
            }

            print FH q|};

1;
|;

            close FH;

        }
    }

    # redo the all file
    if ($buildAll) {
        open FH, '>', "all" or die "$! : all";

        print FH q|# These are all the texts to build the translations files.
# to build unique strings edit the module files instead
# this file is just a shortcut to build strings which are the same
|;

        if ($charset) {
            print FH qq|\$self{charset} = '$charset';\n\n|;
        }

        print FH q|
$self{texts} = {
|;

        foreach $key ( sort keys %all ) {
            $keytext = $key;
            $keytext =~ s/'/\\'/g;
            $keytext =~ s/\\$/\\\\/;

            $text = $all{$key};
            $text =~ s/'/\\'/g;
            $text =~ s/\\$/\\\\/;
            print FH qq|  '$keytext'|
              . ( ' ' x ( 27 - length($keytext) ) )
              . qq| => '$text',\n|;
        }

        print FH q|};

1;
|;

        close FH;

    }

}

$per = sprintf( "%.1f", ( $count - $notext ) / $count * 100 );
print "\n$language - ${per}%\n";

exit;

# eof

sub scanfile {
    my ( $file, $level ) = @_;

    my $fh = new FileHandle;
    return unless ( -e $file or $file !~ /custom/ );
    open $fh, '<', "$file" or die "$! : $file";

    $file =~ s/\.pl//;
    $file =~ s/$bindir\///;

    %temp = ();
    for ( keys %{ $self{texts} } ) {
        $temp{$_} = $self{texts}{$_};
    }

    # read translation file if it exists
    if ( -f $file ) {
        eval { do "$file"; };
        for ( keys %{ $self{texts} } ) {
            $all{$_} ||= $self{texts}{$_};
            if ($level) {
                $temp{$_} ||= $self{texts}{$_};
            }
            else {
                $temp{$_} = $self{texts}{$_};
            }
        }
    }

    %{ $self{texts} } = ();
    for ( sort keys %temp ) {
        $self{texts}{$_} = $temp{$_};
    }

    while (<$fh>) {

        # is this another file
        if (/require\s+\W.*\.pl/) {
            my $newfile = $&;
            $newfile =~ s/require\s+\W//;
            $newfile =~ s/\$form->{path}\///;
            &scanfile( "$basedir/$newfile", 1 ) if $newfile !~ /_/;
        }

        # is this a sub ?
        if (/^sub /) {
            ( $null, $subrt ) = split / +/;
            $subrt{$subrt} = 1;
            next;
        }

        my $rc = 1;

        while ($rc) {
            if (/Locale/) {
                if ( !/^use / ) {
                    my ( $null, $country ) = split /,/;
                    $country =~ s/^ +["']//;
                    $country =~ s/["'].*//;
                }
            }

            if (/\$locale->text.*?\W\)/) {
                my $string = $&;
                $string =~ s/\$locale->text\(\s*['"(q|qq)]['\/\\\|~]*//;
                $string =~ s/\W\)+.*$//;

                # if there is no $ in the string record it
                unless ( $string =~ /\$\D.*/ ) {

                    # this guarantees one instance of string
                    $locale{$string} = 1;

                    # is it a submit button before $locale->
                    if (/type="?submit"?/i) {
                        $submit{$string} = 1;
                    }
                }
            }

            # exit loop if there are no more locales on this line
            ($rc) = ( $' =~ /\$locale->text/ );

            # strip text
            s/^.*?\$locale->text.*?\)//;
        }
    }

    close($fh);

}

sub scanmenu {
    my $file = shift;

    my $fh = new FileHandle;
    open $fh, '<', "$file" or die "$! : $file";

    my @a = grep /^\[/, <$fh>;
    close($fh);

    # strip []
    grep { s/(\[|\])//g } @a;

    foreach my $item (@a) {
        $item =~ s/ *$//;
        @b = split /--/, $item;
        foreach $string (@b) {
            chomp $string;
            if ( $string !~ /^\s*$/ ) {
                $locale{$string} = 1;
            }
        }
    }

}

