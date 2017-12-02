function result = modelicaread(filename)
% Author: Pascal Dubucq, 2014
%
% MODELICAREAD  Reads data from a modelica conform csv file 
% and returns a timeseries object
%
% FILENAME is the target filename (may be relative or absolute). 
%
% [Y] = modelicaread(FILENAME) is a timeseries object containing the data in SI units and the
% corresponding timeseries in seconds and starting at 0.
%
% See also TIMESERIES, MODELICAWRITE
%
try
%
% Open fie
fid=fopen(filename);assert(fid>0, ['File ''' filename ''' not found.']);
tline=fgets(fid); %read first line
assert(strncmpi(tline, '#1',1), 'Modelica data tables format requires first line to be ''#1''. Please check input file.')
firstRow=1; % first data row)
comments=cell(0);
while(ischar(tline) && strncmpi(tline, '#',1))
    comments{firstRow}=tline;
    firstRow=firstRow+1;    % count up comment line
    tline=fgets(fid);       % read next line
end
fclose(fid);
content = dlmread(filename,'\t',firstRow,0);
result = timeseries(content(:,2:end), content(:,1));
if length(comments) > 1
    result.DataInfo.UserData=comments;
end
catch me    
    rethrow(me);
end