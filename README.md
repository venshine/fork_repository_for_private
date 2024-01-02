The public repositories provided by Github do not allow the creation of private branches, and the method of creating a private branch by [copying the repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/duplicating-a-repository) is documented here.

> The git and gh commands need to be installed.

## Usage
1. fork project to personal private repository
```
sh fork_repository_private.sh $github_public_repository_url
```
2. fork project to team private repository
```
sh fork_repository_private.sh $github_public_repository_url $team
```

## Demo
```
sh fork_repository_private.sh https://github.com/venshine/json2model
```
