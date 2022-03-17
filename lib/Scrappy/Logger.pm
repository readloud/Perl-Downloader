# ABSTRACT: Scrappy Scraper Event Logging
# Dist::Zilla: +PodWeaver

package Scrappy::Logger;

BEGIN {
    $Scrappy::Logger::VERSION = '0.94112090';
}

# load OO System
use Moose;

# load other libraries
use Carp;
use DateTime;
use DateTime::Format::SQLite;
use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

has 'auto_save' => (is => 'rw', isa => 'Bool', default => 1);
has file        => (is => 'rw', isa => 'Str');
has verbose     => (is => 'rw', isa => 'Int', default => 0);


sub load {
    my $self = shift;
    my $file = shift;

    if ($file) {

        $self->{file} = $file;

        # load event-log file
        $self->{stash} = LoadFile($file)
          or croak("Log file $file does not exist or is not read/writable");
    }

    return $self->{stash};
}


sub timestamp {
    my $self = shift;
    my $date = shift;

    if ($date) {

        # $date =~ s/\_/ /g;
        return DateTime::Format::SQLite->parse_datetime($date)
          ;    # datetime object
    }
    else {
        $date =
          DateTime::Format::SQLite->format_datetime(DateTime->now);    # string

        # $date =~ s/ /_/g;
        return $date;
    }
}


sub info {
    return shift->event('info', @_);
}


sub warn {
    return shift->event('warn', @_);
}


sub error {
    return shift->event('error', @_);
}


sub event {
    my $self = shift;
    my $type = shift;
    my $note = shift;

    croak("Can't record an event without an event-type and notation")
      unless $type && $note;

    $self->{stash} = {} unless defined $self->{stash};

    $self->{stash}->{$type} = [] unless defined $self->{stash}->{$type};

    my $frame = $type eq 'info' || $type eq 'error' || $type eq 'warn' ? 1 : 0;
    my @trace = caller($frame);
    my $entry = scalar @{$self->{stash}->{$type}};
    my $time  = $self->timestamp;
    my $data  = {};
    $data = {
        '// package'  => $trace[0],
        '// filename' => $trace[1],
        '// line'     => $trace[2],
        '// occurred' => $time,
        '// notation' => $note,
      }
      if $self->verbose;

    $self->{stash}->{$type}->[$entry] = {eventlog => "[$time] [$type] $note"}
      unless defined $self->{stash}->{$type}->[$entry];

    $self->{stash}->{$type}->[$entry]->{metadata} = $data
      if scalar keys %{$data};

    if (@_ && $self->verbose) {
        my $stash = @_ > 1 ? {@_} : $_[0];
        if ($stash) {
            if (ref $stash eq 'HASH') {
                for (keys %{$stash}) {
                    $self->{stash}->{$type}->[$entry]->{metadata}->{$_} =
                      $stash->{$_};
                }
            }
        }
    }

    $self->write;
    return $self->{stash}->{$type}->[$entry];
}


sub write {
    my $self = shift;
    my $file = shift || $self->{file};

    $self->{file} = $file;

    if ($file) {

        # write event-log file
        DumpFile($file, $self->{stash})
          or
          croak("event-log file $file does not exist or is not read/writable");
    }

    return $self->{stash};
}

1;

__END__

=pod

=head1 NAME

Scrappy::Logger - Scrappy Scraper Event Logging

=head1 VERSION

version 0.94112090

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Scrappy::Logger;

    my  $logger = Scrappy::Logger->new;
    
        -f 'scraper.log' ?
        $logger->load('scraper.log');
        $logger->write('scraper.log');
        
        $logger->stash('foo' => 'bar');
        $logger->stash('abc' => [('a'..'z')]);

=head1 DESCRIPTION

Scrappy::Logger provides YAML-Based event-log handling for recording events
encountered using the L<Scrappy> framework.

=head2 ATTRIBUTES

The following is a list of object attributes available with every Scrappy::Logger
instance.

=head3 auto_save

The auto_save attribute is a boolean that determines whether event data is
automatically saved to the log file on update.

    my  $logger = Scrappy::Logger->new;
        
        $logger->load('scraper.log');
        
        # turn auto-saving off
        $logger->auto_save(0);
        $logger->event('...', 'yada yada yada');
        $logger->write; # explicit write

=head3 file

The file attribute gets/sets the filename of the current event-log file.

    my  $logger = Scrappy::Logger->new;
        
        $logger->load('scraper.log');
        $logger->write('scraper.log.bak');
        $logger->file('scraper.log');

=head3 verbose

The verbose attribute is a boolean that instructs the logger to write very
detailed logs.

    my  $logger = Scrappy::Logger->new;
        $logger->verbose(1);

=head1 METHODS

=head2 load

The load method is used to read-in an event-log file, it returns its data in the
structure it was saved-in.

    my  $logger = Scrappy::Logger->new;
    my  $data = $logger->load('scraper.log');

=head2 timestamp

The timestamp method returns the current date/timestamp in string form. When
supplied a properly formatted date/timestamp this method returns a corresponding
L<DateTime> object.

    my  $logger = Scrappy::Logger->new;
    my  $date = $logger->timestamp;
    my  $dt = $logger->timestamp($date);

=head2 info

The info method is used to capture informational events and returns the event
data.

    my  $logger = Scrappy::Logger->new;
    my  %data = (foo => 'bar', baz => 'xyz');
    my  $event = $logger->info('This is an informational message', %data);
    
        $logger->info('This is an informational message');

=head2 warn

The warn method is used to capture warning events and returns the event
data.

    my  $logger = Scrappy::Logger->new;
    my  %data = (foo => 'bar', baz => 'xyz');
    my  $event = $logger->warn('This is a warning message', %data);
    
        $logger->info('This is an warning message');

=head2 error

The error method is used to capture error events and returns the event
data.

    my  $logger = Scrappy::Logger->new;
    my  %data = (foo => 'bar', baz => 'xyz');
    my  $event = $logger->error('This is a n error message', %data);
    
        $logger->info('This is an error message');

=head2 event

The event method is used to capture custom events and returns the event
data.

    my  $logger = Scrappy::Logger->new;
    my  %data = (foo => 'bar', baz => 'xyz');
    my  $event = $logger->event('myapp', 'This is a user-defined message', %data);
    
        $logger->event('myapp', 'This is a user-defined message');

=head2 write

The write method is used to write-out an event-log file.

    my  $logger = Scrappy::Logger->new;
    
        $logger->info('This is very cool', 'foo' => 'bar');
        $logger->warn('Somethin aint right here');
        $logger->error('It broke, I cant believe it broke');
    
        $logger->write('scraper.log');

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

