;;; Gacela, a GNU Guile extension for fast games development
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


(use-modules (srfi srfi-1))

;;; Mob Factory

(define-macro (makemob name . methods)
  `(define* (,name . args)
     (let ((option (car args)))
       ,(union
	 `(case option
	    (:on (mob-on ',name))
	    (:off (mob-off ',name)))
	 (define (options m)
	   (let ((option (car m)) (body (cadr m)))
	     (cond ((null? m) '())
		   (else (cons (list option `(apply ,body (cdr args))) (options (cddr m)))))))
	 (options methods)))))


(define mob-on #f)
(define run-mobs #f)
(define mob-off #f)
(define refresh-running-mobs #f)
(define quit-all-mobs #f)

(let ((running-mobs '()) (mobs-to-add '()) (mobs-to-quit '()))
  (set! mob-on
	(lambda (mob)
	  (push mob mobs-to-add)))

  (set! run-mobs
	(lambda* (option #:key args function)
	  (define (run-mobs-rec mobs)
	    (cond ((null? mobs) #f)
		  (else
		   (cond (function (function)))
		   (catch #t (lambda () (apply (car mobs) (cons option args))) (lambda (key . args) #f))
		   (or #t (run-mobs-rec (cdr mobs))))))))

  (set! mob-off
	(lambda (mob)
	  (push mob mobs-to-quit)))

  (set! refresh-running-mobs
	(lambda ()
	  (do ((mob (pop mobs-to-add) (pop mobs-to-add))) ((null? mob))
	    (push mob running-mobs)
	    (secure-block nil (mob #:init)))
	  (set! running-mobs (reverse (lset-difference eq? running-mobs mobs-to-quit)))
	  (set! mobs-to-quit '())))

  (set! quit-all-mobs
	(lambda ()
	  (set! running-mobs '())
	  (set! mobs-to-add '())
	  (set! mobs-to-quit '()))))


(define (logic-mobs)
  (run-mobs #:logic))

(define (render-mobs)
  (run-mobs #:render #:function (lambda () (glLoadIdentity))))