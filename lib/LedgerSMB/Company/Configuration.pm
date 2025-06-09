

package LedgerSMB::Company::Configuration;

=head1 NAME

LedgerSMB::Company::Configuration - Entry-point for company configuration

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new(connect_data => { ... })
       ->connect;
   my $c = LedgerSMB::Company->new(dbh => $dbh)->configuration;

   # Get the session duration validity
   print 'Session time-out after: ' . $c->setting('session_timeout');

   # Set the value of a setting
   $c->setting('company_name', 'Acme, Inc.');

=head1 DESCRIPTION

Access to the various parts of the company configuration, including
settings, accounts, account headings, currency setup, standardized
industry codes (SIC), etc.

Please note that the only correct procedure to get an instance of this
class is through a L<LedgerSMB::Company> instance.  That is the only
supported entry-point for the Perl API.

=cut


use warnings;
use strict;

use Log::Any qw($log);

use LedgerSMB::Company::Configuration::COANodes;
use LedgerSMB::Company::Configuration::Currencies;
use LedgerSMB::Company::Configuration::GIFIs;
use LedgerSMB::Company::Configuration::SICs;

use Moose;
use namespace::autoclean;

use List::Util qw/any/;
use XML::LibXML qw( :libxml );


=head1 ATTRIBUTES

=head2 dbh (required)

This attribute is required and automatically passed into the instance
upon instantiation by C<LedgerSMB::Company>.

=cut

has '_dbh' => (
    is => 'ro',
    init_arg => 'dbh',
    reader   => 'dbh',
    required => 1);

=head2 coa_nodes

Holds a L<LedgerSMB::Company::Configuration::COANodes> instance, representing
the configuration of the chart of accounts with its headings.

This attribute cannot be set at object instantiation.

=cut

has coa_nodes => (
    is => 'ro',
    init_arg => undef,
    builder => '_build_coa');

sub _build_coa {
    my $self = shift;
    return LedgerSMB::Company::Configuration::COANodes->new(
        dbh => $self->dbh
        );
}

=head2 currencies

Holds a L<LedgerSMB::Company::Configuration::Currencies> instance, providing
access to the currency setup, i.e. available currencies and default currency.

This attribute cannot be set at object instantiation.

=cut

has currencies => (
    is => 'ro',
    init_arg => undef,
    builder => '_build_currencies');

sub _build_currencies {
    my $self = shift;
    return LedgerSMB::Company::Configuration::Currencies->new(
        dbh => $self->dbh
        );
}

=head2 gifi_codes

Holds a L<LedgerSMB::Company::Configuration::GIFIs> instance, providing
access to the L<GIFI|https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/corporations/corporation-income-tax-return/completing-your-corporation-income-tax-t2-return/general-index-financial-information-gifi.html>
setup in the company.

This attribute cannot be set at object instantiation.

=cut

has gifi_codes => (
    is => 'ro',
    init_arg => undef,
    builder => '_build_gifi_codes');

sub _build_gifi_codes {
    my $self = shift;
    return LedgerSMB::Company::Configuration::GIFIs->new(
        dbh => $self->dbh
        );
}

=head2 industry_codes

Holds a L<LedgerSMB::Company::Configuration::SICs> instance, providing
access to the setup of Standardized Industry Codes (SIC).

This attribute cannot be set at object instantiation.

=cut

has 'industry_codes' => (
    is => 'ro',
    init_arg => undef,
    builder => '_build_industry_codes');

sub _build_industry_codes {
    my $self = shift;
    return LedgerSMB::Company::Configuration::SICs->new(
        dbh => $self->dbh
        );
}


=head1 METHODS

=head2 from_xml($source)

Configures the company based on the XML content provided in C<$source>,
which can be either a string or a file handle. In case of a string,
C<$source> is interpreted as an XML source document. In case of a file
handle, the XML content will be read from the backing file. The file handle
should be opened in C<:raw> mode.

The specification of the XML structure (XSD) can be found at
C<doc/company-setup/configuration.xsd> in the LedgerSMB repository.

=cut

sub _process_gifis {
    my ($self, $gifis_xml) = @_;
    my $gifis = $self->gifi_codes;

    my $gifi_xml = $gifis_xml->firstChild;
    while (1) {

        if ($gifi_xml->nodeType == XML_ELEMENT_NODE) {
            my $code = $gifi_xml->getAttribute('code');
            my $desc = $gifi_xml->getAttribute('description');

            my $gifi = $gifis->create(code => $code, description => $desc);
            $gifi->save;
        }

        $gifi_xml = $gifi_xml->nextSibling;
        last unless $gifi_xml;
    }

    return;
}

sub _process_account_links {
    my ($self, $acclink_xml) = @_;
    my @links;

    my $node_xml = $acclink_xml->firstChild;
    while ($node_xml) {
        if ($node_xml->nodeType == XML_ELEMENT_NODE) {
            if ($node_xml->nodeName eq 'link') {
                push @links, $node_xml->getAttribute('code');
            }
        }
        $node_xml = $node_xml->nextSibling;
    };

    return @links;
}

sub _process_account_taxes {
    my ($self, $acctax_xml) = @_;
    my @taxes;
    my @tax_nodes;

    my $node = $acctax_xml->firstChild;
    while ($node) {
        if ($node->nodeType == XML_ELEMENT_NODE) {
            if ($node->nodeName eq 'tax') {
                push @tax_nodes, $node;
            }
        }
        $node = $node->nextSibling;
    }

    $node = shift @tax_nodes;
    if ($node and not @tax_nodes) {
        $node = $node->firstChild;
        while ($node) {
            if ($node->nodeType == XML_ELEMENT_NODE) {
                if ($node->nodeName eq 'rate') {
                    push @taxes, {
                        rate      => $node->getAttribute('value'),
                        pass      => $node->getAttribute('pass') // 0,
                        validto   => $node->getAttribute('valid-to') // 'infinity',
                        min_value => $node->getAttribute('min-value'),
                        max_value => $node->getAttribute('max-value'),
                        taxmodule => $node->getAttribute('taxmodule') // 'Simple',
                    };
                }
            }
            $node = $node->nextSibling;
        }
    }
    elsif (@tax_nodes) {
        die 'Too many <tax> child tags of <account> tag at line ' . $tax_nodes[0]->line_number;
    }
    return @taxes;
}

sub _process_coa_translations {
    my ($self, $node_xml_parent) = @_;
    my @translations;

    my $node_xml = $node_xml_parent->firstChild;
    while ($node_xml) {
        if ($node_xml->nodeType == XML_ELEMENT_NODE) {
            if ($node_xml->nodeName eq 'translation') {
                my $child = $node_xml->firstChild;
                if ($child and $child->nodeType == XML_TEXT_NODE) {
                    push @translations, {
                        lang        => $node_xml->getAttribute('lang'),
                        description => ($child->textContent =~ s/^\s+|\s+$//gr),
                    };
                }
                else {
                    die q{Non-text child element to account's <translation> at line } . $child->line_number;
                }
            }
        }
        $node_xml = $node_xml->nextSibling;
    };
    return @translations;
}


my %account_category = (
    'Asset'              => 'A',
    'Liability'          => 'L',
    'Equity'             => 'Q',
    'Equity (temporary)' => 'Q',
    'Income'             => 'I',
    'Expense'            => 'E',
    );


sub _process_coa_account {
    my ($self, $account_xml, $parent) = @_;

    my $accno = $account_xml->getAttribute('code');
    die "Found account with code '$accno' missing a heading"
        unless $parent;

    my %args;
    for my $arg (qw(description category contra recon
                    obsolete is_temp gifi)) {
        my $value = $account_xml->getAttribute($arg);
        $args{$arg} = $value if defined $value;
    }

    if (not exists $account_category{$args{category}}) {
        die "Unknown account category '$args{category}' on line "
            . $account_xml->line_number;
    }
    $args{category} = $account_category{$args{category}};
    $args{is_temp} = ($args{category} eq 'Equity (temporary)') ? 1 : 0;

    my @links = $self->_process_account_links($account_xml);
    my @taxes = $self->_process_account_taxes($account_xml);
    my @translations = $self->_process_coa_translations($account_xml);
    my $account = $self->coa_nodes->create(
        type        => 'account',
        accno       => $accno,
        heading_id  => $parent->id,
        gifi_id     => $args{gifi},
        link        => \@links,
        tax         => (scalar @taxes > 0 ? 1 : 0),
        %args,
        );
    $account->save;
    # add links, taxes and translations!
    $account->translation($_->{lang}, $_->{description})
        for (@translations);
    $account->add_tax_rate(%$_)
        for (@taxes);

    return;
}

sub _process_coa_heading {
    my ($self, $heading_xml, $parent) = @_;

    my $heading = $self->coa_nodes->create(
        type        => 'heading',
        ###TODO: assert 'code' is supplied!
        accno       => $heading_xml->getAttribute('code'),
        description => $heading_xml->getAttribute('description'),
        category    => $heading_xml->getAttribute('category'),
        heading_id  => $parent ? $parent->id : undef,
        );
    my @translations = $self->_process_coa_translations($heading_xml);

    $heading->save;
    $heading->translation($_->{lang}, $_->{description})
        for (@translations);

    $self->_process_coa_nodes($heading_xml, $heading);
    return;
}

sub _process_coa_nodes {
    my ($self, $nodes_xml_parent, $parent_node) = @_;

    my $node_xml = $nodes_xml_parent->firstChild;
    while (1) {

        last unless $node_xml;
        if ($node_xml->nodeType == XML_ELEMENT_NODE) {
            if ($node_xml->nodeName eq 'account-heading') {
                $self->_process_coa_heading($node_xml, $parent_node);
            }
            elsif ($node_xml->nodeName eq 'account') {
                $self->_process_coa_account($node_xml, $parent_node);
            }
        }

        $node_xml = $node_xml->nextSibling;
    }
    return;
}

sub _process_coa {
    my ($self, $coa_xml) = @_;

    $self->_process_coa_nodes($coa_xml);
    return;
}

sub _process_currencies {
    my ($self, $currs_xml) = @_;
    my $currencies = $self->currencies;

    my $curr_xml = $currs_xml->firstChild;
    while (1) {

        last unless $curr_xml;
        if ($curr_xml->nodeType == XML_ELEMENT_NODE) {
            ###TODO verify element name!
            my $code = $curr_xml->getAttribute('code');
            my $desc = ($curr_xml->firstChild->textContent
                        =~ s/^\s+|\s+$//gr);

            my $curr = $currencies->create(code => $code, description => $desc);
            $curr->save;
        }

        $curr_xml = $curr_xml->nextSibling;
    }

    $currencies->default($currs_xml->getAttribute('default'));
    return;
}

sub _process_settings {
    my ($self, $settings_xml) = @_;

    my $setting_xml = $settings_xml->firstChild;
    while (1) {

        if ($setting_xml->nodeType == XML_ELEMENT_NODE) {
            my $name  = $setting_xml->getAttribute('name');
            my $value;

            if ($setting_xml->hasAttribute('accno')) {
                my $accno = $setting_xml->getAttribute('accno');

                my $account = $self->coa_nodes->get(by => (code => $accno));

                ###BUG: This builds on knowledge of the 'account.id'
                $value = $account->id =~ s/[HA]-//r;
            }
            else {
                $self->setting($name, $setting_xml->getAttribute('value'));
            }
            $self->setting($name, $value);
        }

        $setting_xml = $setting_xml->nextSibling;
        last unless $setting_xml;
    }

    return;
}


sub _skip_text_siblings {
    my $item = shift;

    while ($item and $item->nodeType != XML_ELEMENT_NODE) {
        $item = $item->nextSibling;
        if ($item and $item->nodeType == XML_TEXT_NODE) {
            my $text = $item->nodeValue;
            die "Unexpected text '$text' in XML"
                if $text !~ m/^\s*$/;
        }
    }
    return $item;
}

sub from_xml {
    my $self       = shift;
    my $source     = shift;
    my $input_type = (ref $source) ? 'IO' : 'string';
    binmode($source)  if (ref $source);

    my $doc  = XML::LibXML->load_xml( $input_type => $source );
    my $root = $doc->documentElement;
    my $item = _skip_text_siblings($root->firstChild);

    # $root is a <configuration> tag, which has the following children:
    #   documentation            (optional)
    #   gifi-list                (optional)
    #   custom-account-link-list (optional)
    #   coa                      (required)
    #   currencies               (required)
    #   settings                 (required)
    if ($item and $item->nodeName eq 'documentation') {
        $item = _skip_text_siblings($item->nextSibling);
    }
    if ($item and $item->nodeName eq 'gifi-list') {
        $self->_process_gifis($item);
        $item =  _skip_text_siblings($item->nextSibling);
    }
    if ($item and $item->nodeName eq 'custom-account-link-list') {
        $self->_process_custom_account_links($item);
        $item =  _skip_text_siblings($item->nextSibling);
    }
    if ($item and $item->nodeName eq 'coa') {
        $self->_process_coa($item);
        $item =  _skip_text_siblings($item->nextSibling);
    }
    else {
        die 'Expected "coa" tag, but found: '
            . ($item ? $item->toString : '(nothing)');
    }
    if ($item and $item->nodeName eq 'currencies') {
        $self->_process_currencies($item);
        $item =  _skip_text_siblings($item->nextSibling);
    }
    else {
        die 'Expected "currencies" tag, but found '
            . ($item ? $item->nodeName : '(nothing)');
    }
    if ($item and $item->nodeName eq 'settings') {
        $self->_process_settings($item);
        $item =  _skip_text_siblings($item->nextSibling);
    }
    else {
        die 'Expected "settings" tag, but found '
            . ($item ? $item->nodeName : '(nothing)');
    }
    # (not expecting any other input!)
}


=head2 setting($name, [$new_value])

Returns the value of company setting C<$name> when C<$new_value> is not
provided, or sets the value when C<$new_values> is provided.

=cut

sub setting {
    my $self     = shift;
    my $name     = shift;
    my $newvalue = shift;

    my $oldvalue;
    if (defined $newvalue) {
        $log->infof('Updating setting %s to "%s"', $name, $newvalue);
        $self->dbh->do(
            q{INSERT INTO defaults (setting_key, value) VALUES ($1, $2)
            ON CONFLICT (setting_key) DO UPDATE SET value = $2}, {},
            $name, $newvalue);
    }
    return $oldvalue;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
