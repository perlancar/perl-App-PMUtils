package App::PMUtils;

use 5.010001;
use strict;
use warnings;

# VERSION
# DATE

our $_complete_module = sub {
    require Complete::Module;
    my %args = @_;

    my $word = $args{word} // '';

    # compromise, if word doesn't contain :: we use the safer separator /, but
    # if already contains '::' we use '::' (but this means in bash user needs to
    # use quote (' or ") to make completion behave as expected since : is a word
    # break character in bash/readline.
    my $sep = $word =~ /::/ ? '::' : '/';
    $word =~ s/\W+/::/g;

    my $shcomp = {};

    {
        completion => Complete::Module::complete_module(
            word      => $word,
            find_pmc  => 0,
            find_pod  => 0,
            separator => $sep,
            ci        => 1, # convenience
        ),
        is_path    => 1,
        path_sep   => $sep,
    };
};

our $_complete_pod = sub {
    require Complete::Module;
    my %args = @_;

    my $word = $args{word} // '';

    my $sep = $word =~ /::/ ? '::' : '/';
    $word =~ s/\W+/::/g;

    {
        completion => Complete::Module::complete_module(
            word      => $word,
            find_pm   => 0,
            find_pmc  => 0,
            find_pod  => 1,
            separator => '/',
            ci        => 1, # convenience
        ),
        is_path    => 1,
        path_sep   => $sep,
    };
};

1;
# ABSTRACT: Command line to manipulate Perl module files

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

 pminfo
 pmversion
 pmpath
 podpath
 pmless
 pmedit
 pmcost
 pmdoc
 pmman


=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other utilities existed?

For example, L<mpath> in L<Module::Path> distribution, L<mversion> in
L<Module::Version> distribution, etc.

True. The main point of these utilities is shell tab completion, to save
typing.

=head2 In shell completion, why do you use / (slash) instead of :: (double colon) as it should be?

If you type module name which doesn't contain any ::, / will be used as
namespace separator. Otherwise if you already type ::, it will use ::.

Colon is problematic because by default it is a word breaking character in bash.
This means, in this command:

 % pmpath Text:<tab>

bash is completing a new word (empty string), and in this:

 % pmpath Text::ANSITabl<tab>

bash is completing C<ANSITabl> instead of what we want C<Text::ANSITabl>.

The solution is to use quotes, e.g.

 % pmpath "Text:<tab>
 % pmpath 'Text:<tab>

or, use /.

=cut
