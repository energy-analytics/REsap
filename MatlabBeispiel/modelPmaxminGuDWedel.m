%
% Generate new pmax / pmin timeseries from PQ diagram of GuDW and Thermal
% schedule of WW1 and WW2 from 2012
%
clear variables; clc; close all;
%%
refraw=modelicaread('d:\Transient\Git\transientee-sources\transient_library\TransiEnt\Tables\heat\ThermalUnitCommitmentSchedule_3600s_REF35.txt');
QflowWest=sum(refraw.data(1:end-1,2:3), 2);
QflowNGuD=220e6;
QflowGuD=QflowWest;
QflowGuD(QflowGuD>QflowNGuD)=QflowNGuD;
PQ=[0, 1.0000, 0.2447; 0.2226, 0.9745, 0.2213; 0.9995, 0.8894, 0.6660; 1.0000, 0.8894, 0.6660];
pmax_from_qflow=@(qflow)interp1(PQ(:,1), PQ(:,2), qflow, 'linear');
pmin_from_qflow=@(qflow)interp1(PQ(:,1), PQ(:,3), qflow, 'linear');
qflowGuD=QflowGuD/QflowNGuD;
pmax=pmax_from_qflow(qflowGuD);
pmin=pmin_from_qflow(qflowGuD);
%
modelicawrite('input/GuDW_Pmax.txt', timeseries(pmax, refraw.time))
modelicawrite('input/GuDW_Pmin.txt', timeseries(pmin, refraw.time))
%%
subplot(2,1,1)
plot(modelicaread('input/GuDW_Pmax.txt')); hold on;
plot(modelicaread('input/WW2_Pmax_noWWinJuly.txt')); hold on;
subplot(2,1,2)
plot(modelicaread('input/GuDW_Pmin.txt')); hold on;
plot(modelicaread('input/WW2_Pmin_noWWinJuly.txt')); hold on;