{-|
Module      : ReportGenerator
Description : Simple report generation for N-gram text generator
Copyright   : (c) Your Team, 2024
License     : MIT

This module generates simple execution reports with inputs and outputs.
-}

module ReportGenerator
  ( GenerationSession(..)
  , generateSimpleReport
  , saveReport
  , formatTimestamp
  ) where

import Data.Time.Clock
import Data.Time.Format
import System.Directory (createDirectoryIfMissing)

-- ============================================================================
-- REPORT DATA TYPES
-- ============================================================================

-- | Session information for a text generation run
data GenerationSession = GenerationSession
  { sessionTimestamp    :: UTCTime
  , inputFilePath       :: FilePath
  , ngramSize          :: Int
  , seedWords          :: [String]
  , requestedWords     :: Int
  , generatedText      :: [String]
  } deriving (Show)

-- ============================================================================
-- REPORT GENERATION
-- ============================================================================

-- | Generate a simple report with inputs and outputs
generateSimpleReport :: GenerationSession -> String
generateSimpleReport session = unlines
  [ "╔═══════════════════════════════════════════════════════════════╗"
  , "║          N-GRAM TEXT GENERATOR - EXECUTION REPORT             ║"
  , "╚═══════════════════════════════════════════════════════════════╝"
  , ""
  , "Report Generated: " ++ formatTimestamp (sessionTimestamp session)
  , "═══════════════════════════════════════════════════════════════════"
  , ""
  , "INPUT PARAMETERS"
  , "───────────────────────────────────────────────────────────────────"
  , "• Data File: " ++ inputFilePath session
  , "• N-gram Size: " ++ show (ngramSize session) ++ " (" ++ getModelType (ngramSize session) ++ ")"
  , "• Seed Words: " ++ unwords (seedWords session)
  , "• Requested Words: " ++ show (requestedWords session)
  , ""
  , "OUTPUT"
  , "───────────────────────────────────────────────────────────────────"
  , "Generated Text:"
  , ""
  , wrapText 65 (unwords (generatedText session))
  , ""
  , "Statistics:"
  , "• Total Words Generated: " ++ show (length (generatedText session))
  , "• Unique Words: " ++ show (length $ removeDuplicates (generatedText session))
  , "• Average Word Length: " ++ formatDouble (averageLength (generatedText session)) ++ " characters"
  , ""
  , "═══════════════════════════════════════════════════════════════════"
  , "N-Gram Text Generator - Functional Programming Project"
  , "═══════════════════════════════════════════════════════════════════"
  ]

-- ============================================================================
-- FILE I/O OPERATIONS
-- ============================================================================

-- | Save report to outputs/reports folder
saveReport :: GenerationSession -> IO ()
saveReport session = do
  -- Create reports directory if it doesn't exist
  createDirectoryIfMissing True "outputs/reports"
  
  let report = generateSimpleReport session
  let filename = "report_" ++ formatTimestampFilename (sessionTimestamp session) ++ ".txt"
  let fullPath = "outputs/reports/" ++ filename
  
  writeFile fullPath report
  putStrLn $ "\nReport saved to: " ++ fullPath

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- | Format timestamp for display
formatTimestamp :: UTCTime -> String
formatTimestamp = formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S UTC"

-- | Format timestamp for filename (no special characters)
formatTimestampFilename :: UTCTime -> String
formatTimestampFilename = formatTime defaultTimeLocale "%Y%m%d_%H%M%S"

-- | Format double to 2 decimal places
formatDouble :: Double -> String
formatDouble x = show (fromIntegral (round (x * 100)) / 100 :: Double)

-- | Get model type name
getModelType :: Int -> String
getModelType 2 = "Bigram"
getModelType 3 = "Trigram"
getModelType 4 = "4-gram"
getModelType n = show n ++ "-gram"

-- | Wrap text to specified width
wrapText :: Int -> String -> String
wrapText width text = unlines $ go (words text) []
  where
    go [] current = [unwords (reverse current)]
    go (w:ws) current
      | null current = go ws [w]
      | length (unwords (reverse (w:current))) > width = 
          unwords (reverse current) : go ws [w]
      | otherwise = go ws (w:current)

-- | Remove duplicates
removeDuplicates :: Eq a => [a] -> [a]
removeDuplicates [] = []
removeDuplicates (x:xs) = x : removeDuplicates (filter (/= x) xs)

-- | Calculate average word length
averageLength :: [String] -> Double
averageLength [] = 0
averageLength words = 
  fromIntegral (sum $ map length words) / fromIntegral (length words)
