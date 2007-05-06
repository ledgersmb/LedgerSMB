#!c:\strawberry-perl\perl\bin\perl
# Use this script to convert the beginnings of files to the path to Strawberry Perl
# if you are installing with Strawberry Perl.

opendir DIR, ".";
@perlfiles = grep /\.pl/, readdir DIR;
closedir DIR;

foreach $file (@perlfiles) {
    open FH, '+<', "$file";

    @file = <FH>;

    seek( FH, 0, 0 );
    truncate( FH, 0 );

    $line = shift @file;

    print FH "#!c:\\strawberry-perl\\perl\\bin\\perl\n";
    print FH @file;

    close(FH);

}

