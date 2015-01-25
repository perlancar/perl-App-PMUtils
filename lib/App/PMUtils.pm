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
