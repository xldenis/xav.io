---
title: Sofrware Archeology in 2026
date: '2026-01-26'
extra:
    unlisted: true
---

For the past 7 or so years, on and off, I've been recreating the compiler for the very first programming language created in the USSR. 
This project has waxed and waned as a function of my interest, time and other hobbies, but I've always come back to it. 
Each time I've come back a little wiser, but also with new tools to apply to the problem. 
My current stint working on this is no exception as it's coincided with the arrival of viable models for coding and the whole agentic development process. 
Let's see how that's changed my approach here. 

## OCR and translations

To work on the PP-BESM compiler I have two sources: a copy of "Programming Programme for the BESM computer" a book providing a lot of high-level documentation and design information about the compiler, it includes annotated flowcharts for the entire compiler. 
The second are a set of digitized machine code files from the archives of Ershov which include a complete copy of the source code for an earlier draft of the compiler. 
The only problem is that these scans are all in low resolution russian, and I don't speak russian.  
In the past, I've used google translate to try and transcribe and translate the documents, but to very little success. 
A characteristic of these documents are that some letters are quite blurry and many words are shortened, the two would combien to completely trip up Google's OCR & translation, forcing me to transcribe individual words by hand. 

This time around I tried a different workflow, feeding the scans into Claude Code and asking it to first transcribe into legible Russian and then subsequently translate into English. A fascinating detail which greatly improves over an equivalent Google Translate workflow is that I was able to tell Claude that the transcription should be gramatically correct and when it would incorrectly parse a word, it was thus able to self-correct. 
Splitting the transcription and translation allowed me to perform a manual correction step for letters that were just too complicated to parse automatically. 

The models are not able to handle the grid layout of the scanned pages, so I found my self needing to chop up each line manually and feed them in individually. If I had more pages to scan I would have invested in a little bit of traditional OCR to split up the scans automatically, but I figured half an hour of toil was fine to do by hand.

## Debugging 

In this latest push on PP-BESM, most of the compiler has been finished, in the sense that all sub-processes have *an* implementation, though most definitely not the *correct* implementation, and there remain a lot of bugs to chase down. 
This is nothing new, I had already invested a lot into debugging functionality but most of those were built into the interactive debugger. 
They were powerful but not super ergonomic for tight debugging loops: I would identify a problem, make a change, rebuild, reload the vm and then set the breakpoints again manually. 
This was tolerable before but as I enter the final debugging phase of development the ergonomics start mattering more and more.

I had already built a non-interactive "tracing" functionality that would print the identifiers of all basic blocks that were visited in an execution, but it didn't support breakpoints. 
Adding the ability to specify breakpoints on the command line made it possible to drive this whole loop through an agent, especially when combined with the ability to print values from memory when a breakpoint is hit. 

All of this meant that I could identify a problem when running the compiler, tell claude to idenitfy the cause and then go and identify a fix. 
I've found so far that agents are not great at finding the correct fixes to bugs, there are typically too many complex and subtle interactions for them to handle, however, they are able to narrow the specific site and pathology of bugs quickly, in a way that truly does save a lot of time. 

## Going forward

This most recent spring working on PP-BESM has been quite impactful and I think I've now achieved ~90% completion of the compiler. I've arrived at a state where small programs actually compile successfully, though many language features are still buggy and will cause the compiler to loop or miscompile. In a future post I'll detail the actual progress in the compiler and what's left to go, but I'm optimistic 2016 might finally be the year the BESM lives again. 

