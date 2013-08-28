;; .emacs

(setq inhibit-startup-message t)          ; dont show the GNU splash screen
(transient-mark-mode t)                   ; show selection from mark
(setq visible-bell 1)                     ; turn off bip warnings
(show-paren-mode t)                       ; turn on highlight paren mode
(fset 'yes-or-no-p 'y-or-n-p)             ; use y and n for questions
(global-font-lock-mode t)                 ; enable syntax highlighting
(iswitchb-mode 1)                         ; better buffer switching
(column-number-mode 1)                    ; show column numbers
(setq-default show-trailing-whitespace t) ; show trailing whitespace
(setq-default indent-tabs-mode nil)       ; indent with spaces, not tabs

;; Make Emacs more Windows-y: http://www.emacswiki.org/emacs/CuaMode
(cua-mode t)
(setq cua-auto-tabify-rectangles nil) ;; Don't tabify after rectangle commands
(transient-mark-mode 1) ;; No region when it is not highlighted
(setq cua-keep-region-after-copy t) ;; Standard Windows behaviour

;; SML
(setq sml-mode-dir "~/.emacs.d/sml-mode/")
(setq sml-program-name "mosml")
(setq sml-default-arg "-P full")
(setq sml-config-file (concat sml-mode-dir "/print.sml"))

(add-to-list 'load-path sml-mode-dir)
(autoload 'sml-mode "sml-mode" () t)
(setq auto-mode-alist (cons '("\\.sml$" . sml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.sig$" . sml-mode) auto-mode-alist))

;; Highlight column 80
(add-to-list 'load-path "~/.emacs.d/column-marker/")
(require 'column-marker)
(defface column-marker-4 '((t (:background "red")))
  "Bad, mean, red background color"
  :group 'faces)
(defvar column-marker-4-face 'column-marker-4)
(column-marker-create column-marker-4 column-marker-4-face)
(add-hook 'sml-mode-hook (lambda () (interactive) (column-marker-4 81)))
