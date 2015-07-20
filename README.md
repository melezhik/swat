# SYNOPSIS

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

# WHY

I know there are a lot of tests tool and frameworks, but let me  briefly tell _why_ I created swat.
As devops I update a dozens of web application weekly, sometimes I just have _no time_ sitting and wait 
while dev guys or QA team ensure that deploy is fine and nothing breaks on the road. 
So I need a **tool to run smoke tests against web applications**. 
Not tool only, but the way to **create such a tests from the scratch in way easy and fast enough**. 

So this how I came up with the idea of swat. If I was a marketing guy I'd say that swat:

- is easy to use and flexible tool to run smoke tests against web applications
- is [curl](http://curl.haxx.se/) powered and [TAP](https://testanything.org/) compatible
- leverages famous [prove](http://search.cpan.org/perldoc?prove) utility
- has minimal dependency tree  and probably will run out of the box on most linux environments, provided that one has perl/bash/find/curl by hand ( which is true  for most cases )
- has a simple and yet powerful DSL allow you to both run simple tests ( 200 OK ) or complicated ones ( using curl api and perl one-liners calls )
- is daily it/devops/dev helper with low price mastering ( see my tutorial )
- and yes ... swat is fun :)

# Tutorial

## Install swat

### developer release

    sudo cpanm --mirror-only --mirror https://stratopan.com/melezhik/swat-release/master swat

### stable release

    sudo cpan install swat

Once swat is installed you have **swat** command line tool to run swat tests, but before do this you need to create them.

## Create tests

    mkdir  my-app/ # create a project root directory to hold tests

    # define http URIs application should response to

    mkdir -p my-app/hello # GET /hello
    mkdir -p my-app/hello/world # GET /hello/world

    # define the content the expected to return by requested URIs

    echo 200 OK >> my-app/hello/get.txt
    echo 200 OK >> my-app/hello/world/get.txt

    echo 'This is hello' >> my-app/hello/get.txt
    echo 'This is hello world' >> my-app/hello/world/get.txt

## Run tests

    swat ./my-app http://127.0.0.1

# DSL

Swat DSL consists of 2 parts. Routes and check patterns.

## Routes

Routes are http resources a tested web application should has.

Swat utilize file system _representing_ all existed routes as sub directories paths in the project root directory.
Let we have a following project layout:

    example/my-app/
    example/my-app/hello/
    example/my-app/hello/get.txt
    example/my-app/hello/world/get.txt

When you give swat a run

    swat example/my-app 127.0.0.1

It will find all the directories holding get.txt files and "create" routes:

    GET hello/
    GET hello/world

Then check patterns come into play.

## Check patterns

As you can see from tutorial above check patterns are  just text files describing **what** is expected to return when route requested. Check patterns file parsed by swat line by line and take an action depending on entity found. There are 3 types of entities may be found in check patterns file:

- Expected Values
- Comments
- Perl one-liners code

### Expected values

This is most usable entity that one may define at check patterns files. _It's just a string should be returned_ when swat request a given URI. Here are examples:

    200 OK
    Hello World
    <head><title>Hello World</title></head>

### Comments

Comments are lines started with '#' symbol, they are for humans not for swat which ignore comments when parse check pattern file. Here are examples.

    # this http status is expected
    200 OK
    Hello World # this string should be in the response
    <head><title>Hello World</title></head> # and it should be proper html code

### Perl one-liners code

Everything started with `code:` would be treated by swat as perl code to execute.
There are a _lot of possibilities_! Please follow [Test::More](https://metacpan.org/pod/search.cpan.org#perldoc-Test::More) documentation to get more info about useful function you may call here.

    code: skip('next test is skipped',1) # skip next check forever
    HELLO WORLD

### Using regexp

Regexps are subtypes of expected values, with the only adjustment that you may use _perl regular expressions_ instead of plain strings checks.
Everything started with `regexp:` would be treated as regular expression.

    # this is example of regexp check
    regexp: App Version Number: (\d+\.\d+\.\d+)

# Post requests

When talking about swat I always say about Get http request, but swat may send a Post http request just name your check patterns file  as post.txt instead of get.txt

    echo 200 OK >> my-app/hello/post.txt
    echo 200 OK >> my-app/hello/world/post.txt

You may use curl\_params setting ( follow ["Swat settings"](#swat-settings) section for details ) to define post data, there are some examples:

- `-d` - Post data sending by html form submit.

         # Place this in swat.ini file or sets as env variable:
         curl_params='-d name=daniel -d skill=lousy'

- `--data-binary` - Post data sending as is.

         # Place this in swat.ini file or sets as env variable:
         curl_params=`echo -E "--data-binary '{\"name\":\"alex\",\"last_name\":\"melezhik\"}'"`
         curl_params="${curl_params} -H 'Content-Type: application/json'"

# Swat settings

Swat comes with settings defined in two contexts:

- environmental variables
- swat.ini files

## Environmental variables

Defining a proper environment variables will provide swat settings.

- `debug` - set to `1` if you want to see some debug information in output, default value is `0`
- `debug_bytes` - number of bytes of http response  to be dumped out when debug is on. default value is `500`
- `ignore_http_err` - ignore http errors, if this parameters is off (set to `1`) returned  _error http codes_ will not result in test fails, 
useful when one need to test something with response differ from  2\*\*,3\*\* http codes. Default value is `0`
- `try_num` - number of http requests  attempts before give it up ( useless for resources with slow response  ), default value is `2`
- `curl_params` - additional curl parameters being add to http requests, default value is `""`, follow curl documentation for variety of values for this
- `curl_connec_timeout` - follow curl documentation
- `curl_max_time` - follow curl documentation
- `port`  - http port of tested host, default value is `80`
- `noproxy`  - ignore http proxy when making http requests, default value is `1`

## Swat.ini files

Swat checks files named `swat.ini` in the following directories

- **~/swat.ini**
- **$project\_root\_directory/swat.ini**
- **$route\_directory/swat.ini**

Here are examples of locations of swat.ini files:

     ~/swat.ini # home directory swat.ini file
     my-app/swat.ini # project_root directory swat.ini file
     my-app/hello/get.txt
     my-app/hello/swat.ini # route directory swat.ini file ( route hello )
     my-app/hello/world/get.txt
     my-app/hello/world/swat.ini # route directory swat.ini file ( route hello/world )

Once file exists at any location swat simply **bash sources it** to apply settings.

Thus swat.ini file should be bash file with swat variables definitions. Here is example:

    # the content of swat.ini file:
    curl_params="-H 'Content-Type: text/html'"
    debug=1

## Settings priority table

Here is the list of settings/contexts  in priority ascending order:

    | context                 | location                | priority  level |
    | ------------------------|------------------------ | --------------- |
    | swat.ini file           | ~/swat.ini              |               1 |
    | environmental variables | ---                     |               2 |
    | swat.ini file           | project root directory  |               3 |
    | swat.ini file           | route directory         |               4 |

Swat processes settings _in order_. For every route found swat:

- Clear all settings
- Apply settings from environmental variables ( if any given )
- Apply settings from swat.ini file in home directory ( if any given )
- Apply settings from swat.ini file in project root directory ( if any given )
- And finally apply settings from swat.ini file in route directory ( if any given )

# TAP

Swat produce output in [TAP](https://testanything.org/) format , that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this. Here is example for converting swat tests into JUNIT format

    swat $project_root $host --formatter TAP::Formatter::JUnit

See also ["Prove settings"](#prove-settings) section.

# Command line tool

Swat is shipped as cpan package, once it's installed ( see ["Install swat"](#install-swat) section ) you have a command line tool called **swat**, this is usage info on it:

    swat project_dir URL <prove settings>

- **URL** - is base url for web application you run tests against, you need defined routes which will be requested against URL, see DSL section.
- **project\_dir** - is a project root directory

## Prove settings

Swat utilize [prove utility](http://search.cpan.org/perldoc?prove) to run tests, so all the swat options _are passed as is to prove utility_.
Follow [prove](http://search.cpan.org/perldoc?prove) utility documentation for variety of values you may set here.
Default value for prove options is  `-v`. Here is another examples:

- `-q -s` -  run tests in random and quite mode

# Examples

./examples directory contains examples of swat tests for different cases. Follow README.md files for details.

# Dependencies

Not that many :)

- perl 
- curl 
- bash
- find
- head

# AUTHOR

[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Thanks

To the authors of ( see list ) without who swat would not appear to light

- perl
- curl
- TAP
- Test::More
- prove
