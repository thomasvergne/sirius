{-# LANGUAGE ConstraintKinds  #-}
{-# LANGUAGE FlexibleContexts #-}

module Language.Sirius.ANF.Monad where

import qualified Control.Monad.RWS       as RWS
import qualified Language.Sirius.ANF.AST as ANF
import Language.Sirius.CST.Modules.Annoted (Annoted)
import qualified Language.Sirius.Typecheck.Definition.Type as T

type MonadANF m = (RWS.MonadRWS [(Text, Text)] () Int m)

fresh :: MonadANF m => m Text
fresh = do
  i <- get
  put (i + 1)
  return $ "$a" <> show i

createLet :: [(Annoted T.Type, ANF.Expression)] -> [ANF.Expression]
createLet []              = []
createLet ((name', e):xs) = ANF.ELet name' e : createLet xs
