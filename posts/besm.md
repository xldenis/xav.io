---
date: 2018-07-15
title: ПП-BESM
---

In February, my friend [\@moe](https://github.com/mac-adam-chaieb) came to visit me for a couple weeks. While he was here we talked about programming language design, unicode and the impact that anglo-centering of the computinng world. Moe brought up the language [Qalb](https://github.com/nasser/---), an arabic script, scheme-like language which was also a reflection on these issues.

Qalb is an interesting project and got me thinking, what alternate presents did we miss out on? What could programming languages look like if history took a different path? To do this I wanted to try and find a language that wasn't influenced by decades of anglophone programming.

Typically when we learn of early computer science history, we start with Turing at Bletchley Park, von Neumann at the IAS; we hear about the ENIAC, MARK I, MANIAC. If you lookup "History of Programming Languages" on Wikipedia, you get:

![first programming languages](/images/first-programming-languages.png)

While these languages are undeniably important and the ancestors of the modern languages we all use, enjoy and hate, it also erases a whole trunk of programming language history. While American and British scientists were building computers and designing languages, on the other side of the world in the recovering post-war Soviet Union, mathematicians and engineers weren't idle. Working in relative isolation until the late fifties, they developped a whole lineage of programming languages that was fundamentally different from the american ones.

I wanted to share some of the history I discovered, the insights I gained and hopefully to provoke readers to think about the impact of culture in software engineering. So, I've been working on faithfully reimplementing one of the first soviet compilers or programming programme.

### Programming Programmes

Described in A.P. Ershov's 1959 book "Programming Programme for the BESM Computer", ПП-BESM, was a language implemented for the BESM computer, one of the first large scale soviet computers. Started in 1954, after a lecture on ПП-1 a precursor language, it was finished by 1955.

Based on the "Operator Method", described by A. A. Lyapunov in the first university programming course in 1953, it establishes a separation of programs into two separate parts: a program scheme in which a sequence of 'operators', control operators, are listed and a specification of those operators in which each operator is elaborated. This leads Lyapunovian languages to have what would now be considered a very alien syntax:

![Lyapunov's Program Scheme Notation](/images/lyapunov-scheme.png)

Lyapunov's 'language' was never implemented nor was it really meant to be, it acted more as a form of pseudocode. Programs could be written in it and then translated by hand to machine code. The syntax of the operator method made reasoning about and constructing programs simpler. In ПП-BESM, this strict separation was perfectly maintained so the same program looks like:

![PP-BESM equivalent](/images/pp-besm.png)

The operator method was effectively an attempt at decomposing a problem down into constituent parts that could be written and verified independently, not quite sub-routines but hte next best thing. However, the syntax of ПП-BESM wasn't the only thing that was different. The language also incorporated novel features.

#### Loops

It's one/the first language to have an explicit loop construct. Each loop refers to a _parameter_ defined in a specific section of the program. The parameter can be of three different forms:

- Non-Characteristic: It is given a lower and upperbound and steps between them by unity
- Characteristic Specific: In some cases we want a variable number of iterations, so instead we provide a lower bound and a logical condition for when to terminate the loop.
- Dependent on a higher order parameter: It's also possible to define the upper bound for a loop in relation to another, surrounding loop.

#### Variable Addresses

ПП-BESM has no pointer arithmetic or direct access to memory in the language. Instead, it provides a tool called _variable addresses_. A variable address provides access to cells of a memory block, according to a pre-established linear relation between up to three loop paremeters. This allows ПП-BESM to do things like index into matrices.

#### Optimization

This was also the first language to feature any form of optimization. ПП-BESM can use the rules of commutativity to eliminate common arithmetic sub-expressions. It also can optimize the usage of intermediate results when performing those operations.

#### Compiler Input

The BESM-1, the computer on which ПП-BESM ran, had no text input, instead it could read 39-bit words from punch cards. Those words  represented either instructions or floating point numbers. This meant that ПП-BESM programs had to be encoded as numbers or invalid instructions. This meant that before even feeding a program to the compiler it had to go through a tedious 'coding' step where the program was encoded in the correct punch-card form.

Put together ПП-BESM is a fascinating language that no one has heard of. I've decided to bring it to everyone's attention by fully reimplementing it. I've started a project which will implement the compiler in it's original machine code, and encode programs into their binary representation to be run through the compiler. I'd like to use this to highlight the differences between the early languages that are remembered and the Soviet languages that didn't. Looking at the different ways languages could have evolved is puts our current world of technology into perspective. We chose to follow one specific branch of language design and may never know what would have happened if we instead had chosen a different branch.

#### Comments

If you have any questions don't hesitate to reach out to me on twitter [@xldenis](https://twitter.com/xldenis)

#### References

Here are some of the resources I've used in my research for those that are interested in the subject:

[1]A. P. Ershov, “Program texts,” Academician Andrei Ershov’s Archive, Jun. 20, 2016. http://ershov.iis.nsk.su/en/node/777629 (accessed May 11, 2020).
[2]A. P. Ershov, Programming Programme for the BESM Computer. .
[3]G. D. Crowe and S. E. Goodman, “S.A. Lebedev and the birth of Soviet computing,” IEEE Annals of the History of Computing, vol. 16, no. 1, pp. 4–24, Spring 1994, doi: 10.1109/85.251852.
[4]A. P. Ershov and M. R. Shura-Bura, “The Early Development of Programming in the USSR**English text edited by Ken Kennedy, Department of Mathematical Sciences, Rice University, Houston, Texas.,††This research was carried out for the International Research Conference on the History of Computing held at Los Alamos, New Mexico, 10–15 June 1976.,” in A History of Computing in the Twentieth Century, N. Metropolis, J. Howlett, and G.-C. Rota, Eds. San Diego: Academic Press, 1980, pp. 137–196.
[5]S. A. Lebedev, “The High-Speed Electronic Calculating Machine of the Academy of Sciences of the U.S.S.R.,” J. ACM, vol. 3, no. 3, pp. 129–133, Jul. 1956, doi: 10.1145/320831.320832.

