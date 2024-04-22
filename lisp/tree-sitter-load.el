;;; tree-sitter-load.el --- Language loading for tree-sitter -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020  Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file implements functions to search, load and register `tree-sitter'
;; language objects (grammars).

;;; Code:

(require 'map)
(require 'seq)

(require 'tsc)
(require 'tree-sitter-cli)

(eval-when-compile
  (require 'pcase))

(defvar tree-sitter-languages nil
  "An alist of mappings from language name symbols to language objects.
See `tree-sitter-require'.")

(defvar tree-sitter-load-path (list (tree-sitter-cli-bin-directory))
  "List of directories to search for shared libraries that define languages.")

(defvar tree-sitter-load-suffixes
  (pcase system-type
    ;; The CLI tool outputs `.so', but `.dylib' is more sensible on macOS.
    ('darwin (list ".dylib" ".so"))
    ((or 'gnu 'gnu/linux 'gnu/kfreebsd 'berkeley-unix) "so")
    ('windows-nt (list ".dll"))
    (_ (error "Unsupported system-type %s" system-type)))
  "List of suffixes for shared libraries that define tree-sitter languages.")

;;; TODO: Allow specifying absolute path.
(defun tree-sitter-load (lang-symbol &optional file native-symbol-name)
  "Load a language grammar from FILE and register it under the name LANG-SYMBOL.
If another language was already registered under the same name, override it.

This function returns the loaded language object.

FILE should be the base name (without extension) of the native shared library
that exports the language as the native symbol NATIVE-SYMBOL-NAME.

If FILE is nil, the base name is assumed to be LANG-SYMBOL's name.

If NATIVE-SYMBOL-NAME is nil, the name of the exported native symbol is assumed
to be LANG-SYMBOL's name, prefixed with \"tree_sitter_\"."
  (let* ((lang-name (symbol-name lang-symbol))
         ;; Example: c-sharp -> c_sharp.
         (fallback-name (replace-regexp-in-string "-" "_" lang-name))
         (native-symbol-name (or native-symbol-name
                                 (format "tree_sitter_%s"
                                         fallback-name)))
         ;; List of base file names to search for.
         (files (if file
                    ;; Use only FILE, if it's given.
                    (list file)
                  ;; Otherwise use LANG-SYMBOL. First, as-is. Then, with hyphens
                  ;; replaced by underscores.
                  (cons lang-name
                        (unless (string= lang-name fallback-name)
                          (list fallback-name)))))
         (full-path (seq-some (lambda (base-name)
                               (locate-file base-name
                                            tree-sitter-load-path
                                            tree-sitter-load-suffixes))
                             files)))
    (unless full-path
      ;; TODO: Define custom error class.
      (error "Cannot find shared library for language: %S" lang-symbol))
    (let ((language (tsc--load-language full-path native-symbol-name lang-symbol)))
      (setf (map-elt tree-sitter-languages lang-symbol) language)
      language)))

;;;###autoload
(defun tree-sitter-require (lang-symbol &optional file native-symbol-name)
  "Return the language object loaded and registered under the name LANG-SYMBOL.
If the language has not been loaded yet, load it with `tree-sitter-load'.

FILE should be the base name (without extension) of the native shared library
that exports the language as the native symbol NATIVE-SYMBOL-NAME.

If FILE is nil, the base name is assumed to be LANG-SYMBOL's name.

If NATIVE-SYMBOL-NAME is nil, the name of the exported native symbol is assumed
to be LANG-SYMBOL's name, prefixed with \"tree_sitter_\"."
  (or (alist-get lang-symbol tree-sitter-languages)
      (tree-sitter-load lang-symbol file native-symbol-name)))

(provide 'tree-sitter-load)
;;; tree-sitter-load.el ends here
