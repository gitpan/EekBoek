#! perl

# Userdefs.pm -- User definable stuff
# RCS Info        : $Id: Userdefs.pm,v 1.3 2008/02/07 13:46:14 jv Exp $
# Author          : Johan Vromans
# Created On      : Thu Feb  7 14:28:50 2008
# Last Modified By: Johan Vromans
# Last Modified On: Tue Dec 30 12:22:37 2008
# Update Count    : 4
# Status          : Unknown, Use with caution!

package EB::Shell::Userdefs;

use strict;
use warnings;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

use EB;

# Dit is een voorbeeld van een command-wrapper.

# Wanneer de opdracht "kasverkoop" wordt ingegeven, wordt de method
# pp_kasverkoop aangeroepen met de commandonaam en alle meegegeven
# argumenten. Deze method is dan verantwoordelijk voor het afleveren
# van een (mogelijke andere) opdrachtnaam en argumenten.

sub EB::Shell::pp_kasverkoop {
    my ($self, $cmd, @args) = @_;

    # Controleer argumenten. "--nr=.." is een intern doorgegeven
    # argument wanneer de vorm "kasverkoop:boekstuknummer" wordt
    # gebruikt.

    die("Foute opdracht: tenminste twee argumenten nodig: datum en bedrag\n")
      if ( @args < 2 || (@args < 3 && $args[0] =~ /^--?nr=(.+)/));

    # Nieuwe opdracht.
    $cmd = "kas";

    # Opbouwen nieuwe lijst argumenten.
    my @a;
    if ( $args[0] =~ /^--?nr=(.+)/ ) {
	push(@a, shift(@args));	# boekstuknummer
    }
    if ( $args[0] =~/^\d+-\d+(-\d+)?$/  ) {
	push(@a, shift(@args));	# datum
    }
    my $amt = shift(@args);
    my $desc = @args ? "@args" : "Diversen";
    push(@a, "Verkoop", "std", $desc, $amt.'@1', "8600");

    # Toon...
    warn("+ $cmd @a\n");

    # En afleveren.
    ($cmd, @a);
}

# En uiteraard, de hulpboodschap.

sub EB::Shell::help_kasverkoop {
    return <<EOD;
Eenvoudige manier om een kasverkoop te boeken.

  kasverkoop <datum> <bedrag> [ <omschrijving> ... ]

Bijvoorbeeld:

  kasverkoop 28-01 25,00

Dit wordt omgezet in de opdracht:

  kas 28-01 Verkopen std Diversen 20,00\@1 8600
EOD
}

# Package ends here.

1;
