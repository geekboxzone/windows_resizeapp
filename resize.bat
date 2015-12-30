@echo off & color 0d & setlocal enabledelayedexpansion 

set "partition1_t=0"
set "partition2_t=0"
set "app_partition_t=0"
set "app_size_t=0"
set "app_offset_t=0"
set "mid_partition_t=0"
set "mid_name_t=0"
set "mid_size_t=0"
set "mid_offset_t=0"
set "end_partition_t=0"
set "end_name_t=0"
set "end_size_t=0"
set "end_offset_t=0"
set "app_size_dec_t=0"
set "app_size_dec_to_section=0"
set "mid_offset_dec=0"
set "end_offset_dec=0"
set "partition0_t=0"

rd /q /s output>nul
mkdir output
echo Start to unpack update.img...
if not exist "update.img" (
		echo Error:No found update.img!
		pause
		exit
		)
RKImageMaker.exe -unpack update.img output || pause
AFPTool.exe -unpack output/firmware.img output || pause
del /a /f /q "output\firmware.img"
del /a /f /q "output\boot.bin"
echo Unpacking update.img OK.
grep -e parameter output/package-file | cut.exe -f 2 > parameter_file
set /p parameter_f=<parameter_file
del /a /f /q "parameter_file"


mkdir tmp
grep userdata output/%parameter_f% | awk -F "userdata" '{print $1}' > tmp/partition1
call:myDosFunc tmp/partition1 partition1_t


grep userdata output/%parameter_f% | awk -F "userdata" '{print $2}' > tmp/partition2
call:myDosFunc tmp/partition2 partition2_t


cat tmp/partition1 | awk -F"," '{print $NF}' | awk -F"(" '{print $1}' > tmp/app_partition
call:myDosFunc tmp/app_partition app_partition_t


cat tmp/app_partition | awk -F"@" '{print $1}' > tmp/app_size
call:myDosFunc tmp/app_size app_size_t


cat tmp/app_partition | awk -F"@" '{print $2}' > tmp/app_offset
call:myDosFunc tmp/app_offset app_offset_t


cat tmp/partition2 | awk -F"," '{print $2}' | awk -F"(" '{print $1}' > tmp/mid_partition
call:myDosFunc tmp/mid_partition mid_partition_t


cat tmp/partition2 | awk -F"(" '{print $2}' | awk -F")" '{print $1}' > tmp/mid_name
call:myDosFunc tmp/mid_name mid_name_t


cat tmp/mid_partition | awk -F"@" '{print $1}' > tmp/mid_size
call:myDosFunc tmp/mid_size mid_size_t


cat tmp/mid_partition | awk -F"@" '{print $1}' > tmp/mid_offset
call:myDosFunc tmp/mid_offset mid_offset_t


cat tmp/partition2 | awk -F"," '{print $3}' | awk -F"(" '{print $1}' > tmp/end_partition
call:myDosFunc tmp/end_partition end_partition_t


cat tmp/partition2 | awk -F"(" '{print $3}' | awk -F")" '{print $1}' > tmp/end_name
call:myDosFunc tmp/end_name end_name_t


cat tmp/end_partition | awk -F"@" '{print $1}' > tmp/end_size
call:myDosFunc tmp/end_size end_size_t


cat tmp/end_partition | awk -F"@" '{print $2}' > tmp/end_offset
call:myDosFunc tmp/end_offset end_offset_t


echo Userdata partition size:
echo 1:1G
echo 2:2G
echo 3:3G
echo 4:4G
echo 5:5G
echo 6:6G
set /p p_size=Plese select userdata partition size:
if "%p_size%"=="1" (
	echo 1 > tmp/app_size_dec
) else if "%p_size%"=="2" (
	echo 2 > tmp/app_size_dec
) else if "%p_size%"=="3" (
	echo 3 > tmp/app_size_dec
) else if "%p_size%"=="4" (
	echo 4 > tmp/app_size_dec
) else if "%p_size%"=="5" (
	echo 5 > tmp/app_size_dec
) else if "%p_size%"=="6" (
	echo 6 > tmp/app_size_dec
) else (
echo Error: userdata partition size is not correct!
pause
exit
)

call:myDosFunc tmp/app_size_dec app_size_dec_t

set /a app_size_dec_to_section=%app_size_dec_t%*1024*2048
set /a mid_offset_dec=%app_offset_t%+%app_size_dec_to_section%
set /a end_offset_dec=%mid_offset_dec%+%mid_size_t%

echo "" > tmp/a.txt
echo "" > tmp/b.txt
echo %app_size_dec_to_section% > tmp/a.txt
call:myToHex tmp/a.txt tmp/b.txt
call:myDosFunc tmp/b.txt app_size_t

echo "" > tmp/a.txt
echo "" > tmp/b.txt
echo %mid_offset_dec% > tmp/a.txt
call:myToHex tmp/a.txt tmp/b.txt
call:myDosFunc tmp/b.txt mid_offset_t

echo "" > tmp/a.txt
echo "" > tmp/b.txt
echo %end_offset_dec% > tmp/a.txt
call:myToHex tmp/a.txt tmp/b.txt
call:myDosFunc tmp/b.txt end_offset_t

echo %app_size_t%
echo %mid_offset_t%
echo %end_offset_t%

echo %partition1_t% | awk -F%app_partition_t% '{print $1}' > tmp/partition0
call:myDosFunc tmp/partition0 partition0_t

set partition2_t=),%mid_size_t%@0x%mid_offset_t%(%mid_name_t%),-@0x%end_offset_t%(%end_name_t%)

set partitions=%partition0_t%0x%app_size_t%@%app_offset_t%(userdata%partition2_t%
echo the cmd line:%partitions%

sed -i "/userdata/d" output/%parameter_f%
echo %partitions% >> output/%parameter_f%



echo Start to pack firmware...
grep -e bootloader output/package-file | cut.exe -f 2 > bootloader_file
set /p bootloader_f=<bootloader_file
del /a /f /q "bootloader_file"
copy /y AFPTool.exe output
copy /y RKImageMaker.exe output
cd output
AFPTool.exe -pack ./ Image\update.img
RKImageMaker.exe -RK330A %bootloader_f%  Image\update.img update.img -os_type:androidos
move /y update.img ../update_%p_size%G.img
echo Generate update_%p_size%G.img on current directory
echo Finish

cd ../output
del /a /s /q /f *

cd ../
rd /s /q "tmp"
rd /s /q "output"

echo       Done!!
echo.&pause&exit


:myDosFunc 
    for /f "delims=" %%a in (%~1) do (
      set ip=%%a
      set "%~2=!ip!"
    )
GOTO:EOF


:myToHex
set "Num=0123456789abcdef"
(for /f "delims=" %%a in (tmp/a.txt) do call :a %%a)>tmp/b.txt
goto :eof

:a
	set Dec=%1
	setlocal enabledelayedexpansion
:Lp
	set /a Mod = Dec %% 16,Dec /= 16
	set Hex=!Num:~%Mod%,1!!Hex!
if !Dec! geq 1 goto :Lp
	echo,!Hex!
GOTO:EOF

