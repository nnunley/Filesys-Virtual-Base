#! perl

use Test::More no_plan;

use lib 't';

use TestFS; # this class uses Filesys::Virtual::Base as its base class;

my $fs = TestFS->new;
use Data::Dumper;

is my $cwd = $fs->cwd(), "/", "We're at the root";

is $fs->root_path(), "/", "Root path is '/'  by default";
ok !defined $fs->home_path(), "Home path is undefined by default";

# Not deeply testing the spirit, just confirming that things are being called through
is_deeply [ $fs->stat('/a') ], [ qw( 0 1 2 3 4 5 6 7 8 9 10 11 12 13) ];

is_deeply [ $fs->list('/') ], [ qw( a b ) ] or diag Dumper([ $fs->list('/') ]);


is $fs->size('/a'), 7, "We have the 'right' size (stat field 7)";

is_deeply( [$fs->list_details('/') ], [
"--------w-    3 4        5               7 Jan  1  1970 a",
"--------w-    3 4        5               7 Jan  1  1970 b",
]) or diag Dumper([ $fs->list_details('/') ]);

is $fs->chdir('/a'), '/a', "Should be in the 'a' directory";
