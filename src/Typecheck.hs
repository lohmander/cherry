module Typecheck where

import qualified Syntax              as Ch
import           Typecheck.Error
import           Typecheck.Inference (infer)
import           Typecheck.Solve (solve)
import           Typecheck.Environment (emptyEnv)


typecheck :: Ch.Module -> Either Error Ch.Module
typecheck m =
  case infer emptyEnv m of
    Left err -> Left err
    Right (_, constraints) -> case solve constraints of
      Left err -> Left err
      Right _  -> Right m
