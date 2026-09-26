# Optional features

Each box switches one optional part of this configuration on or off. Ticked is
included; unticked is left out. These are the defaults for every machine.

**Per-machine overrides** go in `~/.config/configme/features.md`, in the same
format. Copy a line from here and change its box; any line present there wins
over this file on that machine only. `./install.sh` creates that file if it is
missing, and `./install.sh --doctor` lists what is on and where each setting
came from.

A feature that is off is left out everywhere: `./install.sh --deps` and
`--install-deps` stop asking for its system packages, the doctor stops checking
for it, Mason stops installing its tools, and its Neovim plugins are disabled.
Switching one off does **not** uninstall anything already installed.

After changing a box, restart Neovim and re-run `./install.sh --deps`.

- [ ] latex -- LaTeX editing: vimtex (compile, view, motions, conceal), texlab, tex-fmt, latex/bibtex parsers; TeX Live, chktex and zathura from apt (~700 MB)
- [x] diagrams -- Rendered images beyond plain pictures: Mermaid diagrams (mmdc plus a Chrome install), LaTeX math in documents (tectonic), PDF previews (ghostscript). Plain images are always on.
