function T = joinResultFiles(filepath, inputFileNameFilter, outputFileName);
fileSet=dir([filepath inputFileNameFilter]);
values=[];
for f=1:length(fileSet)
    tab=readtable([filepath fileSet(f).name]);
    variableName=tab.Variable;
    values=[values tab.Value]; %#ok<*AGROW>
    tmp=strsplit(fileSet(f).name, {'_','.'});
    valueName(f)=tmp(2);
end
T=array2table(values,'VariableNames', valueName,'RowNames', variableName)
writetable(T, [filepath outputFileName],'FileType','Spreadsheet','WriteRowNames',1);