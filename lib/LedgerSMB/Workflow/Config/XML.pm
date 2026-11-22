
use v5.38;
use experimental qw( signatures try );

package LedgerSMB::Workflow::Config::XML;

=head1 NAME

LedgerSMB::Workflow::Config::XML - XML parser for workflow configuration

=head1 SYNOPSIS

  use LedgerSMB::Workflow::Config::XML;

  my @config = LedgerSMB::Workflow::Config::XML->parse('workflow', 'workflow.xml');

=head1 DESCRIPTION

This module implements a parser for workflow configuration files in XML format.

=head1 METHODS

=cut

use parent qw( Workflow::Config );

use Log::Any qw( $log );
use Workflow::Config;
use XML::LibXML;

use constant WF_NS   => 'http://ledgersmb.org/xml-schemas/workflows';

sub _is_wf_element($node) {
    return ($node isa 'XML::LibXML::Element'
            and ($node->namespaceURI // '') eq WF_NS );
}

sub _wf_children($node) {
    return grep { _is_wf_element($_) } $node->nonBlankChildNodes;
}

sub _children_named($node, $name) {
    return grep { $_->localname eq $name } _wf_children($node);
}

# Schema attributes are unqualified, so namespaced attributes are skipped, as
# are attributes not declared for the element. Hyphenated XML names become
# underscored Perl keys. Defaults are applied for absent attributes.
sub _read_attributes($node, $allowed, %defaults) {
    my %h = %defaults;
    for my $attr ($node->attributes) {
        next unless $attr isa XML::LibXML::Attr;
        next if defined $attr->namespaceURI;

        my $xml_name = $attr->nodeName;
        next unless grep { $_ eq $xml_name } @$allowed;
        (my $key = $xml_name) =~ tr/-/_/;
        $h{$key} = $attr->value;
    }
    return \%h;
}

# For elements whose schema type has anyAttribute: declared attributes are read
# as above; any other attribute is kept under its local name, whatever its
# namespace. A namespaced attribute whose local name is declared is ignored so
# it cannot overwrite the declared value.
sub _read_open_attributes($node, $declared, %defaults) {
    my $h = _read_attributes($node, $declared, %defaults);
    my %declared = map { $_ => 1 } @$declared;
    for my $attr ($node->attributes) {
        next unless $attr isa XML::LibXML::Attr;

        my $xml_name = $attr->localname;
        next if $declared{$xml_name};
        (my $key = $xml_name) =~ tr/-/_/;
        $h->{$key} = $attr->value;
    }
    return $h;
}

sub _parse_actions($node) {
    my $h = _read_attributes($node, ['type']);
    $h->{action} = [
        map {
            _parse_action($_)
        } _children_named($node, 'action')
        ];
    return $h;
}

sub _parse_action($node) {
    my $h = _read_open_attributes($node, ['name', 'class', 'description']);
    $h->{field} = [
        map {
            _parse_field($_)
        } _children_named($node, 'field')
        ];
    $h->{validator} = [
        map {
            _parse_action_validator($_)
        } _children_named($node, 'validator')
        ];
    return $h;
}

sub _parse_field($node) {
    my $h = _read_attributes($node, ['is-required', 'type'],
                            is_required => 'no');
    my @kids = _wf_children($node);
    my @params = grep { $_->localname eq 'param' } @kids;

    $h->{param} = [
        map {
            _read_attributes($_, ['name', 'value'])
        } @params
        ];

    # The schema orders the optional param elements before the source choice.
    my $choice = @params ? $params[-1]->nextNonBlankSibling : $kids[0];

    if ($choice && _is_wf_element($choice)) {
        if ($choice->localname eq 'source-list') {
            $h->{source_list} = [
                map {
                    $_->textContent
                } _children_named($choice, 'item')
                ];
        }
        else {
            $h->{source_class} = $choice->textContent;
        }
    }
    return $h;
}

sub _parse_action_validator($node) {
    my $h = _read_attributes($node, ['name']);
    $h->{arg} = [ map { $_->textContent } _children_named($node, 'arg') ];
    return $h;
}

sub _parse_conditions($node) {
    my $h = _read_attributes($node, ['type']);
    $h->{condition} = [
        map {
            _parse_condition($_)
        } _children_named($node, 'condition')
        ];
    return $h;
}

sub _parse_condition($node) {
    my $h = _read_open_attributes($node, ['name', 'class']);
    $h->{param} = [
        map {
            _read_attributes($_, ['name', 'value'])
        } _children_named($node, 'param')
        ];
    return $h;
}

sub _parse_observers($node) {
    my $h = _read_attributes($node, []);
    $h->{observer} = [
        map {
            _read_attributes($_, ['name', 'type', 'class', 'sub'])
        } _children_named($node, 'observer')
        ];
    return $h;
}

sub _parse_validators($node) {
    my $h = _read_attributes($node, []);
    $h->{validator} = [
        map {
            _parse_validator($_)
        } _children_named($node, 'validator')
        ];
    return $h;
}

sub _parse_validator($node) {
    my $h = _read_attributes($node, ['name', 'class']);
    $h->{param} = [
        map {
            _read_attributes($_, ['name', 'value'])
        } _children_named($node, 'param')
        ];
    return $h;
}

sub _parse_persisters($node) {
    my $h = _read_attributes($node, []);
    $h->{persister} = [
        map {
            _parse_persister($_)
        } _children_named($node, 'persister')
        ];
    return $h;
}

sub _parse_persister($node) {
    return _read_open_attributes(
        $node,
        ['name', 'class', 'use-random', 'use-uuid'],
        use_random => 'no',
        use_uuid => 'no');
}

sub _parse_workflow($node) {
    my $h = _read_attributes(
        $node,
        ['class', 'type', 'persister', 'initial-state'],
        class => 'Workflow',
        initial_state => 'INITIAL');
    $h->{state} = [
        map {
            _parse_state($_)
        } _children_named($node, 'state')
        ];
    $h->{observer} = [
        map {
            _read_attributes($_, ['class', 'sub'])
        } _children_named($node, 'observer')
        ];
    return $h;
}

sub _parse_state($node) {
    my $h = _read_attributes(
        $node,
        ['name', 'autorun', 'may-stop'],
        autorun => 'no',
        may_stop => 'no');
    $h->{action} = [
        map {
            _parse_state_action($_)
        } _children_named($node, 'action')
        ];
    return $h;
}

# The "resulting-state" attribute and the "resulting-state" child elements
# share the key resulting_state: only one of them is used per state action.
# When child elements are present, they take precedence.
sub _parse_state_action($node) {
    my $h = _read_attributes(
        $node,
        ['name', 'resulting-state']);
    my @resulting = map {
        _read_attributes($_, ['return', 'state'])
    } _children_named($node, 'resulting-state');
    $h->{resulting_state} = \@resulting if @resulting;

    $h->{condition} = [
        map {
            _read_attributes($_, ['name'])
        } _children_named($node, 'condition')
        ];
    return $h;
}

my %ROOT_PARSERS = (
    actions    => \&_parse_actions,
    conditions => \&_parse_conditions,
    observers  => \&_parse_observers,
    validators => \&_parse_validators,
    persisters => \&_parse_persisters,
    workflow   => \&_parse_workflow,
);


=head2 parse($type, @sources)



=cut

# $source may be a file name, a file handle, or a scalar reference holding
# the XML text.
sub parse($self, $type, @items) {
    my $fh;

    $self->_check_config_type($type);
    my @config_items = Workflow::Config::_expand_refs(@items);
    return () unless ( scalar @config_items );

    my $parser = XML::LibXML->new;
    my @config;
    for my $source (@config_items) {
        try {
            my $doc;
            if (ref($source) eq 'SCALAR') {
                open $fh, '<', $source or die "Cannot read input string: $!\n";
                $doc = $parser->load_xml(IO => $fh);
            }
            elsif (ref $source) {
                $doc = $parser->load_xml(IO => $source);
            }
            else {
                open $fh, '<:raw', $source or die "Cannot open '$source': $!\n";
                $doc = $parser->load_xml(IO => $fh);
            }

            my $root = $doc->documentElement;
            my $parse_root =
                _is_wf_element($root) && $ROOT_PARSERS{ $root->localname };

            unless ($parse_root) {
                die q{Unsupported root element '} .
                    $root->localname .
                    q{' in namespace '} .
                    ($root->namespaceURI // '') . "'\n";
            }

            my $config = $parse_root->($root);
            if (exists $config->{type}) {
                push @config, $config;
            }
            elsif ( $type eq 'persister'
                    and ref $config->{'persister'} eq 'ARRAY' ) {
                push @config, @{ $config->{'persister'} };
            }
            else {
                push @config, $config;
            }
        }
        catch ($e) {
            die "Failed to parse workflow source: $e";
        }
    }

    return @config;
}


Workflow::Config->unregister_factory_type( 'xml' );
Workflow::Config->register_factory_type( xml => __PACKAGE__ );

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

