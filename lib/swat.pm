package swat;

our $VERSION = 'v0.1.22';

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
our ($is_swat_package);
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

    ok($st, "successful response from $http_meth $url$path") unless $ignore_http_err;

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

    diag("start swat for $url/$path | is swat package $is_swat_package");
    diag("swat version $swat::VERSION | debug $debug | try num $try_num | ignore http errors $ignore_http_err")
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



    ENTRY: for my $l (@ents){

        chomp $l;
        diag $l if $ENV{'swat_debug'};
        
        next ENTRY unless $l =~ /\S/; # skip blank lines

        if ($l=~ /^\s*#(.*)/) { # skip comments
            next ENTRY;
        }

        if ($l=~/^\s*code:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'code';
                 next ENTRY; # this is multiline, hold this until last line \ found
            }else{
                undef $ent_type;
                handle_code($code);
            }
        }elsif($l=~/^\s*generator:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'generator';
                 next ENTRY; # this is multiline, hold this until last line \ found
            }else{
                undef $ent_type;
                handle_generator($code);
            }
            
        }elsif($l=~/^\s*regexp:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $re=$1;
            undef $ent_type;
            handle_regexp($re);
        }elsif(defined($ent_type)){
            if ($l=~s/\\\s*$//) {
                push @ents_ok, $l;
                next ENTRY; # this is multiline, hold this until last line \ found
             }else {

                no strict 'refs';
                my $name = "handle_"; $name.=$ent_type;
                push @ents_ok, $l;
                &$name(\@ents_ok);

                undef $ent_type;
                @ents_ok = ();
    
            }
       }else{
            s{#.*}[], s{\s+$}[], s{^\s+}[] for $l;
            undef $ent_type;
            handle_plain($l);
        }
    }

    die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);

}

sub handle_code {

    my $code = shift;

    unless (ref $code){
        eval $code;
        die "code entry eval perl error, code:$code , error: $@" if $@;
        diag "handle_code OK. $code" if $ENV{'swat_debug'};
    } else {
        my $code_to_eval = join "\n", @$code;
        eval $code_to_eval;
        die "code entry eval error, code:$code_to_eval , error: $@" if $@;
        diag "handle_code OK. multiline. $code_to_eval" if $ENV{'swat_debug'};
    }
    
}

sub handle_generator {

    my $code = shift;

    unless (ref $code){
        my $arr_ref = eval $code;
        die "generator entry eval error, code:$code , error: $@" if $@;
        generate_asserts($arr_ref,0);
        diag "handle_code OK. $code" if $ENV{'swat_debug'};
    } else {
        my $code_to_eval = join "\n", @$code;
        my $arr_ref = eval $code_to_eval;
        generate_asserts($arr_ref,0);
        die "code entry eval error, code:$code_to_eval , error: $@" if $@;
        diag "handle_generator OK. multiline. $code_to_eval" if $ENV{'swat_debug'};
    }
    
}

sub handle_regexp {

    my $re = shift;
    my $message = "$http_meth $path returns data matching $re";
    check_line($re, 'regexp', $message);
    diag "handle_regexp OK. $re" if $ENV{'swat_debug'};
    
}

sub handle_plain {

    my $l = shift;
    my $message = "$http_meth $path returns $l";
    check_line($l, 'default', $message);
    diag "handle_plain OK. $l" if $ENV{'swat_debug'};   
}



1;

=head1 SYNOPSIS

SWAT is Simple Web Application Test ( Tool )

    $  swat examples/google/ google.ru
    /home/vagrant/.swat/reports/google.ru/00.t ..
    # start swat for google.ru/
    # try num 2
    ok 1 - successful response from GET google.ru/
    # data file: /home/vagrant/.swat/reports/google.ru/content.GET.txt
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

So this how I came up with the idea of swat. 


=head1 Key features

SWAT:

=over

=item *

is very pragmatic tool designed for job to be done in a fast and simple way

=item *

has simple and yet flexible DSL with low price mastering ( see my tutorial )

=item *

produces L<TAP|https://testanything.org/> output

=item *

leverages famous L<perl prove|http://search.cpan.org/perldoc?prove> and L<curl|http://curl.haxx.se/> utilities


=item *

has minimal dependency tree  and probably will run out of the box on most linux environments, provided that one has perl/bash/find/curl by hand ( which is true  for most cases )


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

    # define the content to return by URIs

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

It will find all the I<directories with get.txt or post.txt files inside> and "create" routes:

    GET hello/
    GET hello/world

When you are done with routes you need to set swat data.


=head2 Swat data

Swat data is DSL to describe/generate validation checks you apply to content returned from web application.

Swat data is stored in swat data files, named get.txt or post.txt. 


The validation process looks like:

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

Regexps are check expressions with the usage of <perl regular expressions> instead of plain strings checks.
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


    code: skip('next test is skipped',1) unless $ENV{'debug'} == 1  # conditionally skip this check
    HELLO SWAT


=head1 Generators

Swat entries generators is the way to I<create new swat entries on the fly>. Technically speaking it's just a perl code which should return an array reference:
Generators are very close to perl expressions ( generators code is also get evaled ) with maijor difference:

Value returned from generator's code should be  array reference. The array is passed back to swat parser so it can create new swat entries from it. 

Generators entries start with C<:generator> marker. Here is example:

    # Place this in swat data file
    generator: [ qw{ foo bar baz } ]

This generator will generate 3 swat entries:

    foo
    bar
    baz



As you can guess an array returned by generator should contain I<perl strings> representing swat entries, here is another example:
with generator producing still 3 swat entities 'foo', 'bar', 'baz' :


    # Place this in swat date file
    generator: my %d = { 'foo' => 'foo value', 'bar' => 'bar value' }; [ map  { ( "# $_", "$data{$_}" )  } keys %d  ] 


This generator will generate 3 swat entities:

    # foo
    foo value
    # bar
    bar value


There is no limit for you! Use any code you want with only requirement - it should return array reference. 
What about to validate web application content with sqlite database entries?

    # Place this in swat data file
    generator:                                                          \
    
    use DBI;                                                            \
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","","");   \
    my $sth = $dbh->prepare("SELECT name from users");                  \
    $sth->execute();                                                    \
    my $results = $sth->fetchall_arrayref;                              \
    
    [ map { $_->[0] } @${results} ]


As an example take a loot at examples/swat-generators-sqlite3 project


=head1 Multiline expressions

Sometimes code looks more readable when you split it on separate chunks. When swat parser meets  C<\> symbols it postpone entry execution and
add next line to buffer. This is repeated till no C<\> found on next. Finally swat execute I<"accumulated"> swat entity.

Here are some exmaples:

    # Place this in swat data file
    generator:                  \
    my %d = {                   \
        'foo' => 'foo value',   \
        'bar' => 'bar value',   \
        'baz' => 'baz value'    \
    };                          \
    [                                               \
        map  { ( "# $_", "$data{$_}" )  } keys %d   \
    ]                                               \

    # Place this in swat data file
    generator: [            \
            map {           \
            uc($_)          \
        } qw( foo bar baz ) \
    ]

    code:                                                       \
    if $ENV{'debug'} == 1  { # conditionally skip this check    \
        skip('next test is skipped',1)                          \ 
    } 
    HELLO SWAT

Multiline expressions are only allowable for perl expressions and generators 

=head1 Generators and Perl Expressions Scope

Swat uses I<perl string eval> when process generators and perl expressions code, be aware of this. 
Follow L<http://perldoc.perl.org/functions/eval.html> to get more on this.

=head1 PERL5LIB

Swat adds B<$project_root_directory/lib> to PERL5LIB , so this is convenient convenient to place here custom perl modules:


    example/my-app/lib/Foo/Bar/Baz.pm

As an example take a loot at examples/swat-generators-with-lib/ project


=head1 Anatomy of swat 

Once swat runs it goes through some steps to get job done. Here is description of such a steps executed in orders

=head2 Run iterator over swat data files

Swat iterator look for all files named get.txt or post.txt under project root directory. Actually this is simple bash find loop.

=head2 Parse swat data file

For every swat data file find by iterator parsing process starts. Swat parse data file line by line, at the end of such a process
I<a list of Test::More asserts> is generated. Finally asserts list and other input parameters are serialized as Test::More test scenario 
written into into proper *.t file.

=head2 Give it a run by prove

Once swat finish parsing all the swat data files there is a whole bunch of *.t files kept under a designated  temporary directory,
thus every swat route maps into Test::More test file with the list of asserts. Now all is ready for prove run. Internally `prove -r `
command is issued to run tests and generate TAP report. That is it.


Below is example hwo this looks like

=head3 project structure


    vagrant@Debian-jessie-amd64-netboot:~/projects/swat$ tree examples/anatomy/
    examples/anatomy/
    |----FOO
    |-----|----BARs
    |           |---- post.txt
    |--- FOOs
          |--- get.txt

    3 directories, 2 files

=head3 swat data files

    # /FOOs 
    FOO
    FOO2
    generator: | %w{ FOO3 FOO4 }|

    # /FOO/BARs
    BAR
    BAR2
    generator: | %w{ BAR3 BAR4 }|
    code: skip('skip next 2 tests',2);
    BAR5
    BAR6
    BAR7


=head3 Test::More Asserts list


    # /FOOs/0.t
    SKIP {
        ok($status, "successful response from GET $host/FOOs") 
        ok($status, "GET /FOOs returns FOO")
        ok($status, "GET /FOOs returns FOO2")
        ok($status, "GET /FOOs returns FOO3")
        ok($status, "GET /FOOs returns FOO4")
    }

    # /FOO/BARs0.t
    SKIP {
        ok($status, "successful response from POST $host/FOO/BARs") 
        ok($status, "POST /FOO/BARs returns BAR")
        ok($status, "POST /FOO/BARs returns BAR")
        ok($status, "POST /FOO/BARs returns BAR3")
        ok($status, "POST /FOO/BARs returns BAR4")
        skip('skip next 2 tests',2);
        ok($status, "POST /FOO/BARs returns BAR5")
        ok($status, "POST /FOO/BARs returns BAR6")
        ok($status, "POST /FOO/BARs returns BAR7")
    }

=head1 Hooks

Hooks are files containing any perl code to be `required` into the beginning of every swat test. There are 2 types of hooks:

=over 

=item *

B<project based hooks>

File located at C<$project_root_directory/hook.pm>. Project based hooks are applied for every route in project and
could be used for I<project initialization>. For example one could define generators here:

    # place this in hook.pm file:
    sub list1 { | %w{ foo bar baz } | }
    sub list2 { | %w{ red green blue } | }


    # now we could use it in swat data file
    generator:  list() 
    generator:  list2()    

=item *

B<route based hooks>

File located at C<$project_root_directory/$route_directory/hook.pm>. Routes based hook are route specific hooks and
could be used for I<route initialization>. For example one could define route specific generators here:

    # place this in hook.pm file:
    # notices that we could tell GET from POST http methods here:

    sub list1 { 

        my $list;

        if ($method eq 'GET') {
            $list = | %w{ GET_foo GET_bar GET_baz } | 
        }elsif($method eq 'POST'){
            $list = | %w{ POST_foo POST_bar POST_baz } | 
        }else{
            die "method $method is not supported"
        }
        $list;
    }


    # now we could use it in swat data file
    generator:  list() 



=back

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

Swat produces output in L<TAP|https://testanything.org/> format , that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this. Here is example for converting swat tests into JUNIT format

    swat $project_root $host --formatter TAP::Formatter::JUnit


See also L<"Prove settings"> section.

=head1 Command line tool

Swat is shipped as cpan package, once it's installed ( see L</"Install swat"> section ) you have a command line tool called B<swat>, this is usage info on it:

    swat <project_root_dir|swat_package> <host:port> <prove settings>

=over

=item *

B<host> - is base url for web application you run tests against, you also have to define swat routes, see DSL section.


=item *

B<project_dir> - is a project root directory

=item *

B<swat_package> - the name of swat package, see L</"Swat Packages"> section


=back


=head1 Prove settings

Swat utilize L<prove utility|http://search.cpan.org/perldoc?prove> to run tests, so all the swat options I<are passed as is to prove utility>.
Follow L<prove|http://search.cpan.org/perldoc?prove> utility documentation for variety of values you may set here.
Default value for prove options is  C<-v>. Here is another examples:

=over

=item *

C<-q -s> -  run tests in random and quite mode

=back


=head1 Swat Packages

Swat packages is portable archives of swat tests. It's easy to create your own swat packages and share with other. 

This is mini how-to on creating swat packages:

=head2 Create swat package

Let's imagine you've got ready swat tests you want to distribute. First of all you need to create _tar.gz archive_ of
swat project root directory:

    tar -zcf $project_root_dir.tar.gz project_root_dir

For example for project ./examples/google 

    cd ./examples/
    tar -zcf google.tar.gz ./google

=head2 Upload package to swat repository

Swat repository might be  _ANY_ web server. One should upload archive into server.
Let's say we have nginx server. The example below is for debian:

    # install nginx:
    sudo apt-get install nginx

    # copy swat distributive:
    sudo cp google.tar.gz /var/www/html/

    # check for archive availability over web server:
    curl -s 127.0.0.1/google.tar.gz -D - -o /dev/null  | head  -n 1
    HTTP/1.1 200 OK

You swat repository with nginx swat package uploaded is ready!

=head2 Install swat package

Swat comes with utility called B<swatman> to manage swat packages. 
First of all one need to setup swat repository:

    echo "swat_repo=127.0.0.1" >> ~/swat.ini

Then install package

    swatman install google

=head2 Run swat tests

Once swat package is installed into your system you may give it a run:

    swat google google.ru

=head1 Debugging

set C<swat_debug> environmental variable to 1


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

=item *

tar

=back

=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Swat Project Home Page

https://github.com/melezhik/swat


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
