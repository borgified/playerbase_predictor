#!/usr/bin/env perl

use strict;
use warnings;

use CGI qw/:standard/;

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib (dirname abs_path $0) . '/';
use PlayerbasePredictor qw(getdb getdow_order getdow_today);

my $data="['Hour','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday','Average'],\n";

my $db=&getdb;
my $dow_order=&getdow_order;
my $dow_today=&getdow_today;

my %a=%$dow_order;
my %b=%$db;

#print pop @{$a{1}};

foreach my $hour (sort keys %{$db}){

	my $hhour=$hour;
	$hhour=~ s/^0//;

	$data=$data."[$hhour,";
	my $avg;
	foreach my $dow (1..7){
		if($dow == 7){
			$data=$data."$b{$hour}{$dow}";
		}else{
			$data=$data."$b{$hour}{$dow},";
		}
		#print "$dow,";
		$avg=$avg+$b{$hour}{$dow};
	}
	$data=$data.",$avg/7],\n";
}


print header;

print <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>
      Google Visualization API Sample
    </title>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load('visualization', '1', {packages: ['corechart']});
    </script>
    <script type="text/javascript">
      function drawVisualization() {
        // Some raw data (not necessarily accurate)
        var data = google.visualization.arrayToDataTable([
$data
        ]);

        var options = {
          title : 'Allegiance Player Playing Pattern',
          vAxis: {title: "# of Players"},
          hAxis: {title: "Hour (UTC)"},
          seriesType: "bars",
	  series: {7: {type: "line"}}
        };

        var chart = new google.visualization.ComboChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
      google.setOnLoadCallback(drawVisualization);
    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 1800px; height: 500px;"></div>
  </body>
</html>
HTML
