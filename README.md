# SYNOPSIS

SWAT is Simple Web Application Test ( Tool )

    $ swat examples/google/ google.ru
    /home/vagrant/.swat/reports/google.ru/00.t ..
    ok 1 - successfull reposnse from google.ru/
    # data file: /home/vagrant/.swat/reports/google.ru///content
    ok 2 - GET / returns 200 OK
    ok 3 - GET / returns Google
    1..3
    ok
    All tests successful.
    Files=1, Tests=3, 11 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
    Result: PASS

# WHY

I know there are a lot of tests tool and frameworks, but let me  briefly tell _why_ I created swat.
As devops I update a dozens of web application weekly, sometimes I just have _no time_ sitting and wait while dev guys or QA team ensure that deploy is fine and nothing breaks on the road. So I need a **tool to run smoke tests against web applications**. Not tool only, but the way to **create such a tests from the scratch in way easy and fast enough**. So this how I came up with the idea of swat. If I was a marketing guy I'd say that swat:

- is easy to use and flexible tool to run smoke tests against web applications
- is [curl](http://curl.haxx.se/) powered and [TAP](https://testanything.org/) compatible 
- has minimal dependency tree  and probably will run out of the box on most linux environments, provided that one has perl/bash/find/curl by hand ( which is true  for most cases )
- has a simple and yet powerful DSL allow you to both run simple tests ( 200 OK ) or complicated ones ( using curl api and perl one-liners calls )
- is daily it/devops/dev helper with low price mastering ( see my tutorial )
- and yes ... swat is fun :) 


# Tutorial

## Install swat

    sudo cpanm --mirror-only --mirror https://stratopan.com/melezhik/swat/master swat

Once swat is installed you have swat command line tool to run swat tests, but before do this you need to create them.


## Create tests

    mkdir  my-app/ # create a project directory to hold tests

    # define http URI application should response

    mkdir -p my-app/hello # GET /hello-world 
    mkdir -p my-app/hello/world # GET /hello-world 

    # define content the URIs should return

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

Swat utilize file system data calculating all existed routes as sub directories pathes in the project root directory. 
Let we have a following project layout:

    example/my-app/    
    example/my-app/hello/    
    example/my-app/hello/get.txt    
    example/my-app/hello/world/get.txt    

When you give swat a run

    swat example/my-app 127.0.0.1 

It just find all the directories holding get.txt files and "create" routes:

    GET hello/
    GET hello/world

Then check patterns come into play.

## Check patterns 

As you can see from tutorial above check patterns are  just text files describing what is expected to return when request a route. Check patterns file parsed by swat line by line and take an action depending on entity found. There are 3 types of entities may be found in check patterns file:

- Expected Values
- Comments
- Perl one-liners code


### Expected values
This is most usable that one may define at check patterns files. _It's just s string should be returned_ when swat request a given URI. Here are examples:

    200 OK
    Hello World
    <h1><title>Hello World</title></h1>



### Comments
Comments are lines started with '#' symbol, they are for human not for swat which ignore them when parse check pattern file. Here are examples.

    # this http status is expected
    200 OK
    Hello World # this string should be in the response 
    <h1><title>Hello World</title></h1> # and it should be html code 


### Perl one-liners code

Everything started with `code:` would be treated by swat as perl code to execute. 
There are a _lot of_ possibilities! Please follow [Test::More](search.cpan.org/perldoc/Test::More) documentation to get more info about useful function you may call here.

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


# Swat settings

Swat has some settings may redefined as _environmental variables_ and|or using swat.ini files 

## Environmental variables

One may set a proper environment variables to adjust swat settings:

- debug - set to 1 if you want to see some debug information in output, default value is `0`
- curl_params - additional curl parameters being add to http requests, default value is `""`, follow curl documentation
- curl_connect_timeout - follow curl documentation
- curl_max_time - follow curl documentation
- ignore_http_err - ignore http errors, if this paramets is off (set to `1`) returned  _error http codes_ will not result in test fails, usefull when one need to test something with response differ from  2\*\*,3\*\* http codes. Default value is `0`
- try_num - number of http requests  attempts before give it up ( useless for resources with slow response  ), default value is `2`

## Swat.ini files

Swat also checks files named swat.ini in _every project sub-directory_ and if one exists apply settings from it.
Swat.ini file should be bash file with swat variables definitions:

    # the content of swat.ini file:
    curl_params="-H 'Content-Type: text/html'"
    debug=1

As I say there are many swat.ini files may exist at your project, the one present at the deepest hierarchy level will override predecessors

    my-app/swat.ini
    my-app/hello/get.txt
    my-app/hello/swat.ini 
    my-app/hello-world/get.txt
    my-app/hello-world/swat.ini


# TAP

Swat produce output in [TAP](https://testanything.org/) format , that means you may use your favorite tap parsers to bring result to
another test / reporting systems, follow TAP documentation to get more on this.

# Command line tool

Swat is shipped as cpan package , once it's installed ( see install section ) you have a command line tool called `swat', this is usage info on it:

    swat project_dir URL

- URL - is base url for web application you run tests against, you need defined routes which will be requested against URL, see DSL section.
- project_dir - is a project root directory 

# Dependencies
Not that many :)

- perl / curl / bash / find  / head

# AUTHOR
[Aleksei Melezhik](mailto:melezhik@gmail.com)

# Thanks 
To the authors of ( see list ) without who swat would not appear to light 
- perl
- curl
- TAP
- Test::More
