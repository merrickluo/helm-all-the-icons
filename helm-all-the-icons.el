;;; helm-all-the-icons.el --- Helm integration with all-the-icons.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Ivan Yonchovski

;; Author: Ivan Yonchovski <yyoncho@gmail.com>
;; Keywords: convenience

;; Version: 0.1
;; URL: https://github.com/merrickluo/helm-all-the-icons
;; Package-Requires: ((emacs "25.1") (dash "2.14.1") (f "0.20.0") (all-the-icons "4.0.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received candidate copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; helm -> all-the-icons.el integration

;;; Code:

(require 'all-the-icons)
(require 'dash)

(defgroup helm-all-the-icons nil
  "Helm all-the-icons."
  :group 'helm)

(defun helm-all-the-icons-buffers-add-icon (candidates _source)
  "Add icon to buffers source.
CANDIDATES is the list of candidates."
  (-map (-lambda ((display . buffer))
          (cons (concat
                 (with-current-buffer buffer
                   (all-the-icons-icon-for-buffer))
                 "\u2009"
                 display)
                buffer))
        candidates))

(defun helm-all-the-icons-files-add-icons (candidates _source)
  "Add icon to files source.
CANDIDATES is the list of candidates."
  (-map (-lambda (candidate)
          (-let [(display . file-name) (if (listp candidate)
                                           candidate
                                         (cons candidate candidate))]
            (cons (concat (cond
                           ((f-dir? file-name) (all-the-icons-icon-for-dir file-name))
                           ((all-the-icons-icon-for-file file-name)))
                          "\u2009"
                          display)
                  file-name)))
        candidates))

(defun helm-all-the-icons-add-transformer (fn source)
  "Add FN to `filtered-candidate-transformer' slot of SOURCE."
  (setf (alist-get 'filtered-candidate-transformer source)
        (-uniq (append
                (-let [value (alist-get 'filtered-candidate-transformer source)]
                  (if (seqp value) value (list value)))
                (list fn)))))

(defun helm-all-the-icons--make (orig name class &rest args)
  "The advice over `helm-make-source'.
ORIG is the original function.
NAME, CLASS and ARGS are the original params."
  (let ((result (apply orig name class args)))
    (cl-case class
      ((helm-recentf-source helm-source-ffiles helm-locate-source helm-fasd-source
                            )
       (helm-all-the-icons-add-transformer
        #'helm-all-the-icons-files-add-icons
        result))
      ((helm-source-buffers helm-source-projectile-buffer)
       (helm-all-the-icons-add-transformer
        #'helm-all-the-icons-buffers-add-icon
        result)))
    (cond
     ((or (-any? (lambda (source-name) (s-match source-name name))
                 '("Projectile files"
                   "Projectile projects"
                   "Projectile directories"
                   "Projectile recent files"
                   "Projectile files in current Dired buffer"
                   "dired-do-rename.*"
                   "Elisp libraries (Scan)")))
      (helm-all-the-icons-add-transformer
       #'helm-all-the-icons-files-add-icons
       result)))
    result))

;;;###autoload
(defun helm-all-the-icons-enable ()
  "Enable `helm-all-the-icons'."
  (interactive)
  (advice-add 'helm-make-source :around #'helm-all-the-icons--make))

(provide 'helm-all-the-icons)
;;; helm-all-the-icons.el ends here
