package Test::PureASCII;

our $VERSION = '0.01';

use strict;
use warnings;

use Test::Builder;
use File::Spec;

my $test = Test::Builder->new;

our @TESTED;

sub import {
    my $self = shift;
    my $caller = caller;

    for my $func ( qw( file_is_pure_ascii all_perl_files_are_pure_ascii all_files_are_pure_ascii) ) {
        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $test->exported_to($caller);
    $test->plan(@_);
}

sub file_is_pure_ascii {
    my $file = shift;
    my $name = @_ ? shift : "Pure ASCII test for $file";

    push @TESTED, $file;
    # $test->diag("FILE: $file");

    my $fh;
    unless (open $fh, '<', $file) {
        $test->ok(0, $name);
        $test->diag("  unable to open '$file': $!");
        return 0;
    }
    # binmode $fh;
    my $failed = 0;
    while (<$fh>) {
        # $test->diag("line $.: $_");
        if (/([^\x00-\x7f]+)/) {
            my @chars = map sprintf("0x%02x", ord $_), split //, $1;
            my $chars = join(', ', @chars);
            my $s = @chars > 1 ? ' sequence' : '';
            my $ln = $.;
            $test->ok(0, $name) unless $failed;
            $test->diag("  non ASCII character$s $chars at line $ln in $file");
            $failed = 1;
        }
    }
    unless (close $fh) {
        $test->ok(0, $name) unless $failed;
        $test->diag("  unable to read from '$file': $!");
        return 0;
    }
    $failed ? 0 : $test->ok(1, $name);
}

sub all_perl_files_are_pure_ascii {
    my @files = all_perl_files(@_);

    $test->plan( tests => scalar @files );

    my $ok = 1;
    foreach my $file (@files) {
        file_is_pure_ascii($file) or undef $ok;
    }
    return $ok;
}

sub all_files_are_pure_ascii {
    my @files = all_files(@_);
   $test->plan( tests => scalar @files );

    my $ok = 1;
    foreach my $file (@files) {
        file_is_pure_ascii($file) or undef $ok;
    }
    return $ok;
}

sub all_perl_files {
    my @queue = @_ ? @_ : starting_points();
    my @perl = ();

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my $dh, $file or next;
            my @newfiles = readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" and $_ ne ".svn" and !/~$/ } @newfiles;

            foreach my $newfile (@newfiles) {
                my $filename = File::Spec->catfile( $file, $newfile );
                if ( -f $filename ) {
                    push @queue, $filename;
                }
                else {
                    push @queue, File::Spec->catdir( $file, $newfile );
                }
            }
        }
        if ( -f $file ) {
            push @perl, $file if is_perl( $file );
        }
    }
    return @perl;
}

sub all_files {
    my @queue = @_ ? @_ : '.';
    my @all = ();

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my $dh, $file or next;
            my @newfiles = readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" and $_ ne ".svn" and !/~$/ } @newfiles;

            foreach my $newfile (@newfiles) {
                my $filename = File::Spec->catfile( $file, $newfile );
                if ( -f $filename ) {
                    push @queue, $filename;
                }
                else {
                    push @queue, File::Spec->catdir( $file, $newfile );
                }
            }
        }
        push @all, $file if -f $file
    }
    return @all;
}

sub starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

sub is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/;
    return 1 if $file =~ /\.p(l|m|od)$/;
    return 1 if $file =~ /\.t$/;

    open my $fh, $file or return;
    my $first = <$fh>;
    close $fh;

    return 1 if defined $first && ($first =~ /^#!.*perl/);

    return;
}


1;

__END__

=head1 NAME

Test::PureASCII - Test that only ASCII characteres are used on your code

=head1 SYNOPSIS

  use Test::PureASCII;
  all_perl_files_are_pure_ascii();

or

  use Test::PureASCII tests => $how_many;
  file_is_pure_ascii($filename1, "only ASCII in $filaname1");
  file_is_pure_ascii($filename2, "only ASCII in $filaname2");
  file_is_pure_ascii($filename3, "only ASCII in $filaname3");
  ...

The usual pure-ASCII test looks like:

  use Test::More;
  eval "use Test::PureASCII";
  plan skip_all => "Test::PureASCII required" if $@;
  all_perl_files_are_pure_ascii();

=head1 DESCRIPTION

This module allows to create tests to ensure that only 7-bit ASCII
characters are used on Perl source files.

=head2 EXPORT

The following functions are exported by this module:

=over 4

=item file_is_pure_ascii($filename [, $test_name])

checks that C<$filename> contains only ASCII characters.

The optional argument C<$test_name> will be included on the output
when reporting errors.

=item all_perl_files_are_pure_ascii( [@dirs] )

find all the Perl source files contained in directories C<@dirs>
recursively and check that they only contain ASCII characters.

C<blib> is used as the default directory if none is given.



=item all_files_are_pure_ascii( [@dirs] )

find all the files (Perl and non-Perl) contained in directories
C<@dirs> recursively and check that they only contain ASCII
characters.

The current directory is used as the default directory if none is
given.

=back


=head1 SEE ALSO

A nice table containing Unicode and Latin1 codes for common (at least
in Europe) non-ASCII characters is available from
L<http://www.alanwood.net/demos/ansi.html>.

=head1 AUTHOR

Salvador FaE<ntilde>dino, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Qindel Formacion y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

This module contains code copied from L<Test::Pod> Copyright (C) 2006
by Andy Lester.


=cut
