function result=modclip(A)
% Author: Pascal Dubucq, 2016
%
% MODCLIP copies the data in matrix A to clipboard in a modelica conform
% syntax
%
% See also CLIPBOARD
%
result=strrep(strcat('{',sprintf('%.2f,', A),'}'),',}','}');
clipboard('copy', result);

