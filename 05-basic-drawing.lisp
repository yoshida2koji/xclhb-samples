(in-package :xclhb-samples)

(defun basic-drawing (&optional host)
  (x:with-connected-client (client host)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (gc (x:allocate-resource-id client)))
      (x:create-window client 0 window (x:screen-root screen) 0 0 800 600 0 0 0
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--event-mask+)
                       0 #x0000ff 0 0 0 0 0 0 0 0 0
                       (x:make-mask x:+event-mask--exposure+)
                       0 0 0)
      (x:create-gc client gc window
                   (x:make-mask x:+gc--foreground+
                                x:+gc--background+
                                x:+gc--line-width+)
                   0 0 #xff0000 #x00ff00 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 )
      (x:map-window client window)
      (x:set-event-handler client x:+expose-event+
                           (lambda (e)
                             (declare (ignore e))
                             (x:poly-point client 0 window gc
                                           (vector (x:make-point :x 10 :y 10)
                                                   (x:make-point :x 20 :y 10)
                                                   (x:make-point :x 30 :y 10)))
                             (x:poly-line client 0 window gc
                                          (vector (x:make-point :x 50 :y 20)
                                                  (x:make-point :x 200 :y 15)
                                                  (x:make-point :x 500 :y 50)))
                             (x:poly-segment client window gc
                                             (vector (x:make-segment :x1 50 :y1 70 :x2 100 :y2 100)
                                                     (x:make-segment :x1 150 :y1 120 :x2 200 :y2 60)
                                                     (x:make-segment :x1 250 :y1 70 :x2 400 :y2 100)))
                             (x:poly-rectangle client window gc
                                               (vector (x:make-rectangle :x 50 :y 150 :width 100 :height 50)
                                                       (x:make-rectangle :x 250 :y 140 :width 100 :height 50)
                                                       (x:make-rectangle :x 500 :y 160 :width 100 :height 50)))
                             (x:poly-arc client window gc
                                         (vector (x:make-arc :x 50 :y 250 :width 50 :height 50
                                                             :angle1 0 :angle2 (* 64 360))
                                                 (x:make-arc :x 150 :y 250 :width 50 :height 100
                                                             :angle1 (* 64 45) :angle2 (* 64 180))
                                                 (x:make-arc :x 250 :y 250 :width 100 :height 50
                                                             :angle1 (* 64 -45) :angle2 (* 64 235))))
                             (flet ((fill-star (x y shape)
                                      (x:fill-poly client window gc shape 0
                                                   (vector (x:make-point :x x :y y)
                                                           (x:make-point :x (- x 30) :y (+ y 80))
                                                           (x:make-point :x (+ x 40) :y (+ y 30))
                                                           (x:make-point :x (- x 40) :y (+ y 30))
                                                           (x:make-point :x (+ x 30) :y (+ y 80))))))
                               (fill-star 50 300 x:+poly-shape--complex+)
                               (fill-star 200 300 x:+poly-shape--nonconvex+)
                               (fill-star 550 300 x:+poly-shape--convex+))
                             (x:poly-fill-rectangle client window gc
                                                    (vector (x:make-rectangle :x 50 :y 450 :width 100 :height 50)
                                                            (x:make-rectangle :x 250 :y 440 :width 100 :height 50)
                                                            (x:make-rectangle :x 500 :y 460 :width 100 :height 50)))
                             (x:poly-fill-arc client window gc
                                              (vector (x:make-arc :x 50 :y 520 :width 50 :height 50
                                                                  :angle1 0 :angle2 (* 64 360))
                                                      (x:make-arc :x 150 :y 520 :width 50 :height 100
                                                                  :angle1 (* 64 45) :angle2 (* 64 180))
                                                      (x:make-arc :x 250 :y 520 :width 100 :height 50
                                                                  :angle1 (* 64 -45) :angle2 (* 64 235))))
                             (x:flush client)))
      (main-loop client window
                 (lambda ())))))

(export 'basic-drawing)
