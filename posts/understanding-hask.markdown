---
title: Understanding Hask
date: 2014-09-14
author: Sophie Taylor
tags: haskell, maths, category theory
---

If you're not well versed in category theory, then understanding many of Edward Kmett's libraries can be a tad difficult. Here, I shall try and guide us through his library Hask, which is a category theory library with a distinctive lens flavour. I won't be going into the details of all the classes, just the basics (i.e., what I can figure out without making my headache worse)

We begin, comrades, with the beginning: Basic categories. As such, let us look at Hask.Category, and more specifically, the class Category':

```haskell
class Category' (p :: i -> i -> *) where
  type Ob p :: i -> Constraint
  id :: Ob p a => p a a
  (.) :: p b c -> p a b -> p a c
```

A category is a type which takes two type arguments in some kind, and produces a type in the standard kind, *.

It contains a collection of objects, encoded as a Constraint on Haskell types, an identity morphism on objects, and a method of composing morphisms.

An example of this is the plain old Hask category that we are used to from Prelude:
```haskell
instance Category' (->) where
  type Ob (->) = Vacuous (->)
  id x = x
  (.) f g x = f (g x)
```
Here, the object constraint is trivially satisfied by every Haskell type, and the identity and compose functions are as expected.

We can see what an endomorphism is, too:
```haskell
type Endo p a = p a a
```
That is, a morphism from an object to itself. 

Now, let's look at functors!

```haskell
class (Category' (Dom f), Category' (Cod f)) => Functor (f :: i -> j) where
  type Dom f :: i -> i -> *
  type Cod f :: j -> j -> *
  fmap :: Dom f a b -> Cod f (f a) (f b)
```

The constraints tell us that the domain and codomain of the functor must both be categories. Indeed, we must specify the domain and codomain as type families.

Since data types basically correspond to functors on objects, which form part of the type (i.e. for a functor F, the object transformation is from A to FA), we only have to specify the morphism transformations; that is, fmap.


