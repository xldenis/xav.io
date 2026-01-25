---
title: 'Verifying Filter in Rust'
date: '2026-01-11'
extra:
    unlisted: true
---

*This is a post I wrote in 2024 and only got around to publishing now.*

Last Friday I had the opportunity to do a proof with Creusot which I found quite
interesting and satisfying highlighting both the strengths and weaknesses of my
tool [Creusot](https://github.com/creusot-rs/creusot). I wanted to share this
proof with a broader audience, and share some insight into what verification
_actually_ looks like, the challenges it poses and the advantages it brings.

In this post we'll be considering the verification of `filter` in Rust which 
a supplied predicate to every element of an underlying iterator. 
Let's be very ambitious; we want to establish that the following assertion succeeds:
```rust
assert!((0..10).filter(|x| x < 10).next().is_some());
```

Obviously this assertion succeeds, but how do we _prove_ that? 
Crucially, to prove this program correct we'll need to establish the behavior of `filter`, which will take remainder of this post{% sn() %}In previous work, we gave a framework for reasoning about iterators in verification, which we'll be leaning on here. Add paper citation.{% end %}.

As a quick reminder, here's the code we'll be working on{% sn() %}The standard library version is written using additional helpers, but they don't change the meaning of the program {% end %}:

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

The need to fully describe a program is where a lot of the complexity of verification comes in. 
Verifiers live in a very manichean world, there are no degrees of truth, a program is either correct or it is not, and the most trivial incorrectness will be the downfall of the whole proof. 
<!-- give an example / explain why -->
We can't satisfied to with describing the happy or even the unhappy-paths, but _everything_ down to the most minor integer overflow must be accounted for as any violation could invalidate some aspect of our specification. 

## specifying filter
 
Let's try to formally state a specification for `filter`, saying: 

> `filter` produces an iterator consisting of exactly all the elements for which the provided predicate evaluated to `true`

To specify iterators, we can describe the valid sequences of elements produced by that iterator.
The tricky part here, is that for each element that `filter` produces an arbitrary amount of elements in the underlying iterator may have been scanned. 
Describing the valid sequences of `filter` requires establishing a correspondence with the elements of the underlying iterator.

```
iter (s):                 1   2   3   4   5   6   7   8   9   10
                              
     
iter.filter(is_even) (t):     2       4       6       8       10

m                             1       3       5       7        9

```

Let `m` be a mapping from the indexes of the values produced by `filter` into the values produced by `filter.iter`.

Now we can say, if `filter.iter` produces a sequence of values `s`, then we can say that the sequence `t`  that `filter` will produce is given by:

```
forall<i : _> 0 <= i && i < t.len() ==> t[i] == s[m(i)] 
```

This specification is written in Pearlite, the specification language of Creusot which has a Rust based syntax. It states simply that for all indexes in `t` the value of `t[i]` is the `m(i)`-th value of `s`. 
In our example: the 0-th value of `t` is the second value of `s`, etc..


Now, we can specify what it means to `filter` as-so: 

```rust 

impl Filter<I, P> {
    #[logic]
    fn produces(self, t: Seq<Self::Item>, end: Self) -> bool {
        pearlite! {
            exists<s: Seq<_>, m> {
                    self.iter.produces(s, end) && 
                    forall<i : _> 0 <= i && i < t.len() ==> t[i] == s[m(i)]
            })
        }
    }

    #[ensures(match result {
        Some(res) => self.produces_one(res),
        None => true
    }
    fn next(&mut self) -> Option<Self::Item> { .. } 
}
```

The syntax `exists` is an existential quantifier, as the name implies it says "there is some sequence of values such that...". 
We've also attached this specification to `next` saying that if we returned `Some` then we produced one value in our relation. 


Great! We've written a specification for filter, its correct, so let's run the solvers and move on to bigger better things...

```
cargo creusot prove
...
Goal Coma.vc_next_Filter_I_F: ✘ (16/19)
  vc_next_Filter_I_F [call_mut requires]
  vc_next_Filter_I_F [next ensures]
  vc_next_Filter_I_F [next ensures]
Library verif.creusot_scratch_rlib.impl_Iterator_for_Filter_I_F.next: ✘ (19/22)
```

Wow, that's a lot of errors, Creusot is not happy with our work. 
In particular, its telling us two things: first, we haven't shown we're allowed to call the closure in our code; second, even if we did, we haven't even shown this proves our postcondition!

Let's look at the closure part first.
What's happening here, is that Creusot is asking us to prove that we can satisfy the preconditions of the closure `self.func`. 
The closure passed to `filter` could be any value, even `|_| panic!("oops")`, to ensure the program doesn't panic, Creusot requires you to prove that you satisfy the precondition of whatever closure is passed in. 

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
      (forall<f : F, g : F> f.hist_inv(g) ==> f == g)
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
...
Goal Coma.vc_next_Filter_I_F: ✘ (17/19)
  vc_next_Filter_I_F [next ensures]
  vc_next_Filter_I_F [next ensures]
Library verif.creusot_scratch_rlib.impl_Iterator_for_Filter_I_F.next: ✘ (20/22)
```

Closer! The final problem is that we can't actually show that the values we return are the ones that satisfy our specification.
This is a classic problem when verifying loops: to "remember" facts across loops they need to be proven to to be _invariant_ over the given loop (unaffected by it). 

```rust
impl Invariant<I: Iterator, F: FnMut(&I::Item) -> bool> for Filter<F, I> {
    #[ensures(match result {
        Some(res) => self.produces_one(res),
        None => true
    })]
    fn next(&mut self) -> Option<I::Item> {
        let old_self = snapshot! { self };
        let mut produced = snapshot! { Seq::empty() };

        #[invariant(self.func == old_self.func)]
        #[invariant(old_self.iter.produces(*produced, self.iter))]
        while let Some(n) = self.iter.next() {
            produced = snapshot! { produced.push_back(n) };
            if (self.func)(&n) {
                return Some(n);
            }
        }

        None
    }
}
```

To finish our argument we need to add two invariants: the first one is remembering that our closure doesn't change when we call `func`, the second is recording the sequence of values produced by the inner iterator and witnessing that they are a valid sequence.


## conclusion 

In verification the simplest programs can turn into monsters, forcing you into arcane arguments about edge cases to establish correctness; or... you can simplify things. 
Often, we don't _actually_ want to run our programs on _every_ possible input, but instead there is an underlying notion of "reasonable" values that can suffice. 

I like the proof of `filter` for this since, by placing what is in practice a very minor restriction on our predicate, we're able to _drastically_ simplify the problem making it far easier to prove but almost more importantly far easier to understand! 

I've often found that beginners in verification struggle with this: your proof must account for all valid inputs, but that doesn't mean you should accept _all_ inputs, you can and should rule out the inputs that don't actually matter to you. 

<!-- 

```rust
pearlite! {
    self.func.hist_inv(succ.func) &&
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
