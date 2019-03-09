{-# LANGUAGE OverloadedStrings #-}

module Main where
--------------------------------------------------------------------------------
import           Data.Monoid (mappend)
import           Hakyll
import           Hakyll.Web.Sass
import           Text.Pandoc
import           Text.Pandoc.Highlighting
import           Data.List              (isSuffixOf, isPrefixOf, isInfixOf,
                                         intercalate, sort)
import           System.FilePath.Posix  (takeBaseName, takeDirectory,
                                         (</>), takeFileName)

import 		 Control.Monad (filterM)
--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*.scss" $ do
        route   $ setExtension "css"
        compile (fmap compressCss <$> sassCompiler)

    match "css/*.css" $ do
        route   idRoute
        compile compressCssCompiler

    match "javascripts/*.js" $ do
        route   idRoute
        compile copyFileCompiler

    match "public/*" $ do
        route   idRoute
        compile copyFileCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ cleanRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls
            >>= cleanIndexUrls

    match "posts/*" $ do
        route $ cleanRoute
        let writerOpts = defaultHakyllWriterOptions { writerHighlightStyle = Just pygments }
        compile $ pandocCompilerWith defaultHakyllReaderOptions writerOpts
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls
            >>= cleanIndexUrls

    create ["archive.html"] $ do
        route cleanRoute
        compile $ do
            posts <- removePrivate =<< recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls
                >>= cleanIndexUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                -- >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls
                >>= cleanIndexUrls

    match "templates/*" $ compile templateBodyCompiler

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
    where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
        where p = toFilePath ident

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls cleanIndex)

cleanIndexHtmls :: Item String -> Compiler (Item String)
cleanIndexHtmls = return . fmap (replaceAll pattern replacement)
    where
      pattern = "/index.html"
      replacement = const ""

cleanIndex :: String -> String
cleanIndex url
    | idx `isSuffixOf` url = take (length url - length idx) url
    | otherwise            = url
  where idx = "/index.html"

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    -- dateField "date" "%B %e, %Y" `mappend`
    defaultContext

removePrivate :: MonadMetadata m => [Item a] -> m [Item a]
removePrivate items = do
	filterM (\item -> do
		metadata <- getMetadata (itemIdentifier item)
		maybe (pure True) (const (pure False)) (lookupString "private" metadata)
	 ) items
