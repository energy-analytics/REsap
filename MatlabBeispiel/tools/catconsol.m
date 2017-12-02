function [y, cat]=catconsol(x, var, N, fu)
%CATMEAN(x,var,N) Calculates the mean value of x per category of a influencing variable
% var. N is the number of categories. 
%
% y and cat are N x 1 vectors containing the value of the main variable var
% and the resulting mean value of x in each category.
%
% See also: HISTCOUNTS, MEAN
%
[y,cat]=deal(zeros(N,1));
%
[~,Tcat,icat]=histcounts(var, N);
for i=1:N
    ycat=x(icat==i);
    y(i)=feval(fu, ycat);
    cat(i)=feval(fu, [Tcat(i+1) Tcat(i)]);
end