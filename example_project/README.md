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

# Sociogrammar (LIN 255C) instructions

This provides step by step instructions for logging on to the server, setting all the necessary environment variables, and running an example TDTlite project on `corn.stanford.edu`.

Start by logging on to the server:

`ssh SUNETID@corn.stanford.edu`

You'll need to enter your password. By default, you will now be in your home directory. The first step is to make sure all your environment variables are set so TDTlite knows where to access the corpora, etc. Check to see whether you have set any of the necessary environment variables. For example:

`echo $TGREP2ABLE`

To set environment variables, first open your .cshrc file in the vim editor:

`vim .cshrc`

Scroll to the bottom by pressing `Shift + G`. Open for editing by pressing `a`. Copy the following lines and paste them into the file:

```shell
setenv TGREP2ABLE /afs/ir/data/linguistic-data/Treebank/tgrep2able/
setenv TGREP2_CORPUS $TGREP2ABLE/swbd.t2c.gz
setenv TDTlite /afs/ir/data/linguistic-data/TDTlite/
setenv TDT_DATABASES /afs/ir/data/linguistic-data/TDTlite/databases
setenv PATH /afs/ir/data/linguistic-data/TDTlite:$PATH
```

Some explanations of the environment variables you just set:

`TGREP2_CORPUS` Set this to the TGrep2 default corpus. If you run TGrep2 without a corpus argument, it will run on this corpus. 

`TDTlite` Set this to the directory that contains the TDT scripts. 

`TDT_DATABASES` Set this to the directory that contains the TDT databases. 

The last line adds the TDTlite directory to your `PATH` so you can run the basic `run` command from anywhere. 


