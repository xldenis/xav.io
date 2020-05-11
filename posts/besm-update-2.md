---
date: 2020-05-09
title: 'ПП-BESM: Progress Report 2
private: true
---

Sadly since my first post almost two years ago I haven't found the time or energy to write more about the work I was doing on the BESM language. However, that didn't stop me from making incremental progress. However, two years is a long time and I still found time to accomplish a lot. What follows is a quick recap of some of the things I did.

## The VM

Over time my emulator for the BESM machine has become more complete and sophisticated. Besides adding support for more operations, I've also developped a suite of debugging features which help me track down bugs in my compiler recreation. The simplest of these is a breakpoint functionality, which lets me stop when specific addresses are being executed. This is incredibly useful when I'm debugging a loop or just generally trying to observe a specific section of code. I'd like to also add memory breakpoints since often what I care about is when specific parts of data are being written or read so I can check that they are the expected values.

I also developped a system to load 'debug symbols' in with the code. The BESM compiler doesn't have "functions", instead it's structured as a control flow graph consisting of "operators" which come from the soviet programming system the "operator method". These operators are regrouped into several "procedures" or sub-graphs which are loaded one by one during the execution. Since the BESM computer used 39-bit words, and my binary format for the BESM machine code encoded one word in every 64-bit one, this left me with 25 bits of spare room for each instruction. In those spare bits I encoded the procedure and operator of each instruction. Then in the VM I would read that information out and produce a trace of the operators visited in order. This enabled me to visualize the "high-level" flow of a program execution, particularily useful to do things like count the number of loop iterations.

# The compiler

I also made a lot of progress on the actual implementation of the compiler. At some point last year I managed to implement the entire first pass and I believe I've eliminated most of the bugs in it. It's hard to be absolutely certain since it requires me to read the binary intermediate representations of the compiler. It's very interesting to see how Ershov squeezed common sub-expression elimination and other optimizations into those couple hundred instructions though.

As of last week, I've also implemented the entire second pass of the compiler which handled loops. There are surely tons of bugs hiding around in the implementation which is the next piece of work I'll have to attack.

The final pass which would layout the compiled program and print it's instructions to a tape printer is likely to be quite tricky. For the first two passes I found a source code listing of a prototype implementation in an archive of Ershov's notes. But there is no such sketch for the third pass! This is tricky because while I have the book he wrote on this compiler, the book doesn't detail all the tricks that he developped to implement things. It also doesn't explain all the data that is stored in the computer's read-only builtin memory which allowed him to cut down on constants in the actual compiler. Still, I hope to find at least a partial implementation of the third part of the compiler and hopefully I'll manage to get it implemented soon as well.


