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
-- > import XMonad.Hooks.ManageHelpers (composeOne, isDialog, (-?>))
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
-- Note: Since xmonad-contrib 0.18, the combinators in
-- "XMonad.Hooks.ManageHelpers" (such as "composeOne", "-?>", "-->>", and
-- "-?>>") are generalised over any "Monad", so they work with "Query" directly
-- and are not duplicated here.


module XMonad.KeyBindings.Query (
    -- * Query Helpers
    -- $helpers
    queryFocused, queryFocused',
    queryState, queryState'
  ) where

import XMonad
import XMonad.StackSet (peek)


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
