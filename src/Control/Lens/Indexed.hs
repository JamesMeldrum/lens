{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Lens.Indexed
-- Copyright   :  (C) 2012 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  rank 2 types, MPTCs, TFs, flexible
--
-- Combinators for working with 'Indexed' functions.
----------------------------------------------------------------------------
module Control.Lens.Indexed
  ( Indexable(..)
  -- * Indexed Functions
  , Indexed(..)
  , (<.>), (<.), (.>)
  , icompose
  , reindexed
  -- * Indexing existing lenses, traversals, etc.
  , indexing
  ) where

import Control.Lens.Classes
import Control.Lens.Internal

infixr 9 <.>, <., .>

-- | Compose an 'Indexed' function with a non-indexed function.
--
-- Mnemonically, the @<@ points to the indexing we want to preserve.
(<.)  :: Indexable i k => Indexed i b c -> (a -> b) -> k a c
Indexed ibc <. ab = indexed $ \ia -> ibc (ab . ia)
{-# INLINE (<.) #-}

-- | Compose a non-indexed function with an 'Indexed' function.
--
-- Mnemonically, the @>@ points to the indexing we want to preserve.
(.>)  :: Indexable i k => (b -> c) -> Indexed i a b -> k a c
bc .> Indexed iab = indexed (bc . iab)
{-# INLINE (.>) #-}

-- | Remap the index.
reindexed :: Indexable j k => (i -> j) -> Indexed i a b -> k a b
reindexed ij (Indexed iab) = indexed $ \ ja -> iab $ \i -> ja (ij i)
{-# INLINE reindexed #-}

-- | Composition of 'Indexed' functions
--
-- Mnemonically, the @\<@ and @\>@ points to the fact that we want to preserve the indices.
(<.>) :: Indexable (i, j) k => Indexed i b c -> Indexed j a b -> k a c
f <.> g = icompose (,) f g
{-# INLINE (<.>) #-}

-- | Composition of 'Indexed' functions with a user supplied function for combining indices
icompose :: Indexable k r => (i -> j -> k) -> Indexed i b c -> Indexed j a b -> r a c
icompose ijk (Indexed ibc) (Indexed jab) = indexed $ \ka -> ibc $ \i -> jab $ \j -> ka (ijk i j)
{-# INLINE icompose #-}

-- | Transform an 'Traversal' into an 'Control.Lens.IndexedTraversal.IndexedTraversal', a 'Fold' into an 'Control.Lens.IndexedFold.IndexedFold', etc.
--
-- @
-- 'indexing' :: 'Control.Lens.Traversal.Traversal' s t a b -> 'Control.Lens.IndexedTraversal.IndexedTraversal' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Type.Lens' s t a b      -> 'Control.Lens.IndexedLens.IndexedLens' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Fold.Fold' s t          -> 'Control.Lens.IndexedFold.IndexedFold' 'Int' s t
-- 'indexing' :: 'Control.Lens.Iso.Iso' s t a b       -> 'Control.Lens.IndexedLens.IndexedLens' 'Int' s t a b
-- 'indexing' :: 'Control.Lens.Getter.Getter' s t        -> 'Control.Lens.IndexedGetter.IndexedGetter' 'Int' s t a b
-- @
indexing :: Indexable Int k => ((a -> Indexing f b) -> s -> Indexing f t) -> k (a -> f b) (s -> f t)
indexing l = indexed $ \iafb s -> case runIndexing (l (\a -> Indexing (\i -> i `seq` (iafb i a, i + 1))) s) 0 of
  (r, _) -> r
{-# INLINE indexing #-}
