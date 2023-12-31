module Language.Sirius.Enumeration where

import qualified Language.Sirius.CST.Modules.Annoted       as C
import qualified Language.Sirius.Typecheck.Definition.AST  as A
import qualified Language.Sirius.Typecheck.Definition.Type as T
import Data.Text (toLower)
import qualified Language.Sirius.CST.Modules.Literal as C

convertEnumeration :: Monad m => A.Toplevel -> m [A.Toplevel]
convertEnumeration (A.TEnumeration (C.Annoted name _) types) = do
  let createFields (args T.:-> _) =
        zipWith (\t i -> ("v" <> show i, t)) args [0 .. length args]
      createFields _ = []
  let fields = map (\(C.Annoted name' ty) -> (name' <> "_variant", createFields ty)) types
  let union =
        A.TUnion
          name
          (zipWith
             (\(C.Annoted name' _) (name'', fields') -> C.Annoted (toLower (name' <> "_variant")) (T.TRec name'' (("type", T.TString) : fields')))
             types fields)
  let functions =
        zipWith
          (\(C.Annoted name' ty) i ->
             A.TFunction
               []
               (C.Annoted name' (T.TId name))
               (map (uncurry C.Annoted) $ createFields ty)
               (A.EBlock [
                A.EDeclaration "v" (T.TId name),
                A.EUpdate (A.UInternalField (A.UVariable "v" (T.TId name)) i) (A.EStruct (T.TId (name' <> "_variant")) (C.Annoted "type" (A.ELiteral (C.String $ toString name')) : map (\(name'', t) -> C.Annoted name'' (A.EVariable name'' t)) (createFields ty))),
                A.EVariable "v" (T.TId name)
               ]))
          types
          (replicate (length types) 0)
  return $ union : functions
convertEnumeration x = return [x]
