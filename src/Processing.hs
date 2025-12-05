-- Processing.hs
-- Core n-gram model training and text generation

module Processing
  ( buildNGramModel
  , generateText
  , calculatePerplexity
  , getModelStats
  , topPredictions
  ) where

import qualified Data.Map.Strict as Map
import Data.List (foldl', sortBy)
import Data.Ord (comparing)
import DataTypes
import Utils

-- | Build an n-gram model from a list of words
-- This is the main training function
buildNGramModel :: ModelConfig -> [String] -> NGramModel
buildNGramModel config words =
  let n = ngramSize config
      -- Add sentence markers to help model learn sentence boundaries
      markedWords = addSentenceMarkers words
      -- Create all n-grams of size n+1 (context + next word)
      ngrams = ngramsOf (n + 1) markedWords
  in foldl' (insertNGram n) Map.empty ngrams

-- | Insert a single n-gram into the model
-- Takes an n-gram like ["to", "be", "or"] and updates the frequency map
insertNGram :: Int -> NGramModel -> [String] -> NGramModel
insertNGram n model ngram =
  let context = take n ngram      -- ["to", "be"]
      nextWord = last ngram        -- "or"
  in Map.insertWith (Map.unionWith (+)) 
                    context 
                    (Map.singleton nextWord 1) 
                    model

-- | Generate text using the n-gram model
-- Takes a seed (starting words) and generates up to maxWords
generateText :: NGramModel -> Int -> [String] -> IO [String]
generateText model maxWords seed = do
  generated <- generateLoop model maxWords seed []
  return $ seed ++ generated
  where
    generateLoop :: NGramModel -> Int -> [String] -> [String] -> IO [String]
    generateLoop _ 0 _ acc = return $ reverse acc
    generateLoop mdl remaining context acc = do
      maybeNext <- selectNextWord mdl context
      case maybeNext of
        Nothing -> return $ reverse acc  -- Can't continue
        Just "<END>" -> return $ reverse acc  -- Sentence ended
        Just nextWord -> 
          let newContext = drop 1 context ++ [nextWord]
          in generateLoop mdl (remaining - 1) newContext (nextWord : acc)

-- | Select the next word based on the current context
selectNextWord :: NGramModel -> [String] -> IO (Maybe String)
selectNextWord model context = 
  case Map.lookup context model of
    Nothing -> 
      -- Fallback: try shorter context if current one not found
      if length context > 1
        then selectNextWord model (tail context)
        else return Nothing
    Just wordFreqs -> weightedRandomSelect wordFreqs

-- | Calculate perplexity of the model on test data
-- Lower perplexity = better model
-- Perplexity measures how "surprised" the model is by the test data
calculatePerplexity :: NGramModel -> [String] -> Double
calculatePerplexity model testWords =
  let n = case Map.keys model of
            [] -> 2
            (k:_) -> length k
      ngrams = ngramsOf (n + 1) testWords
      totalNGrams = length ngrams
      logProbs = map (logProbability model n) ngrams
      avgLogProb = sum logProbs / fromIntegral totalNGrams
  in exp (-avgLogProb)
  where
    logProbability :: NGramModel -> Int -> [String] -> Double
    logProbability mdl n ngram =
      let context = take n ngram
          nextWord = last ngram
      in case Map.lookup context mdl of
           Nothing -> log 0.0001  -- Smoothing for unseen n-grams
           Just wordFreqs ->
             let total = sum $ Map.elems wordFreqs
                 count = Map.findWithDefault 0 nextWord wordFreqs
             in log (fromIntegral count / fromIntegral total)

-- | Get model statistics
getModelStats :: NGramModel -> [String] -> ModelStats
getModelStats model corpusWords = ModelStats
  { totalNGrams = countUniqueNGrams model
  , DataTypes.vocabularySize = Utils.vocabularySize model
  , corpusSize = length corpusWords
  }

-- | Show top predictions for a given context
topPredictions :: NGramModel -> [String] -> Int -> [(String, Double)]
topPredictions model context n =
  case Map.lookup context model of
    Nothing -> []
    Just wordFreqs ->
      let total = sum $ Map.elems wordFreqs
          withProbs = Map.map (\count -> fromIntegral count / fromIntegral total) wordFreqs
      in take n $ sortBy (flip $ comparing snd) $ Map.toList withProbs