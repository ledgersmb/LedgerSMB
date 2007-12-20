#!/usr/bin/perl

# TODO:  Add POD -CT

require "config.pl";

use DBI;
# TODO:  Convert config.pl to namespace so we can use strict.

my $cycle_delay;

my $dbh = db_init();

# Basic db connection setup routines



my $sth;

while (1) {    # loop infinitely
    if ( $dbh->func('pg_notifies') ) {
        on_notify();
    }
    sleep $cycle_delay;
}

sub on_notify {
    my $job_id = 1;
    while ($job_id){
        ($job_id) = $dbh->selectrow_array( 
		"SELECT id from pending_job
		WHERE completed_at IS NULL
		ORDER BY id LIMIT 1
                FOR UPDATE" 
    	);
    	if ($job_id){
            $job_id = $dbh->quote($job_id);
            my ($job_class) = $dbh->selectrow_array(
		"select class from batch_class where id = 
			(select batch_class from pending_job where id = $job_id)"
            );
            # Right now, we assume that every pending job has a batch id.
            # Longer-run we may need to use a template handle as well. -CT
            $dbh->do('SELECT ' .
               $dbh->quote_identifier("job__process_$job_class") . "($job_id)"
            );
            my $errstr = $dbh->errstr;
            if (!$dbh->commit){ # Note error and clean up
                 # Note that this does not clean up the queue holding tables.
                 # This is a feature, not a bug, as it allows someone to review
                 # the actual data and then delete if required separately -CT
                 $dbh->do(
                      "UPDATE pending_job
                      SET completed_at = now(),
                          success = false,
                          error_condition = " . $dbh->quote($errstr) . "
                      WHERE id = $job_id"
                 );
                 $dbh->commit;
            }
            # The line below is necessary because the job process functions
            # use set session authorization so one must reconnect to reset
            # administrative permissions. -CT
            $dbh->disconnect;
            $dbh = db_init(); 
        }
    }
}

sub db_init {
    my $dsn = "dbi:Pg:dbname=$database";
    my $dbh = DBI->connect(
        $dsn, $db_user,
        $db_passwd,
        {
            AutoCommit => 0,
            PrintError => 0,
            RaiseError => 1,
        }
    );
    $dbh->{pg_enable_utf8} = 1;
    ($cycle_delay) = $dbh->selectrow_array(
		"SELECT value FROM defaults 
		WHERE setting_key = 'poll_frequency'"
    );
    if (!$cycle_delay){
        die "No Polling Frequency Set Up!";
    }
    $dbh->do("LISTEN job_entered");
    $dbh->commit;
    return $dbh;
}
