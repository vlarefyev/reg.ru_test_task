$text = "2016-04-11 20:59:03";

$text =~ /(\d{4}(-\d{2}){2})\s((\d{2}:){2}\d{2})/mg;
my ($date, $time) = ($1, $3);

print "$date\n";
print "$time\n";
