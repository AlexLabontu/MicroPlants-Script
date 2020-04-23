Param(
    [Parameter(Mandatory)]
    [string]$File_Survey_Name,
    [switch]$Read_Survey = $false,
    [switch]$Suppress_Output = $false,
    [switch]$Show_Bad_Data = $false,
    [switch]$Fancy_output = $false,
    [string]$Prosessed_CSV,
    [float]$minimum = 0,
    [float]$maximum = 3,
    [int]$Time_Shift = 5
)
write-Host "Processing $File_Survey_Name"

if(!(test-path $File_Survey_Name)){
    write-Host "Cant get file"
    return
}


$File_First_Imported = import-CSV $File_Survey_Name

Class Custom_Import_Object{
    [DateTime] $Date;
    [string] $Event_Action;
    [string] $Event_Label;
    [string] $Total_Events;
    Custom_Import_Object($Input_Element) {
        $this.Date = [DateTime] "$($Input_Element.Date.Substring(4,2))/$($Input_Element.Date.Substring(6,2))/$($Input_Element.Date.Substring(0,4)) $($Input_Element.Hour):$($Input_Element.Minute)";
        $this.Event_Action = $Input_Element.'Event Action'.Substring(8);
        $this.Event_Label = $Input_Element.'Event Label'.Substring(11);
        $this.Total_Events = $Input_Element.'Total Events';
    }
}

Class Combine_Data{

    [string] $classification_id;
    [string] $username;
    [DateTime] $created_at;
    [string] $subject_data;
    [string] $subject_id;
    [string] $Seporator;
    [string] $angle;
    [string] $intersection_point_x;
    [string] $intersection_point_y;
    [string] $Seporator1;
    [string] $axis_length_major;
    [string] $major_x1;
    [string] $major_y1;
    [string] $major_x2;
    [string] $major_y2;
    [string] $Seporator2;
    [string] $axis_length_minor;
    [string] $minor_x1;
    [string] $minor_y1;
    [string] $minor_x2;
    [string] $minor_y2;
    [string] $Seporator3;
    [DateTime] $Date;
    [string] $Event_Action;
    [string] $Event_Label;
    [string] $Total_Events;
    [string] $Seporator4;
    [string] $client_width;
    [string] $client_hight;
    [string] $picture;


    Combine_Data($Input_Element,$Input_Second) {
        $this.classification_id = $Input_Element.classification_id;
        $this.username = $Input_Element.username;
        $this.created_at = $Input_Element.created_at;
        $this.subject_data = $Input_Element.subject_data;
        $this.subject_id = $Input_Element.subject_id;
        $this.Seporator = "";
        $this.angle = $Input_Element.angle;
        $this.intersection_point_x = $Input_Element.intersection_point_x;
        $this.intersection_point_y = $Input_Element.intersection_point_y;
        $this.Seporator1 = "";
        $this.axis_length_major = $Input_Element.axis_length_major;
        $this.major_x1 = $Input_Element.major_x1;
        $this.major_y1 = $Input_Element.major_y1;
        $this.major_x2 = $Input_Element.major_x2;
        $this.major_y2 = $Input_Element.major_y2;
        $this.Seporator2 = "";
        $this.axis_length_minor = $Input_Element.axis_length_minor;
        $this.minor_x1 = $Input_Element.minor_x1;
        $this.minor_y1 = $Input_Element.minor_y1;
        $this.minor_x2 = $Input_Element.minor_x2;
        $this.minor_y2 = $Input_Element.minor_y2;
        $this.Seporator3 = "";
        $this.Date = $Input_Second.Date;
        $this.Event_Action = $Input_Second.Event_Action;
        $this.Event_Label = $Input_Second.Event_Label;
        $this.Total_Events = $Input_Second.Total_Events;
        $this.Seporator4 = "";
        $this.client_width = $Input_Element.client_width;
        $this.client_hight = $Input_Element.client_hight;
        $this.picture = $Input_Element.picture;
    }
}


if(!($Read_Survey)){
    $File_Survay = @()
    $File_First_Imported | %{$File_Survay += [Custom_Import_Object]::new($_)}

    if ($Prosessed_CSV -ne $null -and $Prosessed_CSV -ne ""){
        $Global:File_Finished = Import-CSV $Prosessed_CSV
    }
    elseif($Global:Output_File -ne $null -and $Global:Output_File -ne ""){
        $Global:File_Finished = Import-CSV $Global:Output_File
        $Prosessed_CSV = $Output_File
    }
    else{
        write-Host "Cant get data"
        return
    }

    $global:File_Combined_Data = @()
    $touched = @()
    $last_id = -1
    $indx_cnter = 0
    foreach ($final_element in $File_Finished){
        if($Fancy_output){Write-Progress -Activity "Main Loop" -Status "Running the mile -> $indx_cnter / $($File_Finished.count)" -PercentComplete (($indx_cnter/$File_Finished.count)*100) -CurrentOperation "$($final_element.created_at)"}
        $indx_cnter += 1
        $final_element_DATE = ([DateTime]$final_element.created_at).AddHours($Time_Shift * -1)

        if($last_id -eq $final_element.classification_id){
            $global:File_Combined_Data += [Combine_Data]::new($final_element,$File_Survay[$touched[-1]])
            continue
        }
        elseif($last_id -eq (-1) -and (($final_element_DATE).year -lt $File_Survay[0].Date.year) -or ($final_element_DATE.month -lt $File_Survay[0].Date.month) -or ($final_element_DATE.day -lt $File_Survay[0].Date.day)){
            if($Show_Bad_Data){
                $global:File_Combined_Data += [Combine_Data]::new($final_element,@{Date="1/1/1";Event_Action="";Event_Label="";Total_Events=""})
            }
            continue
        }

        $last_good_index = -1

        Foreach ($entery_index in 0..($File_Survay.count - 1)){
            if($Fancy_output){Write-Progress -Id 1 -Activity "Inner loop" -Status "Looping in circles () $entery_index / $($File_Survay.count)" -PercentComplete (($entery_index/$File_Survay.count)*100) -CurrentOperation InnerLoop}
            if(($File_Survay[$entery_index].Date.year -eq $final_element_DATE.year) -and ($File_Survay[$entery_index].Date.month -eq $final_element_DATE.month) -and ($File_Survay[$entery_index].Date.day -eq $final_element_DATE.day)){

                $diff = ($final_element_DATE - $File_Survay[$entery_index].Date).TotalMinutes

                <#
                if($touched.IndexOf($entery_index) -eq -1){
                    #write-Host "$final_element_DATE   $($file_inter_med[$entery_index].Date)"
                    #write-Host $diff.TotalMinutes
                    if($minimum -ge $diff.TotalMinutes -and $diff.TotalMinutes -lt $maximum){
                        continue
                    }
                    $global:file_Export += [Custom_export_Object]::new($final_element,$file_inter_med[$entery_index])
                    $last_id = $final_element.classification_id
                    $touched += $entery_index
                    break
                }
                #>
                <#
                if($touched.IndexOf($entery_index) -eq -1){
                    if($minimum -le $diff -and $diff -le $maximum){
                        write-host "$($File_Survay[$entery_index].Date) -> $($diff) -> $final_element_DATE"
                        $global:File_Combined_Data += [Combine_Data]::new($final_element,$File_Survay[$entery_index])
                        $last_id = $final_element.classification_id
                        $touched += $entery_index
                        break
                    }
                }
                #>
                #<#
                write-debug "$($File_Survay[$entery_index].Date) -> $minimum -le  $($diff) -le $maximum -> $($final_element_DATE)"
                if($minimum -le $diff -and $diff -le $maximum){
                    $last_good_index = $entery_index
                }
                elseif($last_good_index -gt -1 -and $diff -lt $minimum){
                    break
                }
                #>
            }
        }
        write-debug "===================="
        #<#
        if($last_good_index -gt -1){
            $global:File_Combined_Data += [Combine_Data]::new($final_element,$File_Survay[$last_good_index])
            $last_id = $final_element.classification_id
            $touched += $last_good_index
            #break
        }
        #>
        if($last_id -ne $final_element.classification_id -and $Show_Bad_Data){
            $global:File_Combined_Data += [Combine_Data]::new($final_element,@{Date="1/1/1";Event_Action="";Event_Label="";Total_Events=""})
        }
    }

    if(!($Suppress_Output)){
        $global:File_Combined_Data | Export-Csv -Path "$($Prosessed_CSV)_combined.csv"
        write-Host "Wrote to file $($Prosessed_CSV)_combined.csv"
    }

    #$Global:File_Finished = $null
    $Global:File_Second = $null
    $Global:File_First_Imported = $null
    write-Host "Finished"
}
else{
    $global:File_Survay = @()
    $File_First_Imported | %{$global:File_Survay += [Custom_Import_Object]::new($_)}
}

function global:Gnplt_Item($working_item){
    try{$path = (Get-ChildItem -File $working_item.picture -Recurse)[0].FullName}catch{$path = $null}
    if($path -ne $null){
        $png = Format-Hex $path
        $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
        $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
        $x_scale = $w/$working_item.client_width
        $y_scale = $h/$working_item.client_hight
        $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set title 'gnplt Post-Process $indx';set key off;"
    }else{
        $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set title 'gnplt Post-Process $indx';set key off;"
        $h = 1000
        $w = 1000
        $x_scale = 1
        $y_scale = 1
    }
    $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 3;"
    $temp += "set arrow from $([int]$working_item.major_x1*$x_scale),$($h-([int]$working_item.major_y1*$y_scale)) to $([int]$working_item.major_x2*$x_scale),$($h-([int]$working_item.major_y2*$y_scale)) nohead front ls 1;"
    $temp += "set arrow from $([int]$working_item.minor_x1*$x_scale),$($h-([int]$working_item.minor_y1*$y_scale)) to $([int]$working_item.minor_x2*$x_scale),$($h-([int]$working_item.minor_y2*$y_scale)) nohead front ls 1;"

    if($path -ne $null){
        $temp += "plot '$path' binary filetype=jpg with rgbimage;"
    }
    else{
        $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
    }
    write-host "gnuplot -p -e `"$temp`""
    gnuplot -p -e "$temp"
}

function global:Get_Data_By_ID($ID){

        $global:Temp_Data = ($global:File_Combined_Data | where-Object {($_.subject_id -eq $ID) -and ($_.intersection_point_x -ne "<--->")})
        write-Host "Wrote to Value `$Temp_Data"

}

function global:Save_Data_From_Good_Leaf($Index){
    $good = $Temp_Data[$Index]
    ($global:Temp_Data | where-Object {(
        (((($good.major_x1 -lt $_.intersection_point_x) -and ($_.intersection_point_x -lt $good.major_x2)) -or
          (($good.major_x2 -lt $_.intersection_point_x) -and ($_.intersection_point_x -lt $good.major_x1))) -and
         ((($good.major_y1 -lt $_.intersection_point_y) -and ($_.intersection_point_y -lt $good.major_y2)) -or
          (($good.major_y2 -lt $_.intersection_point_y) -and ($_.intersection_point_y -lt $good.major_y1)))) -or
        (((($good.minor_x1 -lt $_.intersection_point_x) -and ($_.intersection_point_x -lt $good.minor_x2)) -or
          (($good.minor_x2 -lt $_.intersection_point_x) -and ($_.intersection_point_x -lt $good.minor_x1))) -and
         ((($good.minor_y1 -lt $_.intersection_point_y) -and ($_.intersection_point_y -lt $good.minor_y2)) -or
          (($good.minor_y2 -lt $_.intersection_point_y) -and ($_.intersection_point_y -lt $good.minor_y1))))
        )}) | Export-Csv -Path "$($good.subject_id)_$($Index)_DATA.csv"
   write-Host "Wrote to File '$($good.subject_id)_$($Index)_DATA.csv'"
}
function global:Gnplt_Temp($Index){
    $working_list = $Temp_Data[$Index]
    try{$path = (Get-ChildItem -File $working_list.picture -Recurse)[0].FullName}catch{$path = $null}
    if($path -ne $null){
        $png = Format-Hex $path
        $h = [int]($png[10].Bytes[3]*([Byte]::MaxValue+1) + $png[10].Bytes[4])
        $w = [int]($png[10].Bytes[5]*([Byte]::MaxValue+1) + $png[10].Bytes[6])
        $x_scale = $w/$working_list.client_width
        $y_scale = $h/$working_list.client_hight
        $temp = "set grid;set xrange [0:$w];set yrange [0:$h];set title 'gnplt Post-Process $indx';set key off;"
    }else{
        $temp = "set grid;set xrange [0:1000];set yrange [0:1000];set title 'gnplt Post-Process $indx';set key off;"
        $h = 1000
        $w = 1000
        $x_scale = 1
        $y_scale = 1
    }
    $temp += "set style line 1 lc rgb '#FF0000' lt 1 lw 3;"
    $temp += "set arrow from $([int]$working_list.major_x1*$x_scale),$($h-([int]$working_list.major_y1*$y_scale)) to $([int]$working_list.major_x2*$x_scale),$($h-([int]$working_list.major_y2*$y_scale)) nohead front ls 1;"
    $temp += "set arrow from $([int]$working_list.minor_x1*$x_scale),$($h-([int]$working_list.minor_y1*$y_scale)) to $([int]$working_list.minor_x2*$x_scale),$($h-([int]$working_list.minor_y2*$y_scale)) nohead front ls 1;"

    if($path -ne $null){
        $temp += "plot '$path' binary filetype=jpg with rgbimage;"
    }
    else{
        $temp += "plot [0:1000](0,x) lt rgb '#FFFFFFFF';"
    }
    write-host "gnuplot -p -e `"$temp`""
    gnuplot -p -e "$temp"
}
<#
$wlist = $File_Combined_Data | Where-Object{$_.subject_id -eq "8735428"}
$wlist | %{Gnplt_Item($_);Start-Sleep -Seconds 1;}

$good = $wlist[4]

$valid = $wlist | where-Object{
   (((($good.major_x1 -lt $_.intersection_point_x) -and ($_.intersection_point_x -lt $good.major_x2)) -or
    (($good.major_x2 -lt $_.intersection_point_x) -and ($_.intersection_point_x -lt $good.major_x1))) -and
    ((($good.major_y1 -lt $_.intersection_point_y) -and ($_.intersection_point_y -lt $good.major_y2)) -or
    (($good.major_y2 -lt $_.intersection_point_y) -and ($_.intersection_point_y -lt $good.major_y1))))}




    $aaa = $File_Finished | Where-Object{$_.picture -eq "" -and ($_.intersection_point_x -ne "<--->" -and $_.intersection_point_y -ne "<--->")}

#>
