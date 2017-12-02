set(findall(gcf,'-property','TickLength'),'TickLength'  , [.01 .01] ,  'LineWidth'   , 1);
%set(findall(gcf,'-property','MarkerSize'),'MarkerSize',ms)
set(findall(gcf,'-property','FontSize'),'FontSize',fontsize)
set(findall(gcf,'-property','FontName'),'FontName',fontname)
set(findall(gcf,'Interpreter','latex'),'FontSize',fontsize*1.5)
set(gca, 'YTickLabel', cellfun(@(x)strrep(x, '.',','), get(gca,'YTickLabel'), 'UniformOutput',0))
set(gca, 'XTickLabel', cellfun(@(x)strrep(x, '.',','), get(gca,'XTickLabel'), 'UniformOutput',0))