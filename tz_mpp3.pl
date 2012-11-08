#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Date::Calc qw(Day_of_Week Today Add_Delta_DHMS);
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

my $offset=param('offset');

$offset =~ s/[^0-9,-]//go;


while(my @line=$sth->fetchrow_array()){

	$line[1]=~/(\d+)-(\d+)-(\d+) (\d+):/;

	if(!defined($offset)){
		$offset=0;
	}
	my($year,$month,$day,$hour,$min,$sec)=Add_Delta_DHMS($1,$2,$3,$4,0,0,0,$offset,0,0);
	my @number_of_players=split(/ /,$line[2]);
	my $dow=Day_of_Week($year,$month,$day);
	$db{$hour}{$dow}{"$year-$month-$day"}=@number_of_players;
}

my %results;
my $data="['Hour','Weekday Avg','Saturday Avg','Sunday Avg'],\n";
my $rawdata="";

foreach my $hour (sort {$a <=> $b} keys %db){
	my $d=0;
	my $e=0;
	my $f=0;
	my $dacc=0;
	my $eacc=0;
	my $facc=0;
	foreach my $dow (sort {$a <=> $b} keys %{$db{$hour}}){
		foreach my $day (sort keys %{$db{$hour}{$dow}}){
			$rawdata=$rawdata."hour: $hour dow: $dow day: $day $db{$hour}{$dow}{$day}\n";
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
	#$hour=~s/\b0//;
	$hour=$hour.':00';
	$data=$data."[\'$hour\',$a,$b,$c],";
}

$data=~s/\,$//;


if($offset=~/\-\d+/){
}elsif($offset==""){
	$offset='+0';
}else{
	$offset='+'.$offset;
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

      // http://paulgueller.com/2011/04/26/parse-the-querystring-with-jquery/
      jQuery.extend({
          parseQuerystring: function(){
            var nvpair = {};
            var qs = window.location.search.replace('?', '');
            var pairs = qs.split('&');
            \$.each(pairs, function(i, v){
              var pair = v.split('=');
              nvpair[pair[0]] = pair[1];
            });
            return nvpair;
          }
        });
        
        // http://www.mresoftware.com/simpleDST.htm
        function isLocalTimeDST()
        {
            var today = new Date;
            var yr = today.getFullYear();
            var jan = new Date(yr,0);    // January 1
            var jul = new Date(yr,6);    // July 1
            // northern hemisphere test
            if (jan.getTimezoneOffset() > jul.getTimezoneOffset() && today.getTimezoneOffset() != jan.getTimezoneOffset()){
                return true;
                }
            // southern hemisphere test    
            if (jan.getTimezoneOffset() < jul.getTimezoneOffset() && today.getTimezoneOffset() != jul.getTimezoneOffset()){
                return true;
                }
            // if we reach this point, DST is not in effect on the client computer.    
            return false;
        }

      
      
// BT - Use jstz to get user's local timezone (see comment above about jstz).
      var timezone = jstz.determine();

      function drawChart() {
        var data = google.visualization.arrayToDataTable([
$data
        ]);

        var options = {
            curveType: 'function',
              backgroundColor: {fill:'transparent'},
              title: 'Allegiance Player Playing Patterns (past 30 days)',
              vAxis: {title: '# of players', textPosition: 'none'},
              hAxis: {title: 'Hour', gridlines: {color: '#333', count: 24}, slantedText: true, slantedTextAngle: 90, showTextEvery: 1, textStyle: {color: 'black', fontName: 'Arial', fontSize: 12} }
        }

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }

      // BT - Setup drop down with timezone options.
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
        
        // BT: Add timezone selection dropdown.
        var currentTimezoneName = jstz.determine().name();
        
        var queryString = \$.parseQuerystring();
        
        if(typeof(queryString["timezoneName"]) != "undefined")
            currentTimezoneName = queryString["timezoneName"];
            
        var currentTimezoneOffset;
        
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
                if(jstz.olson.dst_start_dates[zoneName] != null && isLocalTimeDST() == true)
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
                {
                    selected = "selected"
                    currentTimezoneOffset = offsetHours;
                }
                    
                var isDSTString = "";
                if(isDST == true)
                    isDSTString = " (DST)"
                
                \$ddlTimezone.append(\$("<option " + selected + " />").val(offsetHours).html(offsetString + zoneName + isDSTString));
                \$("#ddlTimezone option:last-child").attr("timezoneName", zoneName);
            }
        });
        
        \$ddlTimezone.change(function()
        {
            var offset = \$("#ddlTimezone option:selected").val();
            var timezoneName = \$("#ddlTimezone option:selected").attr("timezoneName");
            
            window.location.href = window.location.href.substring(0, window.location.href.length - window.location.search.length) + "?offset=" + offset + "&timezoneName=" + escape(timezoneName);
        });
        
        
        updateSquadgameTime(currentTimezoneOffset, currentTimezoneName);
        
      });    
      
      
      function updateSquadgameTime(timezoneOffsetHours, timezoneName)
      {
            var squadGameTime = new Date();
            
            for(var i = squadGameTime.getUTCDay(); i != 0; i = squadGameTime.getUTCDay())
                squadGameTime.setUTCDate(squadGameTime.getUTCDate() + 1);
            
            squadGameTime.setUTCHours(19 + timezoneOffsetHours);
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
