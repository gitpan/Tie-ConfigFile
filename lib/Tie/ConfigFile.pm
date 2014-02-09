#
# Copyright (C) 2014 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.18.2 or,
# at your option, any later version of Perl 5 you may have available.
#

package Tie::ConfigFile;

use strict;
use warnings;

use IO::File;
use Carp;

our $VERSION = '0.01';

sub __error {
    my($self, $err) = @_;

    croak $err if $self->{die_on_error};

    return
}

sub __init {
    my $self = shift;

    $self->{_fh} = IO::File->new(
        $self->{filename},
        ($self->{readonly} ? O_RDONLY : O_RDWR) |
        ($self->{create_file} ? O_CREAT : 0)
    ) or return __error($self, 'Unable to open file');

    # we utf-8, baby
    $self->{_fh}->binmode(':utf8');

    return 1;
}

sub __read {
    my $self = shift;

    # __init will be launched only if there is no filehandle in $self->{_fh},
    # if __init fails we return undef
    return unless defined($self->{_fh}) || $self->__init;

    my $s = $self->{separator};

    while (defined(my $line = $self->{_fh}->getline)) {
        chomp $line;

        my($r_key, $r_value) = split /\s*$s\s*/, $line, 2;

        $self->{_cache}->{$r_key} = $r_value;
    }

    return
}

sub __write {
    my $self = shift;

    # clear the file before we write to it.
    $self->{_fh}->truncate(0);
    $self->{_fh}->seek(0, 0);

    for (keys %{$self->{_cache}}) {
        $self->{_fh}->print($_ , $self->{separator},
                            $self->{_cache}->{$_}, "\n")
    }

    # Due to flushing, writes are reliable even if user forgets to untie hash.
    $self->{_fh}->flush;

    return;
}

sub TIEHASH {
    my($class, %args) = @_;

    my $self = {
        filename       => undef,
        die_on_error   => 1,
        readonly       => 1,
        create_file    => 0,
        empty_is_undef => 1,
        separator      => '=',
        %args
    };

    unless (defined $self->{filename}) {
        return __error($self, 'Filename is not specified!');
    }

    bless $self, $class;

    $self->__read;

    return $self;
}

sub FETCH {
    my($self, $key) = @_;

    my $val = $self->{_cache}->{$key};

    return if ($val eq '') && $self->{empty_is_undef};
    return $val;
}

sub STORE {
    my($self, $key, $value) = @_;

    if ($self->{readonly}) {
        return $self->__error('STORE is not allowed on read-only config file')
    }

    $self->{_cache}->{$key} = $value;

    $self->__write;

    return;
}

sub DELETE {
    my($self, $key) = @_;

    if ($self->{readonly}) {
        return $self->__error('DELETE is not allowed on read-only config file')
    }

    delete $self->{_cache}->{$key};

    $self->__write;

    return;
}

sub CLEAR {
    my $self = shift;

    %{$self->{_cache}} = ();
    $self->__write;

    return;
}

sub EXISTS {
    my($self, $key) = @_;

    # Empty keys have '' value, so if value is undefined, key doesn't exist.
    return defined $self->{_cache}->{$key};
}

sub FIRSTKEY {
    my $self = shift;

    return (each %{$self->{_cache}})
}

sub NEXTKEY {
    my $self = shift;

    return (each %{$self->{_cache}})
}

sub UNTIE {
    my($self, $count) = @_;

    carp "untie attempted while $count inner references still exist" if $count;

    return
}

sub DESTROY {
    my $self = shift;

    $self->{_fh}->close;

    return
}

'AKZ18/295-200P';

__END__

=head1 NAME

Tie::ConfigFile - Tie configuration file to a hash

=head1 SYNOPSIS

    use Tie::ConfigFile;

    my %hash;
    tie %hash, 'Tie::ConfigFile', filename => 'foobar.conf', readonly => 0;

    $hash{foo} = 'bar'; # will be written to foobar.conf

    untie %hash;

=head1 DESCRIPTION

This module allows you to tie configuration file to a hash. To understand what
"tie" means in this context, read L<perltie>. Comments in configuration files
are B<NOT> supported.

=head1 OPTIONS

=over 4

=item *

C<filename> (string, mandatory) - Path to a configuration file.

=item *

C<create_file> (boolean, default: C<0>) - Try to create configuration file if
it doesn't exist.

=item *

C<die_on_error> (boolean, default: C<1>) - Croak when error happens.

=item *

C<empty_is_undef> (boolean, default: C<1>) - If key does exist but there is no
value, return undef on retrieval.

=item *

C<readonly> (boolean, default: C<1>) - Disallow writing to the config file.

=item *

C<separator> (string, default: C<=>) - Key and value separator in config file.
If specified separator and separator used in config file are different, said
file will get corrupted on write.

=back

=head1 EXPORT

Nothing is exported.

=head1 CAVEATS

When more than one process uses configuration file in non-readonly mode, data
loss may happen.

=head1 SEE ALSO

=over 4

=item *

L<Tie::Cfg>

=item *

L<Tie::Config>

=back

=head1 FOSSIL REPOSITORY

DBD::IngresII Fossil repository is hosted at xenu.tk:

    http://code.xenu.tk/repos.cgi/tie-configfile

=head1 AUTHOR

    Tomasz Konojacki <me@xenu.tk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Tomasz Konojacki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
