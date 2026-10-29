#!/bin/bash
# 回归测试：用假的 git / gh 命令记录调用，不会真的访问 GitHub
set -eu
ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'EOF'
#!/bin/bash
echo "gh $*" >> "$CMD_LOG"
case "$1 $2" in
	"api user") echo "me" ;;
esac
exit 0
EOF
cat > "$WORK/bin/git" <<'EOF'
#!/bin/bash
echo "git $*" >> "$CMD_LOG"
if [ "$1" = "clone" ]; then
	if [ "${FAIL_CLONE:-0}" = "1" ]; then
		exit 128
	fi
	last="${@: -1}"
	case "$last" in
		*:*) mkdir -p "$(basename "$last" .git)" ;;
		*) mkdir -p "$last" ;;
	esac
fi
exit 0
EOF
chmod +x "$WORK/bin/gh" "$WORK/bin/git"
export PATH="$WORK/bin:$PATH"
export CMD_LOG="$WORK/cmd.log"

FAILED=0
fail() {
	echo "FAIL $1"
	FAILED=1
}

# 1. URL 带 .git 后缀时，仓库名不应变成 xxx.git
mkdir -p "$WORK/case1"
(cd "$WORK/case1" && bash "$ROOT/fork_repository_private.sh" https://github.com/venshine/json2model.git > /dev/null 2>&1) || fail "script exited with error for .git url"
grep -q "^gh repo create me/json2model --private" "$CMD_LOG" || fail "repo name should strip .git suffix"

# 2. clone 失败时应立即退出，不能继续 push 或删除当前目录下的同名目录
: > "$CMD_LOG"
mkdir -p "$WORK/case2/json2model.git"
touch "$WORK/case2/json2model.git/keep"
if (cd "$WORK/case2" && FAIL_CLONE=1 bash "$ROOT/fork_repository_private.sh" https://github.com/venshine/json2model > /dev/null 2>&1); then
	fail "script should fail when clone fails"
fi
grep -q "push" "$CMD_LOG" && fail "script should not push after clone fails"
grep -q "repo create" "$CMD_LOG" && fail "script should not create repo after clone fails"
[ -f "$WORK/case2/json2model.git/keep" ] || fail "script removed an unrelated directory"

# 3. 不应修改用户的 gh 全局配置
grep -q "config set" "$CMD_LOG" && fail "script should not change gh config"

if [ "$FAILED" -ne 0 ]; then
	exit 1
fi
echo "all tests passed"
