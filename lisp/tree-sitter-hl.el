;;; tree-sitter-hl.el --- Syntax highlighting based on tree-sitter -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020  Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;;         Timo von Hartz <c0untlizzi@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file implements a new syntax highlighting based on `tree-sitter'.

;;; Code:

(require 'tree-sitter)

(eval-when-compile
  (require 'cl-lib))

;;; ----------------------------------------------------------------------------
;;; Faces for commonly used highlight names: `tree-sitter-hl-face:CAPTURE-NAME'.

(defgroup tree-sitter-hl nil
  "Syntax highlighting using tree-sitter."
  :group 'tree-sitter)

(defgroup tree-sitter-hl-faces nil
  "Faces for highlighting code."
  :group 'tree-sitter-hl)

;;; ------------------------------------
;;; Functions.

(defface tree-sitter-hl-face:function
  '((default :inherit font-lock-function-name-face))
  "Face for function declarations, definitions and bindings."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:function.call
  '((default :inherit (link font-lock-function-name-face) :underline nil))
  "Face for function calls."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:function.builtin
  '((default :inherit font-lock-builtin-face))
  "Face for builtin functions."
  :group 'tree-sitter-hl-faces)

;;; TODO: Remove this?
(defface tree-sitter-hl-face:function.special
  '((default :inherit font-lock-preprocessor-face))
  "Face for functions that alter things at compile/load time."
  :group 'tree-sitter-hl-faces)

;;; TODO: Rename this?
(defface tree-sitter-hl-face:function.macro
  '((default :inherit font-lock-preprocessor-face))
  "Face for macro calls."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:method
  '((default :inherit tree-sitter-hl-face:function))
  "Face for method declarations and definitions."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:method.call
  '((default :inherit tree-sitter-hl-face:function.call))
  "Face for method invocations."
  :group 'tree-sitter-hl-faces)

(define-obsolete-face-alias 'tree-sitter-hl-face:function.method
  'tree-sitter-hl-face:method "0.9.0")

(define-obsolete-face-alias 'tree-sitter-hl-face:function.method.call
  'tree-sitter-hl-face:method.call "0.9.0")

;;; ------------------------------------
;;; Types.

(defface tree-sitter-hl-face:type
  '((default :inherit font-lock-type-face))
  "Face for types."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:type.parameter
  '((default :inherit font-lock-variable-name-face))
  "Face for type parameters."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:type.argument
  '((default :inherit tree-sitter-hl-face:type))
  "Face for type arguments."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:type.builtin
  '((default :inherit font-lock-builtin-face))
  "Face for builtin types."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:type.super
  '((default :inherit tree-sitter-hl-face:type))
  "Face for super types in definitions and type constraints."
  :group 'tree-sitter-hl-faces)

;;; TODO: Remove this?
(defface tree-sitter-hl-face:constructor
  '((default :inherit tree-sitter-hl-face:type))
  "Face for constructors."
  :group 'tree-sitter-hl-faces)

;;; ------------------------------------
;;; Variables, properties.

;;; TODO: Add variable.use?
(defface tree-sitter-hl-face:variable
  '((default :inherit font-lock-variable-name-face))
  "Face for variable declarations, definitions, bindings and mutations."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:variable.parameter
  '((default :inherit tree-sitter-hl-face:variable))
  "Face for function parameters."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:variable.builtin
  '((default :inherit font-lock-builtin-face))
  "Face for builtin variables."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:variable.special
  '((default :inherit font-lock-warning-face))
  "Face for \"dangerous\" variables, e.g. mutable or dynamically-bound."
  :group 'tree-sitter-hl-faces)

;;; TODO: Define a more sensible default.
(defface tree-sitter-hl-face:property
  '((default :inherit font-lock-constant-face :slant italic))
  "Face for properties."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:property.definition
  '((default :inherit tree-sitter-hl-face:variable.parameter))
  "Face for property declarations and definitions."
  :group 'tree-sitter-hl-faces)

;;; ------------------------------------
;;; Strings, comments, text proses.

(defface tree-sitter-hl-face:comment
  '((default :inherit font-lock-comment-face))
  "Face for comments."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:doc
  '((default :inherit font-lock-doc-face))
  "Face for docstrings."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:string
  '((default :inherit font-lock-string-face))
  "Face for strings."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:string.special
  '((default :inherit tree-sitter-hl-face:string :weight bold))
  "Face for special strings, e.g. regular expressions."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:escape
  '((default :inherit font-lock-keyword-face))
  "Face for escape characters in strings."
  :group 'tree-sitter-hl-faces)

;;; TODO: Rename this?
(defface tree-sitter-hl-face:embedded
  '((default :inherit default))
  "Face for embedded expressions and code fragments."
  :group 'tree-sitter-hl-faces)

;;; ------------------------------------
;;; Atomics, constants.

(defface tree-sitter-hl-face:keyword
  '((default :inherit font-lock-keyword-face))
  "Face for keywords."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:operator
  '((default :inherit tree-sitter-hl-face:keyword))
  "Face for operators."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:label
  '((default :inherit font-lock-preprocessor-face))
  "Face for labels."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:constant
  '((default :inherit font-lock-constant-face))
  "Face for constants."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:constant.builtin
  '((default :inherit font-lock-builtin-face))
  "Face for builtin constants."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:number
  '((default :inherit tree-sitter-hl-face:constant))
  "Face for numbers."
  :group 'tree-sitter-hl-faces)

;;; ------------------------------------
;;; Punctuations (aka. should-be-dimmed).

(defface tree-sitter-hl-face:punctuation
  '((default :inherit default))
  "Face for punctuations."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:punctuation.bracket
  '((default :inherit tree-sitter-hl-face:punctuation))
  "Face for brackets."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:punctuation.delimiter
  '((default :inherit tree-sitter-hl-face:punctuation))
  "Face for delimiters."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:punctuation.special
  '((default :inherit tree-sitter-hl-face:keyword))
  "Face for special punctuations."
  :group 'tree-sitter-hl-faces)

;;; ------------------------------------
;;; Markups.

(defface tree-sitter-hl-face:tag
  '((default :inherit font-lock-builtin-face))
  "Face for tags in markup languages."
  :group 'tree-sitter-hl-faces)

(defface tree-sitter-hl-face:attribute
  '((default :inherit font-lock-preprocessor-face))
  "Face for attributes markup languages."
  :group 'tree-sitter-hl-faces)

;;; ------------------------------------
;;; Special.

(defface tree-sitter-hl-face:noise
  '((default :inherit default))
  "Face for things that are syntatic noises.
It's up to themes how they should be displayed: dimmed, hidden..."
  :group 'tree-sitter-hl-faces)

;;; ----------------------------------------------------------------------------
;;; Interfaces for modes and end users.

(defcustom tree-sitter-hl-use-font-lock-keywords :except-font-lock-defaults
  "Whether to keep using the highlighting provided by `font-lock-keywords'.
If `:except-font-lock-defaults', then keywords specified by `font-lock-defaults'
are ignored, while keywords added through `font-lock-add-keywords' are used. The
former is typically set by major modes, while the latter is usually set by minor
modes and end users."
  :group 'tree-sitter-hl
  :type '(choice (const :tag "Yes" t)
                 (const :tag "No" nil)
                 (const :tag "Except `font-lock-defaults'" :except-font-lock-defaults)))

(defcustom tree-sitter-hl-face-mapping-function
  #'tree-sitter-hl-face-from-common-scope
  "Function used to map capture names in query patterns to highlighting faces.
This can also be used to selectively disable certain capture names. For example,
the following code disables keyword highlighting:

 (add-function :before-while 'tree-sitter-hl-face-mapping-function
               (lambda (capture-name)
                 (not (string= capture-name \"keyword\"))))"
  :group 'tree-sitter-hl
  :type 'function)

(defvar-local tree-sitter-hl-default-patterns nil
  "Default syntax highlighting patterns.
This should be set by major modes that want to integrate with `tree-sitter-hl'.
It plays a similar role to `font-lock-defaults'.

It is either a string, or a vector of S-expressions. For more details on the
syntax, see https://emacs-tree-sitter.github.io/syntax-highlighting/queries/.")

(defvar tree-sitter-hl--patterns-alist nil
  "Additional language-specific syntax highlighting patterns.
It plays a similar role to `font-lock-keywords-alist', except that its keys are
language symbols, not major mode symbols.")
(put 'tree-sitter-hl--patterns-alist 'risky-local-variable t)

(defvar-local tree-sitter-hl--extra-patterns-list nil
  "Additional buffer-local syntax highlighting patterns.")

(defvar-local tree-sitter-hl--query nil
  "Tree query used for syntax highlighting, compiled from patterns.")

(defun tree-sitter-hl--ensure-query ()
  "Return the tree query to be used for syntax highlighting in this buffer."
  (unless tree-sitter-hl--query
    (setq tree-sitter-hl--query
          (when tree-sitter-hl-default-patterns
            (tsc-make-query
             tree-sitter-language
             (mapconcat #'tsc--stringify-patterns
                        (append tree-sitter-hl--extra-patterns-list
                                (alist-get (tsc--lang-symbol tree-sitter-language)
                                           tree-sitter-hl--patterns-alist)
                                (list tree-sitter-hl-default-patterns))
                        "\n")
             tree-sitter-hl-face-mapping-function))))
  tree-sitter-hl--query)

(defun tree-sitter-hl-face-from-common-scope (capture-name)
  "Return the default face used to highlight CAPTURE-NAME."
  ;; TODO: If a scope does not have a corresponding face, check its ancestors.
  (intern (format "tree-sitter-hl-face:%s" capture-name)))

;;;###autoload
(defun tree-sitter-hl-add-patterns (lang-symbol patterns)
  "Add custom syntax highlighting PATTERNS.
If LANG-SYMBOL is non-nil, it identifies the language that PATTERNS should be
applied to. If LANG-SYMBOL is nil, PATTERNS are applied to the current buffer,
and are prioritized over language-specific patterns. Either way, PATTERNS are
prioritized over `tree-sitter-hl-default-patterns'.

This function should be used by minor modes and configuration code. Major modes
should set `tree-sitter-hl-default-patterns' instead."
  (declare (indent 1))
  (if lang-symbol
      (tree-sitter-hl--add-patterns-for-language lang-symbol patterns)
    (tree-sitter-hl--add-patterns-locally patterns)))

(defun tree-sitter-hl--add-patterns-locally (patterns)
  "Add buffer-local syntax highlighting PATTERNS.
These will take precedence over `tree-sitter-hl-default-patterns', as well as
previously added patterns."
  ;; Do nothing if the patterns are already on top.
  (unless (equal patterns (cl-first tree-sitter-hl--extra-patterns-list))
    (let ((old-list tree-sitter-hl--extra-patterns-list)
          (old-query tree-sitter-hl--query))
      ;; Update the patterns list and request the query to be rebuilt...
      (setq tree-sitter-hl--extra-patterns-list
            (append (list patterns) (remove patterns old-list)))
      (setq tree-sitter-hl--query nil)
      ;; ... and build it if possible. During a major mode's hook, we may not
      ;; even know the language, in which case we let `tree-sitter-hl--setup'
      ;; build the query later on.
      (when tree-sitter-language
        (tree-sitter--error-protect (tree-sitter-hl--ensure-query)
          ;; When the newly added patterns are invalid, restore the old state.
          (setq tree-sitter-hl--query old-query
                tree-sitter-hl--extra-patterns-list old-list))
        ;; Everything is in place. Request a re-render.
        (when (bound-and-true-p tree-sitter-hl-mode)
          (tree-sitter-hl--invalidate))))))

(defun tree-sitter-hl--add-patterns-for-language (lang-symbol patterns)
  "Add syntax highlighting PATTERNS for the language identified by LANG-SYMBOL.
See `tree-sitter-hl-add-patterns'."
  (let ((old-list (alist-get lang-symbol tree-sitter-hl--patterns-alist)))
    ;; Do nothing if the patterns are already on top.
    (unless (equal patterns (cl-first old-list))
      ;; Check whether the patterns are valid. TODO: Should we delay the check
      ;; if language is not yet loaded, instead of trying to load it?
      (tsc-make-query (tree-sitter-require lang-symbol) patterns)
      (setf (map-elt tree-sitter-hl--patterns-alist lang-symbol)
            (append (list patterns) (remove patterns old-list))))))

(defun tree-sitter-hl-dry-up-region (beg end)
  "Make the highlighting in the region between BEG and END 'permanent'."
  (let ((pos beg) next)
    (while (< pos end)
      ;; Determine the end of the current contiguous block...
      (setq next (next-single-property-change pos 'face))
      ;; ... which should be capped to END.
      (when (or (null next)
                (> next end))
        (setq next end))
      ;; Convert `face' to `font-lock-face'.
      (when-let ((face (get-text-property pos 'face)))
        (put-text-property pos next 'font-lock-face face))
      (setq pos next))))

;;; ----------------------------------------------------------------------------
;;; Internal workings.

(defvar-local tree-sitter-hl--query-cursor nil)

(defconst tree-sitter-hl--extend-region-limit 2048
  "The max size delta of the (structurally) extended regions.")

(defconst tree-sitter-hl--extend-region-levels 4
  "The max number of levels to walk up the syntax tree to extend the regions.
The assumption is that: in any syntax highlighting pattern, the captures do not
lie deeper than this.")

;; https://github.com/tree-sitter/tree-sitter/pull/1130.
(defvar-local tree-sitter-hl-enable-query-region-extension nil
  "Whether to extend query region used for highlighting.
If you get incorrect highlighting, try setting this to t.

See `tree-sitter-hl--extend-regions' for more details.")

;;; TODO: Improve this function's docstring. It's no longer accurate.
(defun tree-sitter-hl--extend-regions (hl-region query-region)
  "Extend HL-REGION and QUERY-REGION before highlighting, mutably.
For performance reason, we execute the highlighting query on a region, instead
of on the whole buffer. When range restriction is used, a match is returned only
when all nodes in a pattern intersect the query cursor's range. Therefore,
QUERY-REGION should intersect all relevant nodes, not just nodes to be
highlighted.

One case that illustrates the need for QUERY-REGION to be larger than HL-REGION
is when `evil-adjust-cursor' triggers a `vertical-motion' (outside of a
redisplay), resulting in `jit-lock--run-funtions' being called on a very small
region. Another case is sibling sub-patterns being cut in halves by HL-REGION's
boundaries.

Note that the main performance bottleneck with querying the whole buffer is in
accessing nodes' texts, which involves allocating temporary strings, copying
them to the dynamic modules, then garbage-collecting them. When dynamic modules
have direct access to buffer text, this function may become obsolete.

See https://github.com/tree-sitter/tree-sitter/issues/598."
  (pcase-let* ((root-node (tsc-root-node tree-sitter-tree))
               (`(,beg . ,end) hl-region)
               (orig-size (- end beg))
               (node (tsc-get-descendant-for-position-range
                      root-node beg end))
               (`(,beg . ,end) (tsc-node-position-range node))
               (size (- end beg))
               (delta (- size orig-size))
               (level 0))
    (when (< delta tree-sitter-hl--extend-region-limit)
      (setcar hl-region beg)
      (setcdr hl-region end)
      (setcar query-region beg)
      (setcdr query-region end))
    ;; Repeatedly extend the region, within the limit. TODO: What if the region
    ;; of the minimal enclosing node is already too large?
    (when tree-sitter-hl-enable-query-region-extension
      (while (and node
                  (< delta tree-sitter-hl--extend-region-limit))
        (setcar query-region beg)
        (setcdr query-region end)
        ;; Walk up to the parent node.
        (when (setq node (when (<= (cl-incf level)
                                   tree-sitter-hl--extend-region-levels)
                           (tsc-get-parent node)))
          (let ((range (tsc-node-position-range node)))
            (setf `(,beg . ,end) range)
            (setq size (- end beg))
            (setq delta (- size orig-size)))))
      ;; Extend to whole lines.
      (goto-char (car query-region))
      (setcar query-region (line-beginning-position 0))
      (goto-char (cdr query-region))
      (setcdr query-region (line-beginning-position 2)))))

(defun tree-sitter-hl--append-text-property (start end prop value &optional object)
  "Append VALUE to PROP of the text from START to END.
This is similar to `font-lock-append-text-property', but deduplicates values. It
also expects VALUE to be a single value, not a list. Additionally, if PROP was
previously nil, it will be set to VALUE, not (list VALUE)."
  (let (next prev)
    (while (/= start end)
      (setq next (next-single-property-change start prop object end)
            prev (get-text-property start prop object))
      ;; Canonicalize old forms of face property.
      (and (memq prop '(face font-lock-face))
           (listp prev)
           (or (keywordp (car prev))
               (memq (car prev) '(foreground-color background-color)))
           (setq prev (list prev)))
      (unless (listp prev)
        (setq prev (list prev)))
      (unless (memq value prev)
        (put-text-property start next prop
                           ;; Reduce GC pressure by not making a list if it's
                           ;; just a single face.
                           (if prev
                               (append prev (list value))
                             value)
                           object))
      (setq start next))))

(defun tree-sitter-hl--highlight-capture (capture)
  "Highlight the given CAPTURE."
  (pcase-let ((`(,face . (,beg-byte . ,end-byte)) capture))
    ;; TODO: If it's a function, call it with (BEG END).
    (when (facep face)
      (tree-sitter-hl--append-text-property
       (byte-to-position beg-byte)
       (byte-to-position end-byte) 'face face))))

;;; TODO: Handle embedded DSLs (injections).
(defun tree-sitter-hl--highlight-region (beg end &optional loudly)
  "Highlight the region (BEG . END).
This is intended to be used as a buffer-local override of
`font-lock-fontify-region-function'.

If LOUDLY is non-nil, print debug messages."
  (tsc--save-context
    (let ((inhibit-point-motion-hooks t))
      ;; Extend the region to be highlighted, so that it is not too wastefully
      ;; small. Then extend it again, based on some heuristic, for querying, to
      ;; avoid certain pathological cases. This is partially analogous to the
      ;; extension done by `font-lock-default-fontify-region'.
      (let ((hl-region `(,beg . ,end))
            (query-region `(,beg . ,end)))
        (tree-sitter-hl--extend-regions hl-region query-region)
        (setf `(,beg . ,end) hl-region)
        (tsc--query-cursor-set-byte-range tree-sitter-hl--query-cursor
                                         (position-bytes (car query-region))
                                         (position-bytes (cdr query-region))))
      (let* ((root-node (tsc-root-node tree-sitter-tree))
             (captures  (tsc--query-cursor-captures-1
                         tree-sitter-hl--query-cursor
                         tree-sitter-hl--query
                         root-node
                         #'tsc--buffer-substring-no-properties)))
        ;; TODO: Handle quitting.
        (with-silent-modifications
          (font-lock-unfontify-region beg end)
          ;; TODO: Consider giving certain combinations of highlight names their
          ;; own faces. For example, it might be desirable for fontification of
          ;; a node that matches both "constructor" and "variable" to be
          ;; different from the union of "constructor fontification" and
          ;; "variable fontification".
          (mapc #'tree-sitter-hl--highlight-capture captures)
          ;; This should primarily be for keywords added through
          ;; `font-lock-add-keywords' (minor modes and end users).
          (when (and tree-sitter-hl-use-font-lock-keywords
                     font-lock-set-defaults)
            (font-lock-fontify-keywords-region beg end loudly)))
        ;; We may have highlighted more, but are only reasonably sure about
        ;; HL-REGION.
        `(jit-lock-bounds ,beg . ,end)))))

(defun tree-sitter-hl--highlight-region-with-fallback (old-fontify-fn beg end &optional loudly)
  "Highlight the region (BEG . END).

This is a wrapper around `tree-sitter-hl--highlight-region' that falls back to
OLD-FONTIFY-FN in certain situations:

1. When the current buffer doesn't have `tree-sitter-hl-mode' enabled. An
   example is `jupyter-repl-mode', which copies and uses other major modes'
   fontification functions to highlight its input cells. See
   https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/78#issuecomment-1005987817.

2. When the code to parse and highlight is confined to a single region. The
   motivating use case parsing and highlighting the current input cell in
   `jupyter-repl-mode'. See `tree-sitter-get-parse-region-function'."
  (if (and tree-sitter-hl--query tree-sitter-tree)
      (if tree-sitter--parse-region
          ;; Highlight only the region that `tree-sitter' parsed. Use the
          ;; underlying fontification function for the rest.
          (pcase-let ((`(,code-beg . ,code-end) tree-sitter--parse-region))
            (let ((tree-hl-beg (max beg code-beg))
                  (tree-hl-end (min end code-end)))
              (if (<= tree-hl-end tree-hl-beg)
                  (funcall old-fontify-fn beg end loudly)
                (when (< beg tree-hl-beg)
                  (funcall old-fontify-fn beg tree-hl-beg loudly))
                (when (< tree-hl-end end)
                  (funcall old-fontify-fn tree-hl-end end loudly))
                (tree-sitter-hl--highlight-region beg end loudly)
                `(jit-lock-bounds ,beg . ,end))))
        (tree-sitter-hl--highlight-region beg end loudly))
    (funcall old-fontify-fn beg end loudly)))

(defun tree-sitter-hl--invalidate (&optional old-tree)
  "Mark regions of text to be rehighlighted after a text change.
Installed on `tree-sitter-after-change-functions'.

OLD-TREE is the tree before the edit."
  (if old-tree
      ;; Incremental parse.
      (seq-doseq (range (tsc-changed-ranges old-tree tree-sitter-tree))
        ;; TODO: How about invalidating a single large range?
        (pcase-let* ((`[,beg-byte ,end-byte] range)
                     (beg (byte-to-position beg-byte))
                     (end (byte-to-position end-byte)))
          ;; TODO: How about calling `jit-lock-refontify' directly?
          (font-lock-flush beg end)))
    ;; First parse.
    (font-lock-flush)))

;;; ----------------------------------------------------------------------------
;;; Setup and teardown.

(defvar-local tree-sitter-hl--font-lock-keywords nil)

(defun tree-sitter-hl--minimize-font-lock-keywords ()
  "Remove keywords set by `font-lock-defaults' from `font-lock-keywords'."
  (when font-lock-set-defaults
    (unless tree-sitter-hl--font-lock-keywords
      (setq tree-sitter-hl--font-lock-keywords font-lock-keywords)
      (when (eq tree-sitter-hl-use-font-lock-keywords :except-font-lock-defaults)
        ;; XXX: Check whether this covers all the edge cases of the interaction
        ;; between `font-lock-eval-keywords' and `font-lock-remove-keywords'.
        (let* ((keywords-spec (car font-lock-defaults))
               ;; The spec can be a list, corresponding to multiple levels of
               ;; fontification. We want to disable all of them.
               (keywords-list (if (and (listp keywords-spec)
                                       (symbolp (car keywords-spec)))
                                  keywords-spec
                                (list keywords-spec))))
          (dolist (keywords keywords-list)
            (font-lock-remove-keywords
             nil (font-lock-eval-keywords keywords))))))))

(defun tree-sitter-hl--restore-font-lock-keywords ()
  "Undo the hack done by `tree-sitter-hl--minimize-font-lock-keywords'."
  (when font-lock-set-defaults
    (when tree-sitter-hl--font-lock-keywords
      (setq font-lock-keywords tree-sitter-hl--font-lock-keywords
            tree-sitter-hl--font-lock-keywords nil))))

(defun tree-sitter-hl--setup ()
  "Set up `tree-sitter-hl' in the current buffer.
This assumes both `tree-sitter-mode' and `font-lock-mode' were already enabled."
  ;; TODO: If there's an error, disable `tree-sitter-hl--extra-patterns-list'
  ;; and retry.
  (when (tree-sitter-hl--ensure-query)
    (unless tree-sitter-hl--query-cursor
      (setq tree-sitter-hl--query-cursor (tsc-make-query-cursor))
      ;; Invalidate the buffer, only if we were actually disabled previously.
      (tree-sitter-hl--invalidate))
    ;; TODO: Override `font-lock-extend-after-change-region-function', or hook
    ;; into `jit-lock-after-change-extend-region-functions' directly. For that to
    ;; work, we need to make sure `tree-sitter--after-change' runs before
    ;; `jit-lock-after-change'.
    (add-hook 'tree-sitter-after-change-functions
              #'tree-sitter-hl--invalidate
              nil :local)
    ;; TODO: Figure out how to properly integrate with `jit-lock-mode' directly,
    ;; without relying on `font-lock-mode'. Among other things, it would enable
    ;; highlighting without setting `font-lock-defaults'. At the moment,
    ;; `font-lock-mode' somehow helps with making sure that fontification is
    ;; updated in-time, instead of eventually.
    (add-function :around (local 'font-lock-fontify-region-function)
                  #'tree-sitter-hl--highlight-region-with-fallback)
    (tree-sitter-hl--minimize-font-lock-keywords)
    ;; XXX: We used to have a hack that calls`font-lock-turn-on-thing-lock',
    ;; which allows turning on tree-based syntax highlighting by temporarily
    ;; binding `major-mode', even though such a major mode may not be installed,
    ;; or does not exist. For example:
    ;;
    ;;     (let ((major-mode 'go-mode)) (tree-sitter-hl-mode))
    ;;
    ;; However, if `font-lock-mode' is subsequently disabled, because
    ;; `font-lock-turn-off-thing-lock' does not properly clean up the local
    ;; value of `font-lock-ensure-function', calling `font-lock-ensure' will
    ;; signal an error. For example, this happens when org-mode's code blocks
    ;; are highlighted). Therefore, we disabled that hack. See
    ;; https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/74
    ))

(defun tree-sitter-hl--teardown ()
  "Tear down `tree-sitter-hl' in the current buffer."
  (remove-function (local 'font-lock-fontify-region-function)
                   #'tree-sitter-hl--highlight-region-with-fallback)
  (remove-hook 'tree-sitter-after-change-functions
               #'tree-sitter-hl--invalidate
               :local)
  (when tree-sitter-hl--query-cursor
    (setq tree-sitter-hl--query-cursor nil)
    ;; Invalidate the buffer, only if we were actually enabled previously.
    (font-lock-flush))
  (when tree-sitter-hl--query
    (setq tree-sitter-hl--query nil)
    (tree-sitter-hl--restore-font-lock-keywords)))

;;;###autoload
(define-minor-mode tree-sitter-hl-mode
  "Toggle syntax highlighting based on Tree-sitter's syntax tree.
If `tree-sitter-hl-default-patterns' is nil, turning on this mode does nothing,
and does not interfere with `font-lock-mode'.

Enabling this automatically enables `tree-sitter-mode' in the buffer.

To enable this automatically whenever `tree-sitter-mode' is enabled:

 (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)"
  :init-value nil
  :group 'tree-sitter
  (tree-sitter--handle-dependent tree-sitter-hl-mode
    #'tree-sitter-hl--setup
    #'tree-sitter-hl--teardown))

(provide 'tree-sitter-hl)
;;; tree-sitter-hl.el ends here
