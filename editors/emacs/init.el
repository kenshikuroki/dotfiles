
;;=================================================
;; Package管理

(require 'package)
(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/") t)
;;(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
;;(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)
(package-initialize)
(setq package-check-signature nil) ;; パッケージのGPG署名検証を無効にする (一時的な対策)

(setq my-packages
      '(auto-complete
        highlight-indent-guides
        ;;golden-ratio
        hiwin
        smart-mode-line
        neotree
        all-the-icons ;; 最初にM+x all-the-icons-install-fontsが必要
        smartparens
        saveplace
        which-key
        flycheck
        flycheck-inline
        gnuplot
        company
        yasnippet-snippets
        rainbow-delimiters
        auto-complete-c-headers))
(defun install-missing-packages ()
  (interactive)
  (package-refresh-contents)
  (dolist (pkg my-packages)
    (unless (package-installed-p pkg)
      (package-install pkg))))
;;(install-missing-packages)


;;=================================================
;; Language settings

;; set language as Japanese and UTF-8
(set-locale-environment nil)
(set-language-environment 'Japanese)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8-unix)


;;=================================================
;; General settings

;; color theme
(load-theme 'misterioso t)

;; start up message非表示
(setq inhibit-startup-message t)
;; scratchの初期メッセージ消去
(setq initial-scratch-message nil)

;; beep音OFF
(setq ring-bell-function 'ignore)
;; Emacsからの質問をy/nで回答する
(fset 'yes-or-no-p 'y-or-n-p)

;; 起動時に最大ウィンドウサイズ
(setq initial-frame-alist '((fullscreen . maximized)))
;; アクティブウィンドウを大き目に
;;(require 'golden-ratio)
;;(golden-ratio-mode 1)
;; 非アクティブウィンドウの背景色を設定
(require 'hiwin)
(hiwin-activate)
(set-face-background 'hiwin-face "gray30")
;; C-x bを改善
(ido-mode 1)
(ido-everywhere 1)
;; C-x C-bを改善
(global-set-key (kbd "C-x C-b") 'ibuffer)
;; アイコン表示のための設定
(require 'all-the-icons)

;; neotree
(require 'neotree)
(global-set-key (kbd "C-x t") 'neotree)
;; treeバッファに行番号を表示しない
(add-hook 'neotree-mode-hook
          #'(lambda ()
              (display-line-numbers-mode -1)))
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))

;; タイトルバーにfull path表示
(setq frame-title-format "%f")
;; メニューバー非表示
(menu-bar-mode -1)
;; ツールバー非表示
(tool-bar-mode -1)
;; モードライン
;;(require 'smart-mode-line)
(defvar sml/no-confirm-load-theme t)
(defvar sml/theme 'dark)
(defvar sml/shorten-directory -1)
(sml/setup)
(setq my/hidden-minor-modes
      '(eldoc-mode
        auto-complete-mode
        company-mode
        yas-minor-mode
        global-whitespace-mode
        global-whitespace-newline-mode
        whitespace-mode
        rainbow-delimiters-mode
        smartparens-mode
        highlight-indent-guides-mode
        which-key-mode
        hs-minor-mode
        ;;golden-ratio-mode
        hiwin-mode
        abbrev-mode))
;; マイナーモードを非表示にする関数
(defun my/hide-minor-modes ()
  (mapc (lambda (mode)
          (setq minor-mode-alist
                (assq-delete-all mode minor-mode-alist)))
        my/hidden-minor-modes))
;; モードのフックに追加
(add-hook 'after-init-hook 'my/hide-minor-modes)
(add-hook 'prog-mode-hook 'my/hide-minor-modes)
;; モードラインに行列番号
(column-number-mode t)
(line-number-mode t)
;; モードラインにカーソルがある関数名
(which-function-mode t)
;; 関数や変数の情報をミニバッファに表示
(add-hook 'prog-mode-hook 'eldoc-mode)
;; 左側に行番号の表示
;;(require 'linum)
;;(global-linum-mode t)
;;(setq linum-format "%3d")
(global-display-line-numbers-mode t)
(setq display-line-numbers-width-start t)
;;; スクロールバーを右側に表示する
(set-scroll-bar-mode 'right)
;; 現在行を目立たせる
(global-hl-line-mode)

;; 1行ごとの改ページ
(setq scroll-conservatively 1)
;; 再開時のカーソル位置を前回終了時の位置に
(require 'saveplace)
(setq-local save-place t)
(save-place-mode 1) ;;emacsが新しいバージョンの時


;;================================================
;; Key bind

;; key bind help
(require 'which-key)
(which-key-mode 1)
(setq which-key-idle-delay 0.3)
;; コードの折りたたみ
(add-hook 'prog-mode-hook 'hs-minor-mode)
(define-key global-map (kbd "C-c h") 'hs-hide-block)
(define-key global-map (kbd "C-c s") 'hs-show-block)
(define-key global-map (kbd "C-c H") 'hs-hide-all)
(define-key global-map (kbd "C-c S") 'hs-show-all)
;; [Alt+?]でヘルプ
(global-set-key (kbd "M-?") 'help-for-help)
;; F6で全体を再インデント
(defun all-indent()
  (interactive)
  (mark-whole-buffer)
  (indent-region (region-beginning)(region-end)))
(global-set-key [f6] 'all-indent)
;; [Shift+矢印]で範囲選択
(if (fboundp 'pc-selection-mode)
    (pc-selection-mode))
;; [CTRL+z]でundo
(global-set-key (kbd "C-z") 'undo)
;; [Alt+g *]で*のギリシャ文字
(global-set-key (kbd "M-g a") "α")
(global-set-key (kbd "M-g b") "β")
(global-set-key (kbd "M-g g") "γ")
(global-set-key (kbd "M-g d") "δ")
(global-set-key (kbd "M-g e") "ε")
(global-set-key (kbd "M-g z") "ζ")
(global-set-key (kbd "M-g h") "η")
(global-set-key (kbd "M-g q") "θ")
(global-set-key (kbd "M-g i") "ι")
(global-set-key (kbd "M-g k") "κ")
(global-set-key (kbd "M-g l") "λ")
(global-set-key (kbd "M-g m") "μ")
(global-set-key (kbd "M-g n") "ν")
(global-set-key (kbd "M-g x") "ξ")
(global-set-key (kbd "M-g o") "ο")
(global-set-key (kbd "M-g p") "π")
(global-set-key (kbd "M-g r") "ρ")
(global-set-key (kbd "M-g s") "σ")
(global-set-key (kbd "M-g t") "τ")
(global-set-key (kbd "M-g u") "υ")
(global-set-key (kbd "M-g f") "ϕ")
(global-set-key (kbd "M-g j") "φ")
(global-set-key (kbd "M-g c") "χ")
(global-set-key (kbd "M-g y") "ψ")
(global-set-key (kbd "M-g w") "ω")
(global-set-key (kbd "M-g A") "Α")
(global-set-key (kbd "M-g B") "Β")
(global-set-key (kbd "M-g G") "Γ")
(global-set-key (kbd "M-g D") "Δ")
(global-set-key (kbd "M-g E") "Ε")
(global-set-key (kbd "M-g Z") "Ζ")
(global-set-key (kbd "M-g H") "Η")
(global-set-key (kbd "M-g Q") "Θ")
(global-set-key (kbd "M-g I") "Ι")
(global-set-key (kbd "M-g K") "Κ")
(global-set-key (kbd "M-g L") "Λ")
(global-set-key (kbd "M-g M") "Μ")
(global-set-key (kbd "M-g N") "Ν")
(global-set-key (kbd "M-g X") "Ξ")
(global-set-key (kbd "M-g O") "Ο")
(global-set-key (kbd "M-g P") "Π")
(global-set-key (kbd "M-g R") "Ρ")
(global-set-key (kbd "M-g S") "Σ")
(global-set-key (kbd "M-g T") "Τ")
(global-set-key (kbd "M-g U") "Υ")
(global-set-key (kbd "M-g F") "Φ")
(global-set-key (kbd "M-g J") "Φ")
(global-set-key (kbd "M-g C") "Χ")
(global-set-key (kbd "M-g Y") "Ψ")
(global-set-key (kbd "M-g W") "Ω")


;;================================================
;; Mode settings

;; header fileもc++ modeで
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))

;; gnuplot-mode
(require 'gnuplot)
(autoload 'gnuplot-mode "gnuplot" "Gnuplot major mode" t)
(autoload 'gnuplot-make-buffer "gnuplot" "open a buffer in gnuplot-mode" t)
(setq auto-mode-alist (append '(("\\.gp$" . gnuplot-mode)) auto-mode-alist))


;;================================================
;; Coding general settings

;; indentの設定
(require 'highlight-indent-guides)
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
(setq highlight-indent-guides-method 'character)
(setq highlight-indent-guides-auto-enabled t)
(setq highlight-indent-guides-responsive 'nil)
(setq highlight-indent-guides-auto-character-face-perc 1000) ;; 色の強度を変更
(setq highlight-indent-guides-auto-top-character-face-perc 1000)
;; 改行で自動インデント
(global-set-key "\C-m" 'newline-and-indent)
;; tabサイズ
(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)

;; smartparens
(require 'smartparens)
(with-eval-after-load 'smartparens
  (require 'smartparens-config)
  (defun indent-between-pair (&rest _ignored)
	(newline)
	(indent-according-to-mode)
	(forward-line -1)
	(indent-according-to-mode))
  (sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
  (sp-local-pair 'prog-mode "[" nil :post-handlers '((indent-between-pair "RET")))
  (sp-local-pair 'prog-mode "(" nil :post-handlers '((indent-between-pair "RET"))))
(smartparens-global-mode t)

;; 対応する括弧を光らせる
(show-paren-mode t)
(setq show-paren-delay 0)
;; ウィンドウ内に収まらないときだけ括弧内も光らせる
(setq show-paren-style 'mixed)

;; rainbow-delimiters
(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
;; 括弧の色を強調する設定
(require 'cl-lib)
(require 'color)
(defun rainbow-delimiters-using-stronger-colors ()
  (interactive)
  (cl-loop
   for index from 1 to rainbow-delimiters-max-face-count
   do
   (let ((face (intern (format "rainbow-delimiters-depth-%d-face" index))))
     (cl-callf color-saturate-name (face-foreground face) 30))))
(add-hook 'emacs-startup-hook 'rainbow-delimiters-using-stronger-colors)

;; 行末の空白を強調表示
(setq-default show-trailing-whitespace t)
;; 全角スペースなどを可視化
(require 'whitespace)
(setq whitespace-style '(face tabs spaces trailing space-mark tab-mark))
(setq whitespace-space-regexp "\\(\u3000+\\)")
(setq whitespace-display-mappings
      '((space-mark ?\u3000 [?\u25a1])
        (tab-mark ?\t [?\u00BB ?\t] [?\\ ?\t])))
(global-whitespace-mode 1)

;; 保存時に空白削除
(add-hook 'before-save-hook 'whitespace-cleanup)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;; 保存時に最終行に空行追加
(setq require-final-newline t)


;;================================================
;; Coding utility

;; インテリセンス
;;(require 'auto-complete)
;;(require 'auto-complete-config)
;;(global-auto-complete-mode t)

;; インテリセンス
(require 'company)
(global-company-mode t)

;; cのheaderをauto complete
(require 'auto-complete-c-headers)
(add-hook 'c++-mode-hook '(setq ac-sources (append ac-sources '(ac-source-c-headers))))
(add-hook 'c-mode-hook '(setq ac-sources (append ac-sources '(ac-source-c-headers))))

;; 構文チェッカ
(require 'flycheck)
(setq flycheck-check-syntax-automatically '(save idle-change new-line mode-enabled))
(setq flycheck-idle-change-delay 0.2)
(global-flycheck-mode)
(with-eval-after-load 'flycheck
  (add-hook 'flycheck-mode-hook #'flycheck-inline-mode))

;; スニペット
(require 'yasnippet)
(yas-global-mode 1)


;;================================================
;; Backup settings

;; バックアップファイルを ~/.emacs.d/backupにつくる
(setq backup-directory-alist
      (cons (cons ".*" (expand-file-name "~/.emacs.d/backup"))
            backup-directory-alist))
;; オートセーブファイルを ~/.emacs.d/backupにつくる
(setq auto-save-file-name-transforms
      `((".*", (expand-file-name "~/.emacs.d/backup/") t)))
;;オートセーブファイル作成までの秒間隔
(setq auto-save-timeout 60)


;;=================================================
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(hl-line ((t (:background "SteelBlue4")))))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" default))
 '(package-selected-packages
   '(diminish neotree all-the-icons flycheck-inline which-key-posframe company whitespace-cleanup-mode yasnippet-snippets yasnippet flycheck-pos-tip auto-complete-c-headers flycheck topsy doom-modeline package-utils hiwin bshell cl-libify rainbow-delimiters smartparens auto-complete)))
