package swat;
our $VERSION = v0.1.4;
1;

package main;
use strict;
use Test::More;
our $HTTP_RESPONSE;
our ($curl_cmd, $content_file, $url, $path, $http_meth, $debug, $ignore_http_err, $try_num, $head_bytes_show );
our ($a, $b);

$| = 1;

sub execute_with_retry {

    my $cmd = shift;
    my $try = shift || 1;

    for my $i (1..$try){
        diag "\nexecute cmd: $cmd, attempt number: $i" if $debug;
        return $i if system($cmd) == 0;
        sleep $i**2;
    }
    return

}

sub make_http_request {

    return $HTTP_RESPONSE if defined $HTTP_RESPONSE;
    my $st = execute_with_retry("$curl_cmd > $content_file && test -s $content_file", $try_num);

    open F, $content_file or die $!;
    $HTTP_RESPONSE = '';
    $HTTP_RESPONSE.= $_ while <F>;
    close F;

    diag `head -c $head_bytes_show $content_file` if $debug;

    ok($st, "successfull response from $http_meth $url$path") unless $ignore_http_err;

    diag "data file: $content_file";

    return $HTTP_RESPONSE;
}

sub hostname {
    my $a = `hostname`;
    chomp $a;
    return $a;
}

sub check_line {
 
    my $pattern = shift;
    my $check_type = shift;
    my $message = shift;

    my $status = 0;
    my $data = make_http_request();

    my @chunks;

    if ($check_type eq 'default'){
        $status = 1 if index($data,$pattern) != -1
    }elsif($check_type eq 'regexp'){
        for my $l (split /\n/, $data){
            chomp $l;
            if ($l =~ qr/$pattern/){
                push @chunks, $1||$&;
                $status = 1;
            }
        }
    }else {
        die "unknown check_type: $check_type";
    }

    ok($status,$message);


    for my $c (@chunks){
        diag("line found: $c");
    }

    return

}


sub header {

    diag("start swat for $url/$path");
    diag("try num $try_num");

}

sub generate_asserts {

    header();

    my $patterns_file = shift;

    open my $fh, $patterns_file or die $!;

    my $comment;

    while (my $l = <$fh>){

        chomp $l;
        

        next unless $l =~ /\S/; # skip blank lines
        if ($l=~ /^\s*#(.*)/) { # skip comments
            $comment = $1;
            s/^\s+//, s/\s+$// for $comment;
            next;
        }

        if ($l=~/\s*code:\s+(.*)/){
            undef $comment;
            my $code = $1;
            eval $code;            
        }elsif($l=~/\s*regexp:\s+(.*)/){
            my $re=$1;
            my $message = $comment ? "[$comment] $http_meth $path returns data matching $re" : "$http_meth $path returns data matching $re";
            check_line($re, 'regexp', $message);
            undef $comment;
        }else{
            s{#.*}[], s{\s+$}[], s{^\s+}[] for $l;
            my $message = $comment ? "[$comment] $http_meth $path returns $l" : "$http_meth $path returns $l";
            check_line($l, 'default', $message);
            undef $comment;
        }
    }

    close $fh;

}



1;


