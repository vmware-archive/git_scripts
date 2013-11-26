[![Build Status](https://travis-ci.org/pivotal/git_scripts.png)](https://travis-ci.org/pivotal/git_scripts)

# Git Scripts

These scripts are helpers for managing developer workflow when using git repos hosted on GitHub.  Install as a rubygem and they can be run as standard git commands like `git about`.

## Gem Installation

    $ gem install pivotal_git_scripts

## System Wide Installation

    $ cd /usr/local/bin && curl -L http://github.com/pivotal/git_scripts/tarball/master | gunzip | tar xvf - --include=*bin --include=*lib --strip=2

## git-about

`git about` shows settings set by `git pair` and `git project`

## git-pair

Configures git authors when pair programming.

    git pair sp js
    user.name=Josh Susser & Sam Pierson
    user.email=pair+jsusser+sam@pivotallabs.com


Create a `.pairs` config file in project root or your home folder.

    # .pairs - configuration for 'git pair'
    pairs:
      # <initials>: <Firstname> <Lastname>[; <email-id>]
      eh: Edward Hieatt
      js: Josh Susser; jsusser
      sf: Serguei Filimonov; serguei
    email:
      prefix: pair
      domain: pivotallabs.com
      # no_solo_prefix: true
    #global: true


By default this affects the current project (.git/config).<br/>
Use the `--global` option or add `global: true` to your `.pairs` file to set the global git configuration for all projects (~/.gitconfig).

Options are:
    -g, --global                     Modify global git options instead of local
    -v, --version                    Show Version
    -h, --help                       Show this.

## git-project

    $ git project pivots

This script sets the user account you will use to access repos hosted on github.com.  It creates a symlink from `id_github_current` to `id_github_pivotal<project>`, which switches the SSH key you are currently using to access GitHub repos.  Make sure you have the following lines in your .ssh/config file:

    Host github.com
      User git
      IdentityFile /Users/pivotal/.ssh/id_github_current

Authors
====
Copyright (c) 2010 [Pivotal Labs](http://pivotallabs.com). This software is licensed under the MIT License.

### [Contributors](https://github.com/pivotal/git_scripts/contributors)
 - git-pair original author [Bryan Helmkamp](http://brynary.com)
 - lots of pivots :)
 - [James Sanders](https://github.com/jsanders)
 - [Todd Persen](https://github.com/toddboom)
