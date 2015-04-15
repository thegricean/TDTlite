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

This provides step by step instructions for logging on to the server, setting all the necessary environment variables, and running an example TDTlite project on `corn.stanford.edu`. There are three general steps:

1. Log on and set environment variables (or check that they are set).

2. Copy the TDTlite example project into your home directory and set your project specific paths.

3. Run TDTlite!

We'll go through each in turn.

## Setting environment variables

Start by logging on to the server:

`$ ssh SUNETID@corn.stanford.edu`

You'll need to enter your password. By default, you will now be in your home directory. The first step is to make sure all your environment variables are set so TDTlite knows where to access the corpora, etc. Check to see whether you have set any of the necessary environment variables. For example:

`$ echo $TGREP2ABLE`

To set environment variables, first open your .cshrc file in the vim editor:

`$ vim .cshrc`

Scroll to the bottom by pressing `Shift + G`. Open for editing by pressing `a`. Copy the following lines and paste them into the file:

```bash
setenv TGREP2ABLE /afs/ir/data/linguistic-data/Treebank/tgrep2able/
setenv TGREP2_CORPUS $TGREP2ABLE/swbd.t2c.gz
setenv TDTlite /afs/ir/data/linguistic-data/TDTlite/
setenv TDT_DATABASES /afs/ir/data/linguistic-data/TDTlite/databases
setenv PATH /afs/ir/data/linguistic-data/TDTlite:$PATH
```

Once the lines are pasted, hit `Esc`, then the combination `Shift+:`. Type `wq` and `Enter`, which saves your work and exits the program. Some explanations of the environment variables you just set:

`TGREP2_CORPUS` Set this to the TGrep2 default corpus. If you run TGrep2 without a corpus argument, it will run on this corpus. 

`TDTlite` Set this to the directory that contains the TDT scripts. 

`TDT_DATABASES` Set this to the directory that contains the TDT databases. 

The last line adds the TDTlite directory to your `PATH` so you can run the basic `run` command from anywhere. 

If you just updated your `.cshrc` file, you need to source it in order to actually set the variables:

`$ source .cshrc`

Now, testing whether your environment variables are set should yield a path to the correct location:

`$ echo $TGREP2ABLE`

## Copying the TDTlite example project and setting project specific paths

It's good practice to have a `projects` directory that you have all your (TDTlite or otherwise) projects organized in. Create this directory in your home directory:

`$ mkdir projects`

Now move into `projects` and copy the TDTlite example_project to your current location:

`$ cp -r $TDTlite/example_project/ .`

Test to see wether it was properly copied:

`$ ls`

You should see an item `example_project`. Move into it:

`$ cd example_project`
`$ ls`

You will see three directories: `data`, `ptn`, and `results`. More on those in a bit. There are also two files, `MACROS.ptn` and `options`. The last thing left to do before we can run TDTlite is to specify project-specific paths in the `options` file. First, you need to find out the path to your home directory:

`$ pwd`

Copy the path, then open `options` in `vim`:

`$ vim options`

At the top of the file you will see two path assignments: one for `data` and one for `results`. These need to be replaced with your project-specific paths. Do so by moving your cursor to the first character after `=` and pressing `X` until all the text you want to replace is deleted. Then press `I` and paste the path that you copied previously. Once you've replaced both, hit `Esc`, then `Shift+:`, type `wq`, and hit `Enter`. You are now ready to run TDTlite.

## Run TDTlite

Running TDTlite is incredibly simple once everything is set up. Simply type, from the top level of the example_project:

`$ run -c swbd -e -o`

This will run TDTlite on the Switchboard corpus (this is what `-c swbd` means), extract data from Switchboard using all the tgrep2 patterns in `ptn` (this is what `-e` means), and build a database of all the extracted data in `results` named `swbd.tab` (this is what `-o` means). You can copy `swbd.tab` onto your computer and import it into your favorite statistical analysis program (e.g., R, Excel). For more information about the way `run` works, see the [TDTlite User Manual](https://github.com/thegricean/TDTlite/blob/master/docs/tdt_manual.pdf).

