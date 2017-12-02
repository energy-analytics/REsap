function answer = dym_existFile(name);
% dym_existFile - check file/directory existence in current directory
%
% dym_existFile(name) returns 1 if filename or directory "name" exists
% (either in the current directory or in the file system if
% a full path name is given), otherwise returns 0
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.

answer = length(dir(name));