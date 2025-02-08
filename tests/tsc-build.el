;;; tsc-build.el --- Tests for tsc-dyn-get.el -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2021  Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; Tests for the code that builds tree-sitter grammars into shared objects.

(require 'async)
(require 'tsc)

(eval-when-compile
  (require 'subr-x))

(ert-deftest tsc-build:no-generate ()
  (let* ((test-dir (make-temp-file "tsc-build-test-" :directory))
         (repo-path (file-name-concat test-dir "tree-sitter-python"))
         (shared-lib-path (file-name-concat test-dir "python.so")))
    (shell-command (format "git clone %s %s"
                           "https://github.com/tree-sitter/tree-sitter-python.git"
                           repo-path))

    ;; Confirm shared object has been built
    (should (not (file-exists-p shared-lib-path)))
    (tsc-build-parser-from-source repo-path :dst-path test-dir)
    (should (file-exists-p shared-lib-path))

    ;; Confirm shared object is not corrupted and can be loaded properly
    (async-sandbox
     (lambda ()
       (require 'tree-sitter)
       (tree-sitter-require 'my/python (file-name-concat test-dir "python") "tree_sitter_python")))))

(ert-deftest tsc-build:generate ()
  (let* ((test-dir (make-temp-file "tsc-build-test-" :directory))
         (repo-path (file-name-concat test-dir "tree-sitter-python"))
         (shared-lib-path (file-name-concat test-dir "python.so")))
    (shell-command (format "git clone %s %s"
                           "https://github.com/tree-sitter/tree-sitter-python.git"
                           repo-path))

    ;; Delete pre-existing parser file. If the parser was not regenerated, the
    ;; compilation will fail.
    (delete-file (file-name-concat repo-path "src" "parser.c"))

    ;; Confirm shared object has been built
    (should (not (file-exists-p shared-lib-path)))
    (tsc-build-parser-from-source
     repo-path
     :dst-path test-dir
     :generate t)
    (should (file-exists-p shared-lib-path))

    ;; Confirm shared object is not corrupted and can be loaded properly
    (async-sandbox
     (lambda ()
       (require 'tree-sitter)
       (tree-sitter-require 'my/python (file-name-concat test-dir "python") "tree_sitter_python")))))

(ert-deftest tsc-build:wrong-directory ()
  (should-error
   (tsc-build-parser-from-source
    (temporary-file-directory)
    :generate t
    :dst-path (temporary-file-directory))
   :type 'rust-error))

;;; Code:
;; Local Variables:
;; no-byte-compile: t
;; End:
