package LedgerSMB::TranslationWorkbench;

use strict;
use warnings;

use File::Find qw(find);
use File::Spec;
use Cwd qw(getcwd);
use POSIX qw(strftime);

sub new {
    my ($class, %args) = @_;
    my $root = File::Spec->rel2abs($args{root} // '.');
    return bless {
        root     => $root,
        dry_run  => $args{dry_run} // 0,
        verbose  => $args{verbose} // 0,
        skip     => { map { $_ => 1 } @{ $args{skip} // [] } },
        executor => $args{executor} // LedgerSMB::TranslationWorkbench::Executor->new(
            verbose => $args{verbose}),
    }, $class;
}

sub root { $_[0]->{root} }

sub version {
    my ($self) = @_;
    open my $fh, '<:encoding(UTF-8)', File::Spec->catfile($self->root, 'lib', 'LedgerSMB.pm')
        or die "Can't open LedgerSMB.pm: $!";
    while (my $line = <$fh>) {
        return $1 if $line =~ /^our \$VERSION = '(.*)';$/;
    }
    die "Version detection failed!\n";
}

sub header {
    my ($self, $date) = @_;
    $date //= strftime('%Y-%m-%d %H:%M', gmtime) . '+0000';
    return qq{msgid ""
msgstr ""
"Project-Id-Version: LedgerSMB @{[$self->version]}\\n"
"Report-Msgid-Bugs-To: devel\@lists.ledgersmb.org\\n"
"POT-Creation-Date: $date\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

};
}

sub collect_perl_sources {
    my ($self) = @_;
    my @files;
    my %excluded = map { File::Spec->catdir($self->root, $_) => 1 } qw(
        devel xt/lib xt/66-cucumber sql b UI/pod UI/node_modules utils/devel
    );
    find({
        wanted => sub {
            return if -d $_;
            return unless /\.(?:pl|pm)$/ && !/LaTeX/;
            my $path = $File::Find::name;
            return if grep { index($path, "$_\/") == 0 || $path eq $_ } keys %excluded;
            push @files, File::Spec->abs2rel($path, $self->root);
        },
        no_chdir => 1,
    }, $self->root);
    return [ sort @files ];
}

sub _run {
    my ($self, $stage, $command, $input) = @_;
    return '' if $self->{skip}{$stage};
    if ($self->{dry_run}) {
        warn "Dry run: @$command\n" if $self->{verbose};
        return '';
    }
    return $self->{executor}->run($command, $input);
}

sub rebuild {
    my ($self) = @_;
    my $old_cwd = getcwd;
    chdir $self->root or die "Can't change to " . $self->root . ": $!";
    my $result = eval { $self->_rebuild };
    my $error = $@;
    chdir $old_cwd or die "Can't restore working directory: $!";
    die $error if $error;
    return $result;
}

sub _rebuild {
    my ($self) = @_;
    my $pot = $self->header;
    my $root = $self->root;
    my $perl_files = join "\n", @{ $self->collect_perl_sources };
    $perl_files .= "\n" if length $perl_files;
    $pot .= $self->_run('perl', [File::Spec->catfile($root, 'utils/devel/extract-perl')],
        $perl_files);

    my @templates;
    find({ wanted => sub {
        my $relative = File::Spec->abs2rel($_, $root);
        return if $relative =~ m{^UI/node_modules(?:/|$)};
        push @templates, $_
            if -f $_ && /\.(?:html|tex|csv)$/ && $relative !~ m{^UI/(?:js|pod)/};
    }, no_chdir => 1 }, map { File::Spec->catdir($root, $_) } qw(UI templates t/data));
    $pot .= $self->_run('template', [File::Spec->catfile($root, 'utils/devel/extract-template-translations')],
        join("\n", sort @templates) . "\n");
    $pot .= $self->_run('sql', [File::Spec->catfile($root, 'utils/devel/extract-sql')],
        _read(File::Spec->catfile($root, 'sql', 'Pg-database.sql')));
    $pot .= $self->_run('vue', [File::Spec->catfile($root, 'utils/devel/extract-vue-template-translations.sh')]);
    $pot .= $self->_run('menu', [File::Spec->catfile($root, 'utils/devel/extract-menu-translations')]);

    if (!$self->{dry_run}) {
        if (!$self->{skip}{normalize}) {
            my $unique = $self->{executor}->run([qw(msguniq)], $pot);
            $pot = $self->{executor}->run([qw(msgcat --sort-output --width=80)], $unique);
        }
        _write(File::Spec->catfile($root, 'locale', 'LedgerSMB.pot'), $pot);
    }
    return $pot if $self->{dry_run};

    my @pofiles;
    find({ wanted => sub { push @pofiles, $_ if -f $_ && /\.po$/ },
           no_chdir => 1 }, File::Spec->catdir($root, 'locale'));
    for my $pofile (sort @pofiles) {
        next if $self->{skip}{merge};
        my $merged = $self->{executor}->run(
            [qw(msgmerge --quiet --no-fuzzy-matching), $pofile,
             File::Spec->catfile($root, 'locale', 'LedgerSMB.pot')]);
        _write($pofile, $merged);
    }
    my @locales;
    find({ wanted => sub { push @locales, $_ if -f $_ && /\.json$/ },
           no_chdir => 1 }, File::Spec->catdir($root, 'UI', 'src', 'locales'));
    for my $json (sort @locales) {
        next if $self->{skip}{json};
        (my $language = $json) =~ s{\.json$}{};
        $language =~ s{.*/}{};
        $self->{executor}->run([
            qw(npx --yes i18next-conv --quiet --skipUntranslated --language),
            $language, '--source', File::Spec->catfile($root, 'locale', 'po', "$language.po"),
            '--target', $json
        ]);
    }
    return $pot;
}

sub _read {
    open my $fh, '<:raw', $_[0] or die "Can't open $_[0]: $!";
    local $/;
    return <$fh>;
}

sub _write {
    open my $fh, '>:raw', $_[0] or die "Can't write $_[0]: $!";
    print {$fh} $_[1] or die "Can't write $_[0]: $!";
    close $fh or die "Can't close $_[0]: $!";
}

package LedgerSMB::TranslationWorkbench::Executor;

use IPC::Open3;
use IO::Select;
use Symbol qw(gensym);

sub new {
    my ($class, %args) = @_;
    return bless { verbose => $args{verbose} // 0 }, $class;
}

sub run {
    my ($self, $command, $input) = @_;
    warn "Running: @$command\n" if $self->{verbose};
    my ($in, $out, $err);
    $err = gensym;
    my $pid = eval { open3($in, $out, $err, @$command) };
    die "Failed to execute @$command: $@" if $@;
    print {$in} $input if defined $input;
    close $in;
    my ($result, $error) = ('', '');
    my %buffers = ($out => \$result, $err => \$error);
    my $select = IO::Select->new($out, $err);
    while (my @ready = $select->can_read) {
        for my $fh (@ready) {
            my $chunk;
            my $length = sysread($fh, $chunk, 8192);
            if (!$length) {
                $select->remove($fh);
                close $fh;
                next;
            }
            ${ $buffers{$fh} } .= $chunk;
        }
    }
    waitpid($pid, 0);
    die "Command failed (@$command): $error" if $? != 0;
    warn $error if $self->{verbose} && $error;
    return $result // '';
}

1;
