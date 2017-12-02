clc;clear all;
filedir='input/';
%raw_data=get(modelicaread(strcat(filedir,'PQ_HeatInput_Matrix_WT.txt')), 'Data');
data=[ 0e6,  470e6,  115e6;
49e6,  458e6,  104e6;
220e6,  418e6,  313e6;
220.1e6,  418e6,  313e6];

%data(1,:)=raw_data(1,:);
%data(2:9,:)=raw_data(3:end,:)
time=[ 0:900:900*35135 ]';
%ts=timeseries(data,time);
n=[1:length(data(:,1))]';
pq=timeseries(data,n)
modelicawrite('input/GuD_PQ_Diagramm.txt',pq)