package Dist::Zilla::Role::Author::YANICK::RequireZillaRole;
BEGIN {
  $Dist::Zilla::Role::Author::YANICK::RequireZillaRole::AUTHORITY = 'cpan:YANICK';
}
{
  $Dist::Zilla::Role::Author::YANICK::RequireZillaRole::VERSION = '0.2.1';
}

use strict;
use warnings;

use Module::Load;
use MooseX::Role::Parameterized;
use Moose::Util qw( apply_all_roles ensure_all_roles );

parameter roles => (
    required => 1,
);

role {
    my $p = shift;

    sub BUILD {}

    after BUILD => sub { 
        my $self = shift;

        my $zilla = $self->zilla;

        # open the patient...
        $zilla->meta->make_mutable;

        for my $role ( @{ $p->roles } ) {
            $role =~ s/^\+// 
                or $role =~ s/^/Dist::Zilla::Role::/;

            next if $zilla->does($role);

            load $role;
            $role->meta->apply($zilla->meta)
        }

        # ... and close the patient
        $zilla->meta->make_immutable;

        return $self;

    }

}

__END__

=pod

=head1 NAME

Dist::Zilla::Role::Author::YANICK::RequireZillaRole

=head1 VERSION

version 0.2.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
