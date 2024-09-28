---
title: 'Verifying Filter in Rust'
date: '2024-09-28'
draft: true
---

Last Friday I had the opportunity to do a proof with Creusot which I found quite interesting and satisfying highlighting both the strengths and weaknesses of my tool [Creusot](https://github.com/creusot-rs/creusot).
I want to share this proof with a broader audience and along the way give some insight on how sophisticated proofs are designed and performed in Creusot.

Iterators are probably one of the most widely used functionalities in Rust, most collection types implement a variety of them, and libraries like `itertools` provide additional combinators to manipulate them.
Because of their central role in real-world Rust programs, last year we published a paper on verifying the implementations and clients of iterators, in which our capstone was a proof of correctness for `map` which handles side-effectful closures{% sn() %}
What was especially cool with this work was that this was all achieved in an ordinary first-order logic verifier, despite higher-order effectul code traditionally being the domain of separation logic tools
This is once again a demonstration of how Rust's ownership model enables powerful reasoning with 'weak' tools.
{% end %}, allowing us to prove the correctness of programs like{% sn() %}
For those less familiar with verification, despite being artificial this program encodes a significant amount of complexity: to prove its correct we must prove that `cnt` never overflows, which depends on being able to demonstrate that `map` will never be called more than `usize::MAX` times.
Internally, the proof must build a 'chain' showing that each call to the closure leaves it in a state where we can make a further call.
{% end %}:

```rust
let mut cnt = 0;
let _ = v.iter().map(|x| { cnt += 1; x }).collect();
assert!(v.len() == cnt);
```

After `map` probably the most important iterator in Rust is `filter`, which returns the elements which match a provided predicate `p`.
I feel like to users `filter` appears *simpler* than `map`, after all `map` transforms elements while `filter` only selects some while leaving them unchanged.
Counter intuitively, for verification `filter` is actually considered *harder* to verify than `map`, because for each element `fitler` produes, it may consume an unbounded amount of elements from the underlying iterator.
The verification will need to "talk" about all those elements and relate them to the ones that *were* produced by the iterator.
For this reason, after our paper we never even *attempted* to prove `filter`, until last week when I took a stab at it.
It ended up being both *easier* and *harder* than I expected and pushed the limits of Creusot in what I consider to be interesting directions which is what leads us to today.

## Our initial implementation

To get started with verification, we're going to need some code to verify, so let's implement `filter`:
{% mn() %}
This implementation of `filter` also happens to showcase one of Creusot's distinguishing features: its completely handling of mutable borrows. This allows us to use sophisticated patterns like iterating over a mutable borrow of an iterator, without any effort.
{% end %}

```rust
pub struct Filter<I: Iterator, F: FnMut(&I::Item) -> bool> {
    pub iter: I,
    pub func: F,
}

impl<I: Iterator, F: FnMut(&I::Item) -> bool> Iterator for Filter<I, F> {
    type Item = I::Item;

    fn next(&mut self) -> Option<I::Item> {
        for item in &mut self.iter {
            if (self.func)(&item) {
                return Some(item);
            }
        }

        None
    }
}
```

Here we define `filter` in the obvious manner, we loop over the elements of the underlying iterator, passing each to our predicate until we find one that returns `true`.
The real implementation is actually written in terms of `Iterator::find` but this is just adding another layer of indirection around the same code.

For verification we're also going to make a few simplifying assumptions:

1. Our closure `self.func` has no mutable state, that is after each call `old(self.func) == self.func`.
2. We'll go even further and assume that the closure has no precondition. This means that we forall `i : &I::Item` we can call `self.func(i)`.

Since our type `F` could be *any* `FnMut(&I::Item) -> bool` we need to restrict ourselves to only the functions which satisfy our two conditions.
We can accomplish this using a *type invariant*, which are supported in Creusot.

```rust
impl Invariant<I: Iterator, F: FnMut(&I::Item) -> bool> for Filter<F, I> {
  #[predicate(prophetic)]
  #[open(self)] fn invariant(self) -> bool {
    pearlite! {
      // precondition is always true
      (forall<f : F, i : &I::Item> f.precondition((i,)))  &&
      // all chains of closure states produced by repeated calls are equal
      (forall<f : F, g : F> f.unnest(g) ==> f == g)
    }
  }
}
```

Here we bring in our first taste of specifications using the `pearlite!` macro.
The trait `Invariant` has a single predicate which must be upheld by all "valid" values of `Filter`, Creusot will automatically insert assertions checking that this invariant is true at key points throughout your program.

The first clause, states that for all values of our *function* `f`, any item `i` satisfies that function's precondition, meaning that precondition is always true.
This ensures we are always allowed to call the closure with any value.

Taking things a step further, we want to ensure that the closure state also never changes because this will make our future efforts simpler.
We can achieve this using the special `unnest` {% sn() %}
The precise definition of this predicate is a little complicated but for our purposes it relates the states produced by successive calls to a mutable closure.
Though today we consider the name `unnest` deprecated, we haven't yet found a good replacement term. We're open to [suggestions](https://github.com/creusot-rs/creusot/issues/new).
{% end %}
predicate provided by Creusot.
The second clause thus states that for any state `f`, all states `g` which can be derived from it must be equal to `f`.

## First run

If we run Creusot on this code, we get back a positive result telling us everything was proven succcessfully, but *what* did we prove?
By default, Creusot attempts to prove that all preconditions are upheld and all panics are avoided, this base level of verification is generally called "safety" and when it is true, it guarantees that your program does not crash.