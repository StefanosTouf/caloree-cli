{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use <$>" #-}
module Lib
  ( executeCommand
  ) where
import           Control.Monad.Reader
import           Data.Text                      ( Text )
import qualified Data.Vector                   as V
import           Http.CustomFoodRequest
import           Http.FoodRequest
import           Http.LogRequest
import           Http.User                      ( getTargetNutrients
                                                , upsertNutrients
                                                )
import           Model.Command                  ( Command(..) )
import           Model.Config                   ( AppConfig(..) )
import qualified Model.CustomFood              as CF
import qualified Model.Food                    as F
import           Model.Log
import           Model.Nutrients
import           Model.NutrientsProgress
import           Model.Types
import           Typeclass.Tabled
import           Typeclass.WithDefault          ( def )

execute :: (Functor m, Tabled a) => m [a] -> Verbosity -> m Text
execute req v = fmap withEmpty req
 where
  withEmpty [] = ""
  withEmpty xs = table v $ V.fromList xs

execute_ :: (Monad m) => m () -> m Text
execute_ req = req >> pure "Ok!"

withTargets
  :: (MonadIO m, MonadReader AppConfig m, Tabled a)
  => Verbosity
  -> Nutrients
  -> [a]
  -> m Text
withTargets Minimal _ as = pure $ table Minimal (V.fromList as)
withTargets v       n as = getTargetNutrients >>= make
 where
  make n' =
    (<>) <$> execute (pure as) v <*> execute (pure $ makeProgress n n') v

executeCommand :: (MonadReader AppConfig m, MonadIO m) => Command -> m Text
executeCommand (SearchFood v d p l) = execute (getFoods (def d) p l) $ def v

executeCommand (SearchCustomFood v d p l) =
  execute (getCustomFoods (def d) p l) $ def v

executeCommand (ViewFood v i a) =
  getFood i a >>= \f -> withTargets (def v) (F.nutrients f) [f]

executeCommand (ViewCustomFood v i a) =
  getCustomFood i a >>= \cf -> withTargets (def v) (CF.nutrients cf) [cf]

executeCommand (ViewLog r v f p l) =
  getLogsRequest p l f
    >>= (\l' -> withTargets (def v) (sumNutrients l') l')
    .   roundTime (def r)

executeCommand (UpdateLog a d n   ) = execute_ $ updateLogRequest a d n
executeCommand (UndoLog d t       ) = execute_ $ undoLogRequest d t
executeCommand (AddLog a d t i    ) = execute_ $ addLogRequest a d t i
executeCommand (RemoveLog     d n ) = execute_ $ removeLogRequest d n
executeCommand (AddCustomFood d n ) = execute_ $ addCustomFood d n
executeCommand (DeleteCustomFood i) = execute_ $ deleteCustomFood i
executeCommand (UpdateTargets    n) = execute_ $ upsertNutrients n
