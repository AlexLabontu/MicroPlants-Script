    
	
The objective of the Micro-plant scripts is to allow bulk possessing of the data and extraction of key data points from data dumps. The user feeds in CSV data taken from the terminal within the museum and then generates a new CSV file containing fixes. The scripts utilize Powershell as the engine to process the data. The way Powershell works for easy importation of the CSV data structure and manipulation and creation of other data structures. The scripts also utilize GNU plot as the visual component of data checking. Here are the three required programs needed the utilize all aspects of the script:

	* Powershell
	* GNU plot
	* Spread sheet viewer

# ./first.ps1
The intent of the first script is to funnel the data dump into the format that Vickie’s app was meant to. As a class, we found that Vickie’s app had numerous mistakes when processing the data and technical issues when importing or exporting the data. The first script solves the web app issues and improves the accuracy of the data filtering. 

When running this script, the user must specify the Raw Kiosk Data file for the script to use. The script will run through many loops processing the data. This may take some time. Then the script will create a new CSV containing the data in a file with the same name but with ‘_processed.csv’ attached.
	
# Flags:
    • [string]Raw_Kiosk_Data_File – Required – This flag needs to be fallowed by the path to the raw data dump
    • [switch]Show_Bad_Data – If this flag exists, then any data that would be filtered out due to bad angles or due to not having any usable data will be kept and substituted with ‘<---->’
    • [switch]Suppress_Output – Prevents the creation of an output CSV

# Global Variables:
    • $Input_file – Stores the name of the file first used.
    • $File_First – Stores the initial values imported from the initial file. 
        ◦ Created only if the Suppress_Output flag exists
    • $File_Second – Stores the extracted data but with the crosses in one list. 
        ◦ Created only if the Suppress_Output flag exists
    • $File_Finished – Stores the data with the crosses separated as its own entary. This is the data structure that is used to create the output file.
        ◦ Created only if the Suppress_Output flag exists
    • $Output_File – Stores the name of the file was created.

# Functions
Only if Suppress_Output exists:

    • Gnplt($index) – Plots both items from $File_First and $File_Second. The index is used to indicate what item you want to graph in reference to either the First or Second data sets
    • Gnplt_First($index) – Plots items from $File_First The index is used to indicate what item you want to graph in reference to the First data sets
    • Gnplt_Second($index) - Plots items from $File_Second The index is used to indicate what item you want to graph in reference to the Second data sets
    • Gnplt_Finished($index) - Plots items from $File_Finished The index is used to indicate what item you want to graph in reference to the Finished data sets

# ./second.ps1
The objective of the second script is to take in the information from the first script and match it to the survey data collected by the intern. The script uses the $Output_File variable or Prosessed_CSV flag as the input file.  An output CSV will be created using the name of the input file with ‘_combined.csv’ appended to the name. 

# Flags:
    • [string]File_Survey_Name – Required – This flag must be fallowed by the path to the survey file gathered by the interns
    • [switch]read_survay – This flag tells the script to put the Survey file in $File_Survay and do nothing else.
    • [switch]Suppress_Output – This flag prevents the creation of the output file.
    • [switch]Show_Bad_Data – Use this flag to include data that would have been filtered out.
    • [switch]Fancy_Output – Visualizes the progress of the script. This does slow down the computer.
    • [string]Prosessed_CSV – This flag must be fallowed by the path to the Processed survey file from the first script. This flag allows this script to run independent from the first script.
    • [float]minimum – Adjust the minimum difference between 2 data sets to indicate a match.
    • [float]maximum – adjust the maximum difference between 2 data sets to indicate a match
    • [int]Time_Shift – equivalent to adjusting for time zones

# Global Variables:
    • $File_Finished – Contains the information from the Processed CSV. Creates the variable if the first script did not run.
    • $File_Combined_Data – Contains the data that will be outputted to exported CSV
    • $File_First_Imported – Contains the data from the survey when read_survay flag is present.
    • $Temp_Data– stores filtered data from the Get_Data_By_ID function.

# Functions:
    • Gnplt_Item($working_item) – Plots the item from $File_Combined_Data by an object
    • Get_Data_By_ID($ID) – Extracts all items from $File_Combined_Data with ID’s similar the the parameter. The data is stored in $Temp_data 
    • Gnplt_Temp($Index) – Plots items by index from the $Temp_data file
    • Save_Data_From_Good_Leaf($Index) – After finding a good measurement by index, this function will grab all crosses who’s intersection point is within the indexed cross area. 
