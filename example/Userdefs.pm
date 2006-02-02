#!/usr/bin/perl

package EB::Shell;

use strict;
use warnings;
use EB;

# Dit is een voorbeeld van een command-wrapper.

# Wanneer de opdracht "kasverkoop" wordt ingegeven, wordt de method
# pp_kasverkoop aangeroepen met de commandonaam en alle meegegeven
# argumenten. Deze method is dan verantwoordelijk voor het afleveren
# van een (mogelijke andere) opdrachtnaam en argumenten.

sub pp_kasverkoop {
    my ($self, $cmd, @args) = @_;
    _kas_iv($self, 0, $cmd, @args);
}
sub pp_kasinkoop {
    my ($self, $cmd, @args) = @_;
    _kas_iv($self, 1, $cmd, @args);
}

sub _kas_iv {
    my ($self, $iv, $cmd, @args) = @_;

    # Kontroleer argumenten. "--nr=.." is een intern doorgegeven
    # argument wanneer de vorm "kasverkoop:boekstuknummer" wordt
    # gebruikt.

    die("Foute opdracht: tenminste twee argumenten nodig: datum en bedrag\n")
      if ( @args < 2 || (@args < 3 && $args[0] =~ /^--?nr=(.+)/));

    # Nieuwe opdracht.
    $cmd = "kas";

    # Opbouwen niewe lijst argumenten.
    my @a;
    if ( $args[0] =~ /^--?nr=(.+)/ ) {
	push(@a, shift(@args));	# boekstuknummer
    }
    if ( $args[0] =~/^\d+-\d+(-\d+)?$/  ) {
	push(@a, shift(@args));	# datum
    }
    my $amt = shift(@args);
    my $desc = @args ? "@args" : "Diversen";
    if ( $iv ) {
	push(@a, "Inkoop", "std", $desc, $amt.'@0', "4799");
    }
    else {
	push(@a, "Verkoop", "std", $desc, $amt.'@1', "8600");
    }

    # Toon...
    warn("+ $cmd @a\n");

    # En afleveren.
    ($cmd, @a);
}

# En uiteraard, de help boodschappen.

sub help_kasverkoop {
    return <<EOD;
Eenvoudige manier om een kasverkoop te boeken.

  kasverkoop <datum> <bedrag> [ <omschrijving> ... ]

Bijvoorbeeld:

  kasverkoop 28-01 25,00

Dit wordt omgezet in de opdracht:

  kas 28-01 Verkopen std Diversen 20,00\@1 8600
EOD
}

sub help_kasinkoop {
    return <<EOD;
Eenvoudige manier om een kasinkoop te boeken.

  kasinkoop <datum> <bedrag> [ <omschrijving> ... ]

Bijvoorbeeld:

  kasinkoop 28-01 25,00

Dit wordt omgezet in de opdracht:

  kas 28-01 Inkopen std Diversen 20,00\@0 799
EOD
}

# Package ends here.

1;
