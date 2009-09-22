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

(clines "#include <SDL/SDL.h>")
(clines "#include <SDL/SDL_image.h>")
(clines "#include <SDL/SDL_ttf.h>")
(clines "#include <SDL/SDL_mixer.h>")
(clines "#include <SDL/SDL_rotozoom.h>")

(defmacro defcconst (type name)
  `(let ((header (concatenate 'string "(defcfun \"

;;; SDL constants as functions
(defcfun "int gacela_SDL_INIT_TIMER (void)" 0 "return SDL_INIT_TIMER;")
(defcfun "int gacela_SDL_INIT_AUDIO (void)" 0 "return SDL_INIT_AUDIO;")
(defcfun "int gacela_SDL_INIT_VIDEO (void)" 0 "return SDL_INIT_VIDEO;")
(defcfun "int gacela_SDL_INIT_CDROM (void)" 0 "return SDL_INIT_CDROM;")
(defcfun "int gacela_SDL_INIT_JOYSTICK (void)" 0 "return SDL_INIT_JOYSTICK;")
(defcfun "int gacela_SDL_INIT_NOPARACHUTE (void)" 0 "return SDL_INIT_NOPARACHUTE;")
(defcfun "int gacela_SDL_INIT_EVENTTHREAD (void)" 0 "return SDL_INIT_EVENTTHREAD;")
(defcfun "int gacela_SDL_INIT_EVERYTHING (void)" 0 "return SDL_INIT_EVERYTHING;")

(defcfun "int gacela_SDL_SWSURFACE (void)" 0 "return SDL_SWSURFACE;")
(defcfun "int gacela_SDL_HWSURFACE (void)" 0 "return SDL_HWSURFACE;")
(defcfun "int gacela_SDL_ASYNCBLIT (void)" 0 "return SDL_ASYNCBLIT;")

(defcfun "int gacela_SDL_ANYFORMAT (void)" 0 "return SDL_ANYFORMAT;")
(defcfun "int gacela_SDL_HWPALETTE (void)" 0 "return SDL_HWPALETTE;")
(defcfun "int gacela_SDL_DOUBLEBUF (void)" 0 "return SDL_DOUBLEBUF;")
(defcfun "int gacela_SDL_FULLSCREEN (void)" 0 "return SDL_FULLSCREEN;")
(defcfun "int gacela_SDL_OPENGL (void)" 0 "return SDL_OPENGL;")
(defcfun "int gacela_SDL_OPENGLBLIT (void)" 0 "return SDL_OPENGLBLIT;")
(defcfun "int gacela_SDL_RESIZABLE (void)" 0 "return SDL_RESIZABLE;")
(defcfun "int gacela_SDL_NOFRAME (void)" 0 "return SDL_NOFRAME;")

(defcfun "int gacela_SDL_HWACCEL (void)" 0 "return SDL_HWACCEL;")
(defcfun "int gacela_SDL_SRCCOLORKEY (void)" 0 "return SDL_SRCCOLORKEY;")

(defcfun "int gacela_SDL_GL_DOUBLEBUFFER (void)" 0 "return SDL_GL_DOUBLEBUFFER;")

(defcfun "int gacela_SDL_DEFAULT_REPEAT_DELAY (void)" 0 "return DEFAULT_REPEAT_DELAY;")
(defcfun "int gacela_SDL_DEFAULT_REPEAT_INTERVAL (void)" 0 "return DEFAULT_REPEAT_INTERVAL;")

(defcfun "int gacela_SDL_LIL_ENDIAN (void)" 0 "return SDL_LIL_ENDIAN;")
(defcfun "int gacela_SDL_BIG_ENDIAN (void)" 0 "return SDL_BIG_ENDIAN;")


;;; SDL Functions
(defcfun "int gacela_SDL_Init (int flags)" 0
  "return SDL_Init (flags);")

(defcfun "void gacela_SDL_Quit (void)" 0
  "SDL_Quit ();")

(defcfun "int gacela_SDL_SetVideoMode (int width, int height, int bpp, int flags)" 0
  "return SDL_SetVideoMode (width, height, bpp, flags);")

(defcfun "void gacela_SDL_WM_SetCaption (char *title, char *icon)" 0
  "SDL_WM_SetCaption (title, icon);")

(defcfun "int gacela_SDL_Flip (int screen)" 0
  "return SDL_Flip (screen);")

(defcfun "void gacela_SDL_FreeSurface (int surface)" 0
  "SDL_FreeSurface (surface);")

(defcfun "void gacela_SDL_Delay (int ms)" 0
  "SDL_Delay (ms);")

(defcfun "int gacela_SDL_GetTicks (void)" 0
  "return SDL_GetTicks ();")

(defcfun "int gacela_SDL_DisplayFormat (int surface)" 0
  "return SDL_DisplayFormat (surface);")

(defcfun "int gacela_SDL_MapRGB (int format, int r, int g, int b)" 0
  "return SDL_MapRGB (format, r, g, b);")

(defcfun "int gacela_SDL_SetColorKey (int surface, int flag, int key)" 0
  "return SDL_SetColorKey (surface, flag, key);")

(defcfun "int gacela_SDL_LoadBMP (char *file)" 0
  "return SDL_LoadBMP (file);")

(defcfun "int gacela_IMG_Load (char *filename)" 0
  "return IMG_Load (filename);")

(defcfun "static object gacela_SDL_GetVideoInfo (void)" 0
  "const SDL_VideoInfo *info;"
  "object vi, label;"
  "info = SDL_GetVideoInfo ();"
  ('nil vi)
  ((cons (int info->blit_hw) vi) vi) (':blit_hw label) ((cons label vi) vi)
  ((cons (int info->hw_available) vi) vi) (':hw_available label) ((cons label vi) vi)
  "return vi;")

(defcfun "int gacela_SDL_GL_SetAttribute (int attr, int value)" 0
  "return SDL_GL_SetAttribute (attr, value);")

(defcfun "static object gacela_SDL_PollEvent (void)" 0
  "SDL_Event sdl_event;"
  "object event, label;"
  ('nil event)
  "if (SDL_PollEvent (&sdl_event)) {"
  "  switch (sdl_event.type) {"
  "    case SDL_KEYDOWN:"
  "    case SDL_KEYUP:"
  ((cons (int sdl_event.key.keysym.sym) event) event) (':key.keysym.sym label) ((cons label event) event)
  "      break;"
  "  }"
  ((cons (int sdl_event.type) event) event) (':type label) ((cons label event) event)
  "}"
  "return event;")

(defcfun "void gacela_SDL_GL_SwapBuffers (void)" 0
  "SDL_GL_SwapBuffers ();")

(defcfun "int gacela_SDL_EnableKeyRepeat (int delay, int interval)" 0
  "return SDL_EnableKeyRepeat (delay, interval);")

(defcfun "int gacela_zoomSurface (int src, float zoomx, float zoomy, int smooth)" 0
  "return zoomSurface (src, zoomx, zoomy, smooth);")

(defcfun "int gacela_SDL_ByteOrder (void)" 0
  "return SDL_BYTEORDER;")

(defentry SDL_Init (int) (int "gacela_SDL_Init"))
(defentry SDL_Quit () (void "gacela_SDL_Quit"))
(defentry SDL_SetVideoMode (int int int int) (int "gacela_SDL_SetVideoMode"))
(defentry SDL_WM_SetCaption (string string) (void "gacela_SDL_WM_SetCaption"))
(defentry SDL_Flip (int) (int "gacela_SDL_Flip"))
(defentry SDL_FreeSurface (int) (void "gacela_SDL_FreeSurface"))
(defentry SDL_Delay (int) (void "gacela_SDL_Delay"))
(defentry SDL_GetTicks () (int "gacela_SDL_GetTicks"))
(defentry SDL_DisplayFormat (int) (int "gacela_SDL_DisplayFormat"))
;(defentry SDL_SurfaceFormat (int) (int "gacela_SDL_SurfaceFormat"))
(defentry SDL_MapRGB (int int int int) (int "gacela_SDL_MapRGB"))
(defentry SDL_SetColorKey (int int int) (int "gacela_SDL_SetColorKey"))
;(defentry SDL_BlitSurface (int int int int) (void "gacela_SDL_BlitSurface"))
;(defentry SDL_Rect (int int int int) (int "gacela_SDL_Rect"))
(defentry SDL_LoadBMP (string) (int "gacela_SDL_LoadBMP"))
(defentry IMG_Load (string) (int "gacela_IMG_Load"))
(defentry SDL_GetVideoInfo () (object "gacela_SDL_GetVideoInfo"))
(defentry SDL_GL_SetAttribute (int int) (int "gacela_SDL_GL_SetAttribute"))
(defentry SDL_PollEvent () (object "gacela_SDL_PollEvent"))
;(defentry TTF_Init () (int "gacela_TTF_Init"))
;(defentry TTF_OpenFont (string int) (int "gacela_TTF_OpenFont"))
;(defentry TTF_CloseFont (int) (void "gacela_TTF_CloseFont"))
;(defentry TTF_Quit () (void "gacela_TTF_Quit"))
;(defentry Mix_OpenAudio (int int int) (int "gacela_Mix_OpenAudio"))
;(defentry Mix_LoadMUS (string) (int "gacela_Mix_LoadMUS"))
;(defentry Mix_LoadWAV (string) (int "gacela_Mix_LoadWAV"))
;(defentry Mix_PlayChannel (int int int) (int "gacela_Mix_PlayChannel"))
;(defentry Mix_PlayMusic (int int) (int "gacela_Mix_PlayMusic"))
;(defentry Mix_PlayingMusic () (int "gacela_Mix_PlayingMusic"))
;(defentry Mix_PausedMusic () (int "gacela_Mix_PausedMusic"))
;(defentry Mix_PauseMusic () (void "gacela_Mix_PauseMusic"))
;(defentry Mix_ResumeMusic () (void "gacela_Mix_ResumeMusic"))
;(defentry Mix_HaltMusic () (int "gacela_Mix_HaltMusic"))
;(defentry Mix_FreeMusic (int) (void "gacela_Mix_FreeMusic"))
;(defentry Mix_FreeChunk (int) (void "gacela_Mix_FreeChunk"))
;(defentry Mix_CloseAudio () (void "gacela_Mix_CloseAudio"))
;(defentry free (int) (void "gacela_free"))
(defentry SDL_GL_SwapBuffers () (void "gacela_SDL_GL_SwapBuffers"))
(defentry SDL_EnableKeyRepeat (int int) (int "gacela_SDL_EnableKeyRepeat"))
(defentry zoomSurface (int float float int) (int "gacela_zoomSurface"))
(defentry SDL_ByteOrder () (int "gacela_SDL_ByteOrder"))

;;; C-Gacela Functions
(defcfun "int gacela_surface_format (int surface)" 0
  "const SDL_Surface *s = surface;"
  "return s->format;")

(defcfun "int gacela_surface_w (int surface)" 0
  "const SDL_Surface *s = surface;"
  "return s->w;")

(defcfun "int gacela_surface_h (int surface)" 0
  "const SDL_Surface *s = surface;"
  "return s->h;")

(defcfun "int gacela_surface_pixels (int surface)" 0
  "const SDL_Surface *s = surface;"
  "return s->pixels;")

(defcfun "int gacela_surface_format_BytesPerPixel (int surface)" 0
  "const SDL_Surface *s = surface;"
  "return s->format->BytesPerPixel;")

;(defentry apply-surface2 (int int int int int int int int int) (void "apply_surface"))
;(defentry render-text2 (int string int int int) (int "render_text"))
;(defentry fill-surface (int int int int) (void "fill_surface"))
;(defentry box-collision (int int int int int int) (int "box_collision"))
;(defentry create-SDL_Surface (int int int int int int) (int "create_SDL_Surface"))
;(defentry copy-SDL_Surface (int) (int "copy_SDL_Surface"))
(defentry surface-format (int) (int "gacela_surface_format"))
(defentry surface-w (int) (int "gacela_surface_w"))
(defentry surface-h (int) (int "gacela_surface_h"))
(defentry surface-pixels (int) (int "gacela_surface_pixels"))
(defentry surface-format-BytesPerPixel (int) (int "gacela_surface_format_BytesPerPixel"))
