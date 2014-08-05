use strict;

my %dic;
my $in_file;


sub readData
{
	
	if(!-f $in_file)
	{
		die "Cannot find file $in_file";
	}
	
	open(FILECSV, "<$in_file");
	my @data = <FILECSV>;
	
	close FILECSV;
	return @data;
}

sub saveToDic
{
	my @source = readData();	
	
	foreach my $line (@source)
	{
		
		if($line =~ /^#/)
		{
			next;
		}
		
		my @lineData = split(',', $line);
		if(scalar @lineData > 6)
		{
			print "Wrong format: $line\n";
			next;
		}
		my $tcID = $lineData[1];
		my $tcName = $lineData[2];
		#my $tcVerdict = $lineData[3];
		my $tcGroup = $lineData[4];
		
		$dic{"$tcID--$tcGroup"} = $tcName;		
	}
}

sub save
{
	saveToDic();
	my $count = 0;
	open(OUT, ">output.csv");
	
	foreach my $key (keys %dic)
	{
		$count++;
		print OUT "$count,$key,$dic{$key}\n";
	}
	print "done save to output file!\n";
	close OUT;
	
}

sub usage
{
	print "Wrong parameter!\n";
}

my $arg_length = scalar @ARGV;

if($arg_length != 1)
{
	usage();
}
else
{
	$in_file = $ARGV[0];
	save();
}