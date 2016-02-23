#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);

#use constant CUFFLINKS  => 'cufflinks-2.0.0.Linux_x86_64/cufflinks';
use constant CUFFLINKS  => '/cufflinks-2.2.1.Linux_x86_64/cufflinks';

# Define worflow options
my ($query_file, $query_dir, $annotation, $user_annotation);


GetOptions( "infile=s" => \$query_file,
	    "indir=s"  => \$query_dir,
	    "G=s"      => \$annotation,
            "M=s"      => \$user_annotation,
	    );

my (@queries,$success);
if ($query_dir) {
    while (<$query_dir/*>) {
	push @queries, $_;
    }
}
if ($query_file) {
    push @queries, $query_file;
}

@queries > 0 || die "I could not find any SAM/BAM input files.\n";


# Allow over-ride of system-level database path with user
# May not need to do this going forward...
if (defined($user_annotation)) {
    $annotation = $user_annotation;
}

# Grab any flags or options we don't recognize and pass them as plain text
# Need to filter out options that are handled by the GetOptions call
my @args_to_reject = qw(-xxxx);
my $CUFFLINKS_ARGS = join(" ", @ARGV);
foreach my $a (@args_to_reject) {
    if ($CUFFLINKS_ARGS =~ /$a/) {
	report("Mostarguments are legal for use with this script, but $a is not. Please omit it and submit again");
	exit 1;
    }
}

    my $app = CUFFLINKS;
    my $cmd = "$app $CUFFLINKS_ARGS -G $annotation ";

for my $query_file (@queries) {    
    chomp(my $basename = `basename $query_file`);
    $basename =~ s/\.\S+$//;
    my $cuffcommand = $cmd . $query_file;
    report("$cuffcommand");

    system("$cuffcommand");

    mkdir $basename;
    system("mv genes.fpkm_tracking isoforms.fpkm_tracking transcripts.gtf $basename");
    
    $success++ if -e "$basename/transcripts.gtf";
}

$success ? exit 0 : exit 1;

sub report {
    print STDERR "$_[0]\n";
}

