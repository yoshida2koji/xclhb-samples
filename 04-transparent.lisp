(in-package :xclhb-samples)

(defun find-visual-id (client depth)
  (let* ((screen (elt (x:setup-roots (x:client-server-information client)) 0))
         (depth-strs (x:screen-allowed-depths screen))
         (depth-str (find depth depth-strs :key #'x:depth-depth)))
    (when depth-str
      (let ((visual-type (find x:+visual-class--true-color+
                               (x:depth-visuals depth-str)
                               :key
                               #'x:visualtype-class)))
        (when visual-type
          (x:visualtype-visual-id visual-type))))))

(defun show-transparent-window (&optional host)
  (x:with-connected-client (client host)
    (let* ((window (x:allocate-resource-id client))
           (c1 (x:allocate-resource-id client))
           (c2 (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (visual-id (find-visual-id client 32))
           (colormap (x:allocate-resource-id client))
           )
      (unless visual-id
        (error "32 depth visual type not found."))
      (x:create-colormap client x:+colormap-alloc--none+ colormap
                         (x:screen-root screen) visual-id)
      (flet ((make-window (window parent x y w h bg)
               (x:create-window client 32 window parent x y w h 10
                       0 visual-id
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--border-pixel+ ; must
                                    x:+cw--colormap+ ; must
                                    )
                       0 bg 0 #x800000ff 0 0 0 0 0 0 0 0 0 colormap 0)))
        (make-window window (x:screen-root screen) 0 0 800 600 #x00ff0000)
        (make-window c1 window 100 100 400 300 #xff00ff00)
        (make-window c2 window 300 300 400 300 #x0000ff00))
      (x:map-window client window)
      (x:map-subwindows client window)
      (x:set-default-error-handler client
                                   (lambda (e)
                                     (error "~a" e)))
      (main-loop client window
                 (lambda ())))))


(export 'show-transparent-window)

