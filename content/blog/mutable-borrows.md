---
title: 'Verifying Mutable Borrows'
date: '2024-06-24'
draft: true
---

In my last [post](rust-formal-verification) I gave a high-level idea of why Rust is interesting to researchers of formal verification.
In this post I want to dive more into the details: specifically how we can leverage the Rust type system to model mutable borrows.
We'll do this by translating Rust programs to equivalent *functional* programs.
When I say translation to functional programs, people often imagine this means using tons of iterators, recursion, etc, but that's almost entirely orthogonal.
Really, what we want is to eliminate the mutable state and the heap. This makes our target language look a lot like a fragment of OCaml or Haskell.
Verifying functional programs is considered easier, because we have eliminated these complicated features (mutable memory, heaps) which enable more powerful reasoning techniques.

Our objective is to find a way to interpret Rust programs into functional ones that faithfully *simulate* the original program's behaviors.
This means it should exhibit *at least* all of the behaviors of the original program though it may have even more{% sn() %}
In which case it is *over approximating*.
Over approximation ensures that if your simulated program satisfies a property `P`, then your original program must as well since every behavior of the original program is present in the simulation.
However, some properties might be true of your source program but not true in your simulation:
{% end % }