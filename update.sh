ghc --make -threaded site.hs && ./site build && aws s3 sync _site/ s3://blog.spacekitteh.moe --region us-east-1
