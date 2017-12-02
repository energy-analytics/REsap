%% Data preparation

%% Figure
width=12;height=5; % small: 12 x 5 / large: 14 x 8
ppre
set(ax, 'Position', [defpos(1) 1.6*defpos(2) defpos(3) 1*defpos(4)]); % left / bottom / width / height
% ---------------
% > LineStyles: 
lw=1.5;ms=5;
l1style={'Color',cols(1,:), 'LineStyle','-', 'LineWidth', lw, 'Marker','none', 'MarkerFaceColor', cols(2,:), 'MarkerEdgeColor','k'};
l2style={'Color',cols(2,:), 'LineStyle','--', 'LineWidth', lw,'Marker', 's', 'MarkerFaceColor', cols(2,:), 'MarkerEdgeColor','k'};
% ----------------------------------------------------------------
% > Plotting
l1=plot(ax,rand(20,1)/max(rand(20,1)),l1style{:}); 
hold on; 
l2=plot(ax,normrnd(20,1,20,1)/max(normrnd(20,1)),l2style{:}); 
ylim(get(ax, 'YLim')); xlim(get(ax, 'XLim'))
% ----------------------------------------------------------------
% > Labels and legends
ylabel('$\frac{\hat{\dot{Q}}}{\dot{Q}}$','interpreter','latex','rotation',0,'HorizontalAlignment','right'); 
xlabel('{\itt} in h');
legend([l1 l2],'Wärmebedarf', 'Erzeugung in KWK','Location','northoutside');
% ----------------------
% > Postprocessing
ppost
% m2l('Test')                           % for use in latex
% export_fig 'test.png' -nocrop -r300         % for use in office (e.g. presentation slides)