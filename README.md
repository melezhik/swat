# SYNOPSIS

SWAT is Simple Web Application Test ( Tool )

# WHY

I know there are a lot of tests tools and frameworks, but let me  briefly tell _why_ I created swat.
As devops I update a dozens of web application weekly, sometimes I just have _no time_ sitting and wait while dev guys or QA team ensure that deploy if fine
and nothing breaks on the road. So I need a tool to _run smoke tests_ against _web applications_. Not tool only, but way to _create such a tests
from the scratch_ in way easy and fast enough. So this how I came up with the idea of swat. If I was a marketing guy I'd say that swat:

- is easy to use and flexible tool to run smoke tests against web applications
- it's curl impovered and TAP compatible 
- it has minimal dependency tree  and probably will run out of the box on most linux environments, provided that one has perl/bash/find/curl by hand 
( which is true  for most cases )
-it has a simple and yet powerfull DSL allow you to both run simple tests ( 200 OK ) or comlicated ones ( using curl api )
- and yes ... it's fun (: 

# Tutorial

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
Swat DSL consists of 2 parts. Routes ( or URIs ) and check patterns.

## Routes

URI resolution is conventional based. It's taken as subtree path taken from project root directory. Let's say we have a project layout 

    exmaple/my-app/    
    exmaple/my-app/hello/    
    exmaple/my-app/hello/get.txt    
    exmaple/my-app/hello/world/get.txt    

When you give swat a run

    swat exmaple/my-app 127.0.0.1 

It just find all the directories holding get.txt files and resolve URI upon project root directory ( which is exmaple/my-app ):

    GET hello/
    GET hello/world

Then check pattern come into play.

## Check patterns 

As you can see from tutorial above check patterns are  just text files describing what you expect to return for given URI. We 


## Comments
You may add comments with lines starts with '#' symbol

    # you may add any comments into your tests, with chunks prepended with #, as here
    HELLO WORLD # and here comment too

## Inline perl code

Everything started with `code:` would be treated as perl code to execute. For usefull test functions (skip,etc) follow Test::More documention

    code: skip('next test is skipped',1) # skip next check forever
    HELLO WORLD

## Using regexp

Everything started with `regexp:` would be treated as perl regular expression


    # this is example of regexp check
    regexp: App Version Number: (\d+\.\d+\.\d+)
    
# POST requests

    # just use post.txt instead of get.txt file
    echo 200 OK >> my-app/hello/post.txt
    echo 200 OK >> my-app/hello/world/post.txt


# Swat settings

## Environmental variables

One may set a proper envrionment variables to define swat settings:

- clear_cache - set to 1 if you need to clear swt cache ( barely need ), default value is 0
- debug - set to 1 if you want to see some debug information in output, default value is 0
- curl_params - additional curl parameters to add to http requests, default value is ""
- curl_connect_timeout - see curl documentation
- curl_max_time - see curl documentation

## Project.ini file

Swat also checks files named project.ini in _every project directory_ and if exists apply settings from there.
Project.ini file should be bash file with swat variables definitions:

    # the content of project.ini file:
    curl_params="-H 'Conent-Type: text/html'"
    debug=1

    # there are many project.ini files here
    my-app/project.ini
    my-app/hello/get.txt
    my -app/hello-world/get.txt
    my -app/hello-world/project.ini


# Dependencies
Not many :)
- curl
- bash / find / head
- perl

# AUTHOR
[Aleksei Melezhik](mailto:melezhik@gmail.com)
