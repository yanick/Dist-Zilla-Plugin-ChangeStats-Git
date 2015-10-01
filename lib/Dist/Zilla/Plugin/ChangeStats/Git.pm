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

=head2 develop_branch

The master developing branch. Defaults to I<master>.

=head2 auto_previous_tag

If enabled, look in the guts of the L<Dist::Zilla::Plugin::Git::Tag> plugin in order to find the
previous release's tag. This will be then compared against the develop_branch. Defaults to false (0).

=head2 release_branch

The branch recording the releases. Defaults to I<releases>.

=cut

use strict;
use warnings;

use CPAN::Changes 0.17;
use Perl::Version;
use Git::Repository;
use Path::Tiny;

use Moose;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::AfterRelease
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

has "develop_branch" => (
    isa => 'Str',
    is => 'ro',
    default => 'master'
);

has "release_branch" => (
    isa => 'Str',
    is => 'ro',
    default => 'releases'
);

has "auto_previous_tag" => (
    isa => 'Bool',
    is => 'ro',
    default => 0,
);

has group => (
    is => 'ro',
    default => '',
);

has stats => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

	# What are we diffing against? :)
	my( $prev, $next ) = ( $self->release_branch, $self->develop_branch );
	if ( $self->auto_previous_tag ) {
		$prev = $self->_get_previous_tag;
		return if ! defined $prev;
	}
	$self->log_debug( "Comparing '$prev' against '$next' for code stats" );
        my @output = $self->repo->run( 'diff', '--stat',
            join '...', $prev, $next
        );

        # actually, only the last line is interesting
	if ( defined $output[-1] ) {
	        my $stats = "code churn: " . $output[-1];
		$stats =~ s/\s+/ /g;
	        return $stats;
	} else {
		return;
	}
  } 
);

sub _get_previous_tag {
	my( $self ) = @_;
	my @plugins = grep { $_->isa('Dist::Zilla::Plugin::Git::Tag') } @{ $self->zilla->plugins_with( '-Git::Repo' ) };
	die "We dont know what to do with multiple Git::Tag plugins loaded!" if scalar @plugins > 1;
	die "Please load the Git::Tag plugin to use auto_release_tag or disable it!" if ! scalar @plugins;
	(my $match = $plugins[0]->tag_format) =~ s/\%\w/\.\+/g; # hack.
	$match = ( grep { $_ =~ /$match/ } $self->repo->run( 'tag' ) )[-1];
	if ( ! defined $match ) {
		$self->log( "Unable to find the previous tag, trying to find the first commit!" );
		$match = $self->repo->run( 'rev-list', "--max-parents=0", 'HEAD' );
		if ( ! defined $match ) {
			$self->log( "Unable to find the first commit, giving up!" );
			return;
		}
	}
	return $match;
}

sub munge_files {
  my ($self) = @_;
  return unless $self->stats;
  my $changelog = $self->zilla->changelog;

  my ( $next ) = reverse $changelog->releases;

  $next->add_changes( { group => $self->group  }, $self->stats );

  $self->zilla->save_changelog($changelog);

}

sub after_release {
  my $self = shift;
  return unless $self->stats;
  my $changes = CPAN::Changes->load( 
      $self->zilla->changelog_name,
      next_token => qr/\{\{\$NEXT\}\}/
  ); 

  for my $next ( reverse $changes->releases ) {
    next if $next->version =~ /NEXT/;

    $next->add_changes( { group => $self->group  }, $self->stats );

    # and finally rewrite the changelog on disk
    path($self->zilla->changelog_name)->spew($changes->serialize);

    return;
  }

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
