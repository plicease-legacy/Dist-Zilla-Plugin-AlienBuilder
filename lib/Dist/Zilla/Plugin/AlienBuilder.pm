package Dist::Zilla::Plugin::AlienBuilder;

use strict;
use warnings;

# ABSTRACT: use Alien::Builder with Dist::Zilla
# VERSION

=head1 SYNOPSIS

 ; meanwhile, within your dist.ini file:
 [MakeMaker]
 [AlienBuilder]
 name = foo
 ; TODO: retriever
 build_commands = %c --prefix=%s
 build_commands = make
 install_commands = make install

=head1 DESCRIPTION

This plugin makes the necessary changes to your C<Makefile.PL> to
make it work with L<Alien::Builder> (it uses L<Alien::Builder::MM>).
It ONLY works with L<ExtUtils::MakeMaker>, to create an L<Alien>
module that works with L<Module::Build>, see L<Dist::Zilla::Plugin::Alien>.

=head1 ATTRIBUTES

These attributes are passed directly into the L<Alien::Builder::MM> constructor:

=over 4

=item arch

=item autoconf_with_pic

=item build_commands

=item build_dir

=item dest_dir

=item extractor

=item ffi_name

=item install_commands

=item interpolator

=item isolate_dynamic

=item msys

=item name

=item provides_cflags

=item provides_libs

=item retriever

=item retriever_start

=item test_commands

=item version_check

=back

These attributes require a little more background:

=head2 ab_class

The builder class to use.  This is L<Alien::Builder::MM> by
default.  If you want to override some of the behavior then
you can create a subclass and specify it here.  Put the class
in your C<inc> directory, which will automatically get
included.

=head2 retriever_spec

The retriever specification is an array of hashes.  See
the L<Alien::Builder> documentation for details.  You can
specify elements in this array using the dot C<.> character:

 [AlienBuilder]
 retriever_spec.0.pattern = ^foo-(([0-9]+\.)*[0-9]+)$
 retriever_spec.1.pattern = ^foo-(([0-9]+\.)*[0-9]+)\.tar\.gz$

=cut

use Moose;
use List::Util qw( first );
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::AfterBuild';
with 'Dist::Zilla::Role::MetaProvider';
with 'Dist::Zilla::Role::TextTemplate';

has ab_class => ( is => 'ro', isa => 'Str', default => 'Alien::Builder::MM' );

has $_ => ( is => 'ro', isa => 'Bool' )
  for qw( arch autoconf_with_pic dest_dir isolate_dynamic msys );

has $_ => ( is => 'ro', isa => 'Str' )
  for qw( name build_dir extractor ffi_name interpolator provides_cflags provides_libs 
          retriever retriever_start version_check );

has $_ => ( is => 'ro', isa => 'ArrayRef[Str]' )
  for qw( build_commands install_commands test_commands );

has retriever_spec => ( is => 'ro', isa => 'ArrayRef' );

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  
  my %args = ref $_[0] ? %{$_[0]} : @_;
  $args{retriever_spec} ||= [];
  
  foreach my $key (keys %args)
  {
    if($key =~ /^retriever_spec\.([0-9]+)\.(.*?)$/)
    {
      my $value = delete $args{$key};
      $args{retriever_spec}->[$1]->{$2} = $value;
    }
  }
  
  $class->$orig(%args);
};

# TODO: bin_requires
# TODO: env
# TODO: helper
# TODO: inline_auto_include
# TODO: retriever_spec

around mvp_multivalue_args => sub {
  my($orig, $self) = @_;
  return ($self->$orig, qw( build_commands install_commands test_commands ));
};

sub after_build
{
  my($self) = @_;
  $self->log_fatal('Build.PL detected, this plugin only works with MakeMaker')
    if first { $_->name eq 'Build.PL' } @{ $self->zilla->files };
}

sub setup_installer
{
  my($self) = @_;
  
  my $file = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  $self->log_fatal('No Makefile.PL') unless $file;
  
  my $content = $file->content;
  
  $self->log_fatal('failed to find position in Makefile.PL...')
    unless $content =~ /my %FallbackPrereqs = \((?:\n[^;]+^)?\);$/mg;
    
  my $pos = pos($content);

  $content = $self->fill_in_string($self->template, {
    before => substr($content, 0, $pos),
    after  => substr($content, $pos),
    self   => \$self,
  }, {});
  
  $file->content($content);
}

sub builder_args
{
  my($self) = @_;

  my %args = (
    dist_name => $self->zilla->name,
    #retriever => [ "http://ftp.gnu.org/gnu/libmicrohttpd/" => { pattern => '^libmicrohttpd-.*\.tar\.gz$' } ],
  );
  
  foreach my $accessor (map { $_->name } __PACKAGE__->meta->get_all_attributes)
  {
    # TODO: can we get more meta on this?  What happens
    # if generic plugin attributes get added?
    next if $accessor =~ /^(logger|zilla|plugin_name|ab_class|delim)$/;
    my $value = $self->$accessor;
    next unless defined $value;
    $args{$accessor} = $value;
  }
  
  \%args;
}

sub metadata
{
  my($self) = @_;
  { dynamic_config => 1 };
}

sub _dump_as
{
  my($self, $ref, $name) = @_;
  require Data::Dumper;
  my $dumper = Data::Dumper->new([$ref], [$name]);
  $dumper->Sortkeys(1);
  $dumper->Indent(1);
  $dumper->Useqq(1);
  return $dumper->Dump;
}

my $template;
sub template
{
  $template = do { local $/; <DATA> } unless $template;
  $template;
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<Alien::Builder>

=item L<Alien::Builder::MM>

=item L<Dist::Zilla>

=item L<Dist::Zilla::Plugin::Alien>

=back

=cut

__DATA__
{{ $before }}

# begin inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}
{{ $self->ab_class ne 'Alien::Builder::MM' ? 'use lib "inc";' : '' }}
use {{ $self->ab_class }};
my {{ $self->_dump_as($self->builder_args, '*AlienBuilderArgs') }}
my $ab = {{ $self->ab_class }}->new(%AlienBuilderArgs);
%WriteMakefileArgs = $ab->mm_args(%WriteMakefileArgs);
my %AlienBuildRequires = %{ (do { my %h = $ab->mm_args; \%h })->{BUILD_REQUIRES} };
$FallbackPrereqs{$_} = $AlienBuildRequires{$_} for keys %AlienBuildRequires;
$ab->save;
# end   inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}

{{ $after }}

# begin inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}
sub MY::postamble {
  $ab->mm_postamble;
}
# end   inserted by {{ blessed $self }} {{ $self->VERSION || 'dev' }}

