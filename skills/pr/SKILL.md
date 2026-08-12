---
name: pr
description: プロジェクト固有のテンプレートとチケット番号付きタイトルでPRを作成する。ユーザーが「/pr」と入力したとき、PRを作成したいとき、PRを開きたいとき、変更をレビューに提出したいときに使用する。commitを自動分析し、テンプレートからPR説明を生成し、GitHub CLIでPRを作成する。
---

# PR作成

PRを作成する。

## ワークフロー

### 1. 現在の状態を分析

branchの状態を把握するため、以下のコマンドを並列実行:

```bash
# 現在のbranchとステータスを確認
git status
git branch --show-current

# remote追跡branchの確認
git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "No upstream"

# mainから分岐後のcommit一覧
git log main..HEAD --oneline

# PR説明用の差分を取得
git diff main...HEAD
```

### 2. タイトル形式の決定

タイトル形式: `簡潔な説明`（70文字以内）

Issue 番号やチケット番号はタイトルに含めない。

### 3. PR本文の生成

プロジェクトテンプレート (`.github/pull_request_template.md` など)が存在する場合はそのテンプレートを使用。

ない場合は、以下のデフォルトを使用。

```markdown
# Issue Link

- [URL]

# やった事

- このPRで何をしたのか？


# Refs (コーディングにあたって参考にした情報）

- [URL]
```

テンプレートの埋め方:
- チケット番号が見つかればIssueリンクを追加。見つからなければ「なし」と記載
- 「やった事」は、プロンプト指示から、このPRで実現することを必要十分かつ簡潔に記載する（コードや編集ファイルの説明は意図が反映されず意味のない記述になるのでしないこと）
- 参照した公式ドキュメントやリンクがあればRefsに記載
- AIが書いた典型例になってしまい読みづらくなってしまわないようにする

### 4. push とPR作成

```bash
# upstream追跡付きでbranchをpush
git push -u origin $(git branch --show-current)

# HEREDOCで本文をformatしてPR作成
gh pr create --title "簡潔なタイトル" --body "$(cat <<'EOF'
# Issue Link

- https://github.com/org/repo/issues/XXX

# やった事

- 変更内容の要約...

## なぜやるのか

- 必要に応じて追加のコンテキスト

# Refs (コーディングにあたって参考にした情報）

- 参照したドキュメント
EOF
)"
```

### 5. 結果の報告

完了後、PR URLをユーザーに返す。

## 重要なルール

- main/masterに直接pushしない
- 明示的に要求されない限り `--force` を使用しない
- git hook（`--no-verify`）をスキップしない
- 正確なPR説明のためbranch内の全commitを分析する
