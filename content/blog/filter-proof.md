---
title: 'Verifying Filter in Rust'
date: '2024-09-28'
draft: true
katex_enable: true
---

*This is a post I wrote last year and only got around to publishing now.*

I recently had a chance to do a cute proof of `filter` in Rust which I think highlights both the strengths and weakenesses of [Creusot]() the verification tool I developed in my thesis.
Verification can be counter-intuitive because often simple code can pose the greatest challenges.
Understanding *why* code is correct requires a totally different skill set than *writing* that code in the first place.
This proof highlights this tension.

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

For an arbitrary `Filter<I, F>` can you describe the conditions under which `next` will run?

Let's look at some concrete examples:

- `iter.filter(|i| i % 2 == 0)`
- `iter.filter(|i| { assert!(i != 0); true })`
- `iter.filter(|i| { cnt += 1; assert!(cnt < 10); i < cnt })`

Each call to `next` requires calling the provided closure (`F`) at least once, which in the first case is fine as our function is well defined for any input value. In the second case, its fine so long as we can guarantee a non-zero input, but in the third case things get a lot trickier, we can only call the closure 10 times before it starts panicking.

Closures are tricky! At each call to `next` we need to ensure the next closure call won't crash and that it sets us up in a state to perform the *following* call.
Dealing with this is where the complexity of our `map` proof emerged, complexity which really only helps express marginal cases, since especially in the case of `filter` we almost *never* pass a predicate with mutable state in.

Rather than having to prove the general case of `filter`, lets restrict ourselves only to a simpler one: immutable closures with no preconditions. To do this, we use a *type invariant*, restricting the valid instances of `Filter<I, F>` to the ones with the properties we care about:

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

The first clause, states that for all values of our *function* `f`, any item `i` satisfies that function's precondition, meaning that precondition is always true.
This ensures we are always allowed to call the closure with any value.
The second clause ensures immutability, stating that any closure state `g` derived from an initial state `f` must be equivalent to `f`.

With one change to the code, Creusot can now prove that our implementation of `filter` will never panic.

```rust
    fn next(&mut self) -> Option<I::Item> {
        #[invariant(inv(self.iter))]
        for item in &mut self.iter {
            if (self.func)(&item) {
                return Some(item);
            }
        }

        None
    }
```

This sleight-of-hand, ruling the tricky cases as undesirable and making them impossible is core to verification, figuring out what restrictions to place is where the art lies.