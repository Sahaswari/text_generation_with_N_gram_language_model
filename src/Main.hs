module Main where

import Control.Monad (when)
import Data.Time.Clock (UTCTime, getCurrentTime)
import DataTypes
import DataPreprocessing
import IOHandler
import Processing
import qualified ReportGenerator as Report

main :: IO ()
main = do
  startTime <- getCurrentTime
  putStrLn "=========================================="
  putStrLn "  N-Gram Text Generator"
  putStrLn "  Functional Programming Project"
  putStrLn "=========================================="
  putStrLn "Enter path to raw text file [data/dataset.txt]:"
  pathInput <- getLine
  let inputFile = if null pathInput then "data/dataset.txt" else pathInput
  rawTextResult <- readRawText inputFile
  case rawTextResult of
    Left err -> putStrLn $ "Error: " ++ err
    Right rawText -> do
      prepConfig <- promptPreprocessConfig
      let cleaned = removeGutenbergMetadata rawText
      let processedWords = preprocessText prepConfig cleaned
      let dataStats = computeStats processedWords
      displayPreprocessStats dataStats
      split <- promptSplit processedWords
      continueWithTraining inputFile split startTime

promptPreprocessConfig :: IO PreprocessConfig
promptPreprocessConfig = do
  putStrLn "\n=== Preprocessing Configuration ==="
  putStrLn "Remove stop words? (y/n) [n]:"
  stopWordsChoice <- getLine
  putStrLn "Minimum word length? [1]:"
  minLenInput <- getLine
  let minLen = if null minLenInput then 1 else read minLenInput :: Int
  let config = PreprocessConfig
        { removeStopWords = stopWordsChoice == "y"
        , minWordLength = minLen
        , lowercase = True
        , removePunctuation = False
        }
  return config

promptSplit :: [String] -> IO DatasetSplit
promptSplit processedWords = do
  putStrLn "\nChoose split strategy:"
  putStrLn "1. Standard (70/15/15)"
  putStrLn "2. Large dataset (80/10/10)"
  putStrLn "3. Simple (80/20, no validation)"
  choice <- getLine
  case choice of
    "3" -> do
      let (trainWords, testWords) = simpleTrainTestSplit processedWords
      putStrLn "\nSplit complete:"
      putStrLn $ "   Training: " ++ show (length trainWords) ++ " words"
      putStrLn $ "   Testing: " ++ show (length testWords) ++ " words"
      let split = DatasetSplit
            { trainingData = trainWords
            , validationData = []
            , testingData = testWords
            }
      return split
    "2" -> do
      let split = largeSplit processedWords
      displaySplitInfo split
      return split
    _ -> do
      let split = standardSplit processedWords
      displaySplitInfo split
      return split

promptNGramSize :: IO Int
promptNGramSize = do
  putStrLn "\n=== Model Configuration ==="
  putStrLn "Choose n-gram size:"
  putStrLn "2 - Bigram"
  putStrLn "3 - Trigram (recommended)"
  putStrLn "4 - 4-gram"
  choice <- getLine
  return $ case choice of
    "2" -> 2
    "4" -> 4
    _    -> 3

continueWithTraining :: FilePath -> DatasetSplit -> UTCTime -> IO ()
continueWithTraining inputFile split startTime = do
  n <- promptNGramSize
  let modelConfig = ModelConfig
        { ngramSize = n
        , minFrequency = 1
        , smoothing = False
        }
  let trainWords = trainingData split
  let testWords = testingData split

  putStrLn $ "\nTraining " ++ show n ++ "-gram model..."
  let model = buildNGramModel modelConfig trainWords
  let modelStats = getModelStats model trainWords
  putStrLn "Training complete!"
  displayModelStats modelStats

  when (not $ null testWords) $ do
    putStrLn "Evaluating model on test data..."
    let perplexity = calculatePerplexity model testWords
    displayEvaluationResults perplexity

  runInteractiveMode inputFile split startTime model modelConfig modelStats

runInteractiveMode :: FilePath -> DatasetSplit -> UTCTime -> NGramModel -> ModelConfig -> ModelStats -> IO ()
runInteractiveMode inputFile split startTime model modelConfig modelStats = do
  showMenu
  choice <- getLine
  let testWords = testingData split
  case choice of
    "1" -> do
      putStrLn "\nEnter seed words (space-separated):"
      putStrLn "(Example: to be or)"
      seedInput <- getLine
      let seedTokens = words seedInput
      if null seedTokens
        then do
          putStrLn "Please provide at least one seed word"
          runInteractiveMode inputFile split startTime model modelConfig modelStats
        else do
          putStrLn "How many words to generate? [20]:"
          numWordsInput <- getLine
          let numWords = if null numWordsInput then 20 else read numWordsInput :: Int
          generated <- generateText model numWords seedTokens
          displayGeneratedText generated

          putStrLn "Save generated text to outputs/generated.txt? (y/n) [n]:"
          saveChoice <- getLine
          when (saveChoice == "y") $ saveGeneratedText "outputs/generated.txt" generated

          putStrLn "Generate execution report? (y/n) [n]:"
          reportChoice <- getLine
          when (reportChoice == "y") $ do
            timestamp <- getCurrentTime
            let session = Report.GenerationSession
                  { Report.sessionTimestamp = timestamp
                  , Report.inputFilePath = inputFile
                  , Report.ngramSize = ngramSize modelConfig
                  , Report.seedWords = seedTokens
                  , Report.requestedWords = numWords
                  , Report.generatedText = generated
                  }
            Report.saveReport session

          runInteractiveMode inputFile split startTime model modelConfig modelStats

    "2" -> do
      putStrLn "\nEnter context words (space-separated):"
      contextInput <- getLine
      let contextTokens = words contextInput
      let predictions = topPredictions model contextTokens 10
      putStrLn "\n=== Top Predictions ==="
      if null predictions
        then putStrLn "Context not found in training data"
        else mapM_ (\(word, prob) ->
              putStrLn $ "  " ++ word ++ ": " ++ show (round (prob * 100)) ++ "%") predictions
      putStrLn "========================\n"
      runInteractiveMode inputFile split startTime model modelConfig modelStats

    "3" -> do
      displayModelStats modelStats
      runInteractiveMode inputFile split startTime model modelConfig modelStats

    "4" -> do
      if null testWords
        then putStrLn "No test data available"
        else do
          putStrLn "\nEvaluating model..."
          let perplexity = calculatePerplexity model testWords
          displayEvaluationResults perplexity
      runInteractiveMode inputFile split startTime model modelConfig modelStats

    "5" -> do
      putStrLn "\nThank you for using N-Gram Text Generator!"
      return ()

    _ -> do
      putStrLn "Invalid choice. Please try again."
      runInteractiveMode inputFile split startTime model modelConfig modelStats
