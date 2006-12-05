#!c:\perl\bin\perl
# Use this script to convert the beginnings of files to the path to ActivePerl 
# if you are installing with ActivePerl.

  opendir DIR, ".";
  @perlfiles = grep /\.pl/, readdir DIR;
  closedir DIR;

  foreach $file (@perlfiles) {
    open FH, '+<', "$file";
    
    @file = <FH>;

    seek(FH, 0, 0);
    truncate(FH, 0);

    $line = shift @file;

    print FH "#!c:\\perl\\bin\\perl\n";
    print FH @file;

    close(FH);
    
  }
