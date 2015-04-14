# TDT test

## Getting started

Make sure the `data` and `results` paths in the `options` file are set to the `data` and `results` subdirectories of this directory. On `corn.stanford.edu` you don't need to change anything.

To test whether everything is running as it should:

`run -c swbd -e -o`

This should have the effect of creating a database called `swbd.tab` in `results`. If you don't have the right permissions on `corn.stanford.edu`, copy `example_project` to a place where you have write access (e.g., your home directory).

`cp -r example_project ~/`

Set the `data` and `results` paths in `options` (use `pwd` to find out the path to the current directory), then try running the above `run` command again.
