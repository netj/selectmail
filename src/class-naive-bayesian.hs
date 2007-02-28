{-
 - Haskell implementation of naive Bayesian categorization
 - Author: Jaeho Shin <netj@sparcs.org>
 - Created: 2007-02-18
 -}
module Main where

import IO
import System

main = do
    -- input
    (nrMsgs, allCounts) <- input
    let msgs = map (toRational.(max 1)) nrMsgs
    let counts = map (map toRational) allCounts
    -- convert to ratios
    let classSize = normalize msgs
    let r_min = 1 / foldl1 max msgs
    let features = map (map (max r_min) . overMsgs) counts
          where overMsgs cs = zipWith (/) cs msgs
    -- compute combined probabilities
    let probUnscaled = foldl1 (zipWith (*)) features
    let prob = normalize $ zipWith (*) probUnscaled classSize
    -- output
    sequence $ map (print . fromRational) prob


input :: IO ([Integer], [[Integer]])
input = do
    -- input number of messages of each class
    args <- getArgs
    -- input number of occurrences of each class for each feature
    if length args > 1 then do let nrMsgs = map read args
                               allCounts <- inputAllCounts
                               return (nrMsgs, allCounts) -- package
        else ioError $ userError $
            "Supply size of each class as arguments, and for stdin, " ++
            "supply each feature's counts for every class as a single line."

inputAllCounts :: IO [[Integer]]
inputAllCounts = do ln <- getLine
                    let counts = map read $ words ln
                    moreCounts <- inputAllCounts
                    return $ counts : moreCounts
                 `catch` withHandler
                    where withHandler e | isEOFError e = return []
                                        | otherwise    = ioError e

normalize xs = map (/ total) xs
        where total = if sum xs == 0 then 1 else sum xs

