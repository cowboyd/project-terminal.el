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

(provide 'project-terminal)
;;; project-terminal.el ends here
