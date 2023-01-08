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
