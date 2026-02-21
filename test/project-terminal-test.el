;;; project-terminal-test.el --- Tests for project-terminal -*- lexical-binding: t; -*-

;;; Commentary:

;; Buttercup tests for project-terminal.

;;; Code:

(require 'buttercup)
(require 'project-terminal)

(describe "project-terminal"
  (after-each
    (when-let ((win (project-terminal--window)))
      (delete-window win))
    (clrhash project-terminal--buffers)
    (dolist (b (buffer-list))
      (when (string-prefix-p "*project-terminal:" (buffer-name b))
        (kill-buffer b))))

  (it "loads successfully"
    (expect (featurep 'project-terminal) :to-be-truthy))

  (describe "project-terminal--key"
    (it "returns project root when in a project"
      (spy-on 'project-current :and-return-value '(vc Git "/fake/project/"))
      (spy-on 'project-root :and-return-value "/fake/project/")
      (expect (project-terminal--key) :to-equal "/fake/project/"))

    (it "returns *global* when no project is active"
      (spy-on 'project-current :and-return-value nil)
      (expect (project-terminal--key) :to-equal "*global*")))

  (describe "project-terminal--buffer"
    (it "creates a buffer named after the project"
      (spy-on 'project-current :and-return-value nil)
      (let ((buf (project-terminal--buffer)))
        (expect (buffer-name buf) :to-equal "*project-terminal: *global**")))

    (it "returns the same buffer on repeated calls"
      (spy-on 'project-current :and-return-value nil)
      (let ((a (project-terminal--buffer))
            (b (project-terminal--buffer)))
        (expect a :to-be b)))

    (it "creates a new buffer if the old one was killed"
      (spy-on 'project-current :and-return-value nil)
      (let ((a (project-terminal--buffer)))
        (kill-buffer a)
        (let ((b (project-terminal--buffer)))
          (expect (buffer-live-p b) :to-be-truthy)
          (expect b :not :to-be a))))

    (it "creates a project-specific buffer"
      (spy-on 'project-current :and-return-value '(vc Git "/fake/"))
      (spy-on 'project-root :and-return-value "/fake/")
      (let ((buf (project-terminal--buffer)))
        (expect (buffer-name buf) :to-equal "*project-terminal: /fake/*"))))

  (describe "project-terminal-show"
    (it "opens a side window"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (expect (project-terminal--window) :not :to-be nil))

    (it "is a no-op if the drawer is already visible"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let ((win (project-terminal--window)))
        (project-terminal-show)
        (expect (project-terminal--window) :to-be win))))

  (describe "project-terminal-hide"
    (it "closes the drawer window"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (expect (project-terminal--window) :not :to-be nil)
      (project-terminal-hide)
      (expect (project-terminal--window) :to-be nil))

    (it "keeps the buffer alive after hiding"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let ((buf (project-terminal--buffer)))
        (project-terminal-hide)
        (expect (buffer-live-p buf) :to-be-truthy)))

    (it "is a no-op if the drawer is not visible"
      (spy-on 'project-current :and-return-value nil)
      (expect (project-terminal-hide) :not :to-throw)))

  (describe "project-terminal-toggle"
    (it "shows the drawer when hidden"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-toggle)
      (expect (project-terminal--window) :not :to-be nil))

    (it "hides the drawer when visible"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (expect (project-terminal--window) :not :to-be nil)
      (project-terminal-toggle)
      (expect (project-terminal--window) :to-be nil))))

;;; project-terminal-test.el ends here
