module Helpers where

import Data.Map (Map)
import qualified Data.Map as Map

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

splitAtOperator :: [String] -> ([String], [String])
{-
    Ingests the current command until an operator is found.
    E.g. ["ls", "-la", "&&", "pwd", ";", "ls"] -> (["ls", "-la"], ["&&", "pwd", ";", "ls"])
    
    Arguments:
        [String] - The command list
    Returns:
        ([String], [String]) - The first element is the current command, the second element is the rest of the command list
-}
splitAtOperator [] = ([], [])
splitAtOperator (x:xs)
    | x `elem` ["&&", "||", ";"] = ([], x:xs) --end the current command if operator is found
    | otherwise =
        let (cmd_continue, rest) = splitAtOperator xs
        in (x:cmd_continue, rest)

containsRedir :: [String] -> Bool
{-
    Determines whether the current command has a redirection.

    Arguments:
        [String] - The current command
    
    Returns:
        Bool - True if > or >> or < is in the current command, False otherwise
-}
containsRedir cmd
    | ">" `elem` cmd = True
    | ">>" `elem` cmd = True
    | "<"  `elem` cmd = True
    | otherwise = False

displayHistory :: [String] -> IO()
{-
    Helper function for the hshell history command. Given a list of
    previous commands, displays it in a manner consistent with the UNIX history
    command.

    Ex. 
    1  ls
    2  test=5
    3  echo $test
    4  cd ~
    5  history

    Arguments:
        [String] - List of previous commands for the current hshell instance
    
    Returns:
        IO() - Prints histories to stdout in the above format.
-}
displayHistory entries = do
    mapM_ putStrLn [show i ++ "  " ++ cmd | (i, cmd) <- zip [1::Int ..] entries]
