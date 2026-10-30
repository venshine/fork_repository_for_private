[English](README.md) | 简体中文

[![CI](https://github.com/venshine/fork_repository_for_private/actions/workflows/ci.yml/badge.svg)](https://github.com/venshine/fork_repository_for_private/actions/workflows/ci.yml)

GitHub 不允许为公开仓库的 fork 创建私有分支。这里记录了通过[复制仓库](https://docs.github.com/zh/repositories/creating-and-managing-repositories/duplicating-a-repository)的方式，把公开仓库复制成私有仓库的方法，并提供了自动化脚本。

> 需要预先安装 `git` 和 `gh` 命令。

## 用法
1. 复制到个人私有仓库，脚本会自动创建仓库：
```
bash fork_repository_private.sh $github_public_repository_url
```
2. 复制到团队（组织）私有仓库，脚本会自动创建仓库：
```
bash fork_repository_private.sh $github_public_repository_url $team
```

## 示例
```
bash fork_repository_private.sh https://github.com/venshine/json2model
```
