# Doing testing in swat way

Web application testing might be tedious, but we still need it. In this informal article I will try to introduce a swat - simple web application test framework as an attempt to reduce test development complexity and speed up test development process.

The idea behind swat is quite simple. Instead of going with unit tests and interact with your application in internal level one should look at application like black box. All we could with it - is to send some http requests and analyze an output.

As rough prototype think about this command:
```
  ( curl -f http://127.0.0.1 | grep 'hello world' )  && echo 'OK'
```


# Swat VS unit tests

To say it clear swat is not instead of unit tests at all. There are a lot of well known unit tests frameworks for a existed web applications, frameworks  - Plack::Test, Test::Mojo, Kelp::Test, etc. and all of them are cool, really. But unit tests by it's nature have some limitations, here I try to list some which could be interesting for our talk:

* unit tests usually are fired before installation step
 
```
  make
  make test
  make install
```
 
This makes it difficult to run unit tests against existed application. This is unit tests nature, as they more relate to tested code that to existed application.

* unit tests coupled with application source code, but decoupling testing logic from application sometimes is required

I know there are props and cons of doing this. But sometimes I don't even have an application source to start writing unit tests for it. All I have a running application needs to be tested. With swat it's not a problem, as swat tests code base is always decoupled from the application source code.


# Hello world example


Ok, let me show you how easy and fast one could write test for web application using swat. For the sake of simplicity let's have an application with the following set of http routes:

route             | returned content     | status code   | route description
------------------|----------------------|---------------|--------------------
`GET /`           | hello world          | 200 OK        | landing page  
`GET /login`      | \<form action="/login" method="POST"\> ...           | 200 OK        | html login form
`POST /login`     | LOGIN OK \| BAD LOGIN      | 200 OK \| 401 Unauthorized | login action, required a \`login' and \`password' parameters get passed via POST request. Valid credentials are *login=admin , password=123456 * . After successful authetication server return a "session" cookie.
`GET /restricted/zone` | welcome to restricted area          | 200 OK  \| 403 Forbidden      | this is restricted resource, only authenticated users have access for it


Now having application routes we could give it a run for swat.


First of all let's create a http routes. Doing things in swat way - routes are just a directories:


```
# no need to create directory for '/' route
mkdir login
mkdir restricted/
mkdir restricted/zone
```


Ok, now having routes let's describe an output we expect to get when making requests to routes. The rule is trivial - name your check file as `(get|post|head ...).txt`  and place it in a directory related to http route:

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

No need explain more so far, as swat is pretty simple and intuitive in this way. Let's run our first swat tests assuring an application runs on 127.0.0.1:3000


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

This results are quite predictable. First two routes succeeded - GET / and GET /login , another two routes failed - POST /login and GET /restricted/area. To not overwhelm this post with too many logs I run swat in \`quite' mode ( using `-q` options for prove which internally swat relies upon ), to see detailed output ( which is by default ) one may run swat as is without any options:



```

swat ./ 127.0.0.1:3000
 
/home/vagrant/.swat/.cache/12289/prove/login/00.GET.t ............
ok 1 - GET 127.0.0.1:3000/login succeeded
# response saved to /home/vagrant/.swat/.cache/12289/prove/jcYWTNuUMM
ok 2 - output match '200 OK'
ok 3 - output match '<form action="/login" method="POST">'
1..3
ok
/home/vagrant/.swat/.cache/12289/prove/00.GET.t ..................
ok 1 - GET 127.0.0.1:3000/ succeeded
# response saved to /home/vagrant/.swat/.cache/12289/prove/sWSUqQRfeV
ok 2 - output match '200 OK'
ok 3 - output match 'hello world'
1..3
ok


... other output ...

```


Now let's see what happening with unsuccessfull routes and try to determine reason they fail:

```
$ test_file=login/00.POST.t swat ./ 127.0.0.1:3000
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


As it expected a login request failed as we did not provide credentials for successful login. Let's change out swat test:


```
$ nano login/swat.ini

if test "${http_method}" = 'get'; then
  curl_params="-d 'login=admin' -d 'password=123456' -c $test_root_directory/cookie.txt "
fi

```
Here we ask swat to do a couple of things. First to pass via POST /login request valid credentials , and then store a cookie returned by server into local file ( As we said before after successful authetication server return a "session" cookie ).
