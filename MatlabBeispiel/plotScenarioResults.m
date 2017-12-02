    function plotScenarioResults(varargin)
clc
var=2;sel=nan;filepath='output/ScenarioResults.xlsx';
for i=1:2:length(varargin),
    switch lower(varargin{i})
        case 'filename'            
            filepath=varargin{i+1};
        case 'sel'
            sel=varargin{i+1};
            sel=sel+1;
        case 'var'
            var=varargin{i+1};
        otherwise
            error('Use one of the following flags: ''filename'', ''sel'', ''var''');
    end
end
T=readtable(filepath);
if isnan(sel)
    sel=2:size(T,2);
end
disp(['>> Selection: Variable ', num2str(var), ' x ',num2str(size(T(:,sel),2)),' scenarios']);
Tdisp=T;Tdisp.Row=strcat(strread(num2str(1:length(Tdisp.Row)),'%s'),': ', Tdisp.Row);
disp(Tdisp(:,[1, sel]));
width=20;height=20;
ppre
cols=hsv(length(sel));
for i=1:length(sel)
    bh=bar(i, table2array(T(var,sel(i)))); hold on;
    set(bh,'FaceColor',cols(i,:));
end
names=T.Properties.VariableNames(sel);
legtext=strcat(strread(num2str(1:length(names)),'%s'),repmat('=', length(names), 1), names');
legend(legtext,'Location','EastOutside')
ylim([min(get(gca, 'YLim')), 1.1*max(get(gca, 'YLim'))])
ppost
set(gcf, 'Position',[50.8000         0   50.8000   29.7392]);
set(gca, 'XTick', 1:length(sel));
title(table2array(T(var,1)),'Interpreter','none','FontSize',13);



 