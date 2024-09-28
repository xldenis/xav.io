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
