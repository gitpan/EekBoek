# $Id: basic.t,v 1.1 2005/09/30 08:16:22 jv Exp $  -*-perl-*-

use strict;
use Test::More qw(no_plan);

# Some basic tests.

BEGIN {
    use_ok("DBI");
    use_ok("DBD::Pg");
}

# Check minimal Pg interface version.
ok($DBD::Pg::VERSION >= 1.41,
   "DBD::PG version = $DBD::Pg::VERSION, should be at east 1.41");

# Check whether we can contact the database.
my @ds;
eval {
    @ds = DBI->data_sources("Pg");
    ok(!$DBI::errstr, "Connect -- Error:\n\t" . ($DBI::errstr||""));
};
ok(!$@, $@);
ok(@ds > 1, "Check databases");
