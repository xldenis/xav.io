---
date: 2018-07-15
title: besm
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
