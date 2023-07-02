(in-package :xclhb-samples/extensions)

(defun draw (client drawable gc w h)
  (let ((points (make-array (* (ceiling w 2) (ceiling h 2))))
        (i 0))
    (loop for y from 0 below h by 2
          do (loop for x from 0 below w by 2
                   do (setf (aref points i) (x:make-point :x x :y y)
                            i (1+ i))))
    (x:poly-point client 0 drawable gc points))
  (x:flush client))

(defun bigreq-sample (&optional host)
  (x:with-connected-client (client host)
    (xclhb-bigreq:init client)
    (xclhb-bigreq:enable-sync client)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (gc (x:allocate-resource-id client)))
      (x:create-window client 0 window (x:screen-root screen) 0 0 800 600 0 0 0
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--event-mask+)
                       0 #xffffff 0 0 0 0 0 0 0 0 0
                       (x:make-mask x:+event-mask--exposure+)
                       0 0 0)
      (x:create-gc client gc window
                   (x:make-mask x:+gc--foreground+)
                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 )
      (x:map-window client window)
      (x:set-event-handler client x:+expose-event+
                           (lambda (e)
                             (declare (ignore e))
                             (draw client window gc 800 600)))
      (xs::main-loop client window
                     (lambda ())))))

(export 'bigreq-sample)
