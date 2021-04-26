# FILE
#   run_analysis.R
#
# OVERVIEW
# Does the following: 
# 1) Merges the training and the test sets to create one data set.
# 2) Extracts only the measurements on the mean and standard deviation for each measurement. 
# 3) Uses descriptive activity names to name the activities in the data set
# 4) Appropriately labels the data set with descriptive variable names. 
# 5) From the data set in step 4, creates a second, independent tidy data 
#     set with the average of each variable for each activity and each subject.

library(dplyr)
library(data.table)

#********************** STEP 1: GET THE DATA ********************** 

print("STEP 1: GET THE DATA")

# download from web
FileUrlZip <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
DirectoryZip <- "final.zip"

#create directory, if dont exist
if (!file.exists(DirectoryZip)) {
  download.file(FileUrlZip, DirectoryZip, mode = "wb")
}

# unzip file
dataPath <- "UCI HAR Dataset"
if (!file.exists(dataPath)) {
  unzip(DirectoryZip)
}


#********************** STEP 2: READ DATAFILES ********************** 

print("STEP 2: READ DATAFILES FROM DATA")


# READ "features", NOT FACTORS
features <- read.table(file.path(dataPath, "features.txt"), as.is = TRUE)

# READ "activities", NOT FACTORS
activities <- read.table(file.path(dataPath, "activity_labels.txt"))

#CREATE COLNAMES FOR LABEL
colnames(activities) <- c("activityId", "activityLabel")

# READ FROM TRAIN DIRECTORY
trainSubjects <- read.table(file.path(dataPath, "train", "subject_train.txt"))
trainValues   <- read.table(file.path(dataPath, "train", "X_train.txt"))
trainActivity <- read.table(file.path(dataPath, "train", "y_train.txt"))

# READ FROM TEST DIRECTORY
testSubjects <- read.table(file.path(dataPath, "test", "subject_test.txt"))
testValues   <- read.table(file.path(dataPath, "test", "X_test.txt"))
testActivity <- read.table(file.path(dataPath, "test", "y_test.txt"))


#****************** STEP 3:MERGE DATA FROM TRAIN & TEST ********************** 

print("STEP 3: MERGING DATA")

# MERGING HERE
humanActivity <- rbind( 
        cbind( trainSubjects, trainValues, trainActivity),
        cbind( testSubjects,  testValues,  testActivity)
)

# REMOVE VARIABLE TO SAVE MEMORY
rm( trainSubjects, trainValues, trainActivity)
rm( testSubjects,  testValues,  testActivity)

#CREATE COLNAMES FOR LABEL
colnames(humanActivity) <- c("subject", features[, 2], "activity")


#*********** STEP 4: MEAN & STANDARD DEVIATION (MEASUREMENT) *************** 

print("STEP 4: CALCULATION ...")

# SELECT FROM DATA -- FILTERING...
columnsToKeep <- grepl("subject|activity|mean|std", colnames(humanActivity))

# DATA THAT WE WANT
humanActivity <- humanActivity[, columnsToKeep]


# **********************  STEP 5:    ********************** 
#*USE DESCRIPTIVE ACTIVITY NAMES TO NAME THE ACTIVITIES IN THE DATA SET
                 
print("STEP 5: DESCRIPTIVE ACTIVITY")

# replace activity values with named factor levels
humanActivity$activity <- factor(
  humanActivity$activity,levels = activities[, 1], labels = activities[, 2]
  )


#*********** STEP 6: LABEL THE DATA WITH THE "DESCRIPTIVE ACTIVITY ABOVE********
print("STEP 6: LABEL THE DATA")


# GET COLUMNAMES 
humanActivityCols <- colnames(humanActivity)

# CLEANING THE DATA - FILETRING - REMOVING CARACTERS
humanActivityCols <- gsub("[\\(\\)-]", "", humanActivityCols)

# CLEANING THE DATA (NAMES), EXPAND ABBREVIATION 
humanActivityCols <- gsub( "^f" ,  "frequencyDomain", humanActivityCols)
humanActivityCols <- gsub( "^t" ,  "timeDomain"     , humanActivityCols)
humanActivityCols <- gsub("Acc" ,  "Accelerometer"  , humanActivityCols)
humanActivityCols <- gsub("Gyro",  "Gyroscope"      , humanActivityCols)
humanActivityCols <- gsub("Mag" ,  "Magnitude"      , humanActivityCols)
humanActivityCols <- gsub("Freq",  "Frequency"      , humanActivityCols)
humanActivityCols <- gsub("mean",  "Mean"           , humanActivityCols)
humanActivityCols <- gsub("std" ,"StandardDeviation", humanActivityCols)

# CORRECT TYPO
humanActivityCols <- gsub("BodyBody", "Body"        , humanActivityCols)

# USING NEW LABEL
colnames(humanActivity) <- humanActivityCols


#*************STEP 7: CREATE NEW DATA WITH ALL THE AVG ATIVITIES *************
print("STEP 7: CREATE NEW DATA ")

# group by subject and activity and summarise using mean
humanActivityMeans <- humanActivity %>% 
                      group_by(subject, activity) %>% 
                      summarise_each(funs(mean))

# output to file "tidy_data.txt"
write.table(humanActivityMeans, "tidy_data.txt", row.names = FALSE, quote = FALSE)

print("STEP 8: SAVE OUTPUT --> tidy_data.txt ")

