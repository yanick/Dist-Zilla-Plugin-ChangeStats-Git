package Dist::Zilla::Plugin::ChangeStats::Git;
BEGIN {
  $Dist::Zilla::Plugin::ChangeStats::Git::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: add code churn statistics to the changelog
$Dist::Zilla::Plugin::ChangeStats::Git::VERSION = '0.3.0';

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

has group => (
    is => 'ro',
    default => '',
);

has stats => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        
        my @output = $self->repo->run( 'diff', '--stat',
            join '...', $self->release_branch, $self->develop_branch
        );

        # actually, only the last line is interesting
        my $stats = "code churn: " . $output[-1];
        $stats =~ s/\s+/ /g;

        return $stats;
  } 
);

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ChangeStats::Git - add code churn statistics to the changelog

=head1 VERSION

version 0.3.0

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

=head2 release_branch

The branch recording the releases. Defaults to I<releases>.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
