package Dist::Zilla::Role::Author::YANICK::Changelog;

use strict;
use warnings;

use Moose::Role;

has changelog => (
    is => 'ro',
    lazy => 1,  # required here because of the lazy role
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

        return CPAN::Changes->load_string( 
            $self->changelog_file->content, 
            next_token => qr/{{\$NEXT}}/
        );
    }
);

sub set_changelog_auto_update {
    my $self = shift;

    for my $plugin ( @{ $self->plugins_with(-FileMunger) } ) {
        $plugin->meta->make_mutable;
        $plugin->meta->add_after_method_modifier('munge_files', sub{ 
            my $self = shift;
            $self->zilla->save_changelog;
        });
        $plugin->meta->make_immutable;
    }
}

sub save_changelog {
    my $self = shift;
    warn 'saving...';
    warn $self->changes->serialize;
    $self->changelog_file->content($self->changes->serialize);
}

before build_in => \&set_changelog_auto_update;

1;
