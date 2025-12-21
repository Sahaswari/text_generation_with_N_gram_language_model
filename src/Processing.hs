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
-- For n-gram: context is (n-1) words, predicting the nth word
-- Bigram (n=2): 1 word context -> next word
-- Trigram (n=3): 2 word context -> next word
buildNGramModel :: ModelConfig -> [String] -> NGramModel
buildNGramModel config words =
  let n = ngramSize config
      -- Add sentence markers to help model learn sentence boundaries
      markedWords = addSentenceMarkers words
      -- Create all n-grams of size n (context of n-1 + next word)
      ngrams = ngramsOf n markedWords
  in foldl' (insertNGram (n - 1)) Map.empty ngrams

-- | Insert a single n-gram into the model
-- Takes an n-gram like ["to", "be", "or"] and updates the frequency map
-- For trigram: context=["to","be"], nextWord="or"
insertNGram :: Int -> NGramModel -> [String] -> NGramModel
insertNGram contextSize model ngram =
  let context = take contextSize ngram  -- For trigram: ["to", "be"]
      nextWord = last ngram              -- For trigram: "or"
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
  let contextSize = case Map.keys model of
            [] -> 1
            (k:_) -> length k
      ngramSize' = contextSize + 1  -- n-gram size = context + 1
      ngrams = ngramsOf ngramSize' testWords
      totalNGrams' = length ngrams
  in if totalNGrams' == 0
     then 1.0 / 0.0  -- Infinity
     else let logProbs = map (logProbability model contextSize) ngrams
              avgLogProb = sum logProbs / fromIntegral totalNGrams'
          in exp (-avgLogProb)
  where
    logProbability :: NGramModel -> Int -> [String] -> Double
    logProbability mdl ctxSize ngram =
      let context = take ctxSize ngram
          nextWord = last ngram
      in case Map.lookup context mdl of
           Nothing -> log 0.0001  -- Smoothing for unseen n-grams
           Just wordFreqs ->
             let total = sum $ Map.elems wordFreqs
                 count = Map.findWithDefault 0 nextWord wordFreqs
             in if count == 0
                then log 0.0001
                else log (fromIntegral count / fromIntegral total)

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