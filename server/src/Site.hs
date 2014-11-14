{-# LANGUAGE OverloadedStrings #-}

------------------------------------------------------------------------------
-- | This module is where all the routes and handlers are defined for your
-- site. The 'app' function is the initializer that combines everything
-- together and is exported by this module.
module Site
  ( app
  ) where

------------------------------------------------------------------------------
import           Control.Applicative
import           Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as CBS
import qualified Data.ByteString.Lazy as LBS
import qualified Data.Text as T
import           Snap (liftIO)
import           Snap.Core
import           Snap.Snaplet
import           Snap.Snaplet.Heist
import           Snap.Util.FileServe
import           Heist
import qualified Heist.Interpreted as I
------------------------------------------------------------------------------
import           Application
------------------------------------------------------------------------------
import           System.IO.Streams (InputStream, OutputStream, stdout)
import qualified System.IO.Streams as Streams
import qualified Data.ByteString as S
import           Network.Http.Client
import           Webhooks.Slack.Types
import           Data.Aeson (encode)
import           System.Environment
import           JSON.JSON
import           Webhooks.Docker.Hub.Types

myHandler :: Handler App App ()
myHandler = do
  txt <- getRequest
  x <- liftIO $ pingSlack $ slackNote
    { text = T.pack $ show $ rqServerName txt }
  writeBS x

getSlackURL = do
  company <- getEnv "SLACK_SUBDOMAIN"
  token <- getEnv "SLACK_TOKEN"
  return $ CBS.concat [ "https://"
                 , CBS.pack company
                 , ".slack.com/services/hooks/incoming-webhook?token="
                 , CBS.pack token
                 ]

--pingSlack :: ToSlack -> IO ()
pingSlack toSlack = do
  slackURL <- getSlackURL
  postForm slackURL
                     [("payload",LBS.toStrict $ encode toSlack)]
                     concatHandler


slackNote :: ToSlack
slackNote = ToSlack { channel = Just $ Channel "@biscarch"
                    , text =  "Testing Slack"
                    , username = Just $ BotName "BotBot"
                    , icon_emoji = Just TRIUMPH
                    , icon_url = Nothing }

fromHubHandler :: Handler App App ()
fromHubHandler = do
  eitherJSON <- getJSON
  case eitherJSON of
    Left err -> do
      liftIO $ pingSlack $ slackNote
        { text =  T.pack err
        , icon_emoji = Just TRIUMPH }
      writeBS "Hub Failure"
    Right fromHub -> do
      liftIO $ pingSlack $ slackNote
        { text = callback_url fromHub
        , icon_emoji = Just DOG}
      writeBS "Hub Success"
------------------------------------------------------------------------------
-- | The application's routes.
routes :: [(ByteString, Handler App App ())]
routes = [("", myHandler)
         ,("/from_hub", fromHubHandler)
         ,("", serveDirectory "static")]


------------------------------------------------------------------------------
-- | The application initializer.
app :: SnapletInit App App
app = makeSnaplet "app" "An snaplet example application." Nothing $ do
    h <- nestSnaplet "" heist $ heistInit "templates"
    addRoutes routes
    return $ App h

