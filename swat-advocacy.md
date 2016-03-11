# SYNOPSIS

[Swat](https://github.com/melezhik/swat) Advocacy - some thoughts on swat advocacy.

# Swat demystified 


Recently I found some questions and possibly misunderstanding of idea behind a swat.

Not trying to tell that I _completely_ understand what people try to find, here in informal
way I am trying to describe some ideas behind swat ideology.


# Does swat instead of a common perl t/* tests ?

No it does not. As already told cpan distribution tests are fine and do it's job
and I think developers usually try to "equip" theirs modules with proper test suites
to cover regression at least.  And sometimes if they are diligent enough even to try to
catch up with brand new features of their shiny applications and modules ;)

But what I try to say here that swat is _another_ point of view on testing process.

While you may stick to conventional t/* way you, you may try swat as well to get some 
benefits it offers while respecting some limitations or conventions it implies.

# Does swat neglect web pages structure and always verify things as plain text?

Well. Yes and No. By default, out of the box swat provides a very simple capabilities
to verify web content. It is very similar to that when one just "grep" a text and 
match it against some patterns. That is it. No dom, xpath or xml/json parsing.
The reason for such a naive approach is that _initially_ swat was born as smoke testing tool,
where checking http status codes and probably some single line text matching was enough for the scope of tes tasks 
were actual for that moment.

Well time passed and it became clear that sometimes checking http codes and grepping 
web pages content is not enough. Consider REST/JSON application as very common situation.
That is why I decided to add possibility to extend swat parser possibilites and called it [response processors](https://github.com/melezhik/swat#process-http-responses) - a custom perl code 
to add some intermediate parsing logic, for example to parse JSON/XML data and convert it into something else
proper for further testing. Details could be found at swat documentation.


# Swat test suites on cpanparty looks quite trivial and simple, so does it worth to use swat?

As my initial intention when I started cpanparty was to _show_ a people a swat way of testing,
not to provide cpan authors with full test coverage of theirs modules - so most of test suites on cpanparty
should be considered as _simple_, way explanatory examples to help people understand swat. This is what I wrote about in my  [post](http://blogs.perl.org/users/melezhik/2016/02/inroducing-cpanparty.html) at blogs.perl.org

But this does not mean that swat can't handle complicated things. In my production environment I run a sophisticated swat test suites for complex functional testing of quite large code base. 

Another idea behind cpanparty examples  is swat test suites are not tests only but API _specification_ for tested modules. Well, swat way to do the things is to "localize" tested API and provides a simple and laconic test suite for it called swat (sparrow) plugin. 

Consider a sophisticated web frameworks. We could split it's API to many parts like "routing", "handling quire parameters", "data base models", etc. Every each of part could be covered by it's documentation section, but if we 
do things in swat way it is easy to write a dedicated test suites for every section to express every API part in
a realistic but still laconic and self explanatory test suite code. 

We could call it TDD or whatever but what I try to say here that using swat brings you interesting benefits that hard to gain by using classical t/* approach.

Reading swat test report one always get the answer on the following questions:

* what routes, http verbs are used
* what named, query parameters, are used
* what kind of content expected to get in server response
* a source code of tested application ( optionally, only we "embed" tested appliaction in swat test suite )

I don't try to say that we could not get this by writing a conventional tests under t/* , but
most of such things swat provides out of the box without or with minimal extra code to write.

Another backside of many tests in t/* format is sometimes theirs ouput hard to read and accept for unprepared reader.
See my thoughts in next question.

Thus, swat test reports output "tries to be":

* self explanatory

* simple

* close to client/server application software model ( we always have client request and server response shown at test output )

* http oriented ( swat tests always expressed in term s of http requests )

* (^) being a good base for software trobleshooting - as swat "generates" a stearm of http requests
in curl utility format, every single step could be reproduced manually _somewhere else_ 
not having test suite by hand all, provided that you have:

  * curl 
  * swat test report output

*(^)* last point have some limitation though not covered in this post


As summary for this point swat by design provides all the necessary data  which is essential in web application testing workflow.

# Swat tests a kind of third party testing , if so _who_ is going to write them ?

This is good question to ask. I believe that t/* approach is proven way to get things tested
from the _developers point of view_. I mean if you are software developer, probably all you need
to ensure that next changes don't break your regression. You don't care much about test report output
readabilty, you may mock some external dependencies if necessary, you rely on test source code to
_understand_ a testing logic in case of issues, and so on ... that is fine.

But let me introduce you some more possible customers of your software. What about end users consuming software API?
Say if you provides some external web/REST services or build a web framework to used by others?

Well now a content of your t/* becomes not that clear and understandable for such a users, the same stuff
with test output which sometimes are specific and tends to express internal "guts" of your software not public API.
Again privite/public methods tests could be mixed together. Unit tests and integration tests comes at one test sute. And so on. All this make your  tests are not friendly for end customer, not deeply ( or not at all ) envolved in software development process.

Of course people involved into software development *have to* cope with this, as they are developers! But I talk about software customers and end users which is quite different story. 

So the answer is obviously is the documentation. Good. But users still need a *realistic examples* of _how_ this works. Documentation often provides a code snippets, that is fine but often you can't use code snippets to get it run, and even author provides some, it's:

* hard to mainatin to accept all new features
* documenation code snippets could be buggy ( missing "use module" statements, so on )

This is where swat test suites may be rescue, as they:

* are complete, realistic examples

* could be runnable on local environment ( this one is optional and often not necessary )

* provide structured and unified output - as swat test harness has *strict and simple structure*

* always answer on question essential for end user context:

    * what kind of code I need to write to get this API feature on my code

    * what kind of input data I need to verify this code is working ( client part )

    * what kind of output data I need to verify this code is working ( server part )


Of course the backside of such approach is that _someone_ need to write a swat tests. Ok, it could be any.
Original software engineer or developer relations engineer or even manager. Not that mater who this is going to be. 
Not taking too much time finnaly we have:

* specifications through the testing
* more objective tests are they don't heavily rely ( or don't rely at all ) on internal application structure
* "true" testing as it again relies only on public API ( no backdoors and "hidden" workarounds inside your tests )

It's up to you to have full coverage for your code base or not. Swat does not "insist" on it.
But what is nice - that with swat you may start with any piece of your software API, choose it,
write up a test and publish test results as specification!

# I am still confused what is the target of swat tests. If this an application or framework that swat tests to verify?

In classic unit test approach you tests functions, methods or modules. If we talk about integration
testing we always have to talk about some application built up from other blocks. It could be
web framework, some plugins or other primitives with various level of abstraction.
Anyway when we talk about integration testing for web application we deal with some application.

In swat concept testing an application means send some http request and analyze an output.

Ok, to test a framework I need some "posterchild" application built with it. To test a plugin
used in a web framework I still need to have an application using such a plugin.

So swat tests your software ( plugins, modules, frameworks ) through web application context.

It is somewhat closer to real life than unit testing. As end users of your software always use
it in _context_. One use web framework to build up a specific web application, or use some plugin
to gain some functionality inside again some web application and so on.

So in swat approach application acts like _adapter_ to test some piece of software API.




  
# Conclusion

There more things related to swat echo system left uncovered in this post. 
Here I tried to only highlights some essential parts of swat, at least at my point of view. 

Feel free to ask me or create your ideas, proposals and feature requests ( or bugs -;) on swat github project
or related project (cpanparty, sparrow, outthentic ) pages. 

I am open for users input.

Regards

-- Alexey Melezhik, the author of swat.

 

 
