> {-# LANGUAGE ConstraintKinds, TypeFamilies #-}
> module MonoidalCats where

> import Control.Category
> import Data.Bifunctor
> import GHC.Exts (Constraint)

> class (Category c) => MonoidalCategory c where
>     type Tensor ::
