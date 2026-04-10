# Paper Type Configuration Guide

This guide explains how to configure `paper-type.json` for your paper and how the derived thresholds affect quality gates.

## Quick Reference

```bash
/paper:init --format long --domain ai-experimental --venue NeurIPS --pages 9
```

## Format Options

| Format | Description | Page Limit | Abstract Max Words |
|--------|-------------|------------|-------------------|
| `long` | Full paper (NeurIPS, ICML, ICLR, journal) | 8-12 | 250 |
| `short` | Short paper / workshop | 4-8 | 150 |
| `letter` | Letters / commentary | 2-4 | 150 |

## Domain Options

| Domain | Description | Key Requirements |
|--------|-------------|------------------|
| `ai-experimental` | Empirical AI research | Ablation study, ≥3 runs, significance tests |
| `ai-theoretical` | Theory / proofs | No ablation required, fewer figures |
| `physics` | Physics experiments | Systematic vs random error, no ablation |
| `numerical` | Numerical simulation | Grid independence, convergence order, ablation |

## Derived Thresholds

### Citation Requirements

| Format + Domain | Min References | Recent Refs % |
|-----------------|----------------|---------------|
| long + any | 30 | varies by domain |
| short + any | 15 | varies by domain |
| letter + any | 10 | 15% |

**Recent refs by domain**:
- ai-experimental: 30%
- ai-theoretical: 15%
- physics: 20%
- numerical: 20%

### Figure & Table Requirements

| Format + Domain | Min Figures | Min Tables | Require Ablation |
|-----------------|-------------|------------|-----------------|
| long + ai-exp | 5 | 1 | yes |
| long + physics | 4 | 1 | no |
| long + ai-theory | 3 | 1 | no |
| long + numerical | 3 | 1 | yes (sensitivity) |
| short + any | 3 | 1 | yes (ai-exp) |
| letter + any | 2 | 0 | no |

### Experiment Runs

| Domain | Min Runs | Notes |
|--------|---------|-------|
| ai-experimental | 3 | Sufficient for mean±std |
| others | 1+ | As appropriate |

## Exemptions

### `recent_refs_pct_exempt`

Set to `true` only if justified (e.g., theory paper citing foundational works). Must provide reason in `recent_refs_pct_exempt_reason`.

### `ablation_exempt`

Set to `true` if ablation is not applicable (e.g., theory paper). Must document reason.

## Modifying After Init

```bash
# Re-run paper:init with new parameters
/paper:init --format short --domain ai-theoretical --venue ACL --pages 8

# Or manually edit .arc/paper-type.json
```

All hooks automatically read the updated thresholds on next run.

## Validation

Run `./validate.sh` to verify paper-type.json is valid and all thresholds are correctly set.
