module Main where

import System.IO
import System.Process
import System.Directory

import Data.Map (Map)
import qualified Data.Map as Map

data Command = Exit | Ls (Maybe String) | Pwd | Cd (Maybe String) | SVar (String, String) | Env

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
        ["env"]     -> execute env_map (Env)
        [s] | Just (var, val) <- splitbyAssignment s -> execute env_map (SVar (var, val))
        _           -> putStrLn "Invalid Command." >> Main.shell env_map

execute :: Map String String -> Command -> IO ()
{-
    Given a command from hshell, executes it and returns to hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
        Command - The command to be run
    Returns:
        IO Monad - shell process
-}
execute _ Exit = putStrLn "Exiting hshell..."
-- ls
execute env_map (Ls Nothing) = callCommand "ls" >> Main.shell env_map
execute env_map (Ls (Just dir)) = callCommand ("ls " ++ dir) >> Main.shell env_map

-- pwd
execute env_map Pwd = callCommand "pwd" >> Main.shell env_map

-- cd
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

-- env
execute env_map Env = showEnvVars env_map >> Main.shell env_map

-- adding new env var
execute env_map (SVar (var, value)) = do
    let env_map' = Map.insert var value env_map
    Main.shell env_map'


-- Helper Functions --

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

showEnvVars :: Map String String -> IO ()
{-
    Helper function to show the entire env_map.
    Arguments:
        Map String String - The env var map.
    Returns:
        IO () - Prints to stdout
-}
showEnvVars env_map = 
    do
        let env_kv = Map.toList env_map
        mapM_ putKV env_kv
    where
        putKV (k, v) = putStrLn (k ++ "=" ++ v)

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    Main.shell Map.empty -- start with empty map of env vars
