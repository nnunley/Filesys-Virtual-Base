
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Filesys::Virtual::Base',
  license => 'perl',
  requires => {
    Filesys::Virtual => 0,
    Class::Accessor::Fast => 0,
  },
  build_requires => {
    Module::Build => 0,
    Test::More => 0 
  },
  auto_configure_requires => 1,
  create_makefile_pl => 'traditional',
);

$build->create_build_script();
