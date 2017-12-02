function modelicawrite(filename,timeseries,varargin)
% Author: Pascal Dubucq, 2014
%
% MODELICAWRITE(FILENAME, TIMESERIES)  Writes a modelica conform csv file from data provided
% by a timeseries-object. Note that LF (line feed) is used as a new line
% character, therefore resulting files may look funny in Windows Notepad which
% requires CRLF - but it works in dymola and matlab, so that's fine!
%
% FILENAME is the target filename (may be relative or absolute). The file
% will be created or overwritten without further notice.
%
% varargin is an optional comment that will be written in result file, every
% additional argument adds another line.
%
% TIMESERIES is a timeseries object containing the data in SI units and the
% corresponding timeseries in seconds and starting at 0.
%
% See also TIMESERIES
N=size(timeseries.time,1);
args=varargin;
assert(size(timeseries.data,1)==length(timeseries.time), ['Error: timeseries.data (Size: ' ...
    num2str(size(timeseries.data)) ') should have as many rows as timeseries.time (' ...
    num2str(length(timeseries.time)) ') !']);
%
try
%
% Open fie
fid=fopen(filename, 'w+');
%
% Write header
fprintf(fid, '%s\n', '#1');                     % line 1, version format
for cl=1:nargin-2
    fprintf(fid, '# %s\n', char(args{cl}));
end
for infoline=2:size(timeseries.DataInfo.UserData, 2)    
    fprintf(fid, '%s', char(timeseries.DataInfo.UserData{infoline}));
end
fprintf(fid, '%s\t', 'double');                 % definitino of data size
fprintf(fid, '%s\n', strcat('default(', num2str(N),', ',num2str(size(timeseries.data,2)+1),')'));               
%
% Write data
dlmwrite(filename, [timeseries.time, timeseries.data],'-append','delimiter','\t','precision',7);
% 
% Close file
fclose(fid);
catch me
    fclose(fid);        
    rethrow(me);
end
fprintf('Data successfully written in modelica conform table format to file %s \n', filename);



