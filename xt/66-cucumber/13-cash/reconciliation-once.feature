@one-db
Feature: Journal lines can be included a reconciliation once
  Journal lines may be allocated to multiple reconciliations, but
  can only be marked as reconciled in one reconciliation.


Background:
  Given a standard test company
    And a fresh reconciliation account

Scenario: An uncleared journal line is not included in earlier reconciliations
  A journal line is *not* included in any reconciliations that are
  being created with an end date before the journal line's date.
    Given an uncleared journal line on 2000-02-01
     When I create a reconciliation ending on 2000-01-01
     Then the journal line is not in the reconciliation

Scenario: An uncleared journal line is included in matching reconciliations
  A journal line is included in each reconciliation that is being
  created with an end date *on* the journal line's date -- until the
  line is cleared.
    Given an uncleared journal line on 2000-01-01
     When I create two reconciliations ending on 2000-01-01
     Then the journal line is in the first reconciliation
      And the journal line is in the second reconciliation

Scenario: An uncleared journal line is included in later reconciliations
  A journal line is included in each reconciliation that is being
  created with an end date *after* the journal line's date -- until
  the line is cleared.
    Given an uncleared journal line on 2000-01-01
     When I create two reconciliations ending on 2000-02-01
     Then the journal line is in the first reconciliation
      And the journal line is in the second reconciliation

Scenario: A cleared journal line is not included in a reconciliation
  A journal line is *not* included in each reconciliation that is
  being created with an end date after the journal line's date as
  soon as the reconciliation is marked 'approved'.
    Given a cleared journal line on 2000-01-01
     When I create a reconciliation ending on 2000-02-01
     Then the journal line is not in the reconciliation

Scenario: A cleared journal line blocks a reconciliation clearing it again
  A journal line that has been cleared through one reconciliation,
  can't be included as cleared in another reconciliation with both
  reconciliations ending in 'approved' status.
    Given an uncleared journal line on 2000-01-01
      And two reconciliations ending on 2000-02-01
     When the journal line is cleared in the first reconciliation
      And the journal line is cleared in the second reconciliation
      And the first reconciliation is submitted
     Then the second reconciliation can't be submitted

Scenario: A cleared journal line does not block a reconciliation holding it uncleared
  A journal line that has been cleared through one reconciliation
  can be included in another reconciliation with both reconciliations
  ending in 'approved' status, as long as the journal line is not
  marked as 'cleared' in the second reconciliation.
    Given an uncleared journal line on 2000-01-01
      And two reconciliations ending on 2000-02-01
     When the journal line is cleared in the first reconciliation
      And the first reconciliation is submitted
     Then the second reconciliation can also be submitted

Scenario: An uncleared journal line does not block clearing the line later
  A journal line that has been cleared through one reconciliation
  can be included in another reconciliation with both reconciliations
  ending in 'approved' status, as long as the journal line is not
  marked as 'cleared' in the second reconciliation.
    Given an uncleared journal line on 2000-01-01
      And two reconciliations ending on 2000-02-01
     When the journal line is cleared in the first reconciliation
      And the second reconciliation is submitted
     Then the first reconciliation can also be submitted


