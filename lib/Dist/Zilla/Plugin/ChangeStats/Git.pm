package Dist::Zilla::Plugin::ChangeStats::Git;
# ABSTRACT: add code churn statistics to the changelog

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

=cut

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

  my @output = $self->repo->run( 'log', '--stat', 'releases..master' );

  # actually, only the last line is interesting
  my $stats = "code churn: " . $output[-1];
  $stats =~ s/\s+/ /g;

  my ( $next ) = reverse $self->zilla->changes->releases;

  $next->add_changes( { group => $self->group  }, $stats );

  $self->zilla->save_changelog;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
