module Main where

import System.IO
import System.Process

data Command = Exit | Ls (Maybe String) | Pwd

shell :: IO ()
shell = do
    putStr "hshell> "
    input <- getLine
    let cmds = words input
    case cmds of
        ["exit"]    -> execute Exit
        ["ls"]      -> execute (Ls Nothing)
        ["ls", dir] -> execute (Ls (Just dir))
        ["pwd"]     -> execute (Pwd)
        _           -> putStr "\nInvalid Command.\n" >> Main.shell

execute :: Command -> IO ()
execute Exit = putStrLn "Exiting hshell..."
execute (Ls Nothing) = callCommand "ls" >> Main.shell
execute (Ls (Just dir)) = callCommand ("ls " ++ dir) >> Main.shell
execute Pwd = callCommand "pwd" >> Main.shell


main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    Main.shell
