# Original from https://juanpalomez.wordpress.com/2013/04/18/memory-usage-treemap-windirstat-for-memory/

my %groups = ();
my $output;

my $output_pre = "
        <html>
          <head>
            <script type='text/javascript' src='https://www.google.com/jsapi'></script>
            <script type='text/javascript'>
              google.load('visualization', '1', {packages:['treemap']});
              google.setOnLoadCallback(drawChart);
              function drawChart() {
                  // Create and populate the data table.
                  var data = google.visualization.arrayToDataTable([
                    ['Process', 'Parent', 'Size'],
                    ['root',    null,                 0],
";

my $output_post = "
                  ]);

                  // Create and draw the visualization.
                  var treemap = new google.visualization.TreeMap(document.getElementById('chart_div'));
                  treemap.draw(data, {
                    minColor: 'red',
                    midColor: '#ddd',
                    maxColor: '#0d0',
                    headerHeight: 15,
                    fontColor: 'black',
                    showScale: true});
                }
        </script>
  </head>

  <body>
    <div id='chart_div' style='width: 900px; height: 500px;'></div>
  </body>
</html>
";

open TASKLIST, "tasklist /nh /fo CSV |" or die "Can't execute tasklist command $!\n";
while (<TASKLIST>) {
        if (m/"(.+)","(.+)",".+",".+","(.+) KB?"/) {
                $name = $1;
                $pid  = $2;
                $size = $3;
                $size =~ s/\.//;
                $output .= "['$pid','$name',$size],\n";
                $groups{"$name"} = 1;
        }
}

close TASKLIST;

while ( my ($key, $value) = each(%groups) ) {
        $output .= "['$key','root',0],\n";
}

chop $output;
chop $output;

print $output_pre . $output . $output_post;
