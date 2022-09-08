module Model.Log
  ( Log
  ) where
import           Colonnade
import           Control.Arrow                  ( Arrow(second) )
import           Data.Aeson                     ( FromJSON
                                                , ToJSON
                                                )
import           Data.Profunctor                ( Profunctor(lmap) )
import           Data.Text                      ( Text )
import           Fmt
import           GHC.Generics                   ( Generic )
import           Model.Nutrients
import           Model.Types                    ( Amount(Amount)
                                                , Description
                                                , EFID(EFID)
                                                , Id(Id)
                                                , Minute(Minute)
                                                , trimmed
                                                )
import           Typeclass.Tabled               ( Tabled(..) )

data Log = Log
  { id          :: EFID
  , day         :: Text
  , minute      :: Minute
  , description :: Description
  , amount      :: Amount
  , nutrients   :: Nutrients
  }
  deriving (Show, Generic)

instance ToJSON Log
instance FromJSON Log

instance Tabled Log where
  colonnade v = mconcat
    [ headed "#" $ pretty . fst
    , headed "id" $ pretty . idcol . Model.Log.id . snd
    , headed "description" $ pretty . trimmed v . description . snd
    , headed "time" $ time . minute . snd
    , headed "amount" $ pretty . (\(Amount a) -> a) . amount . snd
    , ncol
    ]
   where
    time (Minute m) = "" +| m `div` 60 |+ ":" +| m `mod` 60 |+ ""
    ncol = lmap (second nutrients) $ colonnade v

    idcol (EFID (Left  (Id i))) = i
    idcol (EFID (Right (Id i))) = i

