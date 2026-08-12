# インタラクションと状態

文書・プレゼンテーションが持つインタラクティブ要素はごくわずかで、状態も限られる——コピーボタン、折りたたみセクション、スライドナビ、TOCリンク、ダーク/ライト切り替えくらいである。複雑なフォーム部品が必要とする8状態フルセット（default/hover/focus-visible/active/disabled/loading/error/success）は基本的に出番がない。ただし、**状態を持つ要素が少ないからこそ、その少数の実装が雑だと目立つ。** 「状態遷移でレイアウトを動かさない」「フォーカスリングは即座に表示する」といった一般原則は、要素の種類を問わずそのまま当てはまる。

## 対象要素と状態

| 要素 | 持つ状態 | 扱い |
| --- | --- | --- |
| コピーボタン | default / hover / focus-visible / active / success（任意でloading） | ラベル差し替えで成功を示す。トーストは出さない |
| 折りたたみ/アコーディオン | default / hover / focus-visible / open / closed | `aria-expanded` で開閉を示す。開閉でレイアウトが動くのは想定内だが、周囲の要素を無関係にガタつかせない |
| スライドナビ（前へ/次へ） | default / hover / focus-visible / active / disabled（最初/最後のスライド） | 端で `disabled`。非表示にしない |
| TOCリンク | default / hover / focus-visible / active（現在読んでいるセクション） | scroll-spyで自動的にactiveを切り替える |
| ダーク/ライト切り替え | default / hover / focus-visible / pressed | `aria-pressed` で状態を示す |

本番の要素にこれらのいずれかが欠けているなら、その要素は未完成である。

## フォーカスリング

すべてのインタラクティブ要素に、常に見える形で存在させる。

```css
:focus { outline: none; }
:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
  border-radius: inherit;
}
```

要件:

- 2〜3px、要素・ページ双方に対してコントラスト比3:1以上。
- 要素から2pxのオフセット。
- `:focus` ではなく `:focus-visible` を使い、キーボード操作時のみ表示する。
- 代替を用意しない `outline: none` は禁止。フォーカスを消して何も出さないのは、それだけで不合格にすべき問題である。
- **リングの出現自体をアニメーションしない。** フェードインするフォーカスリングは、遷移の開始時点でキーボードユーザーに指標がないという事故を生む。

## レイアウトシフト禁止の原則

**状態が変わってもボックスのジオメトリは変わらない。** border幅・padding・要素の高さは、default・hover・focus・disabled のどの状態でも一定に保つ。フォーカス時にボタンが1pxずれる、ホバー時にトグルが太くなる、といった変化は事故である。

```css
.copy-btn {
  border: 1px solid var(--color-rule-2);   /* どの状態でも1px */
  outline: 2px solid transparent;          /* フォーカスリング用の予約枠 */
  outline-offset: 2px;
}
```

outlineを最初から透明な2px枠として確保しておくと、フォーカスリングが現れる時点ですでにボックスのジオメトリが正しく、レイアウトシフトが起きない。

## ヒットターゲット

タッチで到達可能な要素は最小44×44 CSS px。TOCリンクの行間が詰まっている場合や、折りたたみのシェブロンアイコンが小さい場合は、見た目のサイズを変えずにヒットターゲットを広げる。

```css
.accordion__toggle {
  position: relative;
}
.accordion__toggle::before {
  content: "";
  position: absolute;
  inset: -12px;
}
```

## 要素ごとの状態レシピ

### コピーボタン

- **Default.** アイコン＋「Copy」ラベル。
- **Hover / Focus-visible.** 背景をわずかに変える程度。
- **Active.** `transform: scale(0.98)` 程度の押下フィードバック。
- **Success.** クリック後にラベルを「Copied」＋チェックアイコンへ置き換え、2〜2.5秒後に自動で戻す。色だけに頼らずアイコンとラベル両方を変える。`aria-live="polite"` な領域で状態変化を告知してもよいが、確認のためのトーストは出さない。
- **失敗時.** クリップボードAPIが拒否された場合はラベルを「Copy failed」に変え、無言で失敗させない。

### 折りたたみ/アコーディオン

- **Closed / Open.** `aria-expanded="false"|"true"` をトグル要素に設定し、パネルには `aria-controls` で対応付ける。ネイティブの `<details>`/`<summary>` を使えば多くがデフォルトで揃う。
- **Focus-visible.** サマリー行全体がフォーカス対象。フォーカスリングはサマリーの外周に出す。
- 開閉時の高さアニメーションは `grid-template-rows: 0fr → 1fr` を使い、`height`/`max-height` を直接遷移させない（詳細は [`microinteractions.md`](microinteractions.md)）。

### スライドナビゲーション

- **Default / Hover / Focus-visible / Active.** 通常のボタンと同様。
- **Disabled.** 最初のスライドで「前へ」、最後のスライドで「次へ」を `disabled` にする。`opacity: 0.4` 程度＋`cursor: not-allowed`＋`aria-disabled` の複数シグナルで示し、色だけに頼らない。ボタンを取り除いたり隠したりしない——ボタンの有無が変わるとレイアウトが揺れ、クリック位置への信頼が崩れる。
- 進捗インジケーターの数値/位置更新はアニメーションさせず即時反映する。

```css
.slide-nav__btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
```

### TOCリンク

- **Default / Hover / Focus-visible.** 通常のリンクと同様、下線またはインジケータバーで示す。
- **Active（現在地）.** scroll-spyが検出した現在のセクションに `aria-current="location"` を付与し、視覚的にはアクセントカラーや左端のバーで示す。ハイライトの移動は150ms程度の色変化に留め、TOC全体の高さやレイアウトは動かさない。

### ダーク/ライト切り替え

- **Default / Hover / Focus-visible.** アイコンボタンとして通常の状態遷移。
- **Pressed.** `aria-pressed="true"|"false"` で現在のテーマを示す。アイコンのクロスフェード/モーフは150〜200ms。

## コントラストの規律

出荷前に、ページ上に実際に描画されるすべての `(文字色, 背景色)` の組み合わせについてコントラストを計算する。文書・スライドは特に、セクションごとに背景色を反転させる（明るい紙色↔暗いink色のセクション）演出を使うことが多く、そこでの事故が最も起きやすい。

1. **反転した面の上の文字。** `.section--ink { background: var(--color-ink); }` で面を暗く反転させたのに、内部の文字が引き続き `color: var(--color-ink)` を継承し、ink on inkになる。対策: 暗い `background` を設定するルールは、同じルールの中で必ず `color: var(--color-paper)` も設定する。

```css
/* 誤り — 文字はcolor: var(--color-ink)を継承し、ink on inkになる */
.section--flip { background: var(--color-ink); }

/* 正しい */
.section--flip {
  background: var(--color-ink);
  color: var(--color-paper);
}
```

2. **アクセント塗りの上のボタン文字。** `background: var(--color-accent); color: white;` — whiteが4.5:1を満たすのは `--color-accent` が十分暗い場合のみ。`--color-accent-ink` のような、アクセント色に対しAPCA Lc 60以上を保証するトークンを別途用意して使う。
3. **淡い背景の上のミュートテキスト。** キャプションや出典表記に使う `--color-muted` は、背景が `--color-paper-3` のような中間トーンだと4.5:1を下回りやすい。より暗いニュートラル色を使うか、背景をより明るくする。
4. **フォーカスリングとアクセント塗りの衝突。** ボタンの塗りが `--color-accent` のとき `outline: 2px solid var(--color-focus);` を使うと、両者が同系色ならリングが視認できなくなる。フォーカス色は要素・ページ双方に対しコントラスト比3:1以上のペアにする。

### 計算方法

- **APCA Lc**（知覚的で望ましい）または **WCAG 2.1比**で計算する。
- 事前チェック: 両方がOKLCHで `|L_a − L_b| < 50%` なら、フルチェック対象としてフラグを立てる。
- 文書の本文テキストは **APCA Lc ≥ 60**（≈ WCAG 4.5:1）。プレゼンテーションの本文は **APCA Lc ≥ 75**（プロジェクター等での視認性を見込んだ余裕。詳細は [`responsive.md`](responsive.md) B節）。
- 大きい文字・フォーカスリング・アイコンは **APCA Lc ≥ 45**（≈ WCAG 3:1）を最低ラインとする。

## 禁止事項

- placeholderやツールチップだけに機能の説明を頼ること（ホバーできないタッチユーザーが締め出される）。
- ホバーだけで成立する機能。TOCのハイライトも折りたたみトグルも、キーボードで到達・操作できること。
- 代替なしでフォーカスリングを消すこと。
- 44px未満のタッチターゲット。
- 色だけによる状態表現（成功・エラー・現在地のすべてでアイコンかテキストを併用する）。
- スライドナビのボタンを、無効化ではなく非表示にすること。
