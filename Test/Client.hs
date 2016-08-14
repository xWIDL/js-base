import Language.JS.Type
import Language.JS.Platform
import Control.JS.Utils.Client

x    = JEVar  (Name "x")
zero = JEPrim (PNumber 0.0)
zeroi = JEPrim (PInt 0)


domains :: Domains
domains = Domains [(PTyNumber, [ "x" .@ (x .> zero)
                               , "x" .@ (x .== zero)
                               , "x" .@ (x .< zero)]),
                   (PTyInt   , [ "x" .@ (x .> zeroi)
                               , "x" .@ (x .== zeroi)
                               , "x" .@ (x .< zeroi)])]

onePointNine :: JsUnionVal
onePointNine = JsUnionVal [JVPrim PTyNumber ("x" .@ (x .== JEPrim (PNumber 1.9)))]

oneInt = JsUnionVal [JVPrim PTyInt ("x" .@ (x .== JEPrim (PInt 1)))]

testHarness f = do
    idl <- readFile "Test/prelude.webidl"
    startSession domains idl f

caseObjEval :: IO ()
caseObjEval = testHarness $ \handler -> do
    res <- newCons handler (Name "Bar") []
    print res

casePrimEval :: IO ()
casePrimEval = testHarness $ \handler -> do
    res <- call handler (LInterface (Name "Foo")) (Name "pos") []
    print res

caseWrongArgNum :: IO ()
caseWrongArgNum = testHarness $ \handler -> do
    res <- call handler (LInterface (Name "Foo")) (Name "pos") [onePointNine]
    print res

caseCallbackEval :: IO ()
caseCallbackEval = testHarness $ \handler -> do
    res <- call handler (LInterface (Name "Foo")) (Name "async") [oneInt, JsUnionVal [JVClos 1]]
    print res

main :: IO ()
main = caseCallbackEval
