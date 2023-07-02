(defsystem "xclhb-samples"
  :version "0.1"
  :author "yoshida koji"
  :license "MIT"
  :depends-on ("cffi"
               "opticl"
               "cl-vectors"
               "cl-paths-ttf"
               "cl-aa-misc"
               (:version "xclhb" "0.2")
               "xclhb-bigreq"
               "xclhb-shm"
               "xclhb-render"
               "size-limited-cache"
               "ttf-alpha-mask")
  :serial t
  :components ((:file "package")
               (:file "01-show-window")
               (:file "02-exit-when-window-close")
               (:file "03-process-event")
               (:file "04-transparent")
               (:file "05-basic-drawing")
               (:file "06-simple-paint")))

(defsystem "xclhb-samples/extensions"
  :version "0.1"
  :author "yoshida koji"
  :license "MIT"
  :depends-on ("xclhb-samples"
               "opticl"
               "cl-vectors"
               "cl-paths-ttf"
               "cl-aa-misc"
               "xclhb-bigreq"
               "xclhb-shm"
               "xclhb-render"
               "size-limited-cache"
               "ttf-alpha-mask")
  :serial t
  :components ((:file "extensions-package")
               (:file "07-mit-shm-extension")
               (:file "08-bigreq")
               (:file "09-render-extension")))
