(in-package :xclhb-samples/extensions)


;; font file location
;; /usr/share/fonts/truetype/
;; ~/.local/share/fonts/

(defun pad-image (image)
  (destructuring-bind (h w ch) (array-dimensions image)
    (if (= ch 4)
        image
        (let ((ret-image (make-array (list h w 4) :element-type 'x:card8)))
          (dotimes (y h)
            (dotimes (x w)
              (setf (aref ret-image y x 0) (aref image y x 0)
                    (aref ret-image y x 1) (aref image y x 1)
                    (aref ret-image y x 2) (aref image y x 2))))
          ret-image))))

(defun make-alpha-mask (image &key (src-alpha 3))
  (destructuring-bind (h w ch) (array-dimensions image)
    (declare (ignore ch))
    (let ((ret-image (make-array (list h w) :element-type 'x:card8)))
      (dotimes (y h)
        (dotimes (x w)
          (setf (aref ret-image y x) (aref image y x src-alpha))))
      ret-image)))

(defun find-picture-format (client type depth
                            red-shift red-mask
                            green-shift green-mask
                            blue-shift blue-mask
                            alpha-shift alpha-mask)
  (some (lambda (f)
          (and (eql (xclhb-render:pictforminfo-type f) type)
               (eql (xclhb-render:pictforminfo-depth f) depth)
               (let ((df (xclhb-render:pictforminfo-direct f)))
                 (and (eql (xclhb-render:directformat-red-shift df) red-shift)
                      (eql (xclhb-render:directformat-red-mask df) red-mask)
                      (eql (xclhb-render:directformat-green-shift df) green-shift)
                      (eql (xclhb-render:directformat-green-mask df) green-mask)
                      (eql (xclhb-render:directformat-blue-shift df) blue-shift)
                      (eql (xclhb-render:directformat-blue-mask df) blue-mask)
                      (eql (xclhb-render:directformat-alpha-shift df) alpha-shift)
                      (eql (xclhb-render:directformat-alpha-mask df) alpha-mask)
                      (xclhb-render:pictforminfo-id f)))))
        (render:query-pict-formats-reply-formats (xclhb-render:query-pict-formats-sync client))))

(defun find-picture-format-argb32 (client)
  (find-picture-format client render:+pict-type--direct+ 32 16 255 8 255 0 255 24 255))

(defun find-picture-format-rgb24 (client)
  (find-picture-format client render:+pict-type--direct+ 24 16 255 8 255 0 255 0 0))

(defun find-picture-format-bgr24 (client)
  (find-picture-format client render:+pict-type--direct+ 24 0 255 8 255 16 255 0 0))

(defun find-picture-format-alpha (client)
  (find-picture-format client render:+pict-type--direct+ 8 0 0 0 0 0 0 0 255))

(defun image-width (image)
  (array-dimension image 1))

(defun image-height (image)
  (array-dimension image 0))

(defstruct render-image width height pixmap alpha-pixmap picture alpha-picture)

(defun create-render-image (client gc alpha-gc image)
  (let* ((has-alpha-p (= (array-dimension image 2) 4))
         (screen (elt (x:setup-roots (x:client-server-information client)) 0))
         (root (x:screen-root screen))
         (root-depth (x:screen-root-depth screen))
         (w (image-width image))
         (h (image-height image))
         (pixmap (x:allocate-resource-id client))
         (picture (x:allocate-resource-id client))
         (alpha-pixmap)
         (alpha-picture)
         (alpha-image))
    (unless has-alpha-p
      (setf image (pad-image image)))
    (x:create-pixmap client root-depth pixmap root w h)
    (x:put-image client x:+image-format--zpixmap+ pixmap gc w h 0 0 0 root-depth
                 (make-array (array-total-size image) :element-type 'x:card8 :displaced-to image))
    (render:create-picture client picture pixmap (find-picture-format-bgr24 client) 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
    (when has-alpha-p
      (setf alpha-pixmap (x:allocate-resource-id client)
            alpha-picture (x:allocate-resource-id client)
            alpha-image (make-alpha-mask image))
      (x:create-pixmap client 8 alpha-pixmap root w h)
      (x:put-image client x:+image-format--zpixmap+ alpha-pixmap alpha-gc w h 0 0 0 8
                   (make-array (array-total-size alpha-image) :element-type 'x:card8 :displaced-to alpha-image))
      (render:create-picture client alpha-picture alpha-pixmap (find-picture-format-alpha client) 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
    (let ((render-image (make-render-image :width w
                                           :height h
                                           :pixmap pixmap
                                           :alpha-pixmap alpha-pixmap
                                           :picture picture
                                           :alpha-picture alpha-picture)))
      (tg:finalize render-image
                   (lambda ()
                     (when (x:client-open-p client)
                       (x:free-pixmap client pixmap)
                       (render:free-picture client picture)
                       (when has-alpha-p
                         (x:free-pixmap client alpha-pixmap)
                         (render:free-picture client alpha-picture)))))
      render-image)))

(defun free-render-image (client image)
  (x:free-pixmap client (render-image-pixmap image))
  (x:free-pixmap client (render-image-alpha-pixmap image))
  (when (render-image-picture image) (render:free-picture client (render-image-picture image)))
  (when (render-image-alpha-picture image) (render:free-picture client (render-image-alpha-picture image))))

(defun composite (client dst-picture render-image x y)
  (render:composite client
                    render:+pict-op--over+
                    (render-image-picture render-image)
                    (or (render-image-alpha-picture render-image) 0)
                    dst-picture
                    0 0 0 0 x y
                    (render-image-width render-image)
                    (render-image-height render-image)))


(defun render-sample-composite (background-path foreground-path &optional host)
  "png is recommonded"
  (x:with-connected-client (client host)
    (xclhb-bigreq:init client)
    (xclhb-bigreq:enable-sync client)
    (xclhb-render:init client)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           (root (x:screen-root screen))
           (root-depth (x:screen-root-depth screen))
           (gc (x:allocate-resource-id client))
           (alpha-gc (x:allocate-resource-id client))
           (alpha-pixmap (x:allocate-resource-id client))
           (picture (x:allocate-resource-id client)))
      (x:create-window client root-depth window root 0 0 800 600 0 0 0
                       (x:make-mask x:+cw--back-pixel+
                                    x:+cw--event-mask+)
                       0 #xffffff 0 0 0 0 0 0 0 0 0
                       (x:make-mask x:+event-mask--exposure+)
                       0 0 0)
      (x:create-gc client gc window
                   (x:make-mask x:+gc--foreground+)
                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                   0 0 0 0 0 0)
      (x:create-pixmap client 8 alpha-pixmap root 1 1)
      (x:create-gc client alpha-gc alpha-pixmap 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (render:create-picture client picture window (find-picture-format-rgb24 client) 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (let* ((bg (create-render-image client gc alpha-gc (opticl:read-image-file background-path)))
             (fg (create-render-image client gc alpha-gc (opticl:read-image-file foreground-path))))
        (x:map-window client window)
        (x:set-default-error-handler client (lambda (e) (error e)))
        (xs::main-loop client window
                   (lambda ()
                     (composite client picture bg 0 0)
                     (composite client picture fg 0 0)
                     (x:flush client))
                   0.1)))))

(defstruct render-glyph width height pixmap picture)

(defun make-glyph (client gc font-loader ch size alpha-picture-foramt)
  (multiple-value-bind (mask width) (ttf-alpha-mask:make-alpha-mask font-loader ch size :aligned-line-p t)
    (let* ((pixmap (x:allocate-resource-id client))
           (picture (x:allocate-resource-id client))
           (height (image-height mask)))
      (x:create-pixmap client 8 pixmap (x:screen-root (elt (x:setup-roots (x:client-server-information client)) 0))
                       width height)
      (x:put-image client x:+image-format--zpixmap+ pixmap gc width height
                   0 0 0 8 (make-array (array-total-size mask) :element-type 'x:card8 :displaced-to mask))
      (render:create-picture client picture pixmap alpha-picture-foramt 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (let ((glyph (make-render-glyph :width width
                                      :height height
                                      :pixmap pixmap
                                      :picture picture)))
        (tg:finalize glyph
                     (lambda ()
                       (when (x:client-open-p client)
                         (x:free-pixmap client pixmap)
                         (render:free-picture client picture))))
        glyph))))

(defun get-glyph (client gc font-loader cache-manager ch size alpha-picture-foramt)
  (let ((glyph (size-limited-cache:get-cache cache-manager (list font-loader ch size))))
    (cond (glyph glyph)
          (t (setf glyph (make-glyph client gc font-loader ch size alpha-picture-foramt))
             (size-limited-cache:add-cache cache-manager
                                           (list font-loader ch size)
                                           glyph
                                           (* (render-glyph-width glyph) (render-glyph-height glyph)))
             glyph))))

(defun render-glyph (client dst-picture glyph x y color-picture)
  (render:composite client render:+pict-op--over+ color-picture (render-glyph-picture glyph) dst-picture 0 0 0 0
                    x y (render-glyph-width glyph) (render-glyph-height glyph)))

(defun random-char ()
  (let ((c (code-char (random #x100))))
    (if (or (char<= #\A c #\Z) (char<= #\a c #\z) (char<= #\0 c #\9))
        c
        (random-char))))

(defun render-sample-string (font-path &optional host)
  "only ttf is supported"
  (zpb-ttf:with-font-loader (font-loader font-path)
    (x:with-connected-client (client host)
      (xclhb-bigreq:init client)
      (xclhb-bigreq:enable-sync client)
      (xclhb-render:init client)
      (let* ((window (x:allocate-resource-id client))
             (pixmap (x:allocate-resource-id client))
             (screen (elt (x:setup-roots (x:client-server-information client)) 0))
             (root (x:screen-root screen))
             (root-depth (x:screen-root-depth screen))
             (gc (x:allocate-resource-id client))
             (picture (x:allocate-resource-id client))
             (alpha-gc (x:allocate-resource-id client))
             (alpha-pixmap-dummy (x:allocate-resource-id client))
             (color-pixmap (x:allocate-resource-id client))
             (color-picture (x:allocate-resource-id client))
             (cache-manager (size-limited-cache:create-cache-manager :max-size (* 1024 1024)))
             (font-size 0)
             (alpha-picture-foramt (find-picture-format-alpha client)))
        (x:create-window client root-depth window root 0 0 800 600 0 0 0
                         (x:make-mask x:+cw--back-pixel+
                                      x:+cw--event-mask+)
                         0 #xffffff 0 0 0 0 0 0 0 0 0
                         (x:make-mask x:+event-mask--exposure+)
                         0 0 0)
        (x:create-pixmap client root-depth pixmap root 800 600)
        (x:create-gc client gc root
                     (x:make-mask x:+gc--foreground+)
                     0 0 #xffffff 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0)
        (render:create-picture client picture pixmap (find-picture-format-rgb24 client) 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
        ;; glyph
        (x:create-pixmap client 8 alpha-pixmap-dummy root 1 1)
        (x:create-gc client alpha-gc alpha-pixmap-dummy 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
        ;; color pixmap
        (x:create-pixmap client root-depth color-pixmap root 1 1)
        (render:create-picture client color-picture color-pixmap (find-picture-format-rgb24 client)
                               (x:make-mask render:+cp--repeat+) render:+repeat--normal+ 0 0 0 0 0 0 0 0 0 0 0 0)
        (x:map-window client window)
        (x:set-default-error-handler client (lambda (e) (error e)))
        (xs::main-loop client window
                   (lambda ()
                     (setf font-size (+ 8 (random 25)))
                     (let* ((base-glyph (get-glyph client alpha-gc font-loader cache-manager #\M font-size alpha-picture-foramt))
                            (gw (render-glyph-width base-glyph))
                            (gh (render-glyph-height base-glyph)))
                       (x:change-gc client gc (x:make-mask x:+gc--foreground+) 0 0 #xffffff 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
                       (x:poly-fill-rectangle client pixmap gc (vector (x:make-rectangle :x 0 :y 0 :width 800 :height 600)))
                       (loop for y from 0 below 600 by gh
                             do (loop for x from 0 below 800 by gw
                                      do (x:change-gc client gc (x:make-mask x:+gc--foreground+) 0 0 (random #x1000000)
                                                      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
                                         (x:poly-point client 0 color-pixmap gc (vector (x:make-point :x 0 :y 0)))
                                         (render-glyph client picture
                                                       (get-glyph client alpha-gc font-loader cache-manager (random-char) font-size
                                                                  alpha-picture-foramt)
                                                       x y color-picture)
                                         (x:flush client)))
                       (x:copy-area client pixmap window gc 0 0 0 0 800 600)
                       (x:flush client)))
                   0.1)))))

(export '(render-sample-composite render-sample-string))
