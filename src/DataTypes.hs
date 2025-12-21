{-|
Module      : DataTypes
Description : Core type definitions for N-gram text generator
Copyright   : (c) Your Team, 2024
License     : MIT
Maintainer  : your-email@example.com

This module defines all custom data types used throughout the application.
It serves as the single source of truth for type definitions, ensuring
type safety and making refactoring easier.

Design Principle: Type-Driven Development
- Define types first, implementation follows
- Use type system to prevent bugs at compile time
- Make illegal states unrepresentable
-}

module DataTypes 
  ( NGram
  , Token
  , NGramModel
  , ModelConfig(..)
  , PreprocessConfig(..)
  , DatasetSplit(..)
  , ModelStats(..)
  , DatasetStats(..)
  , defaultBigramConfig
  , defaultTrigramConfig
  , defaultPreprocessConfig
  ) where

import qualified Data.Map.Strict as Map

-- ============================================================================
-- N-GRAM MODEL TYPES
-- ============================================================================

-- | N-gram context (sequence of words)
-- Example: ["to", "be"] for bigram
-- Example: ["to", "be", "or"] for trigram
type NGram = [String]

-- | Single word token
type Token = String

-- | Core n-gram model structure
-- Maps context to possible next words with their frequencies
-- 
-- Example:
--   Map ["to", "be"] (Map "or" 5, Map "that" 3)
--   Means: After "to be", we saw "or" 5 times and "that" 3 times
--
-- Why Map: O(log n) lookup, immutable, persistent data structure
type NGramModel = Map.Map NGram (Map.Map Token Int)

-- ============================================================================
-- CONFIGURATION TYPES
-- ============================================================================

-- | Configuration for n-gram model training
-- This allows easy experimentation with different model parameters
data ModelConfig = ModelConfig
  { ngramSize     :: Int    -- ^ Size of context (2=bigram, 3=trigram, etc.)
  , minFrequency  :: Int    -- ^ Minimum frequency threshold (pruning)
  , smoothing     :: Bool   -- ^ Apply smoothing for unseen n-grams
  } deriving (Show, Eq)

-- | Configuration for text preprocessing
-- Allows flexible data cleaning strategies
data PreprocessConfig = PreprocessConfig
  { removeStopWords   :: Bool   -- ^ Filter common words (the, a, is)
  , minWordLength     :: Int    -- ^ Minimum length to keep
  , lowercase         :: Bool   -- ^ Convert to lowercase
  , removePunctuation :: Bool   -- ^ Strip punctuation
  } deriving (Show, Eq)

-- ============================================================================
-- DATASET TYPES
-- ============================================================================

-- | Dataset split for machine learning
-- Standard practice: separate train/validation/test sets
data DatasetSplit = DatasetSplit
  { trainingData   :: [String]    -- ^ 70% - Model training
  , validationData :: [String]    -- ^ 15% - Hyperparameter tuning
  , testingData    :: [String]    -- ^ 15% - Final evaluation
  } deriving (Show)

-- ============================================================================
-- STATISTICS TYPES
-- ============================================================================

-- | Model performance statistics
-- Useful for reporting and comparing models
data ModelStats = ModelStats
  { totalNGrams    :: Int    -- ^ Unique n-gram contexts learned
  , vocabularySize :: Int    -- ^ Vocabulary size
  , corpusSize     :: Int    -- ^ Total training words
  } deriving (Show)

-- | Dataset statistics for data quality analysis
data DatasetStats = DatasetStats
  { datasetTotalWords :: Int              -- ^ Total word count
  , uniqueWords       :: Int              -- ^ Unique vocabulary
  , avgWordLength     :: Double           -- ^ Average word length
  , mostCommonWords   :: [(String, Int)]  -- ^ Top frequent words
  } deriving (Show)

-- ============================================================================
-- DEFAULT CONFIGURATIONS
-- ============================================================================

-- | Standard bigram model configuration
-- Use case: Fast training, good for small datasets
defaultBigramConfig :: ModelConfig
defaultBigramConfig = ModelConfig
  { ngramSize    = 2
  , minFrequency = 1
  , smoothing    = False
  }

-- | Standard trigram model configuration (RECOMMENDED)
-- Use case: Best balance of quality and performance
defaultTrigramConfig :: ModelConfig
defaultTrigramConfig = ModelConfig
  { ngramSize    = 3
  , minFrequency = 1
  , smoothing    = False
  }

-- | Default preprocessing configuration
-- Conservative settings that work for most cases
defaultPreprocessConfig :: PreprocessConfig
defaultPreprocessConfig = PreprocessConfig
  { removeStopWords   = False
  , minWordLength     = 1
  , lowercase         = True
  , removePunctuation = False
  }