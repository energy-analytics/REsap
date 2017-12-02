% 
% Test the function getCoefficient_CHP_Equation
%
close all
filenames={'WT_PQ_Diagramm.txt' 'WW1_PQ_Diagramm.txt' 'WW2_PQ_Diagramm.txt' 'CCP_PQ_Diagramm_norm.txt', 'ST_PQ_Diagramm_norm.txt'}
for f=1:length(filenames)
    figure
    raw=modelicaread(strcat('input/', filenames{f}));
    if ~isempty(strfind(filenames{f},'norm.txt'))
        % Example: 125 MWel / 180 MWth
        raw.data(:,1)=raw.data(:,1)*180e6;
        raw.data(:,2:3)=raw.data(:,2:3)*125e6;
    end
    data=raw.data;
    plot(data(:,1), data(:,2),'k'); hold on;
    plot(data(:,1),data(:,3),'k');
    [a,b]=getCoefficient_CHP_Equation(data, 'filenames{f}');
    title(strrep(filenames{f}, '_',' '));
    %
	qs=get(gca,'Xlim');
    for p=1:size(a, 1)
        plot(qs, b(p,1)*1e6 + a(p,1) * qs, '--','Color',.7*ones(1,3));
        plot(qs, b(p,2)*1e6 + a(p,2) * qs, '--','Color',.7*ones(1,3));
    end
    plot(data(:,1), data(:,2),'-ok'); hold on;
    plot(data(:,1),data(:,3),'-ok');  
end
    