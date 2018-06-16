---
date: 2018-06-11
title: 'This week in Ill: Error Messages'
---


For the past week I've been going through a phase of tech-debt cleannup in Ill. One of the objectives is to come up with a unified type for compiler phases. Most phases already have a type along the lines of `Module a_i -> Either e_i (Module a_i+1)`. The problem was the error type at each phase either had to be shared by _all_ phases leading to an unwiedly sum _or_ I had to unpack it between each phase.

A long time ago I read a [couple](https://gist.github.com/chrisdone/fd6c6f6a8c5b5d4d3c3f91289343629f) [great](https://github.com/jaspervdj/talks/blob/master/2017-skillsmatter-errors/slides.md#which-is-the-best-representation-2) posts on errors which presented a solution to this problem. They sat on the backburner while there were more important things to work on, but now I've decided to entirely overhaul the error handling as part of that. 2

I adopted Jasper's `Error` datatype, making that the shape of errors between subsystems. Internally, I'll use sum types to keep context about every error and then render it into a `Error` type.
