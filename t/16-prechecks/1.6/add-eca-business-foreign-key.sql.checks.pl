{
    q|Assert "inventory_report" table's columns can be upgraded| =>
        [
         {
             failure_data => [
                 [ qw( class control_code meta_number name description ) ],
                 [ 1, 'V-001', '1001', 'Vendor1', 'A vendor' ],
                 ],
             submit_session =>
                 # all DBD::Mock::Session data *after* the initial failure
                 # during the data-correction/ data-submission session
                 [
                  {
                      statement => q{UPDATE entity_credit_account eca
                        SET business_id = NULL
                      WHERE NOT EXISTS
                        (SELECT 1 FROM business b
                          WHERE eca.business_id = b.id)},
                      results => [],
                  },
                 ],
             response => {
                 confirm => 'clean',
             },
         },
        ],
}
