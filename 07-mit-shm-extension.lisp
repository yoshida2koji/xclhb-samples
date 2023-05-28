(in-package :xclhb-samples)

(defun clamp (n min max)
  (cond ((< n min) min)
        ((< max n) max)
        (t n)))

(defun offset (x y w)
  (* 4 (+ (* y w) x)))

(defun fill-rect (segment width height x y w h c)
  (let ((data (shm:shm-segment-data segment))
        (start-y (clamp y 0 height))
        (end-y (clamp (+ y h) 0 height))
        (start-x (clamp x 0 width))
        (end-x (clamp (+ x w) 0 width)))
    (loop :for y :from start-y :below end-y
          :do (loop :for i :from (offset  start-x y width)
                      :below (offset end-x y width) :by 4
                    :do (setf (cffi:mem-ref data :uint32 i) c)))))

(defun mit-shm-extension ()
  (x:with-connected-client (client)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (gc (x:allocate-resource-id client))
           (shmseg (x:allocate-resource-id client))
           (width 800)
           (height 600)
           (segment (shm:make-shm-segment (* 4 width height))))
      (x:create-window client 0 window (x:screen-root screen) 0 0 width height  0 0 0
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--event-mask+)
                       0 #xffffff 0 0 0 0 0 0 0 0 0
                       (x:make-mask x:+event-mask--exposure+)
                       0 0 0)
      (x:create-gc client gc window 0 0 0 0 0 0 0 0
                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (x:map-window client window)
      (shm:init client)
      (shm:attach client shmseg (shm:shm-segment-id segment) 0)
      (fill-rect segment width height 100 50 600 400 #xff0000)
      (x:set-event-handler client x:+expose-event+
                           (lambda (e)
                             (declare (ignore e))
                             (shm:put-image client window gc width height 0 0 width height
                                            0 0 24 x:+image-format--zpixmap+ 0 shmseg 0)
                             (x:flush client)))
      (x:set-default-error-handler client
                                   (lambda (e)
                                     (error "~a" e)))
      (main-loop client window
                 (lambda ())))))

(export 'mit-shm-extension)
