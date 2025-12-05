{-|
Module      : DataPreprocessing
Description : Data engineering pipeline for text preprocessing
Copyright   : (c) Your Team, 2024
License     : MIT

This module handles the DATA ENGINEERING phase of the pipeline.
It transforms raw text into clean, tokenized data ready for model training.

RESPONSIBILITIES:
  ✓ Remove metadata (headers, footers)
  ✓ Clean text (punctuation, whitespace)
  ✓ Tokenization (split into words)
  ✓ Stop word filtering
  ✓ Dataset splitting (train/validation/test)
  ✓ Statistical analysis

DOES NOT:
  ✗ Build n-gram models (that's Processing.hs)
  ✗ Generate text
  ✗ Handle file I/O (that's IOHandler.hs)

Design Principle: Pure Functional Data Pipeline
- All functions are pure (no side effects)
- Composable transformations
- Type-safe at every step
-}

module DataPreprocessing
  ( removeGutenbergMetadata
  , preprocessText
  , standardSplit
  , largeSplit
  , simpleTrainTestSplit
  , computeStats
  , fullPipeline
  , simplePipeline
  ) where

import Data.Char (toLower, isSpace, isPunctuation)
import Data.List (foldl', sortBy)
import Data.Ord (comparing)
import qualified Data.Set as Set
import qualified Data.Map.Strict as Map
import DataTypes
import Utils (findSubstring)

-- ============================================================================
-- METADATA REMOVAL (Project Gutenberg specific)
-- ============================================================================

-- | Remove Project Gutenberg legal headers and footers
-- These appear in all Gutenberg texts and pollute the training data
--
-- Structure of Gutenberg files:
--   [Header with license info]
--   *** START OF THIS PROJECT GUTENBERG EBOOK HAMLET ***
--   [Actual content]
--   *** END OF THIS PROJECT GUTENBERG EBOOK HAMLET ***
--   [Footer with license info]
--
-- Strategy: Find markers, extract content between them
--
-- Time Complexity: O(n) where n is text length
-- Pure Function: ✓
removeGutenbergMetadata :: String -> String
removeGutenbergMetadata text =
  let startMarker = "*** START OF"
      endMarker = "*** END OF"
  in case (findSubstring startMarker text, findSubstring endMarker text) of
       (Just startIdx, Just endIdx) ->
         -- Find actual content start (skip the marker line itself)
         let contentStart = findNextNewline (startIdx + length startMarker) text
         in take (endIdx - contentStart) (drop contentStart text)
       _ -> text  -- No markers found, return as-is
  where
    -- Helper: Find next newline character after given index
    findNextNewline :: Int -> String -> Int
    findNextNewline idx str
      | idx >= length str = idx
      | str !! idx == '\n' = idx + 1
      | otherwise = findNextNewline (idx + 1) str

-- ============================================================================
-- TEXT CLEANING PIPELINE
-- ============================================================================

-- | Main preprocessing pipeline
-- Applies multiple transformations in sequence
--
-- Pipeline stages:
--   1. Lowercase conversion (optional)
--   2. Punctuation removal (optional)
--   3. Whitespace normalization
--   4. Tokenization
--   5. Stop word filtering (optional)
--   6. Length filtering
--
-- Design Pattern: Pipeline/Chain of Responsibility
-- Each stage transforms the data for the next stage
--
-- Example:
--   Input:  "Hello, World! How are you?"
--   Stage 1: "hello, world! how are you?"
--   Stage 2: "hello world how are you"
--   Stage 3: "hello world how are you"
--   Stage 4: ["hello", "world", "how", "are", "you"]
--   Stage 5: ["hello", "world"]  (if stop words removed)
--   Stage 6: ["hello", "world"]
--
-- Time Complexity: O(n) where n is text length
-- Pure Function: ✓
preprocessText :: PreprocessConfig -> String -> [String]
preprocessText config text =
  let stage1 = if lowercase config 
               then map toLower text 
               else text
               
      stage2 = if removePunctuation config
               then filter (\c -> not (isPunctuation c) || isSpace c) stage1
               else stage1
               
      stage3 = cleanWhitespace stage2
      
      stage4 = tokenize stage3
      
      stage5 = if removeStopWords config
               then filterStopWords stage4
               else stage4
               
      stage6 = filterByLength (minWordLength config) stage5
      
  in stage6

-- | Normalize whitespace (collapse multiple spaces)
-- "hello    world" → "hello world"
--
-- Why: Multiple spaces can cause tokenization issues
-- Pure Function: ✓
cleanWhitespace :: String -> String
cleanWhitespace = unwords . words

-- | Tokenize text into words
-- Simple whitespace-based tokenization
--
-- Limitation: Doesn't handle contractions (can't → ["can", "t"])
-- For production: Use NLP library like tokenizers
--
-- Pure Function: ✓
tokenize :: String -> [String]
tokenize = words

-- | Filter out common stop words
-- Stop words: High-frequency words with little semantic meaning
--
-- Examples: "the", "a", "is", "are", "and", "or"
--
-- When to use:
--   ✓ Text classification
--   ✓ Information retrieval
--   ✗ Language modeling (we want natural text!)
--
-- For this project: Usually set to False for better generation
--
-- Time Complexity: O(n * log m) where n=words, m=stopword set size
-- Pure Function: ✓
filterStopWords :: [String] -> [String]
filterStopWords ws = filter (not . isStopWord) ws
  where
    -- Common English stop words
    -- Source: NLTK stop words list (subset)
    stopWords :: Set.Set String
    stopWords = Set.fromList
      ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
       "of", "with", "is", "was", "are", "were", "been", "be", "have", "has",
       "had", "do", "does", "did", "will", "would", "should", "could", "may",
       "might", "must", "can", "i", "you", "he", "she", "it", "we", "they",
       "this", "that", "these", "those", "am", "as", "by", "from"]
    
    isStopWord :: String -> Bool
    isStopWord w = Set.member (map toLower w) stopWords

-- | Filter words by minimum length
-- Removes very short words (often not meaningful)
--
-- Example: minLength=2 removes "a", "I", etc.
--
-- Pure Function: ✓
filterByLength :: Int -> [String] -> [String]
filterByLength minLen = filter (\w -> length w >= minLen)

-- ============================================================================
-- DATASET SPLITTING
-- ============================================================================

-- | Split data into training/validation/test sets
-- Standard machine learning practice
--
-- Why split:
--   - Training: Learn patterns
--   - Validation: Tune hyperparameters
--   - Test: Evaluate final performance
--
-- Common splits:
--   - 70/15/15 (standard)
--   - 80/10/10 (large datasets)
--   - 60/20/20 (small datasets)
--
-- Important: Don't touch test set until final evaluation!
--
-- Time Complexity: O(n) for list slicing
-- Pure Function: ✓
splitDataset :: Double -> Double -> Double -> [String] -> DatasetSplit
splitDataset trainRatio valRatio _testRatio items =
  let total = length items
      trainSize = floor (fromIntegral total * trainRatio)
      valSize = floor (fromIntegral total * valRatio)
      
      training = take trainSize items
      validation = take valSize (drop trainSize items)
      testing = drop (trainSize + valSize) items
      
  in DatasetSplit
       { trainingData = training
       , validationData = validation
       , testingData = testing
       }

-- | Standard 70/15/15 split
-- Recommended for most datasets
--
-- Pure Function: ✓
standardSplit :: [String] -> DatasetSplit
standardSplit = splitDataset 0.70 0.15 0.15

-- | 80/10/10 split for larger datasets
-- Use when you have >100K words
--
-- Pure Function: ✓
largeSplit :: [String] -> DatasetSplit
largeSplit = splitDataset 0.80 0.10 0.10

-- | Simple 80/20 train/test split (no validation)
-- Use for quick experiments or small projects
--
-- Pure Function: ✓
simpleTrainTestSplit :: [String] -> ([String], [String])
simpleTrainTestSplit items =
  let trainRatio = 0.8 :: Double
      trainSize = floor (fromIntegral (length items) * trainRatio)
  in (take trainSize items, drop trainSize items)

-- ============================================================================
-- STATISTICAL ANALYSIS
-- ============================================================================

-- | Compute dataset statistics
-- Useful for:
--   - Data quality assessment
--   - Model selection
--   - Reporting
--
-- Metrics:
--   - Total words: Dataset size
--   - Unique words: Vocabulary richness
--   - Avg word length: Text complexity
--   - Most common: Distribution analysis
--
-- Time Complexity: O(n log n) due to sorting
-- Pure Function: ✓
computeStats :: [String] -> DatasetStats
computeStats wordList =
  let total = length wordList
      unique = Set.size (Set.fromList wordList)
      avgLen = if total > 0
               then fromIntegral (sum (map length wordList)) / fromIntegral total
               else 0.0
      freqMap = buildFrequencyMap wordList
      common = take 10 $ sortByFrequency $ Map.toList freqMap
      
  in DatasetStats
       { datasetTotalWords = total
       , uniqueWords = unique
       , avgWordLength = avgLen
       , mostCommonWords = common
       }

-- | Build word frequency map
-- Core algorithm for statistical analysis
--
-- Algorithm: Fold with Map accumulation
--   Start with empty map
--   For each word: increment its count
--
-- Time Complexity: O(n log k) where k is unique words
-- Space Complexity: O(k)
-- Pure Function: ✓
buildFrequencyMap :: [String] -> Map.Map String Int
buildFrequencyMap = foldl' incrementCount Map.empty
  where
    incrementCount :: Map.Map String Int -> String -> Map.Map String Int
    incrementCount acc word = Map.insertWith (+) word 1 acc

-- | Sort words by frequency (descending)
-- Used for finding most common words
--
-- Time Complexity: O(n log n)
-- Pure Function: ✓
sortByFrequency :: [(String, Int)] -> [(String, Int)]
sortByFrequency = sortBy (flip $ comparing snd)

-- ============================================================================
-- PIPELINE COMPOSITION
-- ============================================================================

-- | Complete preprocessing pipeline
-- Composes all steps: metadata removal → cleaning → splitting
--
-- This is functional programming at its best:
--   - Function composition
--   - Pure transformations
--   - Type-safe pipeline
--
-- Example usage:
--   rawText <- readFile "shakespeare.txt"
--   let split = fullPipeline defaultConfig rawText
--   let model = trainModel (trainingData split)
--
-- Pure Function: ✓
fullPipeline :: PreprocessConfig -> String -> DatasetSplit
fullPipeline config rawText =
  let cleaned = removeGutenbergMetadata rawText
      processed = preprocessText config cleaned
      split = standardSplit processed
  in split

-- | Simplified pipeline (no validation set)
-- For quick experiments
--
-- Pure Function: ✓
simplePipeline :: PreprocessConfig -> String -> ([String], [String])
simplePipeline config rawText =
  let cleaned = removeGutenbergMetadata rawText
      processed = preprocessText config cleaned
  in simpleTrainTestSplit processed