clear variables; close all; clc;
dymresult=dymload('d:\Transient\TEEsatz\Ergebnisse\GenerateVattenfallHeatDemand.mat');
Q_flow=dymget(dymresult, 'heatGenerationCharline.Q_flow');
t=dymget(dymresult, 'Time');
plot(t, Q_flow);
%%
modelicawrite('input/HeatDemandHHVattenfall_2012.txt', timeseries(Q_flow, t));
