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
#my $rawdata="";

foreach my $hour (sort keys %db){
	my $d=0;
	my $e=0;
	my $dacc=0;
	my $eacc=0;
	foreach my $dow (sort keys %{$db{$hour}}){
		foreach my $day (sort keys %{$db{$hour}{$dow}}){
			#$rawdata=$rawdata."hour: $hour dow: $dow day: $day $db{$hour}{$dow}{$day}\n";
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
	my $a=sprintf("%.1f",$dacc/$d);
	my $b=sprintf("%.1f",$eacc/$e);
	$hour=~s/\b0//;
	$data=$data."[$hour,$a,$b],\n";
}


print header;
print <<HTML;
<html>
  <head>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>

<!-- BT - Added to support user's local timezone.
            http://www.pageloom.com/automatic-timezone-detection-with-javascript -->
    <script type="text/javascript" src="http://cdn.bitbucket.org/pellepim/jstimezonedetect/downloads/jstz.min.js"></script>
    
    <!-- BT - Added to support display of user's local timezone. -->
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(drawChart);

// BT - Use jstz to get user's local timezone (see comment above about jstz).
      var timezone = jstz.determine();

      // BT - Date shift chart data to user's local timezone.
      function fixTimezone(dataArray) {
        var timezoneOffsetHours = new Date().getTimezoneOffset() / 60;
        var shiftHours = timezoneOffsetHours;
        
        var output = new Array();
        output[0] = dataArray[0];
        
        if(timezoneOffsetHours < 0)
            timezoneOffsetHours = 23 + timezoneOffsetHours;
            
        for(var i = 0; i < 24; i++) {
            var currentHour = timezoneOffsetHours + i;
            
            if(currentHour > 23)
                currentHour -= 24;
            
            dataArray[currentHour + 1][0] = i+':00';        
            output[i + 1] = dataArray[currentHour + 1];
        }
        
        return output;
      }

      function drawChart() {
// BT - Added fixTimezone function to dateshift the chart data.
        var data = google.visualization.arrayToDataTable(fixTimezone([
$data
        ]));

        var options = {
			curveType: 'function',
	  		backgroundColor: {fill:'transparent'},
          	title: 'Allegiance Player Playing Patterns (past 30 days)',
          	vAxis: {title: '# of players', textPosition: 'none',},
// BT - Added user's local timezone name.
          	hAxis: {title: 'Hour (' + timezone.name() + ')', gridlines: {color: '#333', count: 24}, slantedText: true, slantedTextAngle: 90, showTextEvery: 1, textStyle: {color: 'black', fontName: 'Arial', fontSize: 12}, },
        }

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }

// BT - Determine next squad game time in user's local timezone.
      \$(document).ready(function()
      {
        var squadGameTime = new Date();
        
        for(var i = squadGameTime.getUTCDay(); i != 0; i = squadGameTime.getUTCDay())
            squadGameTime.setUTCDate(squadGameTime.getUTCDate() + 1);
        
        squadGameTime.setUTCHours(19);
        squadGameTime.setUTCMilliseconds(0);
        squadGameTime.setUTCMinutes(0);
        squadGameTime.setUTCSeconds(0);
      
        \$("#spanSquadGameTime").html(squadGameTime.toString());
      });	

    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 1100px; height: 500px;"></div>
	<h3>Next Squad Game Time: <span id="spanSquadGameTime"></span></h3>
<pre>
Special thanks to these contributors:
BackTrak - client side timezone shifting
and all the folks who provided feedback (and convinced me to graph it) on this <a href="http://www.freeallegiance.org/forums/index.php?showtopic=66568">thread</a>

older versions of this program
<a href="http://spathiwa.com/cgi-bin/pp.pl">version 1</a> (only shows 1 week's worth of data)
<a href="http://spathiwa.com/cgi-bin/gpp.pl">version 2</a> (only shows 1 week's worth of data)
<a href="http://spathiwa.com/cgi-bin/spp.pl">version 3</a> (only shows 1 week's worth of data)
<a href="http://spathiwa.com/cgi-bin/mpp.pl">version 4</a> (uses monthly set of data)
</pre>
  </body>
</html>
HTML
