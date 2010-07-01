
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Filesys::Virtual::Base',
  license => 'perl',
  requires => {
    Filesys::Virtual => undef,
    Class::Accessor::Fast => undef,
  },
  build_requires => {
    Test::More => undef
  },
  create_makefile_pl => 'traditional',
);

$build->create_build_script();
