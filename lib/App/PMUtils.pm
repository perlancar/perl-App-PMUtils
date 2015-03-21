package App::PMUtils;

# DATE
# VERSION

use 5.010001;

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

1;
# ABSTRACT: Command-line utilities related to Perl modules

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
modules:

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

L<App::OrgUtils>, utilities related to Org files.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::UpfUtils>, utilities related to Unix password/shadow files.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=for END_BLOCK: see_also

=cut
