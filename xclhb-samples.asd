
(defsystem "xclhb-samples"
  :version "0.1"
  :author "yoshida koji"
  :license "MIT"
  :depends-on ("cffi"
               (:version "xclhb" "0.2")
               "xclhb-bigreq"
               "xclhb-shm")
  :serial t
  :components ((:file "package")
               (:file "01-show-window")
               (:file "02-exit-when-window-close")
               (:file "03-process-event")
               (:file "04-transparent")
               (:file "05-basic-drawing")
               (:file "06-simple-paint")
               (:file "07-mit-shm-extension")
               (:file "08-bigreq")))
