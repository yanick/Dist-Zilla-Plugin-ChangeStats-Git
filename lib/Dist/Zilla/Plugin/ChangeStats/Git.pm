package Dist::Zilla::Plugin::ChangeStats::Git;
# ABSTRACT: 

=head1 SYNOPSIS

=head1 DESCRIPTION

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

sub munge_files {
  my ($self) = @_;

  my @output = $self->repo->run( 'log', '--stat', 'releases..master' );

  # actually, only the last line is interesting
  my $stats = "stats: " . $output[-1];

  my ($file) = grep { $_->name eq $self->change_file } @{ $self->zilla->files };
  return unless $file;

  my $changes = CPAN::Changes->load_string( $file->content, 
      next_token => qr/{{\$NEXT}}/
  );

  my ( $next ) = reverse $changes->releases;

  my @changes = $next->add_changes( $stats );

  $self->log_debug([ 'updating contents of %s in memory', $file->name ]);
  $file->content($changes->serialize);
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;
