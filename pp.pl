#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Date::Calc qw(Day_of_Week);

my $my_cnf = '/secret/my_cnf.cnf';

my $dbh = DBI->connect("DBI:mysql:"
                        . ";mysql_read_default_file=$my_cnf"
                        .';mysql_read_default_group=playerbase_predictor',
                        undef,
                        undef
                        ) or die "something went wrong ($DBI::errstr)";

my $sql ="SELECT * from currentplayers where date_sub(curdate(),interval 7 day) <= timestamp";
my $sth=$dbh->prepare($sql);
$sth->execute();

my %db;

while(my @line=$sth->fetchrow_array()){

	$line[1]=~/(\d+)-(\d+)-(\d+) (\d+):/;
	my @number_of_players=split(/ /,$line[2]);
	my $dow=Day_of_Week($1,$2,$3);

	$db{$4}{$dow}=@number_of_players;
}


foreach my $hour (sort keys %db){
	foreach my $dow (sort keys $db{$hour}){
		printf("%03d", $db{$hour}{$dow}); print " ";
	}
	print "\n";
}
