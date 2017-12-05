For the past year I've been

- introduce project
- purpose of ill
  - pedagogical
  - good error messages
  - strict semantics?
    - optional semantics
- current state of the project
- recent work
- upcoming work

When I discovered compilers, .

I was frustrated that the projects I found seemed to fall into two classes: toys and production compilers. The toys show the core of a new idea but often, it's not clear how to take it further. All those little details like error messages, data types, global bindings are left out. They get in the way of toy compilers but are often just as complicated to get right as the latest type theory or intermediate representation.

On the other hand, the production compilers take care of all these details, at the price of dramtically increased complexity. Real languages, even the most well intentioned and formalized ones are full of edge cases. They have tons of compiler flags that'll change the output, add logs, debug information and more. The problem with them is extracting the details you're interested in is a challenge, the production details obscure the core algorithms of the compilation process

The catch is, jumping the gap from toy to production is not trivial, and there aren't a ton of resources available for hobbyists in that space. Even the reference books like _The Implementation of Functional Programming Languages_ leave out key wrinkles, like datatypes. I wanted a language and compiler that could showcase all the agorithms in a clear and well documented manner.

I was always curious how compilers implemented ADTs, pattern matching, how they handled typeclasses and type errors. So, for the past year, I've been working on and off on a language I have tentatively called Ill. When finished it should provide a stepping stone between toy and production languages. It should actually perform all the _exercises left for the reader_. Where necessary, I hope to aim for simplicity over performance or optimality.

The language itself is not radical in it's content, it's a Hindley-Milner system, with type classes and algebraic data types. I feel like this provides an interesting base to explore the major components of a compiler. I've decided to keep the semantics of the language unspecified, I'm hoping to play around with both the implementation of call-by-name and call-by-value semantics.

Why am I writing this now? Especially if I've already been months of development? Well I was originally planning on waiting to write about the compiler once it was 'finished', but after harrassing the users of Shopify's #fp channel inncessantly with progress reports, a brave soul recommended I harrass everyone on the internet instead.

# Situation Report

So far I've made quite a lot of progress on the compiler, it's even usable!

Here's a list of some of the stages I've implemented: tktk this needs a lot of rewording tktk

- Parser: I've built a parser ontop of the great `megaparsec` library. There are a couple more features I'd like to support, notably, infix expressions and including more context in parse errors.
- Type Checker: I've implemented a fairly basic bi-directional type checker, it performs binding group analysis to support mutual recursion, and can infer and check types for functions, including trait constraints. Throughout the typechecking, each term is annotated with it's type, information which is used in future passes.
- Trait desugaring: Once a module has been type checked, traits are converted into ordinary datatypes, trait instances are converted into specific instances of the datatypes, and trait methods are converted into dictionary lookups, extracting the correct method from the correct instance of the trait.
- Pattern matching desugaring: In most functional languages, pattern matching is a core method of control flow. In the case of ill, functions can match multiple patterns simultaneously, using a variety of different types of patterns. As it turns out, all those features can be reduced to a much simpler model where only one pattern is inspected at a time. This pass converts all the pattern matching in a module to this simpler representation
- Core Language: Since the user facing language will often have a fairly complex AST, it can be useful to reduce the complexity of the AST before performing optimization or code generation. Like many other functional languages, I chose to simplify everything to a more barebones lambda calculus, in fact, using pretty much the same representation as GHC does internally.
- Desugaring to Core: I've also implemented the pass that actually converts a module into Core.
- Core Linter: This phase checks that the desugaring happened correctly. Turns out, its actually difficult to do it correctly.
- Core Interpreter: What's the point of a compiler if you can't actually use it? I made a simple call-by-need interpreter that evaluates Core modules.

What needs to be done
  - Improved error messages from:
    - Type checker
    - Parser
    - Desugarer
    - Core linter
  - Code generation
    - Optional semantics
  - Imports / Modules

# Recent Work

tktk introduce core tktk

Most recently I've been working on the Core Linter. The Core Linter is a pass that validates the correctness of a core language module. This involves both type checking and performing secondary lints like checking that certain terms only appear in normal forms. This pass is based off of GHC's identically named pass. Within GHC this pass forms a key part of the desugaring pipeline, it's used to check that the various Core-to-Core passes only produce valid programs.

Currently all the linter does is perform type checking and name resolution. This process is very similar to other Hindley-Milner systems, there are let-bindings, lambdas, case-expressions, but there is one major addition: type-lambdas and type-applications. Doing this allows us to avoid needing to use full unification, instead, we bind and explicitly apply polymorphic type variables.

In practice we transform a function like:

```
fn id(x)
  x
end
```
Which has the type `forall a . a -> a`, into:

```
(id :: forall a . a -> a) = \(@a) -> \(x :: a) -> x

```
and at a callsite we apply the _specific_ `a` that we are using, transforming `id(1)` into  `id(@Int)(1)`. the `@X` syntax represents a type application.  Carrying this extra information around helps simplify the machinery that interacts with the Core language.

This next section will provide an overview of how the linter is structured and implemented, but won't attempt to explain every last detail, instead I'll zoom in on the bits I consider interesting.

The typechecker is structured as a simple recursive descent, and implements the signature `runLinter :: CoreModule -> Either String ()`. Internally, it uses a `MonadState` and `MonadError` constraint wrapped up in an alias called `LintM`.

The state consists simply of :

```haskell
data LintEnv = E
  { boundNames  :: M.Map String (Type String)
  , boundTyVars :: [String]
  } deriving (Show, Eq)
```

In the future we may store the kind of bound type variables and check that they are being correctly applied. For now, we assume that they are correct, an unfounded assumption but one that holds up fairly well in practice due to the poor type level language of Ill.

The errors are reported as strings for now, though one of the lowest hanging fruits for improvement will be to replace that with a simple ADT that can track more context than a string easily could.

Operating on this monad we define a few helpers that wrap the state monad providing a more useful api and basic error messages:

```haskell
bindNames :: LintM m => [Var] -> m a -> m a
bindName  :: LintM m => Var   -> m a -> m a

lookupName  :: LintM m => String -> m (Type String)
lookupTyVar :: LintM m => String -> m ()
```

tktktk

The core of the linter occurs in the `lintCore :: LintM m => CoreExp -> m (Type String)` function, this method does the actual recursion on a core expression, determining it's type along the way. Within this, there are two specific constructor alternatives I want to focus on, `Lambda` and `App`. These of course form the core of a lambda calculus so it's only reasonable that most of attention would be spent on them.

A lambda term consists of `Lambda n (Core n)`, in this case `n = Var` so we get `Lambda Var (Core Var)`. The first term represents the binder of the lambda and the second one the body over which it's applied. Remember, we have both type and term lambdas to check. These are distinguished in the constructors of `Var`, there is a constructor for term binders `Id` and one for type binders `TyVar`. The type of the entire lambda depends on this constructor. A type-lambda `\(@a) -> exp` will have the type `forall a. (typeOf exp)` whereas a value-lambda `\a -> exp` will have the type `a -> (typeOf exp)`. Putting this together the function alternative to lint lambdas looks like:

```haskell
lintCore l@(Lambda bind exp) = do
  bodyTy <- bindName bind (lintCore exp)
  return $ makeCorrectFunTy bind bodyTy
  where
  makeCorrectFunTy id@Id{} bodyTy    =  idTy bind `tFn` bodyTy
  makeCorrectFunTy tv@TyVar{} bodyTy =  case bodyTy of
    Forall vars ty -> Forall (varName tv : vars) ty
    ty             -> Forall [varName tv] ty
```

Lambda applications share a similar duality, we need to distinguish between applying a type-variable and term-variable. Unfortunately, these two appear harder to unify in code so we treat them separately.

### Type applcations

When we're given a type application `App f t` that tells us information about `f`, notably we know it must be a polymorphic function, otherwise we wouldn't be able to apply a type to it. This is leveraged in the `splitForall` function which takes the type of `f` and extracts the first polymorphic variable from it:

```haskell
splitForall (Forall [x] ty) = (x, ty)
splitForall (Forall (x:xs) ty) = (x, Forall xs ty)
splitForall ty = error . show $ error message...
```

Once we've popped off the first type variable `x` of the function, we apply a substitution over the remaining function type, replacing occurences of `x` with type applied type `ty`. Going back to the example of the function `id`. This step takes `id :: forall a . a -> a` and applies the substitution `(a, Int)` to `a -> a` giving us the final type `Int -> Int`.

### Value applications

Value applications have a familiar structure to type applications but with dual constraints. Instead of checking that the function's type is polymorphic, we check that it's been fully applied, and consists of a term-lambda. We then check that the argument type of the function matches the provided argument type.

_The other alternatives can be found in the source code at XXXX_

The resulting `lintCore` is called by `runLinter`, which binds all the global names before linting each one. This function is now used in the test suite, checking that test programs compile down to valid core. During it's implementation I uncovered quite a few bugs in desugaring passes! tktk

Thanks for sticking with me through my rambling, I hope to write more posts on the design and implementation of other parts of the compiler in the weeks and months that come.
