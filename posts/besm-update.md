---
date: 2018-09-08
title: 'ПП-BESM: Progress Report'
---

When I wrote my first post on ПП-BESM, I hadn't mentioned that I'd already started and made serious progress on my project. In this post I'll give a quick summary of what I've accomplished since then.

## 1 Encoding Source-Level Programs

As I mentioned in the previous post, source level programs had to be very tedious encoded as numbers. This encoding was very dependent on the exact position of various pieces of information, which made manually coding a tricky and tedious process. Luckily we aren't stuck in 1952 anymore. I wrote a program called `pp-besm` that is responsible for parsing a text representation of the program and producing the coded binary as a series of hexadecimal numbers (which can then be converted to actual binary).

`pp-besm` is mostly complete, but still needs several language features to be fully implemented, documented and tested. It is possible to write and encode many realistic programs with it already.

## ПП-BESM Compiler Machine Code

The book describes ПП-BESM in a lot of detail, giving a description for each of the hundreds of operators as well as flowcharts of how they all fit together. However, many things are left implicit so there is a lot of reverse engineering to do in order to figure out how various operators are actually written.

To help me during this process I create a suite of tools called `compile-pp`. This includes a Haskell DSL for writing the machine code, an assembler that can relocate basic blocks and link procedures together, and facilities to output the machine code in binary.

The DSL makes life much simpler for me since it allows for variables and labelled addresses instead of having to refer to everything by it's absolute address and adjusting things each time I go back to add or remove an instruction. I describe the programs as a series of operators, which are usually equivalent to a single basic block. Each operator has a corresponding label. This means that I can write `CCCC (op 19)` instead of having to figure out _where_ Operator 19 will end up in memory. I also am able to make good usage of the `RecursiveDo` extension of GHC which allows for 'circular' do blocks, letting me refer to _future_ variables in the _past!_

![Extract of operators for the program MP-1](/images/besm-haskell-operators.png)

The assembler takes the output of the DSL, a list of basic blocks and reorganizes them to minimize the amount of actual jump instructions that have to be inserted in the final code. It also links the code against a table of constants and any other procedures that were referenced.

Equipped with all these tools I was able to start making actual progress on ПП-BESM. The book divides the compiler into 3 passes, composed of a total of 14 programs using 1200 instructions and 150 constant values. So far I have been working on the first pass, PP-1. Of the 4 programs described I have implemented 2 fully (modulo remaining bugs) and I've implemented 60/112 operators on the third program.

I've copied the description of each operator in the book as a comment alongside it's Haskell implementation. This provides documentation and helps proof-read the machine code. Whenever there are ambiguities in the operator description, I try to leave notes explaining my thoughts and decisions.

As I've gotten used to writing working programs for the BESM, I've been able to at least 10x my speed. This gives me hope that I'll be able to finish the first pass in short order.

## 2 BESM-1 VM

In order to execute ПП-BESM and the resulting programs it generates, I needed a VM which could actually execute the instructions. I chose to write this VM in Rust as an autodidactic exercise. At this point it supports 16 / 33 operators, the ones that are missing are primarily related to multiplication and division, which I have been too lazy to implement.

The VM comes equipped with a TUI, which has many helpful debugging tools built in. It displays the current instruction in binary, hex, and decoded. It gives a list of the previous instructions, and has a logger that enables rust code to give additional information.

![The main VM screen](/images/besm-vm-main-screen.png)

It also features a memory visualizer, which allows users to view cells interpreted in different manners: binary, hex, float, instruction. This also allows users to look at the values of the magnetic drives attached to the BESM and in the future will show the printer output.

![The main VM screen](/images/besm-vm-memory-screen.png)

The development of the compiler program and the VM are intertwined and they've helped catch errors in each other. Besides implementing the rest of the instructions, I'd like to implement a breakpoint mechanism, instead of having to step through to an exact instruction it'd be helpful to be able to run up to the targeted instruction each time. Since each 39-bit word is stored in 64-bits, I've also considered using the upper 25-bits to store debug information about the program.
