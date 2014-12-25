package App::PMUtils;

use 5.010001;
use strict;
use warnings;

# VERSION
# DATE

sub _complete_stuff {
    require Complete::Module;

    my $which = shift;

    my %args = @_;

    my $word = $args{word} // '';

    # convenience (and compromise): if word doesn't contain :: we use the
    # "safer" separator /, but if already contains '::' we use '::'. Using "::"
    # in bash means user needs to use quote (' or ") to make completion behave
    # as expected since : is by default a word break character in bash/readline.
    my $sep = $word =~ /::/ ? '::' : '/';

    # convenience: shortcuts (should make this user-configurable in the future).
    # so if user types 'dzp' it will become 'Dist/Zilla/Plugin/', if she types
    # 'dzp::' then it will become 'Dist::Zilla::Plugin::'
    state $shortcuts = {
        dzp => 'Dist/Zilla/Plugin/',
        pwp => 'Pod/Weaver/Plugin/',
        pws => 'Pod/Weaver/Section/',
    };
    {
        my $tmp = lc $word;
        if ($shortcuts->{$tmp}) {
            $word = $shortcuts->{$tmp};
            $word =~ s!/!$sep!g;
        }
    }

    # convenience: allow Foo/Bar.{pm,pod,pmc}
    $word =~ s/\.(pm|pmc|pod)\z//;

    my $res;
    {
        my $word = $word;
        $word =~ s/\Q$sep\E/::/g;
        $res = Complete::Module::complete_module(
            word      => $word,
            find_pm   => $which eq 'pod' ? 0 : 1,
            find_pmc  => $which eq 'pod' ? 0 : 1,
            find_pod  => $which eq 'pod' ? 1 : 0,
        );
        for (@$res) {
            s/::/$sep/g;
        }
    }

    {
        words => $res,
        path_sep => $sep,
    };
};

our $_complete_module = sub { _complete_stuff('module', @_) };
our $_complete_pod    = sub { _complete_stuff('pod', @_) };

1;
# ABSTRACT: Command-line utilities related to Perl modules

=head1 SYNOPSIS

This distribution provides several command-line utilities related to Perl
modules. The main purpose of these utilities is tab completion.


=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other utilities existed?

For example, L<mpath> in L<Module::Path> distribution, L<mversion> in
L<Module::Version> distribution, etc.

True. The main point of these utilities is shell tab completion, to save
typing.

=head2 For shell completion, why do you recommend the use of / (slash) instead of :: (double colon) as it should be?

Colon is problematic because by default it is a word breaking character in bash.
This means, in this command:

 % pmpath Text:<tab>

bash is completing a new word (empty string), and in this:

 % pmpath Text::ANSITabl<tab>

bash is completing C<ANSITabl> instead of what we want C<Text::ANSITabl>.

The solution is to use quotes, e.g.

 % pmpath "Text:<tab>
 % pmpath 'Text:<tab>

or, use /, which is by default not a word-breaking character in bash.

The utilities are a bit smart: they accept both kinds of separator. If you type
module name which doesn't contain any ::, / will be used as namespace separator;
otherwise if you already type ::, it will use :: as the separator.


=head1 SEE ALSO

L<App::PlUtils>, distribution that provides utilities related to Perl scripts.

L<App::ProgUtils>, a similarly spirited distribution.

=cut
