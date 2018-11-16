;;; flutter.el --- Tools for working with Flutter SDK -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:

(require 'comint)

(defconst flutter-buffer-name "*Flutter*")

(defvar flutter-sdk-path nil
  "Path to Flutter SDK.")

(defconst flutter-interactive-keys-alist
  '(("r" . hot-reload)
    ("R" . hot-restart)
    ("h" . help)
    ("w" . widget-hierarchy)
    ("t" . rendering-tree)
    ("L" . layers)
    ("S" . accessibility-traversal-order)
    ("U" . accessibility-inverse-hit-test-order)
    ("i" . inspector)
    ("p" . construction-lines)
    ("o" . operating-systems)
    ("P" . performance-overlay)
    ("s" . screenshot)
    ("q" . quit)))

(defvar flutter-mode-map
  (nconc (make-sparse-keymap) comint-mode-map)
  "Basic mode map for `flutter-run'.")

(defun flutter--make-interactive-function (key name)
  "Generate a definition for function with NAME to send KEY to a `flutter` process."
  `(defun ,name ()
     (interactive)
     (flutter--send-command ,key)))

(defmacro flutter-register-key (key name)
  "Register a KEY press with associated NAME recognized by \
`flutter` in interactive mode.  A function `flutter-NAME' will \
be created that sends the key to the `flutter` process."
  (let ((tmpname (make-symbol "fn-name")))
    `(let ((,tmpname (intern (concat "flutter-" (symbol-name ,name))))
           (func ,(flutter--make-interactive-function key tmpname)))
       (define-key flutter-mode-map ,key func)
       (message "Defined %s" ,tmpname))))

(macroexpand '(flutter-register-key "r" blah))
(flutter-register-key "r" blah)
(dolist (item flutter-interactive-keys-alist)
  (let ((key (car item))
        (name (cdr item)))
    (flutter-register-key key name)))

(defun flutter-build-command ()
  "Build flutter command to execute."
  (concat (or flutter-sdk-path "") "flutter"))

(defun flutter-get-project-root ()
  "Find the root of the current project."
  (locate-dominating-file (pwd) "pubspec.yaml"))

(defmacro flutter--from-project-root (&rest body)
  "Execute BODY with the `default-directory' set to the project root."
  `(let ((root (flutter-get-project-root)))
    (if root
        (let ((default-directory root))
          ,@body)
      (error "Root of Flutter project not found"))))

(defmacro flutter--with-run-proc (&rest body)
  "Execute BODY while ensuring an inferior `flutter` process is running."
  `(flutter--from-project-root
    (let* ((buffer (get-buffer-create flutter-buffer-name))
           (alive (flutter--running-p)))
      (unless alive
        (make-comint-in-buffer "Flutter" buffer (flutter-build-command) nil "run"))
      (with-current-buffer buffer
        (unless (derived-mode-p 'flutter-mode)
          (flutter-mode)))
      ,@body)))

(defun flutter-run ()
  "Execute `flutter run` inside Emacs."
  (interactive)
  (flutter--with-run-proc
   (pop-to-buffer-same-window buffer)))

(defun flutter-run-or-hot-reload ()
  "Start `flutter run` or hot-reload if already running."
  (interactive)
  (if (flutter--running-p)
      (flutter-hot-reload)
    (flutter-run)))

(defun flutter--running-p ()
  "Return non-nil if an inferior `flutter` process is already running."
  (comint-check-proc flutter-buffer-name))

(defun flutter--send-command (command)
  "Send COMMAND to a running Flutter process."
  (flutter--with-run-proc
   (let ((proc (get-buffer-process flutter-buffer-name)))
     (comint-send-string proc command))))

(defun flutter--initialize ()
  "Helper function to initialize Flutter."
  (setq comint-process-echoes nil))

(define-derived-mode flutter-mode comint-mode "Flutter"
  "Major mode for `flutter-run'.

\\{flutter-mode-map}"
  (setq comint-prompt-read-only t)
  ;; (set (make-local-variable 'paragraph-separate) "\\'")
  ;; (set (make-local-variable 'font-lock-defaults) '(flutter-font-lock-keywords t))
  ;; (set (make-local-variable 'paragraph-start) flutter-prompt-regexp)
  )

(add-hook 'flutter-mode-hook #'flutter--initialize)

(provide 'flutter)
;;; flutter.el ends here
