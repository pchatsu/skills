# skills

Claude Code用の自作カスタムスキル置き場。`skills/` 配下の各スキルを `~/.claude/skills/` からシンボリックリンクで参照し、git管理する。

## スキルを追加する

1. `skills/<name>/` にスキルを作成する（`SKILL.md` を置く）
2. `~/.claude/skills/<name>` からシンボリックリンクを貼る

   ```bash
   ln -s "$(pwd)/skills/<name>" ~/.claude/skills/<name>
   ```

3. `git add` してコミットする