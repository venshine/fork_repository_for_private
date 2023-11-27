#!/bin/bash

# Check if git is already installed
if ! command -v git > /dev/null 2>&1; then
    echo "git is not installed. Please install git and try again."
    exit 1
fi

# Check if gh is already installed
if ! command -v gh > /dev/null 2>&1; then
    echo "gh is not installed. Please install gh and try again."
    exit 1
fi

# Check gh login status
if ! gh auth status >/dev/null 2>&1; then
    gh auth login
fi

# Check gh login status
if ! gh auth status >/dev/null 2>&1; then
    echo "gh is not logged in to GitHub CLI"
    gh auth login
    exit 1
else 
    gh config set -h github.com git_protocol https
fi

# Check if there is a parameter provided, similar to https://github.com/****/****
if [ "$#" -lt 1 ]; then
    echo "A github repository link is required as a parameter, Usage: $0 [url]"
    exit 1
fi

url=$1

if [ "$#" -eq 2 ]; then
    organization=$2
fi

# Use regular expressions to match URLs and extract the username and repository name
if [[ ! $url =~ ^https://github.com/([^/]+)/([^/]+)/?$ ]]; then
    echo "Invalid GitHub HTTPS URL."
    exit 1
fi

user=${BASH_REMATCH[1]}
repo=${BASH_REMATCH[2]}

# Construct SSH URL
ssh_url="git@github.com:$user/$repo.git"

echo $ssh_url

# get username
name=$(gh api user --jq '.login')

# Create a bare clone of the repository
git clone --bare $ssh_url

# Create a new private repository on Github and name it $repo
# gh auth login
# Check if the organization variable is empty
if [ -z "$organization" ]; then
    gh repo create $name/$repo --private
else
    gh repo create $organization/$repo --private
fi

# Mirror-push your bare clone to your new $repo repository
cd "$repo.git"
if [ -z "$organization" ]; then
    git push --mirror "git@github.com:$name/$repo.git"
else
    git push --mirror "git@github.com:$organization/$repo.git"
fi

# Remove the temporary local repository you created in step 1.
cd ..
rm -rf "$repo.git"

# You can now clone your $repo repository on your machine

if [ -z "$organization" ]; then
    git clone "git@github.com:$name/$repo.git"
else
    git clone "git@github.com:$organization/$repo.git"
fi
cd $repo

# If you want, add the original repo as remote to fetch (potential) future changes. Make sure you also disable push on the remote 
git remote add upstream $ssh_url
git remote set-url --push upstream DISABLE

# You can list all your remotes with
git remote -v