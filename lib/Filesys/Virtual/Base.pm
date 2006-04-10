package Filesys::Virtual::Base;

use strict;
use warnings;

our $VERSION = 0.1;
use base qw(
	Filesys::Virtual
	Class::Accessor::Fast
);

__PACKAGE__->mk_accessors(qw(cwd root_path home_path user group));

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->root_path('/') unless $self->root_path;
  $self->cwd('/') unless $self->cwd;
  return $self;
}

=pod

=head1 NAME

Filesys::Virtual::Base - A base class for virtual filesystems

=head1 SYNOPSIS

  package My::Virtual::FS;
  use base 'Filesys::Virtual::Base';

  my $fs = Filesys::Virtual::Plain->new();

  print foreach ($fs->list('/'));

=head1 DESCRIPTION

This module is used by other modules to provide a virtual filesystem.

=head1 CONSTRUCTOR

=head2 new()

You can pass the initial cwd, root_path, and home_path as a hash.

=head1 REQUIRED SUB-CLASS METHODS

=over

=item stat

=item test($test, $path)

Perform a perl type test on a file and returns the results.

For example to perform a -d on a directory.

  $self->test('d','/testdir');

See filetests in perlfunc (commandline: perldoc perlfunc)

#    -r  File is readable by effective uid/gid.
#    -w  File is writable by effective uid/gid.
#    -x  File is executable by effective uid/gid.
#    -o  File is owned by effective uid.

#    -R  File is readable by real uid/gid.
#    -W  File is writable by real uid/gid.
#    -X  File is executable by real uid/gid.
#    -O  File is owned by real uid.

#    -e  File exists.
#    -z  File has zero size.
#    -s  File has nonzero size (returns size).

#    -f  File is a plain file.
#    -d  File is a directory.
#    -l  File is a symbolic link.
#    -p  File is a named pipe (FIFO), or Filehandle is a pipe.
#    -S  File is a socket.
#    -b  File is a block special file.
#    -c  File is a character special file.
#    -t  Filehandle is opened to a tty.

#    -u  File has setuid bit set.
#    -g  File has setgid bit set.
#    -k  File has sticky bit set.

#    -T  File is a text file.
#    -B  File is a binary file (opposite of -T).

#    -M  Age of file in days when script started.
#    -A  Same for access time.
#    -C  Same for inode change time.

=item mkdir($path, $mode);

Should create a directory with $mode (defaults to 0755) and chown()'s the directory
with the uid and gid.  The return value is from mkdir().

=item unlink($path)

Should delete a file

=item rmdir($path)

Should delete the file or directory at $path if possible

=item list($path)

List the files under $path

=item open_read($path)

Returns a file handle which contains the data associated with $path

=item close_read($fh)

Closes a file handle that was opened with L<open_read>. 

=item open_write($path)

=item close_write($fh)
Perform a perl type test on a file and returns the results.

=item chmod($mode, $path)

Modifies the permissions of the filesystem.  Returns blank by default.

=back

=head1 METHODS

=cut

=head2 cwd

Gets or sets the current directory, assumes / if blank.
This is used in conjunction with the root_path for file operations.
No actual change directory takes place.

=cut

sub cwd {
  my $self = shift;
  
  if (@_) {
    
    $self->{cwd} = shift;    
  } else {
    $self->{cwd} = '/' if (!defined $self->{cwd} || $self->{cwd} eq '' );
  }
    
  return $self->{cwd};
}

=pod

=head2 root_path($path)

Get or set the root path.  All file paths are  off this and cwd
For example:

  $self->root_path('/home/ftp');
  $self->cwd('/test');
  $self->size('testfile.txt');

The size command would get the size for file /home/ftp/test/testfile.txt
not /test/testfile.txt

=cut

sub root_path {
  my ($self) = shift;

  if (@_) {
    my $root_path = shift;
      
    ### Does the root path end with a '/'?  If so, remove it.
    $root_path =~ s{/+$}{}; 
    $root_path = '/' unless length($root_path); # Did we nuke the entire string, fix it
    $self->{root_path}  = $root_path;
  }
    
  return $self->{root_path};
}

=pod

=head2 modtime($file)

Gets the modification time of a file in YYYYMMDDHHMMSS format.

=cut

sub modtime {
  my ($self, $fn) = @_;
  $fn = $self->_path_from_root($fn);
    
  my $mtime = ($self->stat($fn))[9];
    
  my ($sec, $min, $hr, $dd, $mm, $yy, $wd, $yd, $isdst) =
    localtime($mtime); $yy += 1900; $mm++;
    
  return (1,"$yy$mm$dd$hr$min$sec");
}

=pod

=head2 size($file)

Gets the size of a file in bytes.

=cut

sub size {
  my ($self, $fn) = @_;
  $fn = $self->_path_from_root($fn);
  my @stat = $self->stat($fn);
  return $stat[7];
}

=pod

=head2 delete($file)

Deletes a file, returns 1 or 0 on success or failure.

=cut

sub delete {
  my ($self, $fn) = @_;
  $fn = $self->_path_from_root($fn);

  return ($self->test('e',$fn) && !$self->test('d',$fn) && ($self->unlink($fn))) ? 1 : 0;
}

=pod

=head2 chdir($dir)

Changes the cwd to a new path from root_path.
Returns undef on failure or the new path on success.

=cut

sub chdir {
  my ($self, $dir) = @_;

  my $new_cwd = $self->_resolve_path($dir);
  my $full_path = $self->root_path().$new_cwd;

  return unless $self->test('e', $full_path) && $self->test('d', $full_path);
  
  $self->cwd($new_cwd);
}

=pod

=head2 list_details($dir)

Returns an array of the files in ls format.

=cut

sub list_details {
  my ($self, $dirfile) = @_;
  $dirfile = $self->_path_from_root($dirfile);
    
  my @ls;
    
  if( $self->test('e', $dirfile) ) {
    if(! $self->test('d', $dirfile ) ) {
      ### This isn't a directory, so derive its short name, and produce
      ### an ls line.
      my @parts = split(/\//, $dirfile);
      my $fn = pop @parts;
      push(@ls, $self->_ls_stat($dirfile, $fn));
    } else {
      
      my @files = $self->list($dirfile);
            
      ### Make sure the directory path ends in '/'
      if ($dirfile !~ m{/$}) {
        $dirfile .= '/';
      } #If it doesn't end in slash, make it.
            
      ### Process the files...
      foreach (sort @files) {
        push(@ls, $self->_ls_stat($dirfile.$_, $_));
      }
    }
  }
    
  return @ls;
}

=pod

=head2 test($test,$file)


=head2 close_read($fh)

Performs a $fh->close()

=cut

sub close_read {
  my ($self, $fh) = @_;

  return $fh->close();
}

=head2 close_write($fh)

Performs a $fh->close()

=cut

sub close_write {
  my ($self, $fh) = @_;

  $fh->close();
    
  return 1;
}

=head2 seek($fh, $pos, $wence)

Performs a $fh->seek($pos, $wence). See L<IO::Seekable>.

=cut

sub seek {
  my ($self, $fh, $first, $second) = @_;

  return $fh->seek($first, $second);
}

sub chmod {
  # noop
}

=pod

=head2 utime($atime, $mtime, @files)

Performs a utime() on the file(s).  It changes the access time and mod time of
those files.

=cut

sub utime {
  my ($self, $atime, $mtime, @fn) = @_;
}


### Internal methods

# Restrict the path to beneath root path

sub _path_from_root {
  my ($self, $path) = @_;

  my $rooted_path = $self->root_path().$self->_resolve_path($path);
  return $rooted_path;
}

# Resolve a path from the current path

sub _resolve_path {
  my $self = shift;
  my $path = shift || '';

  my $cwd = $self->cwd();
  my $path_out = '';

  if ($path eq '') {
    $path_out = $cwd;
  } elsif ($path eq '/') {
    $path_out = '/';
  } else {
    my @real_ele = split(/\//, $cwd);
    if ($path =~ m/^\//) {
      undef @real_ele;
    }
    foreach (split(/\//, $path)) {
      if ($_ eq '..') {
        pop(@real_ele) if ($#real_ele);
      } elsif ($_ eq '.') {
        next;
      } elsif ($_ eq '~') {
        @real_ele = split(/\//, $self->home_path());
      } else {
        push(@real_ele, $_);
      }
    }
    $path_out = join('/', @real_ele);
  }
  
  $path_out =~ s{^/*}{/};
  $path_out =~ s{//}{/};

  return $path_out;
}


# Given a file's full path and name, produce a full ls line
sub _ls_stat {
  my ($self, $full_fn, $fn) = @_;
  # Determine the current year, for time comparisons
  my $curr_year = (localtime())[5]+1900;

  # Perform stat() on current file.
  my ($mode,$nlink,$uid,$gid,$size,$mtime) = ($self->stat($full_fn))[2 .. 5,7,9];
  #my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
  #   $atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat($full_fn);
  
  # Format the mod datestamp into the ls format
  my ($day, $mm, $dd, $time, $yr) = (localtime($mtime) =~ m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
  
  # Get a string of 0's and 1's for the binary file mode/type
  my $bin_str  = substr(unpack("B32", pack("N", $mode)), -16);
  
  # Produce a permissions map from the file mode
  my $mode_bin = substr($bin_str, -9);
  my $mode_str = '';

  my @modes = ("---------", "rwxrwxrwx");
  for (my $i=0; $i<9; $i++) {
    $mode_str .= substr($modes[substr($mode_bin, $i, 1)], $i, 1);
  }
    
  # Determine what type of file this is from the file type
  my $type_bin = substr($bin_str, -16, 7);
  my $type_str = '-';
  $type_str = 'd' if ($type_bin =~ m/^01/);
  
  # Assemble and return the line
  return sprintf("%1s%9s %4s %-8s %-8s %8s %3s %2s %5s %s",
     $type_str, $mode_str, $nlink,
     $self->user($uid), $self->group($gid), $size, $mm, $dd,
     ($curr_year eq $yr) ? substr($time,0,5) : $yr, $fn);
}


"Remember, Tuesday is Soylent Green day";

__END__

=head1 TODO

Lots.  This really shouldn't be used yet until coverage is strengthened.
Next up, we should provide higher level abstractions for certain kinds
of file operations, such as C<copy> and C<move>.  Additionally,
there seems to be a bit of boiler plate required at the beginning of
each method implementation, so abstracting the calls a bit more should be
done in the near future.

=head1 AUTHOR

Norman Nunley E<lt>nnunley@cpan.orgE<gt>, based on the work of David Davis, E<lt>xantus@cpan.orgE<gt>, http://teknikill.net/

=head1 SEE ALSO

perl(1), L<Filesys::Virtual>, L<Filesys::Virtual::Plain>,
L<POE::Component::Server::FTP>,
L<Net::DAV::Server>, L<HTTP::Daemon>,
http://perladvent.org/2004/20th/

=cut
