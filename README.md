# SYNOPSIS
SWAT - stands for  Simple Web Applications Tests.

# AUTHOR
[Aleksei Melezhik](mailto:melezhik@gmail.com)


# DESCRIPTION

Simple Web Application Test Framework

# Create tests

    mkdir  my-app/ # create a project directory to hold tests


    # define http URI application should response

    mkdir -p my-app/hello # GET /hello-world 
    mkdir -p my-app/hello/world # GET /hello-world 

    # define content the URIs should return

    echo 200 OK >> my-app/hello/get.txt
    echo 200 OK >> my-app/hello/world/get.txt

    echo 'This is hello' >> my-app/hello/get.txt
    echo 'This is hello world' >> my-app/hello/world/get.txt

# Run tests

    swat http://127.0.0.1 ./my-app 

# Advanced DSL

## Comments
You may add comments with standard convetional way, using `#` approach

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

    # just use post.txt instead get.tx file
    echo 200 OK >> my-app/hello/post.txt
    echo 200 OK >> my-app/hello/world/post.txt


# Swat settings

One may set a proper envrionment variables to redefine swat settings:

- clear_cache - set to 1 if you need to clear swt cache ( barely need ), default value is 0

- debug - set to 1 if you want to see some debug information in output, default value is 0

- curl_params - additional curl parameters to add to http requests, default value is ''

    # example
    # sets http headers
    curl_params="-H 'Conent-Type: text/html'"

- curl_connect_timeout - see curl documentation
- curl_max_time - see curl documentation

Swat  also checks files named project.ini in every directory and if exists apply settings from it.
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
Just a few! :)
- bash
- find
- head
- curl
- perl
