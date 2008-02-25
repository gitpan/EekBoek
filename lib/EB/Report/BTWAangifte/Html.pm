# Html.pm -- HTML backend for BTWAangifte
# RCS Info        : $Id: Html.pm,v 1.13 2008/02/15 22:00:25 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Sep 14 14:51:19 2005
# Last Modified By: Johan Vromans
# Last Modified On: Fri Feb 15 23:00:16 2008
# Update Count    : 37
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Report::BTWAangifte::Html;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.13 $ =~ /(\d+)/g;

use strict;
use EB;
use EB::Format qw(datefmt_full);

use base qw(EB::Report::GenBase);

sub new {
    my ($class, $opts) = @_;
    my $self = $class->SUPER::new($opts);
    $self;
}

sub outline {
    my ($self, $ctl, $tag0, $tag1, $sub, $amt) = @_;
    my $span = "";
    my $naps = "";
    if ( $ctl ) {
	if ( $ctl eq 'H1' ) {
	    $self->{fh}->print("<tr><td colspan=\"4\" class=\"heading\">", html($tag0), "</td></tr>\n");
	    return;
	}
	elsif ( $ctl eq 'H2' ) {
	    $self->{fh}->print("<tr><td colspan=\"4\" class=\"subheading\">", html($tag0), " ", html($tag1), "</td></tr>\n");
	    return;
	}
	elsif ( $ctl eq 'X' ) {
	    $span = "<span class=\"notice\">";
	    $naps = "</span>";
	    $tag0 = "\240";
	}
	else {
	    die("?".__x("Ongeldige mode '{ctl}' in {pkg}::addline",
			ctl => $ctl,
			pkg => __PACKAGE__ ) . "\n");
	}
    }

    $self->{fh}->print("<tr><td class=\"c_num\">",   $span, html($tag0), $naps,
		       "</td><td class=\"c_desc\">", $span, html($tag1), $naps,
		       "</td><td class=\"c_col1\">", $span, defined($sub) ? html($sub) : "&nbsp;", $naps,
		       "</td><td class=\"c_col2\">", $span, defined($amt) ? html($amt) : "&nbsp;", $naps,
		       "</td></tr>\n");
}

sub start {
    my ($self, $t1, $t2) = @_;
    my $reptype = "btwaangifte";
    my $adm;
    if ( $self->{boekjaar} ) {
	$adm = $dbh->lookup($self->{boekjaar},
			    qw(Boekjaren bky_code bky_name));
    }
    else {
	$adm = $dbh->adm("name");
    }

    $self->{fh}->print
      ("<html>\n",
       "<head>\n",
       "<title>", html($t1), "</title>\n");

    # This is copied from EB::Report::Reporter::Html.
    # MUST BE INTEGRATED (LATER).
    require EB::Report::Reporter::Html;
    if ( my $style = $self->{style} || $reptype ) {
	if ( $style =~ /\W/ ) {
	    print {$self->{fh}}
	      ('<link rel="stylesheet" href="', $style, '">', "\n");
	}
	elsif ( defined $self->{_cssdir} ) {
	    print {$self->{fh}}
	      ('<link rel="stylesheet" href="', $self->{_cssdir},
	       $style, '.css">', "\n");
	}
	elsif ( my $css = findlib("css/".$style.".css") ) {
	    print {$self->{fh}} ('<style type="text/css">', "\n");
	    EB::Report::Reporter::Html::copy_style($self->{fh}, $css);
	    print {$self->{fh}} ('</style>', "\n");
	}
	else {
	    print {$self->{fh}} ("<!-- ",
				 __x("Geen stylesheet voor {style}",
				     style => $style), " -->\n");
	}
    }

    print {$self->{fh}}
      ("</head>\n",
       "<body>\n",
       "<p class=\"title\">", html($t1), "</p>\n",
       "<p class=\"subtitle\">", html($adm), "</br>\n",
       html($t2), "</p>\n",
       "<table class=\"main\">\n");


}

sub finish {
    my ($self, $notice) = @_;
    $self->{fh}->print("</table>\n");

    $self->{fh}->print
      ("<p class=\"btwaangifte\"><span class=\"notice\">",
       html($notice), "</span></p>\n") if $notice;

    my $now = $cfg->val(qw(internal now), iso8601date());
    my $ident = $EB::ident;
    $ident = (split(' ', $ident))[0] if $cfg->val(qw(internal now), 0);

    $self->{fh}->print("<p class=\"footer\">",
		       __x("Overzicht aangemaakt op {date} door <a href=\"{url}\">{ident}</a>",
			   ident => $ident, date => datefmt_full($now), url => $EB::url), "</p>\n");

    $self->{fh}->print("</body>\n",
		       "</html>\n");

    close($self->{fh});
}

sub html {
    my ($t) = @_;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t =~ s/&/&amp;/g;
    $t =~ s/\240/&nbsp;/g;
    $t;
}

1;
