;; sml-mode-color.el
;; dOvs customization, Olivier Danvy <danvy@brics.dk>, August 2002

(require 'cl)

;; sml-mode.el. Major mode for editing (Standard) ML.
;; Copyright (C) 1989, Lars Bo Nielsen.
;; Copyright (C) 1989, Free Software Foundation, Inc.
;; This file is part of GNU Emacs.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY.  No author or distributor
;; accepts responsibility to anyone for the consequences of using it
;; or for whether it serves any particular purpose or works at all,
;; unless he says so in writing.  Refer to the GNU Emacs General Public
;; License for full details.

;; Everyone is granted permission to copy, modify and redistribute
;; GNU Emacs, but only under the conditions described in the
;; GNU Emacs General Public License.   A copy of this license is
;; supposed to have been given to you along with GNU Emacs so you
;; can know your rights and responsibilities.  It should be in a
;; file named COPYING.  Among other things, the copyright notice
;; and this notice must be preserved on all copies.

;; AUTHOR   Lars Bo Nielsen
;;      Aalborg University
;;      Computer Science Dept.
;;      9000 Aalborg
;;      Denmark
;;
;; EMAIL    lbn@iesd.auc.dk
;;      or: ...!mcvax!diku!iesd!lbn
;;      or: mcvax!diku!iesd!lbn@uunet.uu.net
;;
;; Please let me know if you come up with any ideas, bugs, or fixes.
;; ----------------------------------------------------------------

;; Last Modified On: Fri Jul  6 13:23:39 1990
;; 
;; HISTORY 
;; 1-May-1990  (Last Mod: Tue May  1 11:00:45 1990)  Lars Bo Nielsen
;;    The error messages (from NJ-SML) has changed, so the function
;;    sml-next-error has changed as well.
;;    Added sml-shell-working-dir, so file-names have their leading
;;    path stripped off if they are in the same directory as sml is
;;    running. This might cause problems if the directory of the
;;    inferior process changes directory, so this path-stripping is
;;    only done if sml-strip-path is t.
;;    The format of sml-tmp-files-list has changed slightly.
;;    Version 3.0.
;; 4-Apr-1990  (Last Mod: Mon Apr  2 19:04:27 1990)  Lars Bo Nielsen
;;    Added (case-fold-search nil) in functions that got currupted if
;;    this was set to non-nil.
;;    Version 2.8.
;; 23-Jan-1990  (Last Mod: Sun Jan 21 15:44:36 1990)  Lars Bo Nielsen
;;    Changed sml-get-paren-indent to use throw/catch instead of
;;    loop-variable.
;; 13-Jan-1990  (Last Mod: Sat Jan 13 16:48:41 1990)  Lars Bo Nielsen
;;    Added this history. Version is now 2.7
;;    Added indentation-check for continued strings (The \ ..\n.. \)

(provide 'sml-mode)

(defconst sml-mode-version-string
  "sml-mode, dOvs version (August 2002)")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; CONSTANTS CONTROLLING THE MODE.
;;;
;;; These are constants you probably don't want to change :-)
;;; 

(defvar sml-indent-level 4
  "*Indentation of blocks in sml.")

(defvar sml-pipe-indent -2
  "*Extra (negative) indentation for lines beginning with |.")

(defvar sml-nested-if-indent t
  "*If set to t, nested if-then-else expression will have the same
indentation as:
                 if exp1 then exp2
                 else if exp3 then exp4
                 else if exp5 then exp6
                      else exp7")

(defvar sml-type-of-indent t
  "*How to indent `let' `struct' etc.
 If t:  fun foo bar = let              If nil:  fun foo bar = let
                          val p = 4                 val p = 4
                      in                        in
                          bar + p                   bar + p
                      end                       end

Will not have any effect if the starting keyword is first on the line.")

(defvar sml-electric-semi-mode nil
  "*If t, a `\;' will insert itself, reindent the line, and perform a newline.
If nil, just insert a `\;'. (To insert while t, do: C-q \;).")

(defvar sml-paren-lookback 300
  "*Determines how far back (in chars) the indentation algorithm
should look for open parenthesis. High value means slow indentation
algorithm. A value of 200 (being the equivalent of 4-6 lines) should
suffice most uses. (A value of nil, means do not look at all)")

;; CHANGE HERE
(defvar sml-prog-name "%%EMACSDIR%%/mosml.bat"
  "Moscow ML Version 2.01")

(defvar sml-prog-name-ask-p nil
  "*If t, you will be asked which program to run when the inferior
shell starts up. Useful if you have exported images of sml.")

(defvar sml-use-left-delim "\""
  "*The left delimiter for the filename when using \"use\".
 To be set to `\"[\\\"\"' for Edinburgh SML, and `\"\\\"\"' for New Jersey SML.
 Corresponds to `sml-use-right-delim'.")

(defvar sml-use-right-delim "\""
  "*The right delimiter for the filename when using \"use\".
 To be set to `\"\\\"]\"' for Edinburgh SML, and `\"\\\"\"' for New Jersey SML.
 Corresponds to `sml-use-left-delim'.")

(defvar sml-shell-prompt-pattern "^[^\-=]*[\-=] *"
  "*The prompt pattern for the inferior shell running sml.")

;; CHANGE HERE
(defvar sml-tmp-template "%%SMLTEMPDIR%%/sml.tmp."
  "*Template for the temporary files, created when a region is send to
the inferior process running sml (by sml-simulate-send-region).")

(defvar sml-strip-path nil
  "*If t, then when sending a `use file' or `import file' to the
inferior sml process, the leading path of the filename is stripped of,
iff the file is in the same directory as the directory sml was started
in.
If you change the working directory of the inferior sml, after it has
started up you are in trouble. To get out of this trouble, set this
variable to nil.")

;;;
;;; END OF CONSTANTS CONTROLLING THE MODE.
;;;
;;; If you change anything either above below, you are on your own.
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defvar sml-mode-map nil "The mode map used in sml-mode.")
(if sml-mode-map
    ()
  (setq sml-mode-map (make-sparse-keymap))
  (define-key sml-mode-map "\C-c'" 'sml-next-error)
  (define-key sml-mode-map "\C-c\C-v" 'sml-mode-version)
  (define-key sml-mode-map "\C-c\C-u" 'sml-save-buffer-use-file)
  (define-key sml-mode-map "\C-c\C-s" 'sml-pop-to-shell)
  (define-key sml-mode-map "\C-c\C-r" 'sml-send-region)
  (define-key sml-mode-map "\C-c\C-m" 'sml-region)
  (define-key sml-mode-map "\C-c\C-k" 'sml-skip-errors)
  (define-key sml-mode-map "\C-c\C-f" 'sml-run-on-file)
  (define-key sml-mode-map "\C-c\C-c" 'sml-send-function)
  (define-key sml-mode-map "\C-c\C-b" 'sml-send-buffer)
  ;(define-key sml-mode-map "\C-ci" 'sml-import-file)
  (define-key sml-mode-map "\e|" 'sml-electric-pipe)
  (define-key sml-mode-map "\e\t" 'sml-back-to-outer-indent)
  (define-key sml-mode-map "\C-j" 'reindent-then-newline-and-indent)
  (define-key sml-mode-map "\177" 'backward-delete-char-untabify)
  (define-key sml-mode-map "\;" 'sml-electric-semi)
  (define-key sml-mode-map "\C-c\t" 'sml-indent-region)
  (define-key sml-mode-map "\t" 'sml-indent-line))

(defvar sml-mode-syntax-table nil "The syntax table used in sml-mode.")
(if sml-mode-syntax-table
    ()
  (setq sml-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?\( "()1" sml-mode-syntax-table)
  (modify-syntax-entry ?\) ")(4" sml-mode-syntax-table)
  (modify-syntax-entry ?\\ "\\" sml-mode-syntax-table)
  (modify-syntax-entry ?* ". 23" sml-mode-syntax-table)
  ;;
  ;; Special characters in sml-mode to be treated as normal
  ;; characters: (They can be part of identifier names)
  ;;
  (modify-syntax-entry ?_ "w" sml-mode-syntax-table)
  (modify-syntax-entry ?\' "w" sml-mode-syntax-table))

;; font-lock setup
(defun flatten (ls &optional acc)
  (if (null ls) acc
    (let ((rest (flatten (cdr ls) acc))
      (head (car ls)))
      (if (listp head)
      (flatten head rest)
    (cons head rest)))))

(defun sml-syms-re (&rest syms)
  (concat "\\<" (regexp-opt (flatten syms) t) "\\>"))

(defconst sml-keywords-regexp
  (sml-syms-re "abstraction" "abstype" "and" "andalso" "as" "before" "case"
           "datatype" "else" "end" "eqtype" "exception" "do" "fn"
           "fun" "functor" "handle" "if" "in" "include" "infix"
           "infixr" "let" "local" "nonfix" "of" "op" "open" "orelse"
           "overload" "raise" "rec" "sharing" "sig" "signature"
           "struct" "structure" "then" "type" "val" "where" "while"
           "with" "withtype" "o")
  "A regexp that matches any and all keywords of SML.")

(defconst sml-font-lock-keywords
  `(;;(sml-font-comments-and-strings)
    ("\\<\\(fun\\|and\\)\\s-+\\('\\sw+\\s-+\\)*\\(\\sw+\\)"
     (1 font-lock-keyword-face)
     (3 font-lock-function-name-face))
    ("\\<\\(\\(data\\|abs\\|with\\|eq\\)?type\\)\\s-+\\('\\sw+\\s-+\\)*\\(\\sw+\\)"
     (1 font-lock-keyword-face)
     (4 font-lock-type-def-face))
    ("\\<\\(val\\)\\s-+\\(\\sw+\\>\\s-*\\)?\\(\\sw+\\)\\s-*[=:]"
     (1 font-lock-keyword-face)
     ;;(6 font-lock-variable-def-face nil t)
     (3 font-lock-variable-name-face))
    ("\\<\\(structure\\|functor\\|abstraction\\)\\s-+\\(\\sw+\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-module-def-face))
    ("\\<\\(signature\\)\\s-+\\(\\sw+\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-interface-def-face))
    
    (,sml-keywords-regexp . font-lock-keyword-face))
  "Regexps matching standard SML keywords.")

(defface font-lock-type-def-face
  '((t (:bold t)))
  "Font Lock mode face used to highlight type definitions."
  :group 'font-lock-highlighting-faces)
(defvar font-lock-type-def-face 'font-lock-type-def-face
  "Face name to use for type definitions.")

(defface font-lock-module-def-face
  '((t (:bold t)))
  "Font Lock mode face used to highlight module definitions."
  :group 'font-lock-highlighting-faces)
(defvar font-lock-module-def-face 'font-lock-module-def-face
  "Face name to use for module definitions.")

(defface font-lock-interface-def-face
  '((t (:bold t)))
  "Font Lock mode face used to highlight interface definitions."
  :group 'font-lock-highlighting-faces)
(defvar font-lock-interface-def-face 'font-lock-interface-def-face
  "Face name to use for interface definitions.")

;;;
;;; Code to handle nested comments and unusual string escape sequences
;;;
(defun custom-create-syntax (css args)
  (let ((st (make-syntax-table (cadr (memq :copy args)))))
    (dolist (cs css)
      (let ((char (car cs))
        (syntax (cdr cs)))
    (if (sequencep char)
        (mapcar* (lambda (c) (modify-syntax-entry c syntax st)) char)
      (modify-syntax-entry char syntax st))))
    st))

(defmacro defsyntax (st css doc &rest args)
  `(defconst ,st (custom-create-syntax ,css ,(cons 'list args)) ,doc))

(defsyntax sml-syntax-prop-table
  '((?\\ . ".") (?* . "."))
  "Syntax table for text-properties")

;; For Emacsen that have no built-in support for nested comments
(defun sml-get-depth-st ()
  (save-excursion
    (let* ((disp (if (eq (char-before) ?\)) (progn (backward-char) -1) nil))
       (foo (backward-char))
       (disp (if (eq (char-before) ?\() (progn (backward-char) 0) disp))
       (pt (point)))
      (when disp
    (let* ((depth
        (save-match-data
          (if (re-search-backward "\\*)\\|(\\*" nil t)
              (+ (or (get-char-property (point) 'comment-depth) 0)
             (case (char-after) (?\( 1) (?* 0))
             disp)
            0)))
           (depth (if (> depth 0) depth)))
      (put-text-property pt (1+ pt) 'comment-depth depth)
      (when depth sml-syntax-prop-table))))))

(defvar sml-builtin-nested-comments-flag
  (ignore-errors
    (not (equal (let ((st (make-syntax-table)))
          (modify-syntax-entry ?\* ". 23n" st) st)
        (let ((st (make-syntax-table)))
          (modify-syntax-entry ?\* ". 23" st) st))))
  "Non-nil means this Emacs understands the `n' in syntax entries.")

(defconst sml-font-lock-syntactic-keywords
  `(("^\\s-*\\(\\\\\\)" (1 ',sml-syntax-prop-table))
    ,@(unless sml-builtin-nested-comments-flag
    '(("(?\\(\\*\\))?" (1 (sml-get-depth-st)))))))

(defconst sml-font-lock-defaults
  '(sml-font-lock-keywords nil nil ((?_ . "w") (?' . "w")) nil
    (font-lock-syntactic-keywords . sml-font-lock-syntactic-keywords)))

(defun sml-mode ()
  "Major mode for editing SML code.
Tab indents for SML code.
Comments are delimited with (* ... *).
Paragraphs are separated by blank lines only.
Delete converts tabs to spaces as it moves back.

Default key bindings:
=====================

TAB      -  Indent current line.
C-c TAB  -  Indent region.
LFD      -  Reindent line, newline and indent.
;        -  Insert ';', reindent line, newline and indent.
ESC TAB  -  Back line out one indentation.
ESC |    -  Insert a \"|\". Insert function name, \"=>\" etc.
C-c RET  -  Insert a common used structure.
C-c '    -  Find the next error.
C-c C-k  -  Skip rest of errors.
C-c C-s  -  Pop to the sml window.
C-c C-u  -  Save the buffer, and send a \"use file\".
C-c C-r  -  Send region (point and mark) to sml.
C-c C-f  -  Send a \"use file\" to sml.
C-c C-c  -  Send function/region to sml.
C-c C-b  -  Send whole buffer to sml.
C-c C-v  -  Get the version of sml-mode.


Variables controlling the indentation
=====================================

sml-indent-level (default 4)
    The indentation of a block of code.

sml-pipe-indent (default -2)
    Extra indentation of a line starting with \"|\".

sml-case-indent (default nil)
    Determine the way to indent case-of expression.
    If t:   case expr              If nil:   case expr of
              of exp1 => ...                     exp1 => ...
               | exp2 => ...                   | exp2 => ...

    The first seems to be the standard in NJ-SML. The second is the default.

sml-nested-if-indent (default nil)
    If set to t, nested if-then-else expression will have the same
    indentation as:
                     if exp1 then exp2
                     else if exp3 then exp4
                     else if exp5 then exp6
                          else exp7

sml-type-of-indent (default t)
    How to indent `let' `struct' etc.

    If t:  fun foo bar = let                If nil:  fun foo bar = let
                             val p = 4                   val p = 4
                         in                          in
                             bar + p                     bar + p
                         end                         end

    Will not have any effect if the starting keyword is first on the line.

sml-electric-semi-mode (default t)
    If t, a `\;' will reindent line, and perform a newline.

sml-paren-lookback (default 200)
    Determines how far back (in chars) the indentation algorithm
    should look for open parenthesis. High value means slow indentation
    algorithm. A value of 200 (being the equivalent of 4-6 lines) should
    suffice most uses. (A value of nil, means do not look at all)

Mode map
========
\\{sml-mode-map}
See sml-shell for further information.

Runs sml-mode-hook if non nil."
  (interactive)
  (kill-all-local-variables)
  (use-local-map sml-mode-map)
  (setq major-mode 'sml-mode)
  (setq mode-name "Sml")
  (define-abbrev-table 'sml-mode-abbrev-table ())
  (setq local-abbrev-table sml-mode-abbrev-table)
  (set-syntax-table sml-mode-syntax-table)
  ;; Color support via font-lock-mode
  (set (make-local-variable 'font-lock-defaults) sml-font-lock-defaults)
  ;; A paragraph is separated by blank lines or ^L only.
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^[\t ]*$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'sml-indent-line)
  (make-local-variable 'require-final-newline) ; Always put a new-line
  (setq require-final-newline t)           ; in the end of file
  (make-local-variable 'comment-start)
  (setq comment-start "(* ")
  (make-local-variable 'comment-end)
  (setq comment-end " *)")
  (make-local-variable 'comment-column)
  ;; Start of comment in this column. Changed from original 39.
  ;; I still don't know where I got the 39 from !! (891117 lbn) 
  (setq comment-column 40)      
  (make-local-variable 'comment-start-skip)
  ;; This matches a start of comment (I sure hope!)
  (setq comment-start-skip "(\\*+[ \t]?")
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'sml-comment-indent)
  ;;
  ;; Adding these will fool the matching of parens.
  ;; I really don't know why.
  ;; It would be nice to have comments treated as white-space
  ;; 
  ;; (make-local-variable 'parse-sexp-ignore-comments)
  ;; (setq parse-sexp-ignore-comments t)
  ;; 
  (run-hooks 'sml-mode-hook))       ; Run the hook

(defconst sml-pipe-matchers-reg
  "\\bcase\\b\\|\\bfn\\b\\|\\bfun\\b\\|\\bhandle\\b\
\\|\\bdatatype\\b\\|\\band\\b"
  "The keywords a `|' can follow.")

(defun sml-electric-pipe ()
  "Insert a \"|\". Depending on the context insert the name of
function, a \"=>\" etc."
  (interactive)
  (let ((case-fold-search nil)      ; Case sensitive
    (here (point))
    (match (save-excursion
         (sml-find-matching-starter sml-pipe-matchers-reg)
         (point)))
    (tmp "  => ")
    (case-or-handle-exp t))
    (if (/= (save-excursion (beginning-of-line) (point))
        (save-excursion (skip-chars-backward "\t ") (point)))
    (insert "\n"))
    (insert "|")
    (save-excursion
      (goto-char match)
      (cond
       ;; It was a function, insert the function name
       ((looking-at "fun\\b")
    (setq tmp (concat " " (buffer-substring
                   (progn (forward-char 3)
                      (skip-chars-forward "\t\n ") (point))
                   (progn (forward-word 1) (point))) " "))
    (setq case-or-handle-exp nil))
       ;; It was a datatype, insert nothing
       ((looking-at "datatype\\b")
    (setq tmp " ") (setq case-or-handle-exp nil))
       ;; If it is an and, then we have to see what is was
       ((looking-at "and\\b")
    (let (isfun)
      (save-excursion
        (condition-case ()
        (progn
          (re-search-backward "datatype\\b\\|fun\\b")
          (setq isfun (looking-at "fun\\b")))
          (error (setq isfun nil))))
      (if isfun
          (progn
        (setq tmp
              (concat " " (buffer-substring
                   (progn (forward-char 3)
                      (skip-chars-forward "\t\n ") (point))
                   (progn (forward-word 1) (point))) " "))
        (setq case-or-handle-exp nil))
        (setq tmp " ") (setq case-or-handle-exp nil))))))
    (insert tmp)
    (sml-indent-line)
    (beginning-of-line)
    (skip-chars-forward "\t ")
    (forward-char (1+ (length tmp)))
    (if case-or-handle-exp
    (forward-char -4))))

(defun sml-electric-semi ()
  "Inserts a \;.
If sml-electric-semi-mode is t, indent the current line, and newline."
  (interactive)
  (insert "\;")
  (if sml-electric-semi-mode
      (reindent-then-newline-and-indent)))

(defun sml-mode-version ()
  "Message the version of sml-mode."
  (interactive)
  (message sml-mode-version-string))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; SHORT CUTS (sml-region)
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst sml-region-alist
  '(("let") ("local") ("signature") ("structure") ("datatype")
    ("case") ("functor") ("abstraction"))
  "The list of regions to auto-insert.")

(defun sml-region ()
  "Interactive short-cut. Insert a common used structure in sml."
  (interactive)
  (let ((newline nil)           ; Did we insert a newline
    (name (completing-read "Region to insert: (default let) "
                   sml-region-alist nil t nil)))
    ;; default is "let"
    (if (string= name "") (setq name "let"))
    ;; Insert a newline if point is not at empty line
    (sml-indent-line)           ; Indent the current line
    (if (save-excursion (beginning-of-line) (skip-chars-forward "\t ") (eolp))
    ()
      (setq newline t)
      (insert "\n"))
    (condition-case ()
    (cond
     ((string= name "let") (sml-let))
     ((string= name "local") (sml-local))
     ((string= name "structure") (sml-structure))
     ((string= name "signature") (sml-signature))
     ((string= name "abstraction") (sml-abstraction))
     ((string= name "functor") (sml-functor))
     ((string= name "case") (sml-case))
     ((string= name "datatype") (sml-datatype)))
      (quit (if newline 
        (progn
          (delete-char -1)
          (beep)))))))

(defun sml-let () 
  "Insert a `let in end'."
  (interactive) (sml-let-local "let"))

(defun sml-local ()
  "Insert a `local in end'."
  (interactive) (sml-let-local "local"))

(defun sml-signature ()
  "Insert a `signature ??? = sig end', prompting for name."
  (interactive) (sml-structure-signature "signature"))

(defun sml-structure ()
  "Insert a `structure ??? = struct end', prompting for name."
  (interactive) (sml-structure-signature "structure"))

(defun sml-case ()
  "Insert a case, prompting for case-expression."
  (interactive)
  (let (indent (expr (read-string "expression to dispatch on: ")))
    (insert (concat "case " expr))
    (sml-indent-line)
    (setq indent (current-indentation))
    (end-of-line)
    (insert "\n")
    (indent-to indent)
    (insert "  of ")
    (save-excursion
      (insert "\n")
      (indent-to indent)
      (insert "     => \n")
      (indent-to indent)
      (insert "   | \n")
      (indent-to indent)
      (insert "     => "))))

(defun sml-let-local (starter)
  (let (indent)
    (insert starter)
    (sml-indent-line)
    (setq indent (current-indentation))
    (insert " \n")
    (indent-to indent)
    (insert "in \n")
    (indent-to indent)
    (insert "end")
    (previous-line 2)
    (end-of-line)))

(defun sml-structure-signature (which)
  (let (indent
    (name (read-string (concat "Name of " which ": "))))
    (insert (concat which " " name))
    (sml-indent-line)
    (setq indent (current-indentation))
    (end-of-line)
    (insert "\n")
    (indent-to indent)
    (insert (if (string= which "signature") "= sig\n" "= struct\n"))
    (indent-to (+ indent 4))
    (insert "\n")
    (indent-to (+ indent 2))
    (insert "end")
    (previous-line 1)
    (end-of-line)))

(defun sml-functor ()
  "Insert a `functor ??? () : ??? = struct end', prompting for name and type."
  (let (indent
    (name (read-string "Name of functor: "))
    (signame (read-string "Signature type of functor: ")))
    (insert (concat "functor " name " ()"))
    (sml-indent-line)
    (setq indent (current-indentation))
    (end-of-line)
    (insert "\n")
    (indent-to indent)
    (insert ": " signame)
    (end-of-line)
    (insert "\n")
    (indent-to indent)
    (insert "= struct\n")
    (indent-to (+ indent 4))
    (insert "\n")
    (indent-to (+ indent 2))
    (insert "end")
    (previous-line 1)
    (end-of-line)))

(defun sml-abstraction ()
  "Insert a `abstraction ??? : ??? = struct end', prompting for name and type."
  (let (indent
    (name (read-string "Name of abstraction: "))
    (signame (read-string "Signature type of abstraction: ")))
    (insert (concat "abstraction " name))
    (sml-indent-line)
    (setq indent (current-indentation))
    (end-of-line)
    (insert "\n")
    (indent-to indent)
    (insert ": " signame)
    (end-of-line)
    (insert "\n")
    (indent-to indent)
    (insert "= struct\n")
    (indent-to (+ indent 4))
    (insert "\n")
    (indent-to (+ indent 2))
    (insert "end")
    (previous-line 1)
    (end-of-line)))

(defun sml-datatype ()
  "Insert a `datatype ??? =', prompting for name."
  (let (indent 
    (type (read-string (concat "Type of datatype (default none): ")))
    (name (read-string (concat "Name of datatype: "))))
    (insert (concat "datatype "
            (if (string= type "") "" (concat type " "))
            name " = "))
    (sml-indent-line)
    (setq indent (current-indentation))
    (end-of-line)
    (save-excursion
      (insert "\n| ")
      (sml-indent-line))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; PARSING ERROR MESSAGES (NOTE: works only with SML of New Jersey)
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar sml-last-error 1
  "Last position of error. Initially 1.")

;; The reg-expression used when looking for errors. If you don't want
;; warnings to show up, change this to:
;; "^\\(.+\\):\\([0-9]+\\)\\.\\([0-9]+\\).+Error:"
(defvar sml-error-regexp
  "^\\(.+\\):\\([0-9]+\\)\\.\\([0-9]+\\).+\\(Error\\|Warning\\):"
  "Regexpression for matching error. If you change this beware of the
first three parenthesized expressions. sml-next-error uses these to
get the filename, and the line and character offset.")

(defun sml-next-error (arg)
  "Find the next error by passing the *SML* buffer.
A non-nil argument (prefix arg, if interactive) means reparse the
error messages and start at the first error.

NOTE: This function only knows about the syntax of errors generated by
      SML of New Jersey, and will probably only work with this."
  (interactive "P")
  (if arg
      (setq sml-last-error 1))
  (let ((case-fold-search nil) (found t) (tmp-file nil)
    found-line found-char found-file error-line tmp)
    (save-excursion
      (condition-case ()
      (progn
        (set-buffer (concat "*" sml-process-name "*" ))
        (goto-char sml-last-error)  ; Goto last found error
        (re-search-forward sml-error-regexp) ; Search for error
        (setq
         found-file (buffer-substring (match-beginning 1) (match-end 1))
         found-line (string-to-int
             (buffer-substring (match-beginning 2) (match-end 2)))
         found-char (1-
             (string-to-int (buffer-substring (match-beginning 3)
                              (match-end 3)))))
        (if (string-match "^/" found-file)
        ()
          (setq found-file (concat sml-shell-working-dir found-file)))
        (setq sml-last-error (point))
        (beginning-of-line)
        (setq error-line (point))
        (if (looking-at sml-tmp-template)
        (setq tmp-file t)))
    (error (setq found nil))))
    (if found
    (progn
      (set-window-start
       (display-buffer (concat "*" sml-process-name "*")) error-line)
      (if tmp-file
          (let ((loop t) (tmp-list sml-tmp-files-list))
        (while (and loop tmp-list)
          (setq tmp (car tmp-list))
          (if (string= (car tmp) found-file)
              (setq loop nil)
            (setq tmp-list (cdr tmp-list))))
        (if (null tmp)
            (error "Temporary file not associated with buffer.")
          (condition-case ()
              (progn
            (find-file (nth 1 tmp))
            (message "Error found in temporary file !!")
            (goto-line (1- (+ found-line (nth 2 tmp))))
            (forward-char found-char))
            (error (error "Sorry, buffer doesn't exist any more.")))))
        (if (file-exists-p found-file)
        (progn
          (find-file found-file)
          (goto-line found-line)
          (forward-char found-char))
          (error (concat "File not found: " found-file)))))
      ;; No error found
      (if (= sml-last-error 1)      ; Did we just start
      (message "No errors yet")
    (message "No more errors")) ; Or have we passed all errors
      (beep))))

(defun sml-skip-errors ()
  "Skip past the rest of the errors."
  (interactive)
  (save-excursion
    (set-buffer (concat "*" sml-process-name "*" ))
    (setq sml-last-error (point-max))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; INDENTATION
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun sml-indent-region (begin end)
  "Indent region of sml code."
  (interactive "r")
  (message "Indenting region...")
  (save-excursion
    (goto-char end) (setq end (point-marker)) (goto-char begin)
    (while (< (point) end)
      (skip-chars-forward "\t\n ")
      (sml-indent-line)
      (end-of-line))
    (move-marker end nil))
  (message "Indenting region... done"))

(defun sml-indent-line ()
  "Indent current line of sml code."
  (interactive)
  (let ((indent (sml-calculate-indentation)))
    (if (/= (current-indentation) indent)
    (save-excursion         ;; Added 890601 (point now stays)
      (let ((beg (progn (beginning-of-line) (point))))
        (skip-chars-forward "\t ")
        (delete-region beg (point))
        (indent-to indent))))
    ;; If point is before indentation, move point to indentation
    (if (< (current-column) (current-indentation))
    (skip-chars-forward "\t "))))

(defun sml-back-to-outer-indent ()
  "Unindents to the next outer level of indentation."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward "\t ")
    (let ((start-column (current-column))
      (indent (current-column)))
      (if (> start-column 0)
      (progn
        (save-excursion
          (while (>= indent start-column)
        (if (re-search-backward "^[^\n]" nil t)
            (setq indent (current-indentation))
          (setq indent 0))))
        (backward-delete-char-untabify (- start-column indent)))))))

(defconst sml-indent-starters-reg-dont
  "signature\\b|structure\\b\\functor\\b"
  "The non-indentation starters. The next line, after one starting with
one of these, will not be indented.")

(defconst sml-indent-starters-reg-2
  "case\\b"
  "Special indentation starters. The next line, after one starting with
one of these, will be indented by 2 characters.")

(defconst sml-indent-starters-reg-5
  "type\\b"
  "Special indentation starters. The next line, after one starting with
one of these, will be indented by 5 characters.")

(defconst sml-indent-starters-reg
  "abstraction\\b\\|and\\b\\|datatype\\b\
\\|else\\b\\|fun\\b\\|if\\b\\|sharing\\b\
\\|in\\b\\|infix\\b\\|infixr\\b\\|let\\b\\|local\\b\
\\|nonfix\\b\\|of\\b\\|open\\b\\|raise\\b\\|sig\\b\
\\|struct\\b\\|then\\b\\|\\btype\\b\\|val\\b\
\\|while\\b\\|with\\b\\|withtype\\b"
  "The indentation starters. The next line, after one starting with
one of these, will be indented.")

(defconst sml-starters-reg
  "\\babstraction\\b\\|\\bdatatype\\b\
\\|\\bexception\\b\\|\\bfun\\b\\|\\bfunctor\\b\\|\\blocal\\b\
\\|\\binfix\\b\\|\\binfixr\\b\\|\\bcase\\b\\|\\bsharing\\b\
\\|\\bnonfix\\b\\|\\bopen\\b\\|\\bsignature\\b\\|\\bstructure\\b\
\\|\\btype\\b\\|\\bval\\b\\|\\bwithtype\\b\\|\\bwith\\b"
  "The starters of new expressions.")

(defconst sml-end-starters-reg
  "\\blet\\b\\|\\blocal\\b\\|\\bsig\\b\\|\\bstruct\\b\\|\\bwith\\b"
  "Matching reg-expression for the \"end\" keyword.")

(defconst sml-starters-indent-after
  "let\\b\\|local\\b\\|struct\\b\\|in\\b\\|sig\\b\\|\\bcase\\b\\|with\\b"
  "Indent after these.")

(defun sml-calculate-indentation ()
  (save-excursion
    (let ((case-fold-search nil))
      (beginning-of-line)
      (if (bobp)            ; Beginning of buffer
      0             ; Indentation = 0
      (skip-chars-forward "\t ")
      (cond
        ((looking-at "(\\*")
         ;; Indentation for comments alone on a line, matches the
         ;; proper indentation of the next line. Search only for the
         ;; next "*)", not for the matching.
         (if (not (search-forward "*)" nil t))
         (error "Comment not ended."))
         (end-of-line)
         (skip-chars-forward "\n\t ")
         ;; If we are at eob, just indent 0
         (if (eobp) 0 (sml-calculate-indentation)))
        ((looking-at "\\\\")
         ;; Continued string ? (Added 890113 lbn)
         (save-excursion
           (cond
         ((save-excursion (previous-line 1)
                  (beginning-of-line)
                  (looking-at "[\t ]*\\\\"))
          (previous-line 1)
          (current-indentation))
         ((re-search-backward "[^\\\\]\"" nil t)
          (1+ (current-indentation)))
         (t
          0))))
        ((looking-at "=\\b(fn\\b.*\\b=>")
         (sml-get-indent))
        ((looking-at "|.*=>")
         ;; Are we looking at a case expression ?
         (sml-skip-block)
         (sml-re-search-backward "=>")
         ;; Dont get fooled by fn _ => in case statements (890726)
         ;; Changed the regexp a bit, so fn has to be first on line,
         ;; in order to let the loop continue (Used to be ".*\bfn....")
         ;; (900430).
         (let ((loop t))
           (while (and loop
               (save-excursion (beginning-of-line)
                       (looking-at "[^ \t]+\\bfn\\b.*=>")))
         (setq loop (sml-re-search-backward "=>"))))
         (beginning-of-line)
         (skip-chars-forward "\t ")
         (cond
           ((looking-at "|")
        (current-indentation))
           (;(and sml-case-indent (looking-at "of\\b"))
        (looking-at "of\\b")
        ;; (1+ (current-indentation))
        (+ (current-indentation) 25))
           ((looking-at "fn\\b")
        (+ (current-indentation) 25))
           ((looking-at "handle\\b")
        (+ (current-indentation) 5))
           (t
        (+ (current-indentation)
           ;; sml-pipe-indent
           20))))
        ((looking-at "=>")
         (sml-skip-block)
         (sml-skip-block)
         (cond
           ((looking-at "fn ")
        (+ (current-column) 3))
           ((looking-at "of ")
        (+ (current-column) 3))
           ((looking-at "| ")
        (+ (current-column) 2))
           (t
             (sml-re-search-backward "=>")
         (let ((loop t))
           (while (and loop
                   (save-excursion
                 (beginning-of-line)
                 (looking-at "[^ \t]+\\bcase\\b.*=>")))
             (setq loop (sml-re-search-backward "=>"))))
         (beginning-of-line)
         (skip-chars-forward "\t ")
         (cond
           ((looking-at "of\\b")
            ;; (1+ (current-indentation))
            (+ (current-indentation) 2))
           ((looking-at "fn\\b")
            (+ (current-indentation) 2))
           ((looking-at "handle\\b")
            (+ (current-indentation) 5))
           (t
            (+ (current-indentation)
               ;; sml-pipe-indent
               0))))))
        ((looking-at "and\\b")
         (if (sml-find-matching-starter sml-starters-reg)
         (current-column)
             0))
        ((looking-at "in\\b")
         ;; Match the beginning let/local
         (sml-find-match-indent "in" "\\bin\\b" "\\blocal\\b\\|\\blet\\b"))
        ((looking-at "end\\b")
         ;; Match the beginning
         (sml-find-match-indent "end" "\\bend\\b" sml-end-starters-reg))
        ((and sml-nested-if-indent (looking-at "else[\t ]*if\\b"))
         (sml-re-search-backward "\\bif\\b\\|\\belse\\b")
         (current-indentation))
        ((looking-at "else\\b")
         ;; Match the if
         (sml-find-match-indent "else" "\\belse\\b" "\\bif\\b" t))
        ((looking-at "then\\b")
         ;; Match the if + extra indentation
         (sml-find-match-indent "then" "\\bthen\\b" "\\bif\\b" t))
        (;(and sml-case-indent (looking-at "of\\b"))
         (looking-at "of\\b")
         (sml-re-search-backward "\\bcase\\b")
         (+ (current-column) 2)
         ;; (current-column)
         )
        ((looking-at sml-starters-reg)
         (let ((start (point)))
           (sml-backward-sexp)
           (if (and (looking-at sml-starters-indent-after)
            (/= start (point)))
           (+ (if sml-type-of-indent
              (current-column)
              (beginning-of-line)
              (skip-chars-forward "\t ")
              (if (looking-at "|")
                  (- (current-indentation) sml-pipe-indent)
                  (current-indentation)))
              ;; sml-indent-level
              2)
               (beginning-of-line)
           (skip-chars-forward "\t ")
           (if (and (looking-at sml-starters-indent-after)
                (/= start (point)))
               (+ (if sml-type-of-indent
                  (current-column)
                  (current-indentation))
              ;; sml-indent-level
              2)
               (goto-char start)
               (if (sml-find-matching-starter sml-starters-reg)
               (current-column)
               0)))))
        (t
         (let ((indent (sml-get-indent)))
           (cond
         ((looking-at "|")
          ;; Let's see if it is the follower of some kind of definition
          (if (sml-find-matching-starter
               "\\bcase\\b\\|\\bfun\\b\\|\\bfn\\b\\|\\band\\b\\|\\bhandle\\b\\|\\bdatatype\\b")
              (cond
                ((looking-at "case\\b")
             (+ (current-column) 3))
                ((looking-at "fun\\b")
             (- (current-column) sml-pipe-indent))
            ((looking-at "fn\\b")
             (+ (current-column) 1))
            ((looking-at "and\\b")
             (1+ (1+ (current-column))))
            ((looking-at "handle\\b")
             (+ (current-column) 5))
            ((looking-at "datatype\\b")
             indent))
              (+ indent sml-pipe-indent)))
         (sml-paren-lookback
          ;; Look for open parenthesis ?
          (max indent (sml-get-paren-indent)))
         (t
          indent)))))))))

(defun sml-get-indent ()
  (save-excursion
    (let ((case-fold-search nil)
      (a-bar-p (looking-at "|"))
      (an-equal-p (looking-at "="))
      (an-arrow-p (looking-at "->")))
      (beginning-of-line)
      (skip-chars-backward "\t\n; ")
      (if (looking-at ";") (sml-backward-sexp))
      (cond
        ((save-excursion (sml-backward-sexp) (looking-at "end\\b"))
     (- (current-indentation) sml-indent-level))
        ((save-excursion (sml-backward-sexp) (looking-at "datatype\\b.*="))
     (current-indentation))
    (t
     (while (/= (current-column) (current-indentation))
       (sml-backward-sexp))
     (cond
       ((looking-at "datatype\\b.*=")
        (re-search-forward "=")
        (forward-char -1)
        (current-column))
       ((and (looking-at "|") a-bar-p)
        (current-column))
       ((and (looking-at "|") an-equal-p)
        (+ (current-column) 2))
       ((and (looking-at "=") an-arrow-p)
        (forward-char 2)
        (current-column))
       (t
        (let ((indent (current-column)))
          (skip-chars-forward "\t (")
          (cond
            ((looking-at sml-indent-starters-reg-dont)
         ;; Started signature/structure/functor...
         (current-column))
        ((looking-at sml-indent-starters-reg-2)
         ;; Started case...
         (+ (current-column) 2))
        ((looking-at sml-indent-starters-reg-5)
         ;; Started type...
         (+ (current-column) 5))
        ((looking-at sml-indent-starters-reg)
         ;; Started val/fun...
         (+ (current-column) sml-indent-level))
        ((looking-at ".*=>")
         ;; Indent after "=>" pattern, but only if it's not an fn _ =>
         ;; (890726)
         (if (looking-at ".*\\bfn\\b.*=>")
             indent
             ;; (+ indent sml-indent-level)
             (+ indent 3)))
        ((looking-at "= let fun ")
         (+ indent 10))
        ((save-excursion
           (beginning-of-line)
           (skip-chars-forward "\t ")
           (looking-at "= "))
         (beginning-of-line)
         (skip-chars-forward "\t ")
         (forward-sexp 2)
         (forward-char 1)
         (current-column))
        ((looking-at "(")
         (forward-sexp 2)
         (backward-sexp 1)
         (current-column))
        (t
         ;; otherwise keep the same indentation as in the previous line
         indent))))))))))

(defun sml-get-paren-indent ()
  (save-excursion
    (let ((levelpar 0)          ; Level of "()"
          (levelcurl 0)                 ; Level of "{}"
          (levelsqr 0)                  ; Level of "[]"
          (backpoint (max (- (point) sml-paren-lookback) (point-min))))
      (catch 'loop
    (while (and (/= levelpar 1) (/= levelsqr 1) (/= levelcurl 1))
      (if (re-search-backward "[][{}()]" backpoint t)
          (if (not (sml-inside-comment-or-string-p))
          (cond
           ((looking-at "(") (setq levelpar (1+ levelpar)))
           ((looking-at ")") (setq levelpar (1- levelpar)))
           ((looking-at "\\[") (setq levelsqr (1+ levelsqr)))
           ((looking-at "\\]") (setq levelsqr (1- levelsqr)))
           ((looking-at "{") (setq levelcurl (1+ levelcurl)))
           ((looking-at "}") (setq levelcurl (1- levelcurl)))))
        (throw 'loop 0)))       ; Exit with value 0
    (if (save-excursion
          (forward-char 1)
          (looking-at sml-indent-starters-reg))
        (1+ (+ (current-column) sml-indent-level))
      (1+ (current-column)))))))

;; This is too slow
;;
;; (defun sml-inside-comment-or-string-p ()
;;  (let ((state (parse-partial-sexp (point-min) (point))))
;;    (or (nth 4 state) (nth 3 state))))

(defun sml-inside-comment-or-string-p ()
  (let ((start (point)))
    (if (save-excursion
      (condition-case ()
          (progn
        (search-backward "(*")
        (search-forward "*)")
        (forward-char -1)   ; A "*)" is not inside the comment
        (> (point) start))
        (error nil)))
    t
      (let ((numb 0))
    (save-excursion
      (save-restriction
        (narrow-to-region (progn (beginning-of-line) (point)) start)
        (condition-case ()
        (while t
          (search-forward "\"")
          (setq numb (1+ numb)))
          (error (if (and (not (zerop numb))
                  (not (zerop (% numb 2))))
             t nil)))))))))

(defun sml-skip-block ()
  (let ((case-fold-search nil))
    (sml-backward-sexp)
    (if (looking-at "end\\b")
    (progn
      (goto-char (sml-find-match-backward "end" "\\bend\\b"
                          sml-end-starters-reg))
      (skip-chars-backward "\n\t "))
      ;; Here we will need to skip backward past if-then-else
      ;; and case-of expression. Please - tell me how !!
      )))

(defun sml-find-match-backward (unquoted-this this match &optional start)
  (save-excursion
    (let ((case-fold-search nil)
      (level 1)
      (pattern (concat this "\\|" match)))
      (if start (goto-char start))
      (while (not (zerop level))
    (if (sml-re-search-backward pattern)
        (setq level (cond
             ((looking-at this) (1+ level))
             ((looking-at match) (1- level))))
      ;; The right match couldn't be found
      (error (concat "Unbalanced: " unquoted-this))))
      (point))))

(defun sml-find-match-indent (unquoted-this this match &optional indented)
  (save-excursion
    (goto-char (sml-find-match-backward unquoted-this this match))
    (cond
      ((or sml-type-of-indent indented)
       (current-column))
      ((progn
     (beginning-of-line)
     (skip-chars-forward "\t ")
     (looking-at "|"))
       (- (current-indentation)
      ;; sml-pipe-indent
      3))
      (t
       (current-indentation)))))

(defun sml-find-matching-starter (regexp)
  (let ((case-fold-search nil)
    (start-let-point (sml-point-inside-let-etc))
    (start-up-list (sml-up-list))
    (found t))
    (if (sml-re-search-backward regexp)
    (progn
      (condition-case ()
          (while (or (/= start-up-list (sml-up-list))
             (/= start-let-point (sml-point-inside-let-etc)))
        (re-search-backward regexp))
        (error (setq found nil)))
      found)
      nil)))

(defun sml-point-inside-let-etc ()
  (let ((case-fold-search nil) (last nil) (loop t) (found t) (start (point)))
    (save-excursion
      (while loop
    (condition-case ()
        (progn
          (re-search-forward "\\bend\\b")
          (while (sml-inside-comment-or-string-p)
        (re-search-forward "\\bend\\b"))
          (forward-char -3)
          (setq last (sml-find-match-backward "end" "\\bend\\b"
                          sml-end-starters-reg last))
          (if (< last start)
          (setq loop nil)
        (forward-char 3)))
      (error (progn (setq found nil) (setq loop nil)))))
      (if found
      last
    0))))

(defun sml-re-search-backward (regexpr)
  (let ((case-fold-search nil) (found t))
    (if (re-search-backward regexpr nil t)
    (progn
      (condition-case ()
          (while (sml-inside-comment-or-string-p)
        (re-search-backward regexpr))
        (error (setq found nil)))
      found)
      nil)))

(defun sml-up-list ()
  (save-excursion
    (condition-case ()
    (progn
      (up-list 1)
      (point))
      (error 0))))

(defun sml-backward-sexp ()
  (condition-case ()
      (progn
    (let ((start (point)))
      (backward-sexp 1)
      (while (and (/= start (point)) (looking-at "(\\*"))
        (setq start (point))
        (backward-sexp 1))))
    (error (forward-char -1))))

(defun sml-comment-indent ()
  (if (looking-at "^(\\*")      ; Existing comment at beginning
      0                 ; of line stays there.
      (save-excursion
    (skip-chars-backward " \t")
    (max (1+ (current-column))  ; Else indent at comment column
         comment-column))))     ; except leave at least one space.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; INFERIOR SHELL
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar sml-shell-working-dir ""
  "The working directory of sml-shell")

(defvar sml-process-name nil
  "The name of the SML-process")

(defvar sml-shell-map nil
  "The mode map for sml-shell.")

(defun sml-shell-goto-error () "Blah"
  (interactive)
  ;;(if sml-shell-mother-buffer () (error "Mother buffer is unknown"))
  ;(save-excursion
    (beginning-of-line)
    (let* (
          (beg (search-forward ":"))
          (end (- (search-forward ".") 1))
          (lineno (string-to-int (buffer-substring beg end)))
          )
      (message (concat "Error is in line: " lineno))
      (other-window -1) ;;(switch-to-buffer sml-shell-mother-buffer)
      (goto-line lineno)
      )
    ;)
)

(defun sml-shell ()
  "Inferior shell invoking SML.
It is not possible to have more than one shell running SML.
Like the shell mode with the additional command:

\\[sml-run-on-file]\t Runs sml on the file.
\\{sml-shell-map}
Variables controlling the mode:

sml-prog-name (default \"mosml\")
    The string used to invoke the sml program.

sml-prog-name-ask-p (default nil)
    If t, you will be asked which program to run when the inferior
    shell starts up. Usefull if you have exported images of sml.

sml-use-right-delim (default \"\\\"\")
sml-use-left-delim  (default \"\\\"\")
    The left and right delimiter used by your version of sml, for
    \"use file-name\".

sml-shell-prompt-pattern (default \"^[^\\-=]*[\\-=] *\")
    The prompt pattern.

sml-tmp-template (defualt \"/tmp/sml.tmp.\")
    Template for the temporary files, created when a region is send
    to the inferior process running sml (by sml-simulate-send-region).

Runs sml-shell-hook if not nil."
  (interactive)
  (if (not (and sml-process-name (eq (process-status sml-process-name) 'run)))
      (progn
    (message "Starting SML...") ; start up a new process
    (save-excursion         ; Process is not running
      (and sml-prog-name-ask-p
           (setq sml-prog-name
             (read-file-name
              (concat "Sml (default " sml-prog-name "): ")
              (file-name-directory (buffer-file-name))
              sml-prog-name)))
      (require 'shell)
      (setq sml-shell-working-dir default-directory)
      (if sml-process-name
          ()
        (setq sml-process-name
          (concat
           "Inferior "
           (substring sml-prog-name
                  (string-match "[^/]*$" sml-prog-name)
                  (string-match "$" sml-prog-name)))))
      (set-buffer
       (make-comint sml-process-name
            (if (= (string-to-char sml-prog-name) ?~)
                (expand-file-name sml-prog-name)
              sml-prog-name)))
      (erase-buffer)        ; Erase the buffer if a previous
      (if sml-shell-map     ; process died in there
          ()
        (setq sml-shell-map (copy-sequence shell-mode-map))
        (define-key sml-shell-map "\C-c\C-f" 'sml-run-on-file))
      (use-local-map sml-shell-map)
      (make-local-variable 'shell-prompt-pattern)
      (setq shell-prompt-pattern sml-shell-prompt-pattern)
      (setq major-mode 'sml-shell)
      (setq mode-name "Sml-Shell")
      (set-process-filter
       (get-process sml-process-name) 'sml-process-filter)
      (run-hooks 'sml-shell-hook))
    (message "Starting SML... done."))))

(defun sml-process-filter-km (proc str)
  (let ((cur (selected-window))
    (pop-up-windows t)
    (process (concat "*" sml-process-name "*")))
;;; (pop-to-buffer process)
    (save-excursion ;;; to stop pointing at the end of the file [km]
      (set-buffer process)
      (goto-char (point-max))
      (insert str)
      (set-marker (process-mark proc) (point-max))
    )
;;; (select-window cur)
))

;;; normal version:
(defun sml-process-filter (proc str)
  (let ((cur (selected-window))
    (pop-up-windows t)
    (process (concat "*" sml-process-name "*")))
    (pop-to-buffer process)
;;; (save-excursion
      (set-buffer process)
      (goto-char (point-max))
      (insert str)
      (set-marker (process-mark proc) (point-max))
;;; )
    (select-window cur)     ;;;
))

(defun sml-pop-to-shell ()
  "Pop to the buffer running sml."
  (interactive)
  (sml-shell)
  (pop-to-buffer (concat "*" sml-process-name "*")))

(defun sml-run-on-file (file)
  "Send a use FILE to the inferior shell running sml."
  (interactive "FUse file: ")
  (sml-shell)
  (setq file (expand-file-name file))
  (if sml-strip-path
      (if (string= (substring file 0 (string-match "[^/]*$" file))
           sml-shell-working-dir)
      (setq file (substring file (string-match "[^/]*$" file)
                (string-match "$" file)))))
  (save-some-buffers)
  (sml-skip-errors)
  (send-string sml-process-name
           (concat "use " sml-use-left-delim file
               sml-use-right-delim ";\n")))

(defun sml-save-buffer-use-file ()
  "Save the buffer, and send a `use file' to the inferior shell
running sml."
  (interactive)
  (let (file)
    (if (setq file (buffer-file-name))  ; Is the buffer associated
    (progn              ; with file ?
      (save-buffer)
      (sml-shell)
      (sml-skip-errors)
      (if sml-strip-path
          (if (string= (substring file 0 (string-match "[^/]*$" file))
               sml-shell-working-dir)
          (setq file (substring file (string-match "[^/]*$" file)
                    (string-match "$" file)))))
      (message (concat "use " sml-use-left-delim file sml-use-right-delim))
      (send-string sml-process-name
               (concat "use " sml-use-left-delim
                   file
                   sml-use-right-delim ";\n")))
      (error "Buffer not associated with file."))))

(defun sml-import-file ()
  "Save the buffer, and send an `import file' to the inferior shell
running sml."
  (interactive)
  (let (file)
    (if (setq file (buffer-file-name))
    (if (string-match ".sml$" file)
        (progn 
          (setq file (substring file 0 (string-match ".sml$" file)))
          (save-buffer)
          (sml-shell)
          (if sml-strip-path
          (if (string= (substring file 0 (string-match "[^/]*$" file))
                   sml-shell-working-dir)
              (setq file (substring file (string-match "[^/]*$" file)
                        (string-match "$" file)))))
          (sml-skip-errors)
          (message (concat "import \"" file "\""))
          (send-string sml-process-name
               (concat "import " sml-use-left-delim
                   file
                   sml-use-right-delim ";\n")))
      (error "Filename doesn't match \"*.sml\""))
      (error "Buffer not associated with file."))))

(defvar sml-tmp-files-list nil
  "List of all temporary files created by sml-simulate-send-region.
Each element in the list is a list with the format:
\n   (tmp-filename file-name start-line)")

(defvar sml-simulate-send-region-called-p nil
  "Has sml-simulate-send-region been called previously.")

(defvar sml-old-kill-emacs-hook nil
  "Old value of kill-emacs-hook")

(defconst sml-tmp-bug "")

(defun sml-simulate-send-region (point1 point2)
  "Simulate send region. As send-region only can handle what ever the
system sets as the default, we have to make a temporary file.
Updates the list of temporary files (sml-tmp-files-list)."
  (let ((file (expand-file-name
           (make-temp-name (concat sml-tmp-template sml-tmp-bug)))))
    ;; Remove temporary files when we leave emacs
    (if (not sml-simulate-send-region-called-p)
    (progn
      (setq sml-old-kill-emacs-hook kill-emacs-hook)
      (setq kill-emacs-hook 'sml-remove-tmp-files)
      (setq sml-simulate-send-region-called-p t)))
    ;; As make-temp-name can only make 26 unique file names with the
    ;; same template (bug in Un*x function mktemp), we add a new
    ;; letter to sml-tmp-template.
    (if (zerop (% (1+ (length sml-tmp-files-list)) 25))
    (setq sml-tmp-bug (concat sml-tmp-bug "A")))
    (save-excursion
      (goto-char point1)
      (setq sml-tmp-files-list
        (cons (list file
            (buffer-file-name)
            (save-excursion ; Calculate line no.
              (beginning-of-line)
              (1+ (count-lines 1 (point)))))
          sml-tmp-files-list)))
    (write-region point1 point2 file nil 'dummy)
    (sml-shell)
    (message "Using temporary file: %s" file)
    (send-string
     sml-process-name
     ;; string to send: use file;
     (concat "use " sml-use-left-delim file sml-use-right-delim ";\n"))))

(defun sml-remove-tmp-files ()
  "Remove the temporary files, created by sml-simulate-send-region, if
they still exist. Only files recorded in sml-tmp-files-list are removed.
This function is put into kill-emacs-hook if any temporary files are
used."
  (message "Removing temporary files created by sml-mode...")
  (while sml-tmp-files-list
    (condition-case ()
    (delete-file (car (car sml-tmp-files-list)))
      (error ()))
    (setq sml-tmp-files-list (cdr sml-tmp-files-list)))
  (message "Removing temporary files created by sml-mode... done.")
  (run-hooks 'sml-old-kill-emacs-hook))

(defun sml-send-region ()
  "Send region to inferior shell running sml."
  (interactive)
  (sml-shell)
  (sml-skip-errors)
  (let (start end)
    (save-excursion
      (setq end (point))
      (exchange-point-and-mark)
      (setq start (point)))
    (sml-simulate-send-region start end)))

(defun sml-send-function ()
  "Does *not* send the function, but the paragraph, to inferior shell
running sml (sorry)."
  (interactive)
  (sml-shell)
  (sml-skip-errors)
  (let (start end)
    (save-excursion
      (condition-case ()
      (progn
        (backward-paragraph)
        (setq start (point)))
    (error (setq start (point-min))))
      (condition-case ()
      (progn
        (forward-paragraph)
        (setq end (point)))
    (error (setq end (point-max)))))
    (sml-simulate-send-region start end)))

(defun sml-send-buffer ()
  "Send the buffer, to inferior shell running sml."
  (interactive)
  (sml-shell)
  (sml-skip-errors)
  (sml-simulate-send-region (point-min) (point-max)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; END OF SML-MODE
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


