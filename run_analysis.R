#
# Coursera course project
#
# Getting and Cleaning Data
#


# SetWorkPath -----
wp <- "."
setwd(wp)
getwd()

# CreateDataFolder ------
if (!file.exists("data")) {
    dir.create("data")
    }

# DownloadFileUnzip -----
if (!file.exists("./data/projectData.zip")) {
    fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    download.file(fileURL,destfile = "./data/projectData.zip", mode = "wb")
    unzip("./data/projectData.zip", exdir = "./data")
    }

# GetFileList -----

# 2 Levels for both test and train set
dpHead <- "./data/UCI HAR Dataset/"
dpCase <- c("test/", "train/")
dpSignals <- "Inertial Signals/"

dpTest <- NULL
dpTest[1] <- paste0(dpHead, dpCase[1])
dpTest[2] <- paste0(dpHead, dpCase[1], dpSignals)

dpTrain <- NULL
dpTrain[1] <- paste0(dpHead, dpCase[2])
dpTrain[2] <- paste0(dpHead, dpCase[2], dpSignals)

fileListTest <- list.files(path = dpTest[1], pattern = "*.txt")
fileListTest <- list(fileListTest, 
                     list.files(path = dpTest[2], pattern = "*.txt"))
fileListTrain <- lapply(fileListTest, function (x) gsub("_test", "_train", x))
fileListMerge <- lapply(fileListTest, function (x) gsub("_test", "_merge", x))


# MergeFile -----
library(data.table)

dpMerge <- NULL
dpMerge[1] <- "./data/merge/"
dpMerge[2] <- paste0(dpMerge[1], dpSignals)

nLevels <- 2
for (iLevel in seq(nLevels)) {
    dp <- dpMerge[iLevel]
    if (!file.exists(dp)) {
        dir.create(dp)
    }}


for (iLevel in seq(nLevels)){
    for (iFile in seq_along(fileListTest[[iLevel]])){

        fileTest   <- paste0(dpTest[iLevel], fileListTest[[iLevel]][[iFile]])
        fileTrain  <- paste0(dpTrain[iLevel], fileListTrain[[iLevel]][[iFile]])
        fileMerge  <- paste0(dpMerge[iLevel], fileListMerge[[iLevel]][[iFile]])

        print(paste("Merging : ",fileListMerge[[iLevel]][[iFile]]))

        dtTest <- fread(fileTest)
        print(paste(fileTest, dim(dtTest)[2])) # check No. of Columns for each file
        dtTrain <- fread(fileTrain)
        print(paste(fileTrain, dim(dtTrain)[2])) # check No. of Columns for each file
        dtMerge <- rbindlist(list(dtTest, dtTrain))
        fwrite(dtMerge, file = fileMerge)

    }
}

# ExtractMeanStd -----
# There is only 1 file having 561 columns, need to extract from it the relevant columns 
fileRef   <- paste0(dpMerge[1],"X_merge.txt")
fileMeanStd <- paste0(dpMerge[1],"X_MeanStd.txt")

# Load reference data set of 561 columns
dtRef <- fread(fileRef)

# Read the features.txt
dpHead <- "./data/UCI HAR Dataset/"
fileFeatures <- paste0(dpHead,"features.txt")
dtFeatures <- fread(fileFeatures)

# check for mean() and std(), but not meanFreq
fMeanStd <- lapply(dtFeatures[,2], function (x) grepl("mean[(][)]", x) | grepl("std[(][)]", x))
fMeanStd <- unlist(fMeanStd[[1]]) # convert as a basic logical vector
dtName   <- dtFeatures[fMeanStd,2] # get the field value as name
dtName   <- dtName$V2   # turn into a simple vector

# filter for these flaged cases
dtMeanStd <- dtRef[, ..fMeanStd]
dtName <- gsub("[()]", "", dtName) # rm ()
dtName <- gsub("BodyBody", "", dtName) # fix typo in Name (BodyBody -> Body)
colnames(dtMeanStd) <- dtName
fwrite(dtMeanStd, file = fileMeanStd)

# GetAvgTidy -----

# get list of signal name and nature
dtNameSplit <- strsplit(dtName,"-")

signalName <- gsub("Mag","",lapply(dtNameSplit, `[[`, 1))
signalNature <- unlist(lapply(dtNameSplit, 
                              function (x) ifelse(length(x) == 3, 
                                                  paste0(x[[2]],"-",x[[3]]), 
                                                  paste0(x[[2]],"-mag"))))

# rename columns
colnames(dtMeanStd) <- paste0(signalName, "_", signalNature) 

# prepare long table
dtAvgLong <- data.table(matrix(NA, nrow = length(dtMeanStd), ncol = 3))
colnames(dtAvgLong) <- c("signal", "signalNature", "average") 
dtAvgLong$average <- unlist(dtMeanStd[, lapply(.SD,mean)])
dtAvgLong$signal <- unlist(lapply(strsplit(names(dtMeanStd),"_"), `[[`, 1))
dtAvgLong$signalNature <- unlist(lapply(strsplit(names(dtMeanStd),"_"), `[[`, 2))

# cast into normal table
dtAvg <- dcast(dtAvgLong, signal ~ signalNature, value.var = "average")

# save tidy data set
write.table(dtAvg, file = "DataSetAvg.txt" , row.names = FALSE)
