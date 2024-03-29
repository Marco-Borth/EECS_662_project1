-- file Name: project1.hs
-- file Author: Marco Borth, 2894114
-- description: project1 file containing AE Evaluation functions.

{-# LANGUAGE GADTs, FlexibleContexts #-}

-- Imports for Parsec
import Control.Monad
import Text.ParserCombinators.Parsec
import Text.ParserCombinators.Parsec.Language
import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec.Token

--
-- Simple caculator over naturals with no identifiers
--
-- Author: Perry Alexander
-- Date: Tue Jan 23 17:54:44 CST 2018
--
-- Source files for the Arithmetic Expressions (AE) language from PLIH
--

-- AST Definition

data AE where
  Num :: Int -> AE
  Plus :: AE -> AE -> AE
  Minus :: AE -> AE -> AE
  Mult :: AE -> AE -> AE
  Div :: AE -> AE -> AE
  If0 :: AE -> AE -> AE -> AE
  deriving (Show,Eq)

-- AE Parser (Requires ParserUtils and Parsec included above)

languageDef =
  javaStyle { identStart = letter
            , identLetter = alphaNum
            , reservedNames = [ "if0"
                              , "then"
                              , "else"
                              ]
            , reservedOpNames = [ "+","-","*","/"]
            }

lexer = makeTokenParser languageDef

inFix o c a = (Infix (reservedOp lexer o >> return c) a)
preFix o c = (Prefix (reservedOp lexer o >> return c))
postFix o c = (Postfix (reservedOp lexer o >> return c))

parseString p str =
  case parse p "" str of
    Left e -> error $ show e
    Right r -> r

expr :: Parser AE
expr = buildExpressionParser operators term

operators = [
  [ inFix "*" Mult AssocLeft
    , inFix "/" Div AssocLeft ]
  , [ inFix "+" Plus AssocLeft
  , inFix "-" Minus AssocLeft ]
  ]

numExpr :: Parser AE
numExpr = do i <- integer lexer
             return (Num (fromInteger i))

ifExpr :: Parser AE
ifExpr  = do reserved lexer "if0"
             c <- expr
             reserved lexer "then"
             t <- expr
             reserved lexer "else"
             e <- expr
             return (If0 c t e)


term = parens lexer expr
       <|> numExpr
       <|> ifExpr

-- Parser invocation
-- Call parseAE to parse a string into the AE data structure.

parseAE = parseString expr

-- Evaluation Functions
-- Replace the bodies of these functions with your implementations for
-- Exercises 1-4.  Feel free to add utility functions or testing functions as
-- you see fit, but do not change the function signatures.  Note that only
-- Exercise 4 requires you to integrate the parser above.

divide :: Int -> Int -> Int
divide x y | x - y >= 0 = 1 + divide (x - y) y
           | otherwise = 0

someNatVal :: Int -> AE
someNatVal x = Num x

liftNum :: (Int -> Int -> Int) -> AE -> AE -> AE
liftNum f (Num l) (Num r) = (Num (f l r))



evalAE :: AE -> Int
evalAE (Num n) =
  if n >= 0
    then n :: Int
    else error "ERROR: Only Natural Numbers are Allowed"

evalAE (Plus l r) = -- (liftNum (+) (evalAE (Num l)) (evalAE (Num r)))
  let x = evalAE(l)
      y = evalAE(r)
      in x + y

evalAE (Minus l r) =
  let x = evalAE(l)
      y = evalAE(r)
      in if x >= y
        then x - y
        else error "ERROR: Resulting Difference must be Natural"

evalAE (Mult l r) =
  let x = evalAE(l)
      y = evalAE(r)
      in x * y

evalAE (Div l r) =
  let x = evalAE(l)
      y = evalAE(r)
      in if y == 0
        then error "ERROR: Cannot divide by '0'"
        else divide x y

evalAE (If0 c l r) =
  let x = evalAE (c)
      in if x == 0
        then evalAE(l)
        else evalAE(r)



evalAEMaybe :: AE -> Maybe Int
evalAEMaybe (Num n) = do
  Just (evalAE (Num n))

evalAEMaybe (Plus l r) = do
  let x = evalAE (l)
  let y = evalAE (r)
  if x < 0 || y < 0
    then Nothing
    else Just (evalAE (Plus l r))

evalAEMaybe (Minus l r) = do
  let x = evalAE (l)
  let y = evalAE (r)
  if x < 0 || y < 0
    then Nothing
    else if y > x
      then Nothing
      else Just (evalAE (Minus l r))

evalAEMaybe (Mult l r) = do
  let x = evalAE (l)
  let y = evalAE (r)
  if x < 0 || y < 0
    then Nothing
    else Just (evalAE (Mult l r))

evalAEMaybe (Div l r) = do
  let x = evalAE (l)
  let y = evalAE (r)
  if x < 0 || y <= 0
    then Nothing
    else Just (evalAE (Div l r))

evalAEMaybe (If0 c l r) = do
  let f = evalAE (c)
  let x = evalAE (l)
  let y = evalAE (r)
  if f < 0 || x < 0 || y <= 0
    then Nothing
    else Just (evalAE (If0 c l r))



evalM :: AE -> Maybe Int
evalM (Num n) = do evalAEMaybe (Num n)
evalM (Plus l r) = do evalAEMaybe (Plus l r)
evalM (Minus l r) = do evalAEMaybe (Minus l r)
evalM (Mult l r) = do evalAEMaybe (Mult l r)
evalM (Div l r) = do evalAEMaybe (Div l r)
evalM (If0 c l r) = do evalAEMaybe (If0 c l r)

interpAE :: String -> Maybe Int
interpAE x = evalM(parseAE x)
