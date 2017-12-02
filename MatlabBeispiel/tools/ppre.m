% ---------------
% > Adjust size and font 
fontname = 'Helvetica';fontsize = 9;
close all;
set(0,'DefaultFigureWindowStyle','normal');
set(0,'defaultaxesfontname',fontname);set(0,'defaulttextfontname',fontname);
set(0,'defaultaxesfontsize',fontsize);set(0,'defaulttextfontsize',fontsize);
figure('Units', 'centimeters','Position', [10 5 width height],'Color','w');
cols=get(0, 'DefaultAxesColorOrder');
ax=axes;defpos=get(ax,'Position');
axis tight; grid off; box on;hold on;