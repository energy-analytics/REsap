function [param, globalts]=initScenario(t0, np, ni, rh, dt, scenario,saveResultFiles)
%
% Get scenario definition
[units, extraparams]=getScenarioDefinition(scenario);
%
% Indexing helper functions
param.REUnits=units(find(strcmp({units.Type},'RE')));
param.dispUnits=units(setdiff(1:length(units), find(strcmp({units.Type},'RE'))));
for s=1:length(param.dispUnits); param.dispUnits(s).Key=s;param.dispUnits(s).p_init=0; end;             % Schlüssel ist jetzt neu vergeben
%
% >> Constant parameters
param.const.t0=t0;
param.const.tend=t0+np*rh-1;
param.const.dt=dt;                                                % Zeitschritt der Daten
param.const.P_Pri=extraparams.P_Pri;                              % Upspinning primary Reserve
param.const.P_Sec_up=extraparams.P_Sec_up;                        % Upspinning secondary Reserve
param.const.P_Sec_down=extraparams.P_Sec_down;                    % Downspinning secondary Reserve
param.const.deltat_Sec=5/60*dt;                                   % 5 Minutes
param.const.np=np;
param.const.rh=rh;
param.const.ndu=length(param.dispUnits);
param.const.nreu=length(param.REUnits);
param.const.nu=param.const.ndu+param.const.nreu;
param.const.nsu=length(find([param.dispUnits.isStorage]));
param.const.ndss=length(find([param.dispUnits.isDSS]));
param.const.nstate=length(find([param.dispUnits.isStateUnit]));
param.const.isCHP=length(find([param.dispUnits.isCHP]));
param.const.isBTTP=length(find([param.dispUnits.isBTTP]));
param.const.nv2g=length(find([param.dispUnits.isV2G]));
param.const.npribalu=length(find([param.dispUnits.isPriBalUnit]));
param.const.nsecbalu=length(find([param.dispUnits.isSecBalUnit]));
param.const.T_N_min=extraparams.T_N_min;
param.const.deltat_Sec=extraparams.t_Sec_react;
param.const.flexBalancing=extraparams.flexBalancing;
param.const.P_Pri_Bandwidth=extraparams.P_Pri_Bandwidth;
param.const.Pwindinertia=extraparams.Pwindinertia;
param.const.nel_p=length(find([param.dispUnits.isPowerProducer]));
param.const.nel_u=length(find([param.dispUnits.isPowerUser]));
param.const.nel=param.const.nel_p+param.const.nel_u;
param.const.nheat_p=length(find([param.dispUnits.isHeatProducer]));
param.const.nheat_u=length(find([param.dispUnits.isHeatUser]));
param.const.nheat=param.const.nheat_u+param.const.nheat_p;
param.const.nVarPowLim=length(find([param.dispUnits.isVarPowLim]));
param.const.nFixLoadCur=length(find([param.dispUnits.isFixLoadCur]));
param.const.nREu=length(param.REUnits);
if isfield(extraparams, 'reorderResultFile');param.const.reorderResultFile=extraparams.reorderResultFile;end;
%
% >> Compute problem size parameters
% real: 1 per nel_p, 1 per nel_u, 1 per nheat, 1 per dss (difference power)
% int: 2 per state, 1 per storage
param.const.nvarp=param.const.nel_p+param.const.nel_u+param.const.nheat_p+param.const.nheat_u+2*param.const.nstate+param.const.nsu+param.const.npribalu+2*param.const.nsecbalu+2*param.const.ndss;
param.const.nvar=param.const.nvarp*param.const.np;
%
% Find synchronized units without state
is_statelessSynchronized=setdiff(find(~isnan([param.dispUnits.T_gen])), find([param.dispUnits.isStateUnit]));
param.const.PT_gen_stateless=sum([param.dispUnits(is_statelessSynchronized).P_0].*[param.dispUnits(is_statelessSynchronized).T_gen]);
%% Demand course
% >> Time variant parameters (P in MW, p dimensionless)
timerange = @(x, t0, np, col) x(t0:t0+np-1,col);
filedir='input/';
globalts.Q_dem_t=get(modelicaread(strcat(filedir,extraparams.filename_heatLoad)), 'Data')*1e-6;
if sum(~isnan([param.dispUnits.site]))==1
    globalts.LFsite_t=ones(size(globalts.Q_dem_t));
else
    globalts.LFsite_t=get(modelicaread(strcat(filedir,extraparams.filename_LFsite)), 'Data');
end
globalts.P_dem_t=get(modelicaread(strcat(filedir,extraparams.filename_electricLoad)), 'Data')*1e-6;
if dt~=.25
    globalts.Q_dem_t=interp1(0:900:366*24*3600-900, globalts.Q_dem_t(1:end), 0:3600*dt:366*24*3600-dt)';
    globalts.LFsite_t=interp1(0:900:366*24*3600-900, globalts.LFsite_t(1:end,:), 0:3600*dt:366*24*3600-dt);
    globalts.P_dem_t=interp1(0:900:366*24*3600-900, globalts.P_dem_t, 0:3600*dt:366*24*3600-dt)';
end
param.var.Q_dem_t=timerange(globalts.Q_dem_t,t0,np,1); 
param.var.LFsite_t=timerange(globalts.LFsite_t,t0,np,':'); 
param.var.P_dem_t=timerange(globalts.P_dem_t,t0,np,1); 
%
% >Variable Power Limits Plants
isVarPowLim=find([param.dispUnits.isVarPowLim]);
iVarPowLim=[1:param.const.nVarPowLim];
if ~isempty(isVarPowLim) 
    for i=iVarPowLim
        p_min=get(modelicaread(strcat(filedir,param.dispUnits(isVarPowLim(i)).p_min_t)), 'Data');    
        p_max=get(modelicaread(strcat(filedir,param.dispUnits(isVarPowLim(i)).p_max_t)), 'Data');    
        if dt~=.25
            p_min=interp1((0:900:366*24*3600-900)', p_min, (0:3600*dt:366*24*3600-dt)');
            p_max=interp1((0:900:366*24*3600-900)', p_max, (0:3600*dt:366*24*3600-dt)');        
        end
        globalts.p_min_t(:,i)=p_min;
        globalts.p_max_t(:,i)=p_max;    
        param.var.p_min_t(:,i)=timerange(globalts.p_min_t,t0,np,i);
        param.var.p_max_t(:,i)=timerange(globalts.p_max_t,t0,np,i);
    end
end
%
% > Fixed Load Curve Plants
isFixLoadCur=find([param.dispUnits.isFixLoadCur]);
iFixLoadCur=1:param.const.nFixLoadCur;
if ~isempty(isFixLoadCur) 
    for i=iFixLoadCur
        p_fix=get(modelicaread(strcat(filedir,param.dispUnits(isFixLoadCur(i)).p_t)), 'Data');    
        if dt~=.25
            p_fix=interp1((0:900:366*24*3600-900)', p_fix, (0:3600*dt:366*24*3600-dt)');      
        end
        globalts.p_t(:,i)=p_fix;
        param.var.p_t(:,i)=timerange(globalts.p_t,t0,np,i);
    end
end
param.var.P_RE_t=zeros(np,1);
if param.const.nREu>0
    if extraparams.forceFullLoadHours==0    % do not change profiles
        globalts.P_RW_t=get(modelicaread(strcat(filedir,extraparams.filename_ROWProfile)), 'Data')*5010*3600*param.REUnits(1).P_0;
        globalts.P_PV_t=get(modelicaread(strcat(filedir,extraparams.filename_PVProfile)), 'Data')*param.REUnits(2).P_0;
        globalts.P_On_t=get(modelicaread(strcat(filedir,extraparams.filename_WindProfile)), 'Data')*param.REUnits(3).P_0;
        globalts.P_Off_t=get(modelicaread(strcat(filedir,extraparams.filenameWindOffshore)), 'Data')*param.REUnits(4).P_0;
    else
        flh=extraparams.forceFullLoadHours;
        % ROW is scaled to energy of 1J
        globalts.P_RW_t=get(modelicaread(strcat(filedir,extraparams.filename_ROWProfile)), 'Data')*flh(1)*3600*param.REUnits(1).P_0;
        % others are scaled by installed power, so full load hours of profile is sum(data)/4 (convention: input data has 15 min. resolution)
        tmp=get(modelicaread(strcat(filedir,extraparams.filename_PVProfile)), 'Data');
        globalts.P_PV_t=flh(2)/(sum(tmp)/4).*tmp*param.REUnits(2).P_0;
        tmp=get(modelicaread(strcat(filedir,extraparams.filename_WindProfile)), 'Data');
        globalts.P_On_t=flh(3)/(sum(tmp)/4).*tmp*param.REUnits(3).P_0;
        tmp=get(modelicaread(strcat(filedir,extraparams.filenameWindOffshore)), 'Data');
        globalts.P_Off_t=flh(4)/(sum(tmp)/4).*tmp*param.REUnits(4).P_0;        
    end
    if dt~=.25
        globalts.P_RW_t=interp1(0:900:(length(globalts.P_RW_t)-1)*900, globalts.P_RW_t, 0:3600*dt:ni*np*dt*3600-dt)';
        globalts.P_PV_t=interp1(0:900:(length(globalts.P_PV_t)-1)*900, globalts.P_PV_t, 0:3600*dt:ni*np*dt*3600-dt)';
        globalts.P_On_t=interp1(0:900:(length(globalts.P_On_t)-1)*900, globalts.P_On_t, 0:3600*dt:ni*np*dt*3600-dt)';
        globalts.P_Off_t=interp1(0:900:(length(globalts.P_Off_t)-1)*900, globalts.P_Off_t, 0:3600*dt:ni*np*dt*3600-dt)';
        
    end
x_RW_t=timerange(globalts.P_RW_t,t0,np, 1);
x_PV_t=timerange(globalts.P_PV_t,t0,np,1);
x_On_t=timerange(globalts.P_On_t,t0,np,1);
x_Off_t=timerange(globalts.P_Off_t,t0,np,1);
param.var.P_RE_t=[x_RW_t x_PV_t x_On_t x_Off_t];
end;
%
% > DSS
idssidx=0;
for idss=find([param.dispUnits.isDSS])
    idssidx=idssidx+1;
    % val^idate parameters:
    assert(isfield(extraparams,'dss'), 'Error: Scenarios with DSS Units must provide parameter "dssload" with as many specifications as DSS units in scenario')
    assert(length(extraparams.dss)==length(find([param.dispUnits.isDSS],1)), ['Error: Scenario contains ' ...
        num2str(length(find([param.dispUnits.isDSS],1))) ' DSS units, and ' ...
        num2str(length(extraparams.dss)) 'demand curve definitions (should be equal).']);
    %
    % dtermine wether load for this unit is constant or time dependent
    % (defined by input file)
    if isnumeric(extraparams.dss{idssidx})
        globalts.P_DSSCons_t=extraparams.dss{idssidx}*ones(length(0:dt*3600:366*24*3600-dt*3600),1);
    else
        globalts.P_DSSCons_t=get(modelicaread(char(strcat(filedir,extraparams.dss{idssidx}.p_load))), 'Data');
        if dt~=.25
            globalts.P_DSSCons_t=interp1(0:900:366*24*3600-900, globalts.P_DSSCons_t, 0:3600*dt:366*24*3600-dt)';
        end
        globalts.e_start_DSS_t=get(modelicaread(char(strcat(filedir, extraparams.dss{idssidx}.e_start))),'Data');
        globalts.e_max_DSS_t=get(modelicaread(char(strcat(filedir, extraparams.dss{idssidx}.e_max))),'Data');
        param.dispUnits(idss).e_start=globalts.e_start_DSS_t(ceil(t0/np));
        param.dispUnits(idss).e_max=globalts.e_max_DSS_t(ceil(t0/np));
    end
    %
    % interpolate to simulation grid
    param.var.P_DSSCons_t(:,idssidx)=timerange(globalts.P_DSSCons_t, t0,np,1);
    %
    % > Correction of load to account for extra synthetic load by heat
    % storage unit
    %globalts.P_dem_t=globalts.P_dem_t-globalts.P_DSSCons_t*param.dispUnits(find([param.dispUnits.isDSS])).P_0;
    %Das muss man tun, wenn man annimmt, das die Wärmepumpen im
    %Referenzfall schon im System sind.  
end;
%% V2G

assert(~isempty([param.dispUnits.isV2G]) || np*dt==24, 'Scenarios with V2G units can only be simulated daily (np*dt=24)');
if ~isempty(find([param.dispUnits.isV2G]))
    assert(isfield(extraparams,'v2g_probailityOfGridConnection_per_hour'), 'Error: Scenarios with V2G units must provide parameter ''v2g_probailityOfGridConnection_per_hour''.');
    param.var.v2g_p_Grid=extraparams.v2g_probailityOfGridConnection_per_hour;
    param.const.v2g_e_cons=extraparams.v2g_dailyEnergyConsumption;
    if dt~=1
      param.var.v2g_p_Grid=interp1(0:23, param.var.v2g_p_Grid, linspace(0,23,24/dt));
    end
end

%% CHP Units

if~isempty(find([param.dispUnits.isCHP],1))
    for i=find([param.dispUnits.isCHP])
        data_pq=get(modelicaread(strcat(filedir,param.dispUnits(i).p_q)), 'Data');
        % support for normalized diagrams:
        if ~isempty(strfind(param.dispUnits(i).p_q,'norm.txt'))
            % Example: 125 MWel / 180 MWth
            data_pq(:,1)=data_pq(:,1)*param.dispUnits(i).Q_0*1e6;
            data_pq(:,2:3)=data_pq(:,2:3)*param.dispUnits(i).P_0*1e6;
        end
        %data_pq=[1,6,2;2,8,4];
        [param.dispUnits(i).a , param.dispUnits(i).b ]=getCoefficient_CHP_Equation(data_pq,param.dispUnits(i).Name);
        % replace p_min for chp units with pq diagram with small value since that
        % constraint is the one that's important        
        param.dispUnits(i).p_min=0;
    end
end
%
% >> Set global energy start level to type specific value
for i=1:param.const.ndu; param.dispUnits(i).e_start_t=param.dispUnits(i).e_start;  end;
if saveResultFiles; saveParameters(['output/TEP_Parameters_' scenario '.zip'], param); end;