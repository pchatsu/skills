---
name: ship
description: 実装を PR 作成、セルフレビュー、CI 対応、レビューコメント対応まで進め、merge ready になったら通知する。実装・修正・機能追加を頼まれたとき（壁打ちや相談でない場合）、または「/ship」「PRまでやって」と言われたときに使う。
---

# ship

実装を merge ready まで自走で進める。**merge はしない**。最後の判断はユーザーが行う。

## merge ready の定義

次の条件をすべて満たした状態。

- CI の必須チェックがすべて pass している
- `/code-review` の指摘に対応済み
- bot（Codex など）のレビューコメントに対応済みで、未解決のスレッドがない
- base branch とのコンフリクトがない

人間の approve は待たない。

## 止まってユーザーに確認する条件

次のどれかに当たったら作業を止め、`AskUserQuestion` で確認する。同時に `PushNotification` で「確認待ち」と通知する（離席していても気付けるように）。

- 仕様が複数通りに読め、どれを選ぶかで実装が大きく変わる
- 公開 API、DB スキーマ、マイグレーション、新しい依存パッケージを追加・変更する
- 認証・認可、秘密情報、課金、本番データに関わる
- 依頼された範囲を超える変更（大きなリファクタなど）が必要になった
- 同じ CI 失敗を 3 回直しても通らない
- レビュー指摘に同意できない、または指摘同士が矛盾している
- force push、履歴の書き換え、branch の削除が必要になった

上記に当たらない細かい判断（命名、テストケースの追加、lint 修正など）は自分で決めて進め、PR 本文か最終報告に書く。

## ワークフロー

### 1. 準備

- default branch にいる場合は作業用 branch を切る
- リポジトリの CLAUDE.md、CONTRIBUTING、Makefile、package.json などを見て、test / lint / format のコマンドを確認する

### 2. 実装とローカル検証

- 実装する
- test / lint / typecheck をローカルで通す。通らないまま PR を出さない
- 意味のある単位で commit する

### 3. PR 作成

`pr` skill の手順で PR を作成する。

### 4. セルフレビュー

`/code-review` を実行する（`--comment` は付けない）。妥当な指摘は修正して commit・push する。採用しなかった指摘は理由を控えておき、最終報告に書く。

### 5. CI とレビューの監視ループ

PR の状態は、この SKILL.md と同じディレクトリにある `pr-status.sh` で取得する。skill の置き場所は環境によって違う（ローカル、claude.ai から同期されたもの、Cloud セッション）ので、最初に一度パスを確認する。

```bash
PR_STATUS=$(find ~/.claude/skills -path '*/ship/pr-status.sh' 2>/dev/null | head -1)
bash "$PR_STATUS" [PR番号]
```

CI の完了は `run_in_background` で待つ（終わると自動で再開される）。

```bash
gh pr checks --watch --fail-fast
```

次の順で処理し、merge ready になるまで繰り返す。

1. **CI が失敗した**: `gh run view <run-id> --log-failed` でログを読み、原因を直して push する。flaky と判断した場合だけ `gh run rerun --failed` を使い、その旨を記録する
2. **未解決のレビュースレッドがある**: 指摘を読んで対応する
   - 修正した場合: push してから、スレッドに対応内容を短く返信する
   - 修正しない場合: 理由を返信する。判断に迷う場合は止まって確認する
   - 返信は `gh api` で行う。スレッドの resolve は、修正が明らかに完了したものだけ行う
3. **コンフリクトがある**: base branch を merge して解消する（rebase と force push はしない）。解消方法に迷ったら止まって確認する
4. **CI がすべて green になった**: bot のレビューが最新 commit に対して終わっているか確認する
   - `== Codex review state` の各 review が `status` が running 以外で、`commit` が head と一致していれば完了
   - Codex の状態が出ないリポジトリでは、最後の push から 5 分ほど経ってから `pr-status.sh` を再確認する
   - 待つ間は `run_in_background` で `sleep 120 && bash "$PR_STATUS"` などを実行し、ポーリングで context を消費しない
   - 完了していて未解決スレッドがなければ merge ready

push するたびに CI は再実行されるので、ループの先頭に戻る。

### 6. 通知と報告

merge ready になったら `PushNotification` で通知する。`PushNotification` が使えない環境（Cloud セッションなど）では、最終報告のメッセージをもって通知とする（Claude アプリが完了を知らせる）。

- 例: `PR #123 merge ready: <タイトル>`

ターミナルには次を簡潔に報告する。

- PR の URL
- 何をしたか（1〜3 行）
- 自分で判断して進めた点
- 採用しなかったレビュー指摘とその理由
- 気になっているが今回はスコープ外にした点

## やってはいけないこと

- PR を merge する、auto-merge を有効にする
- テストを skip や削除して CI を通す
- force push する（ユーザーの許可がある場合を除く）
- 必須チェックや branch protection を回避する
