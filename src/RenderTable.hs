module RenderTable
  ( renderTable
  ) where

import           Colonnade
import qualified Colonnade.Encode              as E
import           Data.Text
import qualified Data.Text                     as T

renderTable :: Foldable f => Colonnade Headed a Text -> f a -> Text
renderTable col xs = T.unlines
  [ makeRow makeSingleColumnDivider "+"
  , makeRow makeSingleColumnH       "|"
  , renderBody sizedCol xs
  ]
 where
  sizedCol = E.sizeColumns T.length xs col

  makeRow columnf end = mconcat [E.headerMonoidalFull sizedCol columnf, end]

  makeSingleColumnH (E.Sized (Just sz) (Headed c)) =
    mconcat ["| ", rightPad sz ' ' c, " "]

  makeSingleColumnH (E.Sized Nothing _) = ""

renderBody
  :: Foldable f => Colonnade (E.Sized (Maybe Int) Headed) a Text -> f a -> Text
renderBody sizedCol xs = mconcat [divider, rowContents, divider]
 where
  makeSingleColumn (E.Sized (Just s) _) c =
    mconcat ["| ", rightPad s ' ' c, " "]

  makeSingleColumn (E.Sized Nothing _) _ = ""

  divider =
    mconcat [E.headerMonoidalFull sizedCol makeSingleColumnDivider, "+", "\n"]

  rowContents =
    let makeRow x =
          mconcat [E.rowMonoidalHeader sizedCol makeSingleColumn x, "|", "\n"]
    in  foldMap makeRow xs

makeSingleColumnDivider :: E.Sized (Maybe Int) f a -> Text
makeSingleColumnDivider (E.Sized (Just sz) _) = "+" <> hyphens (sz + 2)
makeSingleColumnDivider (E.Sized Nothing   _) = ""

hyphens :: Int -> Text
hyphens n = T.replicate n "-"

rightPad :: Int -> Char -> Text -> Text
rightPad m a xs = xs <> T.unfoldrN (m - T.length xs) (const $ Just (a, ())) ()

