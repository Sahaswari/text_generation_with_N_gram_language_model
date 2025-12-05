{-|
Module      : Utils
Description : Shared utility functions
Copyright   : (c) Your Team, 2024
License     : MIT

This module provides common utility functions used across the application.
All functions here are pure (no side effects) and reusable.

Design Principle: DRY (Don't Repeat Yourself)
- Centralize common operations
- Keep functions small and focused
- Maintain referential transparency
-}

module Utils
  ( cleanText
  , addSentenceMarkers
  , ngramsOf
  , weightedRandomSelect
  , topN
  , countUniqueNGrams
  , vocabularySize
  , showFrequencies
  , isPrefixOf
  , findSubstring
  ) where

import Data.Char (toLower, isAlphaNum, isSpace)
import Data.List (sortBy)
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import System.Random (randomRIO)

-- ============================================================================
-- TEXT PROCESSING UTILITIES
-- ============================================================================

-- | Clean and tokenize text into words
-- Converts to lowercase, removes punctuation, splits on whitespace
--
-- Examples:
--   cleanText "Hello, World!" → ["hello", "world"]
--   cleanText "The cat sat."  → ["the", "cat", "sat"]
--
-- Why this approach:
--   - Simple and efficient
--   - Handles most common cases
--   - Preserves word boundaries
cleanText :: String -> [String]
cleanText text = 
  let cleaned = map toLower $ filter isValidChar text
  in filter (not . null) $ words cleaned
  where
    -- Keep letters, numbers, and spaces only
    isValidChar c = isAlphaNum c || isSpace c

-- | Add sentence boundary markers
-- Helps model learn sentence start/end patterns
--
-- Example: ["hello", "world"] → ["<START>", "hello", "world", "<END>"]
--
-- Why: Models can learn sentence structure
addSentenceMarkers :: [String] -> [String]
addSentenceMarkers ws = ["<START>"] ++ ws ++ ["<END>"]

-- | Create sliding n-grams from word list
-- Core algorithm for n-gram extraction
--
-- Examples:
--   ngramsOf 2 ["a","b","c","d"] → [["a","b"], ["b","c"], ["c","d"]]
--   ngramsOf 3 ["a","b","c","d"] → [["a","b","c"], ["b","c","d"]]
--
-- Time Complexity: O(n) where n is length of input
-- Space Complexity: O(n * k) where k is n-gram size
ngramsOf :: Int -> [String] -> [[String]]
ngramsOf n wordList
  | length wordList < n = []
  | otherwise = take n wordList : ngramsOf n (tail wordList)

-- ============================================================================
-- PROBABILISTIC SELECTION
-- ============================================================================

-- | Weighted random selection from frequency map
-- Used for probabilistic text generation
--
-- Algorithm: Roulette wheel selection
--   1. Calculate total frequency
--   2. Generate random number in [1, total]
--   3. Find word at that cumulative position
--
-- Example:
--   Input: Map {"cat" → 3, "dog" → 1}
--   Total: 4
--   Random 1,2,3 → "cat", Random 4 → "dog"
--   So "cat" has 75% chance, "dog" has 25% chance
--
-- Time Complexity: O(n) where n is vocabulary size
weightedRandomSelect :: Map.Map String Int -> IO (Maybe String)
weightedRandomSelect wordFreqs
  | Map.null wordFreqs = return Nothing
  | otherwise = do
      let totalCount = sum $ Map.elems wordFreqs
      randNum <- randomRIO (1, totalCount)
      return $ Just $ selectAtPosition randNum $ Map.toList wordFreqs
  where
    -- Helper: Walk through list until cumulative sum exceeds random number
    selectAtPosition :: Int -> [(String, Int)] -> String
    selectAtPosition _ [] = error "Empty frequency map (should not happen)"
    selectAtPosition n ((word, count):rest)
      | n <= count = word  -- Found the word at this position
      | otherwise  = selectAtPosition (n - count) rest

-- ============================================================================
-- SORTING AND RANKING
-- ============================================================================

-- | Get top N most frequent items from frequency map
-- Useful for showing most common words or predictions
--
-- Example: topN 3 (Map {"a"→10, "b"→5, "c"→8}) → [("a",10), ("c",8), ("b",5)]
--
-- Time Complexity: O(n log n) for sorting
topN :: Int -> Map.Map String Int -> [(String, Int)]
topN n freqMap = 
  take n $ sortBy (flip $ comparing snd) $ Map.toList freqMap

-- ============================================================================
-- MODEL INSPECTION
-- ============================================================================

-- | Count unique n-gram contexts in model
-- Metric: Larger = more patterns learned
countUniqueNGrams :: Map.Map [String] (Map.Map String Int) -> Int
countUniqueNGrams = Map.size

-- | Calculate total vocabulary size (all possible next words)
-- Metric: Larger = more diverse vocabulary
vocabularySize :: Map.Map [String] (Map.Map String Int) -> Int
vocabularySize model = 
  length $ Map.keys $ Map.unions $ Map.elems model

-- ============================================================================
-- DISPLAY UTILITIES
-- ============================================================================

-- | Format frequency map for display
-- Shows top 10 items with counts
showFrequencies :: Map.Map String Int -> String
showFrequencies freqMap = 
  unlines $ map formatItem $ topN 10 freqMap
  where
    formatItem (word, count) = "  " ++ word ++ ": " ++ show count

-- ============================================================================
-- STRING MATCHING UTILITIES
-- ============================================================================

-- | Check if one list is prefix of another
-- Used for substring matching in preprocessing
--
-- Examples:
--   isPrefixOf "abc" "abcdef" → True
--   isPrefixOf "xyz" "abcdef" → False
--
-- Time Complexity: O(min(m,n)) where m,n are list lengths
isPrefixOf :: Eq a => [a] -> [a] -> Bool
isPrefixOf [] _ = True
isPrefixOf _ [] = False
isPrefixOf (x:xs) (y:ys) = x == y && isPrefixOf xs ys

-- | Find first occurrence of substring in string
-- Returns index if found, Nothing otherwise
--
-- Time Complexity: O(n*m) naive string matching
-- Note: Good enough for our use case (removing Gutenberg headers)
findSubstring :: String -> String -> Maybe Int
findSubstring needle haystack = go 0 haystack
  where
    go _ [] = Nothing
    go idx str
      | needle `isPrefixOf` str = Just idx
      | otherwise = go (idx + 1) (tail str)