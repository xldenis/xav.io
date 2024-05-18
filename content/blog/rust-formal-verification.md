---
title: 'Visions of the future: formal verification in Rust'
draft: true
date: '2024-03-16'
---

In response to a recent [Boats article](https://without.boats/blog/references-are-like-jumps/), I mentioned that [Rust's type system drastically changes verification](https://twitter.com/xldenis/status/1790297114519404692).
This comment seems to have aroused a lot of [interest](https://graydon2.dreamwidth.org/312681.html), so I figured I'd expand on it, explaining *how* Rust simplifies formal verification and *why* this had the verification community excited for a while now.

I assume that most of you reading this post won't be experts in formal methods so before we talk about what Rust brings to the table, I think it merits to explain what formal verification is and what problems it has. I'm a novice when it comes to blogging, but I'll try to avoid too many technical details and keep things snappy -- bear with me please.

## what is formal verification?

I see a lot of discussions online talk about formal verification, but often it seems to be talked about like a magic powder to be spread on your code to make it Correct™.

In reality, formal verification is simply the application of *formal* (ie: mathematical, logical) techniques to prove that software has *specific* properties stated in a *formal specification language*.
There are many techniques which can be used to achieve this from model checking, to dependent type systems, abstract interpretation or deductive verification.
The most appropriate technique will depend on the language whose programs are being verified and on the properties of interest.
For example, given a pure, functional language you might use a dependent type system like in Coq or Lean to prove theorems, or a refinement type system in Haskell.
To verify concurrency properties you might use a model-checker or alternatively a concurrent separation logic like Iris.
To verify C or Java programs you might instead use a symbolic execution engine backed by SMT.

## the issue with formal verification

In a typical verification problem, we want to know if given some hypotheses $P$, executing a program $s$ will satisfy a property $Q$.
Here $P$ and $Q$ describe conditions that the execution program state of $s$ must satisfy before, and after execution respectively.
This kind of presentation is so common that we have a standard way of writing this: $\{P \} s \{ Q \}$, called a *Hoare triple*.
Let's look at an example verification problem with our Hoare triple notation:

```
{ x = 0 }
x := 2
{ is_even(x) }
```

The argument for why this is true would go something like: after execution, `x = 2`, 2 is an even number and thus `is_even(x)` is true.

Let's consider a second, similar problem with two pointers `x` and `y`:
```
{ *x = 0 && *y = 0 }
*x = 1
{ is_even(y) }
```
is it true that `is_even(y)` holds after execution?
If `x = y`, then no, `y` is not even.
This is an example of what we call the *framing problem*, the frame or footprint of an operation refers to the set of memory locations that may be affected by that operation.
If you can determine the precise frame of each operation, you can know which facts about your program are unaffected by it.

So long as your language is very simple (like BASIC) and has no mutable data structures, you can decide the frame syntactically by looking at the names of variables.
Of course, any non-trivial imperative language will introduce *some* sort of pointer-like structure which makes determining the frame of an operation a *semantic* operation.

The framing problem effectively stalled work on the verification of imperative programs for *decades*, you can perceive this in the Hoare quote at the start of Boats' article:

<blockquote>
  <p>Worst still, an indirect assignment through a pointer, just as in machine code, can update any store location whatsoever, and the damage is no longer confined to the variable explicitly named as the target of assignment...</p>
<footer>C.A.R. Hoare, Hints on programming-language design 1974</footer>
</blockquote>

### separating resources

The turn of the millenium marked the begining of a new era with the introduction of *separation* logic which builds upon the notions of *logical resources* first introduced by Girard for linear logic.
In separation logic, we treat ownership of memory as a *non-duplicable* resource, if I have ownership of some address `a`, I can't also give you ownership of `a`, that would be like if I could turn one dollar into two.
Using separation logic, we can solve our example from before quite nicely:

```
{ *x = 0 &*& *y = 0 }
*x = 1
{ is_even(y) }
```

We use a special *separating conjunction* which states that we own both the resources and that they are disjoint.
Because we now know that `x` and `y` must be different it is easy to conclude that the value of `y` is unchanged.
Its hard to understate how much impact this (simple) change in perspective had.
The following years saw an explosion of activity with this idea extended in every conceviable direction and applied to every problem.

{% figure(src="../csl-family-tree.png") %}
The family tree of Concurrent Separation Logics. Note how after the introduction of CSL in 2004, works explode with almost every year having a major logic introduced, things only stabilize somewhat with the introduction of Iris.

Many thanks to Ilya Sergey for [his family tree picture](https://ilyasergey.net/assets/other/CSL-Family-Tree.pdf)
{% end %}

Modern separation logics like Iris are wonderfully powerful tools, allowing us to precisely state and reason about the most complex and subtle programs and properties.
Using separation logic it becomes possible to *scalable* verification tools for imperative languages like C, Java, Javascript, or even machine code.

## why rust, then?

If separation logic is so great, why do formal verification researchers care so much about Rust?