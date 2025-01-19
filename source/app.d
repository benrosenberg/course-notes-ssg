import std.stdio;
import std.algorithm;
import std.file;
import std.path;
import std.string;
import std.array;
import std.conv;
import commonmarkd;

int main() {
    writeln("Generating site...");
    // check whether required folders and files exist
    string md_file_folder = "md", meta_file_folder = "meta", html_file_folder = "html";
    string template_filename = "template.html", config_filename = "config.txt";
    if (!exists(md_file_folder)) {
        writefln("Designated markdown file folder \"%s\" was not found in this directory.",
            md_file_folder);
        return 1;
    }
    if (!exists(meta_file_folder)) {
        writefln(
            "Designated meta file folder \"%s\" was not found in this directory.",
            meta_file_folder);
        return 1;
    }
    if (!exists(html_file_folder)) {
        writefln(
            "Designated HTML file folder \"%s\" was not found in this directory.",
            html_file_folder);
        return 1;
    }
    if (!exists(buildNormalizedPath(meta_file_folder, template_filename))) {
        writefln(
            "HTML template file \"%s\" in folder \"%s\" was not found.",
            template_filename, meta_file_folder);
        return 1;
    }
    if (!exists(buildNormalizedPath(meta_file_folder, config_filename))) {
        writefln(
            "Configuration file \"%s\" in folder \"%s\" was not found.",
            config_filename, meta_file_folder);
        return 1;
    }

    // delete existing outputs
    foreach (old_html_file; dirEntries(html_file_folder, "*.html", SpanMode.shallow)) {
        remove(old_html_file);
    }

    auto markdown_files = dirEntries(md_file_folder, "*.md", SpanMode.shallow).array;

    if (markdown_files.length == 0) {
        writefln(
            "Mo markdown files found in folder \"%s\".",
            md_file_folder);
        return 0;
    }

    string[string] global_replacements;

    // read config file and apply variables defined there to global replacements
    string config = readText(buildNormalizedPath(meta_file_folder, config_filename));
    foreach (config_line; config.splitter("\n")) {
        string[] config_split_line = config_line.split("=");
        if (config_split_line.length == 2) {
            global_replacements[format("!!!%s!!!", config_split_line[0].strip)] =
                config_split_line[1].strip;
        }
    }

    string[] required_keys = ["!!!ROOT!!!", "!!!SITENAME!!!"];
    foreach (key; required_keys) {
        if (!(key in global_replacements)) {
            writefln("Required key %s not found in %s.",
                key, config_filename);
            return 1;
        }
    }

    // generate index of items
    // assume shallow for now
    string index = "<ul>";
    auto sorted_markdown_files = sort(markdown_files);
    foreach (markdown_file; sorted_markdown_files) {
        string page_title = baseName(markdown_file, ".md");
        string page_path_html = [
            global_replacements["!!!ROOT!!!"], "html",
            format("%s.html", page_title)
        ].join("/");
        index ~= format("<li><a href=\"%s\">%s</a>", page_path_html, page_title);
    }
    index ~= "</ul>";

    global_replacements["!!!INDEX!!!"] = index;

    // create landing page
    if (!("!!!LANDING!!!" in global_replacements)) {
        string page_path_html = [
            global_replacements["!!!ROOT!!!"], "html",
            format("%s.html", baseName(sorted_markdown_files.front, ".md"))
        ].join("/");
        global_replacements["!!!LANDING!!!"] = page_path_html;
        // copy meta/redirect.html into the top level index.html
        // replacing !!!LANDING!!! with the first md file's path
        string redirect_template_file = "redirect.html";
        string redirect_path = buildNormalizedPath(meta_file_folder, redirect_template_file);
        if (!exists(redirect_path)) {
            writefln(
                "Expected redirect template to be present due to missing LANDING directive in config.txt, "
                    ~ "but redirect template file \"%s\" in folder \"%s\" was not found.",
                    redirect_template_file, meta_file_folder);
            return 1;
        }
        string redirect_template_contents = readText(redirect_path);
        auto f = File("index.html", "w");
        f.write(replace(redirect_template_contents, "!!!LANDING!!!",
                global_replacements["!!!LANDING!!!"]));
    } else {
        // copy provided landing page contents into index.html
        copy(global_replacements["!!!LANDING!!!"], "index.html");
        // landing page is just index.html now
        global_replacements["!!!LANDING!!!"] = global_replacements["!!!ROOT!!!"];
    }

    foreach (md_file; markdown_files) {
        string markdown = readText(md_file);
        string html = convertMarkdownToHTML(
            markdown,
            MarkdownFlag.latexMathSpans
                | MarkdownFlag.tablesExtension
                | MarkdownFlag.noIndentedCodeBlocks
                | MarkdownFlag.permissiveAutoLinks
                | MarkdownFlag.collapseWhitespace
                | MarkdownFlag.enableTaskLists
                | MarkdownFlag.permissiveATXHeaders
                | MarkdownFlag.enableStrikeThrough
        );
        string page_title = baseName(md_file, ".md");
        string page_path = buildNormalizedPath(
            "html", format("%s.html", page_title)
        );
        string page_path_html = [
            global_replacements["!!!ROOT!!!"], "html",
            format("%s.html", page_title)
        ].join("/");
        auto f = File(page_path, "w");
        string html_template = readText(
            buildNormalizedPath(meta_file_folder, template_filename));
        foreach (to_replace, replacement; global_replacements) {
            // mark current page as selected in index
            if (to_replace == "!!!INDEX!!!") {
                replacement = replace(
                    replacement,
                    format("<li><a href=\"%s\">%s</a>",
                        page_path_html, page_title),
                    format("<li class=\"currentpage\"><a class=\"currentpage\" href=\"%s\">%s</a>",
                        page_path_html, page_title)
                );
            }
            html_template = replace(html_template, to_replace, replacement);
        }
        string[string] local_replacements = [
            "!!!TITLE!!!": page_title,
        ];
        foreach (to_replace, replacement; local_replacements) {
            html_template = replace(html_template, to_replace, replacement);
        }
        f.write(replace(html_template, "!!!CONTENT!!!", html));
    }

    writeln("Site generation complete.");
    return 0;
}
