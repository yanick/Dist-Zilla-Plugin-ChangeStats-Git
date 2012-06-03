package Dist::Zilla::Role::Author::YANICK::Changelog;
# ABSTRACT: provides an accessor for the changelog

use strict;
use warnings;

use Moose::Role;
use List::Util qw/ first /;

=head1 ATTRIBUTES

=head1 changelog_name()

The name of the changelog file. Defaults to C<Changes>.

=cut

has changelog_name => (
    is => 'ro',
    lazy => 1,  # required here because of the lazy role
    default => 'Changes',
);

=head1 METHODS

=head2 changelog_file

Returns the changelog file object.

=cut 

sub changelog_file {
    my $self = shift;

    return first { $_->name eq $self->changelog_name } @{ $self->files };
};

=head2 changelog()

Returns a L<CPAN::Changes> object representing the changelog.

=cut

sub changelog {
    my $self = shift;

    return CPAN::Changes->load_string( 
        $self->changelog_file->content, 
        next_token => qr/{{\$NEXT}}/
    );
}

=head2 save_changelog( $changes )

Commit I<$changes> as the changelog file for the distribution.

=cut 

sub save_changelog {
    my $self = shift;
    my $changes = shift;
    $self->changelog_file->content($changes->serialize);
}

1;

__END__

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::Foo;

    use Moose;

    qith qw/ 
        Dist::Zilla::Role::Plugin
        Dist::Zilla::Role::FileMunger
    /;

    with 'Dist::Zilla::Role::Author::YANICK::RequireZillaRole' => {
        roles => [ qw/ Author::YANICK::Changelog / ],
    };

    sub munge_files {
        my $self = shift;

        my $changes = $self->changes;

        ...

        $self->save_changelog( $changes );
    }

=head1 DESCRIPTION

Allows to access directly the distribution's changelog.

