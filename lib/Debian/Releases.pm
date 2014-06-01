package Debian::Releases;
# ABSTRACT: Mapping and comparing Debian release codenames and versions

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

use Version::Compare;

=head1 NAME

Debian::Releases - Comparing debian releases

=head1 SYNOPSIS

    use Debian::Releases;

    if(Debian::Releases::version_compare('6.0','squeeze')) {
        print "This is squeeze\n";
    }

=head1 SUBROUTINES/METHODS

=cut

has 'release_data' => (
    'is'      => 'ro',
    'isa'     => 'HashRef',
    'lazy'    => 1,
    'builder' => '_init_release_data',
);

has 'releases' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Str]',
    'lazy'    => 1,
    'builder' => '_init_releases',
);

has 'codenames' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Str]',
    'lazy'    => 1,
    'builder' => '_init_codenames',
);

sub _init_release_data {
    my $self = shift;
    my $rels = {
        '1.1'       => {
          'codename'        => 'buzz',
          'release_date'    => 834969600,
          'support_until'   => 844128000,
          'point_releases'  => {},
        },
        '1.2'       => {
          'codename'        => 'rex',
          'release_date'    => 850348800,
          'support_until'   => 851990400,
          'point_releases'  => {},
        },
        '1.3'       => {
          'codename'        => 'bo',
          'release_date'    => 865468800,
          'support_until'   => 883526400,
          'point_releases'  => {},
        },
        '2.0'       => {
          'codename'        => 'hamm',
          'release_date'    => 869702400,
          'support_until'   => 915062400,
          'point_releases'  => {},
        },
        '2.1'       => {
          'codename'        => 'slink',
          'release_date'    => 920937600,
          'support_until'   => 978220800,
          'point_releases'  => {},
        },
        '2.2'       => {
          'codename'        => 'potato',
          'release_date'    => 966297600,
          'support_until'   => 1051747200,
          'point_releases'  => {},
        },
        '3.0'       => {
          'codename'        => 'woody',
          'release_date'    => 1029715200,
          'support_until'   => 1156982400,
          'point_releases'  => {},
        },
        '3.1'       => {
          'codename'        => 'sarge',
          'release_date'    => 1118016000,
          'support_until'   => 1209600000,
          'point_releases'  => {},
        },
        '4.0'       => {
          'codename'        => 'etch',
          'release_date'    => 1175990400,
          'support_until'   => 1266192000,
          'point_releases'  => {},
        },
        '5.0'       => {
          'codename'        => 'lenny',
          'release_date'    => 1234656000,
          'support_until'   => 1328486400,
          'point_releases'  => {},
        },
        '6.0'       => {
          'codename'        => 'squeeze',
          'release_date'    => 1296950400,
          'support_until'   => 1456617600,
          'point_releases'  => {},
        },
        '7.0'       => {
          'codename'        => 'wheezy',
          'release_date'    => 1367625600,
          'support_until'   => 0,
          'point_releases'  => {},
        },
        '8.0'       => {
          'codename'        => 'jessie',
          'release_date'    => 0,
          'support_until'   => 0,
          'point_releases'  => {},
        },
        '9999.9999' => {
          'codename'        => 'sid',
          'release_date'    => 0,
          'support_until'   => 0,
          'point_releases'  => {},
        },
    };
    return $rels;
}

sub _init_releases {
  my $self    = shift;
  my $reldata = $self->release_data();
  my $rels    = {};

  foreach my $version ( keys %{ $reldata } ) {
    $rels->{$version} = $reldata->{$version}->{'codename'};
  }

  return $rels;
}

sub _init_codenames {
    my $self  = shift;
    my $rels  = $self->releases();
    my $codes = {};
    foreach my $version ( keys %{$rels} ) {
        my $codename = $rels->{$version};
        $codes->{$codename} = $version;
    }
    return $codes;
}

=head2 version_compare

Compare two debian releases in numerical or codename form.

=cut

## no critic (ProhibitAmbiguousNames)
sub version_compare {
    my $self  = shift;
    my $left  = shift;
    my $right = shift;

    $left  =~ s/^\s+//;
    $left  =~ s/\s+$//;
    $right =~ s/^\s+//;
    $right =~ s/\s+$//;
    $left  =~ s/\s*Debian\s*//g;
    $right =~ s/\s*Debian\s*//g;

    if ( $left =~ m/^(\d+\.\d)/ ) {
        $left = $1;
    }
    elsif ( my $ver = $self->codenames()->{$left} ) {
        $left = $ver;
    }
    else {
        $left = '0.0';
    }
    if ( $right =~ m/^(\d+\.\d)/ ) {
        $right = $1;
    }
    elsif ( my $ver = $self->codenames()->{$right} ) {
        $right = $ver;
    }
    else {
        $right = '0.0';
    }

    return Version::Compare::version_compare( $left, $right );
}
## use critic

=head2 is_released

Return a true value (actually the version this was released as) if a given codename
is a valid Debian release which was already released.

=cut
sub is_released {
  my $self      = shift;
  my $codename  = shift;
  my $ver       = $self->codenames()->{$codename};

  # do we know anything about this release?
  return unless $ver;

  # do we know anything about the release date?
  return unless $self->release_data()->{$ver}->{'release_date'};

  if ( time() >= $self->release_data()->{$ver}->{'release_date'} ) {
    return $ver;
  } else {
    return;
  }
}

=head2 is_supported

Return a true value if a given codename is a valid Debian release
which is still supported (normal or LTS support yields true).

=cut
sub is_supported {
  my $self      = shift;
  my $codename  = shift;
  my $ver       = $self->is_released($codename);

  # do we know this release?
  return unless $ver;

  if ( !$self->release_data()->{$ver}->{'support_until'} || 
    time() <= $self->release_data()->{$ver}->{'support_until'}) {
    return 1;
  } else {
    return;
  }
}

no Moose;
__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Dominik Schulz, C<< <dominik.schulz at gauner.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debian-releases at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debian-Releases>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debian::Releases


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debian-Releases>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debian-Releases>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debian-Releases>

=item * Search CPAN

L<http://search.cpan.org/dist/Debian-Releases/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dominik Schulz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Debian::Releases
