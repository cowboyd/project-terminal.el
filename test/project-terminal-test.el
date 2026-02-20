;;; project-terminal-test.el --- Tests for project-terminal -*- lexical-binding: t; -*-

;;; Commentary:

;; Buttercup tests for project-terminal.

;;; Code:

(require 'buttercup)
(require 'project-terminal)

(describe "project-terminal"
  (it "loads successfully"
    (expect (featurep 'project-terminal) :to-be-truthy)))

;;; project-terminal-test.el ends here
