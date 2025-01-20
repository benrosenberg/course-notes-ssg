# course-note-ssg

Simple static site generator for course notes.

Can be used for other things too probably, but I created this for the course notes I was taking at the time and its minimal feature set is best for self-contained things like a set of sequential lecture notes.

Links: 

- [GitHub link](https://github.com/benrosenberg/course-notes-ssg)
- [Example site with real course notes](https://benrosenberg.info/posts/CSCI-260-notes/)

## Expected file structure

```plaintext
.
├── html
│   └── <html files will be generated here>
├── images
│   ├── by.svg
│   ├── by_dark.svg
│   ├── cc.svg
│   ├── cc_dark.svg
│   └── favicon.png
├── md
│   └── <markdown files go here>
└── meta
    ├── config.txt
    ├── hljs-gruvbox-dark.css
    ├── math.js
    ├── menu.js
    ├── redirect.html
    ├── style.css
    ├── template.html
    └── theme.js
```

## Methodology

High-level steps:

0. Delete all HTML files in the output HTML directory
1. Generate index of files:
   - Any files with the `.md` extension in the markdown file directory (`md`) are picked up
   - Files are ordered alphabetically by filename
   - This index is used in the left-hand navigation bar
2. Create template based on index and other inputs (CSS, static content, etc.):
   - Other inputs include JS files for KaTeX math rendering and highlight.js code highlighting. Both of these are delivered via CDN
   - Additionally, some local JS files are loaded to help with the left-hand menu, theming, and applying the KaTeX math rendering
   - The meta/config.txt file is used for global constants such as the site name and the root URL
3. For each markdown file provided, convert the file to HTML using the template:
   - Page titles are taken from the filename (with `.md` removed)
   - The current page is marked as selected in the index
4. Generate the landing page:
   - The landing page redirects to the first file in the index by default
   - Other files are accessible by using the left-hand menu after navigating to the first file
   - You can also add the LANDING directive to the config.txt file to set a custom landing page instead
   - The landing page is accessible by clicking on the site name in the menu

## Notes

- Images need to be in the `html` directory, otherwise they won't be visible.

### Config file syntax

Config files have the following syntax (the "SITENAME" and "ROOT" variables are required):

```
SITENAME=Site Name
ROOT=http://localhost:2000
LANDING=http://localhost:2000/custom-landing-page.html
```

The string `x` on the left hand of the `=` is turned into the variable `!!!x!!!` in the global replacements dictionary and is used to fill parameters of the HTML template. Any line without a `=` character will be skipped.

- `SITENAME`: The name of the site. Will be used in the left-hand menu header
- `ROOT`: The root URL for the site, is used in the template file to prefix URLs for static content
- `LANDING`: If not present, will generate the redirect index.html page at the top level; otherwise, will prepend the `ROOT` variable to the value of the user-provided landing page variable to serve as a custom landing page

### More complex modifications?

Feel free to fork this repository and modify the code as needed.

- This project is written in [D](https://dlang.org/) and was compiled with v2.109.1 of the [DMD64 D Compiler for Windows](https://dlang.org/dmd-windows.html)
- It depends on [`commonmark-d`](https://code.dlang.org/packages/commonmark-d?tab=info), so you will need to install that via the `dub` package manager