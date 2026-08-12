---
name: textlint
description: Markdownファイルにtextlintをかけてエラーを検出し、AIが自動修正する。ユーザーが「/textlint ファイル名」と入力したとき、文章校正を依頼したとき、日本語の文章チェックを求めたときに使用する。
---

# Textlint

指定されたMarkdownファイルにtextlintをかけてエラーを検出し、AIが修正する。

## 実行手順

1. 対象ファイルの存在確認
2. textlintを実行してエラーを検出
3. ファイルを読み込み、検出されたエラーをAIが修正
4. 修正内容を報告

## コマンド

```bash
textlint -c ~/.claude/skills/textlint/.textlintrc.json <ファイルパス>
```

## 使用例

ユーザー: `/textlint test.md`

実行:
```bash
textlint -c ~/.claude/skills/textlint/.textlintrc.json test.md
```

エラー例:
```
1:5   error  "システム" が連続して2回使われています
1:20  error  "である"調 でなければなりません
```

AIが修正:
- 「システムシステムは」→「システムは」
- 「できます。」→「できる。」

## 注意事項

- ファイルは直接上書きされる
- 修正前のバックアップは作成しない
- 全てのエラーをAIが解釈して修正する
