#!/opt/local/bin/perl

use POSIX;
use URI;
use Moose::Role;
use Scrappy;
use Cwd;

my $sitemap = 'urllist.txt';
my $scraper = Scrappy->new;
my $ORIGINAL_DIR = getcwd() . '/backup';

$scraper->debug(1);

open( my $fh, '<', $sitemap ) or die "Can't open $sitemap";

print "Moving inside $ORIGINAL_DIR\n";
chdir( $ORIGINAL_DIR );

while( <$fh> ){
	chomp;
	getthis( $_ );
}
close($fh);

sub getthis {
	if( getcwd() eq $ORIGINAL_DIR ){
		# do nothing
	}else{
		# change to original dir
		chdir( $ORIGINAL_DIR );
	}
	my $url = $_[0];
	my $domain;
	my $spath = $_[0];
	if( $_[0] =~ /([^:]*:\/\/)?([^\/]+\.[^\/]+)/g) {
		$domain = $1.$2."/";
		$spath =~ s/$domain//;
	}	print POSIX::strftime("%m/%d/%Y %H:%M:%S", localtime) . " - Starting download of $url\n";
	print "$url - $domain - $spath \n";
	my @check_dirs = split(/\//, $spath );
	# remove last index
	delete $check_dirs[ scalar( @check_dirs ) - 1 ];
	print "@check_dirs \n";
	foreach( @check_dirs ){
		if( -d $_ ){
			# change to dir
			chdir( $_ );
		}else{
			# create dir
			# change to dir
			mkdir( $_ );
			chdir( $_ );
		}
	}
	if( page( $scraper, $url ) ){
		print POSIX::strftime("%m/%d/%Y %H:%M:%S", localtime) . " - Ended Download of $url\n";	
		return 1;
	}
	print POSIX::strftime("%m/%d/%Y %H:%M:%S", localtime) . " - Failed Download of $url\n";	
	return;
}
sub page {
	my ($self, @options) = @_;

	my $url = $options[0];
	
	die "Can't download a page without a proper URL" unless $url;
	
	$url = URI->new($url)->as_string;

	my $scraper = Scrappy->new;
	$scraper->debug(1);
	$scraper->logger->write('download.log');
	my $downloader = {
		'//link[@href]' => sub {
			my ($self, $item, $params) = @_;
			my $link =
				ref $item->{href} ? $item->{href}->as_string : $item->{href};
			if ($link) {
				if ($link =~ m{^$url} || $link !~ m/^http(s)?\:\/\//) {
				
					$link = URI->new_abs($link, $url)->as_string
						if $link !~ m/^http(s)?\:\/\//;
					
					$self->download($link);

					# assuming its a css stylesheet, lets see if we find
					# any images that need downloading
					# YES, ITS A HACK ... and a bad one, AHHHHHHHHHHHHHHH !!!!!!

					if ($self->get($link)->page_loaded) {
						if (   $self->worker->content_type =~ /css/
							|| $self->worker->response->filename
							=~ /\.css(\?.*)?$/)
						{
							if ($self->content) {
								$self->content->decode;
								my @urls = $self->content->as_string
									=~ /url\s{0,}?\([\'\"\s]{0,}?([^\)]+)?[\'\"\s]{0,}?\)/g;
	                            if (@urls) {
									# download any found urls (probably images)
									foreach my $url (@urls) {
										$url =~ s/^\s+//g;
										$url =~ s/\s+$//g;
										$url =~ s/[\'\"]//g;
										$url !~ m/^http(s)?\:\/\//
											? $self->download( URI->new_abs($url, $link) )
											: $self->download( $url );
									}
								}
							}
						}
					}
				}
			}
		},
		'//script[@src]' => sub {
			my ($self, $item, $params) = @_;
			my $script =
				ref $item->{src} ? $item->{src}->as_string : $item->{src};
			if ($script) {
				$script = URI->new_abs($script, $url)->as_string
					if $script !~ m/^http(s)?\:\/\//;
				$self->download( $script )
					if $script =~ m{^$url}
						|| $script !~ m/^http(s)?\:\/\//;
			}
		},
		'//img[@src]' => sub {
			my ($self, $item, $params) = @_;
			my $image =
				ref $item->{src} ? $item->{src}->as_string : $item->{src};
			if ($image) {
				$image = URI->new_abs($image, $url)->as_string
					if $image !~ m/^http(s)?\:\/\//;
				$self->download( $image )
					if $image =~ m{^$url}
						|| $image !~ m/^http(s)?\:\/\//;
			}
		},
	};
	$scraper->crawl(
		$url,
		'/'  => $downloader,
		'/*' => $downloader
	);
	if ($scraper->get($url)->page_loaded) {
		my $filename = $scraper->worker->response->filename || 'index.html';
		$scraper->store($filename);
		print "\n... successfully downloaded $filename and it's assets\n";
		return 1;
	}
	print "\n... downloading may have had some trouble, see download.log\n";
	return;
}