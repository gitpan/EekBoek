#!/usr/bin/perl
my $RCS_Id = '$Id: skel.pl,v 1.7 1998-02-06 11:41:12+01 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1998
# Last Modified By: Johan Vromans
# Last Modified On: Tue Mar 11 14:01:08 2008
# Update Count    : 150
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use locale;

# Package name.
my $my_package = 'EekBoek';
# Program name and version.
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_name = 'Afschrijvingen';
# Tack '*' if it is not checked in into RCS.
$my_version .= '*' if length('$Locker:  $ ') > 12;

################ Command line parameters ################

use Getopt::Long 2.13;
sub app_options();

my $eb;				# EekBoek boekingen
my $oy;

app_options();

################ The Process ################

$^L = "\n";

use Time::Local;

sub min { $_[0] < $_[1] ? $_[1] : $_[0] }

my @data = ();
my $ythis = 1900 + (localtime())[6];

while ( <DATA> ) {

    # Skip comments and empty lines.
    next if /^#/;
    next unless /\S/;

    # Split up.
    my ( $date, $amt, $rest, $n, @desc ) = split;

    # Check for account numbers.
    my ($bal, $res);
    ($bal, $res) = splice(@desc, 0, 2)
      if @desc > 2 && $desc[0] =~ /^\d+$/ && $desc[1] =~ /^\d+$/;

    my $desc = "@desc";
    my @aux = ($desc, $date, $amt, $rest, $n, $bal, $res);

    my ( $year, $month, $day ) = $date =~ /^(\d\d\d\d)-?(\d\d)-?(\d\d)/;

    # Beginwaarde.
    my $val = $amt;

    # Tijdstip van aanschaf.
    my $t1 = timelocal (0, 0, 0, $day, $month-1, $year);

    # Zolang er meer is dan de restwaarde.
    while ( $val > $rest ) {

	# Eind van het boekjaar.
	my $t2 = timelocal (0, 0, 0, 1, 0, $year+1);

	# Tijdspanne.
	my $d1 = $t2 - $t1;

	# Gedeelte in dit jaar.
	my $d2 = $t2 - timelocal (0, 0, 0, 1, 0, $year);

	# Afschrijving,
	my $decr = ($amt - $rest) / $n * $d1 / $d2;
	$decr = $val-$rest if $val -$decr < $rest;

	# Waardevermindering.
	$val -= $decr;

	# Sla op.
	push (@data, [$year, $decr, min($rest,$val), @aux]);

	# Naar volgend jaar.
	$year++;
	$t1 = $t2;
    }
}

my ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res);

if ( !defined($eb) || !$eb ) {
    my $this = "";

    if ( defined($oy) ) {
	foreach ( sort { $a->[0] <=> $b->[0] or $a->[3] cmp $b->[3] } @data ) {
	    ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res) = @$_;
	    if ( $this ne $year ) {
		$this = $year;
		$- = 0;
	    }
	    next if $oy && $year != $oy;
	    $date =~ /(\d\d\d\d)-?(\d\d)-?(\d\d)/ and $date = "$3-$2-$1";
	    write;
	}
    }
    else {
	foreach ( sort { $a->[3] cmp $b->[3] or $a->[0] <=> $b->[0] } @data ) {
	    ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res) = @$_;
	    if ( $this ne $desc ) {
		$this = $desc;
		$- = 0;
	    }
	    $date =~ /(\d\d\d\d)-?(\d\d)-?(\d\d)/ and $date = "$3-$2-$1";
	    write;
	}
    }
}

if ( !defined($eb) || $eb ) {
    my $fmt = "        std 31-12 %-34s %9.2f %4d";
    foreach ( sort {$a->[0] <=> $b->[0] or $a->[3] cmp $b->[3] } @data ) {
	my ($year, $a, $v, $desc, $bal, $res) = @$_;
	next unless defined($bal) && defined($res);
	$desc = "\"Afschrijving $desc\"";
	printf STDOUT ("# Afschrijving %4d %s, balanswaarde = %.2f -> %.2f\n".
		       "memoriaal 31-12 %s \\\n".
		       "$fmt \\\n".
		       "$fmt\n\n",
		       $year, $_->[3], $v+$a, $v,
		       $desc,
		       $desc, -$a, $bal,
		       $desc, $a, $res);
    }
}

################ Subroutines ################

sub app_ident;
sub app_usage($);

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'eb|eekboek!' => \$eb,
		     'oy|order-year:i' => \$oy,
		     'ident'	=> \$ident,
		     'help|?'	=> \$help,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident if $ident;
    $oy = 0 if defined($oy) && $oy <= 1900;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    --eb   --eekboek	only EekBoek bookings
    --noeb --noeekboek	no EekBoek bookings
    -help		this message
    -ident		show identification
EndOfUsage
    exit $exit if $exit != 0;
}

format STDOUT_TOP =
@>>>  @<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<  @>>>>>>>  @>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>
"Jaar", "Omchrijving", "Aanschaf", "Waarde", "N", "Rest", "Begin", "Afschr.", "Eind"
----  --------------------  ----------  --------  --  --------  --------  --------  --------
.
format STDOUT =
@>>>  @<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<  @>>>>>>>  @>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>
$year, $desc, $date, sprintf("%.2f",$amt), $n, sprintf("%.2f",$rest), sprintf("%.2f",$v+$af), sprintf("%.2f",$af), sprintf("%.2f",$v)
.

__END__
# Aanschaf	Bedrag	Restw  #jr	Bal   Res   Omschrijving
2007-02-12	1457.75     0   5       1111  6810  Computer V
2007-10-06	32197	 3500   5       1121  6820  Auto 53-XD-SR

