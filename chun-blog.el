;;; chun-blog.el -- a naive implementation for blogging in emacs.
;;;
;;; Author: Chunwei Yan
;;; Version: 0.1
;;;
;;; NOTE: This project originates from the org-static-blog https://github.com/bastibe/org-static-blog, reference the original project for more information. I rewrite most of the code just for elisp-learning and for further customization.

(require 'log4e)
(require 'parse-time)

(defgroup chun-blog nil "Settings for a static blog generator using org-mode"
  :version "0.0.1"
  :group 'applications)

(defcustom chun-blog/publish-url "https://example.com/"
  "URL of the blog."
  :type '(string):safe
  t)

(defcustom chun-blog/publish-title "Example.com"
  "Title of the blog."
  :type '(string):safe
  t)

(defcustom chun-blog/publish-directory "~/blog/"
  "Directory where published HTML files are stored."
  :type '(directory):safe
  t)

(defcustom chun-blog/posts-directory "~/blog/posts/"
  "Directory where published ORG files are stored."
  :type '(directory):safe
  t)

(defcustom chun-blog/drafts-directory "~/blog/drafts/"
  "Directory where unpublished ORG files are stored."
  :type '(directory):safe
  t)

(defcustom chun-blog/no-posting-tag "nonpost"
  "The tag to mark the headings that should not publish to html"
  :type '(string):safe
  t)

(defcustom chun-blog/langcode "zh"
  "Language code"
  :type '(string):safe
  t)

(defcustom chun-blog/page-header "<link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@0.9.3/css/bulma.min.css\">"
  "Extra content in <head>"
  :type '(string):safe
  t)

(defcustom chun-blog/archive-file "archive.html"
  "archive file name"
  :type '(string):safe
  t)

(defcustom chun-blog/use-preview t
  "Whether to use preview."
  :type '(boolean):safe
  t)

(defcustom chun-blog/preview-start nil
  "Marker indicating the beginning of a post's preview.
When set to nil, we look for the first occurence of <p> in the
generated HTML.  See also `chun-blog/preview-end'."
  :type '(choice (const :tag "First paragraph"
                        nil)
                 (string)):safe
  t)

(defcustom chun-blog/preview-end nil
  "Marker indicating the end of a post's preview.
When set to nil, we look for the first occurence of </p> after
`chun-blog/preview-start' (or the first <p> if that is nil)
in the generated HTML."
  :type '(choice (const :tag "First paragraph"
                        nil)
                 (string)):safe
  t)

(defcustom chun-blog/preview-link-p nil
  "Whether to make the preview ellipsis a link to the article's page."
  :type '(boolean):safe
  t)

(defcustom chun-blog/preview-date-first-p nil
  "If t, print post dates before title in the preview view."
  :type '(boolean):safe
  t)

(defcustom chun-blog/preview-ellipsis "(...)"
  "The HTML appended to the preview if some part of the post is hidden.

The contents shown in the preview is determined by the values of
the variables `chun-blog/preview-start' and
`chun-blog/preview-end'."
  :type '(string):safe
  t)

(defcustom chun-blog/index-front-matter ""
  "HTML to put at the beginning of the index page."
  :type '(string):safe
  t)

(defcustom chun-blog/index-length 5
  "Number of articles to include on index page."
  :type '(integer):safe
  t)

(defconst chun-blog/texts '((other-posts ("en" . "Other posts")
                                         ("pl" . "Pozostałe wpisy")
                                         ("ru" . "Другие публикации")
                                         ("by" . "Іншыя публікацыі")
                                         ("it" . "Altri articoli")
                                         ("es" . "Otros artículos")
                                         ("fr" . "Autres articles")
                                         ("zh" . "其他帖子")
                                         ("ja" . "他の投稿"))
                            (date-format ("en" . "%d %b %Y")
                                         ("pl" . "%Y-%m-%d")
                                         ("ru" . "%d.%m.%Y")
                                         ("by" . "%d.%m.%Y")
                                         ("it" . "%d/%m/%Y")
                                         ("es" . "%d/%m/%Y")
                                         ("fr" . "%d-%m-%Y")
                                         ("zh" . "%Y-%m-%d")
                                         ("ja" . "%Y/%m/%d"))
                            (tags ("en" . "Tags")
                                  ("pl" . "Tagi")
                                  ("ru" . "Ярлыки")
                                  ("by" . "Ярлыкі")
                                  ("it" . "Categorie")
                                  ("es" . "Categoría")
                                  ("fr" . "Tags")
                                  ("zh" . "标签")
                                  ("ja" . "タグ"))
                            (archive ("en" . "Archive")
                                     ("pl" . "Archiwum")
                                     ("ru" . "Архив")
                                     ("by" . "Архіў")
                                     ("it" . "Archivio")
                                     ("es" . "Archivo")
                                     ("fr" . "Archive")
                                     ("zh" . "归档")
                                     ("ja" . "アーカイブ"))
                            (posts-tagged ("en" . "Posts tagged")
                                          ("pl" . "Wpisy z tagiem")
                                          ("ru" . "Публикации с ярлыками")
                                          ("by" . "Публікацыі")
                                          ("it" . "Articoli nella categoria")
                                          ("es" . "Artículos de la categoría")
                                          ("fr" . "Articles tagués")
                                          ("zh" . "打标签的帖子")
                                          ("ja" . "タグ付けされた投稿"))
                            (no-prev-post ("en" . "There is no previous post")
                                          ("pl" . "Poprzedni wpis nie istnieje")
                                          ("ru" . "Нет предыдущей публикации")
                                          ("by" . "Няма папярэдняй публікацыі")
                                          ("it" . "Non c'è nessun articolo precedente")
                                          ("es" . "No existe un artículo precedente")
                                          ("fr" . "Il n'y a pas d'article précédent")
                                          ("zh" . "无更旧的帖子")
                                          ("ja" . "前の投稿はありません"))
                            (no-next-post ("en" . "There is no next post")
                                          ("pl" . "Następny wpis nie istnieje")
                                          ("ru" . "Нет следующей публикации")
                                          ("by" . "Няма наступнай публікацыі")
                                          ("it" . "Non c'è nessun articolo successivo")
                                          ("es" . "No hay artículo siguiente")
                                          ("fr" . "Il n'y a pas d'article suivants")
                                          ("zh" . "无更新的帖子")
                                          ("ja" . "次の投稿はありません"))
                            (title ("en" . "Title: ")
                                   ("pl" . "Tytuł: ")
                                   ("ru" . "Заголовок: ")
                                   ("by" . "Загаловак: ")
                                   ("it" . "Titolo: ")
                                   ("es" . "Título: ")
                                   ("fr" . "Titre : ")
                                   ("zh" . "标题：")
                                   ("ja" . "タイトル: "))
                            (filename ("en" . "Filename: ")
                                      ("pl" . "Nazwa pliku: ")
                                      ("ru" . "Имя файла: ")
                                      ("by" . "Імя файла: ")
                                      ("it" . "Nome del file: ")
                                      ("es" . "Nombre del archivo: ")
                                      ("fr" . "Nom du fichier :")
                                      ("zh" . "文件名：")
                                      ("ja" . "ファイル名: "))))

(defcustom chun-blog/css-style-file ""
  "The path to alternative customized css style file"
  :type '(string):safe
  t)

(defun chun-blog/blog-template (title content &optional description)
  "Create the template that is used to generate the static pages."
  (concat "<!DOCTYPE html>\n"
          "<html lang=\""
          chun-blog/langcode
          "\">\n"
          "<head>\n"
          "<meta charset=\"UTF-8\">\n"
          "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
          (when description
            (format "<meta name=\"description\" content=\"%s\">\n"
                    description))
          ;; "<link rel=\"alternate\"\n"
          ;; "      type=\"application/rss+xml\"\n"
          ;; "      href=\"" (chun-blog/get-absolute-url org-static-blog-rss-file) "\"\n"
          ;; "      title=\"RSS feed for " org-static-blog-publish-url "\">\n"
          "<title>"
          title
          "</title>\n"
          chun-blog/page-header
          "  <style>"
          (unless (string-empty-p chun-blog/css-style-file)
            (with-temp-buffer
              (insert-file-contents chun-blog/css-style-file)
              (buffer-string)))
          "  </style>"
          "</head>\n"
          "<body>\n"
          ;; "<div id=\"preamble\" class=\"status\">"
          ;; org-static-blog-page-preamble
          ;; "</div>\n"
          ;;
          ;;
          "<div id=\"nav\" class=\"columns is-centered\">\n"
          "  <nav class=\"navbar column is-half\" role=\"navigation\" aria-label=\"main navigation\">\n"
          "    <div class=\"navbar-brand\">"
          "      <a class=\"navbar-item\" href=\""
          chun-blog/publish-url
          "\">"
          "         Superjomn's Blog"
          "      </a>"
          "    </div>"
          "    <div id=\"navbarBasicExample\" class=\"navbar-menu\">\n"
          "      <div class=\"navbar-start\">\n"
          "        <a class=\"navbar-item\" href=\""
          chun-blog/publish-url
          "\">\n"
          "Home\n"
          "        </a>"
          "        <a class=\"navbar-item\" href=\""
          (concat-to-dir chun-blog/publish-url "archive.html")
          "\">\n"
          "          Archive\n"
          "        </a>"
          "        <a class=\"navbar-item\" href=\""
          chun-blog/publish-url
          "\">\n"
          "        About\n"
          "        </a>"
          "      </div>"
          "    </div>"
          "  </nav>"
          "</div>"
          "<div class=\"columns is-centered\">"
          "  <div id=\"content\" class=\"column is-half\">\n"
          content
          "  </div>\n"
          "</div>\n"
          ;; "<div id=\"postamble\" class=\"status\">"
          ;; org-static-blog-page-postamble
          ;; "</div>\n"
          "</body>\n"
          "</html>\n"))

(defun concat-to-dir (dir filename)
  "Concat filename to another path interpreted as a directory."
  (concat (file-name-as-directory dir)
          filename))
(defun chun-blog/matching-publish-filename (post-filename)
  "Generate HTML file name for POST-FILENAME."
  (concat-to-dir chun-blog/publish-directory
                 (chun-blog/get-post-publish-path post-filename)))

(defun chun-blog/get-absolute-url (relative-url)
  "Returns absolute URL based on the RELATIVE-URL passed to the functoin."
  (concat-to-dir chun-blog/publish-url relative-url))

(defun chun-blog/get-post-filenames ()
  "Returns a list of all posts."
  (directory-files-recursively chun-blog/posts-directory
                               ".*\\.org$"))

(defun chun-blog/get-draft-filenames ()
  "Returns a list of all drafts."
  (directory-files-recursively chun-blog/drafts-directory
                               ".*\\.org$"))

(defun chun-blog/get-post-publish-path (post-filename)
  "Returns post filepath in publish directory."
  (chun-blog/generate-post-path (chun-blog/get-relative-path post-filename)
                                (chun-blog/get-date post-filename)))

(defun chun-blog/get-relative-path (post-filename)
  "Get the relative path to the html file."
  (concat (file-name-sans-extension (file-relative-name post-filename chun-blog/posts-directory))
          ".html"))

(defun chun-blog/get-html-relative-path (post-filename)
  "Removes absolute directory path from POST-FILENAME and changes file extension from '.org' to '.html'.
Returns filepath to HTML file relative to posts or drafts directories.

Works with both posts and drafts directories.

For example, when `chun-blog/posts-directory' is set to '~/blog/posts' and `post-filename' is passed as '~/blog/posts/my-life-update.org' then the function will return 'my-life-update.html'. "
  (concat (file-name-sans-extension (file-relative-name post-filename chun-blog/posts-directory))
          ".html"))

(defun chun-blog/needs-publishing-p (post-filename)
  "Check whether POST-FILENAME was changed since last render."
  (let ((pub-filename (chun-blog/matching-publish-filename post-filename)))
    (not (and (file-exists-p pub-filename)
              (file-newer-than-file-p pub-filename post-filename)))))

(defun chun-blog/get-absolute-url (relative-url)
  "Returns absolute URL based on the RELATIVE-URL passed to the function."
  (concat-to-dir chun-blog/publish-url relative-url))

(defun chun-blog/get-post-url (post-filename)
  "Returns absolute URL to the published POST-FILENAME."
  (chun-blog/get-absolute-url (chun-blog/get-post-publish-path post-filename)))

(defun chun-blog/generate-post-path (post-filename post-datetime)
  "Returns post public path based on POST-FILENAME and POST-DATETIME.
By default, this function returns post filepath unmodified.
It can be overrided.
"
  post-filename)

(defun chun-blog/post-get-published-html-path (post-name)
  "Returns the full path to the html file in the publish directory.
e.g. input 'hello.org' get '~/blog/public/hello.html'. "
  (let* ((basename (file-name-sans-extension post-name))
         (html-path (concat-to-dir chun-blog/publish-directory
                                   (concat basename ".html"))))
    html-path))

(defun chun-blog/get-post-filenames ()
  "Returns a list of all posts."
  (directory-files-recursively chun-blog/posts-directory
                               ".*\\.org$"))

(defun chun-blog/get-draft-filenames ()
  "Returns a list of all drafts."
  (directory-files-recursively chun-blog/drafts-directory
                               ".*\\.org$"))

(defun chun-blog/get-date (filename)
  "Extract the `#+date:' from FILENAME as date-time."
  (let ((case-fold-search t))
    (with-temp-buffer
      (insert-file-contents filename)
      (goto-char (point-min))
      (if (search-forward-regexp "^\\#\\+date:[ ]*\\(.+\\)$"
                                 nil t)
          (date-to-time (match-string 1))))))

(defun chun-blog/get-title (filename)
  "Extract the `#+title:' from FILENAME as title."
  (let ((case-fold-search t))
    (with-temp-buffer
      (insert-file-contents filename)
      (goto-char (point-min))
      (if (search-forward-regexp "^\\#\\+title:[ ]*\\(.+\\)$"
                                 nil t)
          (match-string 1)))))

(defun chun-blog/get-description (filename)
  "Extract the `#+title:' from FILENAME as description."
  (let ((case-fold-search t))
    (with-temp-buffer
      (insert-file-contents filename)
      (goto-char (point-min))
      (if (search-forward-regexp "^\\#\\+title:[ ]*<\\(.+\\)>$"
                                 nil t)
          (match-string 1)))))

(defun chun-blog/get-tags (post-filename)
  "Extract the `#+filetags:` from POST-FILENAME as list of strings."
  (let ((case-fold-search t))
    (with-temp-buffer
      (insert-file-contents post-filename)
      (goto-char (point-min))
      (if (search-forward-regexp "^\\#\\+filetags:[ ]*:\\(.*\\):$"
                                 nil t)
          (split-string (match-string 1)
                        ":")
        (if (search-forward-regexp "^\\#\\+filetags:[ ]*\\(.+\\)$"
                                   nil t)
            (split-string (match-string 1)
                          ":"))))))

(defun chun-blog/gettext (text-id)
  "Return localized text.
Depends on chun-blog/langcode and chun-blog/texts."
  (let* ((text-node (assoc text-id chun-blog/texts))
         (text-lang-node (if text-node
                             (assoc chun-blog/langcode text-node)
                           nil)))
    (if text-lang-node
        (cdr text-lang-node)
      (concat "["
              (symbol-name text-id)
              ":"
              chun-blog/langcode
              "]"))))


(defun chun-blog/get-post-summary (post-filename)
  "Assemble post summary for an archive page.
This function is called for every post on the archive and tags-archive page."
  (concat "<div class=\"post-date\">"
          (format-time-string (chun-blog/gettext 'date-format)
                              (chun-blog/get-date post-filename))
          "</div>"
          "<h2 class=\"post-title\">"
          "<a href=\""
          (chun-blog/get-post-url post-filename)
          "\">"
          (chun-blog/get-title post-filename)
          "</a>"
          "</h2>\n"))

(defun chun-blog/get-html-body (post-filename &optional exclude-title)
  "Get the rendered HTML body without headers from POST-FILENAME.
Preamble and Postamble are excluded, too."
  (with-temp-buffer
    (insert-file-contents (chun-blog/matching-publish-filename post-filename))
    (buffer-substring-no-properties (progn
                                      (goto-char (point-min))
                                      (if exclude-title
                                          (progn
                                            (search-forward "<h1 class=\"post-title\">")
                                            (search-forward "</h1>"))
                                        (search-forward "<div id=\"content\">"))
                                      (point))
                                    (progn
                                      (goto-char (point-max))
                                      (search-backward "<div id=\"postamble\" class=\"status\">")
                                      (search-backward "<div id=\"comments\">" nil
                                                       t)
                                      (search-backward "</div>")
                                      (point)))))


(org-export-define-derived-backend 'chun-blog/post-bare
    'html
  :translate-alist '((template . (lambda (contents info)
                                   contents))))

(defun chun-blog/file-buffer (filepath)
  "Return the buffer open with a full filepath, or nil."
  (require 'seq)
  (make-directory (file-name-directory filepath)
                  t)
  (car (seq-filter (lambda (buf)
                     (string= (with-current-buffer buf buffer-file-name)
                              filepath))
                   (buffer-list))))


(defun chun-blog/render-post-content (post-filename)
  "Render blog content as bare HTML without header"
  (let ((org-html-doctype "html5")
        (org-html-html5-fancy t))
    (save-excursion
      (let ((current-buffer (current-buffer))
            (buffer-exists (chun-blog/file-buffer post-filename))
            (result nil))
        (with-temp-buffer
          (if buffer-exists
              (insert-buffer-substring buffer-exists)
            (insert-file-contents post-filename))
          (chun--info "file-content: %s"
                      (buffer-substring (point-min)
                                        (point-max)))
          (org-mode)
          (goto-char (point-min))
                                        ; cut the noposting nodes
          (org-map-entries (lambda ()
                             (setq org-map-continue-from (point))
                                        ; Cut the subtrees thouse matching the [nonpost] tag into the clipboard.
                             (org-cut-subtree))
                           chun-blog/no-posting-tag)
          (chun--info "file-content2: %s"
                      (buffer-substring (point-min)
                                        (point-max)))
          (setq result (org-export-as 'chun-blog/post-bare nil nil
                                      nil nil))
          (switch-to-buffer current-buffer)
          (chun--debug "result: %S" result)
          result)))))

(defmacro chun-blog/with-find-file (file contents &rest body)
  "Executes BODY in FILE. Use this to insert text into FILE. The buffer is disposed after the macro exits (unless it already exited before)."
  `(save-excursion
     (let* ((current-buffer (current-buffer))
            (buffer-exists (chun-blog/file-buffer ,file))
            (result nil)
            (contents ,contents))
       (if buffer-exists
           (switch-to-buffer buffer-exists)
         (find-file ,file))
       (erase-buffer)
       (insert contents)
       (setq result (progn ,@body))
       (basic-save-buffer)
       (unless buffer-exists
         (kill-buffer))
       (switch-to-buffer current-buffer)
       result)))

(defun chun-blog/publish-file (post-filename)
  "Publish a single POST-FILENAME.
The index, archive, tags, and RSS feed are not updated. "
  (interactive "f")
  (chun-blog/with-find-file (chun-blog/matching-publish-filename post-filename)
                            (chun-blog/blog-template (chun-blog/get-title post-filename)
                                                     (chun-blog/render-post-content post-filename)
                                                     (chun-blog/get-description post-filename))))

(defun chun-blog/assemble-index ()
  "Assemble the blog index page.
The index page contains the last `chun-blog/index-length' posts as full text posts. "
  (let ((post-filenames (chun-blog/get-post-filenames)))
    ;; reverse-sort, so that the latter `last' will grab the newest posts
    (setq post-filenames (sort post-filenames
                               (lambda (x y)
                                 (time-less-p (chun-blog/get-date x)
                                              (chun-blog/get-date y)))))
    (chun-blog/assemble-multipost-page (concat-to-dir chun-blog/publish-directory
                                                      "index.html")
                                       (last post-filenames chun-blog/index-length)
                                       chun-blog/index-front-matter)))

(defun chun-blog/assemble-archive ()
  "Re-render the blog archive page.
The archive page contains single-line links and dates for every
blog post, but no post body."
  (let ((archive-filename (concat-to-dir chun-blog/publish-directory
                                         chun-blog/archive-file))
        (archive-entries nil)
        (post-filenames (chun-blog/get-post-filenames)))
    (setq post-filenames (sort post-filenames
                               (lambda (x y)
                                 (time-less-p (chun-blog/get-date y)
                                              (chun-blog/get-date x)))))
    (chun-blog/with-find-file archive-filename
                              (chun-blog/blog-template chun-blog/publish-title
                                                       (concat "<h1 class=\"title\">"
                                                               (chun-blog/gettext 'archive)
                                                               "</h1>\n"
                                                               (apply 'concat
                                                                      (mapcar 'chun-blog/get-post-summary post-filenames)))))))

(defun chun-blog/assemble-multipost-page (pub-filename post-filenames &optional front-matter)
  "Assemble a page that contains multiple posts one after another."
  (setq post-filenames (sort post-filenames
                             (lambda (x y)
                               (time-less-p (chun-blog/get-date y)
                                            (chun-blog/get-date x)))))
  (chun-blog/with-find-file pub-filename
                            (chun-blog/blog-template chun-blog/publish-title
                                                     (concat (when front-matter front-matter)
                                                             (apply 'concat
                                                                    (mapcar (if chun-blog/use-preview 'chun-blog/get-preview
                                                                              'chun-blog/get-body)
                                                                            post-filenames))
                                                             "<div id=\"archive\">\n"
                                                             "<a href=\""
                                                             (chun-blog/get-absolute-url chun-blog/archive-file)
                                                             "\">"
                                                             (chun-blog/gettext 'other-posts)
                                                             "</a>\n"
                                                             "</div>\n"))))

(defun chun-blog/get-preview-region-in-current-buffer ()
  "Find the start and end of the preview in the current buffer."
  (goto-char (point-min))
  (if chun-blog/preview-end
      (when (or (search-forward (or chun-blog/preview-start "<p>")
                                nil
                                t)
                (search-forward "<p>" nil t))
        (let ((start (match-beginning 0)))
          (or (search-forward chun-blog/preview-end nil
                              t)
              (search-forward "</p>" nil t))
          (buffer-substring-no-properties start
                                          (point))))
    (when (search-forward (or chun-blog/preview-start "<p>")
                          nil
                          t)
      (let ((start (match-beginning 0)))
        (search-forward "</p>")
        (buffer-substring-no-properties start
                                        (point))))))

;; TODO
(defun chun-blog/get-preview (post-filename)
  "Get title, date, tags from POST-FILENAME and get the first paragraph from the rendered HTML."
  (with-temp-buffer
    (insert-file-contents (chun-blog/matching-publish-filename post-filename))
    (let* ((post-title (chun-blog/get-title post-filename))
           (post-date (chun-blog/get-date post-filename))
           (post-taglist (chun-blog/get-tags post-filename))
           (post-ellipsis "")
           (preview-region (chun-blog/get-preview-region-in-current-buffer)))
      ;; TODO ...
      (when (and preview-region
                 (search-forward "<p>" nil t))
        (setq post-ellipsis (concat (when chun-blog/preview-link-p
                                      (format "<a href=\"%s\">"
                                              (chun-blog/get-post-url post-filename)))
                                    chun-blog/preview-ellipsis
                                    (when chun-blog/preview-link-p "</a>\n"))))
      (let ((title-link (format "<h2 class=\"post-title\"><a href=\"%s\">%s</a></h2>"
                                (chun-blog/get-post-url post-filename)
                                post-title))
            (date-link (format-time-string (concat "<div class=\"post-date\">"
                                                   (chun-blog/gettext 'date-format)
                                                   "</div>")
                                           post-date)))
        (concat "<div class=\"post-summary\">"
                (if chun-blog/preview-date-first-p
                    (concat date-link title-link)
                  (concat title-link date-link))
                preview-region
                post-ellipsis
                (format "<div class=\"taglist\">%s</div>"
                        post-taglist)
                "</div>")))))

(defun chun-blog/-parse-html (post-filename)
  "Parse the corresponding published HTML file and return a list"
  (with-temp-buffer
    (let* ((html-path (chun-blog/matching-publish-filename post-filename))
           (region-start 0)
           (region-end 0))
      (insert-file-contents html-path)
      (setq region-start (point-min))
      (setq region-end (point-max))
      (libxml-parse-html-region region-start region-end))))

(defun chun-blog/publish (&optional force-render)
  "Render all blog posts, the index, archive, tags, and RSS feed.
Only blog posts that changed since the HTML was created are re-rendered. "
  (interactive "P")
  (dolist (file (append (chun-blog/get-post-filenames)
                        (chun-blog/get-draft-filenames)))
    (when (or force-render
              (chun-blog/needs-publishing-p file))
      (chun-blog/publish-file file)))
  ;; Do the following work including archive and so on.
  (chun-blog/assemble-index)
  (chun-blog/assemble-archive))


(provide 'chun-blog)
