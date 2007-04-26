#=====================================================================
#
# Template support module for LedgerSMB
# LedgerSMB::Template
#
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2007
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.
#
#
#======================================================================
# This package contains template related functions:
#
#
#====================================================================
use Error qw(:try);
use Template;
use LedgerSMB::Sysconfig;

package LedgerSMB::Template;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{myconfig} = shift;
    $self->{template} = shift;
    $self->{format}   = shift;
    $self->{language} = shift;
    $self->{output}   = '';
    bless $self, $class;
    return $self;
}

sub valid_language {
    my $self = shift;

    # XXX Actually perform validity checks
    return 1;
}

sub render {
    my $self = shift;
    my $vars = shift;
    my $template;

    if ( not defined $self->{language} ) {
        $template = Template->new(
            {
                INCLUDE_PATH => $self->{'myconfig'}->{'templates'},
                START_TAG    => quotemeta('<?lsmb'),
                END_TAG      => quotemeta('?>'),
                DELIMITER    => ';',
            }
        ) || throw Error::Simple Template->error();
    }
    elsif ( $self->valid_language() ) {
        $template = Template->new(
            {
                INCLUDE_PATH =>
"$self->{'myconfig'}->{'templates'}/$self->{language};$self->{'myconfig'}->{'templates'}",
                START_TAG => quotemeta('<?lsmb'),
                END_TAG   => quotemeta('?>'),
                DELIMITER => ';',
            }
        ) || throw Error::Simple Template->error();
    }
    else {
        throw Error::Simple 'Invalid language';
    }

    eval "require LedgerSMB::Template::$self->{format}";
    if ($@) {
        throw Error::Simple $@;
    }

    my $cleanvars =
      &{"LedgerSMB::Template::$self->{format}::preprocess"}($vars);
    if (
        not $template->process(
            &{"LedgerSMB::Template::$self->{format}::get_template"}(
                $self->{template} ),
            $cleanvars,
            \$self->{output},
            binmode => ':utf8'
        )
      )
    {
        throw Error::Simple $template->error();
    }

    &{"LedgerSMB::Template::$self->{format}::postprocess"}($self);

    return $self->{output};
}

1;
