<!-- rtk-instructions -->
# RTK — Token-Optimized CLI
**rtk** is a CLI proxy that filters and compresses command outputs, saving 60-90% tokens.
## Rule
Always prefix shell commands with `rtk`:
```bash
# Instead of:              Use:
git status                 rtk git status
git log -10                rtk git log -10
cargo test                 rtk cargo test
docker ps                  rtk docker ps
kubectl get pods           rtk kubectl pods
```
## Meta commands (use directly)
```bash
rtk gain              # Token savings dashboard
rtk gain --history    # Per-command savings history
rtk discover          # Find missed rtk opportunities
rtk proxy <cmd>       # Run raw (no filtering) but track usage
```
<!-- /rtk-instructions -->

# 個人用グローバル指示

## 出力制御（最優先）
- 結論から書く。前置き・要約・謝辞・確認の繰り返しは禁止。
- コードは変更箇所(diff)のみ。全文再掲は明示要求時のみ。
- 説明・解説は求められた場合のみ。自明な注釈は省略。
- 不確実な内容は「推測」「未検証」と明示し、それ以上の確認往復はしない。

## 思考・探索の制限
- 十分な情報が揃えば即実装/回答に移る。同じ検索・読み込みを繰り返さない。
- 不確実でも最有力の1案で進める。全候補列挙は不要。
- 同じ修正を2回試して解決しなければ停止し、状況のみ報告して指示を待つ。

## エンジニアリング方針
- コードのコメント・識別子は英語。
- 可読性優先。適宜簡潔なコメント追加。
- 外部依存追加は提案のみ。

## シェル環境の注意（重要・地雷）
以下のコマンドはaliasにより置換されている:
`ls` `la` `ll` `lt` `tree` `cat` `less` `diff` `du` `df` `free` `top` `ps`
`rm` `cp` `mv` `mkdir` `chmod` `chown` `chgrp` `grep` `fgrep` `egrep`
実行する際は、先頭に `\` を付けて（例: `\cat file`）実行。

## 物理計算
- 自然単位系($\hbar = c = 1$)を採用。

## 環境
- WSL2 Ubuntu 24.04 + zsh + VS Code（Remote-SSH）
