;;; This file contains some unittest for chun-blog.el

(eval-when-compile

  (chun-blog/get-preview (concat-to-dir chun-blog/posts-directory "hello.org"))

  )
