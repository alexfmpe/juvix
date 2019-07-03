module Juvix.Bohm.Type where

import Protolude

-- TODO:: Investigate if it would be advantageous to promote this to a well typed gadt
data Bohm
  = IntLit Int
  | Lambda SomeSymbol Bohm
  | Application Bohm Bohm
  | Infix' Op Bohm Bohm
  | Not Bohm
  | True'
  | False'
  | Letrec SomeSymbol Bohm
  | Let SomeSymbol Bohm Bohm
  | If Bohm Bohm Bohm
  | Cons Bohm Bohm
  | Nil
  | Car Bohm
  | Cdr Bohm
  | IsNil Bohm
  deriving Show


data Op = Mult | Plus | Sub | Division
        | Mod | Or | And | Eq | Neq | Lt | Gt | Ge | Le deriving Show
