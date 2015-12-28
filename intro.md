# Doing testing in a swat way

Web application testing might be tedious, but we still need it.
In this informal article I will try to introduce you a swat - simple web application test framework
as an attempt to reduce test development complexity and speed up test development process.

The idea behind swat is quite simple. Web application is considered as a black box.
No knowledge about internal structure. No web application internally launched as part of your tests.
No spoofing and mocking of internal services and databases. No objects and methods coupled with application API.
It's a testing of real running application.

Application is a black box and all you could do with it is to send some http requests and analyze the output.

As rough prototype think about this command:

```
  ( curl -f http://127.0.0.1 | grep 'hello world' )  && echo 'OK'
```

Swat is based on the same idea - _Make a request and analyze given output_.

# Request oriented design

Swat tries to do the things as simple as possible.

It means swat tries to behave as web client making http requests and analyzing the output. Nothing more.
I dare to say this could be enough for most of cases.

When making requests swat does not try to interact with web application on UI/browser level like some test systems do.
Instead swat operates on lower http level using [curl](http://curl.haxx.se/).
It's very handy. Every time you have your test failed you always face with two types of issues:

* http code is not successful ( not 200 OK )
* an output does not have an expected value(s)

Practically this means that you can repeat your request manually and analyze an output in more precise way.
 
Thus, the basic entity of swat test harness is a *http request*. Other valid terms for this are -
route, http resource or swat story, whatever you call it, it always mean the same - a piece of data send to server
and the piece of data get back.

You may compare this approach with using arbitrary \`*.t' files in an abstract perl test framework.
IMHO when dealing with web application test speaking in language of http requests
is more natural then speaking on language of test files

Swat http requests aka [swat stories](https://github.com/melezhik/swat#bringing-all-together)
could be executed, tested and reused as whole units.

Swat support a sequential requests which make it possible to implement complicated test cases.

Swat tends to be declarative rather than imperative tool. One have to define a set of tested routes and then declare expected output,
using special [DSL](https://github.com/melezhik/outthentic-dsl).

This intentionally strict model results in more neat and simple test structure. You always look at web application as s set of routes
you may send a request to. This approach might be uncomfortable to go with at the very beginning, but eventually results
many benefits.

However it does not mean swat is not agile, one may extend swat test scenarios with regular perl code
and start doing things in classic imperative way.

In the following example I will try to discover in more practical details what I am talking about.

So, meet the swat - simple (smart) web application testing framework.

# Hello world example

Using a simple web application let's see how easy and fast one could bootstrap web test harness for it.

The application used in this example is a tiny [mojo](https://metacpan.org/pod/Mojo) application with a few http routes:

route             | returned content     | status code   | route description
------------------|----------------------|---------------|--------------------
GET /           | hello world          | 200 OK        | landing page
GET /login      | \<form action="/login" method="POST"\> ...           | 200 OK        | html form for login
POST /login     | LOGIN OK \| BAD LOGIN      | 200 OK \| 401 Unauthorized | login action, required a \`login' and \`password' parameters get passed via POST request. Valid credentials are login=admin , password=123456. After successful authentication server return a "session" cookie.
GET /restricted/zone | welcome to restricted area          | 200 OK  \| 403 Forbidden      | this is restricted resource, only authenticated users have access for it

Having such an appliation should be enough to show some common tasks appearing when writing web application tests:

* sending data over various http requests
* using cookies 
* handling http status codes.

Now having our application routes described we could map them into swat test harness.

## Swat test harness

First of all let's create a http routes. Doing things in a swat way - routes are just a directories:


```
# no need to create directory for '/' route as this one is CWD
mkdir login
mkdir restricted/
mkdir restricted/zone
```

Ok, now having routes let's describe an output we expect to get when making requests to routes.
A files containing rules for describing desired output is called swat check files. These are just regular text files
containing expressions written on outthentic DSL language. To not over-complicate this paper this is going to be
a simple check expression - plain strings, though outthentic DSL has more powerful constructions to validate any text output.

The convention for  naming check file is trivial. File should be named by http method name ( get, post, delete, head  etc. )
with .txt extension. You have to place check files at proper route directories:

```

echo 200 OK > get.txt # this is for GET /
echo hello world >> get.txt

echo 200 OK > login/get.txt # this one for GET /login
echo '<form action="/login" method="POST">' >> login/get.txt

echo 200 OK > login/post.txt # this one for POST /login
echo LOGIN OK >> login/post.txt

echo 200 OK > restricted/zone/get.txt # this one for GET /restricted/zone
echo welcome to restricted area >> restricted/zone/get.txt
```

No need explain more so far, as swat is pretty simple and intuitive in this way.

Let's run our first swat tests assuming that application runs on 127.0.0.1:3000


```
swat ./ 127.0.0.1:3000 -q
```

The output will be:

```
/home/vagrant/.swat/.cache/11657/prove/00.GET.t .................. ok
/home/vagrant/.swat/.cache/11657/prove/login/00.GET.t ............ ok
/home/vagrant/.swat/.cache/11657/prove/login/00.POST.t ........... Dubious, test returned 3 (wstat 768, 0x300)
Failed 3/3 subtests
/home/vagrant/.swat/.cache/11657/prove/restricted/zone/00.GET.t .. Dubious, test returned 2 (wstat 512, 0x200)
Failed 2/2 subtests

Test Summary Report
-------------------
/home/vagrant/.swat/.cache/11657/prove/login/00.POST.t         (Wstat: 768 Tests: 3 Failed: 3)
  Failed tests:  1-3
  Non-zero exit status: 3
/home/vagrant/.swat/.cache/11657/prove/restricted/zone/00.GET.t (Wstat: 512 Tests: 2 Failed: 2)
  Failed tests:  1-2
  Non-zero exit status: 2
Files=4, Tests=11,  2 wallclock secs ( 0.04 usr  0.00 sys +  0.23 cusr  0.02 csys =  0.29 CPU)
Result: FAIL

```

This results are quite predictable. First two routes succeeded - GET / and GET /login ,
another two ones failed - POST /login and GET /restricted/area.

Running swat in \`quite' mode ( using `-q` options for prove which internally swat relies upon )
provides not many useful information, to get more detailed output run without any options:


```

swat ./ 127.0.0.1:3000
 
/home/vagrant/.swat/.cache/12289/prove/login/00.GET.t ............
ok 1 - GET 127.0.0.1:3000/login succeeded
# response saved to /home/vagrant/.swat/.cache/12289/prove/jcYWTNuUMM
ok 2 - output match '200 OK'
ok 3 - output match '<form action="/login" method="POST">'
1..3
ok

... skip  output ...

```

As I already told in the beginning swat - is request oriented tool. The best way to start writing your tests
is to focus only at one request per time. Let's start with the POST /login route:
):


```
$ swat ./ 127.0.0.1:3000 -t login/
/home/vagrant/.swat/.cache/12437/prove/login/00.POST.t ..
not ok 1 - POST 127.0.0.1:3000/login succeeded

#   Failed test 'POST 127.0.0.1:3000/login succeeded'
#   at /usr/local/share/perl/5.20.2/swat.pm line 70.
# curl -f -X POST -k --connect-timeout 20 -m 20 -D - -L --stderr - 127.0.0.1:3000/login
# ===>
#   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#                                  Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (22) The requested URL returned error: 401 Unauthorized
# response saved to /home/vagrant/.swat/.cache/12437/prove/W3poOmDyfl
not ok 2 - output match '200 OK'

#   Failed test 'output match '200 OK''
#   at /usr/local/share/perl/5.20.2/swat.pm line 141.
not ok 3 - output match 'LOGIN OK'

#   Failed test 'output match 'LOGIN OK''
#   at /usr/local/share/perl/5.20.2/swat.pm line 141.
1..3
# Looks like you failed 3 tests of 3.
Dubious, test returned 3 (wstat 768, 0x300)
Failed 3/3 subtests

Test Summary Report
-------------------
/home/vagrant/.swat/.cache/12437/prove/login/00.POST.t (Wstat: 768 Tests: 3 Failed: 3)
  Failed tests:  1-3
  Non-zero exit status: 3
Files=1, Tests=3,  1 wallclock secs ( 0.02 usr  0.00 sys +  0.05 cusr  0.00 csys =  0.07 CPU)
Result: FAIL
```

Now we've got the point - we did not provide credentials for successful login.
Ok, let's change request, adding necessary parameters for POST /login:


```
$ nano login/swat.ini

if test "${http_method}" = 'POST'; then
  curl_params="-d 'login=admin' -d 'password=123456' -c $test_root_dir/cookie.txt "
fi

```
Here we ask swat to do a couple of things.
Firstly we pass valid credentials via POST /login request, and secondly
store a cookie returned by server into a local file in the directory where swat tests runs.
( After successful authentication server return a "session" cookie ).

Ok let's re-run our last test:

```
$ swat ./ 127.0.0.1:3000 -t login/
/home/vagrant/.swat/.cache/12669/prove/login/00.POST.t ..
ok 1 - POST 127.0.0.1:3000/login succeeded
# response saved to /home/vagrant/.swat/.cache/12669/prove/ap3_lyTGtf
ok 2 - output match '200 OK'
ok 3 - output match 'LOGIN OK'
1..3
ok
All tests successful.
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.05 cusr  0.00 csys =  0.07 CPU)
Result: PASS
vagrant@Debian-jessie-amd64-netboot:~/projects/myapp2/swat$

```

Hurrah! We succeeded.  Some comments here regarding swat.ini file we have just used:

* Swat ini files - are regular bash scripts
* Generally one define here additional http requests parameters ( curl_params variable )
* Swat uses curl to make http requests
* Swat provides some useful [variables](https://github.com/melezhik/swat#swat-variables) one may utilize
in swat.ini bash scripts f.e. http_method, test_root_dir, etc.


## Code reuse

Ok. Lets go for another route got failed in first swat run. This is GET /restricted/zone.

Let's re-run it to analyze an output:


```
$ swat ./ 127.0.0.1:3000 -t restricted/zone
/home/vagrant/.swat/.cache/12763/prove/restricted/zone/00.GET.t ..
not ok 1 - GET 127.0.0.1:3000/restricted/zone succeeded

#   Failed test 'GET 127.0.0.1:3000/restricted/zone succeeded'
#   at /usr/local/share/perl/5.20.2/swat.pm line 70.
# curl -f -X GET -k --connect-timeout 20 -m 20 -D - -L --stderr - 127.0.0.1:3000/restricted/zone
# ===>
#   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#                                  Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (22) The requested URL returned error: 403 Forbidden
# response saved to /home/vagrant/.swat/.cache/12763/prove/zkAwzCxes4
not ok 2 - output match '200 OK'

#   Failed test 'output match '200 OK''
#   at /usr/local/share/perl/5.20.2/swat.pm line 141.
1..2
# Looks like you failed 2 tests of 2.
Dubious, test returned 2 (wstat 512, 0x200)
Failed 2/2 subtests

Test Summary Report
-------------------
/home/vagrant/.swat/.cache/12763/prove/restricted/zone/00.GET.t (Wstat: 512 Tests: 2 Failed: 2)
  Failed tests:  1-2
  Non-zero exit status: 2
Files=1, Tests=2,  1 wallclock secs ( 0.03 usr  0.00 sys +  0.06 cusr  0.00 csys =  0.09 CPU)
Result: FAIL

```

Well, the reason of failure is we are  unauthorized to access restricted/zone resource.
The solution is quite obvious - we need to login _before_ doing this request.
Wait, ... we already have login request successfully tested before, could we just reuse it? Definitely!


```
$ nano login/swat.ini

if test "${http_method}" = 'POST'; then
  curl_params="-d 'login=admin' -d 'password=123456' -c $test_root_dir/cookie.txt "
  swat_module=1
fi

```

Adding line with \`swat_module=1' we ask swat to treat route POST /login as _swat module_.
This means that now we could call this route inside ( or before) another route.
Like before GET /restricted/zone we need to POST to /login with valid credentials and have our session cookie:


 
```

$ nano restricted/zone/swat.ini

curl_params="-b $test_root_dir/cookie.txt" # we need provide a valid session via cookie
                                           # get created by POST /login action

$ nano restricted/zone/hook.pm

run_swat_module( POST => '/login');

```

Hook.pm file is so called [swat hook](https://github.com/melezhik/swat#hooks) - a code snippet
you could be running before a route get requested. Swat provides hooks API defining what methods you may invoke from here.
run_swat_module - is function which call another swat module ( in this test we need to call POST login/ route ).

Ok, we are ready to run our test again:


```
$ swat ./ 127.0.0.1:3000 -t restricted/zone
/home/vagrant/.swat/.cache/14509/prove/restricted/zone/00.GET.t ..
ok 1 - POST 127.0.0.1:3000/login succeeded
# response saved to /home/vagrant/.swat/.cache/14509/prove/OXQW6x3s3L
ok 2 - output match '200 OK'
ok 3 - output match 'LOGIN OK'
ok 4 - GET 127.0.0.1:3000/restricted/zone succeeded
# response saved to /home/vagrant/.swat/.cache/14509/prove/Sup0fKtkKA
ok 5 - output match '200 OK'
ok 6 - output match 'welcome to restricted area'
1..6
ok
All tests successful.
Files=1, Tests=6,  0 wallclock secs ( 0.02 usr  0.01 sys +  0.06 cusr  0.00 csys =  0.09 CPU)
Result: PASS
```

Excellent, now request for restricted zone succeeded!

Finally let's run all the tests again and make it sure they all passes:

```
$ swat ./ 127.0.0.1:3000
/home/vagrant/.swat/.cache/14540/prove/login/00.GET.t ............
ok 1 - GET 127.0.0.1:3000/login succeeded
# response saved to /home/vagrant/.swat/.cache/14540/prove/lFkIPbrtnO
ok 2 - output match '200 OK'
ok 3 - output match '<form action="/login" method="POST">'
1..3
ok
/home/vagrant/.swat/.cache/14540/prove/00.GET.t ..................
ok 1 - GET 127.0.0.1:3000/ succeeded
# response saved to /home/vagrant/.swat/.cache/14540/prove/Dte0FvMDES
ok 2 - output match '200 OK'
ok 3 - output match 'hello world'
1..3
ok
/home/vagrant/.swat/.cache/14540/prove/restricted/zone/00.GET.t ..
ok 1 - POST 127.0.0.1:3000/login succeeded
# response saved to /home/vagrant/.swat/.cache/14540/prove/zBRaNpWjlw
ok 2 - output match '200 OK'
ok 3 - output match 'LOGIN OK'
ok 4 - GET 127.0.0.1:3000/restricted/zone succeeded
# response saved to /home/vagrant/.swat/.cache/14540/prove/yIYRRRwCo9
ok 5 - output match '200 OK'
ok 6 - output match 'welcome to restricted area'
1..6
ok
All tests successful.
Files=3, Tests=12,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.15 cusr  0.01 csys =  0.19 CPU)
Result: PASS
```

Ok, our job is done. Now we could have  this test suite as part of continue integration pipeline using Travis or Jenkins, but this is probably out of scope ;-)

# Conclusion

As you can see only with only a few lines of perl code have been dropped we tested a 4 routes.
It  did not take too much and at the end we have a clean and simple test structure.

Of course swat is not fully covered in this article, there more things of interest, all of this could be found
in the [documenation](https://github.com/melezhik/swat/) -
hooks api, response spoofing, generators, validators, check expressions and other swat features.

# Swat examples list

Here is list of example swat test projects, some of projects are obsolete some are actual.
Let me know if you are interested in web test automation using swat and I will get back to you kindly!

project           | description                                       | comment
------------------|---------------------------------------------------|-------------------------------------------------------------
[swat for metacpan api](https://github.com/CPAN-API/metacpan-monitoring) | metacpan monitoring with swat |
[swat for yars](https://github.com/melezhik/swat-yars) | swat black box testing for yars restapi - rest archive server |
[swat for docsis config file editor](https://github.com/melezhik/swat-app-docsisious) | swat black box tests for docsis config file editor ( App::docsisious ) |
[swat for dancer2](https://github.com/melezhik/swat-examples/tree/master/dancer) | swat test suite for Dancer2 framework |
[swat for lacuna-api](https://github.com/melezhik/swat-lacuna-api) | swat test suite for lacunaexpanse JSON/RPC API |
[swat for netstoria](https://github.com/melezhik/WebService-Nestoria-Search/tree/master/swat-test) | swat test suite for Nestoria public API |
[swat for nginx](https://github.com/melezhik/swat-examples/tree/master/nginx) | swat test suite for nginx web server | obsolete, require old version of swat. won't run on latest swat version |
[swat for lighttpd](https://github.com/melezhik/swat-examples/tree/master/lighttpd) | swat test suite for lighttpd web server | obsolete, require old version of swat. won't run on latest swat version |
[swat for mongodb-http](https://github.com/melezhik/swat-examples/tree/master/mongodb-http) | swat test suite for mongodb http interface | obsolete, require old version of swat. won't run on latest swat version |
[swat for pintod](https://github.com/melezhik/swat-examples/tree/master/pintod) | swat test suite for pintod API| obsolete, require old version of swat. won't run on latest swat version |
[swat for django](https://github.com/melezhik/swat-examples/tree/master/django) | swat test suite for django web framework| obsolete, require old version of swat. won't run on latest swat version |
[swat for starman](https://github.com/melezhik/swat-examples/tree/master/starman) | swat test suite for starman web server| obsolete, require old version of swat. won't run on latest swat version |
[swat for zendesk](https://github.com/melezhik/swat-examples/tree/master/zendesk) | swat test suite for zendesk| obsolete, require old version of swat. won't run on latest swat version |


I wish you fun and easy testing with swat!

-- Alexey Melezhik, the author of swat.

PS. A sample web application source code and swat tests used in this article
could be found here - [https://github.com/melezhik/swat/tree/master/stuff](https://github.com/melezhik/swat/tree/master/stuff)
