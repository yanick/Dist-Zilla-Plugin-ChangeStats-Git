package Dist::Zilla::Role::Author::YANICK::Changelog;
BEGIN {
  $Dist::Zilla::Role::Author::YANICK::Changelog::AUTHORITY = 'cpan:YANICK';
}
{
  $Dist::Zilla::Role::Author::YANICK::Changelog::VERSION = '0.1.1';
}

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

has _changes => (
    is => 'rw',
    clearer => 'clear_changes',
);

sub changes {
    my $self = shift;

    return $self->_changes || $self->_changes( CPAN::Changes->load_string( 
        $self->changelog_file->content, 
        next_token => qr/{{\$NEXT}}/
    ));
}

sub set_changelog_auto_update {
    my $self = shift;

    for my $plugin ( @{ $self->plugins_with(-FileMunger) } ) {
        $plugin->meta->make_mutable;
        $plugin->meta->add_after_method_modifier('munge_files', sub{ 
                my $self = shift;
                $self->zilla->clear_changes;
        });
        $plugin->meta->add_before_method_modifier('munge_files', sub{ 
                return;
            my $self = shift;
            $self->zilla->load_changelog;
        });
        $plugin->meta->make_immutable;
    }
}

sub save_changelog {
    my $self = shift;
    #warn $self->changes->serialize;
    $self->changelog_file->content($self->changes->serialize);
}

before build_in => \&set_changelog_auto_update;

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::Author::YANICK::Changelog

=head1 VERSION

version 0.1.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

