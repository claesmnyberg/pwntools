#!/usr/bin/perl

use Socket;

# (C) Copyright Claes M Nyberg <md0claes@mdstud.chalmers.se> 2004
#
# $Id: connect_tcp.pl,v 1.1.1.1 2004-12-14 20:27:23 cmn Exp $

#
# Connect to ip:port
#
sub tcp_connect
{
	print "Connecting to $_[0]:$_[1]\n";
	
	$proto = getprotobyname('tcp');
	socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "** Error: socket(): $!";
	$iaddr = gethostbyname($_[0]);
	$port = $_[1];
	$sin = sockaddr_in($port,inet_aton($_[0]));
	connect(SOCK, $sin) || die "** Error Connecting to $_[0]:$_[1]: $!";	
}


$ip = $ARGV[0];
$port = $ARGV[1];

&tcp_connect($ip, $port);


print "Connected\n";

# Read from socket and write to stdout
$response = <SOCK>;

print $response;
