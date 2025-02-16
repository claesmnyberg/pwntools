#!/usr/bin/perl

#
# CGI File Upload
# (C) Copyright Claes M Nyberg <cmn@darklab.org> 2005
#
# $Id: cgi_upload.pl,v 1.2 2005-03-09 17:05:14 cmn Exp $
#

# Read and write file
sub retrieve_file()
{
	$len = int($ENV{'CONTENT_LENGTH'});
	$boundary = <STDIN>;
	$len -= length($boundary);
	$boundary = "\r\n" . $boundary;

	# Read data header
	while (<STDIN>) {
		$len -=length($_);

		# Cho(m)p newline
		s/\n//; s/\r//;
	
		($_ eq '') and last;

		# Strip out source file name
		#if (/^Content-Disposition: /) {
		#	print "** GOT Content: $_\n";
		#}
	}

	# Read the posted data into memory 
	# (and hope that there is enough space ...)
	if (read(STDIN, $buf, $len) != $len) { 
		print("*** FATAL: Failed to read file: $!\n"); 
		exit(1);
	}
	@input = split(/$boundary/, $buf);

	# Get name of target file and open it
	if ($input[1] ne "") {
		@fields = split(/\n/, $input[1]);
		$destpath = $fields[$#fields-1];
	}

	# Open the target file and write the data
	if (open(DEST, ">$destpath") == 0) {
		print("*** FATAL: Failed to open file '$destpath': $!\n");
		exit(1);
	}

	binmode(DEST);
	print DEST $input[0];
	close(DEST);

	# We are done
	print "File <b>$destpath</b> uploaded.<br><br>\n";
	print "<a href=\"$ENV{'SCIPT_NAME'}\">back</a>\n";
	
	print "</body></html>";
	exit(1);
}


# Reopen standard error as standard out
open(STDERR, ">&STDOUT");

print<<__ENDHTML__;
Content-type: text/html\n\n
	<head><title>CGI File Upload</title></head>
	<html>
	<body>
__ENDHTML__

# Attempt to retrieve file
($ENV{'REQUEST_METHOD'} eq "POST") and
	retrieve_file();


print "<form method=\"POST\" enctype=\"multipart/form-data\" \
		action=\"$ENV{'SCIPT_NAME'}\">";

print<<__ENDHTML__;
		<p>
		<b>Source file</b><br>
		<input name="srcfile" type="file" size="30"><br>
		<p>
		<b>Destination path</b><br>
		<input name="destpath" type="text" size="30"><br>
		<p>
		<input type="submit" value="Upload File">
	</form>
__ENDHTML__

print "</body></html>";
