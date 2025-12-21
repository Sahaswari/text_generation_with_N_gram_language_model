# N-Gram Text Generator

## Group Members
- Senanayaka S.M.S.T.S. - EG/2020/4185
- Samasundara S.M.R.D.S - EG/2020/4184
- Dissanayaka R.P.L.M   - EG/2020/3909
- Dissanayaka D.M.C.L   - EG/2020/3903

## Project Title
N-Gram Language Model for Text Generation using Functional Programming

## Problem Description
Text generation is a fundamental task in natural language processing with applications in autocomplete, chatbots, code completion, and creative writing assistance. This project implements a probabilistic language model that learns patterns from text and generates new, contextually relevant sequences.

## Real-World Scenario
- **Autocomplete Systems**: Google Search, smartphone keyboards
- **Code Completion**: GitHub Copilot, VS Code IntelliSense
- **Chatbots**: Customer service, virtual assistants
- **Creative Writing**: Story generation, poetry assistance

## 📋 **EXECUTION FLOW**
```
User runs program
      ↓
Read dataset.txt (data file)
      ↓
Remove Gutenberg metadata (pure function)
      ↓
Preprocess text (pure function)
      ↓
Split 70/15/15 (pure function)
      ↓
Train model on 70% (pure function)
      ↓
Evaluate on 15% test (pure function)
      ↓
Interactive generation

## How to Run

### Prerequisites
- GHC (Glasgow Haskell Compiler) version 8.10 or higher
- Text corpus file (provided in data/ folder)

### Compilation
```bash
ghc -o ngram-generator src/Main.hs src/DataTypes.hs src/Utils.hs src/Processing.hs src/IOHandler.hs src/DataPreprocessing.hs
```

### Execution
```bash
./ngram-generator
```

Or using GHCi:
```bash
ghci src/Main.hs
> main
```

## Sample Input/Output

### Input
```
Training file: data/dataset.txt
N-gram size: 3
Seed words: to be or
Number of words: 15
```

### Output
```
to be or not to be that is the question whether tis nobler
```

## Functional Programming Concepts Used

### 1. Pure Functions
All core logic functions are pure (no side effects):
```haskell
buildNGramModel :: ModelConfig -> [String] -> NGramModel
```

### 2. Immutability
All data structures are immutable:
```haskell
type NGramModel = Map.Map NGram (Map.Map Word Int)
```

### 3. Recursion
Text generation uses tail recursion:
```haskell
generateLoop :: NGramModel -> Int -> [String] -> [String] -> IO [String]
```

### 4. Higher-Order Functions
Extensive use of map, fold, filter:
```haskell
let ngrams = ngramsOf (n + 1) markedWords
in foldl' (insertNGram n) Map.empty ngrams
```

### 5. Algebraic Data Types (ADT)
Custom types for configuration:
```haskell
data ModelConfig = ModelConfig
  { ngramSize :: Int
  , minFrequency :: Int
  , smoothing :: Bool
  }
```

### 6. Type Safety
Strong typing prevents runtime errors:
```haskell
type NGram = [String]
type NGramModel = Map.Map NGram (Map.Map Word Int)
```

### 7. Lazy Evaluation
Processing large files efficiently through lazy I/O

### 8. Monadic I/O
Clean separation of pure and impure code:
```haskell
main :: IO ()
```

## Project Structure
```
src/
├── Main.hs          - Entry point and user interface
├── DataTypes.hs     - Type definitions
├── Processing.hs    - Core n-gram algorithms
├── IOHandler.hs     - File I/O operations
└── Utils.hs         - Helper functions
|__ DataPreprocessing.hs - Prepare the Data for Training

data/
└── dataset.txt     - Training corpus
```
┌─────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYERS                   │
├─────────────────────────────────────────────────────────────┤
│  Main.hs                 → Orchestration & User Interface   │
├─────────────────────────────────────────────────────────────┤
│  IOHandler.hs            → I/O Operations & Display         │
├─────────────────────────────────────────────────────────────┤
│  DataPreprocessing.hs    → RAW TEXT → CLEAN TOKENS          │
│                            (Data Engineering Layer)         │
├─────────────────────────────────────────────────────────────┤
│  Processing.hs           → TOKENS → N-GRAM MODEL            │
│                            (Machine Learning Layer)         │
├─────────────────────────────────────────────────────────────┤
│  Utils.hs                → Shared Utilities                 │
├─────────────────────────────────────────────────────────────┤
│  DataTypes.hs            → Type Definitions                 │
└─────────────────────────────────────────────────────────────┘

## Features
- Bigram, Trigram, and 4-gram models
- Interactive text generation
- Top prediction display
- Model statistics
- Perplexity calculation
- Fallback for unseen contexts
- Export generated text

## Future Extensions
- Add smoothing techniques (Laplace, Good-Turing)
- Implement beam search for better generation
- Add sentence boundary detection
- Support multiple languages
- Web interface using Servant
```

## Data Processing Pipeline

Our project demonstrates functional data processing:

1. **Single Input**: shakespeare_raw.txt
2. **Pure Functions**: All processing in Haskell
3. **Automatic Splitting**: 70% train, 15% validation, 15% test
4. **No External Tools**: Everything in Haskell

This showcases functional programming principles:
- Pure, testable functions
- Immutable data transformations
- Type-safe pipeline
- Function composition
---

## **PART 7: Technical Report Outline**

Create a 3-4 page report with these sections:

### **Section 1: Problem Statement (0.5 page)**
```
1.1 Introduction
- What is text generation?
- Why is it important?

1.2 Industrial Motivation
- Autocomplete systems (Google, smartphones)
- Code completion (GitHub Copilot)
- Chatbots and virtual assistants
- Content creation tools

1.3 Why N-Grams?
- Simple yet effective
- Foundation of language modeling
- Used in production systems
```

### **Section 2: Functional Design (1 page)**
```
2.1 Architecture Overview
[Diagram showing: Input → Cleaning → Training → Model → Generation → Output]

2.2 Key Type Signatures
type NGram = [String]
type NGramModel = Map.Map NGram (Map.Map Word Int)

buildNGramModel :: ModelConfig -> [String] -> NGramModel
generateText :: NGramModel -> Int -> [String] -> IO [String]

2.3 Data Flow
1. Read text file
2. Clean and tokenize
3. Build n-gram frequency map
4. Generate text using probabilities
```

### **Section 3: FP Concepts Application (1 page)**
```
3.1 Pure Functions
- All training logic is pure
- Example: buildNGramModel has no side effects

3.2 Immutability
- Model never modified after creation
- New data structures created on updates

3.3 Recursion
- generateLoop uses tail recursion
- ngramsOf recursively creates n-grams

3.4 Higher-Order Functions
- foldl' for accumulation
- map for transformations
- filter for cleaning

3.5 Type Safety
- Compile-time guarantees
- No null pointer exceptions
```

### **Section 4: Results & Discussion (0.75 page)**
```
4.1 Model Performance
- Bigram: Fast but less coherent
- Trigram: Good balance
- 4-gram: Best quality

4.2 Sample Outputs
[Show actual generated text examples]

4.3 Perplexity Scores
[If you calculated them]

4.4 Why FP Improves This System
- Correctness: Pure functions are testable
- Reliability: No hidden state bugs
- Concurrency: Easy to parallelize (future work)
- Maintainability: Clear data flow
```

### **Section 5: Conclusion & Extensions (0.25 page)**
```
5.1 Achievements
- Implemented working n-gram model
- Demonstrated FP principles
- Generated coherent text

5.2 Possible Extensions
- Add smoothing techniques
- Implement beam search
- Support multiple languages
- Build web interface
- Add neural language models
```

---

## **PART 8: Presentation Script (5-10 minutes)**

### **Slide 1: Title (30 seconds)**
```
"N-Gram Text Generator using Functional Programming"
Team Members: [Names]
```

### **Slide 2: Problem (1 minute)**
```
"Text generation powers:
- Google autocomplete
- GitHub Copilot
- ChatGPT (advanced version)
- Smartphone keyboards"

Show example: Type "the cat" → suggests "sat on the mat"
```

### **Slide 3: Our Approach (1 minute)**
```
"We built an N-gram language model:
1. Learn patterns from text
2. Calculate probabilities
3. Generate new text

Example: After 'to be', model learns:
- 'or' appears 60%
- 'that' appears 30%
- 'the' appears 10%"