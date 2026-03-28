#!/usr/bin/env perl
# forensic_telemetry.pl — Dig through 10 years of garbage data

use strict;
use File::Find;
use Time::Piece;

my %file_types;
my $total_size = 0;
my @parseable_files;

# Recursively find all telemetry files
find(sub {
    return unless -f;
    return unless /\.(csv|log|dat|bin)$/i;
    
    my $size = -s $_;
    my $mtime = localtime((stat($_))[9]);
    
    $file_types{$1}++;
    $total_size += $size;
    
    # Check if we can parse it
    if (quick_validate($_)) {
        push @parseable_files, {
            path => $File::Find::name,
            size => $size,
            date => $mtime,
        };
    }
}, $ARGV[0]);

print "📁 Telemetry Archive Analysis\n";
print "─────────────────────────────\n";
printf "Total files: %d\n", scalar keys %file_types;
printf "Total size: %.2f GB\n", $total_size / 1e9;
print "\nFile types:\n";
foreach (sort keys %file_types) {
    printf "  %s: %d files\n", $_, $file_types{$_};
}

print "\n✅ Parseable files: " . scalar(@parseable_files) . "\n";
print "💡 Recommendation: Convert to unified binary format\n";
print "⚡ Estimated processing time: " . 
      int($total_size / 1e6 / 100) . " seconds\n";

sub quick_validate {
    my ($file) = @_;
    open my $fh, '<', $file or return 0;
    my $first_line = <$fh>;
    close $fh;
    
    # Check for recognizable headers
    return 1 if $first_line =~ /time.*speed.*throttle/i;
    return 1 if $first_line =~ /^[0-9]+\.[0-9]+,/;
    return 0;
}
