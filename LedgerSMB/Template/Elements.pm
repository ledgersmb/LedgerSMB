=head1 NAME

LedgerSMB::Template::Elements:  Template Utility Functions

=head1 SYNOPSIS

Provides utility functions for generating elements for the user interface
templates

=head1 METHODS

=over

=item $object->generate_hidden_elements([...]);
 
Builds data structure for hidden form fields.  Values from the
$form object are run through $form->quote.
 
Sample data structure added to $form->hidden_elements():
 
 $self->{form_elements}{hidden_elements} = [{ type => 'hidden', name => 'foo', value => 'bar'... } ...]

A reference to this structure is returned as well.

=back

=cut

package LedgerSMB::Template::Element;
use strict;
 
sub generate_hidden_elements {
    my $self = shift;
    
    if (! $self->{form_elements}{hidden_elements} ) {
    	$self->{form_elements}{hidden_elements} = [];
    }
 
    for (@_) {
    	my $value = defined($self->{$_}) ? $self->quote( $self->{$_} ) : '';
    	push @{$self->{form_elements}{hidden_elements}}, { type => 'hidden', name => $_, value => $value };
    }
    return $self->{form_elements}{hidden_elements};
}

=over
 
=item $form->generate_radio_elements($radios);
 
Roll out a single radios hash to an array of radio elements,
using the values array as index.
 
Sample data structure added to $form->generate_radio_elements($radios):
 
my $radios = {
    name => 'radio_name',
    class => 'radio',
    attributes => { foo => 'bar' },
    values => [ '1', '2', '3'],
    labels => [ 'Label one', '', 'Label three'],
};
 
=back

=cut

sub generate_radio_elements {
    
    my $self = shift;
    my $radios = shift;
    
    my $elements = [];
    my $i = 0;
 
    # One new radio element for each listed value.
    foreach my $radio_value ( @{$radios->{values}} ) {
        my $element = {};

        # copy all additional attributes 
        while ( my ($key, $value) = each(%$radios) ) {
            if ( $key !~ /^(values|labels|id|value)$/ ) {
                $element->{$key} = $value;
            }
        }
        $element->{id} = $radios->{name} .'-'. $radio_value;

        # id tags with only numbers, letters, and dashes -- nicer CSS.
        $element->{id} =~ s/[^\p{IsAlnum}]/-/g;
        $element->{value} = $radio_value;
        $element->{type} = 'radio';

        # Add label key if present for this element.

        if ( $radios->{labels}[$i] ) {
            $element->{label} = $radios->{labels}[$i];
        }
        push @$elements, $element;
        $i++;
    }
    
    return $elements;
}

=over
 
=item $form->generate_checkbox_elements($checkboxes);
 
Roll out a single checkboxes hash to an array of checkbox elements,
using the names array as index.  Note that if no 'values' array
is passed, value for all checkboxes default to 1.
 
Sample data structure added to $form->generate_checkbox_elements($checkboxes):
 
my $checkboxes = {
    names => [
        'checkbox_name1',
        'checkbox_name2',
        'checkbox_name3',
    ],
    class => 'checkbox',
    attributes => { foo => 'bar' },
    values => [ '4', '', '3'],
    labels => [ 'Label one', '', 'Label three'],
    
};

=back

=cut
 
sub generate_checkbox_elements {
    
    my $self = shift;
    my $checkboxes = shift;
    
    my $elements = [];
    my $i = 0;
 
    # One new checkbox element for each listed name.
    foreach my $checkbox_name ( @{$checkboxes->{names}} ) {
        my $element = {};

        # Additional attributes
        while ( my ($key, $value) = each(%$checkboxes) ) {
            if ( $key !~ /^(names|values|labels|id|value|name)$/ ) {
                $element->{$key} = $value;
            }
        }
        # Value defaults to 1 if not passed for this element.

        $element->{value} = defined($checkboxes->{values}[$i]) 
                          ? $checkboxes->{values}[$i] 
                          : '1';
        $element->{name} = $checkbox_name;
        $element->{id} = $element->{name};
        # id tags with only numbers, letters, and dashes -- nicer CSS.
        $element->{id} =~ s/[^\p{IsAlnum}]/-/g;
        $element->{type} = 'checkbox';
        # Add label key if present for this element.
        if ( $checkboxes->{labels}[$i] ) {
            $element->{label} = $checkboxes->{labels}[$i];
        }
        push @$elements, $element;
        $i++;
    }
    
    return $elements;
}
