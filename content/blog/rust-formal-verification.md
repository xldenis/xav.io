---
title: 'Visions of the future: formal verification in Rust'
draft: true
date: '2024-03-16'
---

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.10/dist/katex.min.css" integrity="sha384-wcIxkf4k558AjM3Yz3BBFQUbk/zgIYC2R0QpeeYb+TwlBVMrlgLqwRjRtGZiK7ww" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.10/dist/katex.min.js" integrity="sha384-hIoBPJpTUs74ddyc4bFZSM1TVlQDA60VBbJS0oA934VSz82sBx1X7kSx2ATBDIyd" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.10/dist/contrib/auto-render.min.js" integrity="sha384-43gviWU0YVjaDtb/GhzOouOXtZMP/7XUzwPTstBeZFe/+rCMvRwr4yROQP43s0Xk" crossorigin="anonymous"
    onload="renderMathInElement(document.body);"></script>

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

In a typical verification problem, we want to know if given some hypotheses `P` executing a program `s` will satisfy a property `Q`.
Here `P`and `Q` are *state predicates* describing logical facts about the program state.
This kind of presentation is so common that we have a standard way of writing this: `{ P } s { Q }`, called a *Hoare triple*.
To prove a Hoare triple, we must show that given a state satisfying `P` executing `s` will *always* result in a state satisfying `Q`.

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
Here we treat `*x = 0` as a *points-to* predicate, it asserts ownership `x` with value `0`.
Because  know that `x` and `y` must be different it is easy to conclude that the value of `y` is unchanged.
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
The answer is can be found in two intertwined concerns: difficulty and automation.

Separation logic intertwines a memory safety proof into every verification proof; for example, to write to a pointer you must demonstrate ownership of that pointer.
This both poses an *aesthetic* and practical problem, every step of proof must track which resources are used where, and which are being framed, hiding the essence of the proof's argument and causing new issues for automation.

Separation logic wasn't the only revolution which happened at the turn of the millennium, the same period saw the introduction of CDCL SAT solvers and modern SMT solvers, exponentially increasing our ability to solve propositional and first-order logical problems.
In comparison the automation for separation logic is in its relative infancy, and significantly harder to boot; separation logics tend to be in much tougher complexity classes than ordinary logics.

That's where Rust enters the picture, the ideal target language for formal verification is one which allows us to keep the strengths of separation logic reasoning -- its precise framing -- while ditching its weaknesses -- the tedious and sometimes difficult resource tracking.
This would allow us to have good reasoning principles for complex imperative patterns while benefiting from the high-powered automation available for first-order logics.

As Ralf Jung once said "Rust programmers already know separation logic".
Setting aside interior mutability for the moment, the ownership typing of Rust tells us that if we have two variables `x : T` and `y : T` they are always separated, the separating conjunction is baked into the language!
Even better, `Box<T>` asserts *exclusive* ownership of a memory region for `T`, giving us our "points to" predicates.

In some sense, the Rust type checker is *performing a separation logic proof for us*, each time we compile our program.
We could rely on the Rust type system to guarantee memory safety and separation for us, freeing us from the need to do that in separation logic and instead allow us to focus on the core *functional* properties we want to prove.
Except that Rust has a core feature which seems to violate the strict separation that we so desire: **borrows**.

Like other forms of reference, borrows introduce an *alias* and thus cause problems for framing, when we do `x = &mut y`, there are now seemingly two ways to access the value of `y`, either through `y` or through `*x`.
Here the Rust type system saves us again, the borrow checker tells that `y` cannot be used so long as `x` is around maintaining the principle that at most one name exists for each mutable value.

In formal verification what this means is that we can reason exclusively in terms of `x` if after `x`'s lifetime expires we can "update" `y` to reflect the modifications made with `x`.
I'm going to be a little handwavey here because this post is getting a bit long, but its possible to do this through divination (like in my tool Creusot) or time-travel (like in Aeneas).

Both these tools use the Rust type system to eliminate the need for separation logic, in fact, these tools transform Rust programs into equivalent, pure, functional programs!
Through this encoding they are able to leverage all the pre-existing tools for reasoning in first-order logics (SMT solvers for Creusot and Lean for Aeneas).

## what about ocaml?

Why aren't we able to eliminate separation logic from a functional language like OCaml then?
Well, OCaml includes the `ref` type, which creates a mutable, aliasable reference, for the following example succeeds:

```ocaml
let x = ref 0 in
let y = x in
x := 5;
assert (!y = 5)
```

This means all the framing problems we had earlier appear again in OCaml.
Combined with the module system of OCaml which lets you hide the implementation details of your types behind abstractions, mutable aliasing can be lurking anywhere in your program!

While in practice OCaml programs are often disciplined in their use of mutation, formal verifiers have to assume the worst: to prove `{ P } totally_not_evil (x : ref int) (y : ref int) { Q }`, we need to consider every possible value for `x` and `y`, even those where they mutably alias.
Unlike Rust, OCaml doesn't (yet) have any notion of "unique reference" which could be used to recover nice reasoning principles.

## conclusion

I hope I was able to convey some of why formal verification researchers are excited about Rust. There's a lot more exciting stuff going on which builds upon and extends this foundation, and there's also the question of what to do about *unsafe Rust* where this ownership discipline isn't necessarily enforced.
Those will have to wait for a separate post.