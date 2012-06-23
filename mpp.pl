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

my $sql ="SELECT * from currentplayers where timestamp > date_sub(current_date, interval 30 day) AND timestamp < current_date";
my $sth=$dbh->prepare($sql);
$sth->execute();

my %db;
my $i=0;

while(my @line=$sth->fetchrow_array()){

	$line[1]=~/(\d+)-(\d+)-(\d+) (\d+):/;
	my @number_of_players=split(/ /,$line[2]);
	my $dow=Day_of_Week($1,$2,$3);

	$db{$4}{$dow}{"$1-$2-$3"}=@number_of_players;
}

my %results;
my $data="['Hour','Weekday Avg','Weekend Avg'],\n";
my $rawdata="";

foreach my $hour (sort keys %db){
	my $d=0;
	my $e=0;
	my $dacc=0;
	my $eacc=0;
	foreach my $dow (sort keys %{$db{$hour}}){
		foreach my $day (sort keys %{$db{$hour}{$dow}}){
			$rawdata=$rawdata."hour: $hour dow: $dow day: $day $db{$hour}{$dow}{$day}\n";
			if($dow < 6){
				$d++;
				$dacc=$dacc+$db{$hour}{$dow}{$day};
			}else{
				$e++;
				$eacc=$eacc+$db{$hour}{$dow}{$day};
			}
		}
	}
#	print "$hour weekday avg: ",$dacc/$d,"\n";
#	print "$hour weekend avg: ",$eacc/$e,"\n";
	my $a=$dacc/$d;
	my $b=$eacc/$e;
	$data=$data."[$hour,$a,$b],\n";
}


print header;
print <<HTML;
<html>
  <head>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
$data
        ]);

        var options = {
	  backgroundColor: {fill:'transparent'},
          title: 'Allegiance Player Playing Patterns (past 30 days)',
          vAxis: {title: '# of players', textPosition: 'none', },
          hAxis: {title: 'Hour (UTC)', gridlines: {color: '#333', count: 24}, },
        }

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 1100px; height: 500px;"></div>
<pre>
dow (monday = 1, tues = 2, etc)
$rawdata
</pre>
  </body>
</html>
HTML
