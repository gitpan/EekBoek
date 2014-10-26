# Sqlite.pm -- EekBoek driver for SQLite database
# RCS Info        : $Id$
# Author          : Johan Vromans
# Created On      : Sat Oct  7 10:10:36 2006
# Last Modified By: Johan Vromans
# Last Modified On: Tue Oct 10 20:05:42 2006
# Update Count    : 123
# Status          : Unknown, Use with caution!

package main;

our $cfg;

package EB::DB::Sqlite;

use strict;
use warnings;
use EB;
use DBI;

my $dbh;			# singleton
my $dataset;

my $trace = $cfg->val(__PACKAGE__, "trace", 0);

# API: type  type of driver
sub type { "SQLite" }

sub _dbname {
    my ($dbname) = @_;

    $dbname =~ s;(^|.*[/\\])(ebsqlite_|eekboek_)?([^/\\]+)$;${1}ebsqlite_$3;;

    return $dbname;
}

sub _dsn {
    my $dsn = "dbi:SQLite:dbname=" . shift;
}

# API: create a new, empty database.
sub create {
    my ($self, $dbname) = @_;

    $dbname = _dbname($dbname);

    # Create (empty) db file.
    open(my $db, '>', $dbname);
    close($db);
    unlink("$db-journal")
      or warn("%".__x("Database journal voor {db} verwijderd",
		      db => $dbname)."\n");
}

# API: connect to an existing database.
sub connect {
    my ($self, $dbname) = @_;
    croak("?INTERNAL ERROR: connect db without dataset name") unless $dbname;

    if ( $dataset && $dbh && $dbname eq $dataset ) {
	return $dbh;
    }

    $self->disconnect;

    $dbname = _dbname($dbname);

    $cfg->newval(qw(database fullname), $dbname);
    unless ( -e $dbname ) {
	die("?".__x("Geen database met naam {name} gevonden",
		    name => $dbname)."\n");
    }
    $dbh = DBI::->connect(_dsn($dbname))
      or die("?".__x("Database verbindingsprobleem: {err}",
		     err => $DBI::errstr)."\n");
    $dataset = $dbname;

    # Create some missing functions.
    register_functions();

    return $dbh;
}

# API: Disconnect from a database.
sub disconnect {
    my ($self) = @_;
    return unless $dbh;
    $dbh->disconnect;
    undef $dbh;
    undef $dataset;
}

# API: Setup whatever is needed.
sub setup {
    # setup will be called after the connection to the database has
    # been established.

    # Create table for sequences.
    unless ( $dbh->selectrow_arrayref("SELECT name".
				      " FROM sqlite_master".
				      " WHERE name = 'eb_seq'".
				      " AND type = 'table'") ) {
	$dbh->do("CREATE TABLE eb_seq".
		 " (name TEXT PRIMARY KEY,".
		 "  value INT)");
    }

    # Clone Accounts table into TAccounts.
    unless ( $dbh->selectrow_arrayref("SELECT name".
				      " FROM sqlite_master".
				      " WHERE name like 'taccounts'".
				      " AND type = 'table'") ) {
	my $sql = $dbh->selectrow_arrayref("SELECT sql".
					   " FROM sqlite_master".
					   " WHERE name like 'accounts'".
					   " AND type = 'table'")->[0];
	$sql =~ s/TABLE Accounts/TABLE TAccounts/;
	$dbh->do($sql);
    }

    # Caller will commit.
}

# API: Get a array ref with table names (lowcased).
sub get_tables {
    my $self = shift;
    my @t;
    foreach ( $dbh->tables ) {
	# SQLite returns table names with quotes.
	# Our tables all start with an uppercase letter.
	next unless /^"([[:upper:]].+)"$/i;
	push(@t, lc($1));
    }
    \@t;
}

# API: List available data sources.
sub list { [] }

################ Sequences ################

# Currently non-atomic, restricting to single user mode.

sub _create_sequence {
    my ($sn, $value) = (@_, 1);

    $dbh->do("INSERT INTO eb_seq (name, value) VALUES (?, ?)",
	     {}, $sn, $value);

    $value;
}

sub _get_sequence {
    my ($seq) = @_;

    # Get the current (=next) value.
    my $rr = $dbh->selectrow_arrayref("SELECT value".
				      " FROM eb_seq".
				      " WHERE name = ?", {}, $seq);

    $rr ? $rr->[0] : undef;
}

sub _set_sequence {
    my ($seq, $value) = @_;

    $dbh->do("UPDATE eb_seq SET value = ? WHERE name = ?", {}, $value, $seq);

    return;
}

# API: Get the next value for a sequence, incrementing it.
sub get_sequence {
    my ($self, $seq) = @_;

    if ( my $v = _get_sequence($seq) ) {
	_set_sequence($seq, $v+1);
	return $v;
    }
    _create_sequence($seq, 2);
    1;
}

# API: Set the next value for a sequence.
sub set_sequence {
    my ($self, $seq, $value) = @_;

    _get_sequence($seq)
      ? _set_sequence($seq, $value)
      : _create_sequence($seq, $value);

    return;
}

################ Interactive SQL ################

# API: Interactive SQL.
sub isql {
    my ($self, @args) = @_;

    my $dbname = $cfg->val(qw(database fullname));
    my $cmd = "sqlite3";
    my @cmd = ( $cmd );

    push(@cmd, $dbname);

    if ( @args ) {
	push(@cmd, "@args");
    }

    my $res = system { $cmd } @cmd;
    # warn(sprintf("=> ret = %02x", $res)."\n") if $res;

}

################ PostgreSQL Compatibility ################

# API: feature  Can we?
sub feature {
    my ($self, $feat) = @_;
    $feat = lc($feat);

    # Known features:
    #
    # pgcopy	F PostgreSQL fast input copying
    # prepcache T Statement handles may be cached
    # filter    C SQL filter routine
    #
    # Unknown/unsupported features may be ignored.

    return \&sqlfilter if $feat eq "filter";

    return 1 if $feat eq "prepcache";

    # Return false for all others.
    return;
}

sub sqlfilter {
    local $_ = shift;
    my (@args) = @_;

    # No sequences.
    return if /^(?:create|drop)\s+sequence\b/i;

    # Constraints are ignored in table defs, but an
    # explicit alter needs to be skipped.
    return if /^alter\s+table\b.*\badd\s+constraint\b/i;

    # UNSOLVED: No insert into temp tables.
    return if /^select\s+\*\s+into\s+temp\b/i;

    # Fortunately, LIKE behaves mostly like ILIKE.
    s/\bilike\b/like/gi;

    return $_;
}

sub register_functions {

    $dbh->func("now", 0,
	       \&iso8601date,
	       "create_function");

    $dbh->func("sign", 1,
	       sub {
		   defined $_[0] ? $_[0] <=> 0 : 0
	       },
	       "create_function");
}

################ End PostgreSQL Compatibility ################

1;
