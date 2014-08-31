use strict;
use DBI;

sub readDb
{
	my $dir = "db/*.csv";
	my @files = glob( $dir );

	foreach my $file (@files )
	{			
		print "reading file: $file\n";
	   	readToDic($file);
	}
	
}

sub readToDic
{
	my $file = shift;
	open F1, "<$file";
	my @data = <F1>;
	
	my $dbh = DBI->connect(          
	    "dbi:SQLite:dbname=all-package.db", 
	    "",                          
	    "",                          
	    { RaiseError => 1 },
	) or die $DBI::errstr;
	
	foreach my $line (@data)
	{
		print "$line\n";
		my @record = split(",", $line);
		$dbh->do("insert into testcases (\'InternalID\',\'Key\',\'TCName\') values(\'$record[0]\',\'$record[1]\',\'$record[2]\')");
#		$big_dictionary{$record[1]} = $record[2];
#		print "$record[0]\n";
	}
	
	close F1;
	$dbh->disconnect();
}


readDb();