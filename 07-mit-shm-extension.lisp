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

(defun resize (client shmseg segment w h)
  (shm:detach client shmseg)
  (shm:free-shm-segment segment)
  (let ((segment (shm:make-shm-segment (* 4 w h))))
    (shm:attach client shmseg (shm:shm-segment-id segment) 0)
    (x:flush client)
    segment))

(defun draw-shm (segment w h)
  (fill-rect segment w h
             (floor w 10) (floor h 10)
             (floor w 1.2) (floor h 1.2)
             #xff0000))

(defun current-seconds ()
  (/ (get-internal-real-time) internal-time-units-per-second))

(defun mit-shm-extension ()
  (x:with-connected-client (client)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (gc (x:allocate-resource-id client))
           (shmseg (x:allocate-resource-id client))
           (width 800)
           (height 600)
           (changed-width width)
           (changed-height height)
           (segment (shm:make-shm-segment (* 4 width height)))
           (window-resized-time 0)
           (resized-time 0)
           (put-image-complete-p nil)
           (updated-p nil))
      (x:create-window client 0 window (x:screen-root screen) 0 0 width height  0 0 0
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--event-mask+)
                       0 #xffffff 0 0 0 0 0 0 0 0 0
                       (x:make-mask x:+event-mask--exposure+
                                    x:+event-mask--structure-notify+)
                       0 0 0)
      (x:create-gc client gc window 0 0 0 0 0 0 0 0
                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (x:map-window client window)
      (shm:init client)
      (shm:attach client shmseg (shm:shm-segment-id segment) 0)
      (draw-shm segment width height)
      (flet ((put-image ()
               (setf put-image-complete-p nil)
               (shm:put-image client window gc width height 0 0 width height
                              0 0 24 x:+image-format--zpixmap+ 1 shmseg 0)
               (x:flush client)))
        (x:set-event-handler client x:+configure-notify-event+
                             (lambda (e)
                               (setf changed-width (x:configure-notify-event-width e)
                                     changed-height (x:configure-notify-event-height e)
                                     window-resized-time (current-seconds)))) 
        (x:set-event-handler client x:+expose-event+
                             (lambda (e)
                               (declare (ignore e))
                               (setf updated-p t)))
        (x:set-event-handler client (+ (x:extension-event-base client shm::+extension-name+) shm:+completion-event+)
                             (lambda (e)
                               (declare (ignore e))
                               (setf put-image-complete-p t)))
        (x:set-default-error-handler client
                                     (lambda (e)
                                       (error "~a" e)))
        (main-loop client window
                   (lambda () 
                     (when (and put-image-complete-p (or (/= changed-width width) (/= changed-height height)))
                       (let ((current-time (current-seconds)))
                         ;; configure-notify-event occur at short intervals, so process with 0.1 second intervals
                         (when (or (> (- current-time resized-time) 0.1) (> (- window-resized-time resized-time) 0.1))
                           (setf width changed-width
                                 height changed-height
                                 resized-time window-resized-time
                                 segment (resize client shmseg segment width height)
                                 updated-p t)
                           (draw-shm segment width height))))
                     (when updated-p
                       (put-image)
                       (setf updated-p nil))))))))

(export 'mit-shm-extension)

