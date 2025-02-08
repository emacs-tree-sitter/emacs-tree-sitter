;;; tree-sitter-imenu.el --- Jump to buffer points of note, in the current buffer, based on tree-sitter -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020  Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;;         Timo von Hartz <c0untlizzi@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file adds an `imenu' backend using `tree-sitter'.
;;
;; This lets users call `imenu' to interactively select relevent
;; points of interest in the current buffer such as class declarations
;; or variable assignments.

;;; Code:

(require 'tree-sitter)

(eval-when-compile
  (require 'cl-lib))

(defgroup tree-sitter-imenu nil
  "`imenu' using tree-sitter."
  :group 'tree-sitter)

;;; ----------------------------------------------------------------------------
;;; Interfaces for modes and end users.

(defvar-local tree-sitter-imenu--query nil
  "Tree query used for `imenu', compiled from patterns.")

(defvar-local tree-sitter-imenu-default-patterns nil
  "Default imenu patterns.
This should be set by major modes that want to integrate with `tree-sitter-imenu'.
It plays a similar role to `imenu-generic-expression'.

It is either a string, or a vector of S-expressions. For more details on the
syntax, see https://emacs-tree-sitter.github.io/syntax-highlighting/queries/.")

(defvar tree-sitter-imenu--patterns-alist nil
  "Additional language-specific `imenu' patterns.
It plays a similar role to `font-lock-keywords-alist', except that its keys are
language symbols, not major mode symbols.")
(put 'tree-sitter-imenu--patterns-alist 'risky-local-variable t)

(defvar-local tree-sitter-imenu--extra-patterns-list nil
  "Additional buffer-local syntax highlighting patterns.")

(defcustom tree-sitter-imenu-type-matching-function
  #'identity
  "Function used to map capture names in query patterns to `imenu' types.
This can also be used to selectively disable certain capture names."
  :group 'tree-sitter-imenu
  :type 'function)

(defun tree-sitter-imenu--query ()
  (or tree-sitter-imenu--query
      (setq tree-sitter-imenu--query
            (when tree-sitter-imenu-default-patterns
              (tsc-make-query
               tree-sitter-language
               (mapconcat #'tsc--stringify-patterns
                          (append tree-sitter-imenu--extra-patterns-list
                                  (alist-get (tsc--lang-symbol tree-sitter-language)
                                             tree-sitter-imenu--patterns-alist)
                                  (list tree-sitter-imenu-default-patterns))
                          "\n")
               tree-sitter-imenu-type-matching-function)))))

;; TODO: tree-sitter-imenu-add-patterns

;;; ----------------------------------------------------------------------------
;;; Index function & helpers

(defun tree-sitter-imenu--captures-leaf-node (captures)
  "Return a node in an entry, CAPTURES, from `tsc--query-cursor-matches'."
  (cdr (aref (cdr captures) (1- (length (cdr captures))))))

(defun tree-sitter-imenu--captures ()
  "Execute variable `tree-sitter-imenu--query' and fetch unique matches.
Returns a value of the form [(PATTERN-INDEX . [CAPTURE...])], that
is a vector of all captures grouped by the pattern index."
  (thread-first
    (tsc--query-cursor-matches
     (tsc-make-query-cursor)
     (tree-sitter-imenu--query)
     (tsc-root-node tree-sitter-tree)
     #'tsc--buffer-substring-no-properties)
    (cl-stable-sort #'< :key #'car)
    ;; TODO: Write custom duplicate remover, `cl-delete-duplicates'
    ;; seems to work by overwriting earlier values matching later
    ;; values with those later values, which is why we double reverse
    ;; here to ensure the order of the original sequence is maintained.
    (nreverse)
    (cl-delete-duplicates
     :key #'tree-sitter-imenu--captures-leaf-node
     :test #'tsc-node-eq)
    (nreverse)))

(defun tree-sitter-imenu--stream (captures)
  "Convert each tree-sitter match in CAPTURES to a list of nodes.
Each node in the return-value is a string except for the final node
which is a cons of the form (\"NAME\" . POINT)."
  (cl-loop for (_ . it) across captures
           with len  = nil do (setq len  (length it))
           with leaf = nil do (setq leaf (aref it (1- len)))
           collect
           (append (list (car leaf))
                   (mapcar #'tsc-node-text
                           (mapcar #'cdr (cl-subseq it 0 (1- len))))
                   (cons (tsc-node-text (cdr leaf))
                         (tsc-node-start-position (cdr leaf))))))

(defun tree-sitter-imenu--group-stream (stream)
  "Group STREAM into a tree of nodes as expected by `imenu'."
  (let ((mem (make-hash-table :test 'equal :size (length stream)))
        leaves)
    (dolist (it stream)
      (if (numberp (cdr it))
          (push it leaves)
        (if-let ((val (gethash (car it) mem)))
            (puthash (car it) (append val (list (cdr it))) mem)
          (puthash (car it) (list (cdr it)) mem))))
    (maphash
     (lambda (key sub-stream)
       (setq leaves
             (append leaves
                     (list (cons key (tree-sitter-imenu--group-stream sub-stream))))))
     mem)
    leaves))

(defun tree-sitter-imenu-index-function ()
  "Tree-sittters `imenu-create-index-function'."
  (thread-first
    (tree-sitter-imenu--captures)
    (tree-sitter-imenu--stream)
    (tree-sitter-imenu--group-stream)))

;;; ----------------------------------------------------------------------------
;;; Setup and teardown.

(defun tree-sitter-imenu--setup ()
  (when (tree-sitter-imenu--query)
    (setq imenu-create-index-function
          #'tree-sitter-imenu-index-function))
  )

(defun tree-sitter-imenu--teardown ()
  ;; TODO: Maybe restore previous index function?
  (when (eq imenu-create-index-function
            #'tree-sitter-imenu-index-function)
    (kill-local-variable 'imenu-create-index-function)))

(define-minor-mode tree-sitter-imenu-mode
  "Toggle `imenu' support based on Tree-sitter's syntax tree.
If `tree-sitter-imenu-default-patterns' is nil, turning on this mode does nothing,
and does not interfere with `font-lock-mode'.

Enabling this automatically enables `tree-sitter-mode' in the buffer.

To enable this automatically whenever `tree-sitter-mode' is enabled:

 (add-hook 'tree-sitter-after-on-hook #'tree-sitter-imenu-mode)"
  :init-value nil
  :group 'tree-sitter
  (tree-sitter--handle-dependent tree-sitter-imenu-mode
    #'tree-sitter-imenu--setup
    #'tree-sitter-imenu--teardown))

(provide 'tree-sitter-imenu)
;;; tree-sitter-imenu.el ends here
