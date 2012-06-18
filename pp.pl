#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Date::Calc qw(Day_of_Week Today);

my $my_cnf = '/secret/my_cnf.cnf';

my $dbh = DBI->connect("DBI:mysql:"
                        . ";mysql_read_default_file=$my_cnf"
                        .';mysql_read_default_group=playerbase_predictor',
                        undef,
                        undef
                        ) or die "something went wrong ($DBI::errstr)";

my $sql ="SELECT * from currentplayers where timestamp > date_sub(current_date, interval 7 day) AND timestamp < current_date";
my $sth=$dbh->prepare($sql);
$sth->execute();

my %db;

while(my @line=$sth->fetchrow_array()){

	$line[1]=~/(\d+)-(\d+)-(\d+) (\d+):/;
	my @number_of_players=split(/ /,$line[2]);
	my $dow=Day_of_Week($1,$2,$3);

	$db{$4}{$dow}=@number_of_players;
}

my $dow_today = Day_of_Week(Today);

my %dow_order=(
	2 => [2,3,4,5,6,7,1],
	3 => [3,4,5,6,7,1,2],
	4 => [4,5,6,7,1,2,3],
	5 => [5,6,7,1,2,3,4],
	6 => [6,7,1,2,3,4,5],
	7 => [7,1,2,3,4,5,6],
	1 => [1,2,3,4,5,6,7],
);

foreach my $hour (sort keys %db){
	foreach my $dow (@{$dow_order{$dow_today}}){
		printf("%03d", $db{$hour}{$dow}); print " ";
	}
	print "\n";
}
