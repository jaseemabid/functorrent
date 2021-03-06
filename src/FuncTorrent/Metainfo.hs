module FuncTorrent.Metainfo
    (Info(..),
     Metainfo(..),
     mkInfo,
     mkMetaInfo
    ) where

import Prelude hiding (lookup)
import Data.ByteString.Char8 (ByteString, unpack)
import Data.Map as M ((!), lookup)
import Crypto.Hash.SHA1 (hash)
import Data.Maybe (maybeToList)

import FuncTorrent.Bencode (BVal(..), encode, bstrToString, bValToInteger)

-- only single file mode supported for the time being.
data Info = Info { pieceLength :: !Integer
                 , pieces :: !ByteString
                 , private :: !(Maybe Integer)
                 , name :: !String
                 , lengthInBytes :: !Integer
                 , md5sum :: !(Maybe String)
                 } deriving (Eq, Show)

data Metainfo = Metainfo { info :: !Info
                         , announceList :: ![String]
                         , creationDate :: !(Maybe Integer)
                         , comment :: !(Maybe String)
                         , createdBy :: !(Maybe String)
                         , encoding :: !(Maybe String)
                         , infoHash :: !ByteString
                         } deriving (Eq, Show)

mkInfo :: BVal -> Maybe Info
mkInfo (Bdict m) = let (Bint pieceLength') = m ! "piece length"
                       (Bstr pieces') = m ! "pieces"
                       private' = Nothing
                       (Bstr name') = m ! "name"
                       (Bint length') = m ! "length"
                       md5sum' = Nothing
                   in Just Info { pieceLength = pieceLength'
                                , pieces = pieces'
                                , private = private'
                                , name = unpack name'
                                , lengthInBytes = length'
                                , md5sum = md5sum'}
mkInfo _ = Nothing

mkMetaInfo :: BVal   -> Either String Metainfo
mkMetaInfo (Bdict m)  =
    let (Just info')  = mkInfo $ m ! "info"
        announce'     = lookup "announce" m
        announceList' = lookup "announce-list" m
        creationDate' = lookup "creation date" m
        comment'      = lookup "comment" m
        createdBy'    = lookup "created by" m
        encoding'     = lookup "encoding" m
    in Right Metainfo {
             info         = info'
           , announceList = maybeToList (announce' >>= bstrToString)
                            ++ getAnnounceList announceList'
           , creationDate = bValToInteger =<< creationDate'
           , comment      = bstrToString  =<< comment'
           , createdBy    = bstrToString  =<< createdBy'
           , encoding     = bstrToString  =<< encoding'
           , infoHash     = hash . encode $ (m ! "info")
        }

mkMetaInfo _ = Left "Unable to make Metainfo. Corrupt BString"

getAnnounceList :: Maybe BVal -> [String]
getAnnounceList Nothing = []
getAnnounceList (Just (Bint _)) = []
getAnnounceList (Just (Bstr _)) = []
getAnnounceList (Just (Blist l)) = map (\s -> case s of
                                               (Bstr s') ->  unpack s'
                                               (Blist s') -> case s' of
                                                              [Bstr s''] -> unpack s''
                                                              _ -> ""
                                               _ -> "") l

getAnnounceList (Just (Bdict _)) = []
