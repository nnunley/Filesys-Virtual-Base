package TestFS;
use strict;
use warnings;

use base 'Filesys::Virtual::Base';
my $DATA = {
  '/' => {
    'list' => [ qw( a b ) ],
    test => { 'e' => 1, 'd' => 1 },
    'stat' => [ qw( 0 0 0 0 0 0 0 0 0 0 0 0 0 ) ],
  },
  '/a' => {
    test => {
      'e' => 1,
      'd' => 1
    },
    list => [],
    'stat' => [ qw( 0 0 0 0 0 0 7 0 0 0 0 0 0 ) ],
  },
  '/b' => {
    test => {
      'e' => 1,
      'f' => 1
    },
    list => [],
    'stat' => [ qw( 0 0 0 0 0 0 7 0 0 0 0 0 0 ) ],

  },
};

sub stat {
  my ($self, $path) = shift;
  return qw(0 1 2 3 4 5 6 7 8 9 10 11 12 13);
}

sub test {
  my ($self, $test, $path) = @_;
  return 1;
}

sub list {
  my ($self, $path) = @_;
  
  return qw( a b );
}

1;