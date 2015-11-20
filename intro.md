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
`GET /login`      | login form           | 200 OK        | html login form
`POST /login`     | LOGIN OK \| BAD LOGIN      | 200 OK \| 401 Unauthorized | login action    
`GET /restricted/zone` | restricted area          | 200 OK  \| 403 Forbidden      | this is restricted resource, only authenticated users have access for it


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

echo 200 OK >> get.txt # this is for GET /
echo hello world >> get.txt # and this one too

echo 200 OK >> login/get.txt
echo '<form action="/login" method="POST">' >> login/get.txt

echo 200 OK >> login/post.txt
echo LOGIN OK >> login/post.txt

echo 200 OK >> restricted/zone/get.txt

```

No need explain more so far, as swat is pretty simple and intuitive in this way. Let's run our first swat tests assuing an aplication runs on 127.0.0.1


```
echo 127.0.0.1 > host
swat
```


