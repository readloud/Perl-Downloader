# ABSTRACT: Scrappy HTTP Request Flow-Control System
# Dist::Zilla: +PodWeaver

package Scrappy::Queue;

BEGIN {
    $Scrappy::Queue::VERSION = '0.94112090';
}

# load OO System
use Moose;

# load other libraries
use Array::Unique;
use URI;

# queue and cursor variables for navigation
our @_queue = ();
tie @_queue, 'Array::Unique';
our $_cursor = -1;


sub list {
    return @_queue;
}


sub add {
    my $self = shift;
    my @urls = @_;

    # validate and formulate proper URLs
    for (my $i = 0; $i < @urls; $i++) {
        my $u = URI->new($urls[$i]);

        if ('URI::' =~ ref $u) {
            $urls[$i] = $u->as_string;
        }
        else {
            unless ($urls[$i] =~ /\w{2,}\.\w{2,}/) {
                delete $urls[$i];
            }
        }
    }

    push @_queue, @urls;
    return $self;
}


sub clear {
    my $self = shift;

    @_queue  = ();
    $_cursor = -1;

    return $self;
}


sub reset {
    my $self = shift;

    $_cursor = -1;

    return $self;
}


sub current {
    my $self = shift;

    return $_queue[$_cursor];
}


sub next {
    my $self = shift;

    return $_queue[++$_cursor];
}


sub previous {
    my $self = shift;

    return $_queue[--$_cursor];
}


sub first {
    my $self = shift;
    $_cursor = 0;

    return $_queue[$_cursor];
}


sub last {
    my $self = shift;
    $_cursor = scalar(@_queue) - 1;

    return $_queue[$_cursor];
}


sub index {
    my $self = shift;
    $_cursor = shift || 0;

    return $_queue[$_cursor];
}


sub cursor {
    return $_cursor;
}

1;

__END__

=pod

=head1 NAME

Scrappy::Queue - Scrappy HTTP Request Flow-Control System

=head1 VERSION

version 0.94112090

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Scrappy::Queue;

    my  $queue = Scrappy::Queue->new;
    
        $queue->add($url);
        
        while (my $url = $queue->next) {
            ... $queue->add(...);
        }

=head1 DESCRIPTION

Scrappy::Queue provides a system for saving URLs to a recordset/queue and iterating
of them using the L<Scrappy> framework.

=head1 METHODS

=head2 list

The list method return the list of URLs in the queue. This is returned in list
context.

    my  $queue = Scrappy::Queue->new;
    
    ...
    
    my  @list = $queue->list;

=head2 add

The add method adds new URLs to the queue. Duplicate URLs will be ignored.

    my  $queue = Scrappy::Queue->new;
        $queue->add($url);

=head2 clear

The clear method completely empties the queue and resets the cursor (loop position).

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
    
        $queue->clear;

=head2 reset

The reset method resets the cursor (loop position).

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        while (my $url = $queue->next) {
            $queue->reset if ...; # beware the infinate loop
        }
        
        $queue->reset;

=head2 current

The current method returns the URL in the current loop position.

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        while (my $url = $queue->next) {
            last if ...;
        }
        
        print 'great' if $url eq $queue->current;

=head2 next

The next method moves the cursor to the next loop position and returns the URL.

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        while (my $url = $queue->next) {
            ...
        }

=head2 previous

The previous method moves the cursor to the previous loop position and returns the URL.

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        while (my $url = $queue->next) {
            ...
        }
        
        print $queue->previous;

=head2 first

The first method moves the cursor to the first loop position and returns the URL.

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        print $queue->first;

=head2 last

The last method moves the cursor to the last loop position and returns the URL.

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        print $queue->last;

=head2 index

The index method moves the cursor to the specified loop position and returns the
URL. The loop position is a standard array index position.

    my  $queue = Scrappy::Queue->new;
    
        $queue->add(...);
        $queue->add(...);
        $queue->add(...);
        
        print $queue->index(1);

=head2 cursor

The cursor method returns the current loop position.

    my  $queue = Scrappy::Queue->new;
        print $queue->cursor;

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

