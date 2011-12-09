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


(define-module (gacela audio)
  #:use-module (gacela sdl)
  #:export (init-audio
	    quit-audio))


(define init-audio #f)
(define quit-audio #f)

(let ((audio #f))
  (set! init-audio
	(lambda ()
	  (cond ((not audio)
		 (SDL_Init SDL_INIT_AUDIO)
		 (set! audio (Mix_OpenAudio 22050 MIX_DEFAULT_FORMAT 2 4096))))))

  (set! quit-audio
	(lambda ()
	  (cond (audio
		 (Mix_CloseAudio)
		 (set! audio #f))))))
