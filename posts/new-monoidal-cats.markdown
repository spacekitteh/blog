---
title: Proposal for monoidal category classes in the base Haskell library
date: 2014-09-15
author: Sophie Taylor
tags: haskell, category theory, maths, ghc, wip
---

Introduction and rationale
------------
Why more category classes in base? Because monoidal categories are a very common abstraction under the guise of many things: for example, every arrow (and generalised arrow) is a monoidal category; and every Cartesian category (that is, with products) is also a monoidal category. Additional structures which monoidal categories may have include braidings, involutions, traces (loops), and so on. Monoidal categories form the basis of circuit diagrams, signal flow diagrams, control theory diagrams, and pretty much any other "process" diagram which somehow models the real world. 

Having all these classes in base would allow a single set of abstractions to optimise and deal with, and may simplify compositionality of different libraries such as FRP and signal processing libraries. Many of the classes included here are in Edward Kmett's library "categories" and other associated libraries.

Bifunctors
----------
The first thing needed is bifunctors:

```haskell
-- | Minimal definition: @bimap@ 
class (Category r, Category s, Category t) => Bifunctor p r s t | p r -> s t, p s -> r t, p t -> r s where
    bimap :: r a b -> s c d -> t (p a c) (p b d)
```

  This is a straight copy/paste from Edward's categories package. Bifunctors are needed because the monoidal operation is a endobifunctor!
  
Examples:

```haskell
instance Bifunctor (,) (->) (->) (->) where
    bimap f g (a,b)= (f a, g b)

instance Bifunctor Either (->) (->) (->) where
    bimap f _ (Left a) = Left (f a)
    bimap _ g (Right a) = Right (g a)
```

Binoidal categories
-------------------
Binoidal categories are used to model categories in which *evaluation order is significant* - they are not commutative in time, i.e., impure functions. If a category is only a binoidal category, we cannot reorder computations at will. :(

```haskell
class (Category k, Bifunctor p k k k) => Binoidal k p
  inLeft :: k a (k b (p a b))
  inRight :: k b (k a (p a b))
```

Examples:

```haskell
instance Binoidal (->) (,) where
  inLeft a = \x -> (a,x)
  inRight b = \x -> (x,b)
  
instance Binoidal (->) Either where
  inLeft a = \_ -> Left a
  inRight b = \_ -> Right b
```

This isn't really a necessary class either, and the infirst/insecond functions could (probably should) be pushed into PreMonoidal. The only thing which would be lost is non-associative binoidal categories, which aren't that interesting, as far as I can tell.

Premonoidal categories
----------------------
First we need an associative operation:
```haskell
class (Bifunctor p k k k, Category k) => Associative k p where
    associateRight :: k (p (p a b) c) (p a (p b c))
    associateLeft :: k (p a (p b c)) (p (p a b) c)
```

Examples:
```haskell
instance Associative (->) (,) where
        associateRight ((a,b),c) = (a,(b,c))
        associateLeft (a,(b,c)) = ((a,b),c)

instance Associative (->) Either where
        associateRight (Left (Left a)) = Left a
        associateRight (Left (Right b)) = Right (Left b)
        associateRight (Right c) = Right (Right c)
        associateLeft (Left a) = Left (Left a)
        associateLeft (Right (Left b)) = Left (Right b)
        associateLeft (Right (Right c)) = Right c
```

Now for premonoidal categories themselves:

```haskell
class (Binoidal k p, Associative k p) => PreMonoidal k p where
    type Id k p :: *
    cancelLeft :: k (p (Id k p) a) a
    cancelRight ::k (p a (Id k p)) a
    unitLeft :: k a (p (Id k p) a)
    unitRight :: k a (p a (Id k p))
```

Another possible naming could be:

```haskell
class (Binoidal k p, Associative k p) => PreMonoidal k p where
    type Id k p :: *
    eliminateLeft :: k (p (Id k p) a) a
    eliminiateRight ::k (p a (Id k p)) a
    introduceLeft :: k a (p (Id k p) a)
    introduceRight :: k a (p a (Id k p))
```


Monoidal categories
-------------------
A monoidal category is just a commutative (in time) premonoidal category - that is, a *pure* premonoidal category; as such, no extra function definitions need to be made.
```haskell
class PreMonoidal k p => Monoidal k p
```

Note: REEEEEAAAALLLY need to give names to the isomorphisms (the associator and the left/right unit isos)

Braided categories
---------------------------
Braidings introduce a "swap" function.

```haskell
class Associative k p => Braided k p where
    braid :: k (p a b) (p b a)
```

Examples:

```haskell
instance Braided (->) Either where
    braid (Left a) = Right a
    braid (Right b) = Left b

instance Braided (->) (,) where
    braid ~(a,b) = (b,a)
```

Symmetric categories
-----------------------------
When braid . braid = id

```haskell
class Braided k p => Symmetric k p

swap :: Symmetric k p => k (p a b) (p b a)
swap = braid
```

Examples:
```haskell
instance Symmetric (->) Either
instance Symmetric (->) (,)
```

String diagrams
---------------
String diagrams can be thought of as an abstract form of network diagrams. Circuit diagrams, Simulink diagrams, signal flow diagrams, etc, are all string diagrams. By having one language to interpret them all (monoidal categories), the level of abstraction is raised tremendously!

[Here is a list of various string diagrams for various classes.](http://ncatlab.org/nlab/show/string+diagram)

Converting proc notation to give monoidal categories where possible
-------------------------------------------------------------------
In much the same manner that do notation should give Applicatives where possible, proc notation should give monoidal categories where possible. This is theoretically acceptable because all Arrows are monoidal categories with extra structure.

Template Haskell support for loading string diagrams
----------------------------------------------------
This would be in another library but it would certainly be made so much easier with monoidal category support in base+ghc

Internal logic
--------------
The internal logic/type theory of symmetric monoidal categories is linear logic/type theory; for plain monodial categories, it is "non-commutative multiplicative intuitionistic linear logic/type theory". 

Links/further reading
=====================
* [Theory and Practice of Causal Commutative Arrows](http://www.thev.net/PaulLiu/download/thesis-liu.pdf)
* [Categories in Control](http://arxiv.org/abs/1405.6881)
* [Generalized Arrows](https://www.eecs.berkeley.edu/Pubs/TechRpts/2014/EECS-2014-130.html)
* [Tangled Circuits](http://www.tac.mta.ca/tac/volumes/26/27/26-27.ps)
* [Algebras of open dynamical systems on the operad of wiring diagrams](http://math.mit.edu/~dspivak/informatics/WD-ODE.pdf)
* [Toward a categorical foundation of functional reactive programming](http://math.mit.edu/~dspivak/informatics/talks/CMU2014-01-23.pdf)

todo
====
braidings, terminal/initial objects, daggers, loops, init/causality

