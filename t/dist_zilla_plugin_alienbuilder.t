use strict;
use warnings;
use Test::More;
use Test::DZil;
use File::Temp qw( tempdir );
use Path::Class qw( file dir );
use Capture::Tiny qw( capture_merged );
use File::chdir;
use List::Util qw( first );

subtest basic => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Alien-Foo' }, { add_files => {
    'source/dist.ini' => simple_ini({ name => 'Alien-Foo' },
      [ 'GatherDir' => {} ],
      [ 'MakeMaker' => {} ],
      [ 'AlienBuilder' => {} ],
    ),
  }});

  $tzil->build;
  
  my $plugin = first { $_->isa('Dist::Zilla::Plugin::AlienBuilder') } @{ $tzil->plugins };
  
  ok $plugin, 'plugin exists';
  is_deeply $plugin->builder_args, { dist_name => 'Alien-Foo' }, 'builder_args' if $plugin;

  compile_ok($tzil, 'Makefile.PL');
};

subtest 'with arguments' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Alien-Foo' }, { add_files => {
    'source/dist.ini' => simple_ini({ name => 'Alien-Foo' },
      [ 'GatherDir' => {} ],
      [ 'MakeMaker' => {} ],
      [ 'AlienBuilder' => {
        arch              => 1,
        autoconf_with_pic => 1,
        dest_dir          => 1,
        isolate_dynamic   => 1,
        msys              => 1,
        name              => 'libfoo',
        build_dir         => '_alien2',
        extractor         => 'My::Extractor',
        ffi_name          => 'foo',
        interpolator      => 'My::Interpolator',
        provides_cflags   => '-I/opt/foo/include',
        provides_libs     => '-L/opt/foo/lib -lfoo',
        version_check     => '/bin/false',
        build_commands    => [ 'foo', 'bar' ],
        test_commands     => [ 'baz', 'blorph' ],
        install_commands  => [ 'foo', 'baz' ],
        retreiver         => 'My::Retreiver',
        retreiver_start   => 'http://foo.com',
      } ],
    ),
  }});

  $tzil->build;
  
  my $plugin = first { $_->isa('Dist::Zilla::Plugin::AlienBuilder') } @{ $tzil->plugins };
  
  ok $plugin, 'plugin exists';
  is_deeply $plugin->builder_args, {
    dist_name => 'Alien-Foo',
        arch              => 1,
        autoconf_with_pic => 1,
        dest_dir          => 1,
        isolate_dynamic   => 1,
        msys              => 1,
        name              => 'libfoo',
        build_dir         => '_alien2',
        extractor         => 'My::Extractor',
        ffi_name          => 'foo',
        interpolator      => 'My::Interpolator',
        provides_cflags   => '-I/opt/foo/include',
        provides_libs     => '-L/opt/foo/lib -lfoo',
        version_check     => '/bin/false',
        build_commands    => [ 'foo', 'bar' ],
        test_commands     => [ 'baz', 'blorph' ],
        install_commands  => [ 'foo', 'baz' ],
        retreiver         => 'My::Retreiver',
        retreiver_start   => 'http://foo.com',
  }, 'builder_args' if $plugin;

  compile_ok($tzil, 'Makefile.PL');
};

subtest 'custom class' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Alien-Foo' }, { add_files => {
    'source/dist.ini' => simple_ini({ name => 'Alien-Foo' },
      [ 'GatherDir' => {} ],
      [ 'MakeMaker' => {} ],
      [ 'AlienBuilder' => { ab_class => 'My::AlienBuilder' } ],
    ),
    'source/inc/My/AlienBuilder.pm' => q{
      package My::AlienBuilder;
      use strict;
      use warnings;
      use base qw( Alien::Builder::MM );
      1;
    },
  }});

  $tzil->build;
  
  my $plugin = first { $_->isa('Dist::Zilla::Plugin::AlienBuilder') } @{ $tzil->plugins };
  
  ok $plugin, 'plugin exists';
  is_deeply $plugin->builder_args, { dist_name => 'Alien-Foo' }, 'builder_args' if $plugin;

  compile_ok($tzil, 'Makefile.PL');
};

done_testing;

sub compile_ok
{
  my($tzil, @files) = @_;

  my $root = tempdir( CLEANUP => 1 );

  foreach my $file (@{ $tzil->files })
  {
    my $disk_file = file( $root, $file->name );
    $disk_file->parent->mkpath(0,0700);
    $disk_file->spew($file->content);
  }

  local $CWD = $root;

  foreach my $filename (@files)
  {
    ok -f $filename, "$filename exists";
    my($out, $exit) = capture_merged { system $^X, -c => $filename; $? };
    is $exit, 0, "$filename compiles";
    if($exit)
    {
      diag $out;
      diag "[Makefile.PL]";
      my $num = 1;
      foreach my $line (split /\n/, scalar file($filename)->slurp)
      {
        diag "@{[ $num++ ]}:$line";
      }
    }
  }
}
