{-# LANGUAGE TupleSections #-}

module Parse.Lexer where

import           Control.Applicative   (empty)
import           Control.Monad         (void)
import           Control.Monad.State

import           Text.Megaparsec       ((<|>))
import qualified Text.Megaparsec       as P
import qualified Text.Megaparsec.Lexer as L

import           Parse.Parse
import qualified Syntax                as Ch


reservedWords :: [String]
reservedWords =
  [ "from"
  , "fromjs"
  , "import"
  , "default"
  , "as"
  , "class"
  , "extends"
  , "module"
  , "exports"
  , "runs"
  , "const"
  , "infix"
  , "infixl"
  , "infixr"
  , "True"
  , "False"
  , "null"
  , "undefined"
  ]


scn :: Parser ()
scn = L.space (void P.spaceChar) empty empty


sc :: Parser ()
sc = L.space (void $ P.oneOf " \t") empty empty


lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc


rWord :: String -> Parser ()
rWord w = P.string w *> P.notFollowedBy P.alphaNumChar *> sc


leadingLowerCase :: Parser String
leadingLowerCase =
  lexeme $ (:) <$> P.lowerChar <*> (P.many P.alphaNumChar)


leadingUpperCase :: Parser String
leadingUpperCase =
  lexeme $ (:) <$> P.upperChar <*> (P.many P.alphaNumChar)


ident :: Parser String
ident = identWith ['_']


dotIdent :: Parser String
dotIdent = identWith ['_', '.']


identWith :: [Char] -> Parser String
identWith chars = lexeme (p >>= checkReserved)
  where
  p = (:) <$> P.letterChar <*> P.many (foldl (\acc ch -> acc <|> P.char ch) P.alphaNumChar chars)


prop :: Parser [String]
prop = lexeme $ do
  p  <- P.some $ P.try (ident <* P.char '.')
  p' <- ident
  return $ p ++ [p']


infixOp :: Parser String
infixOp = lexeme $ P.some $ P.oneOf "?|></$=+*^-~"


checkReserved :: String -> Parser String
checkReserved x =
  if x `elem` reservedWords
    then fail $ "Keyword " ++ show x ++ " is reserved."
    else return x


sym :: String -> Parser String
sym = L.symbol sc


integer :: Parser Integer
integer = lexeme L.integer


float :: Parser Double
float = lexeme L.float


parens :: Parser a -> Parser a
parens = P.between (sym "(") (sym ")")


brackets :: Parser a -> Parser a
brackets = P.between (sym "[") (sym "]")


braces :: Parser a -> Parser a
braces = P.between (sym "{") (sym "}")


doubleQuotes :: Parser a -> Parser a
doubleQuotes = P.between (sym "\"") (sym "\"")


string :: Parser String
string = P.many $ (P.noneOf ['"'] <|> P.char ' ')


comma :: Parser ()
comma = void $ sym ","


colon :: Parser ()
colon = void $ sym ":"


arrowr :: Parser ()
arrowr = void $ sym "->"


arrowl :: Parser ()
arrowl = void $ sym "<-"


equals :: Parser ()
equals = void $ sym "="


refIndent :: Parser ()
refIndent = do
  pos' <- L.indentLevel
  modify $ \s -> s { indentLevel = pos' }


resetIndent :: Parser ()
resetIndent = put emptyParserState


indented :: Parser ()
indented = void $ get >>= L.indentGuard scn GT . indentLevel


pos :: Parser Ch.Pos
pos = P.getPosition >>= \(P.SourcePos sf sline scol) ->
  return $ Ch.Pos sf (fromIntegral $ P.unPos sline) (fromIntegral $ P.unPos scol)
