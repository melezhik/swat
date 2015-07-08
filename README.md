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

    swat ./my-app 

# Advanced DSL

## comments
You may add comments with standard convetional way, using `#` approach

    # you may add any comments into your tests, with chunks prepended with #, as here
    HELLO WORLD # and here comment too

## inline perl code

Everything started with `code:` would be treated as perl code to execute. For usefull test functions (skip,etc) follow Test::More documention

    code: skip('next test is skipped',1) # skip next check forever
    HELLO WORLD

## using regexp

Everything started with `regexp:` would be treated as perl regular expression


    # this is is the exapmple of regexp check
    regexp: App Version Number: \d+\.\d+\.\d+
    
# POST 

# Dependencies
Just a few! :)
- bash
- find
- head
- curl
- perl


# Environmental Variables
- clear_cache - set to 1 if you need to clear swt cache ( barely need )
- debug - set to 1 if you want to see some debug information in output
- curl_params - additional curl parameters to add to http requests


