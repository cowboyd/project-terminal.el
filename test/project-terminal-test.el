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
    (clrhash project-terminal--projects)
    (dolist (b (buffer-list))
      (when (string-prefix-p "*project-terminal" (buffer-name b))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer b)))))

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

  (describe "project-terminal--state"
    (it "creates one eshell tab"
      (spy-on 'project-current :and-return-value nil)
      (let* ((state (project-terminal--state))
             (tabs (plist-get state :tabs)))
        (expect (length tabs) :to-equal 1)
        (expect (buffer-live-p (car tabs)) :to-be-truthy)
        (expect (buffer-local-value 'major-mode (car tabs))
                :to-equal 'eshell-mode)))

    (it "sets the first tab as active"
      (spy-on 'project-current :and-return-value nil)
      (let ((state (project-terminal--state)))
        (expect (plist-get state :active)
                :to-be (car (plist-get state :tabs)))))

    (it "returns the same state on repeated calls"
      (spy-on 'project-current :and-return-value nil)
      (let ((a (project-terminal--state))
            (b (project-terminal--state)))
        (expect a :to-equal b)))

    (it "recreates state if all tab buffers were killed"
      (spy-on 'project-current :and-return-value nil)
      (let* ((state (project-terminal--state))
             (old (car (plist-get state :tabs))))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer old))
        (let ((new (car (plist-get (project-terminal--state) :tabs))))
          (expect (buffer-live-p new) :to-be-truthy)
          (expect new :not :to-be old))))

    (it "removes dead buffers but keeps live ones"
      (spy-on 'project-current :and-return-value nil)
      (let* ((key (project-terminal--key))
             (state (project-terminal--state))
             (buf2 (project-terminal--make-tab key))
             (buf1 (car (plist-get state :tabs))))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer buf1))
        (let* ((new-state (project-terminal--state))
               (tabs (plist-get new-state :tabs)))
          (expect tabs :to-equal (list buf2)))))

    (it "moves active to a live buffer when active is killed"
      (spy-on 'project-current :and-return-value nil)
      (let* ((key (project-terminal--key))
             (state (project-terminal--state))
             (buf2 (project-terminal--make-tab key))
             (buf1 (plist-get state :active)))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer buf1))
        (let ((new-state (project-terminal--state)))
          (expect (plist-get new-state :active) :to-be buf2)))))

  (describe "project-terminal-show"
    (it "opens a side window"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (expect (project-terminal--window) :not :to-be nil))

    (it "displays the active buffer"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (expect (window-buffer (project-terminal--window))
              :to-be (project-terminal--active)))

    (it "is a no-op if the drawer is already visible"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let ((win (project-terminal--window)))
        (project-terminal-show)
        (expect (project-terminal--window) :to-be win)))

    (it "does not create a new shell if one already exists"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let ((buf (window-buffer (project-terminal--window))))
        (project-terminal-hide)
        (project-terminal-show)
        (expect (window-buffer (project-terminal--window))
                :to-be buf))))

  (describe "project-terminal-hide"
    (it "closes the drawer window"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (expect (project-terminal--window) :not :to-be nil)
      (project-terminal-hide)
      (expect (project-terminal--window) :to-be nil))

    (it "keeps buffers alive after hiding"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let ((tabs (plist-get (project-terminal--state) :tabs)))
        (project-terminal-hide)
        (expect (seq-every-p #'buffer-live-p tabs) :to-be-truthy)))

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
      (expect (project-terminal--window) :to-be nil)))

  (describe "project-terminal--select"
    (it "switches the displayed buffer in the drawer"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let* ((key (project-terminal--key))
             (buf2 (project-terminal--make-tab key))
             (state (gethash key project-terminal--projects)))
        (project-terminal--select buf2)
        (expect (window-buffer (project-terminal--window))
                :to-be buf2)
        (expect (plist-get state :active) :to-be buf2))))

  (describe "project-terminal-add"
    (it "creates a new tab and switches to it"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (let ((first (window-buffer (project-terminal--window))))
        (project-terminal-add)
        (let* ((state (project-terminal--state))
               (tabs (plist-get state :tabs)))
          (expect (length tabs) :to-equal 2)
          (expect (plist-get state :active) :not :to-be first)
          (expect (window-buffer (project-terminal--window))
                  :to-be (plist-get state :active)))))

    (it "creates only one tab when no shells exist"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-add)
      (let ((tabs (plist-get (project-terminal--state) :tabs)))
        (expect (length tabs) :to-equal 1)))

    (it "opens the drawer if not already visible"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-add)
      (expect (project-terminal--window) :not :to-be nil))

    (it "creates an eshell buffer"
      (spy-on 'project-current :and-return-value nil)
      (project-terminal-show)
      (project-terminal-add)
      (let ((buf (window-buffer (project-terminal--window))))
        (expect (buffer-local-value 'major-mode buf)
                :to-equal 'eshell-mode)))))

;;; project-terminal-test.el ends here
