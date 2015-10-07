# SYNOPSIS

Web automated testing framework.

# Description

- Swat is a powerful and yet simple and flexible tool for rapid web automated testing development.

- Swat is a web application oriented test framework, this means that it equips you with all you need for a web test development 
and yet it's not burdened by many other "generic" things that you probably won't ever use.

- Swat does not carry all heavy load on it's shoulders, with the help of it's "elder brother" - curl 
swat makes a http requests in a smart way. This means if you know and love curl swat might be easy way to go.
Swat just passes all curl related parameter as is to curl and let curl do it's job.

- Swat is a text oriented tool, for good or for bad it does not provide any level of http DOM or xpath hacking, it does
not even try to decouple http headers from a body. Actually _it just returns you a text_ where you can find and grep
in old good unix way. Does this sound suspiciously simple? I believe that most of things could be tested in a simple way.

- Swat is extendable by writing custom perl code, this is where you may add desired complexity to your test stories.

- And finally swat relies on prove as internal test runner - this has many, many good results:

    - swat transparently passes all it's arguments to prove which makes it simple to adjust swat runner behavior in a prove way
    - swat tests might be easily embedded as unit tests into a cpan distributions.
    - test reports are emitted in a TAP format which is portable and easy to read.

Ok, now I hope you are ready to dive into swat tutorial! :)

# Install

    $ sudo apt-get install curl
    $ sudo cpanm swat

Or install from source:

    # useful for contributors and developers
    perl Makefile.PL
    make
    make test
    make install

# Write your swat story 

Swat test stories always answers on 2 type of questions:

- _What kind of_ http request should be send.
- _What kind of_ http response should be received.

As swat is a web test oriented tool it deals with some http related stuff as:

- http methods
- http resources 
- http responses

Swat leverages unix file system to build an _analogy_ for these things:

## HTTP Resources

_HTTP resource is just a directory_. You have to create a directory to define a http resource:

    mkdir foo/
    mkdir -p bar/baz

This code defines two http resources for your application - 'foo/' and 'bar/baz'

## HTTP methods

_HTTP method is just a file_. You have to create a file to define a http method.

    touch foo/get.txt
    touch foo/put.txt
    touch bar/baz/post.txt

Obviously \`http methods' files should be located at \`http resource' directories.

The code above defines a three http methods for two http resources:

    - GET /foo
    - PUT /foo
    - POST bar/baz

Here is the list of _predefined_ file names for a http methods files:

    get.txt --> GET method
    post.txt --> POST method
    put.txt --> PUT method
    delete.txt --> DELETE method

# Hostname / IP Address

You need to define hostname or ip address to send request to. Just write it up to a special file  called \`host' and swat will use it.

    echo 'app.local' > host

As swat makes http requests with the help of curl, the host name should be complaint with curl requirements, this
for example means you may define a http schema or port here:

    echo 'https://app.local' >> host
    echo 'app.local:8080' >> host

## HTTP Response

Swat makes request to a given http resources with a given http methods and then validates a response. 
Swat does this with the help so called _check lists_, Check lists are defined at \`http methods' files.


Check list is just a list of expressions a response should match. It might be a plain strings or regular expressions:

    echo 200 OK > foo/get.txt
    echo 'Hello I am foo' >> foo/get.txt

The code above defines two checks for response from \`GET /foo':

    - it should contain "200 OK"
    - it should contain "Hello I am foo"

You may add some regular expressions checks as well:

    # for example check if we got something like 'date':
    echo 'regexp: \d\d\d\d-\d\d-\d\d' >> foo/get.txt

# Bringing all together

All these things http method, http resource and check list comprise into essential swat entity called a _swat story_.

Swat story is a very simple test plan, which could be expressed in a cucumber language as follows:

    Given I have web application 'http://my.cool.app:80'
    And I have http method 'GET'
    And make http request 'GET /foo'
    Then I should have response matches '200 OK'
    And I should have response matches 'Hello I am foo'
    And I should have response matches '\d\d\d\d-\d\d-\d\d'

From the file system point of view swat story is a:

- http method - the \`http method' file
- http resource - the directory where \`http method file' located in
- check list - the content of a \`http method' file

## Swat Project

Swat project is a bunch of a related swat stories kept under a single directory. This directory is called _project root directory_.
The project root directory name does not that matter, swat just looks up swat story files into it and then "execute" them.
See [swat runner workflow](#swat-runner-workflow) section for full explanation of this process.

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

When you ask swat to execute swat stories you have to point it a project root directory or \`cd' to it and run swat without arguments:

    swat my/swat/project

    # or

    cd my/swat/project && swat

Note, that project root directory path will be removed from http resources paths during execution:

    - GET FOO
    - POST FOO/BAR

Use \`test_file' variable to execute a subset of swat stories:

    # run a single story
    test_file=FOO/get swat example/my-app 127.0.0.1

    # run all `FOO/*' stories:
    test_file=FOO/ swat example/my-app 127.0.0.1

Test\_file variable should point to a resource(s) path and be relative to project root dir, also it should not contain extension part - \`.txt'


Let's describe swat DSL for check lists expressions.

# Check lists

So, swat check list is list of check expressions, indeed not only check expressions, there are some - comments, 
blank lines, text blocks , perl expressions and generators we will talk about it later.

Let's start with check expressions.


## Check expressions

Swat check expressions declares _what should be_ in a response: 

    # http response
    200 OK
    HELLO
    HELLO WORLD
    My birth day is: 1977-04-16


    # check list
    200 OK
    HELLO
    regexp: \d\d\d\d-\d\d-\d\d


    # swat output
    200 OK matches
    HELLO matches
    regexp: \d\d\d\d-\d\d-\d\d matches



There are two type of check expressions - plain strings and regular expressions. 

- **plain string**

        200 OK
        HELLO SWAT
        

The code above declares that http response should have lines matches to '200 OK' and 'HELLO SWAT'.

- **regular expression**

Similarly to plain strings, you may ask swat to check if http response has a lines matching to a regular expressions:

        regexp: \d\d\d\d-\d\d-\d\d # date in format of YYYY-MM-DD
        regexp: 20\d # successful http status 200, 201 etc
        regexp: App Version Number: \d+\.\d+\.\d+ # version number

Regular expression should start with \`regexp:' marker.
 
You may use \`(,)' symbols to capture subparts of matching strings, the captured chunks will be saved and could be used further, 

- **captures**

Note, that swat does not care about how many times a given check expression is matched by response, 
swat "assumes" it at least should be matched once. However swat is able to accumulate 
all matching lines and save them for further processing, just use \`(,)' symbols to capture subparts of matching strings:

        regexp: Hello, my name is (\w+)

See ["captures"](#captures) section for full explanation of a swat captures:


## Comments, blank lines and text blocks 

- **comments**

    Comment lines start with \`#' symbol, swat ignore comments chunks when parse swat stories

        # comments could be represented at a distinct line, like here
        200 OK
        Hello World # or could be added to existed matchers to the left, like here

- **blank lines**

    Blank lines are ignored. You may use blank lines to improve code readability:

        # check http header
        200 OK
        # then 2 blank lines


        # then another check
        HELLO WORLD

But you **can't ignore** blank lines in a \`text block matching' context ( see \`text blocks' subsection ), use \`:blank_line' marker to match blank lines:

        # :blank_line marker matches blank lines
        # this is especially useful
        # when match in text blocks context:

        begin:
            this line followed by 2 blank lines
            :blank_line
            :blank_line
        end:

- **text blocks**

Sometimes it is very helpful to match a response against a \`block of strings' goes consequentially, like here:

        # this text block
        # consists of 5 strings
        # goes consequentially
        # line by line:

        begin:
            # plain strings
            this string followed by
            that string followed by
            another one
            # regexps patterns:
        regexp: with (this|that)
            # and the last one in a block
            at the very end
        end:

This check list will succeed when gets executed against this chunk:

        this string followed by
        that string followed by
        another one string
        with that string
        at the very end.

But **will not** for this chunk:

        that string followed by
        this string followed by
        another one string
        with that string
        at the very end.

\`begin:' \`end:' markers decorate \`text blocks' content. \`:being|:end' markers should not be followed by any text at the same line.

Also be aware if you leave "dangling" \`begin:' marker without closing \`end': somewhere else 
swat will remain in a \`text block' mode till the end of your swat story, which is probably not you want:

        begin:
            here we begin
            and till the very end of test
            we are in `text block` mode

## Perl expressions

Perl expressions are just a pieces of perl code to _get evaled_ inside your swat story. This is how it works:

        # this is my swat story
        200 OK
        code: print "hello world"
        That's OK


First swat converts swat story into perl code with eval "{code}" chunk added into it, this is called compilation phase:

        ok($status,"response matches 200 OK");
        eval 'print "hello world"';
        ok($status,"content matches That's OK"); # etc

Then prove execute the code above.

Follow ["Swat runner  workflow"](#swat-runner-workflow) to know how swat compile stories into a perl code.

Anyway, the example with 'print "hello world"' is quite useless, there are of course more effective ways how you code use perl expressions in your swat stories.

One of useful thing you could with perl expressions is to call some Test::More functions to modify test workflow:

        # skip tests

        code: skip('next 3 checks are skipped',3) # skip three next checks forever
        color: red
        color: blue
        color: green

        number:one
        number:two
        number:three

        # skip tests conditionally

        color: red
        color: blue
        color: green

        code: skip('numbers checks are skipped',3)  if $ENV{'skip_numbers'} # skip three next checks if skip_numbers set 

        number:one
        number:two
        number:three


Perl expressions are executed by perl eval function, please take this into account.
Follow [http://perldoc.perl.org/functions/eval.html](http://perldoc.perl.org/functions/eval.html) to get know more about perl eval.

## Generators


Swat generators is the way to _create swat check lists  on the fly_. Swat generators like perl expressions are just a piece of perl code
with the only difference that generator code should always return _an array reference_.

An array returned by generator code should contain check list items, _serialized_ as perl strings.
New check list items are passed back to swat parser and will be appended to a current check list. Here is a simple example:

        # original check list

        200 OK
        HELLO
        
        # this generator generates plain string check expressions:
        # new items will be appended into check list

        generator: [ qw{ foo bar baz } ]


        # final check list:

        200 OK
        HELLO
        foo
        bar
        baz

Generators expressions start with \`:generator' marker. Here is more example:

        # this generator generates comment lines 
        # and plain string check expressions:

        generator: my %d = { 'foo' => 'foo value', 'bar' => 'bar value' }; [ map  { ( "# $_", "$data{$_}" )  } keys %d ]


        # final check list:

            # foo
            foo value
            # bar
            bar value

Note about **PERL5LIB**. 

Swat adds \`project_root_directory/lib' path to PERL5LIB path, so you may perl modules here and then \`use' them:

        my-app/lib/Foo/Bar/Baz.pm

        # now it is possible to use Foo::Bar::Baz
        code: use Foo::Bar::Baz; # etc ...

- **multiline expressions**

As long as swat deals with check expressions ( both plain strings or regular expressions ) it works in a single line mode, 
that means that check expressions are single line strings and response is checked in line by line way:

           # swat story
           Multiline
           string
           here    
           regexp: Multiline \n string \n here    

           # http response
           Multiline \n string \n here
           
        
           # swat output
           "Multiline" matched
           "string" matched
           "here" matched
           "Multiline \n string \n here" not matched


Use text blocks instead if you want to achieve multiline checks.

However when writing perl expressions or generators one could use multilines there.  \`\' delimiters breaks a single line text on a multi lines:


        # What about to validate response
        # With sqlite database entries?

        generator:                                                          \

        use DBI;                                                            \
        my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","","");   \
        my $sth = $dbh->prepare("SELECT name from users");                  \
        $sth->execute();                                                    \
        my $results = $sth->fetchall_arrayref;                              \

        [ map { $_->[0] } @${results} ]


# Captures

Captures are pieces of data get captured when swat checks response with regular expressions:

    # here is response data.
    # it's my family ages.
    alex    38
    julia   25
    jan     2


    # let's capture name and age chunks
    regexp: /(\w+)\s+(\d+)/

_After_ this regular expression check gets executed captured data will stored into a array:

    [
        ['alex',    38 ]
        ['julia',   32 ]
        ['jan',     2  ]
    ]

Then captured data might be accessed for example by code generator to define some extra checks:

    code:                               \
    my $total=0;                        \
    for my $c (@{captures()}) {         \
        $total+=$c->[0];                \
    }                                   \
    cmp_ok( $total,'==',72,"total age of my family" );

\`captures()' function is used to access captured data array, it returns an array reference holding all chunks captured during _latest regular expression check_.

Here some more examples:

    # check if response contains numbers,
    # then calculate total amount
    # and check if it is greater then 10

    regexp: (\d+)
    code:                               \
    my $total=0;                        \
    for my $c (@{captures()}) {         \
        $total+=$c->[0];                \
    }                                   \
    cmp_ok( $total,'>',10,"total amount is greater than 10" );


    # check if response contains lines
    # with date formatted as date: YYYY-MM-DD
    # and then check if first date found is yesterday

    regexp: date: (\d\d\d\d)-(\d\d)-(\d\d)
    code:                               \
    use DateTime;                       \
    my $c = captures()->[0];            \
    my $dt = DateTime->new( year => $c->[0], month => $c->[1], day => $c->[2]  ); \
    my $yesterday = DateTime->now->subtract( days =>  1 );     \
    cmp_ok( DateTime->compare($dt, $yesterday),'==',0,"first day found is - $dt and this is a yesterday" );

You also may use \`capture()' function to get a _first element_ of captures array:

    # check if response contains numbers
    # a first number should be greater then ten

    regexp: (\d+)
    code: cmp_ok( capture()->[0],'>',10,"first number is greater than 10" );

# Swat ini files

Every swat story comes with some settings you may define to adjust swat behavior.
These type of settings could be defined at swat ini files.

Swat ini files are file called "swat.ini" and located at \`resources' directory:

     foo/bar/get.txt
     foo/bar/swat.ini

The content of swat ini file is the list of variables definitions in bash format:

    $name=value

As swat ini files is bash scripts you may use bash expressions here:


if [ some condition ]; then
    $name=value
fi

Following is the list of swat variables you may define at swat ini files, the could be divided on two groups:

- **generic settings**
- **curl parameters**

## generic settings

Generic settings define swat  basic configuration, like logging mode, prove runner settings, etc. Here is the list:

- `debug` - set to \`1,2' if you want to see some debug information in output, default value is \`0'.

- `debug_bytes` - number of bytes of http response  to be dumped out when debug is on. default value is \`500'.

- `swat_debug` - set to \`1' to enable swat debug mode, a lot of low level information will be printed on console, default value is \`0'.

- `swat_debug` - run swat in debug mode, default value is \`0`.

- `ignore_http_err` - set to \`1' if you want to ignore unsuccessful http codes (! 2\*\*,3\*\* ).

- `prove_options` - prove options to be passed to prove runner,  default value is \`-v`. See [Prove settings]("#prove-settings") section.

## curl parameters

Curl parameters relates to curl client. Here is the list:

- `try_num` - a number of requests to be send in case curl get unsuccessful return,  similar to curl \`--retry' , default value is \`2'.

- `curl_params` - additional curl parameters being add to http requests, default value is `""`. Here are some examples:

             # -d curl parameter
             curl_params='-d name=daniel -d skill=lousy' # post data sending via form submit.

             # --data-binary curl parameter
             curl_params=`echo -E "--data-binary '{\"name\":\"alex\",\"last_name\":\"melezhik\"}'"`

             # set http header
             curl_params="-H 'Content-Type: application/json'"


Follow curl documentation to get more examples.

- `curl_connect_timeout` - maximum time in seconds that you allow the connection to the server to take, follow curl documentation for full explanation.

- `curl_max_time` - maximum time in seconds that you allow the whole operation to take, follow curl documentation for full explanation.

- `port`  - http port of tested host, default value is \`80'.

## Alternative swat ini files locations

Swat  try to find swat ini files at these locations ( listed in order )

- **~/swat.ini** - home directory

- **$project\_root\_directory/swat.ini** -  project root directory

- **$cwd/swat.my** - custom settings, swat.my should be located at current working directory

## Settings priority table

This table describes all possible locations for swat ini files. Swat try to find swat ini files in order:

    | location                                  | order N     |
    | --------------------------------------------------------|
    | ~/swat.ini                                | 1           |
    | `project_root_directory'/swat.ini         | 2           | 
    | `http resource' directory/swat.ini file   | 3           |
    | current working directory/swat.my file    | 4           |
    | environment variables                     | 5           |


In case the same variable is defined more than once at swat ini files with different locations, the file loaded last win:

    curl_params="-H 'Foo: Bar'" # in a ~/swat.ini 
    curl_params="-H 'Bar: Baz'" # in a project_root_directory/swat.ini 

    # actual curl_params value:
    "-H 'Bar: Baz'"

If you need achieve concatenation mode, use name="$name value" expression:



    curl_params="-H 'Foo: Bar'" # in a ~/swat.ini 
    curl_params="$curl_params -H 'Bar: Baz'" # in a project_root_directory/swat.ini 

    # actual curl_params value:
    "-H 'Foo: Bar' -H 'Bar: Baz'"

In case you need provide default value for some variable use name=${name default_value} expression:

    # port will be set 80 unless it's not set somewhere else
    port=${port:=80} # in a ~/swat.ini 

# Hooks

Hooks are extension points to hack into swat runtime phase. It's just files with perl code gets executed in the beginning of swat story.
You should named your hook file as \`hook.pm' and place it into \`resource' directory:

    foo/get.txt
    foo/hook.pm

    # foo/hook.pm


    diag "hello, I am swat hook";
    sub red_green_blue_generator { [ qw /red green blue/ ] }
    

    # foo/get.txt
    generator: red_gree_blue_generator()
 

There are lot of reasons why you might need a hooks. To say a few:

- create swat generators
- redefine http resources ( see later )
- defined swat template variables ( see later )
- call swat modules ( see later )
- create other custom code 

# Swat runner workflow

This is detailed explanation of how swat runner compiles and then executes swat test stories.

Swat consequentially hits two phases when execute swat stories:

- **Compilation phase** where swat stories are converted into Test::Harness format.
- **Execution phase** where perl test files are recursively executed by prove.

## Swat to Test::Harness compilation

One important thing about check lists is that internally they are represented as Test::More asserts. This is how it work: 

Let's have 3 swat stories:

    user/get.txt # GET /user
    user/post.txt # POST /user
    users/list/get.txt # GET /users/list

Swat parse every story and the creates a perl test file for it:

    user/get.t
    user/post.t
    users/get.txt

Every check lists is converted into the list of the Test::More asserts:

```
    # user/get.txt
    200 OK
    regexp: name: \w+
    regexp: age: \d+

    # user/get.t
    SKIP {
        ok($status,'response matches 200 OK'); 
        ok($status,'response matches name: \w+');
        ok($status,'response matches age: \d+');
    }
```    
     
This is a time diagram for swat runner workflow:

    - Hits swat compilation phase
    - For every swat story found:
        - Calculates swat settings comes from various swat ini files
        - Creates a perl test file at Test::Harness format
    - The end of swat compilation phase
    - Hits swat execution phase - runs \`prove' recursively on a directory with a perl test files
    - For every perl test file gets executed:
        - Require hook.pm if exists
        - Iterate over Test::More asserts
            - Execute Test::More assert
        - The end of Test::More asserts iterator
    - The end of swat execution phase
    

# TAP

Swat produces output in [TAP](https://testanything.org/) format, that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this. 

Here is example for converting swat tests into JUNIT format:

    swat --formatter TAP::Formatter::JUnit

# Prove settings

Swat utilize [prove utility](http://search.cpan.org/perldoc?prove) to run tests, all prove related parameters are passed as is to prove.
Here are some examples:

    swat -Q # don't show anythings unless test summary
    swat -q -s # run prove tests in random and quite mode


# Swat client

Once swat is installed you get swat client at the \`PATH':

    swat <project_root_dir> <host:port> <prove settings>

# Examples

There is plenty of examples at ./examples directory

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Home Page

https://github.com/melezhik/swat

# Thanks

All the stuff that swat relies upon, thanks to those authors:

- linux
- perl
- curl
- TAP
- Test::More
- Test::Harness

# COPYRIGHT

Copyright 2015 Alexey Melezhik.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
