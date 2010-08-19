;; .emacs

;; turn on font-lock mode
(global-font-lock-mode t)

(setq load-path (cons "%%EMACSDIR%%" load-path))

;; SML
(autoload 'sml-mode "sml-mode-color" () t)
(setq auto-mode-alist (cons '("\\.sml$" . sml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.sig$" . sml-mode) auto-mode-alist))
(add-hook 'sml-shell-hook 
  #'(lambda ()  
      (send-string sml-process-name
        "use \"%%EMACSDIR%%/print.sml\";\n")))

