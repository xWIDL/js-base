import Network.MessagePack.Server
import Language.JS.Type
import Language.JS.Platform

import Prelude hiding (div)
import Data.MessagePack
import Text.Read (readMaybe)
import Data.String.Utils
import Control.Monad (msum)
import Data.Either.Utils (maybeToEither)
import Control.Monad.IO.Class (liftIO)

type Hash = Int

call :: LVar -> Name -> [JsUnionVal] -> Server ()
call lvar name vals = do
    liftIO $ print lvar
    liftIO $ print name
    liftIO $ print vals
    return ()

construct :: Name -> [JsUnionVal] -> Hash -> Server JRef
construct iname vals hash = do
    liftIO $ print iname
    liftIO $ print vals
    liftIO $ print hash
    return $ JRef 1

true :: JAssert
true = JAssert (Name "x") (JEPrim (PBool True))

ifEqJust :: Eq a => a -> a -> Maybe a
ifEqJust a1 a2
  | a1 == a2 = Just a1
  | a1 /= a2 = Nothing

ifEqThen :: Eq a => a -> a -> b -> Maybe b
ifEqThen a1 a2 b
  | a1 == a2 = Just b
  | a1 /= a2 = Nothing

parseSingleVal :: String -> Either String JsVal
parseSingleVal "Bool" = Right (JVPrim PTyBool true)
parseSingleVal "Num" = Right (JVPrim PTyNumber true)
parseSingleVal "Str" = Right (JVPrim PTyString true)
parseSingleVal "Null" = Right (JVPrim PTyNull true)
parseSingleVal "UInt" = Right (JVPrim PTyInt true)
parseSingleVal "NotUInt" = Right (JVPrim PTyNumber true) -- XXX: too coarse
parseSingleVal s =
    maybeToEither s $ msum [ JVConst . PString <$> readMaybe s
                           , JVConst . PBool <$> msum [ ifEqThen "true" s True
                                                      , ifEqThen "false" s False ]
                           , JVConst . PNumber <$> readMaybe s
                           , JVConst . PInt <$> ((readMaybe s :: Maybe Double) >>=
                                                 (\n -> round <$> ifEqJust (fromIntegral (round n)) n)) ]


parseVal :: String -> Either String JsUnionVal
parseVal s = let vals = split "|" s in
             JsUnionVal <$> sequence (map parseSingleVal vals)

unknown :: JsValStr -> Server Int
unknown (JsValStr s) = do
    liftIO $ print (parseVal s)
    return 1

main = serve 8888 [ method "call" call
                  , method "unknown" unknown
                  , method "construct" construct ]

