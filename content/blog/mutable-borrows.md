---
title: 'Verifying Mutable Borrows'
date: '2024-06-24'
draft: true
---

In my last [post](rust-formal-verification) I gave a high-level idea of why Rust is interesting to researchers of formal verification.
In this post I want to dive more into the details: specifically how we can leverage the Rust type system to model mutable borrows.