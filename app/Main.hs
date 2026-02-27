module Main where

import System.IO

shell :: IO ()
shell = do
    putStr "hshell> "
    input <- getLine
    print (input)
    shell

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    shell
