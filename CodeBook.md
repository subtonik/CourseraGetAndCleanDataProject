# CodeBook

## Description of Raw data source
The structure for both the __test__ and __train__ folders are similar. Each contains 3 txt files for the processed data, and another folder call _Inertial Signals_ which stores the "raw" signals.

The file names in the __test__ and __train__ folders only differ by a descriptive keyword in the file name.

Among the three main data text files, the **X\_keyword.txt** contains 561 columns as listed in the feature.txt. Hence, it is the target for the data extraction below.
The **y\_keyword.txt** file contains activity indices for the test.
The **subject\_keyword.txt** lists the subject indices for the test.

## Data cleaning actions

The following actions are done to prepare the target data file:

1) First, all the files in the __test__ and __train__ folders are merged into the __merge__ folder.
2) Then, the file features.txt is parsed to flag those containing __mean()__ and __std()__ into a logical vector.
3) After, the __()__ and the typo __BodyBody__ are removed.
4) The complex name is then reshaped into 3 portions: the measurement feature name, component specification and statistics.
5) The activity data is load and the actual names of the activities are fetched.
6) The subject indices are loaded.
7) The subject, activity and mean-std data are combined into one single file.
8) The file is then melted based on *subject* and *activity*
9) The complex name actually contains the signal feature, its component and the statistics of that component. They are separated in the melted file.
10) The __averages__ of each signal feature, per component and statistics, grouped by subject and activity are determined.
11) Lastly, this new format is saved in the output file DataSetAvg.txt

## Variable description

The final data file 6 columns of information:

1) subject: the indices of the test subject
2) activity: the label of the activity during the signal capturing
3) feature: the measurement of the signal
4) component: the components of the measurement, which include 4 values: X, Y, Z, and mag for magnitude
5) mean: the averaged mean of the signal
6) std: the averaged standard deviation of the signal
