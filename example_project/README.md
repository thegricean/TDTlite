# TDTlite test

On `corn.stanford.edu`, follow the instructions below to check that everything is set up for you to use TDTlite.

Start by copying the example project that's included in TDTlite to your home directory. From your home directory, type:

`cp -r example_project .`

Navigate into `example_project`.

`cd example_project`

Open the `options` file and set the `data` and `results` paths to the `data` and `results` subdirectories of `example_project` (use `pwd` to find out the path to the current directory).  

To test whether everything is running as it should:

`run -c swbd -e -o`

This should have the effect of creating a database called `swbd.tab` in `results`. 


