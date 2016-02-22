package swat;

our $VERSION = '0.1.84';

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

use Test::More;
use swat::story;

use Carp;
use Config::Tiny;

my $config;

sub config {

    unless ($config){
        $config = Config::Tiny->read(
            get_prop('ini_file_path') || $ENV{'suite_ini_file'} || 'suite.ini'
            ) or confess "can't read ini file: $!";
    }
    return $config;
}

sub execute_with_retry {

    my $cmd = shift;
    my $try = shift || 1;

    for my $i (1..$try){
        note("\nexecute cmd: $cmd\n attempt number: $i") if debug_mod2();
        return $i if system($cmd) == 0;
        sleep $i**2;
    }

    return

}

sub make_http_request {

    return if get_prop('response_done');

    my ($fh, $content_file) = tempfile( DIR => get_prop('test_root_dir') );

    if (get_prop('response') and @{get_prop('response')} ){

        ok(1,'server response is spoofed');

        open F, ">", $content_file or die $!;
        print F ( join "\n", @{get_prop('response')});
        close F;

        open F, ">", "$content_file.stderr" or die $!;
        close F;

        open F, ">", "$content_file.hdr" or die $!;
        close F;

        note "response saved to $content_file";

    }else{

        my $curl_cmd = get_prop('curl_cmd');
        my $hostname = get_prop('hostname');
        my $resource = get_prop('resource');
        my $http_method = get_prop('http_method'); 

        $curl_cmd.=' -f'  unless ignore_http_err();

        my $curl_runner = "$curl_cmd -D $content_file.hdr -o $content_file --stderr $content_file.stderr '$hostname$resource'";
        my $curl_runner_short = "$curl_cmd -D - '$hostname$resource'";

        note('trying ... '.$curl_runner_short) ; # if debug_mod12();

        my $st = execute_with_retry("$curl_runner && test -f $content_file.hdr", get_prop('try_num'));

        if ($st) {

            ok(1, "server returned successful response");

        }elsif(ignore_http_err()){

            ok(1, "server returned bad response, we still continue due to ignore_http_err set to 1");

        }else{

            ok(0, "server returned successful response");

            note "stderr:";
            open CURL_ERR, "$content_file.stderr" or die $!;
            while  ( my $i = <CURL_ERR>){
                chomp $i;
                note($i);
            }
            close CURL_ERR;

            note "http headers:";
            open CURL_HDR, "$content_file.hdr" or die $!;
            while  ( my $i = <CURL_HDR>){
                chomp $i;
                note($i);
            }
            close CURL_HDR;

            note "http body:";
            open CURL_RSP, "$content_file" or die $!;
            while  ( my $i = <CURL_RSP>){
                chomp $i;
                note($i);
            }
            close CURL_RSP;

            note("can't continue here due to unsuccessfull http status code");
            exit(1);
        }

        note "http headers saved to $content_file.hdr" if debug_mod12();
        note "body saved to $content_file" if debug_mod12();

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
             note("body:\n$bshort ... ( output truncated to $debug_bytes bytes )"); 
        } else{
             note("body:\n$body_str");
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
    
    ok(1, "project: $project");
    ok(1, "hostname: $hostname");
    ok(1, "resource: $resource");
    ok(1, "http method: $http_method");
    ok(1,"swat module: $swat_module");
    ok(1, "debug: $debug");
    ok(1, "try num: $try_num");
    ok(1, "ignore http errors: $ignore_http_err");
    
}

sub generate_asserts {


    my $check_file = shift;

    header() if debug_mod12();

    dsl()->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    make_http_request();

    dsl()->{output} = headers().body();

    run_response_processor();

    eval {
        dsl()->validate($check_file);
    };

    my $err = $@;

    for my $r ( @{dsl()->results}){
        note($r->{message}) if $r->{type} eq 'debug';
        ok($r->{status}, $r->{message}) if $r->{type} eq 'check_expression';

    }

    confess "parser error: $err" if $err;

}

1;


__END__

=pod


=encoding utf8


=head1 NAME

Swat


=head1 SYNOPSIS

Rapid web tests development.


=head1 Description

=over

=item *

Swat is a powerful and yet simple and flexible tool for rapid automated web tests development.



=item *

Swat is a web application oriented test framework, this means that it equips you with all you need for a web test development
and yet it's not burdened by many other "generic" things that you probably won't ever use.



=item *

Swat does not carry all heavy load on it's shoulders, with the help of it's "elder brother" - curl
swat makes a http requests in a smart way. This means if you know and love curl swat might be easy way to go.
Swat just passes all curl related parameter as is to curl and let curl do it's job.



=item *

Swat is a text oriented tool, for good or for bad it does not provide any level of http DOM or xpath hacking ( I<but> see  L<process http responses|#process-http-responses> section ). It does not even try to decouple http headers from a body. Actually I<it just returns you a text> where you can find and grep in old good unix way. Does this sound suspiciously simple? I believe that most of things could be tested in a simple way.



=item *

Swat is extendable by writing custom perl code, this is where you may add desired complexity to your test stories. Check out swat API for details. 



=item *

And finally swat relies on prove as internal test runner - this has many, many good results:

=over

=item *

swat transparently passes all it's arguments to prove which makes it simple to adjust swat runner behavior in a prove way



=item *

swat tests might be easily embedded as unit tests into a cpan distributions.



=item *

test reports are emitted in a TAP format which is portable and easy to read.



=back



=back

Ok, now I hope you are ready to dive into swat tutorial! :)


=head1 Install

    $ sudo apt-get install curl
    $ sudo cpanm swat

Or install from source:

    # could be useful for contributors and developers
    
    perl Makefile.PL
    make
    make test
    make install


=head1 Write your swat story

Swat test stories always answers on 2 type of questions:

=over

=item *

I<What kind of> http request should be sent.


=item *

I<What kind of> http response should be received.


=back

As swat is a web test oriented tool it deals with some http related stuff as:

=over

=item *

http methods


=item *

http resources


=item *

http responses


=back

Swat leverages Unix file system to build an I<analogy> for these things:


=head2 HTTP resources

I<HTTP resource is just a directory>. You have to create a directory to define a http resource:

    mkdir foo/
    mkdir -p bar/baz

This code defines two http resources for your application - '/foo/' and '/bar/baz'


=head2 HTTP methods

I<HTTP method is just a file>. You have to create a file to define a http method.

    touch foo/get.txt
    touch foo/put.txt
    touch bar/baz/post.txt

Obviously `http methods' files should be located at `http resource' directories.

The list below describes two http resources ( /foo, /bar/baz ) and three http methods for these resources ( GET, PUT, DELETE ):

    * GET  /foo
    * PUT  /foo
    * POST /bar/baz

Here is the list of I<predefined> file names for a http methods files:

    get.txt      --> GET      method
    post.txt     --> POST     method
    put.txt      --> PUT      method
    delete.txt   --> DELETE   method


=head1 Hostname / IP Address

You need to define hostname or ip address to send request to. 

Just write it up to a special file  called `host' and swat will use it.

    echo 'app.local' > host

As swat makes http requests with the help of curl, the host name should be compliant with curl requirements, this
for example means you may define a http schema or port here:

    echo 'https://app.local' >> host
    echo 'app.local:8080' >> host


=head2 HTTP Response

Swat makes request to a given http resources with a given http methods and then validates a response.
Swat does this with the help so called I<check lists>, check lists are defined at `http methods' files.

Check list is just a list of expressions a response should match. It might be a set of plain strings or regular expressions:

    echo 200 OK > foo/get.txt
    echo 'Hello I am foo' >> foo/get.txt

The code above defines two checks for response from `GET /foo':

=over

=item *

it should contain "200 OK"


=item *

it should contain "Hello I am foo"


=back

You may add some regular expressions checks as well:

    # for example check if we got something like 'date':
    echo 'regexp: \d\d\d\d-\d\d-\d\d' >> foo/get.txt


=head1 Bringing all together

All these things like http method, http resource and check list build up an essential swat entity called a I<swat story>.

Swat story is a very simple test plan, which could be expressed in a cucumber language as follows:

    Given I have web application 'http://my.cool.app:80'
    And I have http method 'GET'
    And make http request 'GET /foo'
    Then I should have response matches '200 OK'
    And I should have response matches 'Hello I am foo'
    And I should have response matches '\d\d\d\d-\d\d-\d\d'

From the file system point of view swat story is a:

=over

=item *

http method - the `http method' file


=item *

http resource - the directory where `http method file' located in


=item *

check list - the content of a `http method' file


=back


=head2 Swat Project

Swat project is a bunch of a related swat stories kept under a single directory. This directory is called I<project root directory>.
The project root directory name could be any, swat just searches for swat story files in it and then "execute" found stories.
See L<swat runner workflow|#swat-runner-workflow> section for full explanation of this process.

This is an example swat project layout:

    $ tree my/swat/project
      my/swat/project
      |--- host
      |----FOO
      |-----|----BAR
      |           |---- post.txt
      |--- FOO
            |--- get.txt
    
    3 directories, 3 files

When you ask swat to execute swat stories you have to point it a project root directory or `cd' to it and run swat without arguments:

    swat my/swat/project
    
    # or
    
    cd my/swat/project && swat

Note, that project root directory path will be removed from http resources paths during execution:

=over

=item *

GET  /FOO


=item *

POST /FOO/BAR


=back

Also notice that if you pass first argument ( which is project root directory ) to swat client, then the second argument I<could be> a hostname ( in case you don't want to use one defined at host file or you do not have one ):

      # inside project root directory 
      swat ./ 127.0.0.1
    
      # outside of project root directory 
      swat /path/to/project/root/directory/ 127.0.0.1

Follow L<swat client|#swat-client> section for full explanation of swat client command line API.


=head1 Swat check lists

Swat check lists complies L<Outthentic DSL|https://github.com/melezhik/outthentic-dsl> format.

There are lot of possibilities here!

( For full explanation of outthentic DSL please follow L<documentation|https://github.com/melezhik/outthentic-dsl>. )

A few examples:

=over

=item *

plain string checks


=back

Often all you need is to ensure that http response has some strings in:

    # http response
    200 OK
    HELLO
    HELLO WORLD
    
    
    # check list
    200 OK
    HELLO
    
    # swat output
    OK - output matches '200 OK'
    OK - output matches 'HELLO'

=over

=item *

regular expressions


=back

You may use regular expressions as well:

    # http response
    My birth day is: 1977-04-16
    
    
    # check list
    regexp: \d\d\d\d-\d\d-\d\d
    
    
    # swat output
    OK - output matches /\d\d\d\d-\d\d-\d\d/

Follow L<https://github.com/melezhik/outthentic-dsl#check-expressions|https://github.com/melezhik/outthentic-dsl#check-expressions> to know more.

=over

=item *

generators


=back

Yes you may generate new check list on run time:

    # original check list
       
    Say
    HELLO
       
    # this generator creates 3 new check expressions:
       
    generator: [ qw{ say hello again } ]
       
    # final check list:
       
    Say
    HELLO
    say
    hello
    again

Follow L<https://github.com/melezhik/outthentic-dsl#generators|https://github.com/melezhik/outthentic-dsl#generators> to know more.

=over

=item *

inline perl code


=back

What about inline arbitrary perl code? Well, it's easy!

    # check list
    regexp: number: (\d+)
    validator: [ ( capture()->[0] '>=' 0 ), 'got none zero number') ];

Follow L<https://github.com/melezhik/outthentic-dsl#validators|https://github.com/melezhik/outthentic-dsl#validators> to know more.

=over

=item *

text blocks


=back

Need to validate that some lines goes in response successively ?

        # http response
    
        this string followed by
        that string followed by
        another one string
        with that string
        at the very end.
    
    
        # check list
        # this text block
        # consists of 5 strings
        # goes consequentially
        # line by line:
    
        begin:
            # plain strings
            this string followed by
            that string followed by
            another one string
            # regexps patterns:
        regexp: with (this|that) \S+
            # and the last one in a block
            at the very end
        end:

Follow L<https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks|https://github.com/melezhik/outthentic-dsl#comments-blank-lines-and-text-blocks>
to know more.


=head1 Swat ini files

Every swat story comes with some settings you may define to adjust swat behavior.
These type of settings could be defined at swat ini files.

Swat ini files are file called "swat.ini" and located at `resources' directory:

     foo/bar/get.txt
     foo/bar/swat.ini

The content of swat ini file is the list of variables definitions in bash format:

    $name=value

As swat ini files is bash scripts you may use bash expressions here:

    if [ some condition ]; then
        $name=value
    fi

Following is the list of swat variables you may define at swat ini files, it could be divided on two groups:

=over

=item *

B<swat variables>


=item *

B<curl parameters>


=back


=head2 swat variables

Swat variables define swat  basic configuration, like logging mode, prove runner settings, etc. Here is the list:

=over

=item *

C<skip_story> - skip story, default value is `0'. Set to `1' if you want skip store for some reasons.


=back

For example:

    # swat.ini
    # assume that we set profile variable somewhere else
    # 
    
    if test "${profile}" = 'production'; then
        skip_story=1 # we don't want this one for production
    fi

=over

=item *

C<ignore_http_err> - run curl with or without `-f' flag

=over

=item *

swat runs curl command and then checks exit code returned


=item *

if not successful exit code returns a proper swat assert fails


=item *

by default ignore_http_err is set to 0 which make curl run with `-f' flag, for not successful http responses ( bad http status code )
  this means error on swat side ( see previous point )


=item *

settings ignore_http_err to `1' make curl run curl without `-f' flag which result in even non successful http responses are not treated as errors 
( a proper swat assert does not fail )


=back



=item *

C<prove_options> - prove options to be passed to prove runner,  default value is `-v`. See [Prove settings](#prove-settings) section.



=item *

C<debug> - enable swat debugging

=over

=item *

Increasing debug value results in more low level information appeared at output



=item *

Default value is 0, which means no debugging



=item *

Possible values: 0,1,2,3



=back



=item *

C<debug_bytes> - number of bytes of http response to be dumped out when debug is on. default value is `500'.



=item *

C<match_l> - in TAP output truncate matching strings to {match_l} bytes;  default value is `40'.



=item *

C<swat_purge_cache> - remove swat cache files at the end of test run; default value is `\0' ( do not remove ).



=back


=head2 curl parameters

Curl parameters relates to curl client. Here is the list:

=over

=item *

C<try_num> - a number of requests to be send in case curl get unsuccessful return,  similar to curl `--retry' , default value is `2'.



=item *

C<curl_params> - additional curl parameters being add to http requests, default value is C<"">.



=back

Here are some examples:

    # -d curl parameter
    curl_params='-d name=daniel -d skill=lousy' # post data sending via form submit.
    
    # --data-binary curl parameter
    curl_params=`echo -E "--data-binary '{\"name\":\"alex\",\"last_name\":\"melezhik\"}'"`
    
    # set http header
    curl_params="-H 'Content-Type: application/json'"

Follow curl documentation to get more examples.

=over

=item *

C<curl_connect_timeout> - maximum time in seconds that you allow the connection to the server to take, follow curl documentation for full explanation.



=item *

C<curl_max_time> - maximum time in seconds that you allow the whole operation to take, follow curl documentation for full explanation.



=item *

C<port>  - http port of tested host, default value is `80'.



=back


=head2 other variables

This is the list of helpful variables  you may use in swat ini files:

=over

=item *

$resource


=item *

$resource_dir


=item *

$test_root_dir


=item *

$hostname


=item *

$http_method


=back


=head2 Alternative swat ini files locations

Swat try to find swat ini files at these locations ( listed in order )

=over

=item *

B<~/swat.ini> * home directory



=item *

B<$project_root_directory/swat.ini> -  project root directory



=back


=head2 Settings priority table

This table describes all possible locations for swat ini files. Swat try to find swat ini files in order:

    | location                                  | order N     |
    | --------------------------------------------------------|
    | ~/swat.ini                                | 1           |
    | `project_root_directory'/swat.ini         | 2           |
    | `http resource' directory/swat.ini file   | 3           |
    | environment variables                     | 4           |

In case the same variable is defined more than once at swat ini files with different locations, the file loaded last win:

    curl_params="-H 'Foo: Bar'" # in a ~/swat.ini
    curl_params="-H 'Bar: Baz'" # in a project_root_directory/swat.ini
    
    # actual curl_params value:
    "-H 'Bar: Baz'"

If you want concatenation mode use name="$name value" expression:

    curl_params="-H 'Foo: Bar'" # in a ~/swat.ini
    curl_params="$curl_params -H 'Bar: Baz'" # in a project_root_directory/swat.ini
    
    # actual curl_params value:
    "-H 'Foo: Bar' -H 'Bar: Baz'"

In case you need provide default value for some variable use name=${name default_value} expression:

    # port will be set 80 unless it's not set somewhere else
    port=${port:=80} # in a ~/swat.ini


=head1 Hooks

Hooks are extension points to hack into swat runtime phase. It's just files with perl code gets executed in the beginning of swat story.
You should named your hook file as `hook.pm' and place it into `resource' directory:

    # foo/hook.pm
    diag "hello, I am swat hook";
    sub red_green_blue_generator { [ qw /red green blue/ ] }
       
    
    # foo/get.txt
    generator: red_green_blue_generator()

There are lot of reasons why you might need a hooks. To say a few:

=over

=item *

define swat generators


=item *

redefine http responses


=item *

process http responses 


=item *

redefine http resources


=item *

call downstream stories


=item *

other custom code


=back


=head1 Hooks API

Swat hooks API provides several functions to change swat story at runtime


=head2 Redefine http responses

I<set_response(STRING)>

Using set_response means that you never make a real request to a web application, but instead set response on your own side.

This feature is helpful when you need to mock up http responses instead of having them requested from a real web application.
For example in absence of an access to a tested application or if response is too slow or it involves too much data
which make it hard to execute a swat stories often.

This is an example of setting server response inside swat hook:

    # hook.pm
    set_response("THIS IS I FAKE RESPONSE\n HELLO WORLD");
    
    # get.txt
    THIS IS A FAKE RESPONSE
    HELLO WORLD

You may call `set_response' more then once:

    set_response("HELLO WORLD");
    set_response("HELLO WORLD2");

A final response will be:

    HELLO WORLD
    HELLO WORLD2

Another interesting idea about set_response feature is a I<conditional> http requests.

Let say we have `POST /login' request for user authentication, this is a simple swat story for it:

    # login/post.txt
    200 OK

Good. But what if you need to skip authentication under some conditions, like if you are already logged in before?
We could write such a code:

    # login/post.txt
    generator:
    $logged_in ? [ 'I am already logged in' : '200 OK' ]
    
    # login/hook.pm
    if ( ... check if user is logged in .... ){
        set_response('I am already logged in');
    }


=head2 Process http responses 

I<set_response_processor(CODEREF)>

Response processors are custom perl function to modify content returned from server I<before> invoking a validation process.
Processor code should be I<defined> by calling a process_response function with parameter as reference to processor function:

For example:

       set_response_processor( sub { 
          my $headers   = shift; # original response, http headers, String
          my $body      = shift; # original response, body, String
          $body=~s/hello/swat/;
          return $body;          # modified response will be return value of sub {} 
        });

What you should know about processor functions:

=over

=item *

They should be simple, it is good to follow KISS paradigm.



=item *

They are not for validating content, use check lists for this.



=item *

Basicly processor code I<prepare> a content to be validated by check lists.



=item *

When processor function gets called it is supplied with $body parameter which is a http body of original http response relieved from server.



=item *

Remember that if processor function gets called - the content get passed into validation process will be altered as if you use a classic UNIX  pipeline, see schema below.



=item *

In case of response processor function gets called, the original http headers and processor function return value be sent as input for validation process. 



=item *

If no processor function gets called an original http response ( http headers and the body ) will be sent as input for validation process.



=back

This is a rough schema of full process:

     # without processor function
     curl -i some-http-URL | validation-process
    
     # with processor script exists:
     curl -i some-http-URL | processor-function| validation-process

The I<possible> usage of processor functions:

=over

=item *

handling json, xml, yaml data


=back

For example:

      # server response in json format
      {
          "Foo": {
              "Bar" : "Baz"
           }
      }
    
      # processor function
      my $headers   = shift;
      my $body      = shift;
      use JSON;
      $hash = decode_json($body);
      return 'Foo.Bar.Baz :'.( $hash->{Foo}->{Bar}->{Baz} )."\n";
      
    
      # server response in xml format
      <foo>
        <bar>
          <baz>aaa</baz>
        </bar>  
      </foo>
    
      # processor function
      my $headers   = shift;
      my $body      = shift;
      use XML:LibXML;
      my $doc = XML::LibXML->parse_string($body);
      return 'Foo.Bar.Baz :'.( $doc->find("string(/foo/bar/baz)")->string_value )."\n";


=head2 Redefine http resources

I<modify_resource(CODEREF)>

To modify existed resource use modify_resource function:

    # foo/bar/baz/ - resource
       
    # hook.pm
    modify_resource( sub { my $resource = shift; s/bar/bbaarr/, s/baz/bbaazz/ for $resource; $resource  } );
    
    # modified resource
    foo/bbaarr/bbaazz


=head2 Upstream and downstream stories

Swat allow you to call one story from another, using notion of swat modules.

Swat modules are reusable swat stories. Swat never executes swat modules directly, instead you have to call swat module from your swat story.
Story calling another story is named a I<upstream story>, story is being called is named a I<downstream> story.
( This kind of analogy is taken from Jenkins CI )

Let show how this work on a previous `login' example. We need to ensure that user is logged in before
doing some other action, like checking email list:

    # email/list/get.txt
    200 OK
    email list
    
    # email/list/hook.pm
    run_swat_module( POST => '/login', { user => 'alex', password => 'swat' } )  
    
    # and finally this is
    # login/post.txt
    200 OK
    
    # login/swat.ini
    swat_module=1 # this story is a swat module
    curl_params="-d 'user=%user%' -d 'password=%password%'"

Here are the brief comments to the example above:

=over

=item *

`set_module=1' declare swat story as swat module; now swat will never execute this story directly, upstream story should call it.



=item *

call `run_swat_module(method,resource,variables)' function inside upstream story hook to run downstream story.



=item *

you can call as many downstream stories as you wish.



=item *

you can call the same downstream story more than once.



=back

Here is an example code snippet:

    # hook.pm
    run_swat_module( GET => '/foo/' )
    run_swat_module( POST => '/foo/bar' )
    run_swat_module( GET => '/foo/' )

=over

=item *

swat modules have a variables


=back

Use hash passed as third parameter of runI<swat>module function:

    run_swat_module( GET => '/foo', { var1 => 'value1', var2 => 'value2', var3=>'value3'   }  )

Swat I<interpolates> module variables into `curl_params' variable in swat module story:

    # swat module
    # swat.ini
    swat_module=1
    # initial value of curl_params variable:
    curl_params='-d var1=%var1% -d var2=%var2% -d var3=%var3%'
    
    # real value of curl_params variable
    # during execution of swat module:
    curl_param='-d var1=value1 -d var2=value2 -d var3=value3'

Use C<%[\w\d_]+%> placeholders in a curl_params variable to insert module variables here

Access to a module variables is provided by `module_variable' function:

    # hook.pm
    module_variable('var1');
    module_variable('var2');

=over

=item *

swat modules could call other swat modules



=item *

you can't use module variables in a story which is not a swat_module



=back

One word about sharing state between upstream story and swat modules. As swat modules get executed in the same process
as upstream story there is no magic about sharing data between upstream and downstream stories.
The straightforward way to share state is to use global variables :

    # upstream story hook:
    our $state = [ 'this is upstream story' ]
    
    # downstream story hook:
    push our @$state, 'I was here'

Of course more proper approaches for state sharing could be used as singeltones or something else.


=head2 Swat variables accessors

There are some accessors to a common swat variables:

=over

=item *

project_root_dir()



=item *

test_root_dir()



=item *

resource()



=item *

resource_dir()



=item *

http_method()



=item *

hostname()



=item *

ignore_http_err()



=item *

config() - returns hash of test suite configuration



=back

See L<test suite ini file|#test-suite-ini-file> section for details.

Be aware of that these functions are readers not setters.


=head2 PERL5LIB

Swat adds `project_root_directory/lib' path to PERL5LIB path, which make it easy to add some modules and use them:

    # my-app/lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    ...
       
    # hook.pm
    use Foo::Bar::Baz;
    ...


=head1 Swat runner workflow

This is detailed explanation of swat runner life cycle.

Swat runner script consequentially hits two phases:

=over

=item *

swat stories are converted into perl test files ( compilation phase )


=item *

perl test files are recursively executed by prove ( execution phase )


=back

Generating Test::More asserts sequence

=over

=item *

for every swat story found:

=over

=item *

new instance of Outthentic::DSL object (ODO) is created 


=item *

check list file passed to ODO


=item *

http request is executed and response passed to ODO


=item *

ODO makes validation of given stdout against given check list


=item *

validation results are turned into a I<sequence> of Test::More ok() asserts


=back



=back


=head2 Time diagram

This is a time diagram for swat runner life cycle:

=over

=item *

Hits compilation phase



=item *

For every swat story found:

=over

=item *

Creates a perl test file


=back



=item *

The end of compilation phase



=item *

Hits execution phase - runs `prove' recursively on a directory with a perl test files



=item *

For every perl test file gets executed:

=over

=item *

Test::More asserts sequence is generated


=back



=item *

The end of execution phase



=back


=head1 TAP

Swat produces output in L<TAP|https://testanything.org/> format, that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this.

Here is example for converting swat tests into JUNIT format:

    swat --prove '--formatter TAP::Formatter::JUnit'


=head1 Prove settings

Swat utilize L<prove utility|http://search.cpan.org/perldoc?prove> to run tests, 
all prove related parameters could be passed via `--prove' option to prove runner.

Here are some examples:

    swat --prove -Q # don't show anythings unless test summary
    
    swat --prove '-q -s' # run prove tests in random and quite mode


=head1 Test suite ini file

Test suite ini file is a configuration file where you may pass any additional data could be used in your tests:

    cat suite.ini
    
    [main]
    
    foo = 1
    bar = 2

There is no special magic behind this ini file, except this should be L<Config Tiny|https://metacpan.org/pod/Config::Tiny> compliant configuration file.

By default swat runner looks for file named suite.ini placed at current working directory.

You my redefine this by using suiteI<ini>file environment variable:

    suite_ini_file=/path/to/your/ini/file

Or by `--ini' parameter of story runner:

    swat --ini /path/to/your/ini/file

Once suite ini file is read up one may use it in hook.pm files via config()

    # cat hook.pm
    
    my $foo = config()->{main}{foo};
    my $bar = config()->{main}{bar};


=head1 Misc settings

=over

=item *

swat_purge_cache

=over

=item *

Set to `1', in case you need to clear swat cache directory, useful when swat tests get run periodically and a lot of cache files are created.


=item *

Default value is `0' ( do not clear cache ).


=back



=back


=head1 Swat client

Once swat is installed you get swat client at the `PATH':

    swat [[project_root_dir] [host:port]] [swat_command_line_parameters]

=over

=item *

B<project_root_dir> - swat project root directory


=back

In case you don't set one, swat assume it equal to current working directory. Examples:

    # setup project root directory explicitly
    swat /foo/bar/baz
    
    # project root directory is CWD
    swat 

=over

=item *

B<host> - basic URL of tested application, should be in curl compatible format


=back

In case host parameter is missing , swat tries to read it up from `host' file. Examples:

    # setup host explicitly
    swat /foo/bar/baz 127.0.0.1
    
    # host entry gets read from CWD/host file 
    swat /foo/bar/baz
     
    # project root directory is CWD
    # host entry gets read from CWD/host file 
    swat

List of swat command line parameters:

=over

=item *

B<--prove|prove-opts> - sets prove parameters


=back

See L<prove settings|prove-settings>

=over

=item *

B<-t|--test>


=back

Sets a distinct sub sets of stories to execute, see L<Running subset of stories|#Running-subset-of-stories>

=over

=item *

B<--ini> - test suite ini file path


=back

See L<test suite ini file|#test-suite-ini-file> section for details.

=over

=item *

B<--debug|d> - sets value for swat debug parameter


=back

Override the value for swat debug variable, see L<swat variables|#swat-variables> section:

    debug=1 swat --debug 2 # set debug to 2


=head1 Running subset of stories

Use `-t' options to execute a subset of swat stories:

    # run `FOO/*' stories
    swat example/my-app 127.0.0.1 -t FOO/

=over

=item *

`-t' option should point to a resource(s) path and be relative to the project root directory 



=item *

`-t' option should not contain extension part - `.txt'



=item *

it is possible to use more than one `t' options



=back

For example:

    -t FOO/BAR -t BAR -t FOO/BAZ  

=over

=item *

Or even path more than one argument for -t parameter:


=back

For example:

    -t FOO/BAR FOO/BAZ BAR


=head1 Examples

There is plenty of examples at ./examples directory


=head1 AUTHOR

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Home Page

https://github.com/melezhik/swat


=head1 Thanks

=over

=item *

to God as - I<For the LORD giveth wisdom: out of his mouth cometh knowledge and understanding. (Proverbs 2:6)>


=back

All the stuff that swat relies upon, thanks to those authors:

=over

=item *

linux


=item *

perl


=item *

curl


=item *

TAP


=item *

Test::More


=item *

Test::Harness


=back


=head1 COPYRIGHT

Copyright 2015 Alexey Melezhik.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
