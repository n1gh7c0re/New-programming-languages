{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import System.IO
import Data.Aeson
import Data.Aeson.Encode.Pretty (encodePretty)
import qualified Data.ByteString.Lazy as B
import qualified Data.Map.Strict as M
import GHC.Generics
import Data.Maybe (fromMaybe, listToMaybe)

-- Типы
type Vertex = String
type Graph = M.Map Vertex [Vertex]
type Path = [Vertex]

data Query = Query { start :: String, target :: String } deriving (Generic)
instance FromJSON Query

-- Рекурсивный DFS для поиска пути
dfs :: Graph -> Vertex -> Vertex -> Path -> Maybe Path
dfs graph current target visited
    | current == target = Just (reverse visited)
    | otherwise = listToMaybe $ concatMap recurse next
  where
    next = filter (`notElem` visited) $ fromMaybe [] (M.lookup current graph)
    recurse neigh = case dfs graph neigh target (neigh : visited) of
                      Just p -> [p]
                      Nothing -> []

-- Парсинг графа из файла (рёбра -> adjacency list)
parseGraph :: String -> Graph
parseGraph content = foldr addEdge M.empty (lines content)
  where
    addEdge line m
      | length parts /= 2 = m
      | otherwise = M.insertWith (++) from [to] m
      where
        parts = words line
        from = head parts
        to = last parts

-- Главная функция
main :: IO ()
main = do
    graphContent <- readFile "graph.txt"
    queryContent <- B.readFile "query.json"
    
    let graph = parseGraph graphContent
        mQuery = decode queryContent :: Maybe Query
        start' = maybe "A" start mQuery
        target' = maybe "Z" target mQuery
        mPath = dfs graph start' target' [start']
    
    let result = case mPath of
                   Just p -> object ["path" .= p]
                   Nothing   -> object ["path" .= Null]
    
    B.writeFile "path.json" (encodePretty result)
    putStrLn "Готово! Результат в path.json"