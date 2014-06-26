package App::PMUtils;

use 5.010001;
use strict;
use warnings;

# VERSION
# DATE

1;
# ABSTRACT: Command line to manipulate Perl module files

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

 pminfo
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

True. The main point of these utilities are shell tab completion, to save
typing.

=head2 In shell completion, why do you use / (slash) instead of :: (double colon) as it should be?

Colon is problematic because by default it is a word breaking character in bash.
Here's my default COMP_WORDBREAKS:

 "'@><=;|&(:

This means, in this command:

 % pmpath Text:<tab>

bash is completing a new word (empty string), and in this:

 % pmpath Text::ANSITabl<tab>

bash is completing C<ANSITabl> instead of what we want C<Text::ANSITabl>.

So the workaround, instead of telling users to modify their COMP_WORDBREAKS
setting, is to use another character for the module separator (C</>).

=cut
