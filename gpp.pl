#!/usr/bin/env perl

use strict;
use warnings;

use CGI qw/:standard/;

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib (dirname abs_path $0) . '/';
use PlayerbasePredictor;

print header;

my $data="hello";











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
          title: 'Company Performance'
        };

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 900px; height: 500px;"></div>
  </body>
</html>
HTML
