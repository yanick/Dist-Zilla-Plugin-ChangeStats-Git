package Dist::Zilla::Role::Author::YANICK::RequireZillaRole;

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
                or $role =~ s/^/Dist::Zilla::Role::/ if $role !~ m/^Dist::Zilla::Role::/;

            next if $zilla->does($role);

            load $role;
            $role->meta->apply($zilla->meta)
        }

        # ... and close the patient
        $zilla->meta->make_immutable;

        return $self;

    }

}
