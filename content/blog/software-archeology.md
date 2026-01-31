---
title: Software Archeology in 2026
date: '2026-01-26'
extra:
    unlisted: true
---

For the past 7 or so years, on and off, I've been recreating the compiler for the very first programming language created in the USSR. 
This project has waxed and waned as a function of my interest, time and other hobbies, but I've always come back to it. 
Each time I've come back a little wiser, but also with new tools to apply to the problem. 
My current stint working on this is no exception as it's coincided with the arrival of viable models for coding and the whole agentic development process. 
Let's see how that's changed my approach here. 

<!-- give context on besm and link to prior posts -->

## OCR and translations

To work on this project I have two families of sources: a copy of "Programming Programme for the BESM computer", a book written by Andrey Ershov detailing the design of the language and providing high-level documentation of the compulter. 
This book helps explain a lot of the reasoning and intention of the design but is fairly light on implementation details. 
The second are machine code listings from the archives of Andrey that include machine code listings for an earlier revision of the compiler. 

Unfortunately, since the documents are typewritten and the scans are moderately low resolution, quite a few letters blur together and become hard to distinguish. 
<!-- image from scan -->
This causes machine translation and OCR tools like Google Translate to trip up: if they can't reliably identify the source letters then the resulting translations turn into gibberish. 
Since I don't speak Russian it becomes very challenging for me to determine if the errors are caused by single-letter substitutions or something deeper. 
Historically this forced me into a tedious workflow in which I would manually transcribe words and run them through the translator, correcting lexicographic errors until the translation made sense. 

<!-- show source image, transcription and translation side by side  -->
This time around I tried a different workflow, feeding the scans into Claude Code and asking it to first transcribe into legible Russian and then subsequently translate into English.
The real breakthrough was asking Claude to loop over the translations by telling it that they should make grammatical sense in Russian, then when it would incorrectly parse a word, it was able to self-correct. 
Having access to the transcribed Russian also provided me with an opportunity to perform a final spell checking, which allowed me to catch the remaining typos before translating to English. 

I did find that the grid layout of the documents caused a lot of hallucinations, and that I was much better served by first chopping up the documents into individual lines before feeding those in for transcription, but that was comparatively much less work. 

## Closing the loop 

Debugging the PP-BESM compiler leverages the tooling I've built into the VM directly: breakpoints and tracing. 
Historically this tooling was interactive: breakpoints were set in in the VM TUI and had to be re-set each time the VM was reloaded. 
This made iterating on specific bugs quite tedious since things might subtly shift between runs and I would have to re-determine the correct breakpoint locations. 

<!-- short video of tui w debugger view -->

In my day job, I've found that Claude tends to be quite good at identifying which lines of code produce a specific behavior, why not here? 
To make that possible I augmented the VM with a bunch of CLI driven functionality, built in to the VM's tracing functions. 
Each time the compiler is compiled I generate metadata mappings of all basic block and variables to their addresses in memory. These can be used to set breakpoints when an address is executed or written to as well as printing for ranges of addresses to see what memory looks like at various stages. 

Adding the ability to specify breakpoints on the command line made it possible to drive this whole loop through an agent, especially when combined with the ability to print values from memory when a breakpoint is hit. 
Thus, when I'm debugging a specific problem in the compiler, like identifying why loops are being miscompiled, I ask Claude to trace what happens to specific values during compilation and it iteratively step through the execution to hunt down the flow of data. 

<!-- show a trace output -->

This new workflow has allowed me to significantly step up my debugging throughput, as while I work on a patch to one bug an agent can be running in the background to reproduce and isolate a different bug. 
I have found however that Claude is _hopeless_ when it comes to actually writing code for PP-BESM, the compiler is written in a self-referental and self-mutating manner that Claude just can't effectively reason about. 

## Going forward

Software archeology of the kind I've been pursuing is a marathon: accurately recreating software from partial sources is painstaking work. 
At the same time, most of this work is not very "creative", a lot of it comes down to stepping through the same 20 instructions a dozen times until the details click in place. 
For the first time since I've started working on this project I've felt like there are new tools I can apply to this problem which have made me faster and made the work less tedious. 
Let 2026 be the year the BESM lives again! 

