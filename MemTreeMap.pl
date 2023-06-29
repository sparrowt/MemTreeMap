# Memory usage visualisation (like WinDirStat for RAM)
#
# Heavily inspired by https://juanpalomez.wordpress.com/2013/04/18/memory-usage-treemap-windirstat-for-memory/
# Bug fixes, enhancements, comments by sparrowt (who barely knows perl but hasn't yet bothered to rewrite it in python)
#
# Usage:
#   perl MemTreeMap.pl > memoryusage.html && start memoryusage.html
#
# From powershell:
#   perl MemTreeMap.pl | Out-File -Encoding Utf8 memoryusage.html ; start memoryusage.html
#
# Notes:
#  - this does NOT show some memory usage such as 'Driver Locked' (e.g. by Hyper-V) use SysInternals RamMap to show this
#  - to show PID breakdown without clicking change `maxPostDepth: 1` to `maxDepth: 2`

use POSIX 'strftime';

my %groups = ();
my $output_data;

my $output_A = q`
        <html>
          <head>
            <script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script>
            <script type='text/javascript'>
              google.charts.load('current', {'packages':['treemap']});
              google.charts.setOnLoadCallback(drawChart);
              function drawChart() {
                  // Create and populate the data table.
                  var data = google.visualization.arrayToDataTable([
                    ['Process', 'Parent', 'Size'],
                    ['All Processes',    null,                 0],
`;
# The `while` loop below fills in the rest of the data array

my $output_B = q`
                  ]);


                  // Tooltip showing total memory usage
                  function showStaticTooltip(row, size, value) {
                    return '<div style="background:#fff; padding:10px; border-style:solid; border-width: thin">'
                        + 'Total memory usage for &lt;' + data.getValue(row, 0) + '&gt;: ' + parseInt(size).toLocaleString() + ' KB'
                        + '</div>';
                  }

                  // Create and draw the visualization.
                  var treemap = new google.visualization.TreeMap(document.getElementById('chart_div'));
                  treemap.draw(data, {
                    highlightOnMouseOver: true,
                    maxPostDepth: 1,
                    minColor: '#baa',
                    midColor: '#b60',
                    maxColor: '#e00',
                    showScale: true,
                    hintOpacity: 0.0,
                    headerHeight: 15,
                    fontColor: 'black',
                    generateTooltip: showStaticTooltip,
                  });

                  function getSum(dt, column) {
                    var total = 0;
                    for (i = 0; i < dt.getNumberOfRows(); i++)
                        total = total + dt.getValue(i, column);
                    return total;
                  }
                  // Show the total RAM usage of all processes shown
                  document.getElementById('total_mem').innerText = 'total: ' + parseInt(getSum(data, 2)).toLocaleString() + ' KB';
                }
        </script>
  </head>
`;

my $dt_str = strftime("%Y-%m-%d %H:%M:%S UTC", gmtime);

my $output_C = "
  <body>
    <h2>Memory Usage Visualization at $dt_str <span id='total_mem'></span></h2>
    <div id='chart_div' style='width: 1200px; height: 900px;'></div>
    <p>Tips:
        <ul>
            <li>At the top level memory usage is aggregated by executable name</li>
            <li>Left-click to drill down to individual process IDs</li>
            <li>Right-click to return up a level</li>
        </ul>
    </p>
  </body>
</html>
";

open TASKLIST, "tasklist /nh /fo CSV |" or die "Can't execute tasklist command $!\n";
while (<TASKLIST>) {
        # tasklist output columns: "Image Name","PID","Session Name","Session#","Mem Usage"
        if (m/"(.+)","(.+)",".+",".+","(.+) KB?"/) {
                $name = $1;
                $pid  = $2;
                $size = $3;
                # Remove all thousands separators
                $size =~ s/[\.,]//g;
                # Add per-process node as a child of the executable name
                $output_data .= "['$pid','$name',$size],\n";
                # Ensure exe name is in the set of groups (value 1 is ignored)
                $groups{"$name"} = 1;
        }
}

close TASKLIST;

# Add each group (processes by exe name) as children of the root 'All Processes' node
# Set size 0 but they are sized based on the sum of all their children
while ( my ($key, $value) = each(%groups) ) {
        $output_data .= "['$key','All Processes',0],\n";
}

chop $output_data;
chop $output_data;

print $output_A . $output_data . $output_B . $output_C;
