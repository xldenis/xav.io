---
title: 'Verifying Filter in Rust'
date: '2024-09-28'
extra:
    unlisted: true
---

*This is a post I wrote last year and only got around to publishing now.*

Last Friday I had the opportunity to do a proof with Creusot which I found quite
interesting and satisfying highlighting both the strengths and weaknesses of my
tool [Creusot](https://github.com/creusot-rs/creusot). I wanted to share this
proof with a broader audience, and share some insight into what verification
_actually_ looks like, the challenges it poses and the advantages it brings.

In this post we'll be considering the verification of `filter` in Rust which 
a supplied predicate to every element of an underlying iterator.

Here's the code we'll be working on:

In Rust, iterators are one of the most foundational abstractions available and basically every program of more than 100 lines makes use of them and their various combinators. So what does it mean for an iterator to be correct?

That was the question we set out to answer in a 2023 paper I wrote with my advisors in which we formalized the correctness of iterators in terms of transitition systems.
In that paper, we proved the correctness of a dozen iterators including ones with side-effects like `iter_mut`, but none of them compared to the complexity of a simple `iter.map(|x| x)`.

Our capstone was a general proof of correctness for `map` which handled all the edge-cases including closures that have side-effects or can even panic.
That 300 line proof reveals a surprising complexity hiding in the 10 lines it to implement `map`, so what gives?

## blah

Since `map` is a bit complex, lets instead focus on something even *harder*: `filter`. What does it mean for `filter` to be correct? 1) the program *runs*, we're able to successfully pursue the iterator to its end, and 2) it produces the *expected* result.

As a reminder, here's the implementation of `filter`:

```rust
pub struct Filter<I: Iterator, F: FnMut(&I::Item) -> bool> {
||||||| parent of 509dcdd (rewrite again)
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
    pub func: P,
}

impl<I: Iterator, P: FnMut(&I::Item) -> bool> Iterator for Filter<I, P> {
    type Item = I::Item;

    fn next(&mut self) -> Option<I::Item> {
        while let Some(n) = self.iter.next() {
            if (self.func)(&n) {
                return Some(n);
            }
        }

        None
    }
}
```

When you want to formally verify a program you must start by giving it a specification. 
One of the great annoyances of formal verification is how precise that specification needs to be: in general your specification should describe *every possible input-output pair* to your program. 
In specific circumstances, you may be able to prove a looser specification if you know your program will only be used in specific ways but in the case of a library function like `filter`, you really don't know how it'll be used so you need to assume the worst. 


The need to fully describe a program is where a lot of the complexity of verification comes in. Verifiers live in a very manichean world, there are no degrees of truth, a program is either correct or it is not, and the merest incorrectness will be turned against you breaking your entire proof. 
<!-- give an example / explain why -->
We can't satisfied to with describing the happy or even the unhappy-paths, but _everything_ down to the most minor integer overflow must be accounted for as any violation could invalidate some aspect of our specification. 

## specifying filter
 
Let's try to formally state a specification for `filter`, saying: 

> `filter` produces an iterator consisting of exactly all the elements for which the provideed predicate evaluated to `true`

The tricky part here, is that for each element that `filter` produces an arbitrary amount of elements in the underlying iterator may have been scanned. To establish that the correspondence between the two exists, we need to obtain a mapping relating the two sequences of values.

```
1   2   3   4   5   6   7   8   9   10

   
    2       4       6       8       10

```

Let `m` be a mapping from the indexes of the values produced by `filter` into the values produced by `filter.iter`.

Now we can say, if `filter.iter` produces a sequence of values `s`, then we can say that the sequence `t`  that `filter` will produce is given by:

```
forall<i : _> 0 <= i && i < t.len() ==> t[i] == s[m(i)] 
```

This specification is written in Pearlite, the specificaiton language of Creusot which has a Rust based syntax. 

To specify an iterator we use a relation called `produces` captures the sequences that can be produced by an iterator. We can write our definition for filter as-so:

```rust 

impl Filter<I, P> {
    #[predicate]
    fn produces(self, t: Seq<Self::Item>, end: Self) -> bool {
        exists<s: Seq<_>, m> {
                self.iter.produces(s, end) && 
                forall<i : _> 0 <= i && i < t.len() ==> t[i] == s[m(i)]
        })
    }

    #[ensures(match result {
        Some(res) => self.produces(res, ^self),
        None => true
    }
    fn next(&mut self) -> Option<Self::Item> { .. } 
}
```

Great! We've written a specification for filter, its correct, so let's run the solvers and move on to biger better things...

```
cargo creusot prove

....

```

Wow, that's a lot of errors, Creusot is not happy with our work. In particular, it's telling us that calling `self.func` is an error:

```
self.func
^^^^^^^^^ some error here
```

What's happening here, is that Creusot is asking us to prove that we can satisfy the preconditions of the closure `self.func`. 
The closure passed to `filter` could be any value, even `|_| panic!("oops")`, to ensure the program doesn't panic, Creusot requires you to prove that you satisfy the precondition of whatever closure is pased in. 

This is where we can see the complexity of verification start to rear its head. 
We must ensure that at each iteration we have permission to call the closure, moreover, since the closure could be any `FnMut` (that is it could have arbitrary mutable borrows), we must account for the fact that the closure could be mutating its own captures.
Consider the following case:

```
let mut a = true;
(0..10).filter(|x|{ assert!(a); a = false; x % 2 == 0}).collect();
```

On the first iteration, we can successfully call the closure but on the second it will panic, which would violate our specification. 

## ugh, closures

as much as higher-order is convenient when writing programs, it is painful when verifying them. 
If we want to fully describe what `filter` can do, we must reason about why the closure remains invokable, even as it mutates its captures. 
Instead, we could just stick to the simple case, which captures what you generally want to use with `filter`: a pure, total predicate.
If our predicate has no precondition, and doesn't perform any side-effects, things become much simpler.

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

The trait `Invariant` has a single predicate which must be upheld by all "valid"
values of `Filter`, Creusot will automatically insert assertions checking that
this invariant is true at key points throughout your program.

The first clause of the invariant asserts that the precondition of `f` our closure is always satisfied for any input. 
The second clause is what ensures that we don't modify our environment, stating that if you derive `g` from `f` must be equal, an indirect way of saying the state hasn't been mutated. 

With our new invariant we can try verifying again:
```
cargo creusot prove

.... success!

```

## conclusion 

In verification the simplest programs can turn into monsters, forcing you into arcane arguments about edge cases to establish correctness; or... you can simplify things. 
Often, we don't _actually_ want to run our programs on _every_ possible input, but instead there is an underlying notion of "reasonable" values that can suffice. 

I like the proof of `filter` for this since, by placing what is in practice a very minor restriction on our predicate, we're able to _drastically_ simplify the problem making it far easier to prove but almost more importantly far easier to understand! 

I've often found that beginners in verification struggle with this: your proof must account for all valid inputs, but that doesn't mean you should accept _all_ inputs, you can and should rule out the inputs that don't actually matter to you. 

<!-- 

```rust
pearlite! {
    self.func.unnest(succ.func) &&
    // f here is a mapping from indices of `visited` to those of `s`, where `s` is the whole sequence produced by the underlying iterator
    // Interestingly, Z3 guesses `f` quite readily but gives up *totally* on `s`. However, the addition of the final assertions on the correctness of the values
    // blocks z3's guess for `f`.
    exists<s, f : Mapping<Int, Int>> self.iter.produces(s, succ.iter) &&
        // `f` is a monotone mapping
        (forall<i : _, j :_ > 0 <= i && i <= j && j < visited.len() ==> 0 <= f.get(i) && f.get(i) <= f.get(j) && f.get(j) < s.len()) &&
        // `f` is an injection from `visited` to `s`
        (forall<i : _, > 0 <= i && i < visited.len() ==> visited[i] == s[f.get(i)]) &&

        (forall<bor_f : &mut F> *bor_f == self.func && ^bor_f == self.func ==>
            (forall< i : _> 0 <= i &&  i < s.len() ==>  (exists<j : _> 0 <= j && j < visited.len() && f.get(j) == i) == bor_f.postcondition_mut((&s[i],), true))
            // (forall< i : _> 0 <= i &&  i < s.len() ==>  bor_f.postcondition_mut((&s[i],), true) ==> exists<j : _> 0 <= j && j < visited.len() && f.get(j) == i)
        )
}
``` -->
