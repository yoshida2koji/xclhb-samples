(in-package :xclhb-samples)

(defun show-window ()
  (x:with-connected-client (client)
    (let ((root (x:screen-root (elt (x:setup-roots (x:client-server-information client)) 0)))
          (wid (x:allocate-resource-id client)))
      (x:create-window client ; client
                           0 ; depth 0 is same as th parent
                           wid ; wid
                           root ; parent
                           0 ; x changed by window manager
                           0 ; y changed by window manager
                           800 ; width
                           600 ; height
                           0 ; border-width
                           0 ; class 0 is same as the parent
                           0 ; visual 0 is same as the parent
                           (x:make-mask x:+cw--back-pixel+) ; value-mask
                           ;; the following arguments are used when the collesponding
                           ;; bits of the value-mask are set.
                           0 ; background-pixmap
                           #x0000ff ; background-pixel blue
                           0 ; border-pixmap
                           0 ; border-pixel
                           0 ; bit-gravity
                           0 ; win-gravity
                           0 ; backing-store
                           0 ; backing-planes
                           0 ; backing-pixel
                           0 ; override-redirect
                           0 ; save-under
                           0 ; event-mask
                           0 ; do-not-propogate-mask
                           0 ; colormap
                           0 ; cursor
                           )
      (x:map-window client wid)
      (x:flush client)
      (sleep 3))))

(export 'show-window)
