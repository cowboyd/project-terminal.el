;;; project-terminal.el --- Per-project terminal management  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Charles Lowell

;; Author: Charles Lowell
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (project "0.6.0"))
;; Keywords: terminals, projects, convenience
;; URL: https://github.com/cowboyd/project-terminal

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Per-project terminal management for Emacs.  Create and manage
;; multiple terminal instances scoped to each project, with support
;; for different terminal backends (vterm, eshell, shell, etc.).

;;; Code:

(require 'project)

(defgroup project-terminal nil
  "Per-project terminal management."
  :group 'project
  :prefix "project-terminal-")

(defcustom project-terminal-height 0.25
  "Height of the terminal drawer as a fraction of frame height."
  :type 'float
  :group 'project-terminal)

(defcustom project-terminal-side 'bottom
  "Which side of the frame to display the terminal drawer."
  :type '(choice (const :tag "Bottom" bottom)
                 (const :tag "Top" top)
                 (const :tag "Left" left)
                 (const :tag "Right" right))
  :group 'project-terminal)

(defvar project-terminal--buffers (make-hash-table :test 'equal)
  "Map of project root strings to their terminal drawer buffers.")

(defun project-terminal--key ()
  "Return the project key for the current context.
Returns the project root directory, or \"*global*\" when no project."
  (if-let ((proj (project-current)))
      (project-root proj)
    "*global*"))

(defun project-terminal--buffer ()
  "Get or create the drawer buffer for the current project."
  (let* ((key (project-terminal--key))
         (buf (gethash key project-terminal--buffers)))
    (if (and buf (buffer-live-p buf))
        buf
      (let ((buf (get-buffer-create (format "*project-terminal: %s*" key))))
        (with-current-buffer buf
          (setq mode-line-format nil))
        (puthash key buf project-terminal--buffers)
        buf))))

(defun project-terminal--window ()
  "Return the visible drawer window for the current project, or nil."
  (let ((buf (gethash (project-terminal--key) project-terminal--buffers)))
    (when (and buf (buffer-live-p buf))
      (get-buffer-window buf))))

(defun project-terminal--show (buf)
  "Display BUF in a side window drawer."
  (display-buffer-in-side-window buf
    `((side . ,project-terminal-side)
      (slot . 0)
      (window-height . ,project-terminal-height)
      (window-parameters
       (no-delete-other-windows . t)))))

;;;###autoload
(defun project-terminal-show ()
  "Show the terminal drawer for the current project.
If no project is active, show the global drawer.
No-op if the drawer is already visible."
  (interactive)
  (unless (project-terminal--window)
    (project-terminal--show (project-terminal--buffer))))

;;;###autoload
(defun project-terminal-hide ()
  "Hide the terminal drawer for the current project.
No-op if the drawer is not visible."
  (interactive)
  (when-let ((win (project-terminal--window)))
    (delete-window win)))

;;;###autoload
(defun project-terminal-toggle ()
  "Toggle the terminal drawer for the current project."
  (interactive)
  (if (project-terminal--window)
      (project-terminal-hide)
    (project-terminal-show)))

(provide 'project-terminal)
;;; project-terminal.el ends here
