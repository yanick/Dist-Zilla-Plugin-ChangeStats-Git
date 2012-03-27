package Dist::Zilla::Role::Author::YANICK::Changelog;

use strict;
use warnings;

use Moose::Role;

=pod

has changelog => (
    is => 'ro',
    default => 'Changes',
);

has changelog_file => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my ($file) = grep { $_->name eq $self->changelog } @{ $self->files };
        return $file;
    },
);

has changes => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $file = $self->changelog_file;

        return CPAN::Changes->load_string( $file->content, 
            next_token => qr/{{\$NEXT}}/
        );
    }
);

sub save_changelog {
    my $self = shift;
    $self->changelog_file->content($self->changes->serialize);
}

before build => sub {
    my $self = shift;
    return;
    for my $plugin ( $self->plugins_with(-FileMunger)->flatten ) {
        $plugin->meta->make_mutable;
        $plugin->meta->add_after_method_modifier('munge_files', sub{ 
            warn "YAY!";
            my $self = shift;
            $self->zilla->save_changelog;
        });
        $plugin->meta->make_immutable;

    }

};

=cut

1;
