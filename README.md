# skills

Claude Code用の自作カスタムスキル置き場。`skills/` 配下の各スキルを `~/.claude/skills/` からシンボリックリンクで参照し、git管理する。

## スキルを追加する

1. `skills/<name>/` にスキルを作成する（`SKILL.md` を置く）
2. `~/.claude/skills/<name>` からシンボリックリンクを貼る

   ```bash
   ln -s "$(pwd)/skills/<name>" ~/.claude/skills/<name>
   ```

3. `git add` してコミットする

## claude.ai で配るスキル

Cloud セッション（claude.ai/code）では `~/.claude/skills/` が読まれないため、Cloud でも使うスキルは claude.ai に個人スキルとしてアップロードする。ローカルには claude.ai から `~/.claude/skills/synced/` に同期されるので、symlink は貼らない。

対象は `Makefile` の `CLAUDE_AI_SKILLS` で管理する（`make install` はこれらをスキップする）。更新したら `make package` で `dist/<name>.zip` を作り、claude.ai に再アップロードする。
