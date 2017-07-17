(require 'tex-mode)
(provide 'tex-stuff)

(defconst Latex-closer (concat (regexp-quote "\\end") "{[^}]*}"))
(defconst Latex-opener (concat (regexp-quote "\\begin") "{[^}]*}"))
(defconst Latex-blocker
  (concat "\\\(" Latex-opener "\\\)\\\|\\\(" Latex-closer "\\\)"))
;(modify-syntax-entry  ?{ "(}" TeX-mode-syntax-table )
;(modify-syntax-entry  ?} "){" TeX-mode-syntax-table )

(defun latex-close-block () (interactive) 
    (let ((block (save-excursion (latex-find-block 0))) )
        (if (or (not block) (string-equal block "document"))
	    (error "No matching block found."))
        (if (not (bolp)) (newline))
        (insert-string (concat "\\end{" block "}"))
        (if (not (eolp)) (newline)))
)
 
(defun latex-find-block (depth)
      (if (re-search-backward Latex-blocker 0 t) 
	  (progn
	    (while (looking-at Latex-closer)
	      (latex-find-block (+ depth 1))
	      (re-search-backward Latex-blocker 0 t))
	    (if (and (= depth 0) (looking-at Latex-opener))
		(progn 
		  (search-forward "{")
		  (setq first (point))
		  (search-forward "}")
		  (backward-char)
		  (buffer-substring first (point)))
	        nil))
	  nil))

(defun current-tex-error () (interactive)
       (let ((buffer (current-buffer))
	     temp line)
           (switch-to-buffer-other-window "*TeX-shell*")
	   (end-of-buffer)
	   (if (re-search-backward "\nl\.[0-9]+" 0 t)
	       (progn (forward-char 3)
		      (setq temp (point))
		      (re-search-forward "[^0-9]") (backward-char)
		      (setq line (string-to-int
				  (buffer-substring temp (point))))
		      (if (re-search-backward "\n! " 0 t)
			  (progn
			    (forward-char))))
	       (error "No error found"))
	   (switch-to-buffer-other-window buffer)
	   (goto-line line)))
	   
(defvar latex-block-list '( ("enumerate" . nil)
			    ("list" . t)
			    ("abstract" . nil)
			    ("equation*" . nil)
			    ("eqnarray" . nil)
			    ("quote" . nil)
			    ("quotation" . nil)
			    ("center" . nil)
			    ("verse" . nil)
			    ("verbatim" .nil)
			    ("itemize" . nil)
			    ("description" . nil)
			    ("titlepage" . nil )
			    ("thebibliography" . nil)
			    ("figure" . nil)
			    ("tabular" .nil)
			    ("fig" . t )
			    ("Fig" . nil )
			    ("minipage" . t)
			    ("array" . t)
			    ("sblist" . nil)
			    ("blist" . nil)
			    ("dlist" . nil)
			    ("clist" . nil)
			    ("table" . t)) "List of known LaTeX blocks")
			    
(defun latex-begin-block () "Doc"  (interactive)
	(let ((block (completing-read "block: " latex-block-list nil 1)))
	  (if (not (eolp)) (progn (end-of-line) (newline)))
	  (insert "\\begin{" block "}")
	  (if (cdr (assoc block latex-block-list))
	      (progn (insert "[]") (backward-char)))))

(defun latex-declare-block (args block) "Add a block to latex-block-list"
  (interactive "p
sblock: ")
  (setq latex-block-list (cons (cons block
				     (= args 4)) latex-block-list)))

(defun number-slides () (interactive)
  (save-excursion
    (let ((count 1))
      (goto-char (point-min))
      (while (re-search-forward "\\\\begin{slide} *{\\([^}]*\\)}" nil t)
	(if (looking-at ".*% [0-9]*$")
	    (progn
	      (re-search-forward ".*%")
	      (kill-line))
	  (progn (end-of-line) (insert " %")))
	(insert " " (int-to-string count))
	(setq count (+ count 1))))))

(defun number-slides () (interactive)
  (save-excursion
    (let ((count 1))
      (goto-char (point-min))
      (while (re-search-forward "^ *\\\\begin{slide} *{\\([^}]*\\)}" nil t)
	(if (looking-at ".*% *[0-9]* *$")
	    (progn
	      (re-search-forward ".*%")
	      (kill-line))
	  (progn (end-of-line) (insert " %")))
	(insert " " (int-to-string count))
	(setq count (+ count 1))))))

(require 'mlsupport)

;; redefine this from utilities.el 'cause mlsupport defines 
;; it as non-interactive.
(defun line-to-top-of-window nil
  "Move the line the cursor is on to the top of the current window"
  (interactive)
  (recenter 0))

(ml-defun (ml-foo 
(progn
    (declare-global key-I)  (setq key-I "itemize")
    (declare-global key-E)  (setq key-E "enumerate")
    (declare-global key-D)  (setq key-D "description")
    (declare-global key-i)  (setq key-i "\\it ")
    (declare-global key-b)  (setq key-b "\\bf ")
    (declare-global key-r)  (setq key-r "\\rm ")
    (declare-global key-s)  (setq key-s "\\sl ")
    (declare-global key-g)  (setq key-g "\\sf ")
    (declare-global key-t)  (setq key-t "\\tt ")

    (ml-defun (tex-paren
	    (ml-if (= (last-key-struck) (following-char))
		(forward-character)
		(insert (last-key-struck)))
	    (save-excursion
		(backward-list)
		(ml-if (pos-visible-in-window-p)
		    (sit-for 5)
		    (progn
			  (beginning-of-line)
			  (set-mark-command)
			  (end-of-line)
			  (ml-message (region-to-string)))
		)
	    )
	)
	(texo-paren
	    (ml-if (logior (eolp)
		   (logior (= (following-char) ?\))
		      (logior (= (following-char) ?\})
		        (logior (= (following-char) ?\])))))
		(progn (ml-if (= (last-key-struck) ?\()
			   (insert-string "()")
			   (ml-if (= (last-key-struck) ?\[)
			       (insert-string "[]")
			       (ml-if (= (last-key-struck) ?\{)
			            (insert-string "{}")
			            (nothing)
			       )
			   )
		       )
		       (backward-character))
		(insert (last-key-struck))))

	(tex-begin Typename
	    (setq Typename (ml-arg 1 "Type: "))
	    (insert-string (concat (concat "\n\\begin{" Typename) "}\n\n"))
		(insert-string (concat (concat "\\end{" Typename ) "}\n"))
		(previous-line 2)
	)

	(tex-enumerate 
	    (tex-begin "enumerate")
	)

	(tex-itemize 
            (tex-begin "itemize")
	)

	(tex-description 
            (tex-begin "description")
	)

	(tex-slash Typename
            (setq Typename (ml-arg 1 "Type: "))
	    (insert-string "\\")
	    (insert-string Typename)
	    (insert ?\ )
	)

	(tex-item
	    (tex-slash "item"))
 
	(tex-brace Typename                      ;; {\type}
            (setq Typename (ml-arg 1 "Type: "))
	    (insert-string "\{\\")
	    (insert-string Typename)
	    (insert ?\ )
	    (insert-string "\}")
	    (backward-character)
	)

	(tex-emphasis
	    (tex-brace "em"))

	(tex-description-item
	    (tex-item)
	    (backward-character)
	    (insert-string "[]")
	    (backward-character)
	)

	(tex-footnote
	    (tex-slash "footnote")
	    (backward-character)
            (insert-string "{}")
            (backward-character)
	)

	(tex-cite
	    (tex-slash "cite")
	    (backward-character)
            (insert-string "{}")
            (backward-character)
	)

	(tex-ref
	    (tex-slash "ref")
	    (backward-character)
            (insert-string "{}")
            (backward-character)
	)

    (apply-some-begin key macro
	    (setq key (char-to-string (read-char)))
	    (setq macro (execute-mlisp-line (concat "key-" key)))
            (tex-begin macro)
	)
; apply code stolen from Andrew {Black
	  (apply-italics-macro
	      (apply-macro key-i "\\/"))
	  
	  (apply-some-macro key macro
	      (setq key (char-to-string (read-char)))
	      (setq macro (execute-mlisp-line (concat "key-" key)))
	      (apply-macro macro ""))
	  
	  (apply-macro atend initialdot
	      (setq atend (eolp))
	      (ml-if (ml-not atend) (forward-character))
	      (setq initialdot (point-marker))
	      (backward-word 1)
	      (insert ?\{)
;	      (insert-string (ml-arg 1))
	      (insert-string macro)
	      (forward-word 1)
	      (insert-string (ml-arg 2 "suffix: "))
	      (insert ?\})
	      (ml-if atend (end-of-line) 
		  (progn (goto-char initialdot)
			 (backward-character))))

        (tex-special-key
	    (insert ?\\)
	    (insert (last-key-struck)))

        (tex-math-key
	    (insert ?\$)
	    (insert (last-key-struck))
	    (insert ?\$))

        (tex-chapter
	    (insert-string "\\chapter{}")
	    (backward-character))
	
        (tex-section
	    (insert-string "\\section{}")
	    (backward-character))

        (tex-subsection
	    (insert-string "\\subsection{}")
	    (backward-character))

        (tex-subsubsection
	    (insert-string "\\subsubsection{}")
	    (backward-character))
))))
	
(defun local-bind-to-key (name key)
  (or (current-local-map)
      (use-local-map (make-keymap)))
  (define-key (current-local-map)
    (if (integerp key)
	(if (>= key 128)
	    (concat (char-to-string meta-prefix-char)
		    (char-to-string (- key 128)))
	  (char-to-string key))
      key)
    (intern name)))

(ml-defun	(my-tex-mode
; put into text mode but avoid Black special bindings
        (setq fill-column 76)
        (setq left-margin 0)
    	(auto-fill-mode 1)
        (setq case-fold-search 1)
	    (local-bind-to-key "tex-begin" "\^Cb")
	    (local-bind-to-key "apply-some-begin" "\^CB")
	    (local-bind-to-key "tex-footnote" "\^Cf")
	    (local-bind-to-key "tex-item" "\^Ci")
	    (local-bind-to-key "tex-emphasis" "\^Cp")
	    (local-bind-to-key "tex-description-item" "\^Cd")
	    (local-bind-to-key "apply-some-macro" "\^Cm")
	    (local-bind-to-key "tex-enumerate" "\^CE")
	    (local-bind-to-key "tex-itemize" "\^CI")
	    (local-bind-to-key "tex-description" "\^CD")
	    (local-bind-to-key "tex-cite" "\^Cc")
	    (local-bind-to-key "tex-ref" "\^Cr")
	    (local-bind-to-key "tex-chapter" "\^CC")
	    (local-bind-to-key "tex-section" "\^CS")
	    (local-bind-to-key "tex-subsection" "\^Cs")
	    (local-bind-to-key "tex-subsubsection" "\^Cu")
	    ))
;	    (local-bind-to-key "tex-paren" ?\))
;	    (local-bind-to-key "tex-paren" ?\])
;	    (local-bind-to-key "tex-paren" ?\})
;	    (local-bind-to-key "texo-paren" ?\()
;	    (local-bind-to-key "texo-paren" ?\[)
;	    (local-bind-to-key "texo-paren" ?\{)
;	    (local-bind-to-key "tex-special-key" ?\%)
;	    (local-bind-to-key "tex-special-key" ?\$)
;	    (local-bind-to-key "tex-special-key" ?\#)
;	    (local-bind-to-key "tex-special-key" ?\&)
;	    (local-bind-to-key "tex-special-key" ?\_)
;	    (local-bind-to-key "tex-math-key" ?\<)
;	    (local-bind-to-key "tex-math-key" ?\>)
;	    (local-bind-to-key "tex-math-key" ?\=)))

(defun fix-verbatim-region (start end)
"Go through region and: untabify and remove all '\\' chars and '$'"
 (interactive "r")
  (save-excursion
    (save-restriction
		  (narrow-to-region start end)
		  (goto-char start)
		  (untabify start end)
		  (goto-char start)
		  (replace-string "\\_" "_")
		  (goto-char start)
		  (replace-string "$" ""))))

(defun fix-verbatim ()
  (interactive)
  (save-excursion
	(save-restriction
	  (if
		  (and (word-search-backward "\\begin{verbatim}")
			   (word-search-forward "\\end{verbatim}"))
		  (fix-verbatim-region
		   (progn
			 (word-search-backward "\\begin{verbatim}")
			 (point))
		   (progn
			 (word-search-forward "\\end{verbatim}")
			 (point)))
		(progn
		  (message "can't find begin and end for verbatim")
		  (sit-for 3))))))

(ml-foo)
(my-tex-mode)

