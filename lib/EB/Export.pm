# Export.pm -- Export EekBoek administratie
# RCS Info        : $Id: Export.pm,v 1.6 2006/02/02 11:36:07 jv Exp $
# Author          : Johan Vromans
# Created On      : Mon Jan 16 20:47:38 2006
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jan 31 21:22:07 2006
# Update Count    : 123
# Status          : Unknown, Use with caution!

package main;

our $dbh;

package EB::Export;

use strict;
use warnings;

use EB;
use EB::Finance;

my $ident;

sub export {
    my ($self, $opts) = @_;

    my $dir = $opts->{dir};
    if ( $dir ) {
	mkdir($dir, 0777) unless -d $dir;
	die("?".__x("Fout bij aanmaken directory {dir}: {err}",
		    dir => $dir, err => $!)."\n") unless -d $dir;
	die("?".__x("Geen toegang tot directory {dir}",
		    dir => $dir)."\n") unless -w $dir;

	$self->_write("$dir/schema.dat",  sub { $self->_schema(shift) });
	$self->_write("$dir/relaties.eb", sub { print { shift } $self->_relaties });
	$self->_write("$dir/opening.eb",  sub { print { shift } $self->_opening  });
	$self->_write("$dir/mutaties.eb", sub { print { shift } $self->_mutaties });

    }
    else {
	die("?"._T("Export naar bestand is nog niet ge�mplementeerd")."\n");
    }
}

sub _write {
    my ($self, $file, $producer) = @_;
    my $fh;
    open($fh, ">", $file)
      or die("?".__x("Fout bij aanmaken bestand {file}: {err}",
		     file => $file, err => $!)."\n");
    $producer->($fh)
      or die("?".__x("Fout bij schrijven bestand {file}: {err}",
		     file => $file, err => $!)."\n");
    close($fh)
      or die("?".__x("Fout bij afsluiten bestand {file}: {err}",
		     file => $file, err => $!)."\n");
}

sub _schema {
    my ($self, $fh) = @_;
    use EB::Tools::Schema;
    EB::Tools::Schema->dump_schema($fh);
}

sub _quote {
    my ($t) = @_;
    $t =~ s/(\\")/\\$1/g;
    '"'.$t.'"';
}

sub _relaties {
    my ($self) = @_;

    my $sth = $dbh->sql_exec("SELECT rel_code, rel_desc, rel_debcrd,".
			     " rel_btw_status, dbk_desc, rel_acc_id".
			     " FROM Relaties, Dagboeken".
			     " WHERE rel_ledger = dbk_id".
			     " ORDER BY rel_ledger, rel_btw_status");

    my $cur_dbk = "";
    my $cur_btw = -1;
    my $out = __x("# {what} voor administratie {adm}",
		  what => _T("Relaties"), adm => $dbh->adm("name")) . "\n" .
		    __x("# Aangemaakt door {id} op {date}",
			id => $EB::ident, date => iso8601date());

    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($code, $desc, $debcrd, $btw, $dbk, $acct) = @$rr;

	if ( $cur_btw != $btw || $cur_dbk ne $dbk ) {
	    $cur_btw = $btw;
	    $cur_dbk = $dbk;
	    $dbk =~ s/[^[:alnum]]/_/g;
	    $out .= "\n\n" if $out;
	    $out .= "relatie --dagboek=".lc($dbk);
	    $out .= " --btw=".lc(BTWTYPES->[$btw]) unless $btw == BTWTYPE_NORMAAL;
	}
	$out .= " \\\n        ";
	$out .= sprintf("%-10s %s %d", _quote($code), _quote($desc), $acct);
    }

    $out .= "\n\n# " . __x("Einde {what}", what => _T("Relaties")) . "\n";
}

sub _opening {
    my ($self) = @_;

    my $sth;

    my $out = __x("# {what} voor administratie {adm}",
		  what => _T("Openingsgegevens"), adm => $dbh->adm("name")) . "\n" .
		    __x("# Aangemaakt door {id} op {date}",
			id => $EB::ident, date => iso8601date() . "\n\n");

    $out .= "adm_naam         " . _quote($dbh->adm("name")) . "\n";

    my $begin = $dbh->do("SELECT min(bky_begin)".
			 " FROM Boekjaren".
			 " WHERE bky_begin > ( SELECT bky_end FROM Boekjaren WHERE bky_code = ? )",
			 BKY_PREVIOUS);
    $begin = $begin->[0];

    $out .= "adm_begindatum   " . substr($begin, 0, 4) . "\n";
    $out .= "adm_boekjaarcode " . _quote($dbh->lookup($begin, qw(Boekjaren bky_begin bky_code))) . "\n";
    $out .= "adm_btwperiode   " .
      (qw(geen jaar x x kwartaal x x x x x x x maand)[$dbh->adm("btwperiod")]).
	"\n";

    $out .= "\n# " . _T("Openingsbalans") . "\n";

    $sth = $dbh->sql_exec("SELECT acc_id, acc_desc, acc_ibalance, acc_debcrd".
			  " FROM Accounts".
			  " WHERE acc_balres".
			  " AND acc_ibalance <> 0".
			  " ORDER BY acc_debcrd DESC, acc_id");

    my ($dt, $ct) = (0, 0);
    my $debcrd;
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $acc_desc, $acc_balance, $acc_debcrd) = @$rr;
	next unless $acc_balance;

	if ( $acc_balance >= 0 ) {
	    $dt += $acc_balance;
	}
	else {
	    $ct -= $acc_balance;
	}
	$acc_balance = 0 - $acc_balance unless $acc_debcrd;
	if ( !defined($debcrd) || $acc_debcrd != $debcrd ) {
	    $out .= "\n# " . ($acc_debcrd ? _T("Debet") : _T("Credit")) . "\n";
	}
	$out .= sprintf("adm_balans %-5s %10s   # %s\n",
			$acc_id, numfmt($acc_balance),
			$acc_desc);
	$debcrd = $acc_debcrd;
    }

    die("?".__x("Internal error -- unbalance {arg1} <> {arg2}",
		arg1 => numfmt($dt),
		arg2 => numfmt($ct))."\n")
      unless $dt == $ct;
    $out .= "\n# " .  _T("Totaal") . "\n" . "adm_balanstotaal " . numfmt($dt) . "\n";

=begin wrong

    $sth = $dbh->sql_exec("SELECT dbk_desc, bsk_nr, bsr_rel_code, bsk_desc, bsk_amount, bsk_date, dbk_type".
			  " FROM Boekstukken, Dagboeken, Boekstukregels".
			  " WHERE dbk_id = bsk_dbk_id".
			  " AND bsr_bsk_id = bsk_id".
			  " AND bsr_nr = 1".
			  " AND bsk_bky IS NULL".
			  " ORDER BY dbk_id, bsk_nr, bsk_date");

    if ( $sth->rows ) {
	$out .= "\n# "._T("Openstaande posten")."\n\n";
    }

    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($dbk_desc, $bsk_nr, $bsr_rel_code, $bsk_desc, $bsk_amount, $bsk_date, $dbk_type) = @$rr;
	$dbk_desc = lc($dbk_desc);
	$dbk_desc =~ s/[^[:alnum:]]/_/g;
	$bsk_amount = 0-$bsk_amount if $dbk_type == DBKTYPE_INKOOP;
	$out .= join(" ",
		     "adm_relatie",
		     $dbk_desc . ":" . $bsk_nr,
		     $bsk_date, _quote($bsk_desc), _quote($bsr_rel_code),
		     numfmt($bsk_amount)). "\n";
    }

=cut

    $sth = $dbh->sql_exec("SELECT bsk_id".
			  " FROM Boekstukken".
			  " WHERE bsk_date <= ( SELECT bky_end FROM Boekjaren WHERE bky_code = ? )".
			  " ORDER BY bsk_dbk_id, bsk_nr, bsk_date",
			  BKY_PREVIOUS);

    if ( $sth->rows ) {
	$out .= "\n# "._T("Openstaande posten")."\n\n";
    }

    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($bsk_id) = @$rr;
	$out .= "adm_relatie " .
	  EB::Booking::Decode->decode
	      ($bsk_id,
	       { trail  => 1,
		 single => 0,
		 btw    => 0,
		 bsknr  => 1,
		 bky    => 1,
		 total  => 0,
		 noivbskdesc => 1,
		 debcrd => 0 }) . "\n";
    }

    $out .= "\n# "._T("Openen van de administratie")."\n\nadm_open\n";
    $out .= "\n# " . __x("Einde {what}", what => _T("Openingsgegevens")) . "\n";
    $out;
}

sub _mutaties {
    my ($self) = @_;

    my $out = __x("# {what} voor administratie {adm}",
		  what => _T("Boekingen"), adm => $dbh->adm("name")) . "\n" .
		    __x("# Aangemaakt door {id} op {date}",
			id => $EB::ident, date => iso8601date()) . "\n\n";

    my @bky;
    my $sth = $dbh->sql_exec("SELECT bky_code".
			     " FROM Boekjaren".
			     " WHERE bky_begin > ( SELECT bky_end FROM Boekjaren WHERE bky_code = ? )".
			     " ORDER BY bky_code",
			    BKY_PREVIOUS);
    while ( my $rr = $sth->fetchrow_arrayref ) {
	push(@bky, $rr->[0]);
    }

    my $check_je = sub {
	my ($bky) = @_;
	if ( $dbh->lookup($bky, qw(Boekjaren bky_code bky_closed)) ) {
	    $out .= "jaareinde --boekjaar=" . _quote($bky) . " --definitief\n";
	}
	else {
	    $sth = $dbh->sql_exec("SELECT COUNT(*)".
				  " FROM Boekjaarbalans".
				  " WHERE bkb_bky = ?", $bky);
	    my $rr;
	    if ( ($rr = $sth->fetchrow_arrayref) && $rr->[0] ) {
		$out .= "jaareinde --boekjaar=" . _quote($bky) . "\n";
	    }
	    $sth->finish;
	}
    };

    my $cur_bky = $bky[0];
    foreach my $bky ( @bky ) {
	next if $bky eq BKY_PREVIOUS;
	if ( $cur_bky ne $bky ) {
	    $check_je->($cur_bky);
	    $out .= "adm_boekjaarcode " . _quote($bky) . "\n";
	    $out .= "adm_open\n";
	    $cur_bky = $bky;
	}
	$out .= "boekjaar " . _quote($bky) . "\n";

	$sth = $dbh->sql_exec("SELECT bsk_id, dbk_id".
			      " FROM Boekstukken, Dagboeken".
			      " WHERE bsk_dbk_id = dbk_id".
			      " AND bsk_bky = ?".
			      " ORDER BY dbk_type, bsk_id", $bky);

	my $cur_dbk = "";
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($bsk_id, $dbk_id) = @$rr;
	    if ( $cur_dbk ne $dbk_id ) {
		$out .= "\n";
		$cur_dbk = $dbk_id;
	    }
	    $out .= EB::Booking::Decode->decode
	      ($bsk_id,
	       { trail  => 1,
		 d_boekjaar => $bky,
		 single => 0,
		 btw    => 0,
		 bsknr  => 1,
		 total  => 1,
		 debcrd => 0 }) . "\n";
	}
	$out .= "\n";
    }
    $check_je->($cur_bky);
    $out .= "# " . __x("Einde {what}", what => _T("Boekingen")) . "\n";
    $out;
}


1;