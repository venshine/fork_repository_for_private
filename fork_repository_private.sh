#!/bin/bash

# 任一步失败立即退出，避免在错误的目录继续 push 或删除
set -euo pipefail

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
if ! gh auth status >/dev/null 2>&1; then
    echo "gh is not logged in to GitHub CLI"
    exit 1
fi

# Check if there is a parameter provided, similar to https://github.com/****/****
if [ "$#" -lt 1 ]; then
    echo "A github repository link is required as a parameter, Usage: $0 [url] [organization]"
    exit 1
fi

url=$1
organization=${2:-}

# Use regular expressions to match URLs and extract the username and repository name
if [[ ! $url =~ ^https://github\.com/([^/]+)/([^/]+)/?$ ]]; then
    echo "Invalid GitHub HTTPS URL."
    exit 1
fi

user=${BASH_REMATCH[1]}
repo=${BASH_REMATCH[2]%.git}

# Construct SSH URL
ssh_url="git@github.com:$user/$repo.git"

echo "$ssh_url"

# The owner of the new private repository: organization if provided, otherwise current user
owner=${organization:-$(gh api user --jq '.login')}
target_url="git@github.com:$owner/$repo.git"

# Create a bare clone of the repository in a temporary directory
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
git clone --bare "$ssh_url" "$tmp_dir/$repo.git"

# Create a new private repository on Github and name it $repo
gh repo create "$owner/$repo" --private

# Mirror-push your bare clone to your new $repo repository
git -C "$tmp_dir/$repo.git" push --mirror "$target_url"

# You can now clone your $repo repository on your machine
git clone "$target_url"

# If you want, add the original repo as remote to fetch (potential) future changes. Make sure you also disable push on the remote
git -C "$repo" remote add upstream "$ssh_url"
git -C "$repo" remote set-url --push upstream DISABLE

# You can list all your remotes with
git -C "$repo" remote -v
