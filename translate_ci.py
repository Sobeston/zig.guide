from re import template
import jinja2
import os
import sys
import pathlib
from os import path
import tomllib as toml

TRANSLATION_DIR = "./docs"
SNIPPET_DIR = "./docs/snippets/"


def main() -> None:
    template_dict = get_template_dict()
    snippets_dict = get_rendered_snippets_dict(template_dict)

    for language, chapters in snippets_dict.items():
        for chapter in chapters:
            try:
                language_dir = path.join(TRANSLATION_DIR, language)
                for markdown in os.listdir(language_dir):
                    markdown = path.join(language_dir, markdown)
                    with open(markdown, "r+") as md_file:
                        md_templ = jinja2.Template(md_file.read())
                        md_expanded = md_templ.render(
                            snippets_dict[language][chapter])
                        md_file.seek(0)
                        md_file.write(md_expanded)

            except FileNotFoundError:
                print(
                    f"Error: No snippets have been provided for {language}", file=sys.stderr)


# renders snippets and inserts them into a dictionary with the following structure
# structure of the returned dictionary: dict[language][chapter][snippet_name]
def get_rendered_snippets_dict(template_dict: dict[str, dict[str, list[str]]]) -> dict[str, dict[str, dict[str, str]]]:
    snippets_dict: dict[str, dict[str, dict[str, str]]] = dict()
    for chapter, templates in template_dict.items():
        snippets_dict[chapter] = dict()

        for template, translations in templates.items():
            with open(template, "r") as template_file:
                templ = jinja2.Template(template_file.read())
                for translation in translations:
                    with open(translation, "r") as trans_toml:
                        data = toml.loads(trans_toml.read())
                        snippet_name = pathlib.Path(template).parent.stem
                        language = pathlib.Path(translation).stem
                        if language not in snippets_dict:
                            snippets_dict[language] = dict()
                            snippets_dict[language][chapter] = dict()
                        snippets_dict[language][chapter][snippet_name] = templ.render(
                            data)
    return snippets_dict


def get_template_dict() -> dict[str, dict[str, list[str]]]:
    translation_dict: dict[str, dict[str, list[str]]] = dict()
    for chapter in os.listdir(SNIPPET_DIR):
        chapter_path = path.join(SNIPPET_DIR, chapter)
        translation_dict[chapter] = dict()

        for section in os.listdir(chapter_path):
            section_path = path.join(chapter_path, section)
            section_dirs = os.listdir(section_path)

            template_file = ""
            # figure out which file is the snippet template
            for snippet in section_dirs:
                if snippet.endswith(".zig"):
                    template_file = path.join(section_path, snippet)
                    break

            # initializes dictionary with values such that
            # key: is the path for the corresponding template file (the snippet)
            # value: is a list of paths for the translation TOMLs
            for translation in section_dirs:
                translation_path = path.join(section_path, translation)
                if translation.endswith(".zig") or not translation.endswith(".toml"):
                    continue
                if template_file not in translation_dict[chapter]:
                    translation_dict[chapter][template_file] = [
                        translation_path]
                else:
                    translation_dict[chapter][template_file].append(
                        translation_path)
    return translation_dict


if __name__ == "__main__":
    main()
