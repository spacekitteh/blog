---
title: Proposal for monoidal category classes in the base Haskell library
date: 2014-09-15
author: Sophie Taylor
tags: haskell, category theory, maths
---

Introduction and rationale
------------
Why more category classes in base? Because monoidal categories are a very common abstraction under the guise of many things: for example, every arrow (and generalised arrow) is a monoidal category; and every Cartesian category (that is, with products) is also a monoidal category. Additional structures which monoidal categories may have include braidings, involutions, traces (loops), and so on. Monoidal categories form the basis of circuit diagrams, signal flow diagrams, control theory diagrams, and pretty much any other "process" diagram which somehow models the real world. 

Having all these classes in base would allow a single set of abstractions to optimise and deal with, and may simplify compositionality of different libraries such as FRP and signal processing libraries. Many of the classes included here are in Edward Kmett's library "categories" and other associated libraries.

Bifunctors
----------
The first thing needed is bifunctors:

```haskell
-- | Minimal definition either 'bimap' or 'first' and 'second'

-- | Formally, the class 'Bifunctor' represents a bifunctor
-- from @Hask@ -> @Hask@.
--
-- Intuitively it is a bifunctor where both the first and second arguments are covariant.
--
-- You can define a 'Bifunctor' by either defining 'bimap' or by defining both
-- 'first' and 'second'.
--
-- If you supply 'bimap', you should ensure that:
--
-- @'bimap' 'id' 'id' ≡ 'id'@
--
-- If you supply 'first' and 'second', ensure:
--
-- @
-- 'first' 'id' ≡ 'id'
-- 'second' 'id' ≡ 'id'
-- @
--
-- If you supply both, you should also ensure:
--
-- @'bimap' f g ≡ 'first' f '.' 'second' g@
--
-- These ensure by parametricity:
--
-- @
-- 'bimap'  (f '.' g) (h '.' i) ≡ 'bimap' f h '.' 'bimap' g i
-- 'first'  (f '.' g) ≡ 'first'  f '.' 'first'  g
-- 'second' (f '.' g) ≡ 'second' f '.' 'second' g
-- @
class Bifunctor p where
  -- | Map over both arguments at the same time.
  --
  -- @'bimap' f g ≡ 'first' f '.' 'second' g@
  bimap :: (a -> b) -> (c -> d) -> p a c -> p b d
  bimap f g = first f . second g

  -- | Map covariantly over the first argument.
  --
  -- @'first' f ≡ 'bimap' f 'id'@
  first :: (a -> b) -> p a c -> p b c
  first f = bimap f id

  -- | Map covariantly over the second argument.
  --
  -- @'second' ≡ 'bimap' 'id'@
  second :: (b -> c) -> p a b -> p a c
  second = bimap id
```
  
  This is a straight copy/paste from Edward's bifunctors package. An alternate possibility is the PFunctor+QFunctor route from the categories package. Bifunctors are needed because the monoidal operation is a endobifunctor!
  
Binoidal categories
-------------------
Binoidal categories are used to model categories in which *evaluation order is significant* - they are not commutative in time, i.e., impure functions. If a category is only a binoidal category, we cannot reorder computations at will. :(

```haskell
class (Category k, Bifunctor p) => Binoidal k p
  type Op k p :: *
  
  inFirst :: a -> Op k p a b
  inSecond :: b -> Op k p a b
```

Premonoidal categories
----------------------
First we need an associative operation:
```haskell
class (Bifunctor p, Category k) => Associative k p where
    associateRight :: k (p (p a b) c) (p a (p b c))
    associateLeft :: k (p a (p b c)) (p (p a b) c)
```
Now for premonoidal categories themselves:

```haskell
class (Binoidal k p, Associative k p) => PreMonoidal k p where
    type Id k p :: *
    cancelLeft :: (Op k p) (Id k p) a -> a
    cancelRight :: (Op k p) a (Id k p) -> a
```

Monoidal categories
-------------------
A monoidal category is just a commutative premonoidal category - that is, a *pure* premonoidal category; as such, no extra function definitions need to be made.
```haskell
class PreMonoidal k p => Monoidal k p
```

Braided monoidal categories
---------------------------
Braidings introduce a "swap" function.

Symmetric monoidal categories
-----------------------------
When swap . swap = id

String diagrams
---------------
String diagrams can be thought of as an abstract form of network diagrams. Circuit diagrams, Simulink diagrams, signal flow diagrams, etc, are all string diagrams. By having one language to interpret them all (monoidal categories), the level of abstraction is raised tremendously!

Template Haskell support for loading string diagrams
----------------------------------------------------

todo
====
braidings, terminal/initial objects, daggers, loops, init/causality
