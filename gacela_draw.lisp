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

(let ((mode '2d))
  (defun 2d-mode ()
    (glDisable GL_DEPTH_TEST)
    (setq mode '2d))

  (defun 3d-mode ()
    (glEnable GL_DEPTH_TEST)
    (setq mode '3d))

  (defun 3d-mode? ()
    (eq mode '3d)))

(defun draw (&rest vertexes)
  (begin-draw (length vertexes))
  (draw-vertexes vertexes)
  (glEnd))

(defun begin-draw (number-of-points)
  (cond ((= number-of-points 3) (glBegin GL_TRIANGLES))
	((= number-of-points 4) (glBegin GL_QUADS))))

(defun draw-vertexes (vertexes)
  (cond ((null vertexes) nil)
	(t (draw-vertex (car vertexes))
	   (draw-vertexes (cdr vertexes)))))

(defun draw-vertex (vertex &key texture-coord)
  (cond ((consp (car vertex)) (draw-color (car vertex)) (apply #'simple-draw-vertex (cadr vertex)))
	(t (cond (texture-coord (apply #'glTexCoord2f texture-coord)))
	   (apply #'simple-draw-vertex vertex))))

(defun simple-draw-vertex (x y &optional (z 0))
  (cond ((3d-mode?) (glVertex3f x y z))
	(t (glVertex2f x y))))

(defun draw-color (color)
  (apply #'glColor3f color))

(defun load-image-for-texture (filename)
  (init-video-mode)
  (let ((image (IMG_Load filename)))
    (cond ((/= image 0)
	   (let* ((width (surface-w image)) (height (surface-h image))
		  (power-2 (nearest-power-of-two (min width height)))
		  (zoomx (/ power-2 width)) (zoomy (/ power-2 height))
		  zoomed-image)
	     (cond ((and (= zoomx 1) (= zoomy 1)) (values image width height))
		   (t (setq zoomed-image (zoomSurface image zoomx zoomy 0))
		      (SDL_FreeSurface image)
		      (cond ((/= zoomed-image 0) (values zoomed-image width height))))))))))

(defun load-texture (filename &optional (min-filter GL_LINEAR) (mag-filter GL_LINEAR))
  (init-textures)
  (init-video-mode)
  (multiple-value-bind
   (image real-w real-h) (load-image-for-texture filename)
        (cond (image
	       (let ((width (surface-w image)) (height (surface-h image))
		     (byteorder (cond 
		     (texture (car (glGenTextures 1))))
		 (glBindTexture GL_TEXTURE_2D texture)
		 (glTexImage2D GL_TEXTURE_2D 0 3 width height 0 GL_RGBA GL_UNSIGNED_BYTE (surface-pixels image))
		 (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER min-filter)
		 (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER mag-filter)
		 (SDL_FreeSurface image)
		 (values texture real-w real-h))))))

(defun draw-image-function (filename)
  (multiple-value-bind
   (texture width height) (load-texture filename)
        (cond (texture
	       (lambda (&optional (f 1))
		 (draw-rectangle (* f width) (* f height) :texture texture))))))

(defun draw-quad (v1 v2 v3 v4 &key texture color)
  (cond (texture (glBindTexture GL_TEXTURE_2D texture)
		 (begin-draw 4)
		 (draw-vertex v1 :texture-coord '(0 0))
		 (draw-vertex v2 :texture-coord '(1 0))
		 (draw-vertex v3 :texture-coord '(1 1))
		 (draw-vertex v4 :texture-coord '(0 1))
		 (glEnd))
	(t (cond (color (draw-color color)))
	   (draw v1 v2 v3 v4))))

(defun draw-rectangle (width height &key texture color)
  (let* ((w (/ width 2)) (-w (neg w)) (h (/ height 2)) (-h (neg h)))
    (draw-quad (list -w h 0) (list w h 0) (list w -h 0) (list -w -h 0) :texture texture :color color)))

(defun draw-square (&key (size 1) texture color)
  (draw-rectangle size size :texture texture :color color))

(defun draw-cube (&key size texture color)
  (let ((-size (neg size)))
    (enable :textures texture)
    (glNormal3f 0 0 1)
    (draw-quad (list -size size size) (list size size size) (list size -size size) (list -size -size size) :texture texture :color color)
    (glNormal3f 0 0 -1)
    (draw-quad (list -size -size -size) (list size -size -size) (list size size -size) (list -size size -size) :texture texture :color color)
    (glNormal3f 0 1 0)
    (draw-quad (list size size size) (list -size size size) (list -size size -size) (list size size -size) :texture texture :color color)
    (glNormal3f 0 -1 0)
    (draw-quad (list -size -size size) (list size -size size) (list size -size -size) (list -size -size -size) :texture texture :color color)
    (glNormal3f 1 0 0)
    (draw-quad (list size -size -size) (list size -size size) (list size size size) (list size size -size) :texture texture :color color)
    (glNormal3f -1 0 0)
    (draw-quad (list -size -size size) (list -size -size -size) (list -size size -size) (list -size size size) :texture texture :color color)))

(defun add-light (&key light position ambient (id GL_LIGHT1) (turn-on t))
  (init-lighting)
  (and light (glLightfv id GL_DIFFUSE (first light) (second light) (third light) (fourth light)))
  (and light position (glLightfv GL_POSITION (first position) (second position) (third position) (fourth position)))
  (and ambient (glLightfv id GL_AMBIENT (first ambient) (second ambient) (third ambient) (fourth ambient)))
  (and turn-on (glEnable id))
  id)

(defun translate (x y &optional (z 0))
  (glTranslatef x y z))

(defun rotate (xrot yrot &optional zrot)
  (glRotatef xrot 1 0 0)
  (glRotatef yrot 0 1 0)
  (cond (zrot (glRotatef zrot 0 0 1))))

(defun enable (&key textures)
  (cond (textures (glEnable GL_TEXTURE_2D))))

#if SDL_BYTEORDER == SDL_LIL_ENDIAN
    if (surface -> format -> BytesPerPixel == 3){
        mode = GL_BGR ;
    }
    else if (surface -> format -> BytesPerPixel == 4){
        mode = GL_BGRA ;
    }
#else
    if (surface -> format -> BytesPerPixel == 3){
        mode = GL_RGB ;
    }
    else if (surface -> format -> BytesPerPixel == 4){
        mode = GL_RGBA ;
    }
#endif
