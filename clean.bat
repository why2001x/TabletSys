@echo on
echo Delete QuartusII intermediate files
echo Begin deleting...
if exist ".\db" rd /S /Q ".\db"
if exist ".\incremental_db" rd /S /Q ".\incremental_db"
if exist ".\output_files" rd /S /Q ".\output_files"
if exist ".\simulation" rd /S /Q ".\simulation"
if exist ".\greybox_tmp" rd /S /Q ".\greybox_tmp"
for /r . %%c in (*.bak *.temp *.qdf *.qws *.qip *.cmp) do del "%%c"
echo End deleting...
pause
