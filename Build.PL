
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::DZil" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "add code churn statistics to the changelog",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-ChangeStats-Git",
  "dist_version" => "0.2.0",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::ChangeStats::Git",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CPAN::Changes" => "0.17",
    "Dist::Zilla::Role::AfterRelease" => 0,
    "Dist::Zilla::Role::FileMunger" => 0,
    "Dist::Zilla::Role::Plugin" => 0,
    "Git::Repository" => 0,
    "List::Util" => 0,
    "Module::Load" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "MooseX::Role::Parameterized" => 0,
    "Path::Tiny" => 0,
    "Perl::Version" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
