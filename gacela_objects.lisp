;;; Gacela, a GNU Common Lisp extension for fast games development
;;; Copyright (C) 2009 by Javier Sancho Fernandez <jsf at jsancho dot org>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


(eval-when (compile load eval)
	   (when (not (find-package 'gacela)) (make-package 'gacela :nicknames '(gg) :use '(lisp)))
	   (in-package 'gacela :nicknames '(gg) :use '(lisp)))


;;; Behaviours of objects

(defmacro make-behaviour (name attr &rest code)
  `(defun ,(get-behaviour-fun-name name) (object-attr)
     (let ,(mapcar #'attribute-definition attr)
       ,@code
       ,(cons 'progn (mapcar #'attribute-save (reverse attr)))
       object-attr)))

(defun get-behaviour-fun-name (name)
  (intern (concatenate 'string "BEHAVIOUR-" (string-upcase (string name))) 'gacela))

(defun attribute-name (attribute)
  (intern (string attribute) 'keyword))

(defun attribute-definition (attribute)
  (let* ((name (cond ((listp attribute) (car attribute))
		     (t attribute)))
	 (pname (attribute-name name))
	 (value (cond ((listp attribute) (cadr attribute)))))
    `(,name (getf object-attr ,pname ,value))))

(defun attribute-save (attribute)
  (let* ((name (cond ((listp attribute) (car attribute))
		     (t attribute)))
	 (pname (attribute-name name)))
    `(setf (getf object-attr ,pname) ,name)))



;;; Objects Factory

(let (active-objects objects-to-add objects-to-kill)
  (defun add-object (object)
    (pushnew object objects-to-add))

  (defun kill-object (object)
    (pushnew object objects-to-kill))

  (defun kill-all-objects ()
    (setq active-objects nil objects-to-add nil objects-to-kill nil))

  (defun refresh-active-objects ()
    (cond (objects-to-add
	   (setq active-objects (union active-objects objects-to-add))
	   (setq objects-to-add nil)))
    (cond (objects-to-kill
	   (setq active-objects (reverse (set-difference active-objects objects-to-kill)))
	   (setq objects-to-kill nil))))

  (defun bhv-objects ()
    (dolist (o active-objects) (funcall o :action)))

  (defun render-objects ()
    (dolist (o active-objects) (funcall o :render))))


(defmacro make-object (name attr bhv &body look)
  `(progn
     (let ((attr ,(cond (attr (cons 'list (make-object-attributes attr)))))
	   (bhv ,(cond (bhv (cons 'list (make-object-behaviour bhv))))))
       (defun ,name (option &rest param)
	 (case option
	       (:action (dolist (b bhv t) (setq attr (funcall (get-behaviour-fun-name b) attr))))
	       (:get-attr attr)
	       (:get-bhv bhv)
	       (:set-bhv (setq bhv (car param)))
	       (:render (glPushMatrix)
			,@(mapcar (lambda (x) (if (stringp x) `(draw-image ,x) x)) look)
			(glPopMatrix)))))
     (add-object ',name)
     ',name))

(defun make-object-attributes (attr)
  (cond ((or (null attr) (atom attr)) nil)
	(t (let ((rest (make-object-attributes (cdr attr)))
		 (this (object-attribute-definition (car attr))))
	     (setf (getf rest (car this)) (cadr this))
	     rest))))

(defun object-attribute-definition (attribute)
  (let* ((name (cond ((listp attribute) (car attribute))
		     (t attribute)))
	 (pname (attribute-name name))
	 (value (cond ((listp attribute) (cadr attribute)))))
    `(,pname ,value)))

(defun make-object-behaviour (bhv)
  (cond ((null bhv) nil)
	((atom bhv) (list bhv))
	(t bhv)))