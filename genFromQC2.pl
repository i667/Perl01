#author perry
use strict;
use XML::Writer;
use IO::File;
use DBI;

my $input_file;
my $pkg;
my $total = 0;

# database
my $dsn = "dbi:SQLite:dbname=all-package.db";
my $user = '';
my $password = '';
my %attr = ( RaiseError => 1 );

my $dbh = DBI->connect($dsn, $user, $password, \%attr) 
	or die "Can't connect to database: $DBI::errstr";
		
sub println
{
	my $arg = shift;
	print $arg,"\n";
}

sub processPkg
{
	my $myPkg = $pkg;
	my @pkgData = @_;
#	print "package data:\n";
#	print join "\n",@pkgData;
#	print "\n\n";
	my $output = IO::File->new(">$myPkg-Listing.tgl");
	my $writer = XML::Writer->new(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT=>4);
	
	$writer->xmlDecl("UTF-8");
	
	## suite root node
	$writer->startTag("suite");
	
	## Package name
	$writer->dataElement("name", $myPkg);
	
	my $oldGroup = "null";
	my $totalTc = scalar @pkgData;
	
	my $count = 0;
	foreach my $line (@pkgData)
	{
		$count++;		
		my @lineData = split ',', $line;
		
		my $tcGroup = $lineData[0];
		my $tcName = $lineData[1];
		
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
			println "skip this line: $line";
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
		
		my $statement = $dbh->prepare("select ID from testcases where Key=\'$tcID--$tcGroup\'");
		$statement->execute();
		my @row = $statement->fetchrow();
		if(not @row)
		{
			println "$tcID--$tcGroup does\'t exist in big database"; 
		}
		else
		{			
			push(@filter, $row[0]);
		}
	}
	
	close F2; 
	return @filter;

}

sub getGroupFromKey
{
	my $key = shift;
	my @res = split("--", $key);
	return $res[1];
}

sub main
{
	
	println "Read input file $input_file...";
	my @data = sort(readInput());
	
	my @tgl_data;
	foreach my $id (@data)
	{
		$total++;
		my $statement = $dbh->prepare("select Key,TCName from testcases where ID=\'$id\'");
		$statement->execute();
		my @row = $statement->fetchrow();
		
		if(not @row)
		{
			println "ID: $id does\'t exist in big database"; 
		}
		else
		{
			my $group = getGroupFromKey($row[0]);
			my $testcase = $row[1];
			chomp $testcase;
			push(@tgl_data, "$group,$testcase");
		}
	}
	
	println "Generate tgl file...";
	processPkg(@tgl_data);
	
	println "Total testcase in tgl file: $total";
	println "Finish!";
#	print join("\n", @data);
	
}

sub usage
{
	println "Wrong format!";
	println "should be: scriptname inputfile packagename";
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

$dbh->disconnect();

