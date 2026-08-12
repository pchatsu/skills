# マイクロインタラクション

文書とプレゼンテーションは、フォームだらけのWebアプリと違ってインタラクションの数がそもそも少ない。だからこそ、数少ないインタラクションの質がそのまま「作り込まれている」か「生成された感じがする」かを分ける。ここでは文書・プレゼンテーションで実際に使う頻度が高いものだけを扱う——目次のアンカー、折りたたみセクション、コードのコピー、スライドナビ、控えめなスクロールリビュー、ダーク/ライト切り替え。ドロップダウンメニュー、複雑なフォームバリデーション、ドラッグ&ドロップ、複数ステップのモーダルフローのようなWebアプリ的なUIはこのスキルの対象外。

マイクロインタラクションは1つのイベントであり、trigger（引き金）→ rules（動作のルール）→ feedback（反応）→ loops/modes（継続とモード）の4段階で構成される（Saffer）。どれか1つでも欠けると未調整に見える。すべて揃えば、他に特別なことをしなくても「作り込まれた」印象になる。

## 原則

- **モーションには意図がある。なければ削る。** すべてのアニメーションは、何かを明確にする・誘導する・確認する目的を持つ。言葉にできない動きは装飾であり、装飾はAI臭さの温床になる。
- **抑制は個性ではなく判断。** 「モーションを一切使わない」ことが目的ではない。「正しい場所に正しいモーションを置く」ことが目的。目次のスムーズスクロールは良い例。すべてのセクション見出しがスクロールで脈打つのは悪い例。
- **reduced motionは一級市民。** すべてのインタラクションは、reduced-motion時にどう振る舞うかを明示的に定義する。デフォルトは「空間的な動きはopacityクロスフェードに置き換え、durationは150ms以下にする。開閉・選択中などの機能的な状態変化はそのまま保持する」。
- **キーボードが先、ホバーは後。** すべてのホバー効果は、フォーカスでも同じように働くようにする。ホバーだけで完結するインタラクションは作らない。特にスライドナビ・折りたたみ・コピーボタンは、キーボードだけで操作を完結できるようにする。

## タイミングの規範

durationのトークンは[`motion.md`](motion.md)の`--dur-micro`（120ms）／`--dur-short`（220ms）／`--dur-long`（420ms）をそのまま使う。ここで新しい数値を発明しない。用途ごとの対応は次の通り。

| トークン | 用途 |
| --- | --- |
| **`--dur-micro`（120ms）** | 即時フィードバック（コピーボタン押下のtick、折りたたみトグルのアイコン回転）、ホバー状態の遷移、フォーカスリングの出現、TOCのハイライト移動。 |
| **`--dur-short`（220ms）** | 折りたたみセクションの開閉、スライド切り替えのクロスフェード、ツールチップの表示。 |
| **`--dur-long`（420ms）** | スクロールリビューのフェードイン、ページロード時の初出現。 |
| **0 ms（トークンなし）** | フォーカス状態、キーボードナビゲーション、進捗インジケーターの数値更新はアニメーションさせない。意外と正解であることが多い。 |

Exit（退出）のdurationはenter（進入）の60〜75%。`--dur-short`で入るなら`calc(var(--dur-short) * 0.75)`程度で出る。逆は誤り。

## イージングの規範

イージングは[`motion.md`](motion.md)で定義した`--ease-out`／`--ease-in`／`--ease-in-out`の3種類をそのまま使う。ここで定義し直さない。

**禁止カーブ:** `ease`（ブラウザのデフォルト、平板で未調整に見える）、`linear`（進捗表示以外）、110%を超えるオーバーシュート（`cubic-bezier(0.34, 1.56, 0.64, 1)` の類）。文書・スライドはビジネス/編集コンテンツであり、バウンス演出はふさわしくない。

## レシピ

各レシピは trigger／変化する内容／duration／イージング／アクセシビリティ注記の順。

### 目次（TOC）のアンカーリンク

Trigger: TOC項目のクリック。変化: `scroll-behavior: smooth` によるスムーズスクロール、または `Element.scrollIntoView({ behavior: "smooth", block: "start" })`。Duration: ブラウザ制御（概ね300〜500ms）。A11y: `prefers-reduced-motion: reduce` のときは `scroll-behavior: auto` に切り替え、瞬時にジャンプする。

```css
html {
  scroll-behavior: smooth;
  scroll-padding-top: 4rem; /* 固定ヘッダー分のオフセット */
}
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
}
```

**scroll-spy（現在地のハイライト）。** `IntersectionObserver` で見出しの可視状態を監視し、対応するTOC項目に `aria-current="location"` を付与する。ハイライトの移動自体は`var(--dur-micro)` `--ease-out` の色変化程度に留め、TOC全体を揺らさない。

```js
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    const link = toc.querySelector(`a[href="#${entry.target.id}"]`);
    if (!link) return;
    link.toggleAttribute("aria-current", entry.isIntersecting);
  });
}, { rootMargin: "-20% 0px -70% 0px" });

headings.forEach((h) => observer.observe(h));
```

複数の見出しが同時に交差範囲に入る場合は、最も上にあるものを優先する。TOCが同時に0個、または2個以上ハイライトされている状態は事故なので、必ず1つだけ選ばれるようロジックを詰める。

### 折りたたみセクション／アコーディオン

Trigger: 見出しまたはトグルアイコンのクリック。ネイティブの `<details>`/`<summary>` を第一候補にする——キーボード操作・スクリーンリーダー対応・状態管理が無料で手に入る。カスタムアニメーションが必要な場合のみJSで開閉状態を制御する。

```html
<details>
  <summary>補足: 実装の詳細</summary>
  <div class="details__body">…</div>
</details>
```

高さのアニメーションが欲しい場合は `height` や `max-height` を直接遷移させない（レイアウトプロパティのアニメーションはガタつく）。`grid-template-rows: 0fr → 1fr` のトリックを使う。

```css
.accordion__panel {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows var(--dur-short) var(--ease-in-out);
}
.accordion__panel > div { overflow: hidden; }
.accordion[data-open="true"] .accordion__panel { grid-template-rows: 1fr; }
```

トグルアイコン（シェブロン等）は `transform: rotate()` で`var(--dur-micro)` `--ease-out` 回転させる。A11y: `aria-expanded` をトグル要素に、パネルには `id` を対応付けて `aria-controls` で参照する。

### コードブロックのコピーボタン

Trigger: クリック。変化: ボタンのラベル/アイコンがチェックマーク付きの「Copied」に切り替わり、2〜2.5秒後に元に戻る。**トーストは出さない。** ラベルの変化自体がフィードバックである。

```js
btn.addEventListener("click", async () => {
  await navigator.clipboard.writeText(code);
  btn.dataset.state = "copied";
  setTimeout(() => delete btn.dataset.state, 2500);
});
```

```css
.copy-btn[data-state="copied"] .copy-btn__label::after { content: "  ✓  Copied"; }
.copy-btn[data-state="copied"] .copy-btn__label > * { opacity: 0; }
```

クリップボードAPIが使えない・拒否された場合は、ボタンのラベルを「Copy failed」に切り替えるか、選択範囲を作ってユーザーに手動コピーを促す。無言で失敗させない。

### スライドの次へ／前へナビゲーション

Trigger: クリック、または右矢印キー／スペースキー（次へ）・左矢印キー（前へ）。変化: スライド間の遷移は基本的に**カット（0ms）または`--dur-short`（220ms）の`--ease-out`クロスフェード**のいずれかに統一する。1デッキの中で遷移効果を混在させない。

- 端（最初/最後のスライド）では対応するボタンを `disabled` にする。非表示にはしない——ボタンの数が変わるとレイアウトが動く。
- 進捗インジケーター（「3 / 24」やドット列）の更新はアニメーションさせず即時反映する。
- reduced-motion時はクロスフェードも省略し、即座に切り替える。

具体的な実装は [`responsive.md`](responsive.md) の「スライドナビゲーション」を参照。

### 軽いスクロールリビュー

文書の見出しやセクションがビューポートに入ったときに、控えめなフェードインを1つだけ加えるのは許容範囲。ただし**やりすぎ注意**——長文をスクロールするたびに要素が次々フェードインすると、読者は「読む」ことより「演出を眺める」ことに気を取られ、読み進める速度がアニメーションに制約されてしまう。

- 演出は1種類に絞る（opacityフェード、または8px程度の控えめな `translateY`）。両方を同時に使わない。
- Duration: `--dur-long`（420ms）、`--ease-out`。
- `IntersectionObserver` を使う。scrollイベントリスナーでの逐次計算はしない。
- **1回きりの初出現に留める。** 上下にスクロールし直すたびに再生させない（`observer.unobserve()` で一度発火したら監視を外す）。
- 本文の長い段落そのものはフェードインさせない。読者が先に文章を読み始めてしまい、透明な文字を追いかける事故になる。対象は見出し・図版・強調ブロックなど、意味のまとまりの単位に限る。
- reduced-motion時は即座に表示し、フェードを省略する。

```css
.reveal {
  opacity: 0;
  transform: translateY(8px);
  transition: opacity var(--dur-long) var(--ease-out), transform var(--dur-long) var(--ease-out);
}
.reveal.is-visible {
  opacity: 1;
  transform: none;
}
@media (prefers-reduced-motion: reduce) {
  .reveal { opacity: 1; transform: none; transition: none; }
}
```

### ダーク／ライトモード切り替え

Trigger: クリック。変化: アイコン（太陽/月）のクロスフェードまたはモーフ、`var(--dur-micro)` `--ease-out`。テーマ自体の切り替えはCSSカスタムプロパティの再割り当てで瞬時に行い、色のトランジションを付けるとしても `background-color`/`color` に対して`var(--dur-micro)`程度に留める（すべての要素に長いトランジションを付けると切り替え中ちらつく）。

```css
:root { color-scheme: light dark; }
.theme-toggle[aria-pressed="true"] .icon-moon { opacity: 1; }
.theme-toggle[aria-pressed="false"] .icon-sun { opacity: 1; }
```

A11y: `aria-pressed` で現在の状態を示す。`prefers-color-scheme` をデフォルト値として尊重し、ユーザーが明示的に切り替えた場合のみ `localStorage` 等で上書きを保持する。

## AI生成コードに現れる兆候（named tells）

以下は生成コード特有のマイクロインタラクションの署名である。1つでも見つけたら重大な指摘として扱う。

1. **`transition-all`。** visibilityやdisplay、フォーカスリングのような即時であるべきプロパティまで含め、すべてのプロパティがアニメーションしてしまう。プロパティは必ず個別に指定する。
2. **オーバーシュート気味のバウンスイージング。** `cubic-bezier(0.34, 1.56, 0.64, 1)` の類。編集的な文書やスライドには特にふさわしくない。2018年の名残で野暮ったい。
3. **レイアウトプロパティへの `transition`。** `height`、`max-height`、`padding` のアニメーション。毎フレームreflowを引き起こす。`transform` か `grid-template-rows: 0fr → 1fr` を使う。
4. **一律のスクロール連動フェードアップスタガー。** すべての見出し・段落・画像が交差時にフェードインし、ページが落ち着かない。演出は1つだけ選び、対象は絞る。
5. **フェードインするフォーカスリング。** リングが200msかけて現れると、遷移の開始時点でキーボードユーザーに指標がない。フォーカスリングは常に即時に出す。
6. **文字への発光ハロー。** 「ネオン風」の強い `text-shadow`。スライドの見出しに使われがちだが、コントラストを壊し可読性を損なう。
7. **スクロール連動のパララックス。** 文書のヒーロー領域などにレイヤーごとに異なる速度で動く演出を入れる。前庭感覚の誘発要因であり、読み物にはほぼ不要。

## アクセシビリティ最低ライン

- **`prefers-reduced-motion: reduce`** を尊重する。空間的な動きはopacityクロスフェード（150ms以下）に縮約する。
- **フォーカスリング**は2〜3px、コントラスト比3:1以上、フェードイン/アウトさせず、`:focus-visible` によりすべてのインタラクティブ要素に存在する。
- **ヒットターゲット**はタッチ面で44×44 CSS px以上（TOCリンク、折りたたみトグル、スライドナビボタン、コピーボタンすべて対象）。
- **すべてのホバー効果にキーボード相当の挙動がある。** 例外なし。
- **非同期の状態更新には `aria-live`** を使う（コピーボタンの成功表示など）。`polite` を基本とする。

## 迷ったら削る

文書・プレゼンテーションはモーションが主役ではない。出荷前に、出力中のすべてのアニメーションについて「これが瞬時に起きたらどうなるか」を自問する。「何も変わらない、読者は気づかない」なら削る。「何が変わったか分からなくなる」なら残す。

「動きをなくす」という結論に落ち着くのは、判断がきちんと働いている証拠。モーションを足したがるのがAIの既定の癖である。
