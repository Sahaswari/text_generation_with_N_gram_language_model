-- IOHandler.hs (updated version)

module IOHandler
  ( readRawText
  , displayPreprocessStats
  , displaySplitInfo
  , saveGeneratedText
  , displayModelStats
  , showMenu
  , displayGeneratedText
  , displayEvaluationResults
  ) where

import System.IO
import Control.Exception (catch, IOException)
import qualified Data.Map.Strict as Map
import DataTypes
import Utils
import DataPreprocessing

-- | Read raw text file (handles errors)
readRawText :: FilePath -> IO (Either String String)
readRawText filePath = do
  putStrLn $ "Reading file: " ++ filePath
  result <- catch (Right <$> readFile filePath) handleError
  case result of
    Left err -> return $ Left err
    Right content -> do
      putStrLn $ "Success: read " ++ show (length content) ++ " characters"
      return $ Right content
  where
    handleError :: IOException -> IO (Either String String)
    handleError e = return $ Left $ "Error reading file: " ++ show e

-- | Display preprocessing statistics
displayPreprocessStats :: DatasetStats -> IO ()
displayPreprocessStats stats = do
  putStrLn "\n=== Preprocessing Statistics ==="
  putStrLn $ "Total words: " ++ show (datasetTotalWords stats)
  putStrLn $ "Unique words: " ++ show (uniqueWords stats)
  putStrLn $ "Average word length: " ++ show (avgWordLength stats)
  putStrLn "\nTop 10 most common words:"
  mapM_ (\(word, count) -> putStrLn $ "  " ++ word ++ ":" ++ show count) 
        (mostCommonWords stats)
  putStrLn "================================\n"

-- | Display dataset split information
displaySplitInfo :: DatasetSplit -> IO ()
displaySplitInfo split = do
  putStrLn "\n=== Dataset Split ==="
  putStrLn $ "Training data: " ++ show (length $ trainingData split) ++ " words"
  putStrLn $ "Validation data: " ++ show (length $ validationData split) ++ " words"
  putStrLn $ "Testing data: " ++ show (length $ testingData split) ++ " words"
  let total = length (trainingData split) + 
              length (validationData split) + 
              length (testingData split)
  putStrLn $ "Total: " ++ show total ++ " words"
  putStrLn "=====================\n"

-- | Save generated text to file
saveGeneratedText :: FilePath -> [String] -> IO ()
saveGeneratedText filePath words = do
  writeFile filePath (unwords words)
  putStrLn $ "Generated text saved to: " ++ filePath

-- | Display model statistics
displayModelStats :: ModelStats -> IO ()
displayModelStats stats = do
  putStrLn "\n=== Model Statistics ==="
  putStrLn $ "Total unique n-grams: " ++ show (totalNGrams stats)
  putStrLn $ "Vocabulary size: " ++ show (DataTypes.vocabularySize stats)
  putStrLn $ "Training corpus size: " ++ show (corpusSize stats) ++ " words"
  putStrLn "========================\n"

-- | Interactive menu
showMenu :: IO ()
showMenu = do
  putStrLn "\n=== N-Gram Text Generator ==="
  putStrLn "1. Generate text from seed"
  putStrLn "2. Show top predictions for context"
  putStrLn "3. View model statistics"
  putStrLn "4. Evaluate on test data"
  putStrLn "5. Exit"
  putStr "Choose an option: "
  hFlush stdout

-- | Display generated text
displayGeneratedText :: [String] -> IO ()
displayGeneratedText words = do
  putStrLn "\n=== Generated Text ==="
  putStrLn $ unwords words
  putStrLn "======================\n"

-- | Display evaluation results
displayEvaluationResults :: Double -> IO ()
displayEvaluationResults perplexity = do
  putStrLn "\n=== Model Evaluation ==="
  putStrLn $ "Perplexity: " ++ show perplexity
  putStrLn $ "Quality: " ++ interpretPerplexity perplexity
  putStrLn "========================\n"
  where
    interpretPerplexity p
      | p < 50    = "Excellent! 🌟"
      | p < 100   = "Very Good!"
      | p < 200   = "Good 👍"
      | p < 400   = "Acceptable"
      | otherwise = "Needs Improvement"