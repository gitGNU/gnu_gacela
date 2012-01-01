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


(define-module (gacela gacela)
  #:use-module (gacela events)
  #:use-module (gacela video)
  #:use-module (gacela audio)
  #:use-module (ice-9 optargs)
  #:export (load-texture
	    load-font
	    *title*
	    *width-screen*
	    *height-screen*
	    *bpp-screen*
	    *frames-per-second*
	    *mode*
	    set-game-properties!
	    get-game-properties
	    init-gacela
	    quit-gacela
	    game-loop
	    game-running?
	    set-game-code)
  #:export-syntax (game)
  #:re-export (get-current-color
	       set-current-color
	       with-color
	       progn-textures
	       draw
	       draw-texture
	       draw-line
	       draw-quad
	       draw-rectangle
	       draw-square
	       draw-cube
	       translate
	       rotate
	       to-origin
	       add-light
	       set-camera
	       camera-look
	       render-text))


;;; Resources Cache

(define resources-cache (make-weak-value-hash-table))

(define (from-cache key)
  (hash-ref resources-cache key))

(define (into-cache key res)
  (hash-set! resources-cache key res))

(define-macro (use-cache-with module proc)
  (let* ((pwc (string->symbol (string-concatenate (list (symbol->string proc) "-without-cache")))))
    `(begin
       (define ,pwc (@ ,module ,proc))
       (define (,proc . param)
	 (let* ((key param)
		(res (from-cache key)))
	   (cond (res
		  res)
		 (else
		  (set! res (apply ,pwc param))
		  (into-cache key res)
		  res)))))))

(use-cache-with (gacela video) load-texture)
(use-cache-with (gacela video) load-font)


;;; Main Loop

(define loop-flag #f)
(define game-code #f)
(define game-loop-thread #f)

(define-macro (game . code)
  `(let ((game-function ,(if (null? code)
			     `(lambda () #f)
			     `(lambda () ,@code))))
     (set-game-code game-function)
     (cond ((not (game-running?))
	    (game-loop)))))

(define-macro (run-in-game-loop . code)
  `(if game-loop-thread
       (system-async-mark (lambda () ,@code) game-loop-thread)
       (begin ,@code)))

(define (init-gacela)
  (set! game-loop-thread (call-with-new-thread (lambda () (game)))))

(define (quit-gacela)
  (set! game-loop-thread #f)
  (set! loop-flag #f))

(define (game-loop)
;	  (refresh-active-mobs)
  (set! loop-flag #t)
  (init-video *width-screen* *height-screen* *bpp-screen* #:title *title* #:mode *mode* #:fps *frames-per-second*)
  (while loop-flag
	 (init-frame-time)
;	    (check-connections)
	 (process-events)
	 (cond ((quit-signal?)
		(quit-gacela))
	       (else
		(clear-screen)
		(to-origin)
;		   (refresh-active-mobs)
		(if (procedure? game-code)
		    (catch #t
			   (lambda () (game-code))
			   (lambda (key . args) #f)))
;			  (run-mobs)
		(flip-screen)
		(delay-frame))))
  (quit-video))

(define (game-running?)
  loop-flag)

(define (set-game-code game-function)
  (set! game-code game-function))


;;; Game Properties

(define *title* "Gacela")
(define *width-screen* 640)
(define *height-screen* 480)
(define *bpp-screen* 32)
(define *frames-per-second* 20)
(define *mode* '2d)

(define* (set-game-properties! #:key title width height bpp fps mode)
  (if title
      (set-screen-title! title))
  (if bpp
      (run-in-game-loop (set-screen-bpp! bpp)))
  (if (or width height)
      (begin
	(if (not width) (set! width (get-screen-width)))
	(if (not height) (set! height (get-screen-height)))
	(run-in-game-loop (resize-screen width height))))
  (if fps
      (set-frames-per-second! fps))
  (if mode
      (if (eq? mode '3d) (set-3d-mode) (set-2d-mode))))

(define (get-game-properties)
  `((title . ,(get-screen-title)) (width . ,(get-screen-width)) (height . ,(get-screen-height)) (bpp . ,(get-screen-bpp)) (fps . ,(get-frames-per-second)) (mode . ,(if (3d-mode?) '3d '2d))))
