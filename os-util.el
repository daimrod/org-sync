;;; os-utils.el --- Utility functions for org-sync.

;; Copyright (C) 2013  Albert Krewinkel
;;
;; Author: Albert Krewinkel <tarleb+org-sync@moltkeplatz.de>
;; Keywords: org, synchronization, json
;; Homepage: http://orgmode.org/worg/org-contrib/gsoc2012/student-projects/org-sync
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; This file is not part of GNU Emacs.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides utility functions for org-sync.

;;; Code:

(eval-when-compile (require 'cl))
(require 'url)
(require 'json)

(defvar org-sync-util-default-encoding 'utf-8
  "Default encoding expected in server responses.")

(defvar org-sync-util-debug nil
  "If non-nil, show debug messages.")

(defun org-sync-util-get-coding-system (encoding)
  "Find the coding system specified by `encoding' or nil if none is found.
This method accepts either a string or a symbol, the case of
which is ignored."
  (let ((coding-system (cl-assoc encoding coding-system-alist :test 'equalp)))
    (if coding-system
        (intern (car coding-system))
      nil)))

(defun org-sync-util-get-response-encoding (&optional bound)
  "Get encoding charset from a http response header."
  (save-excursion
    (goto-char (point-min))
    (let ((noerror t)
          (content-type-regex
           "^Content-Type: application/json;? *\\(charset=\\(.*\\)\\b\\)?$"))
      (when (<= 0 (search-forward-regexp content-type-regex bound noerror))
        (org-sync-util-get-coding-system (match-string 2))))))

(defun org-sync-util-ensure-correct-encoding (end-of-headers)
  "Make sure that the data returned by a server is interpreted in
  the right encoding."
  (let* ((resp-encoding (org-sync-util-get-response-encoding end-of-headers))
         (new-encoding (or resp-encoding
                           org-sync-util-default-encoding))
         (old-encoding buffer-file-coding-system))
    (unless (coding-system-equal new-encoding old-encoding)
      (recode-region end-of-headers (point-max) new-encoding old-encoding))))

(defun org-sync-util-read-json-from-response-buffer (buffer &optional keep-buffer)
  "Get JSON data from `buffer', then kill the buffer unless
`keep-buffer' is non-nil."
  (with-current-buffer buffer
    (toggle-enable-multibyte-characters 1)
    (org-sync-util-ensure-correct-encoding url-http-end-of-headers)
    (goto-char url-http-end-of-headers)
    (when org-sync-util-debug
      (message "%s" (buffer-substring (point) (point-max))))
    (prog1
        (cons url-http-response-status (ignore-errors (json-read)))
      (unless keep-buffer
        (kill-buffer)))))

(defun org-sync-util-read-json-from-url (url)
  "Get JSON data from url"
  (setq buffer (url-retrieve-synchronously url))
  (org-sync-util-read-json-from-response-buffer buffer))

(provide 'os-util)
;; os-util.el ends here
