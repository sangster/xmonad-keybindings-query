-----------------------------------------------------------------------------
-- |
-- Module       : XMonad.KeyBindings.Query
-- Copyright    : (c) Jon Sangster
-- License      : BSD
--
-- Maintainer   : Jon Sangster <jon@ertt.ca>
-- Stability    : unstable
-- Portability  : unportable
--
-- This module provides helper function to query XMonad's state before running
-- an "X" action.
--
-- > import XMonad.KeyBindings.Query
-- > main =
-- >     xmonad def `additionalKeys`
-- >       [ ((mod4Mask .|. shiftMask, xK_z), appSpecificKey)
-- >       ]
-- >  where
-- >    appSpecificKey = queryFocused' $ composeOne
-- >      [ isDialog               -?> safeSpawn "notify-send" ["this is a dialog"]
-- >      , className =? "firefox" -?> safeSpawn "notify-send" ["firefox is focused"]
-- >      ]
--
-- This module is heavily inspired by Spencer Janssen and Lukas Mai's work in
-- "XMonad.ManageHook" and "XMonad.Hooks.ManageHelpers", respectively.
--
-- Note: This module reimplements some functions from
-- "XMonad.Hooks.ManageHelpers", with more general type-signatures. They
-- function identically, so the versions exported from this module can be used
-- in both cases.


module XMonad.KeyBindings.Query (
    Match(..),

    -- * Query Helpers
    -- $helpers
    queryFocused, queryFocused',
    queryState, queryState',

    -- * Compositions
    -- $compose
    composeAll, composeOne,

    -- * ???
    (/=?), (<==?), (</=?),
    (-->), (=?), (<&&>), (<||>),
    (-?>), (-->>), (-?>>),
    title, appName, className, stringProperty
  ) where

import Data.Bool (bool)
import XMonad
import XMonad.StackSet (peek)
import XMonad.Hooks.ManageHelpers ((/=?), (<==?), (</=?))


-- | A grouping type which can hold the outcome of a predicate Query.
-- This is analogous to group types in regular expressions.
data Match a = Match Bool a


infixr 0 -?>, -->>, -?>>

{- $helpers
"queryFocused" is the primary function exported by this module. It allows you to
supply a "Query" to determine what action to execute based on the currently
focused window. It's possible that no window has focus, so you must supply an
action to perform in that case. The "queryFocused'" version of this function
does nothing if no window has focus.

"queryState" and "queryState'" are more generic versions, if you want to
evaluation a window other than the one that curretly has focus; however, in this
case you must provide a function to extract your window from the current
"XState".
-}


-- | Query the focused window of the current windowset. If no window has focus,
-- the given "fallback" is returned.
queryFocused :: X a
             -> Query a
             -> X a
queryFocused = queryState $ peek . windowset


-- | Like "queryFocused", but does nothing if the query doesn't match the
-- currently focused window.
queryFocused' :: Query ()
              -> X ()
queryFocused' = queryFocused idHook


-- | Query XMonad's current state and use the given function to extract a
-- "Window" from it. That window is then passed through the "Query". If
-- "Nothing" is returned from the function, then "fallback" will be used.
queryState :: (XState -> Maybe Window)
           -> X a
           -> Query a
           -> X a
queryState f fallback q = get >>= maybe fallback (runQuery q) . f


-- | Like "queryState", but does nothing if the given function returns
-- "Nothing".
queryState' :: (XState -> Maybe Window)
            -> Query ()
            -> X ()
queryState' f = queryState f idHook


{- $compose
"composeOne" and "composeAll" are the same as their counterparts exported by
"XMonad.Hooks.ManageHelpers" and "XMonad.ManageHook". The versions exported by
this module have more generic signatures, so you can use them both for
ManageHooks and this.
-}

-- | Like "composeAll", but it stops at the first element that returns a "Just".
composeOne :: Monoid a
           => [Query (Maybe a)]
           -> Query a
composeOne = foldr (\q z -> q >>= maybe z return) idHook


-- | A helper operator for use in "composeOne". It takes a condition and an
-- action; if the condition fails, it returns "Nothing" from the "Query" so
-- "composeOne" will go on and try the next rule.
(-?>) :: Query Bool
      -> Query a
      -> Query (Maybe a)
p -?> f = p >>= bool (pure Nothing) (Just <$> f)


-- | A helper operator for use in "composeAll". It takes a condition and a
-- function taking a grouped datum to action. If "p" is true, it executes the
-- resulting action.
(-->>) :: Monoid b
       => Query (Match a)
       -> (a -> Query b)
       -> Query b
p -->> f = p >>= \(Match b m) -> bool mempty (f m) b


-- | A helper operator for use in "composeOne". It takes a condition and a
-- function taking a groupdatum to action. If "p" is true, it executes the
-- resulting action. If it fails, it returns "Nothing" from the "Query" so
-- "composeOne" will go on and try the next rule.
(-?>>) :: Monoid b
       => Query (Match a)
       -> (a -> Query b)
       -> Query (Maybe b)
p -?>> f = p >>= \(Match b m) -> bool mempty (Just <$> f m) b
