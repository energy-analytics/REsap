function param=updateParameters(param, globalts, t0, np, e_end, p_end)
%
% > Update storage levels and init power
for i=1:length(param.dispUnits)
    param.dispUnits(i).e_start_t=e_end(i);
    param.dispUnits(i).p_init=p_end(i);
end
for i=find([param.dispUnits.isDSS])
    param.dispUnits(i).e_start_t=globalts.e_start_DSS_t(ceil(t0/np));
    param.dispUnits(i).e_max=globalts.e_max_DSS_t(ceil(t0/np));
end
%
% > Update local timeseries
timerange = @(x, col) x(t0:t0+np-1,col);
param.var.P_dem_t=timerange(globalts.P_dem_t,1);
param.var.Q_dem_t=timerange(globalts.Q_dem_t,1); 
param.var.LFsite_t=timerange(globalts.LFsite_t,':'); 
if ~isempty(find([param.dispUnits.isDSS],1))
param.var.P_DSSCons_t=timerange(globalts.P_DSSCons_t, 1);
end
if isfield(globalts, 'p_min_t')
    param.var.p_min_t=timerange(globalts.p_min_t, 1:size(globalts.p_min_t,2));
end
if isfield(globalts, 'p_max_t')
    param.var.p_max_t=timerange(globalts.p_max_t, 1:size(globalts.p_max_t,2));
end
if param.const.nREu>0
x_RW_t=timerange(globalts.P_RW_t, 1);
x_PV_t=timerange(globalts.P_PV_t,1);
x_On_t=timerange(globalts.P_On_t,1);
x_Off_t=timerange(globalts.P_Off_t,1);
param.var.P_RE_t=[x_RW_t x_PV_t x_On_t x_Off_t];
end
%
% > Update constant parameters
param.const.t0=t0;
param.const.np=np;
param.const.tend=t0+np-1;
end