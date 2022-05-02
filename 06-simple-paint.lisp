(in-package :xclhb-samples)

(defun simple-paint ()
  (x:with-connected-client (client)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (gc (x:allocate-resource-id client))
           (pixmap (x:allocate-resource-id client))
           (x1 0) (y1 0))
      (x:create-window client 0 window (x:screen-root screen) 0 0 800 600 0 0 0
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--event-mask+)
                       0 #xffffff 0 0 0 0 0 0 0 0 0
                       (x:make-mask x:+event-mask--exposure+
                                    x:+event-mask--button-press+
                                    x:+event-mask--button-motion+)
                       0 0 0)
      (x:create-pixmap client 24 pixmap window 800 600)
      (x:create-gc client gc window
                   (x:make-mask x:+gc--foreground+)
                   0 0 #xffffff 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (x:poly-fill-rectangle client pixmap gc
                             (vector (x:make-rectangle :x 0 :y 0 :width 800 :height 600)))
      (x:map-window client window)
      (labels ((change-color-and-line-width (c w)
                 (x:change-gc client gc (x:make-mask x:+gc--foreground+
                                                     x:+gc--line-width+)
                              0 0 c 0 w 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
               (copy-area ()
                 (x:copy-area client pixmap window gc 0 0 0 0 800 600)
                 (x:flush client))
               (on-button-press (e)
                 (x:with-button-press-event (event-x event-y detail) e
                   (if (eql detail x:+button-index--3+)
                       (change-color-and-line-width #xffffff 10)
                       (change-color-and-line-width 0 1))
                   (setf x1 event-x
                         y1 event-y)))
               (on-motion-notify (e)
                 (x:with-motion-notify-event (event-x event-y) e
                   (x:poly-line client 0 pixmap gc
                                (vector (x:make-point :x x1 :y y1)
                                        (x:make-point :x event-x :y event-y)))
                   (copy-area)
                   (setf x1 event-x
                         y1 event-y))))
        (x:set-event-handler client x:+expose-event+
                             (lambda (e)
                               (declare (ignore e))
                               (copy-area)))
        (x:set-event-handler client x:+button-press-event+
                             #'on-button-press)
        (x:set-event-handler client x:+motion-notify-event+
                             #'on-motion-notify))
      (x:set-default-error-handler client
                                   (lambda (e)
                                     (error "~a" e)))
      (main-loop client window
                 (lambda ())))))

(export 'simple-paint)
