Param(
    [Parameter(Mandatory)]
    [string]$Raw_Kiosk_Data_File,
    [switch]$Show_Bad_Data = $false,
    [switch]$Suppress_Output = $false
)
write-Host "Processing $Raw_Kiosk_Data_File"

if(!(test-path $Raw_Kiosk_Data_File)){
    write-Host "Cant get file"
    return
}

$File_Raw_Data = import-CSV $Raw_Kiosk_Data_File


<#>
 # This data data structure contains the code that takes the data from the Raw
 # data dump into something that the user finds usefull
 #
 #
<#>
Class Data_Raw_To_Processed{
    [string] $classification_id;
    [string] $username;
    [DateTime] $created_at;
    [string] $subject_data;
    [string] $subject_id;
    [array] $angle;
    [array] $intersection_point_x;
    [array] $intersection_point_y;
    [array] $axis_length;
    [array] $crosse;
    [string] $picture;
    [int] $client_width;
    [int] $client_hight;

    # Constructor
    Data_Raw_To_Processed($Input_Element,$Show_Bad_Data) {

        <#
            $Input_Element = $File_First[26]
        #>

        # Declare Temp Varaibles and its type
        $line_list = @();
        $cross_list = @();
        $line_length_list = @();
        $angle_list = @();
        $intercept_x_list = @();
        $intercept_y_list = @();
        $checked_index_list = @();

        # Makes each line in the annotations a usable data structure
        $Input_Element.annotations.value | %{
            $line_list += @{x1=$_.x1;y1=$_.y1;x2=$_.x2;y2=$_.y2};
        }

        # This loop goes through every item except for the last item and checks
        # if there are intersections, then its added to the cross varaible.
        foreach ($major_inx in 0..($line_list.Count-2)){

            # Checks if the line was priviously included
            if($checked_index_list -contains $major_inx){continue}

            # gets the Major M and B value for
            # y = M*x+B
            if(($line_list[$major_inx].x2 - $line_list[$major_inx].x1) -eq 0){$major_M = 99999999}else{
                $major_M = ($line_list[$major_inx].y2 - $line_list[$major_inx].y1)/($line_list[$major_inx].x2 - $line_list[$major_inx].x1);
            }
            $major_B = $line_list[$major_inx].y1 - ($major_M*$line_list[$major_inx].x1);

            # this loops through the list again but excluding the first element
            # and starting off where parent loop is at
            foreach ($minor_inx in ($major_inx+1)..($line_list.Count-1)){

                # gets the Minor M and B value for
                # y = M*x+B
                if($checked_index_list -contains $minor_inx){continue}
                if(($line_list[$minor_inx].x2 - $line_list[$minor_inx].x1) -eq 0){$minor_M = 99999999}else{
                    $minor_M = ($line_list[$minor_inx].y2 - $line_list[$minor_inx].y1)/($line_list[$minor_inx].x2 - $line_list[$minor_inx].x1);
                }
                $minor_B = $line_list[$minor_inx].y1 - ($minor_M*$line_list[$minor_inx].x1);

                # The fallowing code gets both X and Y intersections point of
                # the Major and Minor.
                try{
                    $temp_xInt = (((($line_list[$major_inx].x1*$line_list[$major_inx].y2)-($line_list[$major_inx].y1*$line_list[$major_inx].x2))*(($line_list[$minor_inx].x1)-($line_list[$minor_inx].x2)))`
                                 -((($line_list[$major_inx].x1)-($line_list[$major_inx].x2))*(($line_list[$minor_inx].x1*$line_list[$minor_inx].y2)-($line_list[$minor_inx].y1*$line_list[$minor_inx].x2))))`
                                /(((($line_list[$major_inx].x1)-($line_list[$major_inx].x2))*(($line_list[$minor_inx].y1)-($line_list[$minor_inx].y2)))`
                                 -((($line_list[$major_inx].y1)-($line_list[$major_inx].y2))*(($line_list[$minor_inx].x1)-($line_list[$minor_inx].x2))));
                }catch{
                    $temp_xInt += $null;
                }try{
                    $temp_yInt = (((($line_list[$major_inx].x1*$line_list[$major_inx].y2)-($line_list[$major_inx].y1*$line_list[$major_inx].x2))*(($line_list[$minor_inx].y1)-($line_list[$minor_inx].y2)))`
                                 -((($line_list[$major_inx].y1)-($line_list[$major_inx].y2))*(($line_list[$minor_inx].x1*$line_list[$minor_inx].y2)-($line_list[$minor_inx].y1*$line_list[$minor_inx].x2))))`
                                /(((($line_list[$major_inx].x1)-($line_list[$major_inx].x2))*(($line_list[$minor_inx].y1)-($line_list[$minor_inx].y2)))`
                                 -((($line_list[$major_inx].y1)-($line_list[$major_inx].y2))*(($line_list[$minor_inx].x1)-($line_list[$minor_inx].x2))));
                }catch{
                    $temp_yInt += $null;
                }

                # Checks if the intersections are between the points of the
                # Major and Minor lines and Calculates the rest of the data
                if(((($line_list[$major_inx].x1 -le $temp_xInt -and $temp_xInt -le $line_list[$major_inx].x2) -or
                     ($line_list[$major_inx].x2 -le $temp_xInt -and $temp_xInt -le $line_list[$major_inx].x1)) -and
                    (($line_list[$major_inx].y1 -le $temp_yInt -and $temp_yInt -le $line_list[$major_inx].y2) -or
                     ($line_list[$major_inx].y2 -le $temp_yInt -and $temp_yInt -le $line_list[$major_inx].y1))) -and
                   ((($line_list[$minor_inx].x1 -le $temp_xInt -and $temp_xInt -le $line_list[$minor_inx].x2) -or
                     ($line_list[$minor_inx].x2 -le $temp_xInt -and $temp_xInt -le $line_list[$minor_inx].x1)) -and
                    (($line_list[$minor_inx].y1 -le $temp_yInt -and $temp_yInt -le $line_list[$minor_inx].y2) -or
                     ($line_list[$minor_inx].y2 -le $temp_yInt -and $temp_yInt -le $line_list[$minor_inx].y1)))
                 ){
                    # Gets the angle of the data and filters it out if it is bad
                    try{
                         $temp_Angle = [math]::abs(([math]::Atan((($major_M - $minor_M) * (-1))/(1+($major_M*$minor_M)))*180)/[math]::PI);
                         if(80 -le $temp_Angle -and $temp_Angle -le 100){
                             $angle_list += $temp_Angle
                         }
                         else{
                            if(!($Show_Bad_Data)){
                                $checked_index_list += $minor_inx
                                $checked_index_list += $major_inx
                                continue
                            }
                            $angle_list += $temp_Angle
                        }
                    }catch{$angle_list += $null;}

                    # Populates the remaining variables in the Temp variables

                    $cross_list += @{major=$line_list[$major_inx];minor=$line_list[$minor_inx]};
                    $intercept_x_list += $temp_xInt
                    $intercept_y_list += $temp_yInt
                    $line_length_list += [math]::Sqrt([math]::Pow($line_list[$major_inx].x1-$line_list[$major_inx].x2,2) + [math]::Pow($line_list[$major_inx].y1-$line_list[$major_inx].y2,2));
                    $line_length_list += [math]::Sqrt([math]::Pow($line_list[$minor_inx].x1-$line_list[$minor_inx].x2,2) + [math]::Pow($line_list[$minor_inx].y1-$line_list[$minor_inx].y2,2));
                    $checked_index_list += $minor_inx
                    $checked_index_list += $major_inx

                    # breaks the loop and moves on to the next data set
                    break;
                }
            }
        }

        # Takes the temp varaibles above and setting it to the data structure
        $this.classification_id = $Input_Element.classification_id;
        $this.username = $Input_Element.user_name;
        try{$this.created_at = "$($Input_Element.created_at.Substring(5,2))/$($Input_Element.created_at.Substring(8,2))/$($Input_Element.created_at.Substring(0,4)) $($Input_Element.created_at.Substring(11,5))";
        }catch{$this.created_at = "1/1/1"};
        $this.subject_data = $Input_Element.subject_data;
        $this.subject_id = $Input_Element.subject_ids;
        $this.angle = $angle_list;
        $this.intersection_point_x = $intercept_x_list;
        $this.intersection_point_y = $intercept_y_list;
        $this.axis_length = $line_length_list;
        $this.crosse = $cross_list;

        # tries to find the pictures and add them to the Data structure
        if($Input_Element.subject_data.IndexOf('image_name') -ne -1){
            $temp_idx = $Input_Element.subject_data.IndexOf(':',$Input_Element.subject_data.IndexOf('image_name'))+2;
            $this.picture = $Input_Element.subject_data.Substring($temp_idx,$Input_Element.subject_data.IndexOf('"',$temp_idx)-$temp_idx);
        }elseif($Input_Element.subject_data.IndexOf('Filename') -ne -1){
            $temp_idx = $Input_Element.subject_data.IndexOf(':',$Input_Element.subject_data.IndexOf('Filename'))+2;
            $this.picture = $Input_Element.subject_data.Substring($temp_idx,$Input_Element.subject_data.IndexOf('"',$temp_idx)-$temp_idx);
        }else{
            $this.picture = "";
        }
        $this.client_width = $Input_Element.metadata.subject_dimensions.naturalWidth;
        $this.client_hight = $Input_Element.metadata.subject_dimensions.naturalHeight;
    }
}


<#>
 # This data structure takes the Input data and polishes it up for shipment
 #
 #
 #
<#>
Class Data_Processed_to_Finished{
    [string] $classification_id;
    [string] $username;
    [DateTime] $created_at;
    [string] $subject_data;
    [string] $subject_id;
    [string] $angle;
    [string] $intersection_point_x;
    [string] $intersection_point_y;
    [string] $axis_length_major;
    [string] $major_x1;
    [string] $major_y1;
    [string] $major_x2;
    [string] $major_y2;
    [string] $axis_length_minor;
    [string] $minor_x1;
    [string] $minor_y1;
    [string] $minor_x2;
    [string] $minor_y2;
    [string] $picture;
    [string] $client_width;
    [string] $client_hight;

    # constructor
    Data_Processed_to_Finished($Input_Element,$index){

        $this.classification_id = $Input_Element.classification_id;
        $this.username = $Input_Element.username;
        $this.created_at = $Input_Element.created_at;
        $this.subject_data = $Input_Element.subject_data;
        $this.subject_id = $Input_Element.subject_id;

        # If there is no value, a place holder value will be put in its place
        # Easy to filter for
        if($Input_Element.angle[$index] -ne $null){
            $this.angle = $Input_Element.angle[$index];
        }else{
            $this.angle = "<--->";
        }
        if($Input_Element.intersection_point_x[$index] -ne $null){
            $this.intersection_point_x = $Input_Element.intersection_point_x[$index];
        }else{
            $this.intersection_point_x = "<--->";
        }

        if($Input_Element.intersection_point_y[$index] -ne $null){
            $this.intersection_point_y = $Input_Element.intersection_point_y[$index];
        }else{
            $this.intersection_point_y = "<--->";
        }

        # Makes the longer line the Major
        if($Input_Element.axis_length[(2*$index)] -ge $Input_Element.axis_length[(2*$index)+1]){
            $this.axis_length_major = $Input_Element.axis_length[(2*$index)];
            $this.major_x1 = $Input_Element.crosse[$index].major.x1;
            $this.major_y1 = $Input_Element.crosse[$index].major.y1;
            $this.major_x2 = $Input_Element.crosse[$index].major.x2;
            $this.major_y2 = $Input_Element.crosse[$index].major.y2;
            $this.axis_length_minor = $Input_Element.axis_length[(2*$index)+1];
            $this.minor_x1 = $Input_Element.crosse[$index].minor.x1;
            $this.minor_y1 = $Input_Element.crosse[$index].minor.y1;
            $this.minor_x2 = $Input_Element.crosse[$index].minor.x2;
            $this.minor_y2 = $Input_Element.crosse[$index].minor.y2;
        }else{
            $this.axis_length_major = $Input_Element.axis_length[(2*$index)+1];
            $this.major_x1 = $Input_Element.crosse[$index].major.x1;
            $this.major_y1 = $Input_Element.crosse[$index].major.y1;
            $this.major_x2 = $Input_Element.crosse[$index].major.x2;
            $this.major_y2 = $Input_Element.crosse[$index].major.y2;
            $this.axis_length_minor = $Input_Element.axis_length[(2*$index)];
            $this.minor_x1 = $Input_Element.crosse[$index].minor.x1;
            $this.minor_y1 = $Input_Element.crosse[$index].minor.y1;
            $this.minor_x2 = $Input_Element.crosse[$index].minor.x2;
            $this.minor_y2 = $Input_Element.crosse[$index].minor.y2;
        }
        $this.picture = $Input_Element.picture;
        $this.client_width = $Input_Element.client_width;
        $this.client_hight = $Input_Element.client_hight;
    }
}

# takes in the data from the Raw data file and turnes the annotations and
# metadata to a usable data structure. This is why I wanted to use powershell!!!
$File_Raw_Data | %{
    try{
        $_.metadata = ConvertFrom-Json $_.metadata
    }catch{
        write-Host "Metadata Error: $($_.metadata)"
    }
    try{
        $_.annotations = ConvertFrom-Json $_.annotations
    }catch{
        write-Host "Annotations Error: $($_.annotations)"
    }
  #$_.subject_data = ConvertFrom-Json $_.subject_data
}

# pumps the data into the Data_Raw_To_Processed data structure
$File_Processed_Data = @()
$File_Raw_Data | %{$File_Processed_Data += [Data_Raw_To_Processed]::new($_,$Show_Bad_Data)}

$File_Finished_Data = @()
$indx_cnter = 0
foreach($element in $File_Processed_Data){
    Write-Progress -Activity "Processing Data" -Status " Complete: $indx_cnter / $($File_Processed_Data.count)" -PercentComplete (($indx_cnter/$File_Processed_Data.count)*100);
    $indx_cnter += 1
    try{$a = [int]$element.classification_id;$a = [int]$element.subject_id}catch{continue}
    if ($element.crosse.Count -eq 0 -and !$Show_Bad_Data){continue}
    if($element.crosse.Count -eq 0){
        $File_Finished_Data += [Data_Processed_to_Finished]::new($element,0)
        continue
    }
    foreach ($ndx in (0..($element.crosse.Count-1))){
        $File_Finished_Data += [Data_Processed_to_Finished]::new($element,$ndx)
    }
}

if(!($Suppress_Output)){
    if($Show_Bad_Data){
        $File_Finished_Data | Export-Csv -Path "$($Raw_Kiosk_Data_File)_processed_bad.csv"
        write-Host "Saving file to $($Raw_Kiosk_Data_File)_processed_bad.csv"
    }else{
        $File_Finished_Data | Export-Csv -Path "$($Raw_Kiosk_Data_File)_processed_good.csv"
        write-Host "Saving file to $($Raw_Kiosk_Data_File)_processed_good.csv"
    }
}else{
    $Global:File_Finished = $File_Finished_Data
    $Global:File_Second = $File_Processed_Data
    $Global:File_First = $File_Raw_Data
    write-Host "Created 3 variables,`n`t`$File_Finished`t`$File_Second`t`$File_First"

    write-Host "Created 4 functions,`n`tGnplt(INDEX)`tGnplt_Finished(INDEX)`tGnplt_Second(INDEX)`tGnplt_First(INDEX)"

    # ./main.ps1 -file_name "/home/alex/Downloads/classifications_short.csv" -supress_output
    function global:Gnplt($indx){
        try{$path = (Get-ChildItem -File $File_Second[$indx].picture -Recurse)[0].FullName}catch{$path = $null}
        if($path -ne $null){
            $png = Format-Hex $path
            $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
            $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
            $x_scale = $w/$File_Second[$indx].client_width
            $y_scale = $h/$File_Second[$indx].client_hight
            $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set key off;"
        }else{
            $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set key off;"
            $h = 1000
            $w = 1000
            $x_scale = 1
            $y_scale = 1
        }
        $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 2;"
        $temp += "set multiplot layout 1,2 rowsfirst;"
        $temp += "set title 'gnplt first $indx';"
        $inc = 0
        $File_First[$indx].annotations.value | %{
            $temp += "set arrow from $($_.x1*$x_scale),$($h-($_.y1*$y_scale)) to $($_.x2*$x_scale),$($h-($_.y2*$y_scale)) nohead front ls 1;"
            $temp += "set label $($inc+1) at $($_.x1*$x_scale),$($h-($_.y1*$y_scale)+30) '$inc' front;";$inc += 1
        }
        if($path -ne $null){
            $temp += "plot '$path' binary filetype=jpg with rgbimage;"
        }
        else{
            $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
        }
        $temp += "set title 'gnplt inter $indx';"
        $inc = 0
        $File_Second[$indx].crosse | %{
            $temp += "set arrow from $($_.major.x1*$x_scale),$($h-($_.major.y1*$y_scale)) to $($_.major.x2*$x_scale),$($h-($_.major.y2*$y_scale)) nohead front ls 1;"
            $temp += "set label $($inc+1+$File_First[$indx].annotations.value.count) at $($_.major.x1*$x_scale),$($h-($_.major.y1*$y_scale)+30) '$inc' front;";$inc += 1
            $temp += "set arrow from $($_.minor.x1*$x_scale),$($h-($_.minor.y1*$y_scale)) to $($_.minor.x2*$x_scale),$($h-($_.minor.y2*$y_scale)) nohead front ls 1;"
            $temp += "set label $($inc+1+$File_First[$indx].annotations.value.count) at $($_.minor.x1*$x_scale),$($h-($_.minor.y1*$y_scale)+30) '$inc' front;";$inc += 1
        }
        if($path -ne $null){
            $temp += "plot '$path' binary filetype=jpg with rgbimage;"
        }
        else{
            $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
        }
        $temp += "unset multiplot;"
        write-host "gnuplot -p -e `"$temp`""
        gnuplot -p -e "$temp"
    }
    function global:Gnplt_Finished($indx){
        try{$path = (Get-ChildItem -File $File_Finished[$indx].picture -Recurse)[0].FullName}catch{$path = $null}
        if($path -ne $null){
            $png = Format-Hex $path
            $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
            $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
            $x_scale = $w/$File_Finished[$indx].client_width
            $y_scale = $h/$File_Finished[$indx].client_hight
            $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set title 'gnplt final $indx';set key off;"
        }else{
            $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set title 'gnplt final $indx';set key off;"
            $h = 1000
            $w = 1000
            $x_scale = 1
            $y_scale = 1
        }
        $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 3;"
        $temp += "set arrow from $([int]$File_Finished[$indx].major_x1*$x_scale),$($h-([int]$File_Finished[$indx].major_y1*$y_scale)) to $([int]$File_Finished[$indx].major_x2*$x_scale),$($h-([int]$File_Finished[$indx].major_y2*$y_scale)) nohead front ls 1;"
        $temp += "set arrow from $([int]$File_Finished[$indx].minor_x1*$x_scale),$($h-([int]$File_Finished[$indx].minor_y1*$y_scale)) to $([int]$File_Finished[$indx].minor_x2*$x_scale),$($h-([int]$File_Finished[$indx].minor_y2*$y_scale)) nohead front ls 1;"

        if($path -ne $null){
            $temp += "plot '$path' binary filetype=jpg with rgbimage;"
        }
        else{
            $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
        }
        write-host "gnuplot -p -e `"$temp`""
        gnuplot -p -e "$temp"
    }
    function global:Gnplt_Second($indx){
        try{$path = (Get-ChildItem -File $File_Second[$indx].picture -Recurse)[0].FullName}catch{$path = $null}
        if($path -ne $null){
            $png = Format-Hex $path
            $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
            $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
            $x_scale = $w/$File_Second[$indx].client_width
            $y_scale = $h/$File_Second[$indx].client_hight
            $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set title 'gnplt inter $indx';set key off;"
        }else{
            $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set title 'gnplt inter $indx';set key off;"
            $h = 1000
            $w = 1000
            $x_scale = 1
            $y_scale = 1
        }
        $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 3;"
        $inc = 0
        $File_Second[$indx].crosse | %{
            $temp += "set arrow from $($_.major.x1*$x_scale),$($h-($_.major.y1*$y_scale)) to $($_.major.x2*$x_scale),$($h-($_.major.y2*$y_scale)) nohead front ls 1;"
            $temp += "set label $($inc+1) at $($_.major.x1*$x_scale),$($h-($_.major.y1*$y_scale)+30) '$inc' front;";$inc += 1
            $temp += "set arrow from $($_.minor.x1*$x_scale),$($h-($_.minor.y1*$y_scale)) to $($_.minor.x2*$x_scale),$($h-($_.minor.y2*$y_scale)) nohead front ls 1;"
            $temp += "set label $($inc+1) at $($_.minor.x1*$x_scale),$($h-($_.minor.y1*$y_scale)+30) '$inc' front;";$inc += 1
        }
        if($path -ne $null){
            $temp += "plot '$path' binary filetype=jpg with rgbimage;"
        }
        else{
            $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
        }
        write-host "gnuplot -p -e `"$temp`""
        gnuplot -p -e "$temp"
    }
    function global:Gnplt_First($indx){
        try{$path = (Get-ChildItem -File $File_Second[$indx].picture -Recurse)[0].FullName}catch{$path = $null}
        if($path -ne $null){
            $png = Format-Hex $path
            $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
            $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
            $x_scale = $w/$File_Second[$indx].client_width
            $y_scale = $h/$File_Second[$indx].client_hight
            $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set title 'gnplt first $indx';set key off;"
        }else{
            $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set title 'gnplt first $indx';set key off;"
            $h = 1000
            $w = 1000
            $x_scale = 1
            $y_scale = 1
        }
        $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 3;"
        $inc = 0
        $File_First[$indx].annotations.value | %{
            $temp += "set arrow from $($_.x1*$x_scale),$($h-($_.y1*$y_scale)) to $($_.x2*$x_scale),$($h-($_.y2*$y_scale)) nohead front ls 1;"
            $temp += "set label $($inc+1) at $($_.x1*$x_scale),$($h-($_.y1*$y_scale)+30) '$inc' front;";$inc += 1
        }
        #<#
        if($path -ne $null){
            $temp += "plot '$path' binary filetype=jpg with rgbimage;"
        }
        else{
            $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
        }
        write-host "gnuplot -p -e `"$temp`""
        gnuplot -p -e "$temp"
    }
}
$global:Input_File = $Raw_Kiosk_Data_File
if($Show_Bad_Data){
    $global:Output_File = "$($Raw_Kiosk_Data_File)_processed_bad.csv"
}else{
    $global:Output_File = "$($Raw_Kiosk_Data_File)_processed_good.csv"
}



<#
$global:File_Finished = Import-Csv "./microplants-classifications_kiosk_Aug_2018_latest data dump.csv_processed_bad.csv"

function global:gnplt_Item($item_Index){
    try{$path = (Get-ChildItem -File $item_Index.picture -Recurse)[0].FullName}catch{$path = $null}
    if($path -ne $null){
        $png = Format-Hex $path
        $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
        $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
        $x_scale = $w/$item_Index.client_width
        $y_scale = $h/$item_Index.client_hight
        $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set title 'gnplt final $indx';set key off;"
    }else{
        $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set title 'gnplt final $indx';set key off;"
        $h = 1000
        $w = 1000
        $x_scale = 1
        $y_scale = 1
    }
    $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 3;"
    $temp += "set arrow from $([int]$item_Index.major_x1*$x_scale),$($h-([int]$item_Index.major_y1*$y_scale)) to $([int]$item_Index.major_x2*$x_scale),$($h-([int]$item_Index.major_y2*$y_scale)) nohead front ls 1;"
    $temp += "set arrow from $([int]$item_Index.minor_x1*$x_scale),$($h-([int]$item_Index.minor_y1*$y_scale)) to $([int]$item_Index.minor_x2*$x_scale),$($h-([int]$item_Index.minor_y2*$y_scale)) nohead front ls 1;"

    if($path -ne $null){
        $temp += "plot '$path' binary filetype=jpg with rgbimage;"
    }
    else{
        $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
    }
    write-host "gnuplot -p -e `"$temp`""
    gnuplot -p -e "$temp"
}
$wlist1 = $File_Finished | Where-Object{$_.subject_id -eq "8735428"}
$wlist2 = $File_Finished | Where-Object{$_.subject_id -eq "8735474"}
$wlist3 = $File_Finished | Where-Object{$_.subject_id -eq "8735482"}

0..25 | %{gnplt_Item($wlist1[$_]);start-sleep -Seconds 1}
0..25 | %{gnplt_Item($wlist2[$_]);start-sleep -Seconds 1}
0..25 | %{gnplt_Item($wlist3[$_]);start-sleep -Seconds 1}

#>
