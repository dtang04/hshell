import Helpers
import Test.Hspec

main :: IO()
{-
    Simple test file that tests functions with no IO() return type.
-}
main = hspec $ do
    describe "splitAtOperator" $ do
        it "splits before &&" $
            splitAtOperator ["ls", "-la", "&&", "pwd"]
                `shouldBe` (["ls", "-la"], ["&&", "pwd"])
        it "splits before ||" $
            splitAtOperator ["ls", "||", "cd"]
                `shouldBe` (["ls"], ["||", "cd"])
        it "splits before ;" $
            splitAtOperator ["ls", ";", "cd"]
                `shouldBe` (["ls"], [";", "cd"])
        it "splits at first operator" $
            splitAtOperator ["ls", "-la", "&&", "pwd", ";", "ls"]
                `shouldBe` (["ls", "-la"], ["&&", "pwd", ";", "ls"])
        
    describe "splitbyAssignment" $ do
        it "splits at =" $
            splitbyAssignment "var1=test"
                `shouldBe` Just ("var1", "test")
        it "does not split if no =" $
            splitbyAssignment "var1test"
                `shouldBe` Nothing
        it "empty" $
            splitbyAssignment ""
                `shouldBe` Nothing
    
    describe "containsRedir" $ do
        it "finds >" $
            containsRedir ["ls", ">", "file.txt"]
                `shouldBe` True
        it "finds >>" $
            containsRedir ["pwd", ">>", "file.txt"]
                `shouldBe` True
        it "finds <" $
            containsRedir ["pwd",  "<", "file.txt"]
                `shouldBe` True
        it "doesn't find" $
            containsRedir ["ls", ";",  "ls",  ";", "pwd"]
                `shouldBe` False
