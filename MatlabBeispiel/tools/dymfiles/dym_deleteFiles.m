function dym_deleteFiles(files)
% dym_deleteFiles - delete files in the current directory
%
% dym_deleteFiles(files) deletes all files in the current
% directory which are specified as a cell array of strings.
% If a defined file does not exist, no action is performed,
% especially no warning message is printed.
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.

for i=1:length(files);
   if dym_existFile(files{i}), delete(files{i}); end;
end;
