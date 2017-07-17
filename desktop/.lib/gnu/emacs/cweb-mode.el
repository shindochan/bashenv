;; CWeb-mode editing commands for Emacs
;;	For C++ and LaTeX.

(require 'cc-mode)
(provide 'cweb-mode)

(defvar cweb-mode-abbrev-table nil
  "Abbrev table in use in CWeb-mode buffers.")
(define-abbrev-table 'cweb-mode-abbrev-table ())

;(defvar cweb-mode-map ()
;  "Keymap used in CWeb mode.")
;(if cweb-mode-map
;    ()
;  (setq cweb-mode-map (make-sparse-keymap))
;  (define-key cweb-mode-map "\t" 'cweb-indent-command))
;
(defvar cweb-mode-syntax-table nil
  "Syntax table in use in CWeb-mode buffers.")

(if cweb-mode-syntax-table
    ()
  (setq cweb-mode-syntax-table (copy-syntax-table c-mode-syntax-table))
  (modify-syntax-entry ?/ ". 12" cweb-mode-syntax-table)
  (modify-syntax-entry ?\n ">" cweb-mode-syntax-table)
  (modify-syntax-entry ?\' "." cweb-mode-syntax-table))

(defun cweb-mode ()
  "Major mode for editing Web code for C++ and LaTeX.  Very much like
editing C code.  Built on top of the c++-mode in cc-mode.

Turning on CWeb mode calls the value of the variable cweb-mode-hook with
no args,if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
;  (use-local-map cweb-mode-map)
  (setq major-mode 'cweb-mode)
  (setq mode-name "CWeb")
  (setq local-abbrev-table cweb-mode-abbrev-table)
  (set-syntax-table cweb-mode-syntax-table)
  (run-hooks 'cweb-mode-hook))
