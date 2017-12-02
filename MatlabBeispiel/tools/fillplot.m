function res = fillplot(time, data, ids, colors)
% Author: Pascal Dubucq, 2014
%
% FILLPLOT  
% Makes a 2D summation plot of a given data matrix. The first column
% in DATA will be displayed at the bottom starting from the y=0 line and
% filled with the color specified with the first entry of the vector
% COLORS. The further entries of data will be added on top (and filled 
% with the corresponding color defined by COLORS) such that the curve on
% top of the plot will be the sum of all data series. A legend will be
% added according to the entries in IDS.
%
% TIME a vector that will be used as the time scale on x axis of the plot
%
% DATA A n x m matrix where n is the length of data sets and m is the
% number of data sets. n must be equal to length(TIME).
%
% IDS a String array containing the elements displayed in the legend. 
% length(IDS) must be equal to m in the n x m matrix DATA
%
% COLORS a m x 3 matrix containing the colors for the fill plot. The length
% m of the matrix COLORS must be equal to the m of the n x m matrix DATA
% 
% [RES] = sumplotdata(DATA) is a matrix containing the first
% column of data and then the incrementing sum of the other columns of
% data
%
% See also SUMPLOTDATA
%
% === remove empty columns from result vector
nonzeroels=find(sum(data,1)~=0);

data=data(:,nonzeroels);
colors=colors(nonzeroels, :);
n=size(data, 2); % number of curves
if n==0
    return;
end;
% 
res=sumplotdata(data);
%
timeloop=[time; flipud(time)];
zerobase=zeros(length(time), 1);
% fill base curve
f=fill(timeloop, [res(:, 1); zerobase], colors(1,:)); hold on;
set(f,'edgecolor','none');
% loop over rest
for i=2:n
   f=fill(timeloop, [res(:,i-1); flipud(res(:,i))], colors(i,:)); 
   set(f,'edgecolor','none');          
end
% Set font size
fig=gcf;
%set(findall(fig,'-property','FontSize'),'FontSize',24) 

% fill legend
if char(ids)~=0 
ids=ids(nonzeroels);
res=legend(ids, 'Location', 'NorthEastOutside');
end;
%
%
end

