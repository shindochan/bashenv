;;; New cscope.el--based loosely on the old.  Uses new features of
;;; cscope.  Basically, these functions just implement an emacs user
;;; interface to cscope.  If you use the fast cscope database, things
;;; will fly.

(defun reload-cscope () "Reload cscope" (interactive) (load "cscope"))

;;; function to call cscope from command line.  You'll need two
;;; commands in your .emacs file as follows:
;;;	(setq command-switch-alist (cons (cons "-cscope" 'cscope-switch)
;;;				 	 command-switch-alist))
;;;	(autoload 'cscope-switch "cscope" "cscope program cross reference" t)
;;; To use, call emacs like so:
;;;	emacs -cscope cscope.out
(defun cscope-switch (switch)
  (cscope (expand-file-name (car command-line-args-left)))
  (setq command-line-args-left (cdr command-line-args-left))
  (run-hooks 'cscope-cmdline-hook))

;;; function to call ccsput from command line.  You'll need two
;;; commands in your .emacs file as follows:
;;;	(setq command-switch-alist (cons (cons "-ccsput" 'ccsput-switch)
;;;				 	 command-switch-alist))
;;;	(autoload 'ccsput-switch "cscope" "cscope program cross reference" t)
;;; To use, call emacs like so:
;;;	emacs -ccsput file-to-put
(defun ccsput-switch (switch)
  (save-excursion
    (set-buffer "*scratch*")		; get cwd right
    (let ((file (expand-file-name (car command-line-args-left))))
      (find-file file)
      (ccsput file)
      (setq command-line-args-left (cdr command-line-args-left))
      (run-hooks 'ccsput-cmdline-hook))))

;;; global constants and variables
(defvar cscope-databases nil "A global list of databases")
(defvar cscope-last-database "cscope.out"
  "The last data base selected via cscope")
(defvar cscope-gnu-regexp t "Type of regexp used in find regexp and
query replace regexp.  If nil, use egrep style of regexp.  Otherwise,
use gnu emacs style of regexps (default)")
(defvar cscope-display-selections t
  "If nil, don't display the selection window every time it is used.
This suppresses the default behavior")
(defvar cscope-depth-first nil
  "If nil, multiple level find functions called/using search breadth
first (default), otherwises search depth first")
(defvar cscope-hook nil "user hook called after cscope executes")
(defvar cscope-load-hook nil "user hook called after cscope is loaded")
(defvar cscope-cmdline-hook nil "user hook called after '-cscope' switch")
(defvar cscope-ifdef "_MICK_" "Token for insert-ifdef")

(defconst cscope-selection-header "file\t\t\t\t\t\tfunction\tline\tsource\n"
  "header line for selections")

;;; buffer local-variables
(defvar cscope-database nil "The name of the database associated
with this buffer" )
(make-variable-buffer-local 'cscope-database)

(defvar cscope-selections nil "The buffer with the selection choices")
(make-variable-buffer-local 'cscope-selections)

(defun cscope (database)
  "Go to a cscope selection buffer.  If there is one associated with
the current buffer, use that one silently.  If not, use the one
currently associated with the DATABASE given.  If there isn't one
associated with the database, create one.  If called interactively,
will ask for a database only if there isn't a selections buffer
associated with the current buffer. Probably should check that it IS a
cscope database, but it doesn't yet.  Still needs work."
  (interactive (list (if cscope-selections
			 (save-excursion
			   (set-buffer cscope-selections)
			   cscope-database)
		       (expand-file-name (read-file-name
					  (format "Database (default %s): "
						  cscope-last-database)
					  nil cscope-last-database t)))))

  ;; go to the cscope selection buffer associated with this buffer, if
  ;; it exists, otherwise to the one associated with the database, if
  ;; it exists, otherwise to a newly created one.
  (let ((buffer (or cscope-selections
		    (cdr (assoc database cscope-databases))
		    (generate-new-buffer "*cscope-selections*"))))
    (if (not cscope-selections) (setq cscope-selections buffer))
    (if cscope-display-selections
	(pop-to-buffer buffer)
      (set-buffer buffer)))
  (if (not cscope-selections)		;new selection buffer, set it up
      (progn
	(setq cscope-selections (current-buffer))
	(setq cscope-database database)
	(setq cscope-databases (cons (cons database cscope-selections)
				     cscope-databases))
	(cd (file-name-directory database))))
  (setq cscope-last-database database)
  (run-hooks 'cscope-hook))

;;; Given a field name and a pattern, invoke cscope via the line
;;; interface to build the selection list.  If there is only one item
;;; in the selection list, bring the user to it.
(defun cscope-find-generic (field pattern &optional listonly)
  "The workhorse.  Given a FIELD specifier and a PATTERN, will create
a list of possible choices to visit.  Field is specified as -<n>,
where n is the zero-based field number of the standard cscope
interactive prompt. Pattern is a pattern appropriate to give to cscope
in the given field. If there is only one item in the resulting
selection list and LISTONLY is missing or nil, do an automatic
cscope-visit-file."

  ;; Pop to a cscope selection window.  If need be, ask for a database.
  (cscope (if cscope-selections
	      (save-excursion
		(set-buffer cscope-selections)
		cscope-database)
	    (expand-file-name (read-file-name (format "Database (default %s): "
				    cscope-last-database)
			    nil cscope-last-database t))))
  (if (/= (point-max) (point))
      (progn
	(push-mark nil t)
	(goto-char (point-max))))
  (if (/= (point-min) (point-max))
      (insert "\n"))
  (insert cscope-selection-header)
  (save-excursion
    (call-process "cscope" nil cscope-selections nil "-d" "-f"
		  cscope-database "-L" field pattern))
  (let ((lines (count-lines (point) (point-max)))) 
    (if (= lines 1)
	(message "1 match")
      (message "%d matches" lines))
    (if (and (not listonly) (= lines 1))
	(cscope-visit-file))))

(defun cscope-debug (string) "" (let ((buffer (current-buffer)))
			   (set-buffer "*scratch*")
			   (insert string)
			   (set-buffer buffer)))

(defun cscope-prompt-symbol (prompt)
  "Prompt for a symbol, give the next one as default.  Useful in interactive"
  (save-excursion
    (modify-syntax-entry ?_ "w")
    (forward-word 1)
    (forward-word -1)
    (modify-syntax-entry ?_ "_")
    (read-string prompt 
		 (or (and (not (eq (current-buffer) cscope-selections))
			  (or (looking-at "[a-zA-Z_$][a-zA-Z_0-9$]*")
			      (re-search-forward "[a-zA-Z_$][a-zA-Z_0-9$]*"
						 nil t))
			  (buffer-substring (match-beginning 0) (match-end 0)))
		     ""))))

(defun cscope-prompt-containing-function (prompt)
  "Prompt for a symbol, gives the function we are within as default.
Useful in interactive"
  (let ((default (save-excursion
		   (or (and (not (eq (current-buffer) cscope-selections))
			    (progn
			      (end-of-defun)
			      (beginning-of-defun)
			      (re-search-backward "[a-zA-Z_0-9$][ \t]*("
						  nil t))
			    (progn
			      (forward-line 0)
			      (re-search-forward
			       "\\([a-zA-Z_$][a-zA-Z_0-9$]*\\)[ \t]*("
			       nil t))
			    (buffer-substring (match-beginning 1)
					      (match-end 1)))
		       ""))))
    (read-string prompt default)))

(defun cscope-find-symbol (regexp)
  "Find the symbol given by the regular expression (^ & $ excepted)"
  (interactive (list (cscope-prompt-symbol
		      "Symbol (regexp) to find: ")))
  (cscope-find-generic "-0" regexp))

(defun cscope-find-global-definition (regexp)
  "Find the definition of this function or #define matched by the
given regexp (^ & $ excepted)"
  (interactive (list (cscope-prompt-symbol
		      "Function or #define to find (regexp): ")))
  (cscope-find-generic "-1" regexp))

(defun cscope-memsq (string list)
  "Returns t if string is a member of list.  Uses string="
    (while (and list (not (string= (car list) string)))
      (setq list (cdr list)))
    list)

(defun cscope-find-functions-called (regexp depth &optional seen-before)
  "Find the definitions of all functions called by the given one"
  (interactive (list (cscope-prompt-containing-function	
		      "Functions called by (regexp): ")
		     (prefix-numeric-value current-prefix-arg)))
  (cscope-find-generic "-2" regexp t)
  (save-excursion			; Add the calling function name
    (while (re-search-forward
	    "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)"
	    nil 'end)
      (replace-match (concat "\\1 "
			     (if seen-before (car seen-before) regexp)
			     " \\2 \\3 \\4"))))
  (if (/= depth 1)
      (save-excursion
	(if (> depth 0)
	    (setq depth (1- depth)))
	(let ((seen seen-before)) 
	  (while (re-search-forward
		  "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)"
		  nil 'end)
	    (catch 'continue
	      (let ((function (buffer-substring (match-beginning 3)
						(match-end 3))))
		(forward-line 1)
		(if (cscope-memsq function seen)
		    (throw 'continue t)
		  (setq seen (cons function seen)))
		(save-excursion
		  (save-restriction
		    (if cscope-depth-first
			(narrow-to-region (point-min) (point)))
		    (cscope-find-functions-called function depth seen)
		    (if (= (forward-line -2) 0)
			(kill-line 2))))))))))
  (if (not seen-before)			; only top level call has this null
      (let ((lines (count-lines (point) (point-max)))) 
	(save-excursion			; remove the called function name
	  (while (re-search-forward
		  "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)"
		  nil 'end)
	    (replace-match "\\1 \\2 \\4 \\5")))
	(if (= lines 1)
	    (progn
	      (message "1 match")
	      (cscope-visit-file))
	  (message "%d matches" lines)))))

(defun cscope-find-functions-using (regexp depth &optional seen-before)
  "Find all uses (calls) of this function"
  (interactive (list (cscope-prompt-containing-function
		      "Functions calling (regexp): ")
		     (prefix-numeric-value current-prefix-arg)))
  (cscope-find-generic "-3" regexp t)
  (if (/= depth 1)
      (save-excursion
	(if (> depth 0)
	    (setq depth (1- depth)))
	(let ((seen seen-before))
	  (while (re-search-forward
		  "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)"
		  nil 'end)
	    (catch 'continue
	      (let ((function (buffer-substring (match-beginning 2)
						(match-end 2))))
		(forward-line 1)
		(if (cscope-memsq function seen)
		    (throw 'continue t)
		  (setq seen (cons function seen)))
		(save-excursion
		  (save-restriction
		    (if cscope-depth-first
			(narrow-to-region (point-min) (point)))
		    (cscope-find-functions-using function depth seen)
		    (if (= (forward-line -2) 0)
			(kill-line 2))))))))))
  (if (not seen-before)			; only top level call has this null
      (let ((lines (count-lines (point) (point-max)))) 
	(if (= lines 1)
	    (progn
	      (message "1 match")
	      (cscope-visit-file))
	  (message "%d matches" lines)))))

(defun cscope-find-text-string (string)
  "Find the given text string--multi file search"
  (interactive "sString to find: ")
  (cscope-find-generic "-4" string))

(defun cscope-find-assignments (regexp)
  "Find assignments to the symbols matched by the given regular expression"
  (interactive (list (cscope-prompt-symbol
		      "Find assignments to Symbol (regexp): ")))
  (cscope-find-generic "-4" regexp))

;;; In order to mimic the regular query replace as close as possible,
;;; I've copied and modified the following help text.
(defconst cscope-query-replace-help
  "Type Space or `y' to replace one match, Delete or `n' to skip to next,
ESC or `q' to exit, Period to replace one match and exit,
Comma to replace but not move point immediately,
C-r to enter recursive edit (\\[exit-recursive-edit] to get out again),
C-w to delete match and recursive edit,
C-l to clear the screen, redisplay, and offer same replacement again,
! to replace all remaining matches with no more questions,
^ to move point back to previous match."
  "Help message while in query-replace")

(defun cscope-query-replace (regexp string continuation)
  "Query replace across multiple files"
  ;; Do a find regexp, remembering where we were in the selections
  ;; buffer.  Then, visit each found file and simulate a query search
  ;; and replace for each visit only. ****** Works, unless two targets share a
  ;; line. If called with an arg, will pick up in the middle--that is,
  ;; it will skip the step of locating the text to change.
  (interactive
   "sCscope query replace regexp: \nsCscope query replace regexp %s with: \nP")
  ;; find all the regexps  This will always leave us in the
  ;; selection buffer at the beginning of our group of selections
  ;; because we call cscope-find-generic with listonly = t.
  ;; NOTE:  The next sexpr is an inline expansion of
  ;; cscope-find-regexp 
  (if (not continuation)
      (cscope-find-generic "-6"
			   (if cscope-gnu-regexp
			       (cscope-regexp-convert regexp)
			     regexp)
			   t))
  (let ((nocasify (not (and case-fold-search case-replace
			    (string-equal regexp (downcase regexp)))))
	(help-form '(concat "Cscope query replacing"
			    regexp
			    " with "
			    string
			    ".\n\n"
			    (substitute-command-keys
			     cscope-query-replace-help)))
	(database-warn t)
	(query-flag t)
	(skips 0)
	(selection-point (point))
	replaced
	previous-loc)
    (catch 'return
      (while (not (eq (point) (point-max)))
	(catch 'continue
	  (cscope-visit-file)
	  ;; Must always do search to position for query
	  ;; replace. 
	  (if (not (re-search-forward regexp (save-excursion (forward-line)
							     (point))
				      t))
	      (progn
		(if database-warn
		    ;; Warn the user about a possilbe out of
		    ;; date cscope database 
		    (if (y-or-n-p  "Cscope database out of date--continue?")
			(setq database-warn nil)
		      (throw 'return t)))
		;; Attempt to position despite database
		;; failure.
		(if (not (or (looking-at regexp)
			     (re-search-forward regexp (save-excursion
							 (forward-line 5)
							 (point))
						t)
			     (re-search-backward regexp (save-excursion
							  (forward-line -5) 
							  (point))
						 t)))
		    ;; despite best efforts, can't find it.
		    ;; Tell the user and continue wihtout
		    ;; intervention 
		    (progn (setq skips (1+ skips))
			   (message "Can't find regexp '%s'(skip # %d)"
				    regexp skips)
			   (throw 'continue t)))))
	  (undo-boundary)
	  ;; In order to match the regular query replace as
	  ;; closely as possible, the next sexpr was copied
	  ;; from perform-replace and modified
	  (if (not query-flag)
	      (replace-match string nocasify nil)
	    (let ((data (match-data))
		  char done)
	      (setq replaced nil)
	      (while (not done)
		(message "Cscope query replacing %s with %s: "
			 regexp string)
		(setq char (read-char))
		;; Restore the match data.  Process filters
		;; and sentinels could run inside read-char..
		(if (not replaced)
		    (store-match-data data))
		(cond ((= char ??) (setq unread-command-events
					 (cons help-char
					       unread-command-events)))
		      ((= char ?\C-r) (save-excursion (recursive-edit)))
		      ((= char ?\C-l) (recenter nil))
		      ((= char ?^)
		       (if previous-loc
			   (progn (setq selection-point (nth 0 previous-loc))
				  (switch-to-buffer (nth 1 previous-loc))
				  (goto-char (nth 2 previous-loc))
				  (setq replaced (nth 3 previous-loc))
				  (setq data (nth 4 previous-loc)))))
		      ((= char ?\,)
		       (or replaced
			   (replace-match string nocasify nil))
		       (setq replaced t))
		      ((= char ?\C-w)
		       (or replaced (delete-region (match-beginning 0)
						   (match-end 0)))
		       (save-excursion (recursive-edit))
		       (setq replaced t))
		      (t (setq done t))))
	      ;; We're out of read loop, because we know we've
	      ;; got to move. Throw return is abort query
	      ;; replace.
	      (cond ((or (= char ?\e) (= char ?q))
		     (throw 'return nil))
		    ((or (= char ?\ ) (= char ?y))
		     (or replaced (replace-match string nocasify nil)))
		    ((= char ?\.)
		     (or replaced (replace-match string nocasify nil))
		     (throw 'return nil))
		    ((= char ?!)
		     (or replaced (replace-match string nocasify nil))
		     (setq query-flag nil))
		    ((or (= char ?\177) (= char ?n)))
		    (t (setq unread-command-events
			     (cons char unread-command-events))
		       (throw 'return nil))))))
	;; This is where (throw continue sexpr) gets you, still inside the
	;; source code buffer.
	(setq previous-loc
	      (list selection-point
		    (current-buffer) (point) replaced (match-data)))
	(if cscope-display-selections
	    (pop-to-buffer cscope-selections)
	  (switch-to-buffer cscope-selections))
	(goto-char selection-point)
	(forward-line)
	(setq selection-point (point))))
    ;; This is where (throw return sexpr) gets you
    ;; Leave the user on the last match operation
    (if cscope-display-selections
	(pop-to-buffer (nth 1 previous-loc))
      (switch-to-buffer (nth 1 previous-loc)))
    (cond ((= 0 skips) (message "Done."))
	  ((= 1 skips) (message "Done, one occurrence skipped."))
	  (t (message "Done, %d occurrences skipped." skips)))))

(defun cscope-find-regexp (regexp)
  "Find the given regexp.  If cscope-gnu-regexp is nil, use the egrep
style of regexp. Otherwise, use gnu emacs regexps."
  (interactive "sText string to find (regexp): ")
  ;; NOTE: if this changes, change the inline expansion in
  ;; cscope-query-replace.
  (cscope-find-generic "-6"
		       (if cscope-gnu-regexp
			   (cscope-regexp-convert regexp)
			 regexp)))

(defun cscope-regexp-convert (regexp)
  "Convert a gnu emacs regexp to an egrep regexp or vica versa. This
involves reversing the back slash quoted state of the three characters
'(', '|' and ')' where these occur outside the box ('[]')."
  ;; To convert a gnu emacs regexp to an egrep regexp, invert the back
  ;; slash quoted state of |, (, and ) when there occur outside of [].
  (let ((result "") (startpos 0)
	(len (length regexp)) (i 0)
	(lbracket ?[) (rbracket ?]) (lparen ?() (rparen ?))
	(state 'normal)
	char)
    (while (< i len)
      (setq char (elt regexp i))
      (cond ((eq state 'normal)
	     (cond ((char-equal ?\\ char) (setq state 'backslash))
		   ((char-equal lbracket char) (setq state 'firstbracket))
		   ((or (char-equal lparen char)
			(char-equal rparen char)
			(char-equal ?| char))
		    (setq result (concat result (substring regexp startpos i)
					 "\\"))
		    (setq startpos i))))
	    ((eq state 'backslash)
	     (if (or (char-equal lparen char)
		     (char-equal rparen char)
		     (char-equal ?| char))
		 (progn (setq result (concat result
					     (substring regexp
							startpos
							(- i 1))))
			(setq startpos i)))
	     (setq state 'normal))
	    ((eq state 'firstbracket)
	     (if (not (char-equal ?^ char))
	         (setq state 'inbracket)))
	    ((eq state 'inbracket)
	     (if (char-equal rbracket char)
	         (setq state 'normal))))
      (setq i (1+ i)))
    (if (not (eq state 'normal))
	(error "Illegal regexp '%s'" regexp))
    (concat result (substring regexp startpos))))

(defun cscope-visit-file ()
  "Do a find file on the file specified by the selection line.  If the
file is already being edited, push the point.  Move the point to the
line designated by cscope."
  (interactive)
  (let ((buffer (or cscope-selections
		    (cdr (assoc database cscope-databases)))))
    (if cscope-display-selections
	(pop-to-buffer buffer)
      (set-buffer buffer)))
  (beginning-of-line)
  (re-search-forward "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)")
  (let ((file (buffer-substring (match-beginning 1) (match-end 1)))
	(line (string-to-int (buffer-substring (match-beginning 3)
					       (match-end 3))))
	(database cscope-database)
	(selections cscope-selections))
    (if cscope-display-selections
	(find-file-other-window file)
      (find-file file))
    (setq cscope-selections selections)
    (if (/= (point-min) (point))
	(progn (push-mark)
	       (goto-char (point-min))))
    (goto-line line)))

(defun cscope-visit-next (count)
  "Do a find file on the file specified by the line after the
selection line.  If the file is already being edited, push the point.
Move the point to the line designated by cscope."
  (interactive "p")
  (let ((buffer (or cscope-selections
		    (cdr (assoc database cscope-databases)))))
    (if cscope-display-selections
	(pop-to-buffer buffer)
      (set-buffer buffer)))
  (save-restriction
    (narrow-to-region (point)
		      (save-excursion
			(if (search-forward cscope-selection-header nil 'end)
			    (forward-line -2))
			(point)))
    (if (or (/= (forward-line count) 0)
	    (not   (re-search-forward
		    "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)" nil t)))
	(progn
	  (forward-line -1)
	  (error "At end of selections"))))
  (let ((file (buffer-substring (match-beginning 1) (match-end 1)))
	(line (string-to-int (buffer-substring (match-beginning 3)
					       (match-end 3))))
	(database cscope-database)
	(selections cscope-selections))
    (if cscope-display-selections
	(find-file-other-window file)
      (find-file file))
    (setq cscope-selections selections)
    (if (/= (point-min) (point))
	(progn (push-mark)
	       (goto-char (point-min))))
    (goto-line line)))

(defun cscope-visit-previous (count)
  "Do a find file on the file specified by the line before the
selection line.  If the file is already being edited, push the point.
Move the point to the line designated by cscope."
  (interactive "p")
  (let ((buffer (or cscope-selections
		    (cdr (assoc database cscope-databases)))))
    (if cscope-display-selections
	(pop-to-buffer buffer)
      (set-buffer buffer)))
  (save-restriction
    (narrow-to-region (save-excursion
			(if (search-backward cscope-selection-header nil 'top)
			    (forward-line))
			(point))
		      (point))
    (if (/= (forward-line (- count)) 0)
	(error "At beginning of selections")))
  (if (not (re-search-forward
	    "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)" nil t))
      (error "No selections"))
  (let ((file (buffer-substring (match-beginning 1) (match-end 1)))
	(line (string-to-int (buffer-substring (match-beginning 3)
					       (match-end 3))))
	(database cscope-database)
	(selections cscope-selections))
    (if cscope-display-selections
	(find-file-other-window file)
      (find-file file))
    (setq cscope-selections selections)
    (if (/= (point-min) (point))
	(progn (push-mark)
	       (goto-char (point-min))))
    (goto-line line)))

(defun cscope-visit-kill ()
  "Do a find file on the file specified by the line after the
selection line, deleting the selection line. If the file is already
being edited, push the point. Move the point to the line designated by
cscope."
  (interactive)
  (let ((buffer (or cscope-selections
		    (cdr (assoc database cscope-databases)))))
    (if cscope-display-selections
	(pop-to-buffer buffer)
      (set-buffer buffer)))
  (save-restriction
    (narrow-to-region (point)
		      (save-excursion
			(if (search-forward cscope-selection-header nil 'end)
			    (forward-line -2))
			(point)))
    (if (or (/= (forward-line 1) 0)
	    (not   (re-search-forward
		    "^\\([^ ]*\\) \\([^ ]*\\) \\([^ ]*\\) \\(.*$\\)" nil t)))
	(progn
	  (forward-line -1)
	  (error "At end of selections"))))
  (forward-line -1)
  (kill-line 1)
  (cscope-visit-file))

(defun cscope-find-file (regexp)
  "Find the file given by the regular expression"
  (interactive "sFile (regexp) to find: ")
  (cscope-find-generic "-7" regexp))

(defun cscope-find-files-including (file)
  "Find files including this one"
  (interactive "sFind files including (file): ")
  (cscope-find-generic "-8" file))

(defun cvsedit ()
  "CvsEdit the file in the current buffer"
  (interactive)
  (let ((buf (current-buffer))
	(database cscope-database)
	(selections cscope-selections)
	(file (file-name-nondirectory (buffer-file-name)))
	(dir (file-name-directory (buffer-file-name)))
	(cvs (get-buffer-create "*CVS*")))
    (switch-to-buffer cvs)
    (goto-char (point-max))
    (cd dir)
    (call-process "chmod" nil cvs t "+w" file)
    (switch-to-buffer buf)
    (if buffer-read-only
	(revert-buffer nil t))
    (setq cscope-database database)
    (setq cscope-selections selections)))

(defun cvsrevert (force)
  "CvsRevert the file in the current buffer. With arg, forces revert even if
the buffers differ."
  (interactive "P")
  (let ((buf (current-buffer))
	(database cscope-database)
	(selections cscope-selections)
	(file (file-name-nondirectory (buffer-file-name)))
	(dir (file-name-directory (buffer-file-name)))
	(cvs (get-buffer-create "*CVS*")))
    (switch-to-buffer cvs)
    (goto-char (point-max))
    (cd dir)
    (if (and (/= (call-process "cvs" nil cvs t "diff" "-c" file) 0)
	     (not force)
	     (not (yes-or-no-p
		   "File has been modified, revert anyway? ")))
	(progn	(switch-to-buffer buf)
		(error "File has changed, not reverted")))
    (call-process "chmod" nil cvs t "-w" file)
    (switch-to-buffer buf)
    (if (not buffer-read-only)
	(revert-buffer nil t))
    (setq cscope-database database)
    (setq cscope-selections selections)))

;;; ****** should eventually be done with a special mode, not recursive edit
(defun ccsput (prompt)
  "CcsPut the file in the current buffer. With arg, prompt for comment leader"
  (interactive "P")
  (let ((buf (current-buffer))
	(database cscope-database)
	(selections cscope-selections)
	(file (file-name-nondirectory (buffer-file-name)))
	(dir (file-name-directory (buffer-file-name)))
	(ccs (get-buffer-create "*CCS*"))
	(ccslog (get-buffer-create "*CCS log message*"))
	(leader (if prompt (read-string "Comment Leader: ") nil))
	log)
    (switch-to-buffer-other-window ccslog)
    (erase-buffer)
    (command-execute 'text-mode)
    (setq fill-column 64)
    (recursive-edit)
    (setq log (buffer-string))
    (switch-to-buffer ccs)
    (goto-char (point-max))
    (cd dir)
    (if leader
	(call-process "ccsput" nil ccs t "-c" leader "-m" log file)
      (call-process "ccsput" nil ccs t "-m" log file))
    (switch-to-buffer buf)
    (find-alternate-file file)
    (setq cscope-database database)
    (setq cscope-selections selections)))

(defun insert-ifdef (min max &optional surround)
  "Insert Ifdef sequence above current line, using cscope-ifdef as the ifdef 
token . With arg, surround the region."
  (interactive "r\nP")
  (if surround
      (goto-char max))
  (beginning-of-line)
  (insert "#else\t/* ")
  (insert cscope-ifdef)
  (insert " */\n#endif\t/* ")
  (insert cscope-ifdef)
  (insert " */\n")
  (if surround
      (goto-char min)
    (forward-line -2))
  (beginning-of-line)
  (insert "#ifdef ")
  (insert cscope-ifdef)
  (insert "\n"))

(defun cscope-help ()
  "Here are the cscope functions and their default key binding.
\\[cscope-find-symbol] FIND this SYMBOL
\\[cscope-find-global-definition] FIND this global DEFINITION
\\[cscope-find-functions-called] FIND functions CALLED by this function
\\[cscope-find-functions-using] FIND functions USING this function
\\[cscope-find-assignments] FIND ASSIGNMENTS to this symbol 
\\[cscope-query-replace] QUERY replace this REGEXP
\\[cscope-find-regexp] FIND this REGEXP
\\[cscope-find-file] FIND this FILE
\\[cscope-find-files-including] FIND files #INCLUDING this file
\\[cscope-visit-file] VISIT FILE described by current line
\\[cscope-visit-next] VISIT file described by NEXT line
\\[cscope-visit-previous] VISIT file described by PREVIOUS line
\\[cscope-visit-kill] Like VISIT next, but after KILLING current line
\\[cvsedit] CvsEdit the file in this buffer
\\[cvsrevert] CvsRevert the file in this buffer
\\[ccsput] CcsPut the file in this buffer-with arg, prompt for comment leader
\\[insert-ifdef] insert Ifdef <cscope-ifdef>.  With arg, surround region.
\\[cscope-help] This function"
  (interactive)
  (describe-function 'cscope-help))

(global-set-key "\M-\C-xfs" 'cscope-find-symbol) ; 0
(global-set-key "\M-\C-xfd" 'cscope-find-global-definition) ; 1
(global-set-key "\M-\C-xfc" 'cscope-find-functions-called)	; 2
(global-set-key "\M-\C-xfu" 'cscope-find-functions-using) ; 3 (calling)
;; 4 was once cscope-find-text-string
;;(global-set-key "\M-\C-xft" 'cscope-find-text-string) ; 4 (text-string)
(global-set-key "\M-\C-xfa" 'cscope-find-assignments) ; 4
(global-set-key "\M-\C-xqr" 'cscope-query-replace)    ; 5 (change grep pattern)
(global-set-key "\M-\C-xfr" 'cscope-find-regexp) ; 6 (find egrep pattern)
(global-set-key "\M-\C-xff" 'cscope-find-file) ; 7 
(global-set-key "\M-\C-xfi" 'cscope-find-files-including) ; 8
(global-set-key "\M-\C-xvf" 'cscope-visit-file) ; visit selection
(global-set-key "\M-\C-xvn" 'cscope-visit-next) ; visit next selection
(global-set-key "\M-\C-xvp" 'cscope-visit-previous) ; visit previous selection
(global-set-key "\M-\C-xvk" 'cscope-visit-kill) ; kill current line, visit next
(global-set-key "\M-\C-x?" 'cscope-help)

(global-set-key "\M-\C-xce" 'cvsedit)
(global-set-key "\M-\C-xcu" 'cvsrevert)
(global-set-key "\M-\C-xcp" 'ccsput)

(global-set-key "\M-\C-xif" 'insert-ifdef)
;;; Next s-expr must be last in this file!
(run-hooks 'cscope-load-hook)
