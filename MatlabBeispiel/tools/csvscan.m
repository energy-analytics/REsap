function T = csvscan(filename, format, delimiter, treatasempty, R, C)
% Author: Pascal Dubucq, 2014
%
% CSVSCAN Read data from a delimiter seperated text file that is allowed to
% contain string values (which does not work with CSVREAD) and simple
% filename assignment (which does not work with TEXTSCAN).
%
% T = CSVSCAN(filename, 'FORMAT') reads comma seperated numerical data 
% from a text based file specified by FILENAME. The FORMAT is a string of
% conversion specifiers enclosed in single quotation marks.
%
% T = CSVSCAN(filename, 'FORMAT', 'DELIMITER') uses the string DELIMITER as the
% delimiter in the scanned file
%
% T = CSVSCAN(filename, 'FORMAT', 'DELIMITER', 'TREATASEMPTY') replaces string 
% values equal to 'TREATASEMPTY' with NaN so that the result is a numeric
% matrix
%
% T = CSVSCAN(filename, 'FORMAT', 'DELIMITER', 'TREATASEMPTY', R, C) starts
% reading at row R and column C. R and C are zero-based so that R=0 and C=0
% specifies the first value in the file (default)
%
% %   Format Options:
%
%   The FORMAT string is of the form:  %<WIDTH>.<PREC><SPECIFIER>
%       <SPECIFIER> is required; <WIDTH> and <PREC> are optional.
%     
%   See TEXTSCAN for more information about the FORMAT options
%
%   Examples:
%
%   Example 1: Read numeric data from a complex text file
%       Suppose the text file 'example.dat' contains the following:
%   
%       This file has been created by... (Comment Line)
%       Sally;Level1;01.01.2014;0.3
%       Sally;Level1;01.01.2014;n.v.
%       Joe;Level1;01.01.2014;0.6
%
%       Read the file and save numerical data in vector X:
%           X = csvscan('example.dat', '%s%s%s%f', ';','n.v.',1,3)
%
%       Will return X = [0.3; NaN; 0.6]
%
% 
%   See also CSVREAD, DLMREAD, TEXTSCAN.        

fid=fopen(filename); 

% text scan
switch nargin 
    case 2    
        T=textscan(fid,format);%,'headerlines',headerLines,'delimiter',colDelimiter);
    case 3
        T=textscan(fid, format, 'delimiter',delimiter);
    case 4
        T=textscan(fid, format, 'delimiter', delimiter, 'TreatAsEmpty', treatasempty);
    case 5
        text = textscan(fid, format, 'delimiter',delimiter, 'TreatAsEmpty', treatasempty,'Headerlines', R);
        T = text{:};
    case 6
        text = textscan(fid, format, 'delimiter',delimiter, 'TreatAsEmpty', treatasempty,'Headerlines', R);
        columns = [text{C}];
        T = columns;
    otherwise 
        T = 0;
end
fclose(fid);
