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

(require 'seq)
(require 'eshell)
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

(defvar project-terminal--projects (make-hash-table :test 'equal)
  "Map of project keys to their terminal state.
Each value is a plist (:tabs :active) where :tabs is a list of
buffers and :active is the currently displayed buffer.")

(defun project-terminal--key ()
  "Return the project key for the current context.
Returns the project root directory, or \"*global*\" when no project."
  (if-let ((proj (project-current)))
      (project-root proj)
    "*global*"))

(defun project-terminal--state ()
  "Get or create the terminal state for the current project.
Returns a plist (:tabs :active), creating an initial eshell if needed.
Dead buffers are removed from the tab list."
  (let* ((key (project-terminal--key))
         (state (or (gethash key project-terminal--projects)
                    (let ((new (list :tabs nil :active nil)))
                      (puthash key new project-terminal--projects)
                      new)))
         (live (or (seq-filter #'buffer-live-p (plist-get state :tabs))
                   (list (project-terminal--make-tab key)))))
    (plist-put state :tabs live)
    (unless (memq (plist-get state :active) live)
      (plist-put state :active (car live)))
    state))

(defun project-terminal--make-tab (key)
  "Create an eshell buffer for project KEY and add it to the state."
  (let* ((state (gethash key project-terminal--projects))
         (tabs (and state (plist-get state :tabs)))
         (buf (generate-new-buffer (format "*project-terminal: %s*" key))))
    (with-current-buffer buf
      (eshell-mode)
      (setq mode-line-format nil)
      (tab-line-mode 1)
      (setq tab-line-format
            '((:eval (project-terminal--tab-line)))))
    (when state
      (plist-put state :tabs (append tabs (list buf))))
    buf))

;;;###autoload
(defun project-terminal-add ()
  "Create a new terminal tab for the current project and switch to it."
  (interactive)
  (let* ((key (project-terminal--key))
         (state (or (gethash key project-terminal--projects)
                    (let ((new (list :tabs nil :active nil)))
                      (puthash key new project-terminal--projects)
                      new)))
         (buf (project-terminal--make-tab key))
         (win (or (project-terminal--window)
                  (project-terminal--show buf))))
    (plist-put state :active buf)
    (set-window-buffer win buf)
    (select-window win)
    (goto-char (point-max))))

(defvar project-terminal--add-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab-line mouse-1]
                (lambda (&rest _)
                  (interactive)
                  (project-terminal-add)))
    map)
  "Keymap for the add button in the tab line.")

(defun project-terminal--tab-line ()
  "Return the tab line for the terminal drawer."
  (let* ((state (project-terminal--state))
         (tabs (plist-get state :tabs))
         (active (plist-get state :active)))
    (append
     (mapcar
      (lambda (buf)
        (let ((face (if (eq buf active)
                        'tab-line-tab-current
                      'tab-line-tab-inactive))
              (map (make-sparse-keymap)))
          (define-key map [tab-line mouse-1]
                      (lambda (&rest _)
                        (interactive)
                        (project-terminal--select buf)))
          (propertize (format " %d " (1+ (seq-position tabs buf)))
                      'face face
                      'keymap map)))
      tabs)
     (list (propertize " + "
                       'face 'tab-line-tab
                       'keymap project-terminal--add-map)))))

(defun project-terminal--select (buf)
  "Switch the drawer to display BUF."
  (let* ((key (project-terminal--key))
         (state (gethash key project-terminal--projects)))
    (when state
      (plist-put state :active buf)
      (let ((win (project-terminal--window)))
        (when win
          (set-window-buffer win buf)
          (select-window win)
          (goto-char (point-max)))))))

(defun project-terminal--active ()
  "Return the active terminal buffer for the current project."
  (plist-get (project-terminal--state) :active))

(defun project-terminal--window ()
  "Return the visible drawer window for the current project, or nil."
  (let* ((state (gethash (project-terminal--key) project-terminal--projects))
         (tabs (and state (plist-get state :tabs))))
    (seq-some (lambda (buf)
               (when (buffer-live-p buf)
                 (get-buffer-window buf)))
             tabs)))

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
    (let ((win (project-terminal--show (project-terminal--active))))
      (select-window win)
      (goto-char (point-max)))))

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
