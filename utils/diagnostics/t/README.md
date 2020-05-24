This README explains a bit about the scripts in `utils/diagnostics/t/`.

All scripts must start with a 2 or 3 digit number and end with the extension ".t"

The number describes the type of information the script will gather and should
follow this list.

```plain
100 - system info
200 - user environment tests
300 - perl environment tests
400 - postgres tests
500 - performance tests
```

The most basic test script could look like this....

```bash
#!/bin/bash

echo "this to the user: your username is $USER"
echo "this to the log: this test was run as user $USER" 1>&5
```

As you can see, any output that is sent to `fd5` will end up in the appropriate
log file.

____

When run, any scripts matching `utils/diagnostics/t/*.t` will be executed in
lexical order.

* `stdin` and `stdout` are available to those scripts for user interaction.
* `fd5` will be redirected to a `logfile` named the same as the test script
* all `logfiles` will be created in a `tempdir` created with `mktemp -dt lsmb-diag.XXXX`
* a `.lock` file will be created within each `tempdir` and removed on exit from `diagnose.sh`
* all non-locked `tempdirs` will be removed at the start of running `diagnose.sh`
* `diagnose.sh` handles creation of the `tempdir`, and actual redirection of `fd5`
to the `logfile`
* `diagnose.sh` creates a `tarball` of the contents of the `tempdir` before
"normal" exit
