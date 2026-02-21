# project-terminal

One of the things I love about VSCode is the drawer of terminals that
it keeps at the bottom of each window. This is my attempt to replicate
some portion of that.

This project adds a drawer of terminals to each project that can be
opened with the function `project-terminal-toggle`. To add new
terminals to th drawer, either click on the `+` tab, or call the
`project-terminal-add` function.


## Installation

Requires Emacs 28.1+ and `project.el`.

### Recommended setup

```elisp
(use-package project-terminal
  :bind (:map project-prefix-map
         ("t" . project-terminal-toggle)
         ("T" . project-terminal-add))
  :custom
  ;; (project-terminal-height 0.25)  ;; Drawer height as a fraction of the frame
  ;; (project-terminal-side 'bottom) ;; Side of the frame (bottom, top, left, right)
  ;; (project-terminal-shell 'eshell) ;; Shell backend (eshell or vterm)
)
```

If you choose `vterm`, you must have
[emacs-libvterm](https://github.com/akermu/emacs-libvterm) installed.

## Development

This project uses [Eask](https://emacs-eask.github.io/) for build
tooling and [Buttercup](https://github.com/jorgenschaefer/emacs-buttercup)
for tests.

```sh
# Install dependencies
eask install-deps --dev

# Run tests
eask test buttercup

# Launch Emacs with just this package loaded
eask emacs
```
