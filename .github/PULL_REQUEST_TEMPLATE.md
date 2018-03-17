Thank you for working on the LedgerSMB code base and wanting to create
a pull request.

For the easiest processing and the best maintenance of the series of
commits ('line of history'), we ask you to take a few things into
consideration. Please:

 * Deal with a single topic in a single PR
   To clarify: fix a single bug or address a single problem in one PR
 * Whenever related, group changes to multiple files into a single commit
   That means: a single search-and-replace action across all files go into
   a single commit
 * Your commits will be become part of the line of commits of the project
   Please create and group your commits in a way that is helpful when
   someone later needs to research 'where does this line come from and why
   did it change'
 * Write tests to validate your change and make sure it continues to work
   in the future
 * Our code base uses a maximum line-width of 80 characters.

By default, all PRs will be tested using Travis CI. For documentation changes,
these tests may be skipped by putting `[skip ci]` somewhere in the commit
message.

For more coding standards and community guidelines, please consult the
links presented above this PR form.

