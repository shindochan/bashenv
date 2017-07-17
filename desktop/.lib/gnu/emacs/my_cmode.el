(defun c-mode-custom () "My customizations for c-mode"
  (setq fill-column 72)
  (setq default-fill-column 72)
  (setq c-basic-offset 4)		        ; Amazon uses indent of four at a time
  (setq indent-tabs-mode nil)		; Amazon uses spaces only
  (setq c-tab-always-indent nil)
  (c-toggle-auto-hungry-state 1)
  (setq c-cleanup-list
	'(defun-close-semi list-close-comma scope-operator))
  (setq c-electric-pound-behavior '(alignleft))
  (setq c-hanging-braces-alist
	'((brace-list-open) (block-close . c-snug-do-while)))
  (setq c-hanging-comment-ender-p nil)
  (setq c-indent-comments-syntactically-p t)
  (setq c-echo-syntactic-information-p t)
  (setq c-comment-continuation-stars "* ")
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'case-label '+)
  (auto-fill-mode 1))

(defun kernel-normalize ()
  (interactive)
  "Do bak-gak normal form for the kernel on current line.  So far, this 
includes: 
    - remove spaces following '(', '[' and '{'
    - remove spaces preceding ')', ']' and '}'
Soon to be added:
    - put parens around return values
    - place 'continue' on otherwise floating ';'
    - moves '{' to previous line if there is only whitespace before it.
"
    (save-excursion
	(let ((last (progn (end-of-line) (point)))
	      (first (progn (beginning-of-line) (point))))
	  (goto-char first)
	  (while (re-search-forward "\\([({[]\\)[ \\t]+" last t)
	    (replace-match "\\1" t nil))
	  (goto-char first)
	  (while (re-search-forward "[ \\t]+\\([]})]\\)" last t)
	    (replace-match "\\1" t nil))))
)
