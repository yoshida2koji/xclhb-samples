# xclhb-samples
xclhb samples

## Usage
```sh
cd ~
mkdir common-lisp # if not exists
cd common-lisp
git clone https://github.com/yoshida2koji/struct-plus.git
git clone https://github.com/yoshida2koji/xclhb.git
git clone https://github.com/yoshida2koji/xclhb-samples.git
```

run your Common Lisp implementation. (quicklisp is required)
```lisp
(ql:quickload :xclhb-samples)
(xclhb-samples:show-window)
(xclhb-samples:exit-when-window-close)
(xclhb-samples:event)
(xclhb-samples:show-transparent-window)
(xclhb-samples:basic-drawing)
(xclhb-samples:simple-paint)
```

extensions sample
```sh
cd ~/common-lisp
git clone https://github.com/yoshida2koji/ttf-alpha-mask.git
git clone https://github.com/yoshida2koji/size-limited-cache.git
```


```lisp
(ql:quickload :xclhb-samples/extensions)
(xclhb-samples/extensions:bigreq-sample)
(xclhb-samples/extensions:mit-shm-extension)
(xclhb-samples/extensions:render-sample-string {truetype-font-path})
(xclhb-samples/extensions:render-sample-composite {background-file-path} {foreground-file-path})
```
