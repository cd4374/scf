# LaTeX Templates for ARC-Harness

This directory contains LaTeX templates for various AI/ML conferences and journals supported by the ARC research pipeline.

## Available Templates

### Conference Templates

| Venue | File | Status | Notes |
|-------|------|--------|-------|
| **NeurIPS** | `neurips/template.tex` + `neurips_2026.sty` | ✅ Ready | NeurIPS 2026 (single-column, numbered references) |
| **ICML** | `icml/template.tex` + `icml2026.sty` | ✅ Ready | ICML 2026 (two-column, 8 pages main + references) |
| **ICLR** | `iclr/template.tex` | ✅ Ready | ICLR 2026 (OpenReview-compatible template) |
| **AAAI** | `aaai/template.tex` | ✅ Ready | AAAI 2026 (7 pages main + references) |
| **ACL** | `acl/template.tex` | ⚠️ Partial | ACL, EMNLP, NAACL scaffold; requires official `acl.sty` |
| **CVPR** | `cvpr/template.tex` | ⚠️ Partial | CVPR, ICCV, ECCV scaffold; requires official `cvpr.sty` |
| **IEEE Conference** | `ieee/template_conference.tex` | ✅ Ready | IEEE conference proceedings (requires IEEEtran) |

### Journal Templates

| Venue | File | Status | Notes |
|-------|------|--------|-------|
| **IEEE Journal** | `ieee/template_journal.tex` | ✅ Ready | IEEE Transactions journals (requires IEEEtran) |
| **Elsevier** | `elsevier/template.tex` | ✅ Ready | Elsevier journals (Pattern Recognition, etc.; requires elsarticle) |
| **Springer** | `springer/template.tex` | ✅ Ready | Springer journals (LNCS, etc.; requires svjour3) |

## Asset Contract

Stage 15.7 (`arc-07-00-template-resolve`) treats templates in three states:

- `ready`: All required files bundled in this repo
- `partial`: Template scaffold provided, but requires external `.sty` files
- `user_supplied`: User explicitly provides custom template

## Template Selection

Templates are referenced by `template_id` in the pipeline:

```json
{
  "target_venue": "neurips",
  "template_version": "neurips_2026"
}
```

### Template IDs

**Conferences:**
- `neurips_2026`, `neurips_2025`
- `icml_2026`, `icml_2025`
- `iclr_2026`, `iclr_2025`
- `aaai_2026`
- `acl_2025`, `emnlp_2025`, `naacl_2025`
- `cvpr_2026`, `iccv_2025`, `eccv_2026`
- `ieee_conference`

**Journals:**
- `ieeetran_journal`
- `elsevier_cas_sc`
- `pattern_recognition`
- `springer_lncs_journal`

## Completing Partial Templates

### ACL/EMNLP/NAACL

```bash
# Download official ACL style file
cd artifacts/<run_id>/template/
wget https://raw.githubusercontent.com/acl-org/acl-style-files/master/acl.sty
# Or clone and copy
# git clone https://github.com/acl-org/acl-style-files.git
```

**Note**: ACL style file must be in the same directory as `main.tex`.

### CVPR/ICCV/ECCV

```bash
# Download official CVPR style file
cd artifacts/<run_id>/template/
wget https://raw.githubusercontent.com/cvpr-org/author-kit/master/cvpr.sty
```

**Note**: CVPR style file must be in the same directory as `main.tex`.

## Using Templates

### Automatic Selection (Default)

The pipeline automatically selects the appropriate template based on:
1. Explicit `template_version` parameter (highest priority)
2. `target_venue` alias matching
3. Default based on `publication_type`

### Manual Template Override

```json
{
  "template_version": "neurips_2026",
  "template_override": {
    "path": "custom/template/",
    "style_files": ["custom.sty"]
  }
}
```

## Math Commands

Include the math commands file for common ML notation:

```latex
\input{math_commands.tex}
```

Provides standardized notation for:
- Vectors/matrices: `\vect{x}`, `\mat{W}`
- Probability: `\E`, `\prob{}`, `\gauss{}{}`
- Optimization: `\argmin`, `\grad{w}`
- ML notation: `\dataset`, `\loss{}`, `\relu`, etc.

## Compilation Requirements

### Required LaTeX Packages

- `pdflatex` or `xelatex`
- `bibtex` or `biber`
- Standard packages: `amsmath`, `graphicx`, `hyperref`, etc.

### Compilation Command

```bash
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

Or using `latexmk`:

```bash
latexmk -pdf main.tex
```

## Template Structure

Each template includes these sections:

```latex
\section{Introduction}      % Problem + motivation
\section{Related Work}     % Literature review
\section{Method}            % Proposed approach
\section{Experiments}       % Empirical evaluation
\section{Conclusion}        % Summary + future work
\section*{Broader Impact}   % Societal implications (if required)
\section*{Limitations}      % Honest limitations (required)
```

## Adding New Templates

To add a new venue template:

1. Create a new directory under `templates/`
2. Add `template.tex` with standard sections
3. Add style file if self-contained (`.sty`)
4. Update `arc-07-00-template-resolve/SKILL.md` with new `template_id`
5. Update this README with template information

## References

- [NeurIPS Author Guidelines](https://nips.cc/)
- [ICML Author Guidelines](https://icml.cc/)
- [ICLR Author Guidelines](https://iclr.cc/)
- [AAAI Author Guidelines](https://aaai.org/)
- [ACL Style Files](https://github.com/acl-org/acl-style-files)
- [CVPR Author Kit](https://github.com/cvpr-org/author-kit)
- [IEEE Author Guidelines](https://ieeeauthorcenter.ieee.org/)
- [Elsevier Author Guidelines](https://www.elsevier.com/authors)
- [Springer Author Guidelines](https://www.springer.com/gp/authors-editors/authors)
