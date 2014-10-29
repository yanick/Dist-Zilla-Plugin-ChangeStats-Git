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

=head2 develop_regexp

A regular expression to be used to search for tags. The most recent one matching this
regex will be used. Overrides the default set in develop_branch if specified. Defaults to none.

NOTE: You need to capture the entire tag in the regexp! This is especially useful in conjunction
with the L<Dist::Zilla::Plugin::Git::Tag> plugin! Sample usage in the F<dist.ini> file:

	[ChangeStats::Git]
	release_regexp = ^(release-.+)$

	[Git::Tag]
	tag_format = release-%v

=head2 release_branch

The branch recording the releases. Defaults to I<releases>.

=head2 release_regexp

A regular expression to be used to search for tags. The most recent one matching this
regex will be used. Overrides the default set in release_branch if specified. Defaults to none.

=cut

use strict;
use warnings;

use CPAN::Changes 0.17;
use Perl::Version;
use Git::Repository;
use Path::Tiny;

use Moose;
use Moose::Util::TypeConstraints;

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

use constant _CoercedRegexp => do {
    my $tc = subtype as 'RegexpRef';
    coerce $tc, from 'Str', via { qr/$_/ };
    $tc;
};

has develop_regexp => (
    is => 'ro',
    isa=> _CoercedRegexp,
    coerce => 1,
    predicate => '_has_develop_regexp',
);

has release_regexp => (
    is => 'ro',
    isa=> _CoercedRegexp,
    coerce => 1,
    predicate => '_has_release_regexp',
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
	if ( $self->_has_release_regexp ) {
		$prev = $self->_get_release_tag( $self->release_regexp );
	}
	if ( $self->_has_develop_regexp ) {
		$next = $self->_get_release_tag( $self->develop_regexp );
	}

        my @output = $self->repo->run( 'diff', '--stat',
            join '...', $prev, $next
        );

        # actually, only the last line is interesting
        my $stats = "code churn: " . $output[-1];
        $stats =~ s/\s+/ /g;

        return $stats;
  } 
);

sub _get_release_tag {
	my( $self, $regex ) = @_;

	# search whatever matches our regex, then return the most recent one
	my $match = ( map { $_ =~ /$regex/ } $self->repo->run( 'tag' ) )[-1];
	die "Unable to find a matching tag for $regex" if ! defined $match;
	return $match;
}

sub munge_files {
  my ($self) = @_;

  my $changelog = $self->zilla->changelog;

  my ( $next ) = reverse $changelog->releases;

  $next->add_changes( { group => $self->group  }, $self->stats );

  $self->zilla->save_changelog($changelog);

}

sub after_release {
  my $self = shift;

  my $changes = CPAN::Changes->load( 
      $self->zilla->changelog_name,
      next_token => qr/{{\$NEXT}}/ 
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
