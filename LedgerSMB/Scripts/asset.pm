=pod

=head1 NAME

LedgerSMB::Scripts::asset

=head1 SYNPOSIS

Asset Management workflow script

=head1 METHODS

=over

=cut

package LedgerSMB::Scripts::asset;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Asset_Class;
use LedgerSMB::DBObject::Asset;
use LedgerSMB::DBObject::Asset_Report;
use LedgerSMB::Report::Assets::Net_Book_Value;
use LedgerSMB::Report::Listings::Asset_Class;
use LedgerSMB::Report::Listings::Asset;
use strict;
use warnings;

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
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'begin_depreciation_all',
        format => 'HTML'
    );
    $template->render({ request => $request });
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
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'info',
        format => 'HTML'
    );
    $template->render({ request => $request });

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
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'edit_class',
        format => 'HTML'
    );
    $template->render({ request => $request,
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
    asset_category_screen($request, $ac);
}

=item asset_category_search

Displays the asset category search screen

=cut

sub asset_category_search {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'search_class',
        format => 'HTML'
    );
    my $ac = LedgerSMB::DBObject::Asset_Class->new();
    $ac->get_metadata;
    $template->render({ request => $request,
                        asset_class => $ac });
}

=item asset_category_results

Displays a list of all asset classes.  No inputs required.

=cut

sub asset_category_results {
    my ($request) = @_;
    LedgerSMB::Report::Listings::Asset_Class->new(%$request)->render($request);
}

=item edit_asset_class

Edits an asset class.  Expects id to be set.

=cut

sub edit_asset_class {
   my ($request) = @_;
   my $ac = LedgerSMB::DBObject::Asset_Class->new({base => $request});
   $ac->get_asset_class;
   asset_category_screen($request,$ac);
}

=item asset_edit

Displats the edit screen for an asset item.  Tag or id must be set.

=cut

sub asset_edit {
    my ($request) = @_;
    my $asset = LedgerSMB::DBObject::Asset->new({base => $request});
    $asset->get();
    $asset->get_metadata();
    asset_screen($asset);
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
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'edit_asset',
        format => 'HTML'
    );
    $template->render({ request => $request,
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
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'search_asset',
        format => 'HTML'
    );
    $template->render({ request => $request,
                        asset => $asset });
}

=item asset_results

Searches for asset items and displays them

See LedgerSMB::DBObject::Asset->search() for a list of search criteria that can
be set.

=cut

sub asset_results {
    my ($request) = @_;
    LedgerSMB::Report::Listings::Asset->new(%$request)->render($request);
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
    asset_screen($request,$newasset);
}

=item new_report

Starts the new report workflow.  No inputs required.

report_init inputs can be used to set defaults.

=cut

sub new_report {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get_metadata;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'begin_report',
        format => 'HTML'
    );
    $template->render({ request => $request,
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
    display_report($request, $report);
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
    new_report($request);
}

=item report_get

Retrieves the report identified by the id input and displays it.

=cut

sub report_get {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Asset_Report->new({base => $request});
    $report->get;
    display_report($request, $report);
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
    my $cols = [];
    @$cols = qw(select tag description purchase_date purchase_value);
    my $heading = {
       tag            =>  $locale->text('Asset Tag') ,
       description    =>  $locale->text('Description') ,
       purchase_date  =>  $locale->text('Purchase Date') ,
       purchase_value =>  $locale->text('Purchase Value') ,
       amount         =>  $locale->text('Proceeds'),
       dm             =>  $locale->text('Disposal Method'),
       percent        =>  $locale->text('Percent'),
   };
   my $rows = [];
   my $hiddens = {};
   my $count = 0;
   for my $asset (@{$request->{assets}}){
       push @$rows,
            { select         => {input => { name    => "asset_$count",
                                            checked => $asset->{checked},
                                            type    => "checkbox",
                                            value   => '1',
                                          },
                                },
              tag            => $asset->{tag},
              description    => $asset->{description},
              purchase_date  => $asset->{purchase_date},
              purchase_value => $asset->{purchase_value},
              dm             => {select => { name       => "dm_$asset->{id}",
                                             options    => $report->{disp_methods},
                                             text_attr  => 'label',
                                             value_attr => 'id',
                                           },
                                },

              amount         => {input => { name  => "amount_$asset->{id}",
                                            type  => 'text',
                                            class => 'amount',
                                            value => $request->{"amount_$asset->{id}"},
                                            size  => 20,
                                          },
                                },
              percent        => {input => { name  => "percent_$asset->{id}",
                                            type  => 'text',
                                            class => 'percent',
                                            value => $request->{"percent_$asset->{id}"},
                                            size  => 6,
                                          },
                                },
            };
       $hiddens->{"id_$count"} = $asset->{id};
       ++$count;
   }
   $request->{rowcount} = $count;
   my $buttons = [
      { name  => 'action',
        text  => $locale->text('Save'),
        value => 'report_save',
        class => 'submit',
        type  => 'submit',
      },
   ];
   if ($request->{depreciation}){
       $request->{title} = $locale->text('Asset Depreciation Report');
   } else {
       $request->{title} = $locale->text('Asset Disposal Report');
       push @$cols, 'dm', 'amount';
       $hiddens->{report_class} = $request->{report_class};
   }
   if ($request->{report_class} == 4){
       $request->{title} = $locale->text('Asset Partial Disposal Report');
       push @$cols, 'percent';
   }
   for my $hide (qw(exp_account_id gain_account_id loss_account_id report_date
                 asset_class rowcount depreciation))
   {
       $hiddens->{$hide} = $request->{$hide};
   }
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'form-dynatable',
        format => 'HTML'
    );
    $template->render({ form => $request,
                     columns => $cols,
                     heading => $heading,
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
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'begin_approval',
        format => 'HTML'
    );
    $template->render({ request => $request,
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
    $ar->{title} = $locale->text('Report Results');
    my @results = $ar->search;
    my $cols = [];
    @$cols = qw(select id report_date type asset_class entered_at
                   approved_at total);
    my $header = {
                        id => $locale->text('ID'),
               report_date => $locale->text('Date'),
                      type => $locale->text('Type'),
               asset_class => $locale->text('Asset Class'),
                entered_at => $locale->text('Entered at'),
               approved_at => $locale->text('Approved at'),
                     total => $locale->text('Total'),
    };
    my $rows = [];
    my $hiddens = {};
    my $count = 0;
    my $base_href = "asset.pl?action=report_details&".
                     "expense_acct=$ar->{expense_acct}";
    if ($ar->{depreciation}){
             $base_href .= '&depreciation=1';
    } else {
             $base_href .= "&gain_acct=$ar->{gain_acct}&loss_acct=".
                            "$ar->{loss_acct}";
    }
    for my $r (@results){
        next if (($r->{report_class} != 1 and $ar->{depreciation})
                 or ($r->{report_class} == 1 and !$ar->{depreciation}));
        $hiddens->{"id_$count"} = $r->{id};
        my $ref = {
              select         => {input => { name    => "report_$count",
                                            checked => $r->{checked},
                                            type    => "checkbox",
                                            value   => $r->{id},
                                          },
                                },
               id             => {href => $base_href . "&id=".$r->{id},
                                  text => $r->{id},
                                 },
               report_date    => $r->{report_date},
               entered_at     => $r->{entered_at},
               approved_at    => $r->{approved_at},
               total          => $r->{total}->to_output(money => 1),
        };
        for my $ac (@{$ar->{asset_classes}}){
            if ($ac->{id} = $r->{asset_class}){
                $ref->{asset_class} = $ac->{label};
            }
        }
        if ($r->{report_class} == 1){
           $ref->{type} = $locale->text('Depreciation');
        } else {
           $ref->{type} = $locale->text('Disposal');
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
                   value => 'approve'
                   },
    ];
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'form-dynatable',
        format => 'HTML'
    );
    $template->render({
         form    => $ar,
         heading => $header,
         rows    => $rows,
         columns => $cols,
         hiddens  => $request,
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
    if ($report->{report_class} == 2) {
      disposal_details($report);
      return;
    } elsif ($report->{report_class} == 4) {
      partial_disposal_details($report);
      return;
    }
    my @cols = qw(tag start_depreciation purchase_value method_short_name
                 usable_life basis prior_through prior_dep dep_this_time
                 dep_ytd dep_total);
    $report->{title} = $locale->text("Report [_1] on date [_2]",
                     $report->{id}, $report->{report_date}->to_output);
    my $header = {
                            tag => $locale->text('Tag'),
             start_depreciation => $locale->text('Dep. Starts'),
                 purchase_value =>$locale->text('Aquired Value'),
              method_short_name =>$locale->text('Dep. Method'),
                    usable_life =>$locale->text('Est. Life'),
                          basis =>$locale->text('Dep. Basis'),
                  prior_through =>$locale->text('Prior Through'),
                      prior_dep =>$locale->text('Prior Dep.'),
                  dep_this_time =>$locale->text('Dep. this run'),
                        dep_ytd =>$locale->text('Dep. YTD'),
                      dep_total =>$locale->text('Total Accum. Dep.'),
    };
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value basis prior_dep dep_this_time dep_ytd
                        dep_total)){
             $r->{$amt} = $r->{$amt}->to_output(money  => 1);
        }
        push @$rows, $r;
    }
    my $template = LedgerSMB::Template->new(
          request => $request,
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'form-dynatable',
        format => 'HTML'
    );
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  'action',
                   value => 'approve'
                   },
    ];
    $template->render({form => $report,
                    columns => \@cols,
                    heading => $header,
                       rows => $rows,
                    hiddens => $report,
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
    my @cols = qw(tag begin_depreciation purchase_value description
                 percent_disposed disposed_acquired_value
                 percent_remaining remaining_aquired_value);
    $report->{title} = $locale->text("Partial Disposal Report [_1] on date [_2]",
                        $report->{id}, $report->{report_date});
    my $header = {
                   tag                => $locale->text('Tag'),
                   description        => $locale->text('Description'),
                   begin_depreciation => $locale->text('Dep. Starts'),
                   purchase_value     => $locale->text('Aquired Value'),
                   percent_disposed   => $locale->text('Percent Disposed'),
                   disposed_acquired_value =>
                                   $locale->text('Disp. Aquired Value'),
                   percent_remaining  => $locale->text('Percent Remaining'),
                   remaining_aquired_value =>
                                   $locale->text('Aquired Value Remaining')
    };
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value adj_basis disposed_acquired_value
                        remaining_aquired_value percent_disposed
                        percent_remaining)
        ){
             $r->{$amt} = $r->{$amt}->to_output(money => 1);
        }
        $r->{gain_loss} = $r->{gain_loss}->to_output(
                                                    money => 1,
                                               neg_format => '-'
        );
        push @$rows, $r;
    }
    my $template = LedgerSMB::Template->new(
          request => $request,
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'form-dynatable',
        format => 'HTML'
    );
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  'action',
                   value => 'approve'
                   },
    ];
    $template->render({form => $report,
                    columns => \@cols,
                    heading => $header,
                       rows => $rows,
                    hiddens => $report,
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
    my @cols = qw(tag description start_dep disposed_on dm purchase_value
                 accum_depreciation adj_basis disposal_amt gain_loss);
    $report->{title} = $locale->text("Disposal Report [_1] on date [_2]",
                     $report->{id}, $report->{report_date});
    my $header = {
                            tag => $locale->text('Tag'),
                    description => $locale->text('Description'),
                      start_dep => $locale->text('Dep. Starts'),
                    disposed_on => $locale->text('Disposal Date'),
                 purchase_value => $locale->text('Aquired Value'),
                             dm => $locale->text('D M'),
             accum_depreciation => $locale->text('Accum. Depreciation'),
                   disposal_amt => $locale->text('Proceeds'),
                      adj_basis => $locale->text('Adjusted Basis'),
                      gain_loss => $locale->text('Gain (Loss)'),
    };
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value adj_basis accum_depreciation
                        disposal_amt)
        ){
             $r->{$amt} = $r->{$amt}->to_output(money  => 1);
        }
        $r->{gain_loss} = $r->{gain_loss}->to_output(money => 1, neg_format => '-');
        push @$rows, $r;
    }
    my $template = LedgerSMB::Template->new(
          request => $request,
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'form-dynatable',
        format => 'HTML'
    );
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  'action',
                   value => 'approve'
                   },
    ];
    $template->render({form => $report,
                    columns => \@cols,
                    heading => $header,
                       rows => $rows,
                    hiddens => $report,
                    buttons => $buttons
    });
}

=item disposal_details_approve

Pass through function for form-dynatable's action munging.  An lias for
report_details_approve.

=cut

sub disposal_details_approve {
    report_details_approve(@_);
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
    search_reports($request);
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
    for my $l (0 .. $request->{rowcount}){
        if ($request->{"report_$l"}){
            my $approved = LedgerSMB::DBObject::Asset_Report->new({base => $request});
            $approved->{id} = $request->{"report_$l"};
            $approved->approve;
        }
    }
   search_reports($request);

}

=item display_nbv

Displays the net book value report, namely the current net value of all active
active assets.

No inputs required or used.

=cut

sub display_nbv {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Assets::Net_Book_Value->new(%$request);
    $report->render($request);
}

=item begin_import

Displays the initial screen for asset import routines.

No inputs required.

=cut

sub begin_import {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/asset',
        template => 'import_asset',
        format => 'HTML'
    );
    $template->render($request);
}

=item run_import

Runs the actual import based on a CSV file.  This is tested primarily against
Excel for the Mac which has known CSV generation problems, and Gnumeric which
produces very good CSV.  It should work on most CSV files if the format is
consistent.

See the Customization Notes section below for more info on how to set up
CSV formats.

=cut

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
    for my $ail ($asset->import_file($request->{import_file})){
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
           $ai->{usable_life} = $ai->{usable_life}/12;
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
    begin_import($request);
}

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/asset.pl"};

1;

=back

=head1 CUSTOMIZATION NOTES

The handling of CSV imports of fixed assets is handled by @file_columns.  This
can be set in a custom/ file.

=head1 Copyright (C) 2010, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
