# hshell - A Simple Shell in Haskell

## Running the HShell

### Build
```bash
cabal build
```

### Run
```bash
cabal run
```

## Supported Commands

| Command | Description |
|---------|-------------|
| `ls [dir]` | List directory contents |
| `pwd` | Print working directory |
| `cd [dir]` | Change directory (supports `~` and `~/path`) |
| `cat <file>` | Display file contents |
| `echo <args>` | Print arguments (supports `$var` expansion) |
| `env` | Display all environment variables |
| `VAR=value` | Set an environment variable |
| `history` | Display command history |
| `clear` | Clear the terminal |
| `exit` | Exit hshell |

## Command Chaining

| Operator | Behavior |
|----------|----------|
| `&&` | Run next command only if previous succeeds |
| `\|\|` | Run next command only if previous fails |
| `;` | Always run next command |

## Multi-Word Arguments (Echo)

The `echo` command supports multiple arguments:

```
hshell> echo hello world
hello world
```

Variable expansion works within multi-word echo:

```
hshell> test=hello
hshell> echo $test how are you
test how are you
```

## I/O Redirection

Supports `>`, `>>`, and `<` redirection operators.

```
hshell> echo hello > output.txt
hshell> cat output.txt
hello
hshell> echo world >> output.txt
hshell> cat output.txt
hello
world
```

---

## Haskell Concepts Used

### IO Monad and `do` Notation
The shell operates entirely within the `IO` monad. The `do` notation chains IO actions sequentially, allowing us to read input, execute commands, and print output in order.

### System.Process
Used `system` from `System.Process` to execute shell commands and capture `ExitCode` values for implementing `&&`, `||`, and `;` chaining logic.

### System.Directory
Used for file system operations:
- `setCurrentDirectory` - implementing `cd`
- `getHomeDirectory` - expanding `~` in paths
- `doesDirectoryExist` / `doesFileExist` - validating paths before operations

### System.Exit (ExitCode)
The `ExitCode` type (`ExitSuccess` | `ExitFailure Int`) from `System.Exit` is used to propagate command success/failure through the shell for proper `&&` and `||` behavior.

### Algebraic Data Types (Command Type)
Defined a data type and respective value constructors to represent all supported commands, with some variants carrying additional commands:
```haskell
data Command = Exit
             | Ls (Maybe String)      -- optional directory
             | Pwd
             | Cd (Maybe String)      -- optional path
             | SVar (String, String)  -- variable assignment
             | Env
             | Echo [String]          -- multiple arguments
             | History
             | Clear
             | Cat String             -- filename
```

### Data.Map
Used for storing environment variables as key-value pairs:
```haskell
Map.insert var value env_map  -- set variable
Map.lookup varName env_map    -- get variable (returns Maybe)
Map.delete var env_map        -- unset variable
```

### String Manipulation
- `words` - splits input string into list of tokens
- `unwords` - joins tokens back into a string
- `break` - splits string at a predicate (used for parsing `var=value`)

### List Comprehensions
Used for formatting numbered history output:
```haskell
[show i ++ "  " ++ cmd | (i, cmd) <- zip [1..] history]
```

### `mapM_` for IO over Lists
Used to apply IO actions across lists without collecting results:
```haskell
mapM_ putStrLn historyLines
mapM_ putKV (Map.toList env_map)
```

### Test.Hspec (Unit Testing)
Used the `hspec` testing framework to write unit tests for pure helper functions:
```haskell
main = hspec $ do
    describe "splitAtOperator" $ do
        it "splits before &&" $
            splitAtOperator ["ls", "-la", "&&", "pwd"]
                `shouldBe` (["ls", "-la"], ["&&", "pwd"])
```

---

## Architecture

### Main Functions

#### `shell`
```
The main hshell.
Arguments:
    Map String String - Mapping of vars to values of env variables
    [String] - Remaining commands/operators to run
Returns:
    IO Monad - shell process
```

#### `execute`
```
Given a command from hshell, executes it and returns to hshell.
Arguments:
    Map String String - Mapping of vars to values of env variables
    Command - The command to be run
    [String] - Remaining commands/operators to run
Returns:
    IO Monad - shell process
```

#### `handleNext`
```
Determines whether to continue executing the argument or not, based on the operator.

Arguments:
    Map String String - The env var map
    ExitCode - exit code from previous command
    [String] - Sequence of remaining command (e.g. ["&&", "ls"])
Returns:
    IO () - continues/stops shell
```

#### `processCurrentCmd`
```
Process the current command.
Arguments:
    Map String String - Mapping of vars to values of env variables

    Consider ["ls", "-l", "&&", "pwd"]:
    [String] - The current command (e.g. ["ls", "-l"])
    [String] - The rest of the command list (e.g. ["&&", "pwd"])
```

### Helper Functions

#### `splitbyAssignment`
```
Helper function for splitting by "=" for env vars.
Arguments:
    String - The "var_name=var_val" string to split by
Returns:
    Just (String, String) - if splitting was sucessful
    Nothing otherwise
```

#### `showEnvVars`
```
Helper function to show the entire env_map.
Arguments:
    Map String String - The env var map.
Returns:
    IO () - Prints to stdout
```

#### `splitAtOperator`
```
Ingests the current command until an operator is found.
E.g. ["ls", "-la", "&&", "pwd", ";", "ls"] -> (["ls", "-la"], ["&&", "pwd", ";", "ls"])

Arguments:
    [String] - The command list
Returns:
    ([String], [String]) - The first element is the current command, the second element is the rest of the command list
```

#### `containsRedir`
```
Determines whether the current command has a redirection.

Arguments:
    [String] - The current command

Returns:
    Bool - True if > or >> or < is in the current command, False otherwise
```

#### `displayHistory`
```
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
```

### About Me and Contact Info:
* Dylan Tang, 4th Year Stats + CS student at UChicago
* Phone: (630) - 915 - 3426
* Email: dtang04@uchicago.edu