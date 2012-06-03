package Dist::Zilla::Plugin::ChangeStats::Git;
BEGIN {
  $Dist::Zilla::Plugin::ChangeStats::Git::AUTHORITY = 'cpan:YANICK';
}
{
  $Dist::Zilla::Plugin::ChangeStats::Git::VERSION = '0.1.2';
}
# ABSTRACT: add code churn statistics to the changelog


use strict;
use warnings;

use CPAN::Changes 0.17;
use Perl::Version;
use Git::Repository;

use Moose;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
/;

with 'Dist::Zilla::Role::Author::YANICK::RequireZillaRole' => {
    roles => [ qw/ Author::YANICK::Changelog / ],
};

has repo => (
    is => 'ro',
    default => sub { Git::Repository->new( work_tree => '.' ) },
);

has change_file => (
    is => 'ro',
    default => 'Changes',
);

has group => (
    is => 'ro',
    default => '',
);

sub munge_files {
  my ($self) = @_;

  my @output = $self->repo->run( 'diff', '--stat', 'releases..master' );

  # actually, only the last line is interesting
  my $stats = "code churn: " . $output[-1];
  $stats =~ s/\s+/ /g;

  my $changelog = $self->zilla->changelog;

  my ( $next ) = reverse $changelog->releases;

  $next->add_changes( { group => $self->group  }, $stats );

  $self->zilla->save_changelog($changelog);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::ChangeStats::Git - add code churn statistics to the changelog

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    In the dist.ini:

    [ChangeStats::Git]
    group=STATISTICS

=head1 DESCRIPTION

Adds a line to the changelog giving some stats about the
code churn since the last release, which will look like:

  - code churn: 6 files changed, 111 insertions(+), 1 deletions(-)

=head1 ARGUMENTS

=head2 group

If given, the line is added to the specified group.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

