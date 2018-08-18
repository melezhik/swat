package swat;

our $VERSION = '0.2.0';

use base 'Exporter'; 

our @EXPORT = qw{version};

sub version {
    print $VERSION, "\n"
}


1;

package main;

use strict;

use Carp;
use File::Temp qw/ tempfile /;

use swat::story;

use Carp;
use Config::Tiny;
use YAML qw{LoadFile};

use Term::ANSIColor;

my $config;

our $STATUS = 1;

sub config {

    unless ($config){
        if (get_prop('suite_ini_file_path') and -f get_prop('suite_ini_file_path') ){
          my $path = get_prop('suite_ini_file_path');
          $config = $config = Config::Tiny->read($path) or confess "file $path is not valid .ini file";
        }elsif(get_prop('suite_yaml_file_path') and -f get_prop('suite_yaml_file_path')){
          my $path = get_prop('suite_yaml_file_path');
          ($config) = LoadFile($path);
        }elsif ( -f 'suite.ini' ){
          my $path = 'suite.ini';
          $config = $config = Config::Tiny->read($path) or confess "file $path is not valid .ini file";
        }elsif ( -f 'suite.yaml'){
          my $path = 'suite.yaml';
          ($config) = LoadFile($path);
        }else{
          confess "configuration file is not found"
        }
    }

    return $config;
}

sub make_http_request {

    return if get_prop('response_done');

    my ($fh, $content_file) = tempfile( DIR => get_prop('test_root_dir') );
    
    my $try_i;

    my $try = get_prop('try_num');

    if (get_prop('response') and @{get_prop('response')} ){

        swat_note(1,'server response is spoofed');

        open F, ">", $content_file or die $!;
        print F ( join "\n", @{get_prop('response')});
        close F;

        open F, ">", "$content_file.stderr" or die $!;
        close F;

        open F, ">", "$content_file.hdr" or die $!;
        close F;

        swat_note("response saved to $content_file");

    }else{

        my $curl_cmd = get_prop('curl_cmd');
        my $hostname = get_prop('hostname');
        my $resource = get_prop('resource');
        my $http_method = get_prop('http_method'); 

        my $curl_runner = "$curl_cmd -w '%{response_code}' -D $content_file.hdr -o $content_file --stderr $content_file.stderr '$hostname$resource' > $content_file.http_status";
        my $curl_runner_short = tapout( "$curl_cmd -D - '$hostname$resource'", ['cyan'] );
        my $http_status = 0;

        TRY: for my $i (1..$try){
            swat_note("try N [$i] $curl_runner") if debug_mod12();
            $try_i = $i;
            system($curl_runner);
            if(open HTTP_STATUS, "$content_file.http_status"){
                $http_status = <HTTP_STATUS>;
                close HTTP_STATUS;
                chomp $http_status;
                swat_note("got http status: $http_status") if debug_mod12();
                last TRY if $http_status < 400 and $http_status > 0;
                last TRY if $http_status >= 400 and ignore_http_err();

            }
            my $delay = ($i)**2;
            swat_note("sleep for $delay seconds before next try") if debug_mod12();
            sleep $delay; 

        }

            
        #swat_note($curl_runner);

        if ( $http_status < 400 and $http_status > 0 ) {

             swat_ok(1, tapout( $http_status, ['green'] )." / $try_i of $try ".$curl_runner_short);

        }elsif(ignore_http_err()){

            swat_ok(1, tapout( $http_status, ['red'] )." / $try_i of $try ".$curl_runner_short);
            swat_note(
                tapout( 
                    "server returned bad response, ".
                    "but we still continue due to ignore_http_err set to 1", 
                    ['blue on_black'] 
                )
            );

        }else{

            swat_ok(1, tapout( $http_status, ['red'] )." / $try_i of $try ".$curl_runner_short);

            swat_note("stderr:");

            open CURL_ERR, "$content_file.stderr" or die $!;
            while  ( my $i = <CURL_ERR>){
                chomp $i;
                swat_note($i);
            }
            close CURL_ERR;

            swat_note("http headers:");
            open CURL_HDR, "$content_file.hdr" or die $!;
            while  ( my $i = <CURL_HDR>){
                chomp $i;
                swat_note($i);
            }
            close CURL_HDR;

            swat_note("http body:");
            open CURL_RSP, "$content_file" or die $!;
            while  ( my $i = <CURL_RSP>){
                chomp $i;
                swat_note($i);
            }
            close CURL_RSP;

            swat_note("can't continue here due to unsuccessfull http status code");
            exit(1);
        }

        if (debug_mod12()) {
            swat_note(tapout( "http headers saved to $content_file.hdr", ['bright_blue'] ));
            swat_note(tapout( "body saved to $content_file", ['bright_blue'] ));
        }

    }


    open F, $content_file or die $!;
    my $body_str = '';
    $body_str.= $_ while <F>;
    close F;

    set_prop( body => $body_str );

    open F, "$content_file.hdr" or die $!;
    my $headers_str = '';
    $headers_str.= $_ while <F>;
    close F;

    set_prop( headers => $headers_str );

    if (debug_mod12()){
        my $debug_bytes = get_prop('debug_bytes');
        my $bshort = substr( $body_str, 0, $debug_bytes );
        if (length($bshort) < length($body_str)) {
             swat_note("body:\n$bshort ... ( output truncated to $debug_bytes bytes )"); 
        } else{
             swat_note("body:\n$body_str");
        }
    }


    set_prop( response_done => 1 );

}

sub header {

    
    my $project = get_prop('project');
    my $swat_module = get_prop('swat_module');
    my $hostname = get_prop('hostname');
    my $resource = get_prop('resource');
    my $http_method = get_prop('http_method');
    my $curl_cmd = get_prop('curl_cmd');
    my $debug = get_prop('debug');
    my $try_num = get_prop('try_num');
    my $ignore_http_err = get_prop('ignore_http_err');
    
    swat_note(1, "project: $project");
    swat_note(1, "hostname: $hostname");
    swat_note(1, "resource: $resource");
    swat_note(1, "http method: $http_method");
    swat_note(1,"swat module: $swat_module");
    swat_note(1, "debug: $debug");
    swat_note(1, "try num: $try_num");
    swat_note(1, "ignore http errors: $ignore_http_err");
    
}

sub generate_asserts {


    my $check_file = shift;

    header() if debug_mod2();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    return if http_method() eq 'META';

    eval {

        make_http_request();

        dsl()->{output} = headers().body();

        run_response_processor();

        dsl()->validate($check_file);
    };

    my $err = $@;

    for my $r ( @{dsl()->results}){
        swat_note($r->{message}) if $r->{type} eq 'debug';
        swat_ok($r->{status}, $r->{message}) if $r->{type} eq 'check_expression';

    }

    if ($err){
      $STATUS = -1;
      confess "parser error: $err" ;
    }

}

sub tapout {

    my $line  = shift;
    my $color = shift;

    if ($ENV{'swat_disable_color'}){
        $line;
    }else{
        colored($color,$line);
    }
}

sub print_meta {

    swat_note('@'.http_method());
    open META, resource_dir()."/meta.txt" or die $!;
    while (my $i = <META>){
        chomp $i;
        swat_note( tapout( "$i", ['yellow'] ));
    }
    close META;
    
}

sub swat_ok {

    my $status    = shift;
    my $message   = shift;

    if ($status) {
      print "OK ", $message, "\n";
    } else {
      print "FAIL ", $message, "\n";
      $STATUS = -1;
    }
}

sub swat_note {

    my $message   = shift;
    print $message, "\n";
}

END {

  if ($STATUS == 1){
    print "FINISHED. OK\n";
    exit(0);
  } elsif($STATUS == -1){
    print "FINISHED. FAIL\n";
    exit(1);
  }

}

1;


__END__

=pod


=encoding utf8


=head1 NAME

Swat


=head1 SYNOPSIS

Web testinfg framework consuming L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl>.


=head1 Documentation

See L<GH pages|https://github.com/melezhik/swat>.


=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 See also

=over

=item *

L<Sparrow|https://github.com/melezhik/sparrow> - Swat/Outthentic plugins manager


=item *

L<Outthentic|https://github.com/melezhik/outthentic> - Multipurpose scenarios framework.


=item *

L<Outthentic::DSL|https://github.com/melezhik/outthentic-dsl> - Outthentic::DSL specification.


=head1 Thanks

To God as the One Who inspires me to do my job!


