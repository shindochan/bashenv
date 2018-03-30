(require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "http://melpa-stable.milkbox.net/packages/") t)

(package-initialize)

(require 'python)
(require 'go-mode)

(global-set-key [?\A-+] #'text-scale-increase)
(global-set-key [?\A--] #'text-scale-decrease)
(global-set-key [?\s-+] #'text-scale-increase)
(global-set-key [?\s--] #'text-scale-decrease)
(defun my-shell-mode-hook ()
  (add-hook 'comint-output-filter-functions 'python-pdbtrack-comint-output-filter-function t))

(add-hook 'shell-mode-hook 'my-shell-mode-hook)

(setq-default cursor-type 'box)
;(set-frame-font "-bitstream-Courier 10 Pitch-normal-normal-normal-*-25-*-*-*-m-0-iso10646-1")
(set-frame-font "courier-18" nil t)
(setq load-path
      (cons (expand-file-name "~/.lib/gnu/emacs")
	    (cons (expand-file-name "/usr/share/emacs/24.3/lisp/obsolete") load-path)))
(add-to-list 'load-path (expand-file-name "~/github/rust-mode"))

(setq auto-mode-alist (cons (cons "\\.otl\\'" 'outline-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.n\\'" 'nroff-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.t\\'" 'nroff-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.sh\\'" 'perl-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.tex\\'" 'tex-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.w\\'" 'c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.x\\'" 'c-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.s\\'" 'lisp-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "TODO\\'" 'org-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.pyx\\'" 'python-mode) auto-mode-alist))
(setq auto-mode-alist (cons (cons "\\.rs\\'" 'rust-mode) auto-mode-alist))
(setq command-switch-alist (cons (cons "-cscope" 'cscope-switch)
				 command-switch-alist))
(setq command-switch-alist (cons (cons "-ccsput" 'ccsput-switch)
				 command-switch-alist))
(setq command-switch-alist (cons (cons "-ostdb" 'ostdb-switch)
				 command-switch-alist))
(setq command-switch-alist (cons (cons "-primary" 'primary-switch)
				 command-switch-alist))
(setq command-switch-alist (cons (cons "-mud" 'mud-switch)
				 command-switch-alist))
(setq command-switch-alist (cons (cons "-crash" 'crash-switch)
				 command-switch-alist))
;----------------------
; If you wish to avoid visiting the same file in two buffers under
; different names, set the variable `find-file-existing-other-name'
; non-nil.  Then `find-file' uses the existing buffer visiting the file

(setq find-file-existing-other-name t)

(defun primary-switch (switch)
;  (cscope (expand-file-name "~/system/tos/usr/cscope.out"))
;  (delete-other-windows)
;  (mh-rmail)
  (find-file "~/TODO")
  (org-mode)
  (server-start)
  )


(global-set-key "\C-cg" 'goto-line)
(add-hook 'text-mode-hook '(lambda () (auto-fill-mode 1)))
(add-hook 'fundamental-mode-hook '(lambda () (auto-fill-mode 1)))
;(add-hook 'cscope-load-hook (function (lambda ()
;				   (setq cscope-display-selections nil))))
(add-hook 'cscope-cmdline-hook (function (lambda ()
			      (switch-to-buffer "*cscope-selections*"))))
(autoload 'google-make-newline-indent "google-c-style" "Standardization of C style")
(autoload 'google-set-c-style "google-c-style" "Standardization of C style")
(autoload 'c-mode-custom "my_cmode" "Customization of C style")
(autoload 'web-start-module "os-tools"
  "Insert a new text module at point into a web file" t)
(autoload 'cscope "cscope" "cscope program cross reference" t)
(autoload 'cscope-switch "cscope" "cscope program cross reference" t)
(autoload 'ccsput-switch "cscope" "Change Control System" t)
(autoload 'ostdb "ostdb" "OSTDB mode, based on gud" t)
(autoload 'ostdb-switch "ostdb" "OSTDB mode, based on gud" t)
(autoload 'crash "crash" "CRASH mode, based on gud" t)
(autoload 'crash-switch "crash" "CRASH mode, based on gud" t)
(autoload 'cweb-mode "cweb-mode" "web mode, C++ and LaTex" t)
(autoload 'web-c++-mode "web-c++-mode" nil t)
(autoload 'rust-mode "rust-mode" nil t)

(add-hook 'c-mode-common-hook 'google-set-c-style)
(add-hook 'c-mode-common-hook 'google-make-newline-indent)
(add-hook 'c-mode-common-hook 'c-mode-custom)
(add-hook 'c++-mode-hook 'google-set-c-style)
(add-hook 'c++-mode-hook 'google-make-newline-indent)
(add-hook 'c++-mode-hook 'c-mode-custom)

(global-set-key "\M-s" 're-search-forward)
(global-set-key "\M-r" 're-search-backward)

;(defun browse-psx ()
;  "Cscope to the Dynix/psx sources with the gnu terminal emulator"
;  (interactive)
;  (let* ((buffer (get-buffer-create  "*cscope*"))
;	 (proc (get-buffer-process buffer)))
;    (if (not proc)
;	(terminal-emulator "*cscope*" "cscope"
;			   (list "-d" "-f" "/bruces/cscope/dV.out" "-i"
;				 "/bruces/cscope/dV.files")))))

;(global-set-key "\C-c\C-c" 'browse-psx)

(put 'narrow-to-region 'disabled nil)

;(defun find-mailbug () "Find file on the next mailbug and move cursor to it"
;  (interactive)
;  (let* ((first (progn (re-search-forward "rn.edit ") (point)))
;	 (last (progn (re-search-forward "[ \t\n]") (backward-char) (point)))
;	 (fn (buffer-substring first last)))
;    (find-file-other-window (concat "/ccs/pts/work/sw/" fn))))

;(global-set-key "f" 'find-mailbug)

;(defun mailbug-not-needed () "Mark the mailbug the cursor is in as not needed"
;  (interactive)
;  (let* ((first (progn (re-search-backward "^rn.edit")
;		      (beginning-of-line 2)
;		      (point)))
;	 (last (progn (re-search-forward "^@@eof")
;		      (beginning-of-line)
;		      (point))))
;    (delete-region first last)
;    (goto-char first)
;    (insert "NOT NEEDED\n")))
;
;(global-set-key "n" 'mailbug-not-needed)

;(defun mailbug-make-m-command ()
;  "Take a mailbug name (on a line by itself) and create an m-command for it"
;  (interactive)
;  (beginning-of-line)
;  (insert "m \\\n")
;  (let* ((first (progn (beginning-of-line) (point)))
;	 (last (progn (end-of-line) (point))))
;    (goto-char last)
;    (insert " \\\n" (buffer-substring first last) " \\\n <<EOF\n\nEOF\n")
;    (forward-line -2)
;    (find-file-other-window (concat "/ccs/pts/work/sw/"
;				    (buffer-substring first last)))))

;(global-set-key "m" 'mailbug-make-m-command)

;;
;; date function (useful for logging times in job notes, etc ...)
;; from fubar
(defun current-date-and-time ()
  "Insert the current date and time (as given by UNIX date) at dot."
  (interactive)
  (call-process "date" nil t nil))
;;
;; ISO 8601 date and time
(defun ISO-date-and-time ()
  "Insert the ISO 8601 date and time at dot."
  (interactive)
  (call-process "date" nil t nil "+%a %F T %T %Z"))

(global-set-key "\C-xt" 'ISO-date-and-time)

;(if (= '19 (string-to-int emacs-version))
;    (progn
;      (setq initial-frame-alist '((horizontal-scroll-bars)
;				  (vertical-scroll-bars)
;				  (menu-bar-lines . 0) (minibuffer . t)))
;      (setq default-frame-alist initial-frame-alist)
;      (if window-system
;          (progn
;            (menu-bar-mode -1)
;            (scroll-bar-mode -1)
;            (define-key global-map [C-return] [13])
;            (global-unset-key "\C-z")))))

;---------------------------
; Customized Initialization of sendmail.el (M-x mail)
;
; If you are copying my .emacs, you SHOULD edit this section.
;
; For some reason, the "Fcc:" mechanism results in a carbon copy with an
; incorrect time stamp.  The "Bcc:" mechanism works better
;
(add-hook 'c++-mode-hook
      (function
       (lambda ()
	 (c-mode-custom))))

(add-hook 'web-c++-mode-hook
      (function
       (lambda ()
	 (run-hooks 'LaTeX-mode-hook)
	 (run-hooks 'c++-mode-hook)
)))

(add-hook 'TeX-mode-hook
      (function
       (lambda ()
	 (require 'tex-stuff)
	 (auto-fill-mode 1))))

(add-hook 'LaTeX-mode-hook
      (function
       (lambda ()
	 (require 'tex-mode)
	 (require 'tex-stuff)
	 (auto-fill-mode 1)
	 (run-hooks 'TeX-mode-hook))))

(add-hook 'cweb-mode-hook
      (function
       (lambda ()
	 (require 'tex-mode)
	 (require 'tex-stuff)
	 (require 'cc-mode)
;	 (local-set-key "m" 'web-start-module)
;	 (local-set-key "s" 'web-bold-word)
;	 (local-set-key "r" 'web-renumber)
;	 (local-set-key "w" 'webfile-header-insert)
;	 (local-set-key "o" 'web-insert-outputfiles)
;	 (local-set-key "t" 'web-insert-test)
;	 (local-bind-to-key "TeX-insert-quote" "\"")
	 (run-hooks 'LaTeX-mode-hook)
	 (run-hooks 'c++-mode-hook)
)))
(message ".emacs line 208")

(if window-system
  (progn
    (defvar sun-esc-bracket t) ;; Enables cursor keys
    (setq visible-bell 1)
    (setq transient-mark-mode 1)
    (setq highlight-nonselected-windows 'nil)	; current window only
    (set-face-foreground 'highlight "green")
    (set-face-background 'highlight "black")
    (set-face-background 'mode-line "MediumSeaGreen")
    (set-face-foreground 'mode-line "black")

;    (setq minibuffer-frame-alist
;      '((reverse . t)
;	(top . 854) (left . 584) (width . 80) (height . 1)
;	(minibuffer . only)
;       ))
    (setq initial-frame-alist
      '((reverse . t)
	(top . 0) (left . 757) (width . 80) (height . 47)
;	(minibuffer . nil)
       ))
;	(font . "-schumacher-clean-medium-r-normal--*-140-*-*-c-*-*-1")
    (setq default-frame-alist
      '(;(reverse . t) 
	(width . 80) (height . 47)
;	(minibuffer . nil)
;	(font . "-schumacher-clean-medium-r-normal--*-140-*-*-c-*-*-1")
	))

;    (load "stig-paren.el")
;    (load "mouse-sel.el")
;    (scroll-bar-mode nil)
;    (menu-bar-mode nil)
    )
)

; this sets initial window to inverse
;;(set-foreground-color "white")
;;(set-background-color "black")
;;(setq inverse-video t)

;;------------------------------------------------------------------
;; gnus setup

(autoload 'gnus "gnus" "Read network news." t)
(autoload 'gnus-post-news "gnuspost" "Post a news." t)

;;------------------------------------------------------------------
;; miscellaneous window functions

(if window-system
  (progn

(defun kill-buffer-and-delete-frame()
  (interactive)
  (kill-buffer (buffer-name))
  (delete-frame))

)) ;; if window-system

;;------------------------------------------------------------------
;; miscellaneous non-window functions

(defun web-bold-word nil (interactive)
  (forward-char 1)
  (backward-word 1)
  (insert "|")
  (forward-word 1)
  (insert "|"))

(defun web-renumber (num) (interactive "*p")
  (save-excursion
    (let (modnum)
      (goto-char (point-min))
      (while (re-search-forward "^@\\([0-9]+\\)" nil t)
	(setq modnum (string-to-number
		      (buffer-substring (match-beginning 1) (match-end 1))))
	(if (and (= num 1) (> modnum num))
	    (setq num modnum))
	(if (not (= num modnum))
	    (progn (kill-region (match-beginning 0) (match-end 0))
		   (insert "@" (int-to-string num))))
	(setq num (+ num 1))))))

;;------------------------------------------------------------------
;; shell command stuff

(defun shell-cmd (command &rest args)
  "helper"
  (cond
   ((or (null args) (null (car args)))
    (shell-command-on-region (point) (point) command nil))
   (t (shell-cmd (concat command " " (car args)) (cdr args)))))
(message ".emacs line 302")

(defun psaux ()
  "run ps -aux"
  (interactive)
  (shell-cmd "ps aux"))

(defun uptime ()
  "run uptime"
  (interactive)
  (shell-cmd "uptime" ""))

(defun top ()
  "run top"
  (interactive)
  (shell-cmd "top"))

(defun tnm (file)
  "run tnm on an object file"
  (interactive "fFile: ")
  (shell-cmd "tnm " file))

(defun rlog (file)
  "run rlog on a file"
  (interactive "FFile: ")
  (shell-cmd "rlog" file))

(defun cvslog (file)
  "run cvs log on a file"
  (interactive "FFile: ")
  (shell-cmd "cvs log" file))

(defun cvsdiff (file)
  "run cvs diff on a file"
  (interactive "FFile: ")
  (shell-cmd "cvs diff" file))

; empty kill ring to save space
(defun empty-kill-ring ()
  "empty the kill ring & garbage collect (to save some space)"
  (interactive)
  (let ((len (length kill-ring))
	(mem-limit 0)
	(mem-whole 0)
	(mem-frac  0))
    (setq kill-ring nil)
    (garbage-collect)
    (setq mem-limit (memory-limit))
    (setq mem-whole (/ mem-limit 1024))
    (setq mem-frac  (/ (- mem-limit (* mem-whole 1024)) 10))
    (message "kill-ring length was %d,  memory: %d.%d MB"
	     len mem-whole mem-frac)))


;; Start up the emacs server
;;(load "/usr/local/lib/xemacs-19.15/lisp/packages/gnuserv.el")

;;(setq gnuserv-frame (selected-frame))	; Uncomment to get new frame per edit
  
;;(defun server-finish ()
;;   "Finish server buffer, kill it, and get back to where you were."
;;   (interactive)
;;   (let ((oldbuf (buffer-name))
;;	 (file (buffer-file-name)))
;;     (server-edit)
;;    (kill-buffer oldbuf)
;;     (setq file (concat file "~"))
;;     (if (file-exists-p file)
;;	 (delete-file file))))

(autoload 'mud "mud" "Jace Mogill's MUD mode." t)
(autoload 'mud-switch "mud" "Jace Mogill's MUD mode." t)


(put 'eval-expression 'disabled nil)

(put 'upcase-region 'disabled nil)

(put 'downcase-region 'disabled nil)

(add-hook 'org-mode-hook 'turn-on-font-lock)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)
(global-set-key "\C-cl" 'org-store-link)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-names-vector
   ["#212526" "#ff4b4b" "#b4fa70" "#fce94f" "#729fcf" "#e090d7" "#8cc4ff" "#eeeeec"])
 '(custom-enabled-themes (quote (wheatgrass)))
 '(focus-follows-mouse t))
(message ".emacs line 397")
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(setq-default indent-tabs-mode nil)
(setq-default c-basic-offset 4)
(setq-default show-trailing-whitespace t)
(add-to-list 'load-path "~/.emacs.d/jdee-2.4.1/lisp")
(load "jde")
