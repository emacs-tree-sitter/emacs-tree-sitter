;;; tree-sitter-cli.el --- Utilities for tree-sitter CLI -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020 Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file contains functions to work with the tree-sitter CLI. It must not
;; depend (directly on indirectly) on `tsc-dyn'. It shouldn't depend on
;; `tree-sitter'.

;;; Code:

(eval-when-compile
  (require 'subr-x))

(defvar tree-sitter-binary (executable-find "tree-sitter")
  "Tree-sitter binary location.")

(defun tree-sitter-version ()
  "Return tree-sitter CLI version."
  (if tree-sitter-binary
      (nth 1 (split-string
              (shell-command-to-string
               (concat tree-sitter-binary " -V"))))
    "0"))

(defun tree-sitter-cli-config-directory ()
  "Return tree-sitter CLI's config directory, including the ending separator.
This is the directory where the CLI stores the configuration file."
  (file-name-as-directory
   (expand-file-name
    ;; https://github.com/tree-sitter/tree-sitter/blob/1bad6dc/cli/src/config.rs#L20
    (if-let ((dir (getenv "TREE_SITTER_DIR")))
        dir
      "~/.tree-sitter"))))

(defun tree-sitter-cli-cache-directory ()
  "Return tree-sitter CLI's cache directory, including the ending separator.
This is the directory where the CLI tool keeps compiled lang definitions."
  (file-name-as-directory
   ;; https://github.com/tree-sitter/tree-sitter/blob/master/cli/loader/src/lib.rs#L110-L115
   (expand-file-name "tree-sitter"
                     (cond
                      ((eq system-type 'gnu/linux)
                       (let ((env (getenv "XDG_CACHE_HOME")))
                         (if (or (null env) (not (file-name-absolute-p env)))
                             (expand-file-name "~/.cache")
                           env)))
                      ((eq system-type 'darwin)
                       "~/Library/Caches")
                      ((memq system-type '(cygwin windows-nt ms-dos))
                       "~/AppData/Local")))))

(defun tree-sitter-cli-lib-directory ()
  "Return the directory used by tree-sitter CLI to store compiled grammars."
  (file-name-as-directory
   (if (version<= "0.20" (tree-sitter-version))
       (expand-file-name "lib" (tree-sitter-cli-cache-directory))
     (expand-file-name "bin" (tree-sitter-cli-config-directory)))))

(provide 'tree-sitter-cli)
;;; tree-sitter-cli.el ends here
