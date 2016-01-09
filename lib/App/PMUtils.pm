package App::PMUtils;

# DATE
# VERSION

use 5.010001;

our %SPEC;

our $arg_module_multiple = {
    schema => ['array*' => of=>'str*', min_len=>1],
    req    => 1,
    pos    => 0,
    greedy => 1,
    element_completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
};

our $arg_module_single = {
    schema => 'str*',
    req    => 1,
    pos    => 0,
    completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
};

$SPEC{pmpath} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
    args => {
        module => $App::PMUtils::arg_module_multiple,
        all => {
            summary => 'Return all found files for each module instead of the first one',
            schema => 'bool',
            cmdline_aliases => {a=>{}},
        },
        abs => {
            summary => 'Absolutify each path',
            schema => 'bool',
            cmdline_aliases => {P=>{}},
        },
        pm => {
            schema => 'bool',
            default => 1,
        },
        pmc => {
            schema => 'bool',
            default => 0,
        },
        pod => {
            schema => 'bool',
            default => 0,
        },
        prefix => {
            schema => 'bool',
            default => 0,
        },
        dir => {
            summary => 'Show directory instead of path',
            description => <<'_',

Also, will return `.` if not found, so you can conveniently do this on a Unix
shell:

    % cd `pmpath -Pd Moose`

and it won't change directory if the module doesn't exist.

_
            schema  => ['bool', is=>1],
            cmdline_aliases => {d=>{}},
        },
    },
};
sub pmpath {
    require Module::Path::More;
    my %args = @_;

    my $mods = $args{module};
    my $res = [];
    my $found;

    for my $mod (@{$mods}) {
        my $mpath = Module::Path::More::module_path(
            module      => $mod,
            find_pm     => $args{pm},
            find_pmc    => $args{pmc},
            find_pod    => $args{pod},
            find_prefix => $args{prefix},
            abs         => $args{abs},
            all         => $args{all},
        );
        $found++ if $mpath;
        for (ref($mpath) eq 'ARRAY' ? @$mpath : ($mpath)) {
            if ($args{dir}) {
                require File::Spec;
                my ($vol, $dir, $file) = File::Spec->splitpath($_);
                $_ = $dir;
            }
            push @$res, @$mods > 1 ? {module=>$mod, path=>$_} : $_;
        }
    }

    if ($found) {
        [200, "OK", $res];
    } else {
        if ($args{dir}) {
            [200, "OK (not found)", "."];
        } else {
            [404, "No such module"];
        }
    }
}

$SPEC{pmdir} = do {
    my $meta = { %{ $SPEC{pmpath} } }; # shallow copy
    $meta->{summary} = "Get directory of locally installed Perl module/prefix";
    $meta->{description} = <<'_';

This is basically a shortcut for:

    % pmpath -Pd MODULE_OR_PREFIX_NAME

Sometimes I forgot that `pmpath` has a `-d` option, and often intuitively look
for a `pmdir` command.

_
    $meta->{args} = { %{ $SPEC{pmpath}{args} } }; # shalow copy
    delete $meta->{args}{all};
    delete $meta->{args}{dir};
    delete $meta->{args}{prefix};
    $meta;
};
sub pmdir {
    pmpath(@_, prefix=>1, dir=>1);
}

1;
# ABSTRACT: Command-line utilities related to Perl modules

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
modules:

#INSERT_EXECS_LIST

The main purpose of these utilities is tab completion.


=head1 FAQ

=for BEGIN_BLOCK: faq

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=for END_BLOCK: faq


=head1 SEE ALSO

=for BEGIN_BLOCK: see_also

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=for END_BLOCK: see_also

=cut
