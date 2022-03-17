package Scrappy::Scraper::UserAgent;

BEGIN {
    $Scrappy::Scraper::UserAgent::VERSION = '0.94112090';
}

# load OO System
use Moose;

# load other libraries
use Carp;
use FindBin;
use File::ShareDir ':ALL';
use File::Slurp;

has 'name'    => (is => 'rw', isa => 'Str');
has 'options' => (is => 'rw', isa => 'HashRef');

sub random_user_agent {
    my $self = shift;
    my ($browser, $os) = @_;

    $browser = 'any' unless $browser;

    $browser = 'explorer'
      if lc($browser) eq 'internet explorer'
      || lc($browser) eq 'explorer'
      || lc($browser) eq 'ie';

    $browser = lc $browser;

    my @browsers = ('explorer', 'chrome', 'firefox', 'opera', 'safari');

    my @oss = ('Windows', 'Linux', 'Macintosh');

    if ($browser ne 'any') {
        croak("Can't load user-agents from unrecognized browser $browser")
          unless grep /^$browser$/, @browsers;
    }

    if ($os) {
        $os = ucfirst(lc($os));
        croak("Can't filter user-agents with an unrecognized Os $os")
          unless grep /^$os$/, @oss;
    }

    my @selection = ();
    $self->options({})
      unless defined $self->options;

    if ($browser eq 'any') {
        if ($self->options->{any}) {
            @selection = @{$self->options->{any}};
        }
        else {
            foreach my $file (@browsers) {
                my $u = dist_dir('Scrappy') . "/support/$file.txt";
                $u = "share/support/$file.txt" unless -e $u;
                push @selection, read_file($u);
            }
            $self->options->{'any'} = [@selection];
        }
    }
    else {
        if ($self->options->{$browser}) {
            @selection = @{$self->options->{$browser}};
        }
        else {
            my $u = dist_dir('Scrappy') . "/support/$browser.txt";
            $u = "share/support/$browser.txt" unless -e $u;
            push @selection, read_file($u);
            $self->options->{$browser} = [@selection];
        }
    }

    @selection = grep /$os/, @selection if $os;

    $self->name($selection[rand(@selection)] || '');
    return $self->name;
}

1;
