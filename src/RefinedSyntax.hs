{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE FlexibleInstances #-}

-- {-# LANGUAGE OverloadedStrings #-}
-- {-# LANGUAGE RecordWildCards #-}
-- {-# Language DeriveAnyClass #-}

module RefinedSyntax where

-- import Data.Text          (Text, pack, unpack)
-- import GHC.Generics
-- import Data.List.NonEmpty hiding (fromList)
-- import Data.ByteString       (ByteString)
-- import Data.Aeson
-- import Data.Aeson.Types
-- import Data.Vector (fromList)

import Data.Map.Strict (Map, empty)
import Data.Functor.Foldable
import Data.Tuple (swap)

import qualified Syntax as S

-- AST post typechecking

type Id = String

data Behaviour = Behaviour
  { _name :: Id
  , _contract :: Id
  , _interface :: Interface
  , _preconditions :: [Exp 'MBool]  -- possibly empty
  , _cases :: [Case]                -- nonempty
  , _return :: Maybe Typed
}

data Interface = Interface Id [Decl]
  deriving Show

data Creation
  = CDefn Defn
  | CDecl Decl

data Case = Case (Exp 'MBool) (Both [Store] Typed)
  deriving Show

data Store = Store (S.Ref Typed) Typed
  deriving Show

data Decl = Decl MType Id
  deriving Show

data Defn = Defn Decl Typed

-- types understood by proving tools
data MType
  = MBool
  | MInt
  | MMap MType MType
  deriving (Eq, Show)

-- needed for matching on typed expressions
data Witness t where
  WBool :: Witness 'MBool
  WInt :: Witness 'MInt
deriving instance Show (Witness t)
deriving instance Eq (Witness t)

-- typing context
type Gamma = Map Id MType

-- typed expressions
data Exp (t :: MType) where

  -- booleans
  BoolLit :: Bool -> Exp 'MBool
  Not :: Exp 'MBool -> Exp 'MBool
  And  :: Exp 'MBool -> Exp 'MBool -> Exp 'MBool
  Or   :: Exp 'MBool -> Exp 'MBool -> Exp 'MBool
  Impl :: Exp 'MBool -> Exp 'MBool -> Exp 'MBool

  -- binary relations
  Eq  :: Exp a -> Exp a -> Exp 'MBool
  NEq  :: Exp a -> Exp a -> Exp 'MBool
  LE :: Exp 'MInt-> Exp 'MInt-> Exp 'MBool
  LT :: Exp 'MInt-> Exp 'MInt-> Exp 'MBool
  GE :: Exp 'MInt-> Exp 'MInt-> Exp 'MBool
  GT :: Exp 'MInt-> Exp 'MInt-> Exp 'MBool

  -- integers
  IntLit :: Integer -> Exp 'MInt
  Add :: Exp 'MInt -> Exp 'MInt -> Exp 'MInt
  Sub :: Exp 'MInt -> Exp 'MInt -> Exp 'MInt
  Mul :: Exp 'MInt -> Exp 'MInt -> Exp 'MInt
  Div :: Exp 'MInt -> Exp 'MInt -> Exp 'MInt
  Mod :: Exp 'MInt -> Exp 'MInt -> Exp 'MInt
  Exp :: Exp 'MInt -> Exp 'MInt -> Exp 'MInt

  Read :: S.Ref Typed -> Exp a
  -- missing ethenv
  ITE :: Exp 'MBool -> Exp a -> Exp a -> Exp a
  -- missing underscore
  -- missing bytestrings
  -- missing newaddr
  
deriving instance Show (Exp t)

data Typed where
  T :: Exp t -> Witness t -> Typed
deriving instance Show Typed


data Both a b
  = Dex a
  | Sin b
  | Both a b
  deriving (Eq, Show)


instance Semigroup (Exp 'MBool) where
  a <> b = And a b

instance Monoid (Exp 'MBool) where
  mempty = BoolLit True

{-


-- intermediate json output helpers ---
instance ToJSON Behaviour where
  toJSON (Behaviour {..}) = object  [ "name" .= _name
                                    , "contract"  .= _contract
                                    , "mode" .= (String . pack $ show _mode)
                                    , "creation" .= _creation
                                    , "interface"  .= (String . pack $ show _interface)
                                    , "preConditions"   .= (toJSON _preconditions)
                                    , "stateUpdates" .= toJSON _stateUpdates
                                    , "contracts" .= toJSON _contracts
                                    , "returns" .= toJSON _returns]


instance ToJSON StorageLocation where
  toJSON (IntLoc a) = object ["location" .= toJSON a]


instance ToJSON StorageUpdate where
  toJSON (IntUpdate a b) = object ["location" .= toJSON a
                                  ,"value"    .= toJSON b]

instance ToJSON (TStorageItem b) where
  toJSON (DirectInt a) = String $ pack a
  toJSON (DirectBool a) = String $ pack a
  toJSON (DirectBytes a) = String $ pack a
  toJSON (MappedInt a b) = symbol "lookup" a b 
  toJSON (MappedBool a b) = symbol "lookup" a b
  toJSON (MappedBytes a b) = symbol "lookup" a b

instance ToJSON ReturnExp where
   toJSON (ExpInt a) = object ["sort" .= (pack "int")
                              ,"expression" .= toJSON a]
   toJSON (ExpBool a) = object ["sort" .= (String $ pack "bool")
                               ,"expression" .= toJSON a]
   -- toJSON (ExpTuple a) = object ["sort" .= (String $ pack "tuple")
   --                              ,"expression" .= toJSON a]


instance ToJSON (Exp Int) where
  toJSON (Add a b) = symbol "+" a b
  toJSON (Sub a b) = symbol "-" a b
  toJSON (Exp a b) = symbol "^" a b
  toJSON (NewAddr a b) = symbol "newAddr" a b
  toJSON (IntVar a) = String $ pack a
  toJSON (LitInt a) = toJSON a
  toJSON (IntEnv a) = String $ pack $ show a
  toJSON (TEntry a) = toJSON a
  toJSON v = error $ "todo: json ast for: " <> show v

instance ToJSON (Exp Bool) where
  toJSON (And a b)  = symbol "and" a b
  toJSON (LE a b)   = symbol "<" a b
  toJSON (GE a b)   = symbol ">" a b
  toJSON (Impl a b) = symbol "=>" a b
  toJSON (NEq a b)  = symbol "=/=" a b
  toJSON (Eq a b)   = symbol "==" a b
  toJSON (LEQ a b)  = symbol "<=" a b
  toJSON (GEQ a b)  = symbol ">=" a b
  toJSON (LitBool a) = String $ pack $ show a
  toJSON (Neg a) = object [   "symbol"   .= pack "not"
                          ,  "arity"    .= (Data.Aeson.Types.Number 1)
                          ,  "args"     .= (Array $ fromList [toJSON a])]
  toJSON v = error $ "todo: json ast for: " <> show v

symbol s a b = object [  "symbol"   .= pack s
                      ,  "arity"    .= (Data.Aeson.Types.Number 2)
                      ,  "args"     .= (Array $ fromList [toJSON a, toJSON b])]


instance ToJSON (Exp ByteString) where
  toJSON a = String $ pack $ show a

  -}
