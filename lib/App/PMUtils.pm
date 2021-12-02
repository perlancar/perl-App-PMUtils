package App::PMUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

our $arg_module_multiple = {
    #schema => ['perl::modnames*', min_len=>1], # XXX Perinci::Sub::GetArgs::Argv can't yet handle case for greedy=1 and when 'array' is not specified explicitly
    schema => ['array*', {
        of=>['perl::modname*'],
        min_len=>1,
        'x.perl.default_value_rules' => ["Perl::these_mods"],
    }],
    'x.perinci.cmdline.default_from_schema' => 1,
    #req    => 1,
    pos    => 0,
    slurpy => 1,
    element_completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
};

our $arg_module_single = {
    schema => ['perl::modname*', {
        'x.perl.default_value_rules' => ["Perl::this_mod"],
    }],
    'x.perinci.cmdline.default_from_schema' => 1,
    #req    => 1,
    pos    => 0,
    completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
};

our %argopts_pmpath_all = (
    all => {
        summary => 'Get all found files for each module instead of the first one',
        schema => 'bool',
        cmdline_aliases => {a=>{}},
    },
);

our %argopts_pmpath_types = (
    pm => {
        schema => ['int*', min=>0],
        default => 1,
    },
    pmc => {
        schema => ['int*', min=>0],
        default => 0,
    },
    pod => {
        schema => ['int*', min=>0],
        default => 0,
    },
);

$SPEC{pmpath} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
    args => {
        module => $App::PMUtils::arg_module_multiple,
        %argopts_pmpath_all,
        %argopts_pmpath_types,
        abs => {
            summary => 'Absolutify each path',
            schema => 'bool',
            cmdline_aliases => {P=>{}},
        },
        prefix => {
            schema => ['int*', min=>0],
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

Sometimes I forgot that <prog:pmpath> has a `-d` option, and often intuitively
look for a <prog:pmdir> command.

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

$SPEC{rel2mod} = {
    v => 1.1,
    summary => 'Convert release name (e.g. Foo-Bar-1.23.tar.gz) to '.
        'module name (Foo::Bar)',
    args => {
        releases => {
            #'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    result_naked => 1,
};
sub rel2mod {
    my %args = @_;

    #use DD; dd \%args;

    my @res;
    for (@{ $args{releases} }) {
        s!.+/!!; # remove directory path
        s/(.+)-v?\d.+/$1/;
        s/-/::/g;
        push @res, $_;
    }

    \@res;
}

$SPEC{pmunlink} = {
    v => 1.1,
    summary => 'Unlink (remove) locally installed Perl module',
    args => {
        module => $App::PMUtils::arg_module_multiple,
        %argopts_pmpath_all,
        %argopts_pmpath_types,
    },
    features => {
        dry_run => 1,
    },
};
sub pmunlink {
    my %args = @_;

    my $res = pmpath(%args);
    return $res unless $res->[0] == 200;

    return [304, "No module files to delete"] unless @{ $res->[2] };

    my $num_success = 0;
    my $num_fail    = 0;
    for my $item (@{ $res->[2] }) {
        my $path = ref $item eq 'HASH' ? $item->{path} : $item;
        my $success;

        if ($args{-dry_run}) {
            log_trace "[DRY_RUN] Unlinking $path ...";
            $num_success++;
            next;
        }
        log_trace "Unlinking $path ...";
        if (unlink $path) {
            $num_success++;
        } else {
            warn "Can't unlink $path: $!\n";
            $num_fail++;
        }
    }

    [$num_success ? 200:500,
     $num_success ? "OK" : "All files failed",
     undef,
     {'cmdline.exit_code' => $num_fail ? 1:0}];
}

$SPEC{pmabstract} = {
    v => 1.1,
    summary => 'Extract the abstract of locally installed Perl module(s)',
    args => {
        module => $App::PMUtils::arg_module_multiple,
    },
};
sub pmabstract {
    require Module::Abstract;

    my %args = @_;
    my @rows;
    for my $mod (@{ $args{module} }) {
        push @rows, {
            module => $mod,
            abstract => Module::Abstract::module_abstract($mod),
        };
    }

    if (@rows > 1) {
        return [200, "OK", \@rows, {'table.fields'=>[qw/module abstract/]}];
    } else {
        return [200, "OK", $rows[0]{abstract}];
    }
}

$SPEC{update_this_mod} = {
    v => 1.1,
    summary => 'Update "this" Perl module',
    description => <<'_',

Will use <pm:App::ThisDist>'s `this_mod()` to find out what the current Perl
module is, then run "cpanm -n" against the module. It's a convenient shortcut
for:

    % this-mod | cpanm -n

_
    args => {
        # XXX cpanm options
    },
    deps => {
        prog => 'cpanm',
    },
};
sub update_this_mod {
    require App::ThisDist;
    require IPC::System::Options;

    my %args = @_;

    my $mod = App::ThisDist::this_mod();
    return [412, "Can't determine the current module"] unless defined $mod;
    IPC::System::Options::system({log=>1, die=>1}, "cpanm", "-n", $mod);
    [200];
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

L<App::PerlReleaseUtils>, utilities related to Perl distribution releases.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=for END_BLOCK: see_also

=cut
