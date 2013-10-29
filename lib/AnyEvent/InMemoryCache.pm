package AnyEvent::InMemoryCache;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent;
use Time::Duration::Parse;

sub new {
    my $class = shift;
    my %args = @_;
    if ( exists $args{expires_in} ) {
        $args{expires_in} = parse_duration($args{expires_in});
    } else {
        $args{expires_in} = -1;  # endless
    }
    $args{_datastore} = {};
    bless \%args, $class;
}

sub set {
    my ($self, $key, $val, $expires_in) = @_;
    if ( @_ < 4) {
        $expires_in = $self->{expires_in};
    } else {
        $expires_in = parse_duration($expires_in);
    }
    $self->{_datastore}{$key} = [
        $val,
        ($expires_in < 0 ? undef : AE::timer $expires_in, 0, sub{ delete $self->{_datastore}{$key} })
    ];
    $val;
}

sub get {
    my ($self, $key) = @_;
    ($self->{_datastore}{$key} || [])->[0];
}

sub exists {
    my ($self, $key) = @_;
    exists $self->{_datastore}{$key};
}

sub delete {
    my ($self, $key) = @_;
    (delete $self->{_datastore}{$key} || [])->[0];
}


# Tie-hash subroutines

*TIEHASH = \&new;
*FETCH   = \&get;
*STORE   = \&set;
*DELETE  = \&delete;
*EXISTS  = \&exists;

sub CLEAR {
    %{$_[0]->{_datastore}} = ();
};

sub FIRSTKEY {
    my $self = shift;
    keys %{$self->{_datastore}};  # rest iterator
    scalar each %{$self->{_datastore}};
}

sub NEXTKEY {
    scalar each %{$_[0]->{_datastore}};
}

sub SCALAR {
    scalar %{$_[0]->{_datastore}};
}


1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::InMemoryCache - It's new $module

=head1 SYNOPSIS

    use AnyEvent::InMemoryCache;

=head1 DESCRIPTION

AnyEvent::InMemoryCache is ...

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

