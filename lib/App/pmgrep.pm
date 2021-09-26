## no critic: InputOutput::RequireBriefOpen

package App::pmgrep;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'pmgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines from installed Perl module sources matching a pattern',
    description => <<'_',

This is a like the Unix command **grep** but instead of specifying filenames,
you specify module names or prefixes. The utility will search module source
files from Perl's `@INC`.

Examples:

    # Find pre-increment in all Perl module files
    % pmgrep '\+\+\$'

    # Find some pattern in all Data::Sah::Coerce::* modules (note ** wildcard for recursing)
    % pmgrep 'return ' Data::Sah::Coerce::**

_
    add_args    => {
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => 'perl::modnames*',
            pos => 1,
            greedy => 1,
            description => <<'_',

If not specified, all installed Perl modules will be searched.

_
        },
        pm  => {
            schema => 'bool*',
            default => 1,
            summary => 'Whether to include .pm files',
            'summary.alt.bool.neg' => 'Do not include .pm files',
        },
        pod => {
            schema => 'bool*',
            summary => 'Whether to include .pod files',
        },
        pmc => {
            schema => 'bool*',
            summary => 'Whether to include .pmc files',
        },
        recursive => {
            schema => 'true*',
            cmdline_aliases => {r=>{}},
        },
    },
    output_code => sub {
        require Module::Path::More;
        require PERLANCAR::Module::List;

        my %args = @_;
        $args{pm} //= 1;

        my %files;
        for my $q (@{ $args{modules} // [""] }) {
            if ($q eq '' || $q =~ /::\z/ || $args{recursive}) {
                my $mods = PERLANCAR::Module::List::list_modules(
                    $q eq '' || $q =~ /::\z/ ? $q : "$q\::",
                    {
                        list_modules => $args{pm} || $args{pmc},
                        list_pod     => $args{pod},
                        recurse      => $args{recursive},
                        return_path  => 1,
                    },
                );
                $files{ $mods->{$_} }++ for keys %$mods;
            }
            if ($q =~ /\A\w+(\::\w+)*\z/) {
                my $path = Module::Path::More::module_path(
                    module   => $q,
                    find_pm  => $args{pm},
                    find_pmc => $args{pmc},
                    find_pod => $args{pod},
                );
                $files{$path}++ if $path;
            }
        }
        my @files = sort keys %files;
        die "No module source files found!\n" unless @files;

        my ($fh, $file);
        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "pmgrep: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $file);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT:
