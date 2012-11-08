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
my $data="";
#my $rawdata="";

foreach my $hour (sort keys %db){
	my $d=0;
	my $e=0;
	my $f=0;
	my $dacc=0;
	my $eacc=0;
	my $facc=0;
	foreach my $dow (sort keys %{$db{$hour}}){
		foreach my $day (sort keys %{$db{$hour}{$dow}}){
			#$rawdata=$rawdata."hour: $hour dow: $dow day: $day $db{$hour}{$dow}{$day}\n";
			if($dow < 6){
				$d++;
				$dacc=$dacc+$db{$hour}{$dow}{$day};
			}elsif($dow == 6){
				$e++;
				$eacc=$eacc+$db{$hour}{$dow}{$day};
			}else{
				$f++;
				$facc=$facc+$db{$hour}{$dow}{$day};
			}
		}
	}
#	print "$hour weekday avg: ",$dacc/$d,"\n";
#	print "$hour weekend avg: ",$eacc/$e,"\n";
	my $a=sprintf("%.1f",$dacc/$d);
	my $b=sprintf("%.1f",$eacc/$e);
	my $c=sprintf("%.1f",$facc/$f);
	$hour=~s/\b0//;
	$data=$data."[$hour,$a,$b,$c],\n";
}

$data=~s/\,$//;

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
      
      // BT - Date shift chart data to user's local timezone.
      function fixTimezone(timezoneOffsetMinutes, dataArray) {
        var timezoneOffsetHours = Math.round(timezoneOffsetMinutes / 60) * -1;
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

    function drawChart(timezoneName, timezoneOffsetMinutes)
    {
        \$("#chart_div").empty();
        
        weekendLabel1 = "Saturday Avg";
        weekendLabel2 = "Sunday Avg";
        
        // Once squad game time crosses midnight local time, shift the labels up a day.
        if(timezoneOffsetMinutes / 60 >= 4)
        {
            weekendLabel1 = "Sunday Avg";
            weekendLabel2 = "Monday Avg";
        }
    
        // BT - Added fixTimezone function to dateshift the chart data.
        var data = google.visualization.arrayToDataTable(fixTimezone(timezoneOffsetMinutes, [
            ['Hour','Weekday Avg',weekendLabel1,weekendLabel2],
$data
        ]));

        var options = {
            curveType: 'function',
            backgroundColor: {fill:'transparent'},
            title: 'Allegiance Player Playing Patterns (past 30 days)',
            vAxis: {title: '# of players', textPosition: 'none'},
            
            // BT - Added user's local timezone name.
            hAxis: {title: 'Hour (' + timezoneName + ')', gridlines: {color: '#333', count: 24}, slantedText: true, slantedTextAngle: 90, showTextEvery: 1, textStyle: {color: 'black', fontName: 'Arial', fontSize: 12} }
        }

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }

    // BT - Determine next squad game time in user's local timezone.
    \$(document).ready(function()
    {
        var currentTimezoneName = jstz.determine().name();
        var currentTimezoneOffsetMinutes = new Date().getTimezoneOffset();
        
        // BT: Add timezone selection dropdown.
        var \$ddlTimezone = \$("#ddlTimezone");
        \$.each(jstz.olson.timezones, function(offsetMinutesList, zoneName)
        {
            var offsetMinutes = parseInt(offsetMinutesList.split(",")[0]);
            
            // Ignore any .5 timezones, they will just have to pick a neighbor timezone.
            // .5 timezones messes up the date shifter, and the graph legend, etc.
            if(offsetMinutes % 60 == 0)
            {
                // If the local machine is obeying DST, and the timezone has an olson DST start date
                // we'll pretend that the timezone should be shown with the DST offset.
                var isDST = false;
                if(jstz.olson.dst_start_dates[zoneName] != null && jstz.date_is_dst(new Date()) == true)
                {
                    offsetMinutes += 60;
                    isDST = true;
                }
                
                var offsetHours = offsetMinutes / 60;
                
                var offsetString = "UTC";
                if(offsetHours >= 0)
                    offsetString += "+"
                    
                offsetString += offsetHours;
                
                var currentStringLength = offsetString.length;
                for(var i = 0; i < (10 - currentStringLength); i++)
                    offsetString += "&nbsp;";
                
                var selected = "";
                if(currentTimezoneName == zoneName)
                    selected = "selected"
                    
                var isDSTString = "";
                if(isDST == true)
                    isDSTString = " (DST)"
                
                \$ddlTimezone.append(\$("<option " + selected + " />").val(offsetMinutes).html(offsetString + zoneName + isDSTString));
                \$("#ddlTimezone option:last-child").attr("timezoneName", zoneName);
            }
            
        });

        \$ddlTimezone.change(function()
        {
            var offset = \$("#ddlTimezone option:selected").val();
            var timezoneName = \$("#ddlTimezone option:selected").attr("timezoneName");
            
            drawChart(timezoneName, offset);
        
            updateSquadgameTime(offset, timezoneName);
        });
        
        \$ddlTimezone.trigger("change");
    });    
      
      function updateSquadgameTime(timezoneOffsetMinutes, timezoneName)
      {
            var squadGameTime = new Date();
            
            for(var i = squadGameTime.getUTCDay(); i != 0; i = squadGameTime.getUTCDay())
                squadGameTime.setUTCDate(squadGameTime.getUTCDate() + 1);
            
            squadGameTime.setUTCHours(19 + (timezoneOffsetMinutes / 60));
            squadGameTime.setUTCMilliseconds(0);
            squadGameTime.setUTCMinutes(0);
            squadGameTime.setUTCSeconds(0);
            
            var month=new Array(12);
            month[0]="January";
            month[1]="February";
            month[2]="March";
            month[3]="April";
            month[4]="May";
            month[5]="June";
            month[6]="July";
            month[7]="August";
            month[8]="September";
            month[9]="October";
            month[10]="November";
            month[11]="December";
            
            var squadGameHours = squadGameTime.getUTCHours ( );
            var squadGameMonth = month[squadGameTime.getUTCMonth()];
            var squadGameDay = squadGameTime.getUTCDate ( );
            var squadGameYear = squadGameTime.getUTCFullYear ( );
            
          
            \$("#spanSquadGameTime").html(
                squadGameMonth + " " +
                squadGameDay + ", " +
                squadGameYear + " " + squadGameHours + ":00:00   (" + timezoneName + ")");
      }

    </script>
  </head>
  <body>
    
    <!-- BT: Cause the select to be centered. -->
    <div style="display: inline-block; text-align: center;">
        <div id="chart_div" style="width: 1100px; height: 500px;"></div>
        <select id="ddlTimezone" style="font-family: monospace"></select>
    </div>
    <h3>Next Squad Game Time: <span id="spanSquadGameTime"></span></h3>
<pre>
Special thanks to these contributors:
BackTrak - client side timezone shifting
and all the folks who provided feedback (and convinced me to graph it) on this <a href="http://www.freeallegiance.org/forums/index.php?showtopic=66568">thread</a>

other versions of this program
<a href="http://spathiwa.com/cgi-bin/playerbase_predictor/pp.pl">original table version</a> (only shows 1 week\'s worth of data)
<a href="http://spathiwa.com/pp/">timezone adjustment at input + timezone autodetect</a> (uses monthly set of data)
<a href="http://spathiwa.com/cgi-bin/playerbase_predictor/tz_mpp2.pl">centered around sg time (19:00 UTC on Sunday = midnight)</a> (uses monthly set of data)
</pre>
  </body>
</html>
HTML
