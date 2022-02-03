#!/bin/env python3
"""
Obfuscate, commit, and break git repo
"""
import argparse
import logging
import re
import string
import sys
import random
from pathlib import Path

PYTHON_VARIABLE_REGEX_FMT = r"^\s*\b({})\b(?=( ?=(?!=)))"
JAVA_VARIABLE_REGEX_FMT = r"^\s*(?:\w+)[^=]*(\b\w+\b) ?(?:;|\=)"


parser = argparse.ArgumentParser()
parser.add_argument(
    "-j",
    "--java",
    action="store_true",
    help="Force files to be interpreted as Java files",
)
parser.add_argument(
    "-p",
    "--python",
    action="store_true",
    help="Force files to be interpreted as Python files",
)
parser.add_argument(
    "--pre",
    metavar="N",
    default=10,
    type=int,
    help="Number of git commits to make before breaking (default=10)",
)
parser.add_argument(
    "--post",
    default=10,
    metavar="N",
    type=int,
    help="Number of git commits to make after breaking (default=10)",
)
parser.add_argument(
    "--breaks",
    default=10,
    metavar="N",
    type=int,
    help="Number of breaking changes to commit (default=1)",
)
parser.add_argument(
    "--variable-length",
    default=16,
    metavar="N",
    type=int,
    help="Length of obfuscated variable names (default=16)",
)
parser.add_argument(
    "-n",
    "--dry",
    action="store_true",
    help="Only show what would be changed",
)
parser.add_argument(
    "--no-commit",
    action="store_true",
    help="Don't commit anything, only make changes",
)
parser.add_argument(
    "-q",
    "--quiet",
    action="store_true",
    help="Only show errors (turn off warnings)",
)
parser.add_argument(
    "-v",
    "--verbose",
    dest="verbosity",
    action="count",
    default=0,
    help="Increase verbosity",
)
parser.add_argument("files", nargs="+", metavar="FILE")

cli = parser.parse_args()
if cli.quiet:
    cli.verbosity = -1
logging.basicConfig(format="%(message)s", level=30 - cli.verbosity * 10)


def obfuscate_code(code, regex_fmt, variable_length=16, whitespace=False):
    """
    Obfuscate the file at path by scrambling the variable name of a random capture group
    if random is True, or the first capture group if random is False. If whitespace is
    True, only add whitespace.
    """
    if whitespace:
        whitespace_indices = []
        latest_newline = code.rfind("\n")
        current_newline = code.index("\n")
        while latest_newline != current_newline:
            print(f"Newline found at {current_newline}")
            current_newline = code.index("\n", current_newline + 1)
        # TODO: Insert new whitespaces
        expanding_newline = random.choice(whitespace_indices)
        return code
    variables = re.findall(regex_fmt.format(r"\w+"), code)
    if len(variables) > 0:
        logging.error("No variable declarations found in code")
        return code
    variable = random.choice(list(set(variables)))
    new_name = "".join(random.choices(string.ascii_lowercase, k=variable_length))
    changes = re.sub(regex_fmt.format(variable), new_name, code)
    logging.info("Variable '%s' was renamed to '%s'")
    return changes


def main():
    """Main entry point"""

    filetype = None
    if cli.java:
        filetype = "java"
    elif cli.python:
        filetype = "py"
    else:
        filetype = cli.files[0].split(".")
        if len(filetype) < 1:
            logging.error("Invalid file(s) without --java or --python flag")
            sys.exit(1)
        filetype = filetype[-1]

    regex = PYTHON_VARIABLE_REGEX_FMT if filetype == "py" else JAVA_VARIABLE_REGEX_FMT
    for path in cli.files.copy():
        if not Path(path).exists():
            logging.warning("File '%s' not found, skipping", path)
            cli.files.remove(path)
            continue

        with open(path, "r" if cli.dry else "r+", encoding="utf8") as code:
            # Perform changes
            for _ in range(cli.pre):
                logging.info("Pre-obfuscation")
                code = obfuscate_code(code, regex, variable_length=cli.variable_length)
            for _ in range(cli.breaks):
                logging.info("Fake breaking")
            for _ in range(cli.post):
                logging.info("Fake post-obfuscation")

    if cli.dry:
        logging.info("Would have changed files %s", cli.files)
    else:
        logging.info("Changed files %s", cli.files)


if __name__ == "__main__":
    main()
