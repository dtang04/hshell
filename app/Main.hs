module Main where

import System.IO
import System.Process
import System.Directory

import Data.Map (Map)
import qualified Data.Map as Map

data Command = Exit | Ls (Maybe String) | Pwd | Cd (Maybe String) | SVar (String, String)

shell :: Map String String ->  IO ()
{-
    The main hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
    Returns:
        IO Monad - shell process
-}
shell env_map = do
    putStr "hshell> "
    input <- getLine
    let cmds = words input
    case cmds of
        ["exit"]    -> execute env_map Exit
        ["ls"]      -> execute env_map (Ls Nothing)
        ["ls", dir] -> execute env_map (Ls (Just dir))
        ["pwd"]     -> execute env_map (Pwd)
        ["cd", dir] -> execute env_map (Cd (Just dir))
        ["cd"]      -> execute env_map (Cd Nothing)
        [s] | Just (var, val) <- splitbyAssignment s -> execute env_map (SVar (var, val))
        _           -> putStr "\nInvalid Command.\n" >> Main.shell env_map

splitbyAssignment :: String -> Maybe (String, String)
{-
    Helper function for splitting by "=" for env vars.
    Arguments:
        String - The "var_name=var_val" string to split by
    Returns:
        Just (String, String) - if splitting was sucessful
        Nothing otherwise
-}
splitbyAssignment s = 
    case break (== '=') s of
        (var, '=':val) -> Just (var, val)
        _              -> Nothing

execute :: Map String String -> Command -> IO ()
{-
    Given a command from hshell, executes it and returns to hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
        Command - The command to be run
    Returns:
        IO Monad - shell process
-}
execute env_map Exit = putStrLn "Exiting hshell..."
execute env_map (Ls Nothing) = callCommand "ls" >> Main.shell env_map
execute env_map (Ls (Just dir)) = callCommand ("ls " ++ dir) >> Main.shell env_map
execute env_map Pwd = callCommand "pwd" >> Main.shell env_map
execute env_map (Cd Nothing) = do
    homeDir <- getHomeDirectory
    setCurrentDirectory homeDir
    Main.shell env_map
execute env_map (Cd (Just ('~':'/':rest))) = do
    homeDir <- getHomeDirectory
    setCurrentDirectory (homeDir ++ "/" ++ rest)
    Main.shell env_map
execute env_map (Cd (Just dir))
    | dir == "~" = execute env_map (Cd Nothing)
    | otherwise = setCurrentDirectory dir >> Main.shell env_map
execute env_map (SVar (var, value)) = do
    let env_map' = Map.insert var value env_map
    Main.shell env_map'

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    Main.shell Map.empty -- start with empty map of env vars
