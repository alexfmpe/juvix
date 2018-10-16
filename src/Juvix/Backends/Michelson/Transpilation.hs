module Juvix.Backends.Michelson.Transpilation where

import qualified Data.Text                                    as T
import           Protolude                                    hiding (catch)

import qualified Juvix.Backends.Michelson.Emit                as M
import qualified Juvix.Backends.Michelson.Lift                as M
import           Juvix.Backends.Michelson.Transpilation.Types
import qualified Juvix.Backends.Michelson.Typed               as M
import qualified Juvix.Backends.Michelson.Untyped             as MU
import           Juvix.Lang
import           Juvix.Utility

transpileToMichelsonSourceFile ∷ ∀ m . (MonadError TranspilationError m) ⇒ Expr → m Text
transpileToMichelsonSourceFile expr = do
  (M.SomeExpr code, paramTy, retTy, storageTy) <- transpileToMichelson expr
  return $ T.unlines [
    "parameter " <> M.emitType paramTy <> ";",
    "return " <> M.emitType retTy <> ";",
    "storage " <> M.emitType storageTy <> ";",
    "code " <> M.emitFinal code <> ";"
    ]

transpileToMichelson ∷ ∀ m . (MonadError TranspilationError m) ⇒ Expr → m (M.SomeExpr, MU.Type, MU.Type, MU.Type)
transpileToMichelson expr = do
  let michelsonExprType = MU.LamT (MU.PairT MU.StringT MU.StringT) (MU.PairT MU.StringT MU.StringT)
  case michelsonExprType of
    MU.LamT start@(MU.PairT paramTy startStorageTy) end@(MU.PairT retTy endStorageTy) | startStorageTy == endStorageTy → do
      case (M.liftType paramTy, M.liftType startStorageTy, M.liftType retTy, M.liftType endStorageTy) of
        (DynamicType (Proxy ∷ Proxy paramTyLifted), DynamicType (Proxy ∷ Proxy startStorageTyLifted), DynamicType (Proxy ∷ Proxy retTyLifted), DynamicType (Proxy ∷ Proxy endStorageTyLifted)) → do
          let michelsonExpr ∷ MU.Expr
              michelsonExpr = MU.Nop
          (M.SomeExpr (expr ∷ M.Expr (M.Stack a) (M.Stack b)), _) ← do
            case M.liftUntyped michelsonExpr (M.typeToStack start) (DynamicType (Proxy :: Proxy startStorageTyLifted)) of
              Right r -> return r
              Left e  -> throw (DidNotTypecheck e)
          case (eqT ∷ Maybe (a :~: (M.Pair paramTyLifted startStorageTyLifted, ())), eqT ∷ Maybe (b :~: (M.Pair retTyLifted endStorageTyLifted, ()))) of
            (Just Refl, Just Refl) →
              return (M.SomeExpr expr, paramTy, retTy, startStorageTy)
            _ →
              throw (InternalFault "cannot unify start/end stack types")
    _ -> throw (InvalidInput "invalid type for main function")
