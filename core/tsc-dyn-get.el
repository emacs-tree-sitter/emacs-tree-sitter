;;; tsc-dyn-get.el --- Utilities to obtain tsc-dyn -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020  Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file contains the utilities to obtain the dynamic module `tsc-dyn', by
;; either downloading pre-built binaries or building from source.

;;; Code:

(require 'seq)
(require 'dired-aux)
(require 'compile)

(eval-when-compile
  (require 'subr-x)
  (require 'cl-lib))

(eval-when-compile
  ;; Version string set by `tsc-dyn' when it's loaded.
  (defvar tsc-dyn--version))

(defconst tsc-dyn-get--version-file "DYN-VERSION"
  "File that records the version after getting the binary from a source.")

(defconst tsc--dir (file-name-directory (or (locate-library "tsc.el") ""))
  "The directory where the library `tsc' is located.")

(defgroup tsc nil
  "Core tree-sitter APIs."
  :group 'languages)

(defcustom tsc-dyn-dir tsc--dir
  "The directory that `tsc-dyn' module is resided.
This should be set before `tsc' is loaded.

In Windows you may want to set this to prevent package upgrade failure by loaded
module deletion. See ubolonton/emacs-tree-sitter#122 for more detail.

Example setting:
\(setq tsc-dyn-dir (expand-file-name \"tree-sitter/\" user-emacs-directory))"
  :group 'tsc
  :type 'directory)

(defcustom tsc-dyn-get-from '(:github :compilation)
  "Where the dynamic module binary should come from, in order of priority.

For pre-built binaries, it attempts to download the requested version.

For local compilation, the Rust toolchain is required.

If you want to manually get the dynamic module through another mechanism,
instead of letting `tsc-dyn-get' automatically try to download/build it, set
this to nil."
  :group 'tsc
  :type '(set (const :tag "Binary from GitHub" :github)
              (const :tag "Local Compilation" :compilation)))

(defvar tsc-dyn-get--force-sync nil)

(defun tsc-dyn-get--dir ()
  "Return the directory to put `tsc-dyn' module in."
  (or tsc-dyn-dir
      (error "Could not locate the directory for `tsc-dyn'")))

(defun tsc-dyn-get--ext ()
  "Return the dynamic module extension, which is system-dependent."
  (pcase system-type
    ('windows-nt "dll")
    ('darwin "dylib")
    ((or 'gnu 'gnu/linux 'gnu/kfreebsd 'berkeley-unix) "so")
    ((or 'ms-dos 'cygwin) (error "Unsupported system-type %s" system-type))
    (_ "so")))

(defun tsc-dyn-get--file ()
  "Return the dynamic module filename, which is OS-dependent."
  (format "tsc-dyn.%s" (tsc-dyn-get--ext)))

;;; TODO: Make this correct.
(defun tsc-dyn-get--system-specific-file ()
  "Return the dynamic module filename, which is system-dependent."
  (pcase system-type
    ('windows-nt "tsc-dyn.x86_64-pc-windows-msvc.dll")
    ('darwin (if (string-prefix-p "x86_64" system-configuration)
                 "tsc-dyn.x86_64-apple-darwin.dylib"
               "tsc-dyn.aarch64-apple-darwin.dylib"))
    ((or 'gnu 'gnu/linux 'gnu/kfreebsd)
     "tsc-dyn.x86_64-unknown-linux-gnu.so")))

(defun tsc-dyn-get--log (format-string &rest args)
  (apply #'message (concat "tsc-dyn-get: " format-string) args))

(defun tsc-dyn-get--warn (&rest args)
  (display-warning 'tsc-dyn-get (apply #'format args) :emergency))

(defun tsc-dyn-get--recorded-version ()
  "Return the `tsc-dyn' version recorded in the manifest
`tsc-dyn-get--version-file'."
  (let ((default-directory (tsc-dyn-get--dir)))
    (when (file-exists-p tsc-dyn-get--version-file)
      (with-temp-buffer
        (let ((coding-system-for-read 'utf-8))
          (insert-file-contents tsc-dyn-get--version-file)
          (buffer-string))))))

(defun tsc-dyn-get--loaded-version ()
  "Return the currently loaded version of `tsc-dyn'."
  (and (featurep 'tsc-dyn) (bound-and-true-p tsc-dyn--version)))

;;; ----------------------------------------------------------------------------
;;; Pre-built binaries downloaded through HTTP.

(defun tsc-dyn-get--check-http (&rest _args)
  (when-let ((status (bound-and-true-p url-http-response-status)))
    (when (>= status 400)
      (error "Got HTTP status code %s" status))))

;; TODO: Find a better way to make `url-copy-file' handle bad HTTP status codes.
(defun tsc-dyn-get--url-copy-file (&rest args)
  "A wrapper around `url-copy-file' that signals errors for bad HTTP statuses."
  (advice-add 'mm-dissect-buffer :before #'tsc-dyn-get--check-http)
  (unwind-protect
      (apply #'url-copy-file args)
    (advice-remove 'mm-dissect-buffer #'tsc-dyn-get--check-http)))

(defun tsc-dyn-get--github (version)
  "Download the pre-compiled VERSION of `tsc-dyn' from GitHub.
This function records the downloaded version in the manifest
`tsc-dyn-get--version-file'."
  (let* ((bin-dir (tsc-dyn-get--dir))
         (default-directory bin-dir)
         (_ (unless (file-directory-p bin-dir) (make-directory bin-dir)))
         (uncompressed? (version< "0.7.0" version))
         (system-specific? (version<= "0.16.1" version))
         (local-name (tsc-dyn-get--file))
         (remote-name (format "%s%s"
                              (if system-specific?
                                  (tsc-dyn-get--system-specific-file)
                                local-name)
                              (if uncompressed? "" ".gz")))
         (url (format "https://github.com/emacs-tree-sitter/elisp-tree-sitter/releases/download/%s/%s"
                      version remote-name)))
    (tsc-dyn-get--log "Downloading %s" url)
    (if uncompressed?
        (tsc-dyn-get--url-copy-file url local-name :ok-if-already-exists)
      (tsc-dyn-get--url-copy-file url remote-name)
      (when (file-exists-p local-name)
        (delete-file local-name))
      ;; XXX: Uncompressing with `dired-compress-file' doesn't work on Windows.
      (dired-compress-file remote-name))
    (with-temp-file tsc-dyn-get--version-file
      (let ((coding-system-for-write 'utf-8))
        (insert version)))))

;;; ----------------------------------------------------------------------------
;;; Local compilation.

(define-error 'tsc-compile-error "Could not compile `tsc-dyn'")

(defun tsc-dyn-get--build-output (face &rest args)
  (declare (indent 1))
  (let ((str (propertize (apply #'format args) 'face face 'font-lock-face face))
        (inhibit-read-only t))
    (if noninteractive
        (progn (princ str) (princ "\n"))
      (insert str)
      (insert "\n"))))

(defmacro tsc-dyn-get--compilation-to-stdout (condition &rest body)
  "Eval BODY forms with compilation output conditionally redirected to `princ'."
  (declare (indent 1))
  (let ((print-stdout (make-symbol "print-stdout")))
    `(if ,condition
         (let ((,print-stdout (lambda (_proc string) (princ string))))
           (advice-add 'compilation-filter :override ,print-stdout)
           (unwind-protect
               (progn ,@body)
             (advice-remove 'compilation-filter ,print-stdout)))
       ,@body)))

(defun tsc-dyn-get--build-version ()
  "Return the dynamic module's version after asking 'cargo'."
  (thread-first (shell-command-to-string "cargo pkgid")
    string-trim
    (split-string "\[#:@\]")
    last car))

;; TODO: Remove this when cargo allows specifying output file name.
(defun tsc-dyn-get--out-file ()
  "Return cargo's output filename, which is system-dependent."
  (let ((base (pcase system-type
                ('windows-nt "tsc_dyn")
                (_ "libtsc_dyn"))))
    (format "%s.%s" base (tsc-dyn-get--ext))))

(defun tsc-dyn-get--build-cleanup (comp-buffer status)
  "Clean up after compiling the dynamic module `tsc-dyn'.
This function copies the built binary to the appropriate location, delete the
build directory, and record the built version in the manifest
`tsc-dyn-get--version-file'."
  (with-current-buffer comp-buffer
    (let* ((file (tsc-dyn-get--file))
           (out-name (tsc-dyn-get--out-file))
           (out-file (format "target/release/%s" out-name)))
      (unless (string= status "finished\n")
        (signal 'tsc-compile-error
                (list (format "Compilation failed with status: %s" status))))
      (tsc-dyn-get--build-output 'compilation-info
        "Moving binary %s from build dir" out-name)
      (condition-case _
          (rename-file out-file file)
        (file-already-exists
         (delete-file file)
         (rename-file out-file file)))
      (tsc-dyn-get--build-output 'compilation-info
        "Removing build dir")
      (delete-directory "target" :recursive)
      (tsc-dyn-get--build-output 'compilation-info
        "Recording built version in %s" tsc-dyn-get--version-file)
      (with-temp-file tsc-dyn-get--version-file
        (let ((coding-system-for-write 'utf-8))
          (insert (tsc-dyn-get--build-version))))
      (tsc-dyn-get--build-output 'success "Done"))))

;; XXX: We don't use `call-process' because the process it creates is not killed
;; when Emacs exits in batch mode. That's probably an Emacs's bug.
(defun tsc-dyn-get--build-sync (dir)
  "Build the dynamic module `tsc-dyn' and put it in DIR, blocking until done."
  ;; FIX: Figure out how to print the progress bar when run synchronously.
  (tsc-dyn-get--compilation-to-stdout noninteractive
    (let ((proc (tsc-dyn-get--build-async dir)))
      (condition-case s
          (while (accept-process-output proc)
            (unless noninteractive
              (redisplay)))
        (quit (let ((buf (process-buffer proc)))
                (set-process-query-on-exit-flag proc nil)
                (interrupt-process proc)
                (with-current-buffer buf
                  (tsc-dyn-get--build-output 'error "Cancelled")
                  ;; TODO: Don't wait for a fixed amount of time.
                  (sit-for 1)
                  (kill-buffer)))
              (signal (car s) (cdr s)))))))

(defun tsc-dyn-get--build-async (dir)
  "Build the dynamic module `tsc-dyn' and put it in DIR, asynchrounously."
  (let* ((default-directory dir)
         (compilation-auto-jump-to-first-error nil)
         (compilation-scroll-output t)
         ;; We want responsive progress bar. It's ok since the output is small.
         (process-adaptive-read-buffering nil)
         (comp-buffer (compilation-start
                       "cargo build --release"
                       nil (lambda (_) "*tsc-dyn compilation*")))
         (proc (get-buffer-process comp-buffer)))
    (with-current-buffer comp-buffer
      (setq-local compilation-error-regexp-alist nil)
      (add-hook 'compilation-finish-functions #'tsc-dyn-get--build-cleanup
                nil :local)
      (unless noninteractive
        (when (functionp 'ansi-color-apply-on-region)
          (add-hook 'compilation-filter-hook
            (lambda () (ansi-color-apply-on-region (point-min) (point-max)))
            nil :local))))
    proc))

(defun tsc-dyn-get--build (&optional dir)
  "Build the dynamic module `tsc-dyn' from source.

When called during an attempt to load `tsc', or in batch mode, this blocks until
compilation finishes. In other situations, it runs in the background.

This function records the built version in the manifest
`tsc-dyn-get--version-file'.

On Windows, if `tsc-dyn' has already been loaded, compilation will fail because
the OS doesn't allow overwriting opened dynamically-loaded libraries."
  (unless dir (setq dir tsc--dir))
  (while (not (executable-find "cargo"))
    (if noninteractive
        (signal 'tsc-compile-error "Could not find `cargo' executable")
      ;; TODO: Make a better prompt.
      (unless (y-or-n-p
               (format "Could not find `cargo' executable.
Please press '%s' after installing the Rust toolchain (e.g. from https://rustup.rs/).
Press '%s' to cancel. "
                       (propertize "y" 'face 'bold)
                       (propertize "n" 'face 'error)))
        (signal 'tsc-compile-error "Compilation was cancelled"))))
  (if (or noninteractive
          (not (featurep 'tsc-dyn))
          tsc-dyn-get--force-sync)
      (tsc-dyn-get--build-sync dir)
    ;; TODO: Notify user for further actions. If `tsc' has not been loaded,
    ;; offer to load it. If it has already been loaded, offer to restart Emacs
    ;; to be able to load the newly built `tsc-dyn'.
    (tsc-dyn-get--build-async dir)))

;;; ----------------------------------------------------------------------------
;;; Generic mechanism.

(defun tsc--module-load-noerror (file)
  "Try loading `tsc-dyn' from FILE.
Return nil if the file does not exist, or is not a loadable shared library."
  (or (featurep 'tsc-dyn)
      (condition-case _
          (module-load file)
        (module-open-failed nil))))

;; On macOS, we use`.dylib', which is more sensible than `.so'.
;;
;; XXX: Using `require' after setting`module-file-suffix' to `.dylib' results in
;; "Cannot open load file: No such file or directory, tsc-dyn".
;;
;; XXX: Using `load' results in an error message with garbled text: "Symbol’s
;; value as variable is void: Ïúíþ".
;;
;; Therefore, we need to search for the file and use `module-load' directly.
(defun tsc-dyn--try-load-mac ()
  "Search and load the dynamic module on macOS."
  (let ((file "tsc-dyn.dylib"))
    ;; Try directory containing `load-file-name'. Typical case. TODO: Remove
    ;; this special case.
    (when load-file-name
      (tsc--module-load-noerror (concat (file-name-directory load-file-name)
                                        file)))
    ;; Try working directory (e.g. when invoked by `eask'). TODO: Modifying load
    ;; path when using `eask' instead.
    (tsc--module-load-noerror file)
    ;; Fall back to `load-path'.
    (seq-find (lambda (dir)
                (let ((full-name (concat (file-name-as-directory
                                          (expand-file-name dir))
                                         file)))
                  (tsc--module-load-noerror full-name)))
              load-path)))

(defun tsc-dyn--try-load ()
  "Try loading `tsc-dyn' without signaling an error.
Return t on success, nil otherwise."
  (if (featurep 'tsc-dyn)
      t
    (when (eq system-type 'darwin)
      (tsc-dyn--try-load-mac))
    (require 'tsc-dyn nil :noerror)))

;; TODO: Add tests for this.
(defun tsc-dyn-get-ensure (requested)
  "Try to get and load the REQUESTED (or later) version of `tsc-dyn'.

If this function cannot find a suitable version on `load-path', it tries to get
the dynamic module from sources listed in `tsc-dyn-get-from'.

NOTE: Emacs cannot unload dynamic modules, so if `tsc-dyn' was already loaded,
you will need to restart Emacs to load the new version."
  (let* ((default-directory (tsc-dyn-get--dir))
         (recorded (tsc-dyn-get--recorded-version))
         (loaded (tsc-dyn-get--loaded-version))
         (load-path (cons (tsc-dyn-get--dir) load-path))
         (tsc-dyn-get--force-sync t)
         get-new)
    (cl-block nil
      (dolist (source tsc-dyn-get-from)
        (tsc-dyn-get--log "Using source %s (:loaded %s :recorded %s :requested %s)"
                          source loaded recorded requested)
        (setq get-new (pcase source
                        (:github (lambda () (tsc-dyn-get--github requested)))
                        (:compilation (lambda () (tsc-dyn-get--build)))
                        (_ (error "Don't know how to get `tsc-dyn' from source %s" source))))
        (with-demoted-errors "Could not get `tsc-dyn': %s"
          (cond
           (loaded (if (version<= requested loaded)
                       (tsc-dyn-get--log "Loaded version already satisfies requested -> skipping")
                     ;; TODO: On Windows, refuse to continue and ask user to set
                     ;; the requested version and restart instead.
                     (tsc-dyn-get--log "Loaded version is older than requested -> getting new")
                     (funcall get-new)))
           (recorded (if (version<= requested recorded)
                         (progn
                           (tsc-dyn-get--log "Recorded version already satifies requested -> loading")
                           (unless (tsc-dyn--try-load)
                             ;; The version file may have been accidentally deleted.
                             (tsc-dyn-get--log "Could not load -> getting new")
                             (funcall get-new)
                             (tsc-dyn--try-load)))
                       (tsc-dyn-get--log "Recorded version is older than requested -> getting new")
                       (funcall get-new)
                       (tsc-dyn--try-load)))
           (t (funcall get-new)
              (tsc-dyn--try-load)))
          (when (featurep 'tsc-dyn)
            (cl-return)))))
    (if (and loaded (version< loaded requested))
        (tsc-dyn-get--warn "Version %s is requested, but %s was already loaded. Please try restarting Emacs."
                           requested loaded)
      ;; Even if none of the sources worked, the module may still be there.
      (tsc-dyn--try-load)
      (if-let ((loaded (tsc-dyn-get--loaded-version)))
          (when (version< loaded requested)
            (tsc-dyn-get--warn "Version %s is requested, but actual version after loading is %s."
                               requested loaded))
        (tsc-dyn-get--warn "Failed to get requested version %s." requested)))
    (tsc-dyn-get--loaded-version)))

(provide 'tsc-dyn-get)
;;; tsc-dyn-get.el ends here
