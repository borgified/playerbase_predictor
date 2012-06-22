#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Date::Calc qw(Day_of_Week Today);
use CGI qw/:standard/;
use POSIX;

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
my %db1;
my %values; #to prettify with html
my %save_date;

while(my @line=$sth->fetchrow_array()){

#	print "@line\n";
	$line[1]=~/(\d+)-(\d+)-(\d+) (\d+):/;
	my @number_of_players=split(/ /,$line[2]);
	my $dow=Day_of_Week($1,$2,$3);

	$db{$4}{$dow}=@number_of_players;
	$db1{$4}{$dow}{'callsigns'}="$line[2]";
	$values{@number_of_players}="";

	$save_date{$dow}="$1-$2-$3";

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

#foreach my $hour (sort keys %db){
#	foreach my $dow (@{$dow_order{$dow_today}}){
#		printf("%03d", $db{$hour}{$dow}); print " ";
#	}
#	print "\n";
#}

my @values = reverse sort {$a <=> $b} keys(%values);
my $num_values=@values;

my($high,$medium,$low);

if($num_values >= 9){
	$high="$values[0]|$values[1]|$values[2]";
	$medium="$values[3]|$values[4]|$values[5]";
	$low="$values[6]|$values[7]|$values[8]";
}elsif($num_values >= 3){
	$high=$values[0];
	$medium=$values[1];
	$low=$values[2];
}else{
#dont bother coloring
	$high="dont bother";
	$medium="dont bother";
	$low="dont bother";
}

my %human_readable_dow = (
	1 => 'Mon',
	2 => 'Tue',
	3 => 'Wed',
	4 => 'Thu',
	5 => 'Fri',
	6 => 'Sat',
	7 => 'Sun',
);

print header,start_html;

print "<h3>current servertime is: ", scalar localtime," ",strftime("%Z",localtime), "</h3>";

print "<table border=1><tr><th>hour</th>";
foreach my $dow (@{$dow_order{$dow_today}}){
	print "<th>$save_date{$dow} ($human_readable_dow{$dow})</th>";
}
print "</tr>\n";

#<a onmouseover="popup('Lorem ipsum dolor sit ...');" href='somewhere.html'>some text</a>

foreach my $hour (sort keys %db){
	print "<tr><td>$hour</td>";
	foreach my $dow (@{$dow_order{$dow_today}}){
		if($db{$hour}{$dow}=~/$high/){
			print "<td bgcolor=red><a href='' title=\"$db1{$hour}{$dow}{'callsigns'}\">$db{$hour}{$dow}</a></td>";
		}elsif($db{$hour}{$dow}=~/$medium/){
			print "<td bgcolor=orange><a href='' title=\"$db1{$hour}{$dow}{'callsigns'}\">$db{$hour}{$dow}</a></td>";
		}elsif($db{$hour}{$dow}=~/$low/){
			print "<td bgcolor=yellow><a href='' title=\"$db1{$hour}{$dow}{'callsigns'}\">$db{$hour}{$dow}</a></td>";
		}else{
			print "<td>$db{$hour}{$dow}</td>";
		}
	}
	print "</tr>\n";
}
print "</table>";

print end_html;
