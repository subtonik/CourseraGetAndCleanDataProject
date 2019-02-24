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
# Load the X data set of 561 columns
fileDataX   <- paste0(dpMerge[1],"X_merge.txt")
dtDataX <- fread(fileDataX)

# Read the features.txt
dpHead <- "./data/UCI HAR Dataset/"
fileFeatures <- paste0(dpHead,"features.txt")
dtFeatures <- fread(fileFeatures)

# set filter for mean() and std(), but not meanFreq
fMeanStd <- lapply(dtFeatures[,2], function (x) grepl("mean[(][)]", x) | grepl("std[(][)]", x))
fMeanStd <- unlist(fMeanStd[[1]]) # convert as a basic logical vector

# filter for these flaged cases from X data file
dtMeanStd <- dtDataX[, ..fMeanStd]

# get and clean feature names
dtName   <- dtFeatures[fMeanStd,2] # get the field value as name
dtName   <- dtName$V2   # turn into a simple vector

dtName <- gsub("[()]", "", dtName) # rm ()
dtName <- gsub("BodyBody", "", dtName) # fix typo in Name (BodyBody -> Body)

dtNameSplit <- strsplit(dtName,"-")

featureName <- gsub("Mag","",lapply(dtNameSplit, `[[`, 1))
featureStat <- unlist(lapply(dtNameSplit, `[[`, 2))
featureSpec <- unlist(lapply(dtNameSplit, function (x) ifelse(length(x) == 3, x[[3]], "mag")))

# rename columns of the filtered data set
colnames(dtMeanStd) <- paste0(featureName, "_", featureSpec, "_", featureStat) 


# Load the activity data label (y)
fileActivity   <- paste0(dpMerge[1],"y_merge.txt")
dtActivity <- fread(fileActivity)
colnames(dtActivity) <- "IDactivity"

# Read the activity_labels.txt
dpHead <- "./data/UCI HAR Dataset/"
fileActivityLabels <- paste0(dpHead,"activity_labels.txt")
dtActivityLabels <- fread(fileActivityLabels)
colnames(dtActivityLabels) <- c("IDactivity","activity")

# replace index in activity
replaceIndex <- function(x) unlist(dtActivityLabels[x,activity])
dtActivity <- dtActivity[, activity:= replaceIndex(IDactivity)]

# Load the subject label
fileSubject   <- paste0(dpMerge[1],"subject_merge.txt")
dtSubject <- fread(fileSubject)
colnames(dtSubject) <- "subject"

# combine data set
dtDataSet <- cbind(dtSubject,dtActivity[,.(activity)],dtMeanStd)

# save data set
fileMeanStd <- paste0(dpMerge[1],"DataSet_MeanStd.txt")
fwrite(dtDataSet, file = fileMeanStd)

# GetAvgTidy -----

# melt the data table based on subject and activity
dtDataSet0 <- melt(dtDataSet, id.vars = c("subject", "activity"), measure.vars = .SD)
dtDataSet0 <- dtDataSet0[,variable:=as.character(variable)] # convert factor into character

# split complex variable name into different columns
dtDataSet0 <- dtDataSet0[, feature:=as.character(lapply(strsplit(variable,"_"), `[[`, 1))]
dtDataSet0 <- dtDataSet0[, component:=as.character(lapply(strsplit(variable,"_"), `[[`, 2))]
dtDataSet0 <- dtDataSet0[, stat:=as.character(lapply(strsplit(variable,"_"), `[[`, 3))]

# remove dummy column variable
dtDataSet0 <- dtDataSet0[,variable:=NULL]

# get average 
dtAvg <- dtDataSet0[, mean(value), by=.(subject, activity, feature, component, stat)]
names(dtAvg)[names(dtAvg) == "V1"] = "average"

# cast into final table
dtTidyDataSet <- dcast(dtAvg, subject + activity + feature + component ~ stat, value.var = "average")
dtTidyDataSet

# save tidy data set
write.table(dtTidyDataSet, file = "DataSetAvg.txt" , row.names = FALSE)
