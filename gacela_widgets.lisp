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


(in-package :gacela)

;;; Timers

(defstruct timer (start 0) (paused 0) (state 'stopped))

(defun start-timer (timer)
  (setf (timer-start timer) (SDL_GetTicks))
  (setf (timer-state timer) 'running))

(defun stop-timer (timer)
  (setf (timer-state timer) 'stopped))

(defun get-time (timer)
  (cond ((eq (timer-state timer) 'stopped) 0)
        ((eq (timer-state timer) 'paused) (timer-paused timer))
        (t (- (SDL_GetTicks) (timer-start timer)))))

(defun pause-timer (timer)
  (cond ((eq (timer-state timer) 'running)
         (setf (timer-paused timer) (- (SDL_GetTicks) (timer-start timer)))
         (setf (timer-state timer) 'paused))))

(defun resume-timer (timer)
  (cond ((eq (timer-state timer) 'paused)
         (setf (timer-start timer) (- (SDL_GetTicks) (timer-paused timer)))
         (setf (timer-state timer) 'running))))

