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
import DataTypes

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
  , "📥 INPUT PARAMETERS"
  , "───────────────────────────────────────────────────────────────────"
  , "• Data File: " ++ inputFilePath session
  , "• N-gram Size: " ++ show (ngramSize session) ++ " (" ++ getModelType (ngramSize session) ++ ")"
  , "• Seed Words: " ++ unwords (seedWords session)
  , "• Requested Words: " ++ show (requestedWords session)
  , ""
  , "📤 OUTPUT"
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
  putStrLn $ "\n✅ Report saved to: " ++ fullPath

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

generateHeader session = unlines
  [ "┌─────────────────────────────────────────────────────────────────┐"
  , "│                  N-GRAM TEXT GENERATOR REPORT                   │"
  , "│            Functional Programming Project - Haskell             │"
  , "└─────────────────────────────────────────────────────────────────┘"
  , ""
  , "Report Generated: " ++ formatTimestamp (sessionTimestamp session)
  , "Processing Time: " ++ show (processingTimeMs session) ++ " ms"
  , "═══════════════════════════════════════════════════════════════════"
  , ""
  ]

-- | Generate input parameters section
generateInputSection :: GenerationSession -> String
generateInputSection session = unlines
  [ "1. INPUT PARAMETERS"
  , "───────────────────────────────────────────────────────────────────"
  , ""
  , "📁 Data Source:"
  , "   File Path: " ++ inputFilePath session
  , ""
  , "⚙️  Preprocessing Configuration:"
  , "   • Remove Stop Words: " ++ show (removeStopWords $ preprocessingConfig session)
  , "   • Minimum Word Length: " ++ show (minWordLength $ preprocessingConfig session)
  , "   • Lowercase Conversion: " ++ show (lowercase $ preprocessingConfig session)
  , "   • Remove Punctuation: " ++ show (removePunctuation $ preprocessingConfig session)
  , ""
  , "🧠 Model Configuration:"
  , "   • N-gram Size: " ++ show (ngramSize $ modelConfiguration session)
  , "   • Model Type: " ++ getModelType (ngramSize $ modelConfiguration session)
  , "   • Minimum Frequency: " ++ show (minFrequency $ modelConfiguration session)
  , "   • Smoothing Enabled: " ++ show (smoothing $ modelConfiguration session)
  , ""
  , "🎯 Generation Parameters:"
  , "   • Seed Words: " ++ unwords (seedWords session)
  , "   • Requested Length: " ++ show (requestedWords session) ++ " words"
  , ""
  ]

-- | Generate data processing section
generateProcessingSection :: GenerationSession -> String
generateProcessingSection session = 
  let stats = datasetStatistics session
      split = splitInformation session
  in unlines
  [ "2. DATA PROCESSING & STATISTICS"
  , "───────────────────────────────────────────────────────────────────"
  , ""
  , "📊 Raw Dataset Statistics:"
  , "   • Total Words: " ++ formatNumber (datasetTotalWords stats)
  , "   • Unique Words (Vocabulary): " ++ formatNumber (uniqueWords stats)
  , "   • Average Word Length: " ++ formatDouble (avgWordLength stats) ++ " characters"
  , "   • Type-Token Ratio: " ++ formatDouble (calculateTTR stats)
  , ""
  , "📈 Top 10 Most Frequent Words:"
  , formatWordFrequencies (take 10 $ mostCommonWords stats)
  , ""
  , "✂️  Dataset Split (Pure Function):"
  , "   • Training Set: " ++ formatNumber (length $ trainingData split) ++ 
    " words (" ++ formatPercentage (trainingData split) (datasetTotalWords stats) ++ ")"
  , "   • Validation Set: " ++ formatNumber (length $ validationData split) ++ 
    " words (" ++ formatPercentage (validationData split) (datasetTotalWords stats) ++ ")"
  , "   • Testing Set: " ++ formatNumber (length $ testingData split) ++ 
    " words (" ++ formatPercentage (testingData split) (datasetTotalWords stats) ++ ")"
  , ""
  , "✅ FP Principle: Immutable data transformation pipeline"
  , "   Raw Text → Cleaned → Tokenized → Split (all pure functions)"
  , ""
  ]

-- | Generate model training section
generateModelSection :: GenerationSession -> String
generateModelSection session = 
  let stats = modelStatistics session
      perplexity = evaluationPerplexity session
  in unlines
  [ "3. MODEL TRAINING & EVALUATION"
  , "───────────────────────────────────────────────────────────────────"
  , ""
  , "🏗️  Model Architecture:"
  , "   • Unique N-grams Learned: " ++ formatNumber (totalNGrams stats)
  , "   • Vocabulary Size: " ++ formatNumber (vocabularySize stats)
  , "   • Training Corpus Size: " ++ formatNumber (corpusSize stats)
  , "   • Model Coverage: " ++ formatDouble (calculateCoverage stats) ++ "%"
  , ""
  , "📐 Mathematical Foundation:"
  , "   P(w|context) = Count(context, w) / Count(context)"
  , "   where context = " ++ show (ngramSize $ modelConfiguration session) ++ " previous words"
  , ""
  , case perplexity of
      Nothing -> "⚠️  Model Evaluation: Not performed"
      Just p  -> unlines
        [ "🎯 Model Performance (Perplexity):"
        , "   • Perplexity Score: " ++ formatDouble p
        , "   • Interpretation: " ++ interpretPerplexity p
        , "   • Lower is better (perfect = 1.0, random = vocabulary size)"
        ]
  , ""
  , "✅ FP Principle: Pure function builds immutable model"
  , "   buildNGramModel :: ModelConfig -> [String] -> NGramModel"
  , ""
  ]

-- | Generate output section
generateOutputSection :: GenerationSession -> String
generateOutputSection session = 
  let generated = generatedText session
      seed = seedWords session
  in unlines
  [ "4. GENERATED OUTPUT"
  , "───────────────────────────────────────────────────────────────────"
  , ""
  , "📝 Input Seed:"
  , "   " ++ unwords seed
  , ""
  , "🎨 Generated Text (" ++ show (length generated) ++ " words):"
  , "   ┌─────────────────────────────────────────────────────────────┐"
  , formatTextBlock (unwords generated)
  , "   └─────────────────────────────────────────────────────────────┘"
  , ""
  , "📊 Output Statistics:"
  , "   • Total Words Generated: " ++ show (length generated)
  , "   • Unique Words Used: " ++ show (length $ removeDuplicates generated)
  , "   • Average Word Length: " ++ formatDouble (averageLength generated) ++ " characters"
  , "   • Longest Word: " ++ findLongestWord generated
  , ""
  , "✅ FP Principle: Recursive text generation with tail call optimization"
  , "   generateLoop :: NGramModel -> Int -> [String] -> IO [String]"
  , ""
  ]

-- | Generate functional programming techniques section
generateFPSection :: GenerationSession -> String
generateFPSection session = unlines
  [ "5. FUNCTIONAL PROGRAMMING TECHNIQUES DEMONSTRATED"
  , "───────────────────────────────────────────────────────────────────"
  , ""
  , "✅ 1. PURE FUNCTIONS"
  , "   All core logic has no side effects:"
  , "   • buildNGramModel :: ModelConfig -> [String] -> NGramModel"
  , "   • preprocessText :: PreprocessConfig -> String -> [String]"
  , "   • calculatePerplexity :: NGramModel -> [String] -> Double"
  , "   Benefit: Predictable, testable, composable code"
  , ""
  , "✅ 2. IMMUTABILITY"
  , "   All data structures are immutable:"
  , "   • NGramModel = Map.Map NGram (Map.Map Token Int)"
  , "   • Once created, model never changes"
  , "   Benefit: Thread-safe, no race conditions, easier debugging"
  , ""
  , "✅ 3. RECURSION"
  , "   Text generation uses tail recursion instead of loops:"
  , "   • generateLoop model remaining context result"
  , "   • No mutable loop counters"
  , "   Benefit: Stack-safe, elegant mathematical expression"
  , ""
  , "✅ 4. HIGHER-ORDER FUNCTIONS"
  , "   Extensive use of map, fold, filter:"
  , "   • foldl' (insertNGram n) Map.empty ngrams"
  , "   • map (\\word -> processWord config word) tokens"
  , "   Benefit: Concise data transformations, code reuse"
  , ""
  , "✅ 5. ALGEBRAIC DATA TYPES (ADT)"
  , "   Custom types model domain exactly:"
  , "   • data ModelConfig = ModelConfig { ngramSize :: Int, ... }"
  , "   • data DatasetSplit = DatasetSplit { trainingData :: [String], ... }"
  , "   Benefit: Self-documenting, compiler-enforced correctness"
  , ""
  , "✅ 6. TYPE SAFETY"
  , "   Strong typing prevents runtime errors:"
  , "   • type NGram = [String]  (not just any list)"
  , "   • type NGramModel = Map.Map NGram (Map.Map Token Int)"
  , "   Benefit: Catch errors at compile time, safe refactoring"
  , ""
  , "✅ 7. LAZY EVALUATION"
  , "   Process large files efficiently:"
  , "   • words <$> readFile \"dataset.txt\""
  , "   • Only compute what's needed"
  , "   Benefit: Handle gigabyte files with megabytes of RAM"
  , ""
  , "✅ 8. MONADIC I/O"
  , "   Clean separation of pure and impure code:"
  , "   • main :: IO ()"
  , "   • Pure core, impure shell architecture"
  , "   Benefit: Side effects are explicit and controlled"
  , ""
  ]

-- | Generate conclusion section
generateConclusionSection :: GenerationSession -> String
generateConclusionSection session = unlines
  [ "6. CONCLUSION & INSIGHTS"
  , "───────────────────────────────────────────────────────────────────"
  , ""
  , "🎯 Session Summary:"
  , "   • Successfully processed " ++ formatNumber (datasetTotalWords $ datasetStatistics session) ++ " words"
  , "   • Trained " ++ getModelType (ngramSize $ modelConfiguration session) ++ " with " ++ 
      formatNumber (totalNGrams $ modelStatistics session) ++ " unique patterns"
  , "   • Generated coherent text from seed: \"" ++ unwords (seedWords session) ++ "\""
  , "   • Total execution time: " ++ show (processingTimeMs session) ++ " ms"
  , ""
  , "💡 Functional Programming Benefits Observed:"
  , "   ✓ Code correctness guaranteed by type system"
  , "   ✓ Easy to reason about data flow (no hidden state)"
  , "   ✓ Testable components (pure functions)"
  , "   ✓ Efficient memory usage (lazy evaluation)"
  , "   ✓ Concurrent-ready (immutable data structures)"
  , ""
  , "📚 Real-World Applications:"
  , "   • Autocomplete systems (Google Search, smartphones)"
  , "   • Code completion (GitHub Copilot, VS Code)"
  , "   • Chatbots and virtual assistants"
  , "   • Creative writing assistance"
  , ""
  , "═══════════════════════════════════════════════════════════════════"
  , "Report generated by N-Gram Text Generator"
  , "Functional Programming Project - Haskell"
  , "Group Members: [Your Team Names]"
  , "═══════════════════════════════════════════════════════════════════"
  , ""
  ]

-- ============================================================================
-- FILE I/O OPERATIONS
-- ============================================================================

-- | Save report to file
saveReport :: FilePath -> SessionReport -> IO ()
saveReport filepath report = do
  -- Create reports directory if it doesn't exist
  createDirectoryIfMissing True "outputs/reports"
  
  let fullPath = "outputs/reports/" ++ filepath
  writeFile fullPath (fullReport report)
  putStrLn $ "✅ Report saved to: " ++ fullPath

-- | Generate complete report and save to file
generateCompleteReport :: GenerationSession -> IO ()
generateCompleteReport session = do
  let report = generateReport session
  let filename = "report_" ++ formatTimestampFilename (sessionTimestamp session) ++ ".txt"
  saveReport filename report
  putStrLn "\n📄 Report Summary:"
  putStrLn $ "   Location: outputs/reports/" ++ filename
  putStrLn $ "   Size: " ++ show (length $ fullReport report) ++ " characters"
  putStrLn "   Status: Successfully generated"

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- | Format timestamp for display
formatTimestamp :: UTCTime -> String
formatTimestamp = formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S UTC"

-- | Format timestamp for filename (no special characters)
formatTimestampFilename :: UTCTime -> String
formatTimestampFilename = formatTime defaultTimeLocale "%Y%m%d_%H%M%S"

-- | Format number with commas
formatNumber :: Int -> String
formatNumber n
  | n < 1000  = show n
  | n < 1000000 = show (n `div` 1000) ++ "," ++ pad3 (n `mod` 1000)
  | otherwise = show (n `div` 1000000) ++ "," ++ 
                pad3 ((n `mod` 1000000) `div` 1000) ++ "," ++ 
                pad3 (n `mod` 1000)
  where
    pad3 x = replicate (3 - length (show x)) '0' ++ show x

-- | Format double to 2 decimal places
formatDouble :: Double -> String
formatDouble x = show (fromIntegral (round (x * 100)) / 100 :: Double)

-- | Format word frequencies
formatWordFrequencies :: [(String, Int)] -> String
formatWordFrequencies freqs = 
  unlines $ map (\(i, (w, c)) -> 
    "   " ++ show i ++ ". \"" ++ w ++ "\" → " ++ formatNumber c ++ " occurrences") 
    (zip [1..] freqs)

-- | Calculate Type-Token Ratio (vocabulary diversity)
calculateTTR :: DatasetStats -> Double
calculateTTR stats = 
  fromIntegral (uniqueWords stats) / fromIntegral (datasetTotalWords stats)

-- | Calculate model coverage
calculateCoverage :: ModelStats -> Double
calculateCoverage stats = 
  (fromIntegral (totalNGrams stats) / fromIntegral (vocabularySize stats)) * 100

-- | Get model type name
getModelType :: Int -> String
getModelType 2 = "Bigram Model"
getModelType 3 = "Trigram Model"
getModelType 4 = "4-gram Model"
getModelType n = show n ++ "-gram Model"

-- | Format percentage
formatPercentage :: [a] -> Int -> String
formatPercentage subset total = 
  formatDouble (fromIntegral (length subset) / fromIntegral total * 100) ++ "%"

-- | Format text block with proper wrapping
formatTextBlock :: String -> String
formatTextBlock text = 
  let maxWidth = 60
      wrappedLines = wrapText maxWidth text
  in unlines $ map (\line -> "   │ " ++ padRight maxWidth line ++ " │") wrappedLines

-- | Wrap text to specified width
wrapText :: Int -> String -> [String]
wrapText width text = go (words text) []
  where
    go [] current = [unwords (reverse current)]
    go (w:ws) current
      | null current = go ws [w]
      | length (unwords (reverse (w:current))) > width = 
          unwords (reverse current) : go ws [w]
      | otherwise = go ws (w:current)

-- | Pad string to right
padRight :: Int -> String -> String
padRight n s = s ++ replicate (n - length s) ' '

-- | Remove duplicates
removeDuplicates :: Eq a => [a] -> [a]
removeDuplicates [] = []
removeDuplicates (x:xs) = x : removeDuplicates (filter (/= x) xs)

-- | Calculate average word length
averageLength :: [String] -> Double
averageLength [] = 0
averageLength words = 
  fromIntegral (sum $ map length words) / fromIntegral (length words)

-- | Find longest word
findLongestWord :: [String] -> String
findLongestWord [] = "N/A"
findLongestWord words = 
  foldr (\w acc -> if length w > length acc then w else acc) "" words

-- | Interpret perplexity score
interpretPerplexity :: Double -> String
interpretPerplexity p
  | p < 50    = "Excellent - Model has strong predictive power"
  | p < 100   = "Very Good - Model performs well on test data"
  | p < 200   = "Good - Acceptable performance for most applications"
  | p < 500   = "Fair - Model may need more training data"
  | otherwise = "Poor - Consider larger dataset or different n-gram size"
