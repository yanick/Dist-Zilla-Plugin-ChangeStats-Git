
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Carp" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::DZil" => 0,
    "Test::More" => "0.94",
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "add code churn statistics to the changelog",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-ChangeStats-Git",
  "dist_version" => "0.1.2",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::ChangeStats::Git",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CPAN::Changes" => "0.17",
    "Dist::Zilla::Role::FileMunger" => 0,
    "Dist::Zilla::Role::Plugin" => 0,
    "Git::Repository" => 0,
    "List::Util" => 0,
    "Module::Load" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "MooseX::Role::Parameterized" => 0,
    "Perl::Version" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
