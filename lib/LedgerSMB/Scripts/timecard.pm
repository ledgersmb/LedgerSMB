
package LedgerSMB::Scripts::timecard;

=head1 NAME

LedgerSMB::Scripts::timecard - LedgerSMB workflow routines for timecards.

=head1 SYNPOSIS

 LedgerSMB::Scripts::timecard::display($request, $tcard)

=head1 DESCRIPTION

This module contains the basic workflow scripts for managing timecards for
LedgerSMB.  Timecards are used to track time and materials consumed in the
process of work, from professional services to payroll and manufacturing.

=head1 METHODS

This module does not specify any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );

use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Business_Unit;
use LedgerSMB::Magic qw( MIN_PER_HOUR SEC_PER_HOUR SUNDAY SATURDAY );
use LedgerSMB::PGDate;
use LedgerSMB::PGTimestamp;
use LedgerSMB::Report::Timecards;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::UI;
use LedgerSMB::Timecard;
use LedgerSMB::Timecard::Type;

=head1 ROUTINES

=over

=item new

This begins the timecard workflow.  The following may be set as a default:

=over

=item business_unit_class

=item time_frame (1 for day, 7 for week)

=item date_from

=back

=cut

sub new {
    my ($request) = @_;
    @{$request->{bu_class_list}} = LedgerSMB::Business_Unit_Class->list();
    return LedgerSMB::Template::UI->new_UI
        ->render($request, 'timecards/entry_filter', $request);
}

=item display

Displays a timecard.  LedgerSMB::Timecard properties set are treated as
defaults.

=cut

sub display {
    my ($request, $tcard) = @_;
    $tcard->{non_billable} ||= 0;
    if ($tcard->{in_hour} and $tcard->{in_min}) {
        my $tcard->{min_used} =
            ($tcard->{in_hour} * MIN_PER_HOUR) + $tcard->{in_min} -
            ($tcard->{out_hour} * MIN_PER_HOUR) - $tcard->{out_min};
        $tcard->{qty} = $tcard->{min_used}/MIN_PER_HOUR - $tcard->{non_billable};
    } else { # Default to current date and time
        my $now = LedgerSMB::PGTimestamp->now;
        $tcard->{in_hour} = $now->hour unless defined $tcard->{in_hour};
        $tcard->{in_min} = $now->minute unless defined $tcard->{in_min};
    }
    @{$tcard->{b_units}} = LedgerSMB::Business_Unit->list(
          $tcard->{bu_class_id}, undef, 0, $tcard->{transdate}
    );
    @{$tcard->{currencies}} =
        $request->setting->get_currencies;
    $tcard->{total} =
        ($tcard->{qty} // 0) + ($tcard->{non_billable} // 0);
     my $template = LedgerSMB::Template::UI->new_UI;
     return $template->render($request, 'timecards/timecard', $tcard);
}

=item timecard_screen

This displays a screen for entry of timecards, either single day or week.

=cut

sub timecard_screen {
    my ($request) = @_;
    if (1 == $request->{num_days}){
        $request->{transdate} = $request->{date_from};
        return display($request, $request);
    } else {
         @{$request->{b_units}} = LedgerSMB::Business_Unit->list(
              $request->{bu_class_id}, undef, 0, $request->{transdate}
         );
         @{$request->{currencies}} =
             $request->setting->get_currencies;
         my $startdate = LedgerSMB::PGDate->from_input($request->{date_from});

         my @dates = ();
         for (SUNDAY .. SATURDAY){
             push @dates, $startdate->clone;
             $startdate->add_interval('day', 1);
         }
         $request->{num_lines} = 1 unless $request->{num_lines};
         $request->{transdates} = \@dates;
         my $template = LedgerSMB::Template::UI->new_UI;
         return
             $template->render($request, 'timecards/timecard-week', $request);
    }
}

=item save

=cut

sub save {
    my ($request) = @_;
    $request->{parts_id} =  LedgerSMB::Timecard->get_part_id(
           $request->{partnumber}
    );
    $request->{jctype} ||= 1;
    $request->{total} = ($request->{qty}//0) + ($request->{non_billable}//0);
    $request->{checkedin} = $request->{transdate};
    die $request->{_locale}->text('Please submit a start/end time or a qty')
        unless defined $request->{qty}
               or ($request->{checkedin} and $request->{checkedout});
    $request->{qty} //= _get_qty($request->{checkedin}, $request->{checkedout});
    my $timecard = LedgerSMB::Timecard->new(%$request);
    $timecard->save;
    $request->{id} = $timecard->id;
    $request->merge($timecard->get($request->{id}));
    $request->{templates} = ['timecard'];
    @{$request->{printers}} = %LedgerSMB::Sysconfig::printer; # List context
    return display($request, $request);
}

sub _get_qty {
    my ($checkedin, $checkedout) = @_;
    my $when_in = LedgerSMB::PGDate->from_input($checkedin);
    my $when_out = LedgerSMB::PGDate->from_input($checkedout);
    return ($when_in->epoch - $when_out->epoch) / SEC_PER_HOUR;
}

=item save_week

Saves a week of timecards.

=cut

sub save_week {
    my $request = shift @_;
    for my $row(1 .. $request->{rowcount}){
        for my $dow (SUNDAY  .. SATURDAY){
            my $date = $request->{"transdate_$dow"};
            my $hash = { transdate => LedgerSMB::PGDate->from_input($date),
                         checkedin => LedgerSMB::PGDate->from_input($date), };
            $date =~ s#\D#_#g;
            next unless $request->{"partnumber_${date}_${row}"};
            $hash->{$_} = $request->{"${_}_${date}_${row}"}
                 for (qw(business_unit_id partnumber description qty curr
                                 non_billable));
            $hash->{non_billable} ||= 0;
            $hash->{parts_id} =  LedgerSMB::Timecard->get_part_id(
                     $hash->{partnumber}
            );
            $hash->{jctype} ||= 1;
            $hash->{total} = $hash->{qty} + $hash->{non_chargeable};
            my $timecard = LedgerSMB::Timecard->new(%$hash);
            $timecard->save;
        }
    }
    return new($request);
}

=item print

=cut

sub print {
    my ($request) = @_;
    $request->{parts_id} =  LedgerSMB::Timecard->get_part_id(
           $request->{partnumber}
    );
    my $timecard = LedgerSMB::Timecard->new(%$request);
    my $template = LedgerSMB::Template->new( # printed document
        user     => $request->{_user},
        locale   => $request->{_locale},
        dbh      => $request->{dbh},
        path     => 'DB',
        template => 'timecard',
        format   => $request->{format} || 'HTML',
    );

    if (lc($request->{media}) eq 'screen') {
        $request->{DBNAME} = $request->{company};
        $template->render($request);
        my $body = $template->{output};
        utf8::encode($body) if utf8::is_utf8($body);  ## no critic
        my $filename = 'timecard-' . $request->{id} .
            '.' . lc($request->{format} || 'HTML');
        return
            [ HTTP_OK,
              [
               'Content-Type' => $template->{mimetype},
               'Content-Disposition' => qq{attachment; filename="$filename"},
              ],
              [ $body ] ];
    }
    else {
        $template->render($request);
        $template->output(%$request);

        return display($request, $request);
    }
}

=item timecard_report

This generates a report of timecards.

=cut

sub timecard_report{
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Timecards->new(%$request)
        );
}

=item generate_order

This routine generates an order based on timecards

=cut

sub generate_order {
    my ($request) = @_;
    # TODO after beta 1
    return;
}

=item get

This routine retrieves a timecard and sends it to the display.

=cut

sub get {
    my ($request) = @_;
    my $tcard = LedgerSMB::Timecard->get($request->{id});
    $tcard->{transdate} = LedgerSMB::PGDate->from_db(
              $tcard->checkedin->to_db,
             'date');
    $tcard->{transdate}->is_time(0);
    my ($part) = $tcard->call_procedure(
         funcname => 'part__get_by_id', args => [$tcard->parts_id]
    );
    $tcard->{partnumber} = $part->{partnumber};
    $tcard->{qty} //= 0;
    $tcard->{non_billable} //= 0;
    return display($request, $tcard);
}


=back

=head1 SEE ALSO

=over

=item LedgerSMB::Timecard

=item LedgerSMB::Timecard::Type

=item LedgerSMB::Report::Timecards

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
