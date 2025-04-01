# CV-TR2
Computer vision project about quality inspection and object detection of materials through recognition algorithms


**CV_IntensityAnalysis.m**: to find the ROI of objects by stabilizing threshold and trigger time
**CV_PlotsBox.m**: moltitude of plots about the ROIs founded (also extra visualization tools)
**CV_PreProcessSWIR.m**: showing a variety of filters appliable to the raw image data
**CV_RoiFeatureExtraction**: takes ROIs got from **CV_IntensityAnalysis.m** saved in a .xslx and print in another .xlsx all the features exctractable from data

Pipeline:
1. The image is preprocessed: segmentation and statistical data extraction is carried out (**CV_ImageProcessing.m**)
2. The data are analyzed to distinguish good objects from those to be discarded (**CV_DataPlotAnalysis.m**)