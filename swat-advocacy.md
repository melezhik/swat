# SYNOPSIS

Swat Advocacy - some thoughts on swat advocacy.

# Swat demystified 


Recently I found some questions and possibly misunderstanding of idea behind a swat.

Not try to tell that I completely understand what people try to find, here in informal
way I am bringing some ideas behind swat ideology.


# Does swat instead of a common perl t/* tests ?

No it does not. As already told cpan distribution tests are fine and do it's job
and I think developers usually try to "equip" theirs modules with proper test suites
to cover regression at least and sometimes if they are diligent enough even try to
catch up with brand new features for their shiny applications ;)

But what I try to say here, that swat is _another_ point of view on testing process.

While you may stick to conventional t/* way you may try swat as well to get some 
benefits it's offer to you while respect some limitations it implies as well.

# Does swat neglect web pages structure and always verify things as plain text?

Well. Yes and No. By default, out of the box swat provides a very simple capabilities
to verify web content. it is very similar one may gain simple "grepping" a text and 
matching it against some patterns. That is it. No dom, xpath or xml / json parsing.
The reason for such a naive approach is _initially_ swat was born as smoke testing tool,
where checking http status codes plus probably some single line text was quite enough 
for the scope of tasks were actual for that moment.

Well time passed and it became clear that sometimes checking http codes and grepping 
web pages content is not enough. Consider REST/JSON application as common example.
That is why I decided to add possibility to cope with such cases and this one is 
called [response processors](https://github.com/melezhik/swat#process-http-responses) - a custom perl code to add some intermediate parsing logic,
for example to parse JSON data and convert it into something else.


# Swat test suites on cpanparty looks quite trivial and simple, so does it worth to use swat?

As my initial intention when I started cpanparty for to _show_ a people a swat way of testing,
not provides cpan author with full test coverage of theirs modules, most of test suites on cpanparty
should be considered as _simple_ examples. But this does not mean that swat can't handle complicated
things. In my production environment I run a sophisticated swat test suite for complex functional testing
of quite large code base. 

Another idea behind cpanparty examples simplicity is swat test suites not only are tests but
API specification for tested modules. Well swat way to do the things is to "localize" tested API
and provides a simple and laconic test suite for it called swat (sparrow) plugin. Consider a sophisticated
web frameworks. We could split it's API to many parts like "routing", "handling quire parameters", "data base models", etc. Every each of part could be covered by it's documentation, but if we 
do things in swat way - it is easy to write a dedicated test suites to express every parts in
a realistic but still laconic test code. We could call it TDD or whatever but what I try to say here
that using swat brings you interesting benefits hard to gain by using classical t/* approach.


Reading swat test report one always get the answer on following questions:

* what routes, http verbs are used
* what named, query parameters, are used
* what kind of content expected to get in server response

I don't try to say that we could not get this by writing a conventional tests under t/* , but
most of such things swat provides out of the box without or with minimal extra code to write.

Swat by design provides all the necessary data which is essential in testing workflow.

# Swat tests a kind of third party testing , if so _who_ is going to write them ?

This is good question to ask. I believe that t/* approach are proven way to get things tested
from the developers point of view. I mean if you are software developer , probably all you need
to ensure that next changes don't break your regression. You don't are about test report output,
you may mock some external dependencies if necessary, you rely on test source code to
describe a testing process, that is fine.

Let me introduce some more possible customers of software you code. What about end users of your API?
Specially if your proves some external web/REST services or build a web framework.
Well now a content of your t/* becomes not that clear and understandable for such others, the same stuff
with test output which sometimes are quite obscure. Of course people involved into software have to
handle with this, as they are developers! but I talk about software customers and end users which
are quite a lot. So the answer the documentation. Good. But I still need a realistic examples
of who this works. Documentation often provides a code snippets, that is fine but what if I need
more on this or I have no time read, I need a simple working example to work with, and that is
where swat test suites may rule. As they are:

* complete, realistic examples

* could be runnable on local environment ( this one is optional and often not necessary )

* provides structured and unified output ( as swat has strict structure )

* always answer on question essential for end user context:

    * what kind of code I need to write to get this feature implemented

    * what kind of input data I need to verify this code ( client part )

    * what kind of output I need to get to verify this code ( server part )


Of course the backside of this that _someone_ need to write a swat tests. It could be any.
Original software engineer or developer relations engineer or even manager. Not that mater
who this is going to be. But as result we have:

* specifications though the testing
* more objective tests are they don't heavily rely on internal application structure
* "true" testing as it again relies on documentation or sometimes being a documentation itself

It's up to you to have full coverage for your code base or not. Swat does not "insist" on it.
But what is nice - that with swat you may start with any piece of your software API, choose it,
write up a test and publish test results as specification!


  
# Conclusion

There more things related to swat echo system left uncovered in this post. 
Here I tried to only highlights some essential parts of swat, at least at my point of view. 

Feel free to ask me or create your ideas, proposals and feature requests ( or bugs -;) on swat github project
or related project (cpanparty, sparrow, outthentic ) pages. 

I am open for users input.

Regards

-- Alexey Melezhik, the author of swat.

 

 
