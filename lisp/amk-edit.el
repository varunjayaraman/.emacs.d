;;; amk-edit.el --- Custom editing commands

;; Copyright (C) 2017-2020 Aaron Madlon-Kay

;; Author: Aaron Madlon-Kay
;; Version: 0.1.0
;; URL: https://github.com/amake/.emacs.d
;; Package-Requires: ((emacs "24"))

;;; Commentary:

;; Custom editing commands, including Eclipse-like line moving; see
;; https://www.emacswiki.org/emacs/MoveLine

;;; Code:

(defmacro amk-edit--save-column (&rest body)
  "Note current column, do BODY, then restore column."
  (let ((tmp (make-symbol "col")))
    `(let ((,tmp (current-column)))
       ,@body
       (move-to-column ,tmp))))

(defun amk-edit-move-lines-up ()
  "Move the current line or region up by one line."
  (interactive)
  (save-current-buffer
    (if (use-region-p)
        (amk-edit--move-lines-impl t)
      (amk-edit-move-line-up))))

(defun amk-edit--move-lines-impl (&optional up)
  "Move the current region up by one line.  Set UP to true to go up."
  (let (deactivate-mark
        (rstart (region-beginning))
        (rend (region-end)))
    (goto-char rstart)
    (let ((start (line-beginning-position)))
      (goto-char rend)
      (let* ((end (if (= (current-column) 0)
                         rend
                         (line-beginning-position 2)))
             (text (buffer-substring start end)))
        (delete-region start end)
        (forward-line (if up -1 1))
        (push-mark)
        (insert text)))))

(defun amk-edit-move-line-up ()
  "Swap the current line with the previous one."
  (interactive)
  (amk-edit--save-column
   (transpose-lines 1)
   (forward-line -2)))

(defun amk-edit-move-lines-down ()
  "Move the current line or region down by one line."
  (interactive)
  (save-current-buffer
    (if (use-region-p)
        (amk-edit--move-lines-impl)
      (amk-edit-move-line-down))))

(defun amk-edit-move-line-down ()
  "Swap the current line with the next one."
  (interactive)
  (amk-edit--save-column
   (forward-line 1)
   (transpose-lines 1)
   (forward-line -1)))

(defun amk-edit-copy-file-name-to-clipboard ()
  "Copy the current buffer file name to the clipboard."
  ;; https://stackoverflow.com/a/9414763/448068
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (kill-new filename)
      (message "Copied buffer file name '%s' to the clipboard." filename))))

(defun amk-edit-split-buffer-chars (&optional delimiter)
  "Split the buffer so that each char past point is separated by DELIMITER.

By default DELIMITER is a line feed (\\n).  Invoke with a prefix
to be prompted for the delimiter."
  (interactive (list (if (consp current-prefix-arg)
                         (read-string "Delimiter: ")
                       "\n")))
  (while (re-search-forward "\\(.\\)" nil t)
    (replace-match (format "\\1%s" delimiter))))

(provide 'amk-edit)
;;; amk-edit.el ends here
