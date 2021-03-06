module Typecheck.Environment where

import qualified Data.Map as Map
import qualified Data.Set as Set

import qualified Type as T


type TypeVar = Map.Map String T.Scheme


data Environment
  = Environment
  { vars    :: TypeVar
  , aliases :: Map.Map String T.Alias
  , types   :: Set.Set T.Type
  }
  deriving (Show)


emptyEnv :: Environment
emptyEnv =
  Environment Map.empty Map.empty $ Set.fromList T.primaryTypes


unionEnvs :: [Environment] -> Environment
unionEnvs = foldl u emptyEnv
  where u env env' =
          Environment
          { vars    = Map.union (vars env) (vars env')
          , aliases = Map.union (aliases env) (aliases env')
          , types   = Set.union (types env) (types env')
          }


extend :: (String, T.Scheme) -> Environment -> Environment
extend (name, scheme) env =
  env { vars = Map.insert name scheme $ vars env }


alias :: String -> T.Alias -> Environment -> Environment
alias name a env =
    env { aliases = Map.insert name a $ aliases env }


remove :: String -> Environment -> Environment
remove name env = env { vars = Map.delete name $ vars env }


lookupVar :: String -> Environment -> Maybe T.Scheme
lookupVar var env = Map.lookup var $ vars env


lookupType :: T.Type -> Environment -> Maybe T.Type
lookupType t env =
  case t of
    T.Term{} ->
      if Set.member t $ types env
        then Just t
        else Nothing

    _ ->
      Just t
