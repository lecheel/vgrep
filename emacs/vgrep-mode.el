;;; vgrep-mode.el --- a mode for viewing/grep context in wide
;;; Copyright (C) 2oo9 lecheel
;;; Author: lecheel <lecheel [at] gmail [dot]com>
;;;
;;; This file is NOT part of GNU Emacs
;;;
;;; how to use vgrep-mode.el
;;; Installation:
;;;
;;; 1. Put this file in a directory that is a member of load-path, and
;;;    byte-compile it (e.g. with `M-x byte-compile-file') for better
;;;    performance.
;;; 2. Add the following to your ~/.emacs:
;;;    (require vgrep-mode)
;;;    (add-hook 'grp-mode-hook '(lambda ()
;;;        (local-set-key (kbd "RET") 'vEnter)))
;;;    (global-set-key [(f11)]'vlist)
;;;
;;; 3. need external vgrep
;;;    same package available in vim http://www.vim.org/scripts/script.php?script_id=773
;;;    also with vgrep source

(defun vgrep-default ()
  (or (and transient-mark-mode mark-active
	   (/= (point) (mark))
	   (buffer-substring-no-properties (point) (mark)))
      (funcall (or find-tag-default-function
		   (get major-mode 'find-tag-default-function)
		   'find-tag-default))
      ""))

(defun vgrep-read-regexp ()
  "Read regexp arg for interactive grep."
  (let ((default (vgrep-default)))
    (setq vstr
	  (read-string
	   (concat "Search for"
		   (if (and default (> (length default) 0))
		       (format " (default \"%s\"): " default) ": "))
	   nil 'grep-regexp-history default))
;;    (message "<%s> Marked! vgrep v0.1" vstr)
    
    ))


(defun vgrep-read-files ()
  "Read regexp arg for interactive grep files."
  (let ((default (concat "\\*." (vgrep-file-ext))))
    (setq vstr
	  (read-string
	   (concat "Search for files "
		   (if (and default (> (length default) 0))
		       (format " (default \"%s\"): " default) ": "))
	   nil 'grep-regexp-history default))
    
    ))


(defun vgrep ()
(interactive)
   (let* ((regexp (vgrep-read-regexp))
	 (files (vgrep-read-files))
	 (dir (read-directory-name "In directory: " nil default-directory nil))
	 )  
     (start-process "vgrep" "*Messages*" "vgrep" "--grep" regexp dir files)
     (message "<F11> for vlist.")
     ))

(defun vlist ()
  (interactive)
  (find-file-read-only "~/fte.grp")
  )

(defun cur-file ()
  "Return the filename (without directory) of the current buffer"
  (file-name-nondirectory (buffer-file-name (current-buffer)))
  )

(defun vgrep-file-ext ()
    "Return the extension of current-buffer"
	(file-name-extension (cur-file))
)

(defun vEnter()
  (interactive)
  (progn (beginning-of-line)
		 (setq myLine (thing-at-point 'word))
		 (search-backward "File:")
		 (setq myLLLL (thing-at-point 'line))
		 (setq myFile (substring myLLLL 6 -1))
		 (kill-buffer (current-buffer))
		 (set-buffer (find-file-noselect myFile))
		 (switch-to-buffer (current-buffer))
		 (goto-line (string-to-number myLine))
		 )
  )
  
(defun grp-mode-quit()
  (interactive)
  (kill-buffer (current-buffer))
  )

(defvar grp-mode-hook nil)
(defvar grp-mode-map
  (let ((grp-mode-map (make-keymap)))
    (define-key grp-mode-map "\C-j" 'vEnter)
    (define-key grp-mode-map (kbd "q") 'grp-mode-quit)
    (define-key grp-mode-map (kbd "e") 'vEnter)
    grp-mode-map)

  "Keymap for vGrep major mode")

(add-to-list 'auto-mode-alist '("\\.grp\\'" . grp-mode))

(defun vEnter1()
  (interactive nil)
  (message "vEnter...")
;;  (search-backward "File:" 0 t 1)
)

(defconst grp-font-lock-keywords-1
  (list '("File:.*"
		  . font-lock-comment-face)
		'("^[0-9]*"
		  . font-lock-function-name-face))
  "Minimal highlighting expressions for grp mode.")

(defvar grp-font-lock-keywords grp-font-lock-keywords-1
  "Default highlighting expressions for grp mode.")

(defvar grp-mode-syntax-table
  (let ((grp-mode-syntax-table (make-syntax-table)))
	
    ; This is added so entity names with underscores can be more easily parsed
	(modify-syntax-entry ?_ "w" grp-mode-syntax-table)
	
	; Comment styles are same as C++
	(modify-syntax-entry ?/ ". 124b" grp-mode-syntax-table)
	(modify-syntax-entry ?* ". 23" grp-mode-syntax-table)
	(modify-syntax-entry ?\n "> b" grp-mode-syntax-table)
	grp-mode-syntax-table)
  "Syntax table for grp-mode")
  
(defun grp-mode ()
  (interactive)
  (kill-all-local-variables)
  (use-local-map grp-mode-map)
  (set-syntax-table grp-mode-syntax-table)
  ;; Set up font-lock
  (set (make-local-variable 'font-lock-defaults) '(grp-font-lock-keywords))
  ;; Register our indentation function
  (set (make-local-variable 'newline) 'vEnter)
  (setq major-mode 'grp-mode)
  (setq mode-name "vGrep")
  (run-hooks 'grp-mode-hook))

(provide 'vgrep-mode)
