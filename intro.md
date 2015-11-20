



# Doing testing in swat way

Web application testsing might be tedious, but we still need it. In this informal article I will try to introduce a swat - simple web application test framework as an attempt to reduce test devlopment compelxity and speed up test development process.

The idea behind swat is quite simple. Instead of going with unit tests and interact with your application in internal level one should look at application like black box. All we could with it - is to send some http requests and analize an output.

As rough prototype think about this command:

  curl -f http://127.0.0.1  && echo 'OK'


# Swat VS unit tests

To say it clear swat is not instead of unit tests at all. There are a lot of well known unit tests frameworks for a existed web applications, frameworks  - Plack::Test, Test::Mojo, Kelp::Test, etc. and all of them are cool, realy. But unit tests by it's nature have some limitations, here I try to list some which could be intersiting for our talk:

* unit tests usualy are fired before installation step

  make 
  make test
  make install

This makes it difficuilt to run unit tests against existed application. This is unit tests nature, as they more relate to tested code that to existed application.

* unit tests coupled with applicatiuon source code, but decoupling testing logic from application sometimes is required

I know there are props and cons of doing this. But sometimes I don't even have an application source to start writting unit tests for it. All I have a running application needs to be tested.




 
