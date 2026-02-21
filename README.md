# project-terminal

One of the things I love about VSCode is the drawer of terminals that
it keeps at the bottom of each window. It's simple and wonderfully
convenient, and so This is my attempt to replicate some portion of
that.

To do so, this adds a drawer of terminals to each project that can be
opened and closed with the function `project-terminal-toggle`. By
default it will have a single terminal inside. However, you can add
more terminals by either clicking on the `+` tab, or calling the
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
  ;; (project-terminal-height 0.25)   ;; Drawer height as a fraction of the frame
  ;; (project-terminal-side 'bottom)  ;; Side of the frame (bottom, top, left, right)
  ;; (project-terminal-shell 'vterm) ;; Shell backend (eshell or vterm)
)
```
Personally, I use (and recommend) [`vterm`](https://github.com/akermu/emacs-libvterm), but it can be a bit of a beast to setup, so `eshell` is the default.

## Development

```sh
# Install dependencies
eask install-deps --dev

# Run tests
eask test buttercup

# Launch Emacs with just this package loaded
ask emacs --eval "(require 'project-terminal)"
```
