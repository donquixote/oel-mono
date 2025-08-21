# OEL Mono Repo

This is a monorepo for different OEL packages.\
Currently it is only meant as an optional tool for developers to try out changes across packages.


## Git operations

### Set up remotes for packages

After cloning the package, run the setup script.\
This will create the remotes and also do some other preparation.

```sh
./setup.sh
```

### Pull / merge changes from packages

This allows to update the monorepo with new changes from each package repository.

```sh
# Optionally, fetch and look at the history.
git fetch --all
git log --graph --decorate --pretty=oneline --abbrev-commit --abbrev=8 --all

# Merge changes from packages.
git subtree merge --prefix=packages/oe_bootstrap_theme oe_bootstrap_theme/1.x
git subtree merge --prefix=packages/oe_whitelabel oe_whitelabel/1.x
git subtree merge --prefix=packages/oe_showcase oe_showcase/1.x
```

Notes:
- The 1.x branches of the different packages are not always aligned.\
  Sometimes it is better to merge specific feature branches or specific commit ids, rather than just blindly merging 1.x.
- The `git subtree merge` operation creates a special type of merge commit, that does not play nice with `git rebase`.
- The `git subtree` tool is not strictly part of git core, but is available in most systems.

### Commit changes

You can start a feature branch and commit changes to it, as you normally would.

```
git checkout -b OEL-12345
# Edit some files.
touch packages/oe_showcase/hello.txt
git add packages/oe_showcase/hello.txt
git commit -m"Add hello.txt in oe_showcase."
```

### Split / push changes to a package

This allows to create branches and pull requests in each package, based on local development done in the monorepo.

```
# Optionally, fetch all remotes.
git fetch --all

# Extract the changes only for a specific package.
# Use a branch naming pattern that allows to distinguish branches from different packages.
git subtree split --prefix=packages/oe_bootstrap_theme -b split-oe_bootstrap_theme-OEL-12345

# Look at the history, and verify that it continues from oe_bootstrap_theme/1.x.
git log --graph --decorate --pretty=oneline --abbrev-commit --abbrev=8 split-oe_bootstrap_theme-OEL-12345

# Push to the package repository.
# Use <local branch>:<remote branch> so that the remote branch will have a different (simpler) name.
git push --set-upstream oe_boostrap_theme split-oe_bootstrap_theme-OEL-12345:OEL-12345
```

You can now create a merge request in the package repository.

### Connect a local package repository

This allows to port development from a local instance of the monorepo into a local repo of a specific package, and vice versa.

Let's assume you have a local repository for `oe_booststrap_theme`, like this:

```
/home/<user>/projects/
  oe_bootstrap_theme/.git/
  oe_whitelabel/.git/
  oel-mono/.git/
```

Inside `oel-mono/`, you can add local directories as remotes:

```
cd /path/to/oel-mono
git remote add local-oe_bootstrap_theme ../oe_bootstrap_theme/
git config --add remote.local-oe_bootstrap_theme.fetch '+refs/tags/*:refs/tags/local-oe_bootstrap_theme/*'
git fetch local-oe_bootstrap_theme

# You can also do the reverse:
cd ../oe_bootstrap_theme
git remote add local-oel-mono ../oel-mono/
git config --add remote.local-oel-mono.fetch '+refs/tags/*:refs/tags/local-oel-mono/*'
git fetch local-oel-mono
```

Now, you can follow the steps as in "Pull / merge changes from packages" and "Split / push changes to a package", but using the local remote.

Howver, instead of `git push local-***`, it is better to switch to that local package repository and fetch:

```
cd /path/to/oel-mono
git subtree split --prefix=packages/oe_bootstrap_theme -b split-oe_bootstrap_theme-OEL-12345
cd ../oe_bootstrap_theme
git fetch local-oel-mono
git checkout -b OEL-12345 local-oel-mono/split-oe_bootstrap_theme-OEL-12345
```

## Development setup

For now, the only supported setup is within a package directory.\
An installation in the root directory is currently not supported.

Only one package installation can be active at any given time!

### Requirements

- [Docker](https://www.docker.com/get-docker)
- [Docker Compose](https://docs.docker.com/compose/)

### Preparation

Run the setup script, if you have not already done so.

```sh
# Symlink the start script for each package.
./setup.sh
```

### Setup for a specific package

```sh
# Enter the package directory.
cd packages/<name>

# Run the start script.
./start.sh
```

If Drupal was not already installed, this will trigger site install.
