(in-package :xclhb-samples)

(defun event (&optional host)
  (x:with-connected-client (client host)
    (x:set-keycode-keysym-table client)
    (let* ((w-top (x:allocate-resource-id client))
           (w-l1 (x:allocate-resource-id client))
           (w-l2 (x:allocate-resource-id client))
           (w-r1 (x:allocate-resource-id client))
           (w-r2 (x:allocate-resource-id client))
           (gc (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (w-top-x 0) (w-top-y 0) (w-top-w 800) (w-top-h 600) (w-top-bg #xffffff)
           (w-l1-x 100) (w-l1-y 300) (w-l1-w 300) (w-l1-h 300) (w-l1-bg #xffaaaa)
           (w-l2-x 100) (w-l2-y 0) (w-l2-w 200) (w-l2-h 100) (w-l2-bg #xff8888)
           (w-r1-x 400) (w-r1-y 300) (w-r1-w 300) (w-r1-h 300) (w-r1-bg #xaaaaff)
           (w-r2-x 0) (w-r2-y 0) (w-r2-w 200) (w-r2-h 200) (w-r2-bg #x8888ff)
           (event-dispatch-table (make-hash-table :test #'equal)))
      (labels ((make-window (wid parent x y w h bg)
                 (x:create-window client 0 wid parent x y w h 0 0 0
                                  (x:make-mask x:+cw--back-pixel+
                                               x:+cw--event-mask+)
                                  0 bg 0 0 0 0 0 0 0 0 0
                                  (x:make-mask x:+event-mask--key-press+
                                               x:+event-mask--key-release+
                                               x:+event-mask--button-press+
                                               x:+event-mask--button-release+
                                               x:+event-mask--pointer-motion+
                                               x:+event-mask--enter-window+
                                               x:+event-mask--leave-window+)
                                  0 0 0))
               (draw-text (text y)
                 (x:clear-area client 0 w-top  0 (- y 20) w-top-w 25)
                 (x:image-text8 client (length text) w-top gc 10 y
                                (x::string->card8-vector text))
                 (x:flush client))
               (set-event-handler (window code handler)
                 (setf (gethash (cons window code) event-dispatch-table)
                       handler))
               (on-key-press (window message)
                 (set-event-handler window x:+key-press-event+
                                    (lambda (e)
                                      (x:with-key-press-event (detail state) e
                                        (draw-text (format nil "~a ~a pressed."
                                                           message
                                                           (x:keycode->keysym client detail state))
                                                   20)))))
               (on-key-release (window message)
                 (set-event-handler window x:+key-release-event+
                                    (lambda (e)
                                      (x:with-key-release-event (detail state) e
                                        (draw-text (format nil "~a ~a released."
                                                           message
                                                           (x:keycode->keysym client detail state))
                                                   50)))))
               (on-button-press (window message)
                 (set-event-handler window x:+button-press-event+
                                    (lambda (e)
                                      (x:with-button-press-event (detail event-x event-y) e
                                        (draw-text (format nil "~a ~a button pressed. x: ~a y: ~a"
                                                           message detail event-x event-y)
                                                   80)))))
               (on-button-release (window message)
                 (set-event-handler window x:+button-release-event+
                                    (lambda (e)
                                      (x:with-button-release-event (detail event-x event-y) e
                                        (draw-text (format nil "~a ~a button released. x: ~a y: ~a"
                                                           message detail event-x event-y)
                                                   110)))))
               (on-motion (window message)
                 (set-event-handler window x:+motion-notify-event+
                                    (lambda (e)
                                      (x:with-motion-notify-event (event-x event-y state) e
                                        (draw-text (format nil "~a motion. x: ~a y: ~a state: ~a"
                                                           message event-x event-y state)
                                                   140)))))
               (on-enter (window message)
                 (set-event-handler window x:+enter-notify-event+
                                    (lambda (e)
                                      (x:with-enter-notify-event (event-x event-y) e
                                        (draw-text (format nil "~a enter. x: ~a y: ~a"
                                                           message event-x event-y)
                                                   170)))))
               (on-leave (window message)
                 (set-event-handler window x:+leave-notify-event+
                                    (lambda (e)
                                      (x:with-leave-notify-event (event-x event-y) e
                                        (draw-text (format nil "~a leave. x: ~a y: ~a"
                                                           message event-x event-y)
                                                   200))))))
        (make-window w-top (x:screen-root screen) w-top-x w-top-y w-top-w w-top-h w-top-bg)
        (make-window w-l1 w-top w-l1-x w-l1-y w-l1-w w-l1-h w-l1-bg)
        (make-window w-l2 w-l1 w-l2-x w-l2-y w-l2-w w-l2-h w-l2-bg)
        (make-window w-r1 w-top w-r1-x w-r1-y w-r1-w w-r1-h w-r1-bg)
        (make-window w-r2 w-r1 w-r2-x w-r2-y w-r2-w w-r2-h w-r2-bg)
        (macrolet ((set-handler (window message)
                     `(progn
                        ,@(mapcar (lambda (h)
                                    (list h window message))
                                  `(on-key-press on-key-release
                                                 on-button-press on-button-release
                                                 on-motion on-enter on-leave))))
                   (set-handler-2 (event window-accessor)
                     `(x:set-event-handler client ,event
                                           (lambda (e)
                                             (let ((h (gethash (cons (,window-accessor e)
                                                                     ,event)
                                                               event-dispatch-table)))
                                               (when h
                                                 (funcall h e)))))))
          (set-handler w-top "top")
          (set-handler w-l1 "left1")
          (set-handler w-l2 "left2")
          (set-handler w-r1 "right1")
          (set-handler w-r2 "right2")
          (set-handler-2 x:+key-press-event+ x:key-press-event-event)
          (set-handler-2 x:+key-release-event+ x:key-release-event-event)
          (set-handler-2 x:+button-press-event+ x:button-press-event-event)
          (set-handler-2 x:+button-release-event+ x:button-release-event-event)
          (set-handler-2 x:+motion-notify-event+ x:motion-notify-event-event)
          (set-handler-2 x:+enter-notify-event+ x:enter-notify-event-event)
          (set-handler-2 x:+leave-notify-event+ x:leave-notify-event-event)
          ))
      (x:create-gc client gc w-top
                   (x:make-mask x:+gc--foreground+
                                x:+gc--background+)
                   0 0 0 #xffffff 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 )
      (x:map-window client w-top)
      (x:map-subwindows client w-top)
      (x:map-subwindows client w-l1)
      (x:map-subwindows client w-r1)
       (main-loop client w-top
                 (lambda ())))))

(export 'event)
