use strict;
use XML::Writer;
use IO::File;


my %big_dictionary;
my $input_file;
my $pkg;
my $count = 0;

sub println
{
	my $arg = shift;
	print $arg,"\n";
}

sub readDb
{
	my $dir = "db/*.csv";
	my @files = glob( $dir );

	foreach my $file (@files )
	{			
		println "reading file: $file";
	   	readToDic($file);
	}
	
}

sub readToDic
{
	my $file = shift;
	open F1, "<$file";
	my @data = <F1>;
	
	foreach my $line (@data)
	{
		my @record = split(",", $line);
		$big_dictionary{$record[1]} = $record[2];
	}
	
	close F1;
}

sub processPkg
{
	my $myPkg = $pkg;
	my @pkgData = @_;
#	print "package data:\n";
#	print join "\n",@pkgData;
#	print "\n\n";
	my $output = IO::File->new(">$myPkg-Listing.tgl");
	my $writer = XML::Writer->new(OUTPUT => $output, UNSAFE => 1, DATA_MODE => 1, DATA_INDENT=>4);
	
	$writer->xmlDecl("UTF-8");
	
	## suite root node
	$writer->startTag("suite");
	
	## Package name
	$writer->dataElement("name", $myPkg);
	
	my $oldGroup = "null";
	my $totalTc = scalar @pkgData;
	
	foreach(@pkgData)
	{
		$count++;
		my $line = $_;
		my @lineData = split ',', $line;
		
		my $tcGroup = $lineData[0];
		my $tcName = $lineData[1];
		#my $tcVerdict = $lineData[2];
		
		if($tcGroup ne $oldGroup)
		{
			## Group name
			if($oldGroup ne "null")
			{
				$writer->endTag();
			}
			
			# start new group
			$writer->startTag("group");
			$writer->dataElement("name", $tcGroup);
			$oldGroup = $tcGroup;
			
			# also add the first testcase of the new group
			$writer->startTag("test");
			$writer->dataElement("name", $tcName);
			$writer->endTag();
		}
		else
		{
			## loop testcase here:
			$writer->startTag("test");
			$writer->dataElement("name", $tcName);
			$writer->endTag();
		}
		if($count == $totalTc)
		{
			## End of the group, Close group tag
			$writer->endTag();
		}
	}
	# close suite tag
	$writer->endTag();
#	print $writer->to_string();
	$writer->end();
	$output->close();
#	undef $output;
}

sub readInput
{
	if(!-f $input_file)
	{
		die "Cannot find file $input_file";
	}
	
	open(F2, "<$input_file");
	
	my @data = <F2>;
	my @filter;
	
	foreach my $line (@data)
	{
		if($line =~ /^#/ or $line =~ /Passed/i)
		{
			next;
		}
		
		my @lineData = split(',', $line);
		if(scalar @lineData > 6)
		{
			print "Wrong format: $line\n";
			next;
		}
		my $tcGroup = $lineData[2];
		my $tcID = $lineData[3];
		if(defined $big_dictionary{"$tcID--$tcGroup"})
		{
			my $tcName = $big_dictionary{"$tcID--$tcGroup"};
			chomp $tcName;
			push(@filter, "$tcGroup,$tcName");
		}
		else
		{
			println "$tcID--$tcGroup does\'t exist in big dictionary";  
		}
	}
	
	close F2; 
	return @filter;

}

sub main
{
	println "Read database csv...";
	readDb();
	
	println "Read to big dictionary...";
	readToDic();
	
	println "Read input file...";
	my @data = readInput();
	
	println "Generate tgl file...";
	processPkg(@data);
	
	println "Total testcase in tgl file: $count";
	println "Finish!";
}

sub usage
{
	println "Wrong format!";
	
}

my $arg_length = scalar @ARGV;

if($arg_length != 2)
{
	usage();
}
else
{
	$input_file = $ARGV[0];
	$pkg = $ARGV[1];
	main();
}

