# Report Generation Feature

## Overview
The N-Gram Text Generator now automatically generates execution reports that include:
- **Input Parameters**: Data file, N-gram size, seed words, requested length
- **Output Results**: Generated text and statistics

## How It Works

### During Text Generation
When you generate text, the program will ask:
```
📊 Generate execution report? (y/n):
```

If you answer `y`, a report will be automatically saved to `outputs/reports/`

### Report Format
Reports are saved with timestamps: `report_YYYYMMDD_HHMMSS.txt`

Example: `report_20241219_153045.txt`

## Sample Report Output

```
╔═══════════════════════════════════════════════════════════════╗
║          N-GRAM TEXT GENERATOR - EXECUTION REPORT             ║
╚═══════════════════════════════════════════════════════════════╝

Report Generated: 2024-12-19 15:30:45 UTC
═══════════════════════════════════════════════════════════════════

📥 INPUT PARAMETERS
───────────────────────────────────────────────────────────────────
• Data File: data/dataset.txt
• N-gram Size: 3 (Trigram)
• Seed Words: to be or
• Requested Words: 20

📤 OUTPUT
───────────────────────────────────────────────────────────────────
Generated Text:

to be or not to be that is the question whether tis nobler
in the mind to suffer the slings and arrows of

Statistics:
• Total Words Generated: 20
• Unique Words: 18
• Average Word Length: 3.45 characters

═══════════════════════════════════════════════════════════════════
N-Gram Text Generator - Functional Programming Project
═══════════════════════════════════════════════════════════════════
```

## Location
All reports are saved in: `outputs/reports/`

## Benefits
- ✅ Track all your text generation experiments
- ✅ Compare different n-gram sizes and seed words
- ✅ Document results for your project report
- ✅ Easy to share and present results

## Usage Example

```haskell
-- When running the program:
1. Generate text (choose option 1)
2. Enter seed words: "to be or"
3. Enter word count: 20
4. When asked "Generate execution report? (y/n):", type: y
5. Report is automatically saved!
```

## Note
- Reports use pure functional programming principles
- Timestamps ensure unique filenames
- No duplicate reports (each has unique timestamp)
