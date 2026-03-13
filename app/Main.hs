module Main where

import System.IO
import System.Process
import System.Directory
import System.Exit (ExitCode(..))
import Helpers

import Data.Map (Map)
import qualified Data.Map as Map

data Command = Exit | Ls (Maybe String) | Pwd | Cd (Maybe String) | SVar (String, String) | Env | Echo String

shell :: Map String String -> [String] -> IO ()
{-
    The main hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
        [String] - Remaining commands/operators to run
    Returns:
        IO Monad - shell process
-}

shell env_map [] = do -- no more pending operations, get next command from user
    putStr "hshell> "
    input <- getLine
    let (current_cmd, rest) = splitAtOperator (words input)
    processCurrentCmd env_map current_cmd rest
        
shell env_map cmd_lst = do -- an operation is in-flight
    let (current_cmd, rest) = splitAtOperator cmd_lst
    processCurrentCmd env_map current_cmd rest

execute :: Map String String -> Command -> [String] -> IO ()
{-
    Given a command from hshell, executes it and returns to hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
        Command - The command to be run
        [String] - Remaining commands/operators to run
    Returns:
        IO Monad - shell process
-}
execute _ Exit _ = putStrLn "Exiting hshell..."

-- ls
execute env_map (Ls Nothing) rest_cmds = do
    exitCode <- system "ls"
    handleNext env_map exitCode rest_cmds
execute env_map (Ls (Just dir)) rest_cmds = do
    exitCode <- system ("ls " ++ dir)
    handleNext env_map exitCode rest_cmds

-- pwd
execute env_map Pwd rest_cmds = do
    exitCode <- system "pwd"
    handleNext env_map exitCode rest_cmds

-- cd
execute env_map (Cd Nothing) rest_cmds = do
    homeDir <- getHomeDirectory
    setCurrentDirectory homeDir
    handleNext env_map ExitSuccess rest_cmds

execute env_map (Cd (Just ('~':'/':rest))) rest_cmds = do
    homeDir <- getHomeDirectory
    let full_path = homeDir ++ "/" ++ rest
    status <- doesDirectoryExist full_path
    if status
        then do
            setCurrentDirectory full_path
            handleNext env_map ExitSuccess rest_cmds
        else do
            putStrLn "Directory doesn't exist."
            handleNext env_map ExitSuccess rest_cmds

execute env_map (Cd (Just dir)) rest_cmds
    | dir == "~" = execute env_map (Cd Nothing) rest_cmds
    | otherwise = do
        status <- doesDirectoryExist dir
        if status
        then do
            setCurrentDirectory dir 
            handleNext env_map ExitSuccess rest_cmds
        else do
            putStrLn "Directory doesn't exist."
            handleNext env_map ExitSuccess rest_cmds

-- env
execute env_map Env rest_cmds = do
    showEnvVars env_map
    handleNext env_map ExitSuccess rest_cmds

-- echo
execute env_map (Echo str) rest_cmds
    | null str = do 
        putStrLn ""
        handleNext env_map ExitSuccess rest_cmds
    | head str == '$' = do
        case Map.lookup (tail str) env_map of 
            Just x  -> putStrLn x
            _ -> putStrLn ""
        handleNext env_map ExitSuccess rest_cmds
    | otherwise = do 
        putStrLn str
        handleNext env_map ExitSuccess rest_cmds

-- adding new env var
execute env_map (SVar (var, value)) rest_cmds = do
    let env_map' = Map.insert var value env_map
    handleNext env_map' ExitSuccess rest_cmds

handleNext :: Map String String -> ExitCode -> [String] -> IO ()
{-
    Determines whether to continue executing the argument or not, based on the operator.

    Arguments: 
        Map String String - The env var map
        ExitCode - exit code from previous command
        [String] - Sequence of remaining command (e.g. ["&&", "ls"])
    Returns:
        IO () - continues/stops shell 
-}
handleNext env_map _ [] = Main.shell env_map [] -- ready to parse new input
handleNext env_map exitcode (current_op:rest)
    | current_op == "&&" && exitcode == ExitSuccess = Main.shell env_map rest
    | current_op == "&&" && exitcode /= ExitSuccess = do
        putStrLn "Execution failed, exiting..."
        Main.shell env_map []
    | current_op == "||" && exitcode /= ExitSuccess = do
        putStrLn "Execution failed, continuing to next command"
        Main.shell env_map rest
    | current_op == "||" && exitcode == ExitSuccess = Main.shell env_map []
    | current_op == ";" = Main.shell env_map rest
    | otherwise = Main.shell env_map rest -- Invalid operator

processCurrentCmd :: Map String String -> [String] -> [String] -> IO()
{-
    Process the current command.
    Arguments:
        Map String String - Mapping of vars to values of env variables

        Consider ["ls", "-l", "&&", "pwd"]:
        [String] - The current command (e.g. ["ls", "-l"])
        [String] - The rest of the command list (e.g. ["&&", "pwd"])
-}
processCurrentCmd env_map current_cmd rest = 
    case current_cmd of
        ["exit"]    -> execute env_map Exit []
        ["ls"]      -> execute env_map (Ls Nothing) rest
        ["ls", dir] -> execute env_map (Ls (Just dir)) rest
        ["pwd"]     -> execute env_map (Pwd) rest
        ["cd", dir] -> execute env_map (Cd (Just dir)) rest
        ["cd"]      -> execute env_map (Cd Nothing) rest
        ["env"]     -> execute env_map (Env) rest
        ["echo"]    -> execute env_map (Echo "") rest
        ["echo", str]    -> execute env_map (Echo str) rest
        [s] | Just (var, val) <- splitbyAssignment s -> execute env_map (SVar (var, val)) rest
        _           -> if containsRedir current_cmd 
                       then 
                          do 
                            exit_status <- system (unwords current_cmd)
                            handleNext env_map exit_status rest
                       else putStrLn "Invalid Command." >> Main.shell env_map rest

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    Main.shell Map.empty [] -- start with empty map of env vars, empty cmd list
