# OEL Mono Repo

This is a monorepo for different OEL packages.\
Currently it is only meant as an optional tool for developers to try out changes across packages.


## Git operations

### Set up remotes for packages

```sh
git remote add oe_bootstrap_theme git@github.com:openeuropa/oe_bootstrap_theme.git
git remote add oe_whitelabel git@github.com:openeuropa/oe_whitelabel.git
git remote add oe_showcase git@github.com:openeuropa/oe_showcase.git

# Configure prefixes for tags from different remotes.
git config --add remote.oe_bootstrap_theme.fetch '+refs/tags/*:refs/tags/oe_bootstrap_theme/*'
git config --add remote.oe_whitelabel.fetch '+refs/tags/*:refs/tags/oe_whitelabel/*'
git config --add remote.oe_showcase.fetch '+refs/tags/*:refs/tags/oe_showcase/*'

# Optionally, fetch and look at the history.
git fetch --all
git log --graph --decorate --pretty=oneline --abbrev-commit --abbrev=8 --all
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

### Setup for oe_showcase

Clean up and stop other packages:

```sh
# Remove vendor and build directories for packages that will be symlinked.
# You will need sudo because these all belong to the root user, if they exist.
sudo rm -rf packages/oe_bootstrap_theme/vendor
sudo rm -rf packages/oe_bootstrap_theme/build
sudo rm -rf packages/oe_whitelabel/vendor
sudo rm -rf packages/oe_whitelabel/build

# Stop containers in all packages.
docker compose --project-directory=packages/oe_bootstrap_theme stop
docker compose --project-directory=packages/oe_whitelabel stop
docker compose --project-directory=packages/oe_showcase stop
```

Build assets in other packages that will be symlinked.

```sh
cd packages/oe_bootstrap_theme
docker compose up -d node
docker compose exec -u node node npm install
docker compose exec -u node node npm run build
cd ../..

cd packages/oe_whitelabel
docker compose up -d node
docker compose exec -u node node npm install
docker compose exec -u node node npm run build
cd ../..
```

Enter the package directory.

```sh
cd packages/oe_showcase
```

Start the container:

```sh
# Start docker-compose with a custom list of docker-compose files.
docker compose -f docker-compose.yml -f ../../shared/docker-compose.package.yml up -d
```

Prepare `composer.mono.lock`:

```sh
cp composer.lock composer.mono.lock
docker compose exec web composer update --no-install openeuropa/oe_whitelabel openeuropa/oe_bootstrap_theme
```

Now you can follow the instructions from [packages/oe_showcase/README.md](packages/oe_showcase/README.md):

```sh
# Install a demo website.
docker compose exec web composer install
docker compose exec web ./vendor/bin/run drupal:site-install

# Prepare for phpunit tests.
docker-compose exec web ./vendor/bin/run ci:site-setup
docker-compose exec web ./vendor/bin/drush en -y oe_showcase_test

# Run phpunit tests.
docker compose exec web ./vendor/bin/phpunit
```

### Setup for oe_whitelabel

Clean up and prepare `packages/oe_bootstrap_theme/` as explained for `oe_showcase` above.

Enter the package directory.

```sh
cd packages/oe_whitelabel
```

Start the container as explained for `oe_showcase` above.

Follow further instructions from [packages/oe_whitelabel/README.md](packages/oe_whitelabel/README.md).

### Setup for oe_bootstrap_theme

Enter the package directory.

```sh
cd packages/oe_bootstrap_theme
```

Follow further instructions from [packages/oe_bootstrap_theme/README.md](packages/oe_bootstrap_theme/README.md).

(There is no need for a customized docker-compose and composer setup, because no local packages need to be symlinked.)




