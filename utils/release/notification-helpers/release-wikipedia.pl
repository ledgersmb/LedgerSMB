#!/usr/bin/perl

#### http://search.cpan.org/~exobuzz/MediaWiki-API-0.41/lib/MediaWiki/API.pm
use MediaWiki::API;
use strict;
use warnings;

  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = 'http://en.wikipedia.org/w/api.php';

#  # get user info
#  my $userinfo = $mw->api( {
#    action => 'query',
#    meta => 'userinfo',
#    uiprop => 'blockinfo|hasmsg|groups|rights|options|editcount|ratelimits' } );
#

#Which version of true / false constants is more correct?
use constant false => 0;
use constant true  => 1;
#use constant false => 1==0;
#use constant true => not false;

sub usage {
    print '
    wikipedia-update.pl [boilerplate|Wikipage] [stable|preview] [NewVersion] [NewDate] [UserName Password]
        boilerplate :   writes a sample {{ Infobox software }} to "User:Sbts.david/sandbox"
                        You would only use this for testing the script or login credentials.
        Wikipage    :   The pagename you wish to edit.
                        Defaults to "User:Sbts.david/sandbox"
                        You can also use the *shared* sandbox
                            "Wikipedia:Sandbox"
                            which will force the boilerplate option.
                        for LedgerSMB you need "LedgerSMB"
        stable      :   Edit the Stable Release Version and Date
        preview     :   Edit the Preview Release Version and Date
        NewVersion  :   The New Version Number (valid characters [a..zA..Z0..9-._] )
        NewDate     :   The New Date (valid characters [0..9-] )
        
        UserName    :   UserName and Password, if used must BOTH be supplied.
        Password        If either one is missing anonymous edits will be done
                        Anonymous Edits will expose your IP address to the public
                        
        Any field that is set to "" will use its default value
        Any field that you want to use the default value for should be set to ""
            unless there are no following fields that will be needed.
    '
}
#    my $pagename = "Wikipedia:Sandbox";
    my $WriteBoilerplate = false;
    my $pagename = shift;
    if ( length($pagename || ''))   {
        if ( $pagename   eq "boilerplate" ) {
            $pagename = "User:Sbts.david/sandbox";
            $WriteBoilerplate = true;
        } elsif ($pagename  eq "Wikipedia:Sandbox" ) {
            $WriteBoilerplate = true;
        }
    }
    my $EditStable = shift;
    my $NewVersion = shift;
    my $NewDate = shift;
    my $UserName = shift;
    my $Password = shift;
    if ( ! length($pagename || ''))   { $pagename   = "User:Sbts.david/sandbox"; }
    if ( ! length($EditStable || '')) { $EditStable = "stable"; }
    if ( ! length($NewVersion || '')) { $NewVersion = '99.99.99'; }
    if ( ! length($NewDate    || '')) { $NewDate    = '2999-01-01'; }
    if ( ! length($UserName    || '')) { $UserName = ""; }
    if ( ! length($Password    || '')) { $Password = ""; }

print "Updating wikipedia page with the following information\n";
if ( $WriteBoilerplate ) { print "Writing Boilerplate Infobox to sandbox.\n"; }
print "pagename   = $pagename\n";
print "EditStable = $EditStable\n";
print "NewVersion = $NewVersion\n";
print "NewDate    = $NewDate\n";

my $usersandboxheader = '{{User sandbox}}';
my $wikipediasandboxheader = '{{Please leave this line alone (sandbox heading)}}<!--
*               Welcome to the sandbox!              *
*            Please leave this part alone            *
*           The page is cleared regularly            *
*     Feel free to try your editing skills below     *
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■-->
';

    if ( $pagename eq "User:Sbts.david/sandbox" ) { my $sandboxheader = "$usersandboxheader"; }
    elsif ( $pagename eq "Wikipedia:Sandbox" ) { my $sandboxheader = "$wikipediasandboxheader"; }
    else { my $sandboxheader = ""; }

my $infobox = '
{{Infobox software
| name = LedgerSMB
| logo =
| screenshot = [[Image:LedgerSMB Login Screen.png|200px]]
| caption = LedgerSMB login screen
| author =
| developer =
| released = 2006-09-06
| latest release version = 0.0.0
| latest release date = 1970-01-01
| latest preview version = 0.0.0-beta1
| latest preview date = 1970-01-01
| operating system = Any [[Unix-like]], [[Mac OS]], [[Microsoft Windows|Windows]], [[Android (operating system)|Android]]
| programming language = [[Perl]], [[PL/SQL]]
| platform = [[Cross-platform]]
| language =
| status = Active
| genre = [[Accounting]], [[Enterprise resource planning|ERP]], [[Customer relationship management|CRM]]
| license = [[GNU General Public License]]
| website = [http://ledgersmb.org/ ledgersmb.org]
}}
';

sub login {
    if ( length($UserName || '') && length($Password || '') ) { # the username and password is set to something other than null, 0, "0" so we can try logging in
        # log in to the wiki
        print "\n\n**** Logging In as $UserName.";
        $mw->login( { lgname => $UserName, lgpassword => $Password } )
            || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
    }
}

sub logout() {
        $mw->logout();  ## die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
}

sub getpage {
  # get some page contents
  my $page = $mw->get_page( { title => $pagename } );
    return $page;
}

sub printpage {  # print page contents
    my $page = shift;
    my $title = shift;
    print "\n\n===============================\n";
    print "$title\n";
    print "===============================\n";
    print $page->{'*'};
    print "\n==============================\n\n";
}

sub editpage {
    my $editStable = shift;
    my $newversion = shift;
    my $newdate = shift;
    $newversion =~ s/[^\w\-\.]//g;        # sanitize by stripping chars that are not whitelisted
    $newdate =~ s/[^\d\-]//g;            # sanitize by stripping chars that are not whitelisted

    my $ref = $mw->get_page( { title => $pagename } );
    my $text = $ref->{'*'};
    if ( $WriteBoilerplate ) {
        $text = $infobox;
        print $text;
    }
    if ( $mw->{config}->{api_url} =~ /en.wiki/ ) { # english regex
        if ( $editStable eq "stable" ) {
            $text =~ s/(latest release version) = .*\n/$1 = $newversion \n/m;
            $text =~ s/(latest release date) = .*\n/$1 = $newdate \n/m;
        } elsif ( $editStable eq "preview" ) {
            $text =~ s/(latest preview version) = .*\n/$1 = $newversion \n/m;
            $text =~ s/(latest preview date) = .*\n/$1 = $newdate \n/m;
        } else {
            die "editpage():  Nothing to edit.";
        }
    } elsif ( $mw->{config}->{api_url} =~ /es.wiki/ ) {  # spanish regex
        if ( $editStable eq "stable" ) {
#            $text =~ s/última_versión\s*= .*\n/última_versión              = $newversion \n/m;
#            $text =~ s/fecha_última_versión\s*= .*\n/fecha_última_versión        = $newdate \n/m;
            $text =~ s/(.ltima_versi.n)\s*= .*$/$1              = $newversion \n/m;
            $text =~ s/(fecha_.ltima_versi.n)\s*= .*\n/$1        = $newdate \n/m;
        } elsif ( $editStable eq "preview" ) {
            $text =~ s/(.ltima_versi.n_prueba)\s*= .*\n/$1      = $newversion \n/m;
            $text =~ s/(fecha_.ltima_versi.n_prueba)\s*= .*\n/$1         = $newdate \n/m;
        } else {
            die "editpage():  Nothing to edit.";
        }
    } # else we don't alter anything.
    unless ( $ref->{missing} ) {
        my $timestamp = $ref->{timestamp};
        $mw->edit( {
            action => 'edit',
            title => $pagename,
            basetimestamp => $timestamp, # to avoid edit conflicts
            minor => '',
            bot => '',
            summary => "Release Version Update",
            text => $text
        } ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
    }
}
usage();
print "\n";
#printpage( getpage(), "==== Original Page Content ====" );

#### Edit the English Page
$mw->{config}->{api_url} = 'http://en.wikipedia.org/w/api.php';
login();
editpage( 'stable', $NewVersion, $NewDate );
print " view the changes at \n";
print " https://en.wikipedia.org/wiki/$pagename\n";

logout();

#### Edit the Spanish Page
$mw->{config}->{api_url} = 'http://es.wikipedia.org/w/api.php';
$pagename =~ s/User:/Usuario:/;  # if we are using a users pagename then translate the 'User:' portion of the name
login();
editpage( 'stable', $NewVersion, $NewDate );
print " view the changes at \n";
print " https://es.wikipedia.org/wiki/$pagename\n";
print "\n\n";

logout();

=head1
=cut

exit ;
