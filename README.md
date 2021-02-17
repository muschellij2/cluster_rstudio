---
title: "RStudio and Other Cluster Things"
author: "John Muschelli"
output: 
  html_document:
    keep_md: true
    theme: cosmo
    toc: true
    toc_depth: 3
    toc_float:
      collapsed: false
    number_sections: true
---



# Before you read

Go to https://jhpce.jhu.edu/knowledge-base/how-to/ first.

<h1>*Disclaimer*</h1>I wrote a bunch of random thoughts down and don't guarantee any of this.  Don't break your computer and come to me.  I will not know what to do or likely will tell you to reread this section.  That's why I made that word so big.  So like do things incrementally and with care and test along the way.  Just in like every other step of research you do hopefully.

I'm going to talk about a bunch of random stuff before talking about how to use RStudio and JHPCE.

# Bash Setup 

Stop typing a bunch of stuff just to start work.   It's slow, you make mistakes.  Use shortcuts.  Your time is valuable.  Also, if I see you typing this over 2 times when we're working together I'm going to walk away.  It's for both of our sake.

## Setting up your local aliases

Set up aliases (kind of functions/short cuts).  When we use `export` in `bash` that's like creating an environment variable, which you have to reference with a `$`.  Aliases are like shortcuts too, but no `$` required.  There are other differences, but do you really care right now?  

Terminal stuff: Your `~/.bash_profile` runs when your user "logs in" to the terminal (when you make a new window).  The `rc` stands for "run commands".  I never knew what that meant until I wrote this thing, so it proves that that info doesn't matter.  But the file itself is *very* important.  It's more important than you think because if you mess it up, no terminal really will run and you'll be very sad face.  So don't mess it up.

Now that we've scared you enough, put these in `~/.bashrc`.  FYI - `~/` is essentially just a shortcut for "home".  

```bash
## In local .bashrc file
export jhpce_username="YOUR USERNAME"
alias jhpce="ssh -Y -X ${jhpec_username}@jhpce01.jhsph.edu"
alias jhpce2="ssh -Y -X ${jhpec_username}@jhpce02.jhsph.edu"
alias jhpcet="ssh -Y -X ${jhpec_username}@transfer01.jhpce.jhu.edu"
```

Make sure you run all the following commands in another new Terminal or run `source ~/.bashrc`.  Source is like `source` in R, it runs stuff.  You can write `source file.sh` or `. file.sh` in most shells.  If it says "command not found", try the other one.

## Passwordless Logins

Once again, stop typing so many things.  Like your username.  And your password.  And some 6 numbers your phone is telling you to do.  Keep your environment/computer secure but break down every little thing you can to make your workflow faster.  It saves small amounts of time, but it's done millions of time in your work.  Time you can be doing research. Or, like, sleeping.

See https://jhpce.jhu.edu/knowledge-base/authentication/ssh-key-setup/ on how to create passwordless logins.  This is much more in detail than this document and also covers Windows machines.  The gist of what's going on is below, but seriously, go to that link.

1.  If you've already done this once before you should **NOT** do it again.  This is done locally. Create your public/private keys using `ssh-keygen -t rsa`. Change to your `.ssh` directory with `cd ~/.ssh`. There should be a file `id_rsa.pub` which is your public key file..
2.  Note, before running this command `IDENTIFIER` should be changed.  Copy your public key to JHPCE, using `scp`:

`cat ~/.ssh/id_rsa.pub | ssh ${jhpec_username}@jhpce01.jhsph.edu 'cat >> ~/.ssh/authorized_keys'`
where you can replace `IDENTIFIER` with the name of your computer. 

Now you should be able to run:

```bash
jhpce
```
and log in without a password (or your passphrase).


## Logging into a node with one command

Now we will set up an alias locally so you can log into JHPCE, and automatically `qrsh` into a node.  Here `qr` will run logging in and `qrsh` with default options.  If you want to change the options, such as `qrsh -l mem_free=30G,h_vmem=30G`, then the `qrsh` (local) function below will allow you to do that:

```bash
## In local .bashrc file
alias qr="jhpce -t 'source /etc/profile; qrsh'"
qrsh () { 
    echo "qrsh requests were: $@";
    cmd="source /etc/profile; qrsh $@";
    jhpce -t $cmd
}
```

Now, you should be able to go into your **new** Terminal window and run:
```bash
qrsh
```
and be logged into a compute node.

# Submitting R Jobs

There are a number of ways to submit R jobs to the cluster.  One way is to make a `.sh` file and submit that, but that seems like overkill because most times the `sh` file is simply (for a `script.R` file):
```bash
R --no-save script.R
```
which is pretty unnecessary.  One way to do it is to `qsub` the script directly, but put `#! /usr/bin/env Rscript` at the top.  I don't like this because sometimes Rscript does not print out things I want.  Also, I have used these helpers for some time, and they do what I need.


I use these 2 functions to do anything on the cluster with respect to `R`:
```bash
# Run R --no-save (has methods called)
function Rnosave {
  x="$1"
  mydir=`mktemp file.XXXX.sh`
  echo '#!/bin/bash' > $mydir
  echo "R --no-save < ${x}" >> $mydir
  shift
  qsub -cwd "$@" $mydir 
  rm $mydir
}

# Run Rscript on an R Script
function Rbatch {
  x="$1"
  mydir=`mktemp file.XXXX.sh`
  echo '#!/bin/bash' > $mydir
  echo "Rscript ${x}" >> $mydir
  shift
  qsub -cwd "$@" $mydir 
  rm $mydir
}
```

## How to use these on the cluster
How do you use these?  Either a) Make a file in `~/` like `~/Rsubmit.sh` and then run `source ~/Rsubmit.sh` in your `~/.bash_profile` (recommended) or b) copy and paste them in your `~/.bash_profile` (it's your life).  
Even better, put this in your `~/.bash_profile`:
```bash
if [ -f ~/Rsubmit.sh ]; then
    . ~/Rsubmit.sh
fi
```
which checks to see if the file exists before trying to source it all willy-nilly.


## How to use these in practice
There is no big difference between the 2 generally, and I use `Rnosave` almost exclusively. I almost always *name* my jobs, which is an SGE thing.  For example:
```bash
Rnosave script.R -N MYJOB
```

Why name a job?  Well:

1. Output files are named after the job name (e.g. `MYJOB.o12343`,  `MYJOB.e12343`)
2. I can `qdel MYJOB` rather than remember the job number.  I believe you still need to use the job number to kill certain tasks in an array job, like `qdel 12343.5` to kill task `5`.
3. It tells me what the job is doing. Otherwise it's named something like `file.asdfdf`.  Usually it's not `MYJOB`, but more `REGISTRATION` or something.

Why do I name it in all caps?  It makes it easier to find the output files and then delete them when needed, like `rm MYJOB.*`.  You can pass in any `qsub` arguments *after* the script, such as:
```bash
Rnosave script.R -l mem_free=20G,h_vmem=21G -t 1-200 -N MYJOB
```

## When to use Rbatch
The times I use `Rbatch` is when I'm using `commandArgs` in the R script and passing in command line arguments to R.  This can complicate things a bit and you need to quote the script, like:
```bash
Rbatch "script.R -a RCOMMANDARG" -l mem_free=20G,h_vmem=21G -t 1-200 -N MYJOB
```
but I typically don't do that (see array jobs below).


When I plan on knitting an `Rmd` document, I will use:

```bash
# Run rmarkdown render to knit doc
function Rknit {
  x="$1"  
  str="library(methods); rmarkdown::render('${x}')"
  mydir=`mktemp file.XXXX.sh`
  echo '#!/bin/bash' > $mydir
  echo "Rscript -e \"${str}\"" >> $mydir
  shift
  qsub -cwd "$@" $mydir 
  rm $mydir
}  
```


# Array Jobs
I have a blog post on array jobs here: https://hopstat.wordpress.com/2013/11/05/array-and-sequential-cluster-jobs/.  Start there.  Notably, see about `hold_jid` and `hold_jid_ad` for making dependencies.

I will once iterate again the use of `expand.grid`.  If you are doing a number of different parameters or different conditions, put those conditions in a `expand.grid(condition1=c1, condition2=c2)` in your `R` script (do any deletions you need) and then do:


```r
scenarios = expand.grid(condition1=c1, condition2=c2)
iscen <- as.numeric(Sys.getenv("SGE_TASK_ID"))
if (is.na(iscen)) {
  iscen = 1 # or some value to do interactively
}
scen = scenarios[iscen,]
c1 = scen$c1
c2 = scen$c2
# run your code with c1/c2, etc.
```
This is nice because when working interactively, `SGE_TASK_ID` is not set by the scheduler/cluster as you're not doing an array job (you're in `QRLOGIN` and there is no task).  It will let you test stuff interactively and the code will still run.  If you just do `as.numeric(Sys.getenv("SGE_TASK_ID"))` without the `if` statement, then you're going to get `NA` and have a bad time.

# Other random stuff

## Auto loading modules when on a node

Put this in your `~/.bashrc` and you will automatically load the modules you want.  The `hostname` part checks to see if you're on a node (aka something starting with `compute`) and if that's true, then loads a bunch of stuff.  **Do not leave that out** - otherwise it will try to run that on the login node.  Don't do that.

Don't worry about the `LD_LIBRARY_PATH` if you don't know what that's about.
```bash
hostname | grep compute- > /dev/null 2>&1
if [ $? == 0 ]
then
  module load matlab
	module load sas
	module load stata
  module load conda_R
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/jhpce/shared/jhpce/core/conda/miniconda3-4.6.14/envs/svnR-4.0.x/include/
fi;
```

## I can't get on a node!!

There is a timeout for requests.  Some requests can never be fulfilled (did you request 1Tb of Memory!?). 
The `-now n` argument will allow your request to wait longer:

```bash
qrsh -l mem_free=30G,h_vmem=31G -now n
```
So you're saying "not now" (but hopefully soon).  If you're using `qrsh` local function from above, then you may need to put that all in quotes, but I forget.

## Java stuff
Java is a deep dark magic that only the strongest of heart mess with.  But pretty much if Java gives me some problems it's due to heap size, which you can up to a maximum of 3Gb (which is a lot) using:
```bash
export _JAVA_OPTIONS=-Xmx3g
```

This may, in turn, make OTHER things break.  Also, make sure you up your usage of your memory when submitting (but be a good cluster citizen - go incrementally and not way too high).

## How do I see plots in R

Google X11 forwarding and either do `ssh -X -Y` like in `qrsh` above, or add:
```
Host *
    ForwardAgent yes
    ForwardX11 yes
```
to `~/.ssh/config`.  STOP USING the process of plotting something then downloading `Rplot.png` to view it.  That process is inefficient and weak sauce.

## Set up your SSH keys on Github

Make SSH keys on the cluster, use it for passwordless logins, and then add these keys to GitHub so that you can use GitHub as a go-between if you want with the cluster.


## Modules

Pretty much all I know about modules:

```bash
module load conda_R # load up conda_R
module list # what do you have loaded
module avail # available modules
module spider conda # searches for the word conda
module -r spider '.*conda.*' # regular expressions!
```
Also - *these change your PATH variable*.  That can break stuff.  Be aware.

## Working with big data files

Remember setting a LARGE value of `h_fsize` in case you're output is *really* big (or check your default before running).




# How do I use RStudio and JHPCE
The goal of this report is to allow users to edit and send code from the RStudio IDE to a cluster compute node with `R`.  

What this tutorial is not:

1) How to use RStudio on the JHPCE (see https://jhpce.jhu.edu/question/how-do-i-get-the-rstudio-program-to-work-on-the-cluster/)
2) How to get the cluster on the `Console` portion of RStudio (we use Terminal)
3) `knit` documents on the JHPCE.


# RStudio

Now, the whole setup above allowed you to 1) log into a node with one command, and 2) have X11 forwarding on with `-X` and `-Y` in the `ssh` command.  The forwarding is important so we can do plots.  You need to make sure you have the most up-to-date RStudio to use the Terminals.

## A new Terminal

Now in RStudio, go to `Tools → Terminal → New Terminal` or `Alt+Shift+R`.  The Terminal window should pop up.  Run `qrsh` in the Terminal, make sure you're on a compute node.  Then run `R` as you normally would on JHPCE.  Now, you have the RStudio editor and an interactive `R` session within RStudio.  

Run 
```r
plot(0, 0)
```
to see if X11 is forwarded correctly.

## How should this look

<img src="example.gif" width="100%" />

## Other Resources/Options

https://www.rdocumentation.org/packages/rmote/versions/0.3.4
https://cran.r-project.org/package=remoter



