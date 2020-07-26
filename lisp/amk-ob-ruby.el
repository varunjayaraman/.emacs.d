;;; amk-ob-ruby.el --- Customization for ob-ruby

;; Copyright (C) 2020 Aaron Madlon-Kay

;; Author: Aaron Madlon-Kay
;; Version: 0.1.0
;; URL: https://github.com/amake/.emacs.d
;; Package-Requires: ((emacs "24.4"))

;; Package-Requires:

;;; Commentary:

;; Allow customizing the Ruby executable in an org-babel source block by
;; specifying the header argument ":cmd".  You can also put it in a drawer:
;;
;;   :PROPERTIES:
;;   :header-args:ruby: :cmd "bundle exec ruby"
;;   :end:
;;
;; If executing remotely, note that you will probably want to set up Tramp to
;; respect the remote host's PATH:
;;
;;   (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
;;
;; Putting this code in its own feature was an attempt to get it to work nicely
;; with ob-async (so it could be `require'd from the
;; `ob-async-pre-execute-src-block-hook' and thus take effect in the forked
;; process) but it doesn't seem to work.


;;; Code:

(require 'ob-ruby)

(defun amk-ob-ruby-custom-command (old-func &rest args)
  "Advise `org-babel-execute:ruby' to allow customizing the Ruby command."
  (let* ((params (cadr args))
         (cmd (cdr (assq :cmd params)))
         (org-babel-ruby-command (or cmd org-babel-ruby-command)))
    (apply old-func args)))

(advice-add #'org-babel-execute:ruby :around #'amk-ob-ruby-custom-command)

(provide 'amk-ob-ruby)
;;; amk-ob-ruby.el ends here