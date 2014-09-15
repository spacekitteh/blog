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
class (Category r, Category t) => PFunctor p r t | p r -> t, p t -> r where
    first :: r a b -> t (p a c) (p b c)

class (Category s, Category t) => QFunctor q s t | q s -> t, q t -> s where
    second :: s a b -> t (q c a) (q c b)

-- | Minimal definition: @bimap@ 

-- or both @first@ and @second@
class (PFunctor p r t, QFunctor p s t) => Bifunctor p r s t | p r -> s t, p s -> r t, p t -> r s where
    bimap :: r a b -> s c d -> t (p a c) (p b d)
```

  This is a straight copy/paste from Edward's categories package. Bifunctors are needed because the monoidal operation is a endobifunctor!
  
Examples:

```haskell
instance PFunctor (,) (->) (->) where first f = bimap f id
instance QFunctor (,) (->) (->) where second = bimap id
instance Bifunctor (,) (->) (->) (->) where
    bimap f g (a,b)= (f a, g b)

instance PFunctor Either (->) (->) where first f = bimap f id
instance QFunctor Either (->) (->) where second = bimap id
instance Bifunctor Either (->) (->) (->) where
    bimap f _ (Left a) = Left (f a)
    bimap _ g (Right a) = Right (g a)
```
  
Binoidal categories
-------------------
Binoidal categories are used to model categories in which *evaluation order is significant* - they are not commutative in time, i.e., impure functions. If a category is only a binoidal category, we cannot reorder computations at will. :(

```haskell
class (Category k, Bifunctor p k k k) => Binoidal k p
  inFirst :: k a (k b (p a b))
  inSecond :: k b (k a (p a b))
```

Examples:

```haskell
instance Binoidal (->) (,) where
  inFirst a = \x -> (a,x)
  inSecond b = \x -> (x,b)
  
instance Binoidal (->) Either where
  inFirst a = \_ -> Left a
  inSecond b = \_ -> Right b
```

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
```

Monoidal categories
-------------------
A monoidal category is just a commutative (in time) premonoidal category - that is, a *pure* premonoidal category; as such, no extra function definitions need to be made.
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
