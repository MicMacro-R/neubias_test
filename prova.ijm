/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Name: intersection_v1
 * Author: Michela Roccuzzo
 * Affiliation:	Advanced Imaging Core facility (AICF) of CIBIO Department - University of Trento
 * Version: 1	Date: 23/05/2023
 * User: Federica Casiraghi (Hanczyc lab)
 *
 * Description: This is an automatic pipeline.
 * 				All the images to be analyzed should be grouped in the input folder.
 * 				Single images are 2 channels (C1-green, C2-red), no z-stack.
 * 				Threshold values for C1/C2 segmentation must be set by the user.
 * 				Area of the intersection of green and red [min(green, red)] is calculated.
 * 
 * Output: 	1) one Results tab with the intersection area of green and red channels, calculated for each image in the input folder.
 * 
 */
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function to close a selected window
function clean(image){
	selectWindow(image);
	close();
}

run("Set Measurements...", "area limit redirect=None decimal=3");

arrayName = newArray(0);
arrayArea = newArray(0);

inputDir = getDirectory ("select_input_folder");
outputDir = inputDir + "Results_intersection analysis"+ File.separator;
File.makeDirectory(outputDir);

filelist = getFileList(inputDir);
for (d=0; d<lengthOf(filelist); d++) {
		if (endsWith(filelist[d], ".zvi")) {
			image=filelist[d];
			path=inputDir+image;
			run("Bio-Formats Importer", "open=&path autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
			title=getTitle();
			shortTitle=File.nameWithoutExtension;
			arrayName=Array.concat(arrayName,shortTitle);
			run("Split Channels");
			
			//green ch pre processing and thresholding
			selectWindow("C1-"+title);rename("green");
			run("Despeckle");
			run("Subtract Background...", "rolling=200");
			run("Gaussian Blur...", "sigma=3");
			setAutoThreshold("Otsu dark");
			setOption("BlackBackground", false);
			run("Convert to Mask");
			waitForUser;
			
			//red ch pre processing and thresholding
			selectWindow("C2-"+title);rename("red");
			run("Despeckle");
			run("Subtract Background...", "rolling=200");
			run("Gaussian Blur...", "sigma=3");
			setAutoThreshold("Otsu dark");
			setOption("BlackBackground", false);
			run("Convert to Mask");
			waitForUser;

			//create intetsection area
			imageCalculator("Min create", "green","red");
			setAutoThreshold("Otsu");
			rename("interesction");
			waitForUser;
			
			run("Measure");
			Area = getResult("Area", 0);
			run("Clear Results");
			arrayArea=Array.concat(arrayArea,Area);
			
			clean("green");
			clean("red");
			clean("interesction");
			
			}
		}

//create and save results tab
Table.create("intersection area_Results");
print("[intersection area_Results]", "\\Headings:"+"Image \t intersection area");
Table.setColumn("Image", arrayName);
Table.setColumn("intersection area", arrayArea);
Table.update;
saveAs("Results", outputDir + "intersection area_Results" + ".csv");
run("Close");

showMessage("Done!");


