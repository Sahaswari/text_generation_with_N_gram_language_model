-- Main.hs (Complete updated version with Report Generation)

module Main where

import System.Environment (getArgs)
import System.IO
import Control.Monad (when)
import qualified Data.Map.Strict as Map
import Data.Time.Clock (getCurrentTime, diffUTCTime)
import DataTypes
import Processing
import IOHandler
import Utils
import DataPreprocessing
import ReportGenerator

main :: IO ()
main = do
  startTime <- getCurrentTime
  
  putStrLn "=========================================="
  putStrLn "  N-Gram Text Generator"
  putStrLn "  Functional Programming Project"
  putStrLn "  Pure Haskell Data Processing Pipeline"
  putStrLn "  📄 Report Generation Enabled"
  putStrLn "=========================================="
  
  -- Step 1: Read raw text file
  putStrLn "\nEnter path to raw text file:"
  putStrLn "(Example: data/dataset.txt)"
  filePath <- getLine
  
  rawTextResult <- readRawText filePath
  
  case rawTextResult of
    Left err -> putStrLn $ "❌ Error: " ++ err
    Right rawText -> do
      
      -- Step 2: Configure preprocessing
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
      
      -- Step 3: Preprocess and split data (PURE FUNCTIONS!)
      putStrLn "\n🔄 Preprocessing text..."
      putStrLn "   - Removing metadata"
      putStrLn "   - Cleaning text"
      putStrLn "   - Tokenizing"
      putStrLn "   - Splitting into train/validation/test"
      
      let cleaned = removeGutenbergMetadata rawText
      let processedWords = preprocessText config cleaned
      let stats = computeStats processedWords
      
      -- Display preprocessing statistics
      displayPreprocessStats stats
      
      -- Step 4: Split dataset
      putStrLn "Choose split strategy:"
      putStrLn "1. Standard (70% train, 15% validation, 15% test)"
      putStrLn "2. Large dataset (80% train, 10% validation, 10% test)"
      putStrLn "3. Simple (80% train, 20% test, no validation)"
      splitChoice <- getLine
      
      case splitChoice of
        "3" -> do
          -- Simple split
          let (trainWords, testWords) = simpleTrainTestSplit processedWords
          putStrLn $ "\n✅ Split complete:"
          putStrLn $ "   Training: " ++ show (length trainWords) ++ " words"
          putStrLn $ "   Testing: " ++ show (length testWords) ++ " words"
          
          -- Continue with training
          continueWithTraining trainWords testWords []
        
        "2" -> do
          -- Large split
          let split = largeSplit processedWords
          displaySplitInfo split
          continueWithTraining 
            (trainingData split) 
            (testingData split) 
            (validationData split)
        
        _ -> do
          -- Standard split (default)
          lefilePath
            config
            stats
            split
            startTime
            (trainingData split) 
            (testingData split) 
            (validationData split)

-- | Continue with model training after data preparation
continueWithTraining :: FilePath -> PreprocessConfig -> DatasetStats -> DatasetSplit 
                     -> UTCTime ->Data split)

-- | Continue with model training after data preparation
continueWithTraining :: [String] -> [String] -> [String] -> IO ()
continueWithTraining trainWords testWords valWords = do
  
  -- Step 5: Choose n-gram model
  putStrLn "\n=== Model Configuration ==="
  putStrLn "Choose n-gram size:"
  putStrLn "2 - Bigram (fast, less coherent)"
  putStrLn "3 - Trigram (recommended, good balance)"
  putStrLn "4 - 4-gram (slower, more coherent)"
  ngramChoice <- getLine
  
  let n = case ngramChoice of
            "2" -> 2
            "3" -> 3
            "4" -> 4
            _   -> 3  -- Default
  
  let modelConfig = ModelConfig
        { ngramSize = n
        , minFrequency = 1
        , smoothing = False
        }
  
  -- Step 6: Train model
  putStrLn $ "\n🧠 Training " ++ show n ++ "-gram model..."
  putStrLn "   (This may take a moment for large datasets)"
  
  let model = buildNGramModel modelConfig trainWords
  let modelStats = getModelStats model trainWords
  
  putStrLn "✅ Training complete!"
  displayModelStats modelStats
  
  -- Step 7: Evaluate on test data
  when (not $ null testWords) $ do
    putStrLn "📊 Evaluating model on test data..."
    let perplexity = calculatePerplexity model testWords
    displayEvaluationResults perplexity
  
  -- Step 8: Interactive mode
  runInteractiveMode inputFile prepConfig dataStats dataSplit startTime 
                     model modelConfig modelStats trainWords testWords

-- | Interactive mode for text generation and analysis
runInteractiveMode :: FilePath -> PreprocessConfig -> DatasetStats -> DatasetSplit 
                   -> UTCTime -> NGramModel -> ModelConfig -> ModelStats 
                   -> [String] -> [String] -> IO ()
runInteractiveMode inputFile prepConfig dataStats dataSplit startTime 
                   model modelConfig modelStats trainWords testWords = do
  showMenu
  choice <- getLine
  
  case choice of
    "1" -> do
      -- Generate text
      genStartTime <- getCurrentTime
      putStrLn "\nEnter seed words (space-separated):"
      putStrLn "(Example: to be or)"
      seedInput <- getLine
      let seed = words seedInput
      
      when (null seed) $ do
        putStrLn "❌ Please provide at least one seed word"
        runInteractiveMode inputFile prepConfig dataStats dataSplit startTime 
                          model modelConfig modelStats trainWords testWords
      
      putStrLn "How many words to generate? [20]:"
      numWordsInput <- getLine
      let numWords = if null numWordsInput 
                     then 20 
                     else read numWordsInput :: Int
      genEndTime <- getCurrentTime
      
      let processingTime = round $ toRational $ diffUTCTime genEndTime startTime * 1000
      
      displayGeneratedText generated
      
      -- Generate and save report
      putStrLn "\n📊 Generate execution report? (y/n):"
      reportChoice <- getLine
      when (reportChoice == "y") $ do
        timestamp <- getCurrentTime
        let session = GenerationSession
              { sessionTimestamp = timestamp
              , inputFilePath = inputFile
              , ngramSize = ngramSize modelConfig
              , seedWords = seed
              , requestedWords = numWords
              , generatedText = generated
              }
        saveReport session
      
      putStrLn "\nSave geinputFile prepConfig dataStats dataSplit startTime 
                        model modelConfig modelStats trainWords testWords
    
    "3" -> do
      -- Show statistics
      displayModelStats modelStats
      runInteractiveMode inputFile prepConfig dataStats dataSplit startTime 
                        model modelConfig modelStats trainWords testWords
    
    "4" -> do
      -- Evaluate on test data
      if null testWords
        then putStrLn "⚠️  No test data available"
        else do
          putStrLn "\n📊 Evaluating model..."
          let perplexity = calculatePerplexity model testWords
          displayEvaluationResults perplexity
      runInteractiveMode inputFile prepConfig dataStats dataSplit startTime 
                        model modelConfig modelStatse)"
      contextInput <- getLine
      let context = words contextInput
      
      let predictions = topPredictions model context 10
      putStrLn "\n=== Top 10 Predictions ==="
      if null predictions
        then putStrLn "⚠️  Context not found in training data"
        else mapM_ (\(word, prob) -> 
               putStrLn $ "  " ++ word ++ ": " ++ 
                         show (round (prob * 100)) ++ "%") predictions
      putStrLn "===========================\n"
      
      runInteractiveMode model trainWords testWords
    
    "3" -> do
      -- Show statistics
      let stats = getModelStats model trainWords
      displayModelStats stats
      runInteractiveMode model trainWords testWords
    
    "4" -> do
      -- Evaluate on test data
      if null testWords
        then putStrLn "⚠️  No test data available"
        else do
          putStrLn "\n📊 Evaluating model..."
          let perplexity = calculatePerplexity model testWords
          displayEvaluationResults perplexity
      runInteractiveMode model trainWords testWords
    
    "5" -> do
      -- Exit
      putStrLn "\n👋 Thank you for using N-Gram Text Generator!"
      putStrLn "   Project by:Group No-"
      return ()
    
    _ -> do
      putStrLn "❌ Invalid choice. Please try again."
      runInteractiveMode model trainWords testWords

-- | Quick demo for testing
quickDemo :: IO ()
quickDemo = do
  putStrLn "=== Quick Demo Mode ==="
  let sampleText = "the cat sat on the mat. the dog ran fast. the cat was happy. the mat was red."
  let config = defaultPreprocessConfig
  let processed = preprocessText config sampleText
  let (train, test) = simpleTrainTestSplit processed
  
  let modelConf = defaultTrigramConfig
  let model = buildNGramModel modelConf train
  
  putStrLn "Sample text processed and model trained!"
  putStrLn "\nGenerating from 'the cat':"
  generated <- generateText model 10 ["the", "cat"]
  displayGeneratedText generated