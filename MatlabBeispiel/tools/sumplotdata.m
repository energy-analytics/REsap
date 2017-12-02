function res = sumplotdata(data)
% Author: Pascal Dubucq, 2014
%
% SUMPLOTDATA  
% Takes a matrix containing multiple data series and adds them 
% up so that the first column stays the same, the second is the
% sum of the first and the second and so on. This function is used
% in the top level function FILLPLOT
%
% DATA A n x m matrix where n is the length of data sets and m is the
% number of data sets.
%
% [RES] = sumplotdata(DATA) is a matrix containing the first
% column of data and then the incrementing sum of the other columns of
% data
%
% See also FILLPLOT
%
res=zeros(size(data));
res(:, 1)=data(:,1);
for i=2:size(data,2)    
  res(:, i) = res(:,i-1) + data(:,i);
end


