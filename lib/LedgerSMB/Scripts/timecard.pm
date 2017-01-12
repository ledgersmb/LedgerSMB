=head1 NAME

LedgerSMB::Scripts::timecard - LedgerSMB workflow routines for timecards.

=head1 SYNPOSIS

 LedgerSMB::Scripts::timecard::display({ request => $request })

=head1 DESCRIPTION

This module contains the basic workflow scripts for managing timecards for
LedgerSMB.  Timecards are used to track time and materials consumed in the
process of work, from professional services to payroll and manufacturing.

=cut

package LedgerSMB::Scripts::timecard;
use strict;
use warnings;

use LedgerSMB::Template;
use LedgerSMB::Timecard;
use LedgerSMB::Timecard::Type;
use LedgerSMB::Report::Timecards;
use LedgerSMB::Company_Config;
use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Business_Unit;
use LedgerSMB::Setting;
use DateTime;

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

use Data::Printer;

sub new {
    my ($request) = @_;
    @{$request->{bu_class_list}} = LedgerSMB::Business_Unit_Class->list();
    return LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/timecards',
        template => 'entry_filter',
        format   => 'HTML'
    )->render_to_psgi({ request => $request });
}

=item display

Displays a timecard.  LedgerSMB::Timecard properties set are treated as
defaults.

=cut

sub display {
    my ($request) = @_;
#    $request->{qty} //= 0;
#    $request->{non_billable} //= 0;
    $request->{in_edit} ||= 0;
    if (defined $request->{checkedin} and $request->{checkedin}->is_time) {
        $request->{in_hour} = $request->{checkedin}->{hour};
        $request->{in_min} = $request->{checkedin}->{min};
    }
    if (defined $request->{checkedout} and $request->{checkedout}->is_time) {
        $request->{out_hour} = $request->{checkedout}->{hour};
        $request->{out_min} = $request->{checkedout}->{min};
    }
    if ($request->{in_hour} and $request->{in_min}) {
        my $request->{min_used} =
            ($request->{in_hour} * 60) + $request->{in_min} -
            ($request->{out_hour} * 60) - $request->{out_min};
        $request->{qty} = $request->{min_used}/60 - $request->{non_billable};
    }
    @{$request->{b_units}} = LedgerSMB::Business_Unit->list(
        $request->{bu_class_id}, undef, 0, $request->{transdate}
    );
    my $curr = LedgerSMB::Setting->get('curr');
    @{$request->{currencies}} = split /:/, $curr;
    $request->{defaultcurr} = @{$request->{currencies}}[0];
    $_ = {value => $_, text => $_} for @{$request->{currencies}};
    $request->{unitprice} = (
           LedgerSMB::Timecard->get_part_discountedprice(
                                $request->{business_unit_id},
                                $request->{parts_id},
                                $request->{transdate},
                                $request->{qty},
                                $request->{curr})   # Why the currency? YL
        // LedgerSMB::Timecard->get_part_sellprice($request->{partnumber})
    );
    $request->{total} = $request->{qty} + $request->{non_billable};
    $request->{sellprice} = $request->{unitprice} * $request->{qty}
        if $request->{unitprice} && $request->{qty};
    return LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/timecards',
        template => 'timecard',
        format   => 'HTML'
    )->render_to_psgi({ request => $request });
}

=item timecard_screen

This displays a screen for entry of timecards, either single day or week.

=cut

sub timecard_screen {
    my ($request) = @_;
    if (1 == $request->{num_days}){
        $request->{transdate} = $request->{date_from};
        return display($request);
    } else {
         @{$request->{b_units}} = LedgerSMB::Business_Unit->list(
              $request->{bu_class_id}, undef, 0, $request->{transdate}
         );
         my $curr = LedgerSMB::Setting->get('curr');
         @{$request->{currencies}} = split /:/, $curr;
         my $startdate = LedgerSMB::PGDate->from_input($request->{date_from});

         my @dates = ();
         for (0 .. 6){
            push @dates, LedgerSMB::PGDate->from_db(
                    $startdate->add(days => 1)->strftime('%Y-%m-%d'),
                    'date'
            );
         }
         $request->{num_lines} = 1 unless $request->{num_lines};
         $request->{transdates} = \@dates;
         return LedgerSMB::Template->new(
             user     => $request->{_user},
             locale   => $request->{_locale},
             path     => 'UI/timecards',
             template => 'timecard-week',
             format   => 'HTML',
             debug    => 1
         )->render_to_psgi({ request => $request });
    }
}

=item save

=cut

sub save {
    my ($request) = @_;
    $request->{total} = ($request->{qty}//0) + ($request->{non_billable}//0);
    die $request->{_locale}->text('Please submit a start/end time or a qty')
        unless defined $request->{qty}
               or ($request->{checkedin} and $request->{checkedout});
    $request->{qty} //= _get_qty($request->{checkedin}, $request->{checkedout});
    $request->{checkedin} = $request->{transdate}
        if !$request->{checkedin};
    $request->{checkedout} = $request->{checkedin}
        if !$request->{checkedout} and $request->{total};
    $request->{sellprice} = $request->{unitprice}
        if !$request->{sellprice} and $request->{total};
    $request->{fxsellprice} //= $request->{sellprice};
    my $timecard = LedgerSMB::Timecard->new(%$request);
    $timecard->save;
    $request->{in_edit} = 0;
    $request->{id} = $timecard->id;
    $request->merge($timecard->get($request->{id}));
    $request->{templates} = ['timecard'];
    @{$request->{printers}} = %LedgerSMB::Sysconfig::printer; # List context
    return display($request);
}

sub _get_qty {
    my ($checkedin, $checkedout) = @_;
    my $when_in = LedgerSMB::PGDate->from_input($checkedin);
    my $when_out = LedgerSMB::PGDate->from_input($checkedout);
    return ($when_in->epoch - $when_out->epoch) / 3600;
}

=item save_week

Saves a week of timecards.

=cut

sub save_week {
    my $request = shift @_;
    for my $row(1 .. $request->{rowcount}){
        for my $dow (0 .. 6){
            my $date = $request->{"transdate_$dow"};
            my $hash = { transdate => LedgerSMB::PGDate->from_input($date),
                         checkedin => LedgerSMB::PGDate->from_input($date), };
            $date =~ s#\D#_#g;
            next unless $request->{"partnumber_${date}_${row}"};
            $hash->{$_} = $request->{"${_}_${date}_${row}"}
                 for (qw(business_unit_id partnumber description qty curr
                                 non_billable));
            $hash->{non_billable} ||= 0;
            $hash->{total} = $hash->{qty} + $hash->{non_chargeable};
            $hash->{sellprice} = $hash->{unitprice} * $hash->{qty}
                if $hash->{sellprice} && $hash->{unitprice};
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
    my $timecard = LedgerSMB::Timecard->new(%$request);
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => $LedgerSMB::Company_Config::settings->{templates},
        template => 'timecard',
        no_auto_output => 1,
        format   => $request->{format} || 'HTML'
    );

    if (lc($request->{media}) eq 'screen') {
        return $template->render_to_psgi($request,
            extra_headers => [ 'Content-Disposition' =>
                  'attachment; filename="timecard-' . $request->{id}
                            . '.' . lc($request->{format} || 'HTML') . '"' ]);
    }
    else {
        $template->render($request);
        $template->output(%$request);

        return display($request);
    }
}

=item timecard_report

This generates a report of timecards.

=cut

sub timecard_report{
    my ($request) = @_;
    my $report = LedgerSMB::Report::Timecards->new(%$request);
    return $report->render_to_psgi({ request => $request });
}

=item generate_order

This routine generates an order based on timecards

=cut

sub generate_order {
    my ($request) = @_;
    # TODO after beta 1
    # Generate Sell Orders handled through menu
    #TODO: Generate Purchase orders
}

=item _get

This routine retrieves a timecard and sends it to the display.

=cut

sub _get_jctype {
    my ($request) = @_;
    return $request->{timecard_type} eq 'by_time'      ? 1
         : $request->{timecard_type} eq 'by_materials' ? 2
         : $request->{timecard_type} eq 'by_overhead'  ? 3
         : undef;
}

sub _get {
    my ($request) = @_;
    $request->{jctype} = _get_jctype($request);
    my $tcard = LedgerSMB::Timecard->get($request->{id});
    $tcard->{transdate} = LedgerSMB::PGDate->from_db(
              $tcard->checkedin->to_db,
             'date');
    $tcard->{transdate}->is_time(0);
    $tcard->{unitprice} = $tcard->{sellprice};
    return $tcard;
}

sub get {
    my ($request) = @_;
    my $tcard = _get($request);
    my ($part) = $tcard->call_procedure(
         funcname => 'part__get_by_id', args => [$tcard->parts_id]
    );
    $tcard->{partnumber} = $part->{partnumber};
    $tcard->{in_edit} = 0;
    return display($tcard);
}

=item edit

=cut

sub edit {
    my ($request) = @_;
    my $tcard = _get($request);
    $tcard->{in_edit} = 1;
    return display($tcard);
}

=item delete

=cut

sub delete {
    my ($request) = @_;
    my $count = LedgerSMB::Timecard->delete($request->{id});
    delete($request->{id});
    timecard_report();
}

=item refresh

=cut

sub refresh {
    my ($request) = @_;
    $request->{jctype} = _get_jctype($request);
    return display($request);
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Timecard

=item LedgerSMB::Timecard::Type

=item LedgerSMB::Report::Timecards

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
