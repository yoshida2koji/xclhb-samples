(in-package :xclhb-samples)

(defun intern-atom-sync (client atom-name)
  (let ((name (x::string->card8-vector atom-name)))
    (x:intern-atom-reply-atom (x:wait-reply (x:intern-atom client nil 0 (length name) name)))))

(defun atom-to-data-buffer (atom)
  (let ((buf (x::make-buffer 4)))
    (setf (aref buf 0) (ldb (byte 8 24) atom))
    (setf (aref buf 1) (ldb (byte 8 16) atom))
    (setf (aref buf 2) (ldb (byte 8 8) atom))
    (setf (aref buf 3) (ldb (byte 8 0) atom))
    buf))


(defun set-on-window-close-function (client window fn)
  (let* ((atom-atom (intern-atom-sync client "ATOM"))
         (wm-protocols-atom (intern-atom-sync client "WM_PROTOCOLS"))
         (wm-delete-window-atom (intern-atom-sync client "WM_DELETE_WINDOW")))
    (x:change-property client 0 window wm-protocols-atom atom-atom 32 1
                       (atom-to-data-buffer wm-delete-window-atom))
    (x:set-event-handler client x:+client-message-event+ fn)))

(defun main-loop (client window fn &optional (delay-seconds 0.016))
  (let ((quit-p))
    (set-on-window-close-function client window
                                  (lambda (e)
                                    (declare (ignore e))
                                    (setf quit-p t)))
    (x:flush client)
    (loop
      (when quit-p
        (return))
      (x:process-input client)
      (funcall fn)
      (sleep delay-seconds))))

(defun exit-when-window-close ()
  (x:with-connected-client (client)
    (let* ((window (x:allocate-resource-id client))
           (screen (elt (x:setup-roots (x:client-server-information client)) 0))
           )
      (x:create-window client 0 window (x:screen-root screen) 0 0 800 600 0 0 0
                       (x:make-mask x:+cw--back-pixel+)
                       0 #x0000ff 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (x:map-window client window)
      (main-loop client window
                 (lambda ())))))

(export 'exit-when-window-close)
