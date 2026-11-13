# Internal Presentations

A collection of tools for build reproducible technical
presentations. This project uses pandoc to process markdown files into
slidy presentations. We use plantuml or mermaid to build digrams.

## Install

```shell
brew bundle
```

## Usage

Add your presentations as markdown files in a folder named after you
(e.g. `ivan/`, `alex/`). `just build-all` builds every `*.md` file in
every top-level folder. Output HTML goes to `build/`, mirroring the
source layout (e.g. `ivan/notifications-storage.md` builds to
`build/ivan/notifications-storage.html`).

```shell
just --list
just build-all
just build-presentation ivan/notifications-storage.md
just clean
```


## Styling

Decks are themed by `templates/oneproject.css`, a Slidy stylesheet
using One Project's design tokens (cream paper, Roboto/Roboto Serif,
amber accents). It's embedded into each built deck, so the output is a
single self-contained HTML file. Retheme by editing the `:root` token
block at the top of the file. Useful extras: `# Title {.dark}` for a
full-bleed dark slide, `::: handout` for speaker notes (hidden on
screen, shown in print), and `::: columns` / `::: column` for
side-by-side layout.

## Pandoc

Pandoc provides us a build pipeline where we translate raw digram code
blocks into SVGs
