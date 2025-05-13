
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

use LedgerSMB::Magic qw( MONTHS_PER_YEAR  RC_PARTIAL_DISPOSAL RC_DISPOSAL );
use LedgerSMB::PGNumber;
use LedgerSMB::Report::Assets::Net_Book_Value;
use LedgerSMB::Report::Listings::Asset_Class;
use LedgerSMB::Report::Listings::Asset;


our $default_dep_account = '5010'; # Override in custom/asset.pl
our $default_asset_account = '1300'; # Override in custom/asset.pl

=item asset_category_screen

Asset class (edit create class)

No inputs required.  Standard properties for asset_class used to populate form
if they are provided.

=cut

sub _asset_class_get_metadata {
    my ($request) = @_;

    return {
        asset_accounts => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_class__get_asset_accounts', args => [] ) ],
        dep_accounts   => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_class__get_dep_accounts', args => [] ) ],
        dep_methods    => [
            $request->call_procedure( funcname => 'asset_class__get_dep_methods', args => [] )
        ],
    };
}


sub asset_category_screen {
    my ($request, $ac) = @_;
    my $title;
    if ($request->{id}){
        $request->{title} = $request->{_locale}->text('Edit Asset Class');
    } else {
        $request->{title} = $request->{_locale}->text('Add Asset Class');
    }

    $ac //= {};
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'asset/edit_class',
                             {
                                 request => $request,
                                 asset_class => {
                                     title => $request->{title},
                                     _asset_class_get_metadata($request)->%*,
                                     $ac->%*
                                 }
                             });
}

=item asset_category_save

Saves the asset class information provided.
See LedgerSMB::DBObject::Asset_report for standard properties.  ID is optional.
Others are required.

=cut

sub asset_category_save {
    my ($request) = @_;
    my ($newclass) = $request->call_procedure(
        funcname => 'asset_class__save',
        args     => [
            $request->@{qw( id  asset_account_id  dep_account_id
                            method label unit_label )}
        ]);

    return asset_category_screen($request, $newclass);
}

=item asset_category_search

Displays the asset category search screen

=cut

sub asset_category_search {
    my ($request) = @_;

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'asset/search_class',
                             { request => $request,
                               asset_class => _asset_class_get_metadata($request) });
}

=item asset_category_results

Displays a list of all asset classes.  No inputs required.

=cut

sub asset_category_results {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::Asset_Class->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item edit_asset_class

Edits an asset class.  Expects id to be set.

=cut

sub edit_asset_class {
    my ($request) = @_;
    my ($ac) = $request->call_procedure(
        funcname => 'asset_class__get',
        args     => [ $request->{id} ]);
   return asset_category_screen($request, $ac);
}

=item asset_edit

Displats the edit screen for an asset item.  Tag or id must be set.

=cut

sub _asset_get_metadata {
    my ($request) = @_;

    return {
        asset_classes  => [ $request->call_procedure( funcname => 'asset_class__list', args => [] ) ],
        locations      => [ $request->call_procedure( funcname => 'warehouse__list_all', args => [] ) ],
        departments    => [ $request->call_procedure( funcname => 'business_unit__list_by_class', args => [1, undef, undef, undef] ) ],
        asset_accounts => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_class__get_asset_accounts', args => [] ) ],
        dep_accounts   => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_class__get_dep_accounts', args => [] ) ],
        exp_accounts   => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_report__get_expense_accts', args => [] ) ],
        dep_method     => {
            map { $_->{id} => $_ } $request->call_procedure( funcname => 'asset_class__get_dep_methods', args => [] )
        },
    };
}

sub _asset_get_next_tag {
    my ($request) = @_;
    my ($ref) = $request->call_procedure(
          funcname => 'setting_increment',
          args     => ['asset_tag']
    );
    return $ref->{setting_increment};
}

sub _asset_get {
    my ($request) = @_;

    my ($ref) = $request->call_procedure( funcname => 'asset__get', args => [ $request->{id} ]);
    return $ref;
}


sub asset_edit {
    my ($request) = @_;
    return asset_screen($request, _asset_get($request));
}

=item asset_screen

Screen to create a new asset.

No inputs required, any standard properties from LedgerSMB::DBObject::Asset
can be used to set defaults.

=cut

sub asset_screen {
    my ($request, $asset) = @_;

    my $template = $request->{_wire}->get('ui');
    return $template->render(
        $request, 'asset/edit_asset',
        {
            request => $request,
            asset => {
                title => $asset->{title} // $request->{_locale}->text('Add Asset'),
                tag   => $asset->{tag} // _asset_get_next_tag($request),
                $asset->%*,
                _asset_get_metadata($request)->%*
            }
        });
}

=item asset_search

Displays the search screen for asset items.  No inputs required.

Any inputs for asset_results can be used here to set defaults.

=cut

sub asset_search {
    my ($request) = @_;
    my $template = $request->{_wire}->get('ui');
    return $template->render(
        $request, 'asset/search_asset',
        {
            request => $request,
            asset => _asset_get_metadata($request)
        });
}

=item asset_results

Searches for asset items and displays them

=cut

sub asset_results {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::Asset->new(
            $request->%{ qw( asset_class description
                             tag usable_life) },
            _locale => $request->{_locale},
            _uri => $request->{_uri},
            formatter_options => $request->formatter_options,
            purchase_date => $request->parse_date( $request->{purchase_date} ),
            purchase_value => $request->parse_amount( $request->{purchase_value} ),
            salvage_value => $request->parse_amount( $request->{salvage_value} ),
        ));
}

=item asset_save

Saves the asset.

Additionally this also creates a note with the vendor number and invoice number
for future reference, since this may not have been entered specifically as a
vendor transaction in LedgerSMB.

=cut

sub asset_save {
    my ($request) = @_;

    my ($newasset) = $request->call_procedure(
        funcname => 'asset__save',
        args      => [
            $request->@{qw(id asset_class description tag
                          purchase_date purchase_value
                          usable_life salvage_value
                          start_depreciation warehouse_id
                          department_id invoice_id
                          asset_account_id dep_account_id
                          exp_account_id obsolete_by)}
        ]);

    $request->call_procedure(
        funcname => 'asset_item__add_note',
        args      => [
            $newasset->{id},
            'Vendor/Invoice Note',
            qq|
Vendor: $request->{meta_number}
Invoice: $request->{invnumber}
|
        ]);

    return asset_screen($request, $newasset);
}

=item new_report

Starts the new report workflow.  No inputs required.

report_init inputs can be used to set defaults.

=cut

sub _asset_report_get {
    my ($request, $id) = @_;

    my ($ref) = $request->call_procedure(
        funcname => 'asset_report__get',
        args     => [ $id ]);

    if ($ref->{report_class} == 1) {
        $ref->{report_lines} = [
            $request->call_procedure(
                funcname => 'asset_report__get_lines',
                args     => [ $id ])
            ];
    }
    elsif ($ref->{report_class} == 2) {
        $ref->{report_lines} = [
            $request->call_procedure(
                funcname => 'asset_report__get_disposal',
                args     => [ $id ])
            ];
    }
    elsif ($ref->{report_class} == 4) {
        $ref->{report_lines} = [
            $request->call_procedure(
                funcname => 'asset_report_partial_disposal_details',
                args     => [ $id ])
            ];
    }

    return $ref;
}

sub _asset_report_get_metadata {
    my ($request) = @_;

    return {
        asset_classes => [ $request->call_procedure( funcname => 'asset_class__list', args => [] ) ],
        disp_methods  => [ $request->call_procedure( funcname => 'asset_report__get_disposal_methods', args => [] ) ],
        cash_accounts => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_report__get_cash_accts', args => [] ) ],
        exp_accounts => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_report__get_expense_accts', args => [] ) ],
        gain_accounts => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_report__get_gain_accts', args => [] ) ],
        loss_accounts => [
            map { $_->{text} = $_->{accno} . '--' . $_->{description}; $_ }
            $request->call_procedure( funcname => 'asset_report__get_loss_accts', args => [] ) ],
    };
}

sub new_report {
    my ($request) = @_;

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'asset/begin_report',
                             { request => $request,
                               report => {
                                   depreciation => $request->{depreciation},
                                   _asset_report_get_metadata($request)->%*
                               }
                             });
}

=item report_init

Creates a report and populates the screen with possible report lines.

Inputs expected:
* report_id int:  Report to enter the transactions into,
* accum_account_id int:  ID for accumulated depreciation.

=cut

sub report_init {
    my ($request) = @_;

    my @assets = $request->call_procedure(
        funcname => 'asset_report__generate',
        args     => [
            $request->{depreciation},
            $request->{asset_class},
            $request->{report_date}
        ]);
    if ($request->{depreciation}) {
        $_->{checked} = 'CHECKED' for @assets;
    }
    return display_report($request,
                          {
                              assets => \@assets,
                              depreciation => $request->{depreciation},
                              asset_class => $request->{asset_class},
                              report_date => $request->{report_date},
                              report_class => $request->{report_clas},
                              id => $request->{id},
                              accum_account_id => $request->{accum_account_id}
                          });
}

=item report_save

Saves the report.

see LedgerSMB::DBObject::Asset_Report->save() for expected inputs.

=cut

sub report_save{
    my ($request) = @_;

    my @ids =
        (map { $request->{"row_$_"} }
         grep { $request->{"asset_$_"} }
         1 .. $request->{rowcount_});

    if ($request->{depreciation}) {
        my ($ref) = $request->call_procedure(
            funcname => 'asset_report__save',
            args     => [
                $request->@{qw( id report_date report_class asset_class )}
            ]);

        my $id = $ref->{id};
        my ($dep) = $request->call_procedure(
            funcname => 'asset_class__get_dep_method',
            args     => [ $request->{asset_class} ]);
        $request->call_procedure(
            funcname => $dep->{sproc},
            args     => [
                \@ids,
                $request->{report_date},
                $id
            ]);
    }
    else {
        my ($ref) = $request->call_procedure(
            funcname => 'asset_report__begin_disposal',
            args     => [
                $request->{asset_class},
                $request->{report_date},
                $request->{report_class}
            ]);

        for my $i (grep { $request->{"asset_$_"}  }
                   0 .. $request->{rowcount_}) {
            my $id = $request->{"asset_$i"};
            $request->call_procedure(
                funcname => 'asset_report__dispose',
                args     => [
                    $ref->{id},
                    $id,
                    $request->{"amount_$id"},
                    $request->{"dm_$id"},
                    $request->{"percent_$id"}
                ]);
        }
    }

    return new_report($request);
}

=item report_get

Retrieves the report identified by the id input and displays it.

=cut

sub report_get {
    my ($request) = @_;
    return display_report($request, asset_report_get($request, $request->{id}));
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
    $report = {
        $report->%*,
        _asset_report_get_metadata($request)->%*
    };
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
        { name  => '__action',
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
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'Reports/display_report', {
        FORM_ID => $request->{form_id},
        HIDDENS => $hiddens,
        SCRIPT  => $request->{script},
        name    => $title,
        columns => $cols,
        rows    => $rows,
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

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'asset/begin_approval',
                             { request => $request,
                               asset_report => _asset_report_get_metadata($request) });
}

=item report_results

Executes the search for asset reports and displays the results.  See the
required inputs for LedgerSMB::DBObject::Asset_Report->search() for a list of
inputs.

=cut

sub report_results {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $ar = _asset_report_get_metadata($request);

    my @results = $request->call_procedure(
        funcname => 'asset_report__search',
        args     => [
            $request->@{qw(start_date end_date asset_class approved entered_by)}
        ]);

    my $base_href = 'asset.pl?__action=report_details&'.
                     "expense_acct=$request->{expense_acct}";
    if ($request->{depreciation}){
             $base_href .= '&depreciation=1';
    } else {
             $base_href .= "&gain_acct=$request->{gain_acct}&loss_acct=".
                            "$request->{loss_acct}&cash_acct=$request->{cash_acct}";
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
        cash_acct => $request->{cash_acct},
    };
    my $count = 0;
    for my $r (@results){
        next if (($r->{report_class} != 1 and $request->{depreciation})
                 or ($r->{report_class} == 1 and not $request->{depreciation}));
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
            total          => $request->format_amount($r->{total}, money => 1),
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
                   name  => '__action',
                   value => 'report_results_approve'
                   },
        ];

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'Reports/display_report', {
         FORM_ID => $request->{form_id},
         HIDDENS => $hiddens,
         SCRIPT  => $request->{script},
         name    => $locale->text('Report Results'),
         rows    => $rows,
         columns => $cols,
         buttons => $buttons,
   });
}

=item report_details

Displays the details of an existing report.  Requires that the id request arg is
set which represents the id of the report.

=cut

sub report_details {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $report = _asset_report_get($request, $request->{id});
    if ($report->{report_class} == RC_DISPOSAL) {
      return disposal_details($request, $report);
    } elsif ($report->{report_class} == RC_PARTIAL_DISPOSAL ) {
      return partial_disposal_details($request, $report);
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
                      $report->{id}, $request->format_amount( $report->{report_date} ) );
    my $rows = [];
    for my $r (@{$report->{report_lines}}){
        for my $amt (qw(purchase_value basis prior_dep dep_this_time dep_ytd
                        dep_total)){
             $r->{$amt} = $request->format_amount( $r->{$amt}, money  => 1);
        }
        push @$rows, $r;
    }
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  '__action',
                   value => 'report_details_approve'
                   },
    ];
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'Reports/display_report', {
        FORM_ID => $request->{form_id},
        HIDDENS => { id => $report->{id} },
        SCRIPT  => $request->{script},
        name    => $title,
        columns => $cols,
        rows    => $rows,
        buttons => $buttons
    });
}

=item partial_disposal_details

Displays the results of a partial disposal report.  The id must be set to the
id of the report desired.

=cut

sub partial_disposal_details {
    my ($request, $report) = @_;
    my $locale = $request->{_locale};

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
            col_id => 'purchase_value',
            name   => $locale->text('Aquired Value'),
            type   => 'text',
            class  => 'amount',
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
             $r->{$amt} = $request->format_amount( $r->{$amt}, money => 1);
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
                   name =>  '__action',
                   value => 'disposal_details_approve'
                   },
        ];

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'Reports/display_report', {
        SCRIPT  => $request->{script},
        HIDDENS => {
            id        => $report->{id},
            gain_acct => $report->{gain_acct},
            loss_acct => $report->{loss_acct},
            cash_acct => $report->{cash_acct},
        },
        FORM_ID => $request->{form_id},
        name    => $title,
        columns => $cols,
        rows    => $rows,
        buttons => $buttons
    });
}

=item disposal_details

Displays the details of a disposal report.

id must be set to the id of the report to be displayed.

=cut

sub disposal_details {
    my ($request, $report) = @_;
    my $locale = $request->{_locale};

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
            col_id => 'purchase_value',
            name   => $locale->text('Aquired Value'),
            type   => 'text',
            class  => 'amount',
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
             $r->{$amt} = $request->format_amount( $r->{$amt}, money  => 1);
        }
        push @$rows, $r;
    }
    my $buttons = [{
                   text  => $locale->text('Approve'),
                   type  => 'submit',
                   class => 'submit',
                   name =>  '__action',
                   value => 'disposal_details_approve'
                   },
        ];
    my $title = $locale->text('Disposal Report [_1] on date [_2]',
                     $report->{id}, $report->{report_date});
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'Reports/display_report', {
        SCRIPT  => $request->{script},
        HIDDENS => {
            id        => $report->{id},
            gain_acct => $report->{gain_acct},
            loss_acct => $report->{loss_acct},
            cash_acct => $report->{cash_acct},
        },
        FORM_ID => $request->{form_id},
        name    => $title,
        columns => $cols,
        rows    => $rows,
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

For depreciation reports, expense_acct must be set to an appropriate account id.

=cut

sub report_details_approve {
    my ($request) = @_;

    $request->call_procedure(
        funcname => 'asset_report__aprove',
        args     => [
            $request->@{qw( id expense_acct gain_acct loss_acct cash_acct )}
        ]);
    return search_reports($request);
}

=item report_results_approve

Loops through the input and approves all selected reports.

For disposal reports, gain_acct, loss_acct and cash_acct must be set to appropriate
account id's.

For depreciation reports, expense_acct must be set to an appropriate accont id.

For each row, there is  report_$id field which if set to a true value, indicates
a report to be approved.

=cut

sub report_results_approve {
    my ($request) = @_;
    for my $l (0 .. $request->{rowcount_}){
        if ($request->{"select_$l"}){
            $request->call_procedure(
                funcname => 'asset_report__approve',
                args     => [
                    $request->{"select_$l"},
                    $request->@{qw( expense_acct gain_acct loss_acct cash_acct )}
                ]);
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
    return $request->render_report(
        LedgerSMB::Report::Assets::Net_Book_Value->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item begin_import

Displays the initial screen for asset import routines.

No inputs required.

=cut

sub begin_import {
    my ($request) = @_;
    my $template = $request->{_wire}->get('ui');
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
    my $asset = {
        %$request,
        _asset_get_metadata($request)->%*
    };

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

    my @file_columns =
        qw(tag purchase_date description asset_class location vendor
           invoice department asset_account purchase_value
           accum_dep nbv start_depreciation usable_life
           usable_life_remaining);
    for my $ail (_import_file($request)){
        my $ai = {};
        for (0 .. $#file_columns){
          $ai->{$file_columns[$_]} = $ail->[$_];
        }
        next if $ai->{purchase_value} !~ /\d/;
        $ai->{purchase_value} = $request->parse_amount(
             $ai->{purchase_value}
        );
        $ai->{accum_dep} = $request->parse_amount($ai->{accum_dep});
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
        $request->call_procedure(
            funcname => 'asset_report__import',
            args     => [
                $ai->@{qw(
                           description tag purchase_value
                           salvage_value usable_life purchase_date
                           start_depreciation location_id department_id
                           asset_account_id dep_account_id exp_account_id
                           asset_class_id invoice_id dep_report_id
                           accum_dep obsolete_other
                           )}
            ]);
    }
    $request->{info} = $request->{_locale}->text('File Imported');
    return begin_import($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
