# The TGrep2 Database Tools

The TGrep2 Database Tools (lite) are a collection of (mostly perl, and some python, and some shell) scripts that allow you to extract data from large corpora (if you already have the corpora in a tgrep2able format) and combine the output into a comprehensive database in a format suitable for importing into your favorite statistical analysis program. These tools are still very much underdocumented, but see the user manual in `docs` for more information, or get in touch via email: `jdegen@stanford.edu`

These scripts were written for the most part by [T. Florian Jaeger](http://www.bcs.rochester.edu/people/fjaeger/) (University of Rochester) with later contributions by Neal Snider (Nuance Communications) and Austin Frank (Riot Games). Documentation and integration into one tool suite was provided by [Judith Degen](https://sites.google.com/site/judithdegen/) (Stanford University).

## Getting started

Set the following environment variables in your profile:

`TGREP2ABLE` Set this to the directory that contains the TGrep2 corpora. For example, on `corn.stanford.edu`:

`setenv TGREP2ABLE /afs/ir/data/linguistic-data/Treebank/tgrep2able/`

`TGREP2_CORPUS` Set this to the TGrep2 default corpus. If you run TGrep2 without a corpus argument, it will run on this corpus. For example, on `corn.stanford.edu`:

`setenv TGREP2_CORPUS $TGREP2ABLE/swbd.t2c.gz`

`TDTlite` Set this to the directory that contains the TDT scripts. For example, on `corn.stanford.edu`:

`setenv TDTlite /afs/ir/data/linguistic-data/TDTlite/`

`TDT_DATABASES` Set this to the directory that contains the TDT databases. For example, on `corn.stanford.edu`:

`setenv TDT_DATABASES /afs/ir/data/linguistic-data/TDTlite/databases`

Then add the TDTlite directory to your `PATH`. For example, on `corn.stanford.edu`:

`setenv PATH /afs/ir/data/linguistic-data/TDTlite:$PATH`

With this in place, you should be able to use the basic `run` command from within a project directory. Follow the instructions in `example_project` to test that everything is set up properly.
