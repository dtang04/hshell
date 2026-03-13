module Main where

import System.IO
import System.Process
import System.Directory
import System.Exit (ExitCode(..))
import Helpers

import Data.Map (Map)
import qualified Data.Map as Map

data Command = Exit | Ls (Maybe String) | Pwd | Cd (Maybe String) | SVar (String, String) | Env | Echo [String] | History 
                    | Clear | Cat String | Touch String | MkDir String | Rm String | RmDir String | Date

shell :: Map String String -> [String] -> [String] -> IO ()
{-
    The main hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
        [String] - Remaining commands/operators to run
    Returns:
        IO Monad - shell process
-}

shell env_map [] history = do -- no more pending operations, get next command from user
    putStr "hshell> "
    input <- getLine
    let (current_cmd, rest) = splitAtOperator (words input)
    processCurrentCmd env_map current_cmd rest history
        
shell env_map cmd_lst history = do -- an operation is in-flight
    let (current_cmd, rest) = splitAtOperator cmd_lst
    processCurrentCmd env_map current_cmd rest history

execute :: Map String String -> Command -> [String] -> [String] -> IO ()
{-
    Given a command from hshell, executes it and returns to hshell.
    Arguments:
        Map String String - Mapping of vars to values of env variables
        Command - The command to be run
        [String] - Remaining commands/operators to run
    Returns:
        IO Monad - shell process
-}
execute _ Exit _ _ = putStrLn "Exiting hshell..."

-- ls
execute env_map (Ls Nothing) rest_cmds history = do
    exitCode <- system "ls"
    handleNext env_map exitCode rest_cmds history
execute env_map (Ls (Just dir)) rest_cmds history = do
    exitCode <- system ("ls " ++ dir)
    handleNext env_map exitCode rest_cmds history

-- pwd
execute env_map Pwd rest_cmds history = do
    exitCode <- system "pwd"
    handleNext env_map exitCode rest_cmds history

-- cd
execute env_map (Cd Nothing) rest_cmds history = do
    homeDir <- getHomeDirectory
    setCurrentDirectory homeDir
    handleNext env_map ExitSuccess rest_cmds history

execute env_map (Cd (Just ('~':'/':rest))) rest_cmds history = do
    homeDir <- getHomeDirectory
    let full_path = homeDir ++ "/" ++ rest
    status <- doesDirectoryExist full_path
    if status
        then do
            setCurrentDirectory full_path
            handleNext env_map ExitSuccess rest_cmds history
        else do
            putStrLn "Directory doesn't exist."
            handleNext env_map ExitSuccess rest_cmds history

execute env_map (Cd (Just dir)) rest_cmds history
    | dir == "~" = execute env_map (Cd Nothing) rest_cmds history
    | otherwise = do
        status <- doesDirectoryExist dir
        if status
        then do
            setCurrentDirectory dir 
            handleNext env_map ExitSuccess rest_cmds history
        else do
            putStrLn "Directory doesn't exist."
            handleNext env_map ExitSuccess rest_cmds history

-- env
execute env_map Env rest_cmds history = do
    showEnvVars env_map
    handleNext env_map ExitSuccess rest_cmds history

-- echo
execute env_map (Echo args) rest_cmds history = go env_map args rest_cmds history
    where
        go env_map' [] rest_cmds' _ = do
            putStrLn ""
            handleNext env_map' ExitSuccess rest_cmds' history
        go env_map' (a:as) rest_cmds' _
            | null a = do 
                putStr ""
                go env_map' as rest_cmds' history
            | head a == '$' = do
                case Map.lookup (tail a) env_map of 
                    Just x  -> putStr (x ++ " ")
                    _ -> putStr " "
                go env_map as rest_cmds history
            | otherwise = do 
                putStr (a ++ " ")
                go env_map as rest_cmds history

-- history
execute env_map History rest_cmds history = do
    displayHistory history
    handleNext env_map ExitSuccess rest_cmds history

-- clear
execute env_map Clear rest_cmds history = do
    exitCode <- system "clear"
    handleNext env_map exitCode rest_cmds history

-- cat
execute env_map (Cat f_name) rest_cmds history = do
    status <- doesFileExist f_name
    if status
    then do
        contents <- readFile f_name
        putStr contents
        handleNext env_map ExitSuccess rest_cmds history
    else do
        putStrLn "File does not exist"
        handleNext env_map (ExitFailure 1) rest_cmds history

-- touch
execute env_map (Touch f_name) rest_cmds history = do
    exitCode <- system ("touch " ++ f_name)
    handleNext env_map exitCode rest_cmds history

-- rm
execute env_map (Rm f_name) rest_cmds history = do
    exitCode <- system ("rm " ++ f_name)
    handleNext env_map exitCode rest_cmds history

-- mkdir
execute env_map (MkDir dir_name) rest_cmds history = do
    exitCode <- system ("mkdir " ++ dir_name)
    handleNext env_map exitCode rest_cmds history

-- rmdir
execute env_map (RmDir dir_name) rest_cmds history = do
    exitCode <- system ("rmdir " ++ dir_name)
    handleNext env_map exitCode rest_cmds history

-- date
execute env_map Date rest_cmds history = do
    exitCode <- system "date"
    handleNext env_map exitCode rest_cmds history

-- adding new env var
execute env_map (SVar (var, value)) rest_cmds history = do
    let env_map' = Map.insert var value env_map
    handleNext env_map' ExitSuccess rest_cmds history

handleNext :: Map String String -> ExitCode -> [String] -> [String] -> IO ()
{-
    Determines whether to continue executing the argument or not, based on the operator.

    Arguments: 
        Map String String - The env var map
        ExitCode - exit code from previous command
        [String] - Sequence of remaining command (e.g. ["&&", "ls"])
    Returns:
        IO () - continues/stops shell 
-}
handleNext env_map _ [] history = Main.shell env_map [] history -- ready to parse new input
handleNext env_map exitcode (current_op:rest) history
    | current_op == "&&" && exitcode == ExitSuccess = Main.shell env_map rest history
    | current_op == "&&" && exitcode /= ExitSuccess = do
        putStrLn "Execution failed, exiting..."
        Main.shell env_map [] history
    | current_op == "||" && exitcode /= ExitSuccess = do
        putStrLn "Execution failed, continuing to next command"
        Main.shell env_map rest history
    | current_op == "||" && exitcode == ExitSuccess = Main.shell env_map [] history
    | current_op == ";" = Main.shell env_map rest history
    | otherwise = Main.shell env_map rest history -- Invalid operator

processCurrentCmd :: Map String String -> [String] -> [String] -> [String] -> IO()
{-
    Process the current command.
    Arguments:
        Map String String - Mapping of vars to values of env variables

        Consider ["ls", "-l", "&&", "pwd"]:
        [String] - The current command (e.g. ["ls", "-l"])
        [String] - The rest of the command list (e.g. ["&&", "pwd"])
-}
processCurrentCmd env_map current_cmd rest history = 
    case current_cmd of
        ["exit"]                    -> execute env_map Exit [] (history ++ ["exit"])
        ["ls"]                      -> execute env_map (Ls Nothing) rest (history ++ ["ls"])
        ["ls", dir]                 -> execute env_map (Ls (Just dir)) rest (history ++ ["ls " ++ dir])
        ["pwd"]                     -> execute env_map Pwd rest (history ++ ["pwd"])
        ["cd", dir]                 -> execute env_map (Cd (Just dir)) rest (history ++ ["cd " ++ dir])
        ["cd"]                      -> execute env_map (Cd Nothing) rest (history ++ ["cd"])
        ["env"]                     -> execute env_map Env rest (history ++ ["env"])
        "echo":args                 -> execute env_map (Echo args) rest (history ++ ["echo " ++ unwords args])
        ["history"]                 -> execute env_map History rest (history ++ ["history"])
        ["clear"]                   -> execute env_map Clear rest (history ++ ["clear"])
        [s] | Just (var, val) <- splitbyAssignment s -> execute env_map (SVar (var, val)) rest (history ++ [var ++ "=" ++ val])
        ["cat", f_name]             -> execute env_map (Cat f_name) rest (history ++ ["cat " ++ f_name])
        ["touch", f_name]           -> execute env_map (Touch f_name) rest (history ++ ["touch " ++ f_name])
        ["rm", f_name]              -> execute env_map (Rm f_name) rest (history ++ ["rm " ++ f_name])
        ["mkdir", dir_name]         -> execute env_map (MkDir dir_name) rest (history ++ ["mkdir " ++ dir_name])
        ["rmdir", dir_name]         -> execute env_map (RmDir dir_name) rest (history ++ ["rmdir " ++ dir_name])
        ["date"]                    -> execute env_map (Date) rest (history ++ ["date"])
        _           -> if containsRedir current_cmd -- check for redirections
                       then 
                          do 
                            exit_status <- system (unwords current_cmd)
                            handleNext env_map exit_status rest (history ++ [unwords current_cmd])
                       else putStrLn "Invalid Command" >> Main.shell env_map rest history

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    Main.shell Map.empty [] [] -- start with empty map of env vars, empty cmd list, no command history
