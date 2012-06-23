#!/usr/bin/env perl

use strict;
use warnings;

use CGI qw/:standard/;

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib (dirname abs_path $0) . '/';
use PlayerbasePredictor qw(getdb getdow_order getdow_today);

print header;

my $data="['Hour','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'],\n";

my $db=&getdb;
my $dow_order=&getdow_order;
my $dow_today=&getdow_today;

my %a=%$dow_order;
my %b=%$db;

#print pop @{$a{1}};

foreach my $hour (sort keys %{$db}){

	my $hhour=$hour;
	$hhour=~ s/^0//;

	$data=$data."['$hhour',";
	foreach my $dow (1..7){
		if($dow == 7){
			$data=$data."$b{$hour}{$dow}";
		}else{
			$data=$data."$b{$hour}{$dow},";
		}
		#print "$dow,";
	}
	$data=$data."],\n";
}



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
          title: 'Allegiance Player Playing Patterns',
	  vAxis: {title: '# of players'},
	  hAxis: {title: 'Hour (UTC)',},
	}

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 1800px; height: 500px;"></div>
  </body>
</html>
HTML
