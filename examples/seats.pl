#!/usr/local/bin/perl

sub biggest {
    local($max, $mp);
    $mp = 0;
    
    for ( keys %pri ) {
	($max = $_) && ($mp = $pri{$_}) if $pri{$_} > $mp;
#	print "testing $_, $max, $mp, $pri{$_}\n";
    }
    return $max;
}

$| = 1;

while (<STDIN>) {
    ($state, $pop ) = split(" ",$_);

    $pri{$state} = $pop{$state} = $pop;
}

for ( keys(%pri) ) {
    $seats{$_} = 1;
    $pri{$_} = $pop{$_} * 1/sqrt(($seats{$_}+1)*$seats{$_});
    $tot ++;
}

while ( $tot < 436 ) {
    $b = &biggest();
    $seats{$b}++;
    $pri{$b} = $pop{$b} * 1/sqrt(($seats{$b}+1)*$seats{$b});
    $tot++;
#    print "Picked $b $pri{$b}\n";
}

for ( keys(%pri) ) {
    print "$_ $seats{$_} $pop{$_}\n";
}

    

