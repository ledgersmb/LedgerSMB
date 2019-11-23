
package LedgerSMB::Scripts::asset;

=head1 NAME

LedgerSMB::Scripts::asset - web entry points for fixed assets accounting

=head1 DESCRIPTION

Asset Management workflow script

=head1 METHODS

=over

=cut

use strict;
use warnings;

use Text::CSV;

use LedgerSMB::DBObject::Asset_Class;
use LedgerSMB::DBObject::Asset;
use LedgerSMB::DBObject::Asset_Report;
use LedgerSMB::Magic qw( MONTHS_PER_YEAR  RC_PARTIAL_DISPOSAL RC_DISPOSAL );
use LedgerSMB::PGNumber;
use LedgerSMB::Report::Assets::Net_Book_Value;
use LedgerSMB::Report::Listings::Asset_Class;
use LedgerSMB::Report::Listings::Asset;
use LedgerSMB::Template::UI;

our @file_columns = qw(tag purchase_date description asset_class location vendor
                      invoice department asset_account purchase_value
                      accum_dep nbv start_depreciation usable_life
                      usable_life_remaining); # override in custom/asset.pl

our $default_dep_account = '5010'; # Override in custom/asset.pl
our $default_asset_account = '1300'; # Override in custom/asset.pl

=item begin_depreciation_all

Displays the depreciation screen for all asset classes.

No inputs required.  Those inputs expected for depreciate_all can be used to
set defaults here.

=cut

sub begin_depreciation_all {
    my ($request) = @_;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/begin_depreciation_all',
                             { request => $request });
}

=item depreciate_all

Creates a depreciation report for each asset class.  Depreciates all assets

Expects report_date to be set.

=cut

sub depreciate_all {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get_metadata;
    for my $ac(@{$report->{asset_classes}}){
        my $dep = LedgerSMB::DBObject::Asset_Report->new({base => $request});
        $dep->{asset_class} = $ac->{id};
        $dep->generate;
        for my $asset (@{$dep->{assets}}){
            push @{$dep->{asset_ids}}, $asset->{id};
        }
        $dep->save;
    }
    $request->{message} = $request->{_locale}->text('Depreciation Successful');
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'info', { request => $request });
}

=item asset_category_screen

Asset class (edit create class)

No inputs required.  Standard properties for asset_class used to populate form
if they are provided.

=cut

sub asset_category_screen {
    my ($request, $ac) = @_;
    if ($request->{id}){
        $request->{title} = $request->{_locale}->text('Edit Asset Class');
    } else {
        $request->{title} = $request->{_locale}->text('Add Asset Class');
    }
     if (! defined $ac) {
          $ac = LedgerSMB::DBObject::Asset_Class->new({base => $request});
     }
     $ac->get_metadata;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/edit_class',
                             { request => $request,
                               asset_class => $ac });
}

=item asset_category_save

Saves the asset class information provided.
See LedgerSMB::DBObject::Asset_report for standard properties.  ID is optional.
Others are required.

=cut

sub asset_category_save {
    my ($request) = @_;
    my $ac = LedgerSMB::DBObject::Asset_Class->new({base => $request});
    $ac->save;
    return asset_category_screen($request, $ac);
}

=item asset_category_search

Displays the asset category search screen

=cut

sub asset_category_search {
    my ($request) = @_;
    my $ac = LedgerSMB::DBObject::Asset_Class->new();
    $ac->get_metadata;

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/search_class',
                             { request => $request,
                               asset_class => $ac });
}

=item asset_category_results

Displays a list of all asset classes.  No inputs required.

=cut

sub asset_category_results {
    my ($request) = @_;
    return LedgerSMB::Report::Listings::Asset_Class->new(%$request)
        ->render($request);
}

=item edit_asset_class

Edits an asset class.  Expects id to be set.

=cut

sub edit_asset_class {
   my ($request) = @_;
   my $ac = LedgerSMB::DBObject::Asset_Class->new({base => $request});
   $ac->get_asset_class;
   return asset_category_screen($request,$ac);
}

=item asset_edit

Displats the edit screen for an asset item.  Tag or id must be set.

=cut

sub asset_edit {
    my ($request) = @_;
    my $asset = LedgerSMB::DBObject::Asset->new({base => $request});
    $asset->get();
    $asset->get_metadata();
    return asset_screen($asset);
}

=item asset_screen

Screen to create a new asset.

No inputs required, any standard properties from LedgerSMB::DBObject::Asset
can be used to set defaults.

=cut

sub asset_screen {
    my ($request,$asset) = @_;
    $asset = LedgerSMB::DBObject::Asset->new({base => $request})
        unless defined $asset;
    $asset->get_metadata;
    if (!$asset->{tag}){
        $asset->get_next_tag;
    }
    $asset->{title} = $request->{_locale}->text('Add Asset')
                 unless $asset->{title};
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/edit_asset',
                             { request => $request,
                               asset => $asset });
}

=item asset_search

Displays the search screen for asset items.  No inputs required.

Any inputs for asset_results can be used here to set defaults.

=cut

sub asset_search {
    my ($request) = @_;
    my $asset = LedgerSMB::DBObject::Asset->new({base => $request});
    $asset->get_metadata;
    unshift @{$asset->{asset_classes}}, {};
    unshift @{$asset->{locations}}, {};
    unshift @{$asset->{departments}}, {};
    unshift @{$asset->{asset_accounts}}, {};
    unshift @{$asset->{dep_accounts}}, {};
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/search_asset',
                             { request => $request,
                               asset => $asset });
}

=item asset_results

Searches for asset items and displays them

See LedgerSMB::DBObject::Asset->search() for a list of search criteria that can
be set.

=cut

sub asset_results {
    my ($request) = @_;
    return LedgerSMB::Report::Listings::Asset->new(%$request)
        ->render($request);
}

=item asset_save

Saves the asset.  See LedgerSMB::DBObject::Asset->save() for more info.

Additionally this also creates a note with the vendor number and invoice number
for future reference, since this may not have been entered specifically as a
vendor transaction in LedgerSMB.

=cut

sub asset_save {
    my ($request) = @_;
    my $asset = LedgerSMB::DBObject::Asset->new({base => $request});
    for my $number (qw(salvage_value purchase_value usable_life)){
        $asset->{"$number"} = LedgerSMB::PGNumber->from_input(
               $asset->{"$number"}
        );
    }
    $asset->save;
    $asset->{note} = 'Vendor:' . $asset->{meta_number} . "\n"
                   . 'Invoice:'.$asset->{invnumber};
    $asset->{subject} = 'Vendor/Invoice Note';
    $asset->save_note;
    my $newasset = LedgerSMB::DBObject::Asset->new({
                  base  => $request,
                  copy  => 'list',
                  merge => ['stylesheet'],
    });
    return asset_screen($request,$newasset);
}

=item new_report

Starts the new report workflow.  No inputs required.

report_init inputs can be used to set defaults.

=cut

sub new_report {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get_metadata;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/begin_report',
                             { request => $request,
                               report => $report });
}

=item report_init

Creates a report and populates the screen with possible report lines.

Inputs expected:
* report_id int:  Report to enter the transactions into,
* accum_account_id int:  ID for accumulated depreciation.

=cut

sub report_init {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->generate;
    return display_report($request, $report);
}

=item report_save

Saves the report.

see LedgerSMB::DBObject::Asset_Report->save() for expected inputs.

=cut

sub report_save{
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->{asset_ids} = [];
    for my $count (0 .. $request->{rowcount}){
        my $id = $request->{"id_$count"};
        if ($request->{"asset_$count"}){
           push @{$report->{asset_ids}}, $id;
        }
    }
    $report->save;
    my $ar = LedgerSMB::DBObject::Asset_Report->new(
             base => $request,
             copy => 'base'
    );
    return new_report($request);
}

=item report_get

Retrieves the report identified by the id input and displays it.

=cut

sub report_get {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get;
    return display_report($request, $report);
}

=item display_report

Not directly called.  This routine displays a report that is set up.

Assumes that all standard properties of LedgerSMB::DBObject::Asset_Report are
set, and also requires $request->{assets} is an array ref to the report line
items.  Each has the standard properties of the LedgerSMB::DBObject::Asset plus
dm (disposal method id) and amount (amount to depreciate).

=cut

sub display_report {
    my ($request, $report) = @_;
    $report->get_metadata;
    my $locale = $request->{_locale};
    my @disp_methods = (
        map { { text => $_->{label},
                value => $_->{id} } } @{$report->{disp_methods}} );
    my $cols = [
        {
            col_id => 'asset',
            type   => 'checkbox',
        },
        {
            col_id => 'tag',
            name   => $locale->text('Asset Tag'),
            type   => 'text',
        },
        {
            col_id => 'description',
            name   => $locale->text('Description'),
            type   => 'text',
        },
        {
            col_id => 'purchase_date',
            name   => $locale->text('Purchase Date'),
            type   => 'text',
        },
        {
            col_id => 'purchase_value',
            name   => $locale->text('Purchase Value'),
            type   => 'text',
        },
        ];
   my $rows = [];
   my $hiddens = {};
   my $count = 0;
    for my $asset (@{$report->{assets}}){
        $asset->{row_id} = $asset->{id};
        push @$rows, $asset;
   }
    my $buttons = [
        { name  => 'action',
          text  => $locale->text('Save'),
          value => 'report_save',
          class => 'submit',
          type  => 'submit',
        },
        ];
    my $title;
    if ($request->{depreciation}){
       $title = $locale->text('Asset Depreciation Report');
    } else {
        $title = $locale->text('Asset Disposal Report');

        push @$cols, ({
            col_id  => 'dm',
            name    => $locale->text('Disposal Method'),
            type    => 'select',
            options => \@disp_methods,
        },
        {
            col_id  => 'amount',
            name    => $locale->text('Proceeds'),
            type    => 'input_text',
            class   => 'amount',
        });
        $hiddens->{report_class} = $request->{report_class};
    }
    if ($request->{report_class} == RC_PARTIAL_DISPOSAL ){
        $title = $locale->text('Asset Partial Disposal Report');
        push @$cols, {
            col_id  => 'percent',
            name    => $locale->text('Percent'),
            type    => 'input_text',
            class   => 'percent',
        };
    }
    for my $hide (qw(exp_account_id gain_account_id loss_account_id report_date
                  asset_class rowcount depreciation))
    {
        $hiddens->{$hide} = $request->{$hide};
    }
    $request->{hiddens} = $hiddens;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Reports/display_report', {
                        name => $title,
                     request => $request,
                     columns => $cols,
                        rows => $rows,
                     hiddens => $hiddens,
                     buttons => $buttons,
    });
}

=item search_reports

Displays search report filter.  The only input expected is depreciation which if
set and true makes this a depreciation report.

Any other inputs required by
report_results can be used here to set defaults.  See the required inputs for
LedgerSMB::DBObject::Asset_Report->search() for a list of such inputs.

=cut

sub search_reports {
    my ($request) = @_;
    $request->{title} = $request->{_locale}->text('Search reports');
    my $ar = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $ar->get_metadata;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/begin_approval',
                             { request => $request,
                               asset_report => $ar });
}

=item report_results

Executes the search for asset reports and displays the results.  See the
required inputs for LedgerSMB::DBObject::Asset_Report->search() for a list of
inputs.

=cut

sub report_results {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $ar = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $ar->get_metadata;
    my $title = $locale->text('Report Results');
    my @results = $ar->search;
    my $base_href = 'asset.pl?action=report_details&'.
                     "expense_acct=$ar->{expense_acct}";
    if ($ar->{depreciation}){
             $base_href .= '&depreciation=1';
    } else {
             $base_href .= "&gain_acct=$ar->{gain_acct}&loss_acct=".
                            "$ar->{loss_acct}";
    }
    $base_href .= '&id=';
    my $cols = [
        {
            col_id => 'select',
            type   => 'checkbox',
        },
        {
            col_id    => 'id',
            name      => $locale->text('ID'),
            type      => 'href',
            href_base => $base_href,
        },
        {
            col_id => 'report_date',
            name   => $locale->text('Date'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'type',
            name   => $locale->text('Type'),
            type   => 'text',
        },
        {
            col_id => 'asset_class',
            name   => $locale->text('Asset Class'),
            type   => 'text',
        },
        {
            col_id => 'entered_at',
            name   => $locale->text('Entered at'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'approved_at',
            name   => $locale->text('Approved at'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'total',
            name   => $locale->text('Total'),
            type   => 'amount',
        },
        ];
    my $rows = [];
    my $hiddens = {
        gain_acct => $request->{gain_acct},
        loss_acct => $request->{loss_acct},
    };
    my $count = 0;
    for my $r (@results){
        next if (($r->{report_class} != 1 and $ar->{depreciation})
                 or ($r->{report_class} == 1 and not $ar->{depreciation}));
        $hiddens->{"id_$count"} = $r->{id};
        my $ref = {
            select         => 0,
            row_id         => $r->{id},
            id             => $r->{id},
            type           => (($r->{report_class} == 1)
                               ? $locale->text('Depreciation')
                               : $locale->text('Disposal')),
            report_date    => $r->{report_date},
            entered_at     => $r->{entered_at},
            approved_at    => $r->{approved_at},
            total          => $r->{total}->to_output(money => 1),
        };
        for my $ac (@{$ar->{asset_classes}}){
            if ($ac->{id} == $r->{asset_class}){
                $ref->{asset_class} = $ac->{label};
            }
        }
        push @$rows, $ref;
        ++$count;
    }
    $request->{rowcount} = $count;
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name  => 'action',
                   value => 'report_results_approve'
                   },
        ];
    $ar->{hiddens} = $hiddens;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Reports/display_report', {
         request => $ar,
            name => $title,
         rows    => $rows,
         columns => $cols,
        buttons  => $buttons,
   });
}

=item report_details

Displays the details of an existing report.  Requires that the id request arg is
set which represents the id of the report.

=cut

sub report_details {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get;
    if ($report->{report_class} == RC_DISPOSAL) {
      return disposal_details($report);
    } elsif ($report->{report_class} == RC_PARTIAL_DISPOSAL ) {
      return partial_disposal_details($report);
    }
    my $cols = [
        {
            col_id => 'tag',
            name   => $locale->text('Tag'),
            type   => 'text',
        },
        {
            col_id => 'start_depreciation',
            name   => $locale->text('Dep. Starts'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'purchase_value',
            name   => $locale->text('Aquired Value'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'method_short_name',
            name   => $locale->text('Dep. Method'),
            type   => 'text',
        },
        {
            col_id => 'usable_life',
            name   => $locale->text('Est. Life'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'basis',
            name   => $locale->text('Dep. Basis'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'prior_through',
            name   => $locale->text('Prior Through'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'prior_dep',
            name   => $locale->text('Prior Dep.'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'dep_this_time',
            name   => $locale->text('Dep. this run'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'dep_ytd',
            name   => $locale->text('Dep. YTD'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'dep_total',
            name   => $locale->text('Total Accum. Dep.'),
            type   => 'text',
            class  => 'amount',
        }
        ];

    my $title =
        $locale->text('Report [_1] on date [_2]',
                      $report->{id}, $report->{report_date}->to_output);
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value basis prior_dep dep_this_time dep_ytd
                        dep_total)){
             $r->{$amt} = $r->{$amt}->to_output(money  => 1);
        }
        push @$rows, $r;
    }
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  'action',
                   value => 'report_details_approve'
                   },
    ];
    $report->{hiddens} = { id => $report->{id} };
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Reports/display_report', {
                    request => $report,
                       name => $title,
                    columns => $cols,
                       rows => $rows,
                    buttons => $buttons
    });
}

=item partial_disposal_details

Displays the results of a partial disposal report.  The id must be set to the
id of the report desired.

=cut

sub partial_disposal_details {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get;
    my $cols = [
        {
            col_id => 'tag',
            name   => $locale->text('Tag'),
            type   => 'text',
        },
        {
            col_id => 'begin_depreciation',
            name   => $locale->text('Dep. Starts'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'purchase_value',
            name   => $locale->text('Aquired Value'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'description',
            name   => $locale->text('Description'),
            type   => 'text',
        },
        {
            col_id => 'percent_disposed',
            name   => $locale->text('Percent Disposed'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'disposed_acquired_value',
            name   => $locale->text('Disp. Aquired Value'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'percent_remaining',
            name   => $locale->text('Percent Remaining'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'remaining_aquired_value',
            name   => $locale->text('Aquired Value Remaining'),
            type   => 'text',
            class  => 'amount',
        },
#        #@@TODO Gain/Loss isn't part of partial disposals.... (#4231)
#        {
#            col_id => 'gain_loss',
#            name   => $locale->text('Gain/Loss'),
#            type   => 'text',
#            class  => 'amount',
#        },
        ];
    my $title = $locale->text('Partial Disposal Report [_1] on date [_2]',
                        $report->{id}, $report->{report_date});
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value disposed_acquired_value
                     remaining_aquired_value percent_disposed
                     percent_remaining)){
             $r->{$amt} = $r->{$amt}->to_output(money => 1);
        }
#        $r->{gain_loss} = $r->{gain_loss}->to_output(
#                                                    money => 1,
#                                               neg_format => '-'
#        );
        push @$rows, $r;
    }
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  'action',
                   value => 'disposal_details_approve'
                   },
        ];
    $report->{hiddens} = {
        id => $report->{id},
        gain_acct => $report->{gain_acct},
        loss_acct => $report->{loss_acct},
    };

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Reports/display_report', {
                    request => $report,
                       name => $title,
                    columns => $cols,
                       rows => $rows,
                    buttons => $buttons
    });
}

=item disposal_details

Displays the details of a disposal report.

id must be set to the id of the report to be displayed.

=cut

sub disposal_details {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get;
    my $cols = [
        {
            col_id => 'tag',
            name   => $locale->text('Tag'),
            type   => 'text',
        },
        {
            col_id => 'description',
            name   => $locale->text('Description'),
            type   => 'text',
        },
        {
            col_id => 'start_dep',
            name   => $locale->text('Dep. Starts'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'disposed_on',
            name   => $locale->text('Disposal Date'),
            type   => 'text',
            class  => 'date',
        },
        {
            col_id => 'dm',
            name   => $locale->text('D M'),
            type   => 'text',
        },
        {
            col_id => 'purchase_value',
            name   => $locale->text('Aquired Value'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'accum_depreciation',
            name   => $locale->text('Accum. Depreciation'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'adj_basis',
            name   => $locale->text('Adjusted Basis'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'disposal_amt',
            name   => $locale->text('Proceeds'),
            type   => 'text',
            class  => 'amount',
        },
        {
            col_id => 'gain_loss',
            name   => $locale->text('Gain (Loss)'),
            type   => 'text',
            class  => 'amount',
        },
        ];
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value adj_basis accum_depreciation
                        disposal_amt gain_loss)
        ){
             $r->{$amt} = $r->{$amt}->to_output(money  => 1);
        }
        push @$rows, $r;
    }
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  'action',
                   value => 'disposal_details_approve'
                   },
        ];
    $report->{hiddens} = {
        id        => $report->{id},
        gain_acct => $report->{gain_acct},
        loss_acct => $report->{loss_acct},
    };
    my $title = $locale->text('Disposal Report [_1] on date [_2]',
                     $report->{id}, $report->{report_date});
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Reports/display_report', {
                       name => $title,
                    request => $report,
                    columns => $cols,
                       rows => $rows,
                    buttons => $buttons
    });
}

=item disposal_details_approve

Pass through function for form-dynatable's action munging.  An alias for
report_details_approve.

=cut

sub disposal_details_approve {
    return report_details_approve(@_);
}

=item report_details_approve

Approves disposal details.  id must be set,

For disposal reports, gain_acct and loss_acct must be set to appropriate
account id's.

For depreciation reports, expense_acct must be set to an appropriate accont id.

=cut

sub report_details_approve {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->approve;
    return search_reports($request);
}

=item report_results_approve

Loops through the input and approves all selected reports.

For disposal reports, gain_acct and loss_acct must be set to appropriate
account id's.

For depreciation reports, expense_acct must be set to an appropriate accont id.

For each row, there is  report_$id field which if set to a true value, indicates
a report to be approved.

=cut

sub report_results_approve {
    my ($request) = @_;
    for my $l (0 .. $request->{rowcount_}){
        if ($request->{"select_$l"}){
            my $approved = LedgerSMB::DBObject::Asset_Report->new({base => $request});
            $approved->{id} = $request->{"select_$l"};
            $approved->approve;
        }
    }
   return search_reports($request);

}

=item display_nbv

Displays the net book value report, namely the current net value of all active
active assets.

No inputs required or used.

=cut

sub display_nbv {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Assets::Net_Book_Value->new(%$request);
    return $report->render($request);
}

=item begin_import

Displays the initial screen for asset import routines.

No inputs required.

=cut

sub begin_import {
    my ($request) = @_;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'asset/import_asset', $request);
}

=item run_import

Runs the actual import based on a CSV file.  This is tested primarily against
Excel for the Mac which has known CSV generation problems, and Gnumeric which
produces very good CSV.  It should work on most CSV files if the format is
consistent.

See the Customization Notes section below for more info on how to set up
CSV formats.

=cut

sub _import_file {
    my $request = shift @_;

    my $handle = $request->upload('import_file');
    my $csv = Text::CSV->new;
    $csv->header($handle);
    my $import_entries = $csv->getline_all($handle);

    return @$import_entries;
}


sub run_import {

    my ($request) = @_;
    my $asset = LedgerSMB::DBObject::Asset->new({base => $request});
    $asset->get_metadata;

    my @rresults = $asset->call_procedure(
                               funcname => 'asset_report__begin_import',
                                   args => [$asset->{asset_classes}->[0]->{id},
                                            $asset->{report_date}]
    );
    my $report_results = shift @rresults;
    my $department = {};
    my $location = {};
    my $class = {};
    my $asset_account = {};
    my $dep_account = {};
    for my $c (@{$asset->{asset_classes}}){
        $class->{"$c->{label}"} = $c;
    }
    for my $l (@{$asset->{locations}}){
        $location->{"$l->{description}"} = $l->{id};
    }
    for my $d (@{$asset->{departments}}){
        $department->{"$d->{description}"} = $d->{id};
    }
    for my $a (@{$asset->{asset_accounts}}){
       $asset_account->{"$a->{accno}"} = $a;
    }
    for my $a (@{$asset->{dep_accounts}}){
       $dep_account->{"$a->{accno}"} = $a;
    }
    for my $ail (_import_file($request)){
        my $ai = LedgerSMB::DBObject::Asset->new({copy => 'base', base => $request});
        for (0 .. $#file_columns){
          $ai->{$file_columns[$_]} = $ail->[$_];
        }
        next if $ai->{purchase_value} !~ /\d/;
        $ai->{purchase_value} = LedgerSMB::PGNumber->from_input(
             $ai->{purchase_value}
        );
        $ai->{accum_dep} = LedgerSMB::PGNumber->from_input($ai->{accum_dep});
        $ai->{dep_account} = $default_dep_account if !$ai->{dep_account};
        $ai->{asset_account} = $default_asset_account if !$ai->{dep_account};
        if (!$ai->{start_depreciation}){
            $ai->{start_depreciation} = $ai->{purchase_date};
        }
        if ($ai->{asset_class} !~ /Leasehold/i){
           $ai->{usable_life} = $ai->{usable_life}/MONTHS_PER_YEAR;
        }
        $ai->{dep_report_id} = $report_results->{id};
        $ai->{location_id} = $location->{"$ai->{location}"};
        $ai->{department_id} = $department->{"$ai->{department}"};
        $ai->{asset_class_id} = $class->{"$ai->{asset_class}"}->{id};
        $ai->{dep_account_id} = $class->{"$ai->{asset_class}"}->{dep_account_id};
        $ai->{asset_account_id} = $asset_account->{"$ai->{asset_account}"}->{id};
        if (!$ai->{dep_account_id}){
            $ai->{dep_account_id} = $dep_account->{$default_dep_account}->{id};
        }
        for my $l (@{$asset->{locations}}){
            if ($ai->{location} eq $l->{description}){
               $ai->{location} = $l->{id};
            }
        }
        for my $l (@{$asset->{departments}}){
            if ($ai->{location} eq $l->{description}){
               $ai->{location} = $l->{id};
            }
        }
        for my $l (@{$asset->{asset_classes}}){
           if ($ai->{location} eq $l->{label}){
               $ai->{location} = $l->{id};
            }
        }
        for my $attr_name (qw(location department asset_class)){
            my $attr = $ai->{$attr_name};
            $ai->{$attr} = $asset->{"${attr}_name"};
        }
        $ai->import_asset;
    }
    $request->{info} = $request->{_locale}->text('File Imported');
    return begin_import($request);
}

{
    local ($!, $@) = ( undef, undef);
    my $do_ = 'scripts/custom/asset.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die ( "Status: 500 Internal server error (asset.pm)\n\n" );
            }
        }
    }
};

=back

=head1 CUSTOMIZATION NOTES

The handling of CSV imports of fixed assets is handled by @file_columns.  This
can be set in a custom/ file.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
