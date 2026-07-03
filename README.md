This is the code for Fritzinger and Carney (2026),
"Timbre Encoding in the Inferior Colliculus" published in the Journal of Neuroscience.

## Data 

Data is available for download at: https://osf.io/uyn5/. This zip file contains data used for all analyses, 
a PDF including rate responses and characteristics for all neurons included in the manuscript, and code. 

Data include a folder called Neural_Data which contains data for each neuron in the manuscript. 
Preprocessed data used in figure generation are included as  excel and .mat files. 

## Code Workflow 

### Generating Figures 

Run ```generate_figs.m``` with an input of the figure to be generated. For convenience, preprocessed data is included 
in the data folder due to lengthy compute times for some analyses. Functions for each figure, including 
supplemental material, are found in the _"figures"_ folder. 

Scripts to run the analyses for preprocessed data are found in the _"analysis"_ folder. Other functions used for
analysis and figure generation are found in the _"helper-functions"_ folder. 

### Running Models
#### Broad Inhibition Model 

The _"model-lat-inh"_ folder contains precompiled code necessary to run the broad inhibition model on Mac and 
Windows operating systems. This folder also contains an example script simulating a response to amplitude
modulated noise using this model. 

#### SFIE Model 

The _"UR_EAR_2022a"_ folder is the release of the AN and SFIE model used in this manuscript. The _"model-SFIE"_ 
folder contains wrapper functions for the AN and SFIE models.

#### Energy Model 

The _"model-energy"_ folder contains gammatone filters used in the manuscript. This folder includes two example scripts
that run the model and output a figure either using a population of neurons or a single neuron with the sliding 
WB-TIN stimulus. 

### Data Format
Loading in a single putative neuron dataset will give you a 'data' variable. This variable is formatted like this:

| Index | Column 1  | Column 2 |
|-------|-----------|----------|
| 1     |           | bin      |
| 2     | rm_con    | rm bin   |
| 3     | mtf_con   | mtf bin  |
| 4     | strf_con  | strf bin |
| 5     | rvf       | schr     |
| 6     | st 43 con | st 43    |
| 7     | st 63 con | st 63    |
| 8     | st 73 con | st 73    |
| 9     | st 83 con | st 83    |
| 10    |           | st 43 100Hz |
| 11    |           | st 63 100Hz |
| 12    |           | st 83 100Hz |
| 13    |           | Oboe        |
| 14    |           | Bassoon     |
| 15    |           | Other nt    |
