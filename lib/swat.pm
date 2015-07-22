package swat;

our $VERSION = 'v0.1.17';

use base 'Exporter'; 

our @EXPORT = qw{version};

sub version {
    print $VERSION, "\n"
}


1;

package main;
use strict;
use Test::More;

our $HTTP_RESPONSE;
our ($curl_cmd, $content_file);
our ($url, $path, $http_meth); 
our ($debug, $ignore_http_err, $try_num, $debug_bytes);
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

    diag `head -c $debug_bytes $content_file` if $debug;

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
    diag("debug $debug | try num $try_num | ignore http errors $ignore_http_err")
}

sub generate_asserts {

    my $filepath_or_array_ref = shift;
    my $write_header = shift;

    header() if $write_header;

    my @ents;
    my @ents_ok;
    my $ent_type;

    if ( ref($filepath_or_array_ref) eq 'ARRAY') {
        @ents = @$filepath_or_array_ref
    }else{
        return unless $filepath_or_array_ref;
        open my $fh, $filepath_or_array_ref or die $!;
        while (my $l = <$fh>){
            push @ents, $l
        }
        close $fh;
    }



    ENTITY: for my $l (@ents){

        chomp $l;
        warn $l if $ENV{'swat_debug'};
        
        next ENTITY unless $l =~ /\S/; # skip blank lines

        if ($l=~ /^\s*#(.*)/) { # skip comments
            next ENTITY;
        }

        if ($l=~/^\s*code:\s*(.*)/){
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'code';
                 next ENTITY; # this is multiline, hold this until last line found
            }else{
                undef $ent_type;
                handle_code($code);
            }
        }elsif($l=~/^\s*generator:\s*(.*)/){
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'generator';
                 next ENTITY; # this is multiline, hold this until last line found
            }else{
                undef $ent_type;
                handle_generator($code);
            }
            
        }elsif($l=~/^\s*regexp:\s*(.*)/){
            my $re=$1;
            if ($re=~s/\\\s*$//){ 
                 push @ents_ok, $re;
                 $ent_type = 'regexp';
                 next ENTITY; # this is multiline, hold this until last line found
            }else{
                undef $ent_type;
                handle_regexp($re);
                
            }
        }elsif(defined($ent_type)){
            if ($l=~s/\\\s*$//) {
                push @ents_ok, $l;
                next ENTITY; # this is multiline, hold this until last line found
             }else {

                no strict 'refs';
                my $name = "handle_"; $name.=$ent_type;
                push @ents_ok, $l;
                &$name(join "", @ents_ok);

                undef $ent_type;
                @ents_ok = ();
    
            }
       }else{
            s{#.*}[], s{\s+$}[], s{^\s+}[] for $l;
            if ($l=~s{\\\s*$}[]){ 
                 push @ents_ok, $l;
                 $ent_type = 'expected_val';
                 warn "push to multiline OK. $ent_type. $l" if $ENV{'swat_debug'};
                 next ENTITY; # this is multiline, hold this until last line found
            }else{
                undef $ent_type;
                handle_expected_val($l);
                
            }
        }
    }


}

sub handle_code {

    my $code = shift;
    eval $code;
    die "code entity eval perl error, code:$code , error: $@" if $@;
    warn "handle_code OK. $code" if $ENV{'swat_debug'};
    
}

sub handle_generator {

    my $code = shift;
    my $arr_ref = eval $code;
    die "generator entity perl eval error, code:$code , error: $@"  if $@;
    generate_asserts($arr_ref,0);
    warn "handle_generator OK. $code" if $ENV{'swat_debug'};
    
}

sub handle_regexp {

    my $re = shift;
    my $message = "$http_meth $path returns data matching $re";
    check_line($re, 'regexp', $message);
    warn "handle_regexp OK. $re" if $ENV{'swat_debug'};
    
}

sub handle_expected_val {

    my $l = shift;
    my $message = "$http_meth $path returns $l";
    check_line($l, 'default', $message);
    warn "handle_expected_val OK. $l" if $ENV{'swat_debug'};   
}



1;

=head1 ABSTRACT

SWAT is Simple Web Application Test ( Tool )

=head1 SYNOPSIS

SWAT is Simple Web Application Test ( Tool )

    $  swat examples/google/ google.ru
    /home/vagrant/.swat/reports/google.ru/00.t ..
    # start swat for google.ru//
    # try num 2
    ok 1 - successfull response from GET google.ru/
    # data file: /home/vagrant/.swat/reports/google.ru///content.GET.txt
    ok 2 - GET / returns 200 OK
    ok 3 - GET / returns Google
    1..3
    ok
    All tests successful.
    Files=1, Tests=3, 12 wallclock secs ( 0.00 usr  0.00 sys +  0.02 cusr  0.00 csys =  0.02 CPU)
    Result: PASS


=head1 WHY

I know there are a lot of tests tool and frameworks, but let me  briefly tell I<why> I created swat.
As devops I update a dozens of web application weekly, sometimes I just have I<no time> sitting and wait 
while dev guys or QA team ensure that deploy is fine and nothing breaks on the road. 
So I need a B<tool to run smoke tests against web applications>. 
Not tool only, but the way to B<create such a tests from the scratch in way easy and fast enough>. 

So this how I came up with the idea of swat. If I was a marketing guy I'd say that swat:

=over

=item *

is easy to use and flexible tool to run smoke tests against web applications


=item *

is L<curl|http://curl.haxx.se/> powered and L<TAP|https://testanything.org/> compatible

=item *

leverages famous L<prove|http://search.cpan.org/perldoc?prove> utility


=item *

has minimal dependency tree  and probably will run out of the box on most linux environments, provided that one has perl/bash/find/curl by hand ( which is true  for most cases )

=item *

has a simple and yet powerful DSL allow you to both run simple tests ( 200 OK ) or complicated ones ( using curl api and perl functions calls )

=item *

is daily it/devops/dev helper with low price mastering ( see my tutorial )

=item *

and yes ... swat is fun :)


=back


=head1 Tutorial


=head2 Install swat


=head3 stable release

    sudo cpan install swat

=head3 developer release

    # developer release might be untested and unstable
    sudo cpanm --mirror-only --mirror https://stratopan.com/melezhik/swat-release/master swat


Once swat is installed you have B<swat> command line tool to run swat tests, but before do this you need to create them.


=head2 Create tests

    mkdir  my-app/ # create a project root directory to contain tests

    # define http URIs application should response to

    mkdir -p my-app/hello # GET /hello
    mkdir -p my-app/hello/world # GET /hello/world

    # define the content the expected to return by requested URIs

    echo 200 OK >> my-app/hello/get.txt
    echo 200 OK >> my-app/hello/world/get.txt

    echo 'This is hello' >> my-app/hello/get.txt
    echo 'This is hello world' >> my-app/hello/world/get.txt


=head2 Run tests

    swat ./my-app http://127.0.0.1

=head1 DSL

Swat DSL consists of 2 parts. Routes and Swat Data.

=head2 Routes

Routes are http resources a tested web application should have.

Swat utilize file system to get know about routes. Let we have a following project layout:

    example/my-app/
    example/my-app/hello/
    example/my-app/hello/get.txt
    example/my-app/hello/world/get.txt

When you give swat a run

    swat example/my-app 127.0.0.1

It will find all the I<directories with get.txt|post.txt files inside> and "create" routes:

    GET hello/
    GET hello/world

When you are done with routes you need to set swat data.


=head2 Swat data

Swat data is DSL to describe/generate validation checks you apply to content returned from web application.
Swat data is stored in swat data files, named get.txt or post.txt. 



The process of validation looks like:

=over

=item *

Swat recursively find files named B<get.txt> or B<post.txt> in the project root directory to get swat data.

=item *

Swat parse swat data file and I<execute> entries found. At the end of this process swat creates a I<final check list> with 
L</"Check Expressions">.

=item *

For every route swat makes http requests to web application and store content into text file 

=item *

Every line of text file is validated by every item in a I<final check list>


=back 

I<Objects> found in test data file are called I<swat entries>. There are I<3 basic type> of swat entries:

=over

=item *

Check Expressions


=item *

Comments


=item *

Perl Expressions and Generators


=back


=head3 Check Expressions

This is most usable type of entries you  may define at swat data file. I<It's just a string should be returned> when swat request a given URI. Here are examples:

    200 OK
    Hello World
    <head><title>Hello World</title></head>


Using regexps

Regexps are check expresions with the usage of <perl regular expressions> instead of plain strings checks.
Everything started with C<regexp:> marker would be treated as perl regular expression.

    # this is example of regexp check
    regexp: App Version Number: (\d+\.\d+\.\d+)


=head3 Comments

Comments entries are lines started with C<#> symbol, swat will ignore comments when parse swat data file. Here are examples.

    # this http status is expected
    200 OK
    Hello World # this string should be in the response
    <head><title>Hello World</title></head> # and it should be proper html code


=head3 Perl Expressions

Perl expressions are just a pieces of perl code to I<get evaled> by swat when parsing test data files.

Everything started with C<code:> marker would be treated by swat as perl code to execute.
There are a I<lot of possibilities>! Please follow L<Test::More|search.cpan.org/perldoc/Test::More> documentation to get more info about useful function you may call here.

    code: skip('next test is skipped',1) # skip next check forever
    HELLO WORLD


    code: skip('next test is skipped',1) unless $ENV{'debug'} == 1  # confitionally skip this check
    HELLO SWAT


=head1 Generators

Swat entities generators is the way to I<create new swat entries on the fly>. Technically specaking it's just a perl code which should return an array reference:
Generators are very close to perl expressions ( generators code is alos get evaled ) with maijor difference:

Value returned from generator's code should be  array reference. The array is passed back to swat parser so it can create new swat entries from it. 

Generators entries start with C<:generator> marker. Here is example:

    # Place this in swat pattern file
    generator: [ qw{ foo bar baz } ]

This generator will generate 3 swat entities:

    foo
    bar
    baz



As you can guess an array returned by generator should contain I<perl strings> representing swat entries, here is another example:
with generator producing still 3 swat entites 'foo', 'bar', 'baz' :


    # Place this in swat pattern file
    generator: my %d = { 'foo' => 'foo value', 'bar' => 'bar value', 'baz' => 'baz value'  }; [ map  { ( "# $_", "$data{$_}" )  } keys %d  ] 


This generator will generate 3 swat entities:

    # foo
    foo value
    # baz
    baz value
    # bar
    bar value


There is no limit for you! Use any code you want with only requiment - it should return array reference. 
What about to validate web application content with sqlite database entries?

    # Place this in swat pattern file
    generator: \
    
    use DBI; \
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","",""); \
    my $sth = $dbh->prepare("SELECT name from users"); \
    $sth->execute(); \
    my $results = $sth->fetchall_arrayref; \
    
    [ map { $_->[0] } @${results} ]

See examples/swat-generators-sqlite3 for working example


=head1 Multiline expressions

Sometimes code looks more readable when you split it on separate chunks. When swat parser meets  C<\> symbols it postpone entity execution and
and next line to buffer. Once no C<\> occured swat parser I<execute> swat entity.

Here are some exmaples:

    # Place this in swat pattern file
    generator:                  \
    my %d = {                   \
        'foo' => 'foo value',   \
        'bar' => 'bar value',   \
        'baz' => 'baz value'    \
    };                          \
    [                                               \
        map  { ( "# $_", "$data{$_}" )  } keys %d   \
    ]                                               \

    # Place this in swat pattern file
    generator: [            \
            map {           \
            uc($_)          \
        } qw( foo bar baz ) \
    ]

    code:                                                       \
    if $ENV{'debug'} == 1  { # confitionally skip this check    \
        skip('next test is skipped',1)                          \ 
    } 
    HELLO SWAT

Multiline expressions are only allowable for perl expressions and generators 

=head1 Post requests

Name swat data file as post.txt to make http POST requests.

    echo 200 OK >> my-app/hello/post.txt
    echo 200 OK >> my-app/hello/world/post.txt

You may use curl_params setting ( follow L</"Swat Settings"> section for details ) to define post data, there are some examples:

=over

=item *

C<-d> - Post data sending by html form submit.


     # Place this in swat.ini file or sets as env variable:
     curl_params='-d name=daniel -d skill=lousy'


=item *

C<--data-binary> - Post data sending as is.


     # Place this in swat.ini file or sets as env variable:
     curl_params=`echo -E "--data-binary '{\"name\":\"alex\",\"last_name\":\"melezhik\"}'"`
     curl_params="${curl_params} -H 'Content-Type: application/json'"


=back





=head1 Generators and Perl Expressions Scope

Swat call I<perl string eval> when process generators and perl expressions entities, be aware of this. 
Follow L<http://perldoc.perl.org/functions/eval.html> to get more on this.


=head1 Swat Settings

Swat comes with settings defined in two contexts:

=over

=item *

Environmental Variables


=item *

swat.ini files


=back


=head2 Environmental Variables

Defining a proper environment variables will provide swat settings.

=over

=item *

C<debug> - set to C<1> if you want to see some debug information in output, default value is C<0>


=item *

C<debug_bytes> - number of bytes of http response  to be dumped out when debug is on. default value is C<500>


=item *

C<ignore_http_err> - ignore http errors, if this parameters is off (set to C<1>) returned  I<error http codes> will not result in test fails, 
useful when one need to test something with response differ from  2**,3** http codes. Default value is C<0>


=item *

C<try_num> - number of http requests  attempts before give it up ( useless for resources with slow response  ), default value is C<2>


=item *

C<curl_params> - additional curl parameters being add to http requests, default value is C<"">, follow curl documentation for variety of values for this


=item *

C<curl_connec_timeout> - follow curl documentation


=item *

C<curl_max_time> - follow curl documentation


=item *

C<port>  - http port of tested host, default value is C<80>


=back


=head2 Swat.ini files

Swat checks files named C<swat.ini> in the following directories

=over

=item *

B<~/swat.ini>

=item *

B<$project_root_directory/swat.ini>

=item *

B<$route_directory/swat.ini>

=back

Here are examples of locations of swat.ini files:


     ~/swat.ini # home directory swat.ini file
     my-app/swat.ini # project_root directory swat.ini file
     my-app/hello/get.txt
     my-app/hello/swat.ini # route directory swat.ini file ( route hello )
     my-app/hello/world/get.txt
     my-app/hello/world/swat.ini # route directory swat.ini file ( route hello/world )


Once file exists at any location swat simply B<bash sources it> to apply settings.

Thus swat.ini file should be bash file with swat variables definitions. Here is example:

    # the content of swat.ini file:
    curl_params="-H 'Content-Type: text/html'"
    debug=1


=head2 Settings priority table

Here is the list of settings/contexts  in priority ascending order:

    | context                 | location                | priority  level |
    | ------------------------|------------------------ | --------------- |
    | swat.ini file           | ~/swat.ini              |               1 |
    | environmental variables | ---                     |               2 |
    | swat.ini file           | project root directory  |               3 |
    | swat.ini file           | route directory         |               4 |


Swat processes settings I<in order>. For every route found swat:

=over

=item *

Clear all settings

=item *

Apply settings from environmental variables ( if any given )

=item *

Apply settings from swat.ini file in home directory ( if any given )


=item *

Apply settings from swat.ini file in project root directory ( if any given )

=item *

And finally apply settings from swat.ini file in route directory ( if any given )

=back


=head1 TAP

Swat produce output in L<TAP|https://testanything.org/> format , that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this. Here is example for converting swat tests into JUNIT format

    swat $project_root $host --formatter TAP::Formatter::JUnit


See also L<"Prove settings"> section.

=head1 Command line tool

Swat is shipped as cpan package, once it's installed ( see L</"Install swat"> section ) you have a command line tool called B<swat>, this is usage info on it:

    swat project_dir URL <prove settings>

=over

=item *

B<URL> - is base url for web application you run tests against, you need defined routes which will be requested against URL, see DSL section.


=item *

B<project_dir> - is a project root directory


=back


=head2 Prove settings

Swat utilize L<prove utility|http://search.cpan.org/perldoc?prove> to run tests, so all the swat options I<are passed as is to prove utility>.
Follow L<prove|http://search.cpan.org/perldoc?prove> utility documentation for variety of values you may set here.
Default value for prove options is  C<-v>. Here is another examples:

=over

=item *

C<-q -s> -  run tests in random and quite mode

=back


=head1 Examples

./examples directory contains examples of swat tests for different cases. Follow README.md files for details.


=head1 Dependencies

Not that many :)

=over

=item *

perl 

=item *

curl 

=item *

bash

=item *

find

=item *

head

=back

=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Thanks

To the authors of ( see list ) without who swat would not appear to light

=over

=item *

perl

=item *

curl

=item *

TAP

=item *

Test::More

=item *

prove

=back
