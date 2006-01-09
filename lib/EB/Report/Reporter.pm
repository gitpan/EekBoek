# Reporter.pm -- 
# RCS Info        : $Id: Reporter.pm,v 1.6 2006/01/08 21:20:57 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Dec 28 13:18:40 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jan  8 22:17:54 2006
# Update Count    : 128
# Status          : Unknown, Use with caution!
#!/usr/bin/perl -w

package EB::Report::Reporter;

use strict;
use warnings;
use EB;

sub new {
    my ($class, $style, $config) = @_;
    $class = ref($class) || $class;
    my $self = bless { _fields => [],
		       _fdata  => {},
		       _style  => $style,
		     }, $class;

    foreach my $col ( @$config ) {
	if ( $col->{name} ) {
	    my $a = { name  => $col->{name},
		      title => $col->{title} || ucfirst(lc(_T($a->{name}))),
		      width => $col->{width} || length($a->{title}),
		      align => $col->{align} || "<",
		      style => $col->{style} || $col->{name},
		    };
	    $self->{_fdata}->{$a->{name}} = $a;
	    push(@{$self->{_fields}}, $a);
	}
	else {
	    die("?"._T("Ontbrekend \"name\" of \"style\""));
	}
    }

    # Return object.
    $self;
}

sub fields {
    my ($self, @f) = @_;

    my @nf;			# new order of fields

    foreach my $fld ( @f ) {
	my $a = $self->{_fdata}->{$fld};
	die("?".__x("Onbekend veld: {fld}", fld => $fld)."\n")
	  unless defined($a);
	push(@nf, $a);
    }
    $self->{_fields} = \@nf;

    # PBP: Return nothing sensible.
    return;
}

sub widths {
    my ($self, $w) = @_;

    while ( my($fld,$width) = each(%$w) ) {
	die("?".__x("Onbekend veld: {fld}", fld => $fld)."\n")
	  unless defined($self->{_fdata}->{$fld});
	$self->{_fdata}->{$fld}->{width} = $w;
    }

    # PBP: Return nothing sensible.
    return;
}

sub start {
    my $self = shift;
    my ($t1, $t2, $t3l, $t3r) = @_;

    # Top title.
    if ( !$t1 ) {
	# This one really should be filled in with something distinguishing.
	$t1 = _T("Rapportage");
    }

    # Report date / period.
    if ( !$t2 ) {
	$t2 = "Periode: ****";
	if ( exists($self->{periodex}) ) {
	    if ( $self->{periodex} == 1 ) {
		$t2 = __x("Periode: t/m {to}",
			  to   => $self->{periode}->[1]);
	    }
	    else {
		$t2 = __x("Periode: {from} t/m {to}",
			  from => $self->{periode}->[0],
			  to   => $self->{periode}->[1]);
	    }
	}
    }

    # Administration name.
    if ( !$t3l ) {
	$t3l = $::dbh->adm("name");
    }

    # Creation date + program version
    if ( !$t3r ) {
	if ( $ENV{EB_SQL_NOW} ) {
	    # Fixed date. Strip program version. Makes it easier to compare reports.
	    $t3r = (split(' ', $EB::ident))[0] . ", " . $ENV{EB_SQL_NOW};
	}
	else {
	    # Use current date.
	    $t3r = $EB::ident . ", " . iso8601date();
	}
    }

    # Move to self.
    $self->{_title1}  = $t1;
    $self->{_title2}  = $t2;
    $self->{_title3l} = $t3l;
    $self->{_title3r} = $t3r;

    $self->{_needhdr} = 1;
    $self->{_needskip} = 0;
    $self->{fd} ||= *STDOUT;
}

sub finish {
    my ($self) = @_;
}

sub add {
    my ($self, $data) = @_;

    while ( my($k,$v) = each(%$data) ) {
	die("?",__x("Ongeldig veld: {fld}", fld => $k))
	  unless defined $self->{_fdata}->{$k};
    }

}

sub style { return }

sub _getstyle {
    my ($self, $row, $cell) = @_;
    return $self->style($row) unless $cell;

    my $a = $self->style("_any", $cell) || {};
    my $b = $self->style($row, $cell) || {};
    return { %$a, %$b };
}

sub _checkhdr {
    my ($self) = @_;
    return unless $self->{_needhdr};
    $self->{_needhdr} = 0;
    $self->header;
}

1;
