---
title: 'Visions of the future: formal verification in Rust'
draft: true
date: '2024-03-16'
---

In response to a recent [Boats article](https://without.boats/blog/references-are-like-jumps/), I mentioned that [Rust's type system drastically changes verification](https://twitter.com/xldenis/status/1790297114519404692).
This comment seems to have aroused a lot of [interest](https://graydon2.dreamwidth.org/312681.html), so I figured I'd expand on it, explaining *how* Rust simplifies formal verification and *why* this had the verification community excited for a while now.

I assume that most of you reading this post won't be experts in formal methods so before we talk about what Rust brings to the table, I think it merits to explain what formal verification is and what problems it has. I'm a novice when it comes to blogging, but I'll try to avoid too many technical details and keep things snappy -- bear with me please.

## What is formal verification?

I see a lot of discussions online talk about formal verification, but often it seems to be talked about like a magic powder to be spread on your code to make it Correct™.

Formal verification is a kind of *formal methods* which concerns itself with verifying that *programs* satisfy a *formal specification*.
This distinguishes it from other formal techniques like TLA+ in which you construct a *model* of your program and then verify properties of that model.
Additionally as a field its often (though not exclusively) concerned with verifying programs coming from 'real world' languages like C, Java, Haskell, OCaml or Rust.

A formal verifier for a given target language will typically provide a *specification language* that you can use to state the desired behavior of your programs.
These languages allow you to express various classes of properties from basic ones like *safety* ( no undefined behavior) or panic-freedom (no crashes), to more advanced properties like *input-output* (for each input you calculate the correct output), *non-interference* (secret values can't be observed from public inputs), *deadlock freedom*, *fairness*, *relational properties* (two different programs are related in some way), or *hyperproperties* (multiple executions of a program satisfy some condition).

Most tools pick a few classes of properties and optimize towards solving those kinds of problems, in part because the properties of interest will influence the *technique* used to reason about them.
There are many techniques we can use but here we'll restrict ourselves to *deductive verification*, where the correctness of a program is reduced to the correctness of a logical formula called a *verification condition* (VC), derived mechanically from the program source.
<!-- Vaguely introduce hoare logic triples using an example  -->

## The problems with formal verification

Regardless of the property of interest, the verification technique used, or the language studied, there is one problem which inevitably rears its head in verification: aliasing.

Give an example using swap in c?

give an example in ocaml

talk about GOSPEL

mutable state

insight: formal verification amplifies the pain in your language

## what rust changes

## prophecies, pledges and time travel

## conclusion