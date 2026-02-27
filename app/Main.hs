module Main where

import System.IO
import System.Process
import System.Directory

data Command = Exit | Ls (Maybe String) | Pwd | Cd (Maybe String)

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
        ["cd", dir] -> execute (Cd (Just dir))
        ["cd"]      -> execute (Cd Nothing)
        _           -> putStr "\nInvalid Command.\n" >> Main.shell

execute :: Command -> IO ()
execute Exit = putStrLn "Exiting hshell..."
execute (Ls Nothing) = callCommand "ls" >> Main.shell
execute (Ls (Just dir)) = callCommand ("ls " ++ dir) >> Main.shell
execute Pwd = callCommand "pwd" >> Main.shell
execute (Cd Nothing) = do
    homeDir <- getHomeDirectory
    setCurrentDirectory homeDir
    Main.shell
execute (Cd (Just ('~':'/':rest))) = do
    homeDir <- getHomeDirectory
    setCurrentDirectory (homeDir ++ "/" ++ rest)
    Main.shell
execute (Cd (Just dir))
    | dir == "~" = execute (Cd Nothing)
    | otherwise = setCurrentDirectory dir >> Main.shell

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    Main.shell
