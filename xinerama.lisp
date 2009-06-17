;;; -*- Mode: Lisp -*-
;;;
;;; Copyright (C) 2008, Julian Stecklina
;;;
;;;   ((
;;;    ))     This file is COFFEEWARE. As long as you retain this notice
;;;  |   |o)  you can do whatever you want with this code. If you think,
;;;  |___|jgs it's worth it, you may buy the author a coffee in return.
;;;
;;; Description:
;;;
;;; This is an implementation of the XINERAMA extension. It does not
;;; include the obsolete PanoramiX calls.

(defpackage :xlib.xinerama
  (:use :common-lisp :xlib)
  (:nicknames :xinerama)
  (:import-from :xlib
		#:with-buffer-request
		#:with-buffer-request-and-reply
		#:data
		#:boolean
		#:boolean-get
		#:card8
		#:card8-get
		#:card16
		#:card16-get
		#:card32
		#:card32-get
		#:int16
		#:int16-get)
  (:export #:screen-info
           #:screen-info-number
           #:screen-info-x
           #:screen-info-y
           #:screen-info-width
           #:screen-info-height
           #:xinerama-query-version
           #:xinerama-is-active
           #:xinerama-query-screens))

(in-package :xinerama)

(define-extension "XINERAMA")

(defun xinerama-opcode (display)
  (extension-opcode display "XINERAMA"))

(defconstant +major-version+ 1)
(defconstant +minor-version+ 1)

(defconstant +get-version+ 0)
(defconstant +get-state+ 1)
(defconstant +get-screen-count+ 2)
(defconstant +get-screen-size+ 3)
(defconstant +is-active+ 4)
(defconstant +query-screens+ 5)

(defstruct screen-info
  (number 0 :type (unsigned-byte 32))
  (x 0 :type (signed-byte 16))
  (y 0 :type (signed-byte 16))
  (width 0 :type (unsigned-byte 16))
  (height 0 :type (unsigned-byte 16)))

(defun xinerama-query-version (display)
  (with-buffer-request-and-reply (display (xinerama-opcode display) nil)
    ((data +get-version+)
     (card8 +major-version+)
     (card8 +minor-version+))
    (values
     (card16-get 8)                     ; server major version
     (card16-get 10))))                 ; server minor version

(defun xinerama-is-active (display)
  "Returns T, iff Xinerama is supported and active."
  (with-buffer-request-and-reply (display (xinerama-opcode display) nil)
    ((data +is-active+))
    (values
     ;; XCB says this is actually a CARD32, but why?!
     (boolean-get 8))))

(defun xinerama-query-screens (display)
  "Returns a list of screen-info structures."
  (with-buffer-request-and-reply (display (xinerama-opcode display) nil)
    ((data +query-screens+))
    (values
     (loop
        with index = 32
        for number from 0 below (card32-get 8)
        collect (prog1
                    (make-screen-info :number number
                                      :x (int16-get index)
                                      :y (int16-get (+ index 2))
                                      :width (card16-get (+ index 4))
                                      :height (card16-get (+ index 6)))
                  (incf index 8))))))

;;; EOF
