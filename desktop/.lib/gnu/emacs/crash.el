;;; This file is mostly glue holding together ostdb and shell commands
;;; in a way that allows one to just call crash on an image, and have
;;; the correct thing happen.

(require 'gud)
(require 'shell)

;;;###autoload
(defun crash (unix dump &optional crash)
  "Run crash on program UNIX with memory dump DUMP. If CRASH is
specified, it is the binary program to use for crash. This program runs
ostdb in open socket mode and starts crash up in nub mode and makes sure
they talk to each other."
  (interactive "funix binary
		fmemory dump file
		Fcrash program")
  (ostdb (concat "ostdb -rm -open_socket " (expand-file-name unix)))
  (process-send-string (get-buffer-process (current-buffer)) "run\n")
  (let ((ostdb (get-buffer-process (current-buffer)))
	(crash-socket
	 (save-excursion
	   (search-backward "-d ")
	   (forward-char 3)
	   (let (start (point))
	     (search-forward " ")
	     (backward-char)
	     (buffer-substring start (point))))))
    (start-process-shell-command "crash" (generate-new-buffer "*crash*")
				 (if crash
				     (expand-file-name crash)
				   "crash")
				 "-n" crash-socket dump unix)
    
    (process-send-string ostdb "y\n"))

  (run-hooks 'crash-mode-hook))

;;; function to call crash from command line.  You'll need two
;;; commands in your .emacs file as follows:
;;;	(setq command-switch-alist (cons (cons "-crash" 'crash-switch)
;;;				 	 command-switch-alist))
;;;	(autoload 'crash-switch "crash" "CRASH mode, based on shell" t)
;;; To use, call emacs like so:
;;;	emacs -crash unix dump {<optional crash>}
(defun crash-switch (switch)
  (let ((unix (expand-file-name (car command-line-args-left)))
	(dump (expand-file-name (nth 1 command-line-args-left)))
	(crash (expand-file-name (nth 2 command-line-args-left))))
    (crash unix dump crash))
  (setq command-line-args-left (nthcdr 3 command-line-args-left))
  (run-hooks 'crash-cmdline-hook))
