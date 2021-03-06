context("MADRaT configuration")

cfg <- getConfig(verbose = FALSE)

test_that("cache folder can be set properly", {
  setConfig(cachefolder=getwd(), .verbose = FALSE)
  expect_identical(getwd(),getConfig("cachefolder"))
  
  # test shortcut formulation
  setConfig(cachefolder="rev123", .verbose = FALSE)
  expect_identical(file.path(getConfig("mainfolder"),"cache/rev123"),getConfig("cachefolder"))
})

test_that("main folder setting works", {
  sink(tempfile())
  main <- getOption("MADRAT_MAINFOLDER")
  on.exit(options(MADRAT_MAINFOLDER = main))
  options(MADRAT_MAINFOLDER = NULL)
  expect_identical(basename(madrat:::getMainfolder(.testmode = TRUE)), "testmaindir")
  expect_identical(basename(madrat:::getMainfolder()), "testmaindir")
  
  options(MADRAT_MAINFOLDER = NULL)
  if (!is.na(Sys.getenv("MADRAT_MAINFOLDER", unset = NA))) {
    madratenv <- Sys.getenv("MADRAT_MAINFOLDER", unset = NA)
    on.exit(Sys.setenv(MADRAT_MAINFOLDER = madratenv), add = TRUE)
  }
  Sys.setenv(MADRAT_MAINFOLDER = "test")
  expect_identical(basename(madrat:::getMainfolder()), "test")
  Sys.unsetenv("MADRAT_MAINFOLDER")
  sink()
})
