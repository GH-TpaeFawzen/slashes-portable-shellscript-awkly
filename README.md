# slashes-portable-shellscript-awkly
Interpreter of esoteric language Slashes implemented in portable shellscript (mainly using awk script) 

# What is Slashes language?
The "///", aka the slashes language, is an esoteric language
invented by Tanner Swett in 2006. It has nothing but program-substitution command
and quine command.
For more details, see the following article:

<<https://esolangs.org/wiki////>>

# Files
* `slashes.sh` -- The interpreter of "///" implemented in POSIX-compliant shellscript.
* `slashes-outputs-during-processing.sh` -- Slow, but outputs during processing the program.
* `slashes-outputs-when-done.sh` -- Fast, but never outputs till completing the processing.
  * This is just a copy of `slashes.sh` (original one).

# Usage
```sh
./slashes.sh [ FILE ]
```

```sh
./slashes-outputs-during-processing.sh [ -d | -d1 | -d2 | -d12 | -d21 ] [ FILE ]
```

Same goes to `slashes-outputs-when-done`.

Leaving `FILE` to be empty, the program is read
from stdin.

## Option
`-d` for debugging. `-d1` before one of substition or output, or `-d2`
after output. `-d` is treated as if `-d1` is chosen.
The debugging will be output to the stderr.

## Notes about your Slashes program
This interpreter accepts any binarily-written program, because
the interpreter translates the source into hexadecimal to be read
byte-by-byte.
This interpreter expects your program to be encoded in
ASCII-compatible encoding.

# Requirements
The interpreter requires following POSIX-compliant utilities:
sh, od, tr, sed, grep, echo, awk, and xargs.

# License
See `LICENSE` for details. This software is distributed under CC0 1.0.
