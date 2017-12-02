% =========================== Calculations ===============================
%
% > Shortcut notation
IndexSetsandShortCut;
set(0,'DefaultAxesLineStyleOrder',{'-','--',':','-'})
P_t=X_total.P_t;
Q_t=X_total.Q_t;
zs_t=X_total.zs_t;
z_t=X_total.z_t;
iCurt=find([param.dispUnits.isCurt]);                                       % index of curtailment unit
isDisp=1:param.const.ndu;
dt=param.const.dt;

% if isempty(isCHP);isCHP=0;end;
% if isempty(isPowerUnit);isPowerUnit=0;end;
% if isempty(isHeatUnit);isHeatUnit=0;end;
%
% > Calculate timeseries of power
rng=1:np*rh*ni;                                                          % Index range of simulation
if param.const.nREu > 0
    P_REfluct_th=globalts.P_RW_t(rng)+globalts.P_PV_t(rng)+...
        globalts.P_On_t(rng)+globalts.P_Off_t(rng);                             % Potential RE power
    
    if isempty(iCurt);   
        P_Curt=0; 
    else P_Curt=P_t(:,find(isPowerUnit==iCurt));
    end
    P_REfluct_is=P_REfluct_th-P_Curt;                                                       % Resulting (usable) RE power
else
    [P_REfluct_is,P_REfluct_th,P_Curt]=deal(zeros(size(P_t,1),1));
end
iBM=find(strcmp({param.dispUnits.Type}, 'BM'));
if ~isempty(iBM)
    P_BM=P_t(:, find(isPowerUnit==iBM));                    % Biomass units
else
    P_BM=zeros(size(P_t,1),1);
end
P_RE_is=P_REfluct_is+P_BM;
P_Dem_old=globalts.P_dem_t(rng);
P_PtH=-P_t(:,intersect(isPowerUser, isHeatProducer));
if isempty(P_PtH); P_PtH=zeros(size(P_Dem_old)); end;
P_Dem=globalts.P_dem_t(rng)+P_PtH;                                                % Demand is sum of old demand plus Power2Heat Demand
P_Residual=P_Dem-P_REfluct_th;                                              % Residual load: Load minus fluctuating RE power potential
P_min_CHP=0;
Q_Dem=globalts.Q_dem_t(rng);

% if sum([param.dispUnits.isCHP])>0
%     P_min_CHP=sum(globalts.p_CHP_min_t(rng, :)*[param.dispUnits(find([param.dispUnits.isCHP])).P_0]'); %#ok<*FNDSB>
% end

%
% > Calculate generated energy and full load hours
E_el_demand=dt*sum(P_Dem);
% Add DSM demand to electric demand (uncommented, because it is subtracted
% in initScenario
for i=isDSS
    E_el_demand=E_el_demand-dt*sum(P_t(:,i));
end
E_th_demand=dt*sum(Q_Dem);
E=dt*sum(P_t, 1);
E_REfluct_th=dt*sum(sum(P_REfluct_th));                                     % Fluctuating RE potential
E_BM=sum(P_BM)*dt;
if strcmp({param.dispUnits.Type}, 'BM')
    E_BM_th=param.dispUnits(find(strcmp({param.dispUnits.Type},'BM'))).P_0*7886*np*rh*ni*dt/(366*24);
else
    E_BM_th=sum(P_BM)*dt;
end
E_RE_th=E_REfluct_th+E_BM_th;                                          % total RE potential
E_Curt=dt*-sum(P_Curt);
if isempty(E_Curt)
    E_Curt=0;
end
E_REfluct_is=E_REfluct_th-E_Curt;
E_RE_is=E_REfluct_is+E_BM;
P_0_tot=[P_0 [param.REUnits.P_0]];
E_fossil=dt*sum(sum(P_t(:, find([param.dispUnits.isFossil])))); 
E_mustrun=dt*(param.const.P_Pri+P_min_CHP);
x_mustrun_demand=E_mustrun/E_el_demand*100;
x_fossil_demand=E_fossil/E_el_demand*100;
x_fossildisp_demand=(E_fossil-E_mustrun)/E_el_demand*100;
x_spinning_demand=dt*np*rh*ni*param.const.P_Pri/E_el_demand*100;
x_chpmin_demand=x_mustrun_demand-x_spinning_demand;
%
% > Map results to fuel types (statically)
nuc=1;lign=2;bc=3;ng=4;othrs=0;bio=5;
% this must match getTypeDefinition()
typeDefFuels=[nuc lign bc bc bc bc ng ng othrs othrs othrs bio othrs nan ...
    bc ng bc bc othrs othrs othrs othrs othrs othrs othrs othrs othrs ...
    othrs bc];
if strcmp(scenario,'VALID')
    typeDefFuels(4)=ng; % KWK in Hamburg ist hauptsächlich steinkohle, aber in Deutschland hauptsächlich gas (vgl. Gores2014a, Tab. 2-5)
end
typedef=getTypeDefinition();
map2fuel=containers.Map({typedef.Type}, typeDefFuels);
fuels=cell2mat(values(map2fuel,{param.dispUnits(isPowerUnit).Type}));
E_nuc=sum(E(fuels==nuc));
E_lign=sum(E(fuels==lign));
E_bc=sum(E(fuels==bc));
E_ng=sum(E(fuels==ng));
E_bm=sum(E(fuels==bio));
E_others=sum(E(fuels==othrs));
E_row=dt*sum(globalts.P_RW_t(rng));
E_pv=dt*sum(globalts.P_PV_t(rng));
E_on=dt*sum(globalts.P_On_t(rng));
E_off=dt*sum(globalts.P_Off_t(rng));
E_wind=E_on+E_off;
namesPerEnergy={'Nuclear', 'Lignite', 'BlackCoal', 'NaturalGas', 'Biomass', 'Runoff', 'PV','On','Off', 'Wind', 'Others'};
energyPerEnergy=[E_nuc E_lign E_bc E_ng E_bm E_row E_pv E_on E_off E_wind E_others];
installedPerEnergy=[sum(P_0_tot(fuels==nuc)) sum(P_0_tot(fuels==lign)) sum(P_0_tot(fuels==bc)) ...
    sum(P_0_tot(fuels==ng)) sum(P_0_tot(fuels==bio)) P_0_tot(end-3:end) sum(P_0_tot(end-1:end)) sum(P_0_tot(fuels==othrs))];
fullLoadHoursPerEnergy=energyPerEnergy./installedPerEnergy*(8760/(np*ni));
resultsPerEnergy=array2table([fullLoadHoursPerEnergy; energyPerEnergy./E_el_demand*100], ...
    'VariableNames', namesPerEnergy, 'RowNames', {'Full load hours', 'Fraction of demand (in %)'});
if strcmp(scenario,'VALID')
    relerr=@(ref,x)round((x-ref)./ref*100,2);
    xref=[15.8 25.6 18.5 12.2 6.1 3.5 4.2 8 0.1 8.1 4.1]; % Fraction of demand according to AGEB2015 for 2012
    flhref=xref/100*sum(E)./installedPerEnergy;
    refResultsPerEnergy=array2table(...
        [flhref;relerr(flhref, fullLoadHoursPerEnergy);...
        xref; ...
        energyPerEnergy/sum(E)*100-xref], ...
    'VariableNames', namesPerEnergy, 'RowNames', {'Full load hours Ref','Deviation in percent', 'Fraction of demand Ref (in %)','Deviation in percent (energy)'});
    writetable([resultsPerEnergy(1,:); refResultsPerEnergy(1:2,:);resultsPerEnergy(2,:); refResultsPerEnergy(3:4,:)],strcat('output/Validationresults','.csv'));
end
%
% > Time series of grid time constant
P_0_stateUnits=[param.dispUnits(find([param.dispUnits.isStateUnit])).P_0];
T_gen_stateUnits=[param.dispUnits(find([param.dispUnits.isStateUnit])).T_gen];
P_0_rot=z_t*(P_0_stateUnits.*T_gen_stateUnits)'+param.const.PT_gen_stateless;
if ~isempty(P_0_rot)
H_t=P_0_rot./P_Dem;
else
    H_t=zeros(size(P_t));
end
%
% > Compute storage levels
isStor=find([param.dispUnits.isStorage]);                                   % index of storage units
isStor_el=intersect(isPowerUnit,isStor); 
isStor_heat=intersect(isHeatUnit,isStor); 

if ~isempty(isStor)
    P_storage_prod=zeros(np*rh*ni, param.const.nsu);
    E_storage=zeros(np*rh*ni+1, param.const.nsu);                              % one more element for start value (e_start)
    p_storage=zeros(np*rh*ni,param.const.nsu);
    e_storage=zeros(np*rh*ni+1,param.const.nsu);
    for i=isStor;
        iStor=isDisp(isStor==i);                                            % index of storage unit in storage index set (first storage: iStor=1 but may be unit 10, i.e. i=10)
        iPower=isDisp(isPowerUnit==i);
        iHeat=isDisp(isHeatUnit==i);
        if find(i==isStor_el) 
            P_storage_prod(:,iStor)=P_t(:,iPower)/eta(iPower)+P_t(:,iPower+1)*eta(iPower+1);
            E_storage(1,iStor)=param.dispUnits(i).e_start*P_0(i);
            E_storage(2:end,iStor)=E_storage(1,iStor)-cumsum(P_storage_prod(:,iStor))*dt; 
            p_storage(:,iStor)=bsxfun(@rdivide, P_storage_prod(:,iStor), P_0(i));
            e_storage(:,iStor)=bsxfun(@rdivide, E_storage(:,iStor), param.dispUnits(i).e_max*P_0(i));
        elseif find(i==isStor_heat)  
            P_storage_prod(:,iStor)=Q_t(:,iHeat)/eta(iHeat)+Q_t(:,iHeat+1)*eta(iHeat+1);
            E_storage(1,iStor)=e_start(i)*Q_0(i);
            E_storage(2:end,iStor)=E_storage(1,iStor)-cumsum(P_storage_prod(:,iStor))*dt;    
            p_storage(:,iStor)=bsxfun(@rdivide, P_storage_prod(:,iStor), Q_0(i));
            e_storage(:,iStor)=bsxfun(@rdivide, E_storage(:,iStor), param.dispUnits(i).e_max*Q_0(i));
        end
    end   
    
end
%
% > Compute Demand side storage (DSS) levels 
isDSS=find([param.dispUnits.isDSS]);
if ~isempty(isDSS)
    [P_DSS_fromGrid, P_DSS_fromStor]=deal(zeros(np*rh*ni, param.const.ndss));
    E_DSM=zeros(np*rh*ni+1, param.const.ndss);
	for i=isDSS;
		iDSS=isDisp(isDSS==i);
		E_DSM(1,iDSS)=e_start(i)*P_0(i)*-1;
		P_DSS_fromGrid(:,iDSS)=-P_t(:,i);
        P_DSS_fromStor(:,iDSS)=globalts.P_DSSCons_t(1:np*rh*ni,:)*P_0(i)/param.dispUnits(i).eta;
		E_DSM(2:end,iDSS)=E_DSM(1,iDSS)+cumsum(P_DSS_fromGrid(:,iDSS)+P_DSS_fromStor(:,iDSS))*dt;        
	end
    p_DSS_fromGrid=bsxfun(@rdivide, P_DSS_fromGrid, -P_0(isDSS));
    p_DSS_fromStor=bsxfun(@rdivide, -P_DSS_fromStor, P_0(isDSS));
    e_DSS=bsxfun(@rdivide, E_DSM, -1.*e_max(isDSS).*P_0(isDSS));
end
%
% > Compute emobility storage (V2G) levels
isVTG=find([param.dispUnits.isV2G]);
for i=isVTG
    E_G2V=zeros(np*rh*ni+1, 1);
    P_G2V=-P_t(:,i);
    E_G2V(1)=e_start(i)*P_0(i)*-1;
    E_G2V(2:end)=E_G2V(1)+cumsum(P_G2V)*dt;
    for x=1:ni                                                              % At the end of each 24 hours load is applied
        E_G2V(1+x*np:end)=E_G2V(1+x*np:end)+param.const.v2g_e_cons*P_0(i);
    end
    Prob_V2G=repmat(param.var.v2g_p_Grid, 1, ni)';
    e_G2V=bsxfun(@rdivide, E_G2V , -1*e_max(i)*P_0(i).*[Prob_V2G(24/dt);Prob_V2G]);    
    p_G2V=bsxfun(@rdivide, P_G2V, P_0(i).*Prob_V2G);
end
%
% > Calculate variable costs (without artificial costs for storages etc.)
Cprod=[param.dispUnits.c_prod];
Cstart=[param.dispUnits.c_start];
iSU=find([param.dispUnits.isStateUnit]);                                    % Index of state units
isImport=find(strcmp({param.dispUnits.Type}, 'Import'));
isVariableCost=setdiff(setdiff(find([param.dispUnits.c_prod] > 0), isImport), isStor);
%isVariableCost=isDisp;
%fuelcost=sum(P_t(:,isVariableCost), 1)*Cprod(isVariableCost)';

% > fuelcost
fuelcost_P=0;
fuelcost_Q=0;
fuelcost_CHP=0;
fuelcost_PowerUser=0;
for i=setdiff(isPowerUnit,[isCHP isPowerUser iCurt])
    fuelcost_P=fuelcost_P+sum(P_t(:,find(isPowerUnit==i)), 1)*Cprod(i)';
end

for i=setdiff(isHeatUnit,[isCHP isPowerUser isBTTP])
    fuelcost_Q=fuelcost_Q+sum(Q_t(:,find(isHeatUnit==i)), 1)*Cprod(i)';
end

for i=intersect(isPowerUnit,isCHP)
    fuelcost_CHP=fuelcost_CHP+((sum(P_t(:,find(isPowerUnit==i)), 1)*param.dispUnits(i).alphaHeatInput(1) +...
                  sum(Q_t(:,find(isHeatUnit==i)), 1)*param.dispUnits(i).alphaHeatInput(2)+param.dispUnits(i).alphaHeatInput(3)) * Cprod(i)');
end
for i=intersect(isPowerUnit,isPowerUser)
    fuelcost_PowerUser=fuelcost_PowerUser+sum(P_t(:,find(isPowerUnit==i)), 1)*-Cprod(i)';
end

fuelcost=fuelcost_P+fuelcost_Q+fuelcost_CHP+fuelcost_PowerUser ;
startcost=sum(zs_t(:,:), 1)*[Cstart(iSU).*P_0(iSU)]';
mainResults=cell2table({...
   'E_RE_th / E_el_demand (%)',               E_RE_th/E_el_demand*100; ...
   'E_RE_used / E_el_demand (%)',             E_RE_is/E_el_demand*100; ...
   'E_RE_fluct_th / E_el_demand (%)',         E_REfluct_th/E_el_demand*100;...
   'E_RE_fluct_used / E_el_demand (%)',       (E_REfluct_th-E_Curt)/E_el_demand*100;...    
   'E_BM / E_el_demand (%)',                  E_BM/E_el_demand*100;...
   'E_curt / E_el_demand (%)',                E_Curt/E_el_demand*100; ...
   'E_curt / E_RE_total (%)',              E_Curt/E_RE_th*100; ...
   'E_curt / E_RE_fluct (%)',              E_Curt/E_REfluct_th*100; ...
   'E_mustrun / E_fossil (%)',             E_mustrun/E_fossil*100; ...
    'Total cost (EUR)',                     fuelcost+startcost; ...
    'Average curtailed RE (MW)',            -mean(P_Curt);...
    'RMS of scheduling (MW)',               rms(sum(P_t, 2)-globalts.P_dem_t(rng))},...
    'VariableNames', {'Variable', 'Value'});
%UnitResults (full load hours)
if length(isPowerUnit)>0
    fullLoadHours_electricUnits=array2table([sum(P_t, 1)./[param.dispUnits(isPowerUnit).P_0 param.REUnits.P_0]/np/ni*8760; [param.dispUnits(isPowerUnit).P_0 param.REUnits.P_0]],...
        'VariableNames',{param.dispUnits(isPowerUnit).Name param.REUnits.Name},...
        'RowNames', {'Full load hours' , 'Instaled Power in MW'});
else
    fullLoadHours_electricUnits='>> No electric units in scenario';
end;
if length(isHeatUnit)>0
    fullLoadHours_thermalUnits=array2table(sum(Q_t, 1)./[param.dispUnits(isHeatUnit).Q_0]/np/ni*8760,'VariableNames',{param.dispUnits(isHeatUnit).Name});
else 
    fullLoadHours_thermalUnits='>> No thermal units in scenario';
end;
if logresults; 
    disp('>> Main results of simulation:'); 
    disp('>>');disp(mainResults); 
    disp('>> Full load hours of units:'); 
    disp('>>');disp(fullLoadHours_electricUnits);
    disp('>>');disp(fullLoadHours_thermalUnits);    
    disp('Results per energy carrier:');
    disp(resultsPerEnergy);
    if strcmp(scenario,'VALID')
        disp('Expected values')
        disp(refResultsPerEnergy)
    end    
    %Detail_Leistungsaufstellung_Units;
end;
E_CHP_legacy=sum(E(~cellfun(@isempty, {param.dispUnits.p_min_t})));
%sum(E(~cellfun(@isempty, {param.dispUnits.p_min_t})))/sum(E)*100;
%sum(E(and(~cellfun(@isempty, {param.dispUnits.p_min_t}), fuels==ng)))/sum(E)*100; % Fraction of CHP production with natural gas (as an example)

%
% =========================== Figures ===============================
%
% > Plot Figures
if plotfigures
    tplot=0:dt:np*rh*ni*dt-dt;
    %
    % > Total power production overview plot
    z=1;    
    plot(P_Dem_old-P_REfluct_th,'-ok');hold on;grid minor;
    names{z}='Residuallast (vor PtH)';
    for i=isPowerUnit
            iPU=isDisp(isPowerUnit==i);
        if ~sum(P_t(:,iPU)); continue; end;
        stairs(P_t(:,iPU));
        z=z+1;names{z}=param.dispUnits(i).Name;
    end
    legend(names);title(strcat('Power production (Scenario: ',scenario, ')'));
    xlabel('Time in hours');
    ylabel('Power in MW');
        
    %
    % > Total heat production overview plot
    if ~isHeatUnit==0    
        figure
        set(0,'DefaultAxesLineStyleOrder',{'-','--',':','-'})
        z=1;    
        plot(Q_Dem,'-ok');hold on;grid minor;
        names='';
        names{z}='Last';
        for i=isHeatUnit
                iHeat=isDisp(isHeatUnit==i);
            if ~sum(Q_t(:,iHeat)); continue; end;
            stairs(Q_t(:,iHeat));
            z=z+1;names{z}=param.dispUnits(i).Name;
        end
        legend(names);title(strcat('Heat production (Scenario: ',scenario, ')'));
        xlabel('Time in hours');
        ylabel('Power in MW'); 
    end

    %
    % > Storage production plot
    if ~isempty(isStor)
        figure; 
        plot(e_storage,'-o'); hold on; 
        plot(p_storage,'-x');
        stornames=char({param.dispUnits(isStor).Name});
        nstor=length(isStor);
        legend([[[char(ones(nstor,1)*'E') char(ones(nstor,1)*'_')];[char(ones(nstor,1)*'P') char(ones(nstor,1)*'_')]] [stornames;stornames]])
        grid minor; title(strcat('Storage levels (Scenario: ',scenario, ')'));
        ylabel('Entladeleistung (>0 = Speicher wird entladen)')
    end
    
    %
    % > Demand side storage plot
    if ~isempty(isDSS)
        figure;         
        plot([-1 tplot], e_DSS,'-o'); hold on; 
        plot(tplot,p_DSS_fromGrid,'-x');
        plot(tplot,p_DSS_fromStor,'-s');
        l=legend;
        for idss=1:length(isDSS)
            thisDSSName=param.dispUnits(isDSS(idss)).Name;
            tempLeg={'E DSM','P DSM grid2stor','P DSM stor2cons'};
            thisLeg=strrep(tempLeg, 'DSM',thisDSSName);
            l=legend([l.String,thisLeg]);
        end
        plot(tplot,P_Residual./max(abs(P_Residual)),'-ok');
        plot(tplot,P_Curt./max(abs(P_Curt)),'-.k');
        legend([l.String, 'P_{Residual}', 'P_{Curtailed}'], 'Location', 'EastOutside');grid minor;title(strcat('Demand response (Scenario: ',scenario, ')'));
    end;
    %
    % > Show V2G plots
    if ~isempty(isVTG)
        figure; 
        plot([-1 tplot], e_G2V(1:end), '-o'); hold on;
        plot(tplot, -p_G2V, '-x')
        plot(tplot,P_Residual./max(abs(P_Residual)),'-ok');
        legend('E_V2G', 'P_V2G', 'R_{Residual}')
    end
    %
    % > Show primary reserve units
    %pribalunits=param.dispUnits(sum(X_total.Ppr_t~=0, 1)~=0);    
    pribalunits=param.dispUnits(isPriBalUnit);
    pribalunits_used=param.dispUnits(isPriBalUnit(sum(X_total.Ppr_t~=0, 1)~=0));        
    
    figure; axes;
    l=legend;
    for i=[pribalunits_used.Key]
        iPriBalUnit=isDispUnit(isPriBalUnit==i);
        plot(tplot, X_total.Ppr_t(:,iPriBalUnit)*param.const.P_Pri);
        hold on;
        l=legend([l.String, pribalunits(iPriBalUnit).Name]);
    end
    xlabel('Time');ylabel('Primary reserve in MW'); title('Primary Reserve Allocation');
    %
    % > Show secondary reserve units
    
    %secbalunits_pos=param.dispUnits(sum(X_total.PsecPos_t~=0, 1)~=0);
    %secbalunits_neg=param.dispUnits(sum(X_total.PsecNeg_t~=0, 1)~=0);
    
    secbalunits=param.dispUnits(isSecBalUnit);
    secbalunits_pos=secbalunits(sum(X_total.PsecPos_t~=0, 1)~=0);
    secbalunits_neg=secbalunits(sum(X_total.PsecNeg_t~=0, 1)~=0);
    
    isSecBalUnits_pos=[secbalunits_pos.Key];
    isSecBalUnits_neg=[secbalunits_neg.Key];
    
    figure; axes;
    l=legend;
    for i=isSecBalUnits_pos
        iSecBalUnits_pos=isDispUnit(isSecBalUnit==i);        
        plot(tplot, X_total.PsecPos_t(:,iSecBalUnits_pos)*param.const.P_Sec_up, 'Marker', 'o');
        hold on;
        l=legend([l.String, [secbalunits(iSecBalUnits_pos).Name ' (Pos)']]);
    end
    for i=isSecBalUnits_neg
        iSecBalUnits_neg=isDispUnit(isSecBalUnit==i);
        plot(tplot, X_total.PsecNeg_t(:,iSecBalUnits_neg)*param.const.P_Sec_down, 'Marker', 'x');
        hold on;
        l=legend([l.String, [secbalunits(iSecBalUnits_neg).Name ' (Neg)']]);
    end    
    xlabel('Time');ylabel('Secondary reserve in MW'); title('Secondary Reserve Allocation');    
    %
    % > Show grid time constant
    if ~isempty(P_0_rot)

    figure;
    plot(tplot, H_t,'-ok'); hold on;
    plot(tplot, ones(size(tplot))*10);
    grid on;    
    end
    %
    plot_CHP
end;
   

%
% =========================== Data Export ===============================
%
% > Save result files 
if saveResultFiles
    % prepare reserve allocation schedule:
    [P_priBal_t,P_secBalPos_t, P_secBalNeg_t]=deal(zeros(size(P_t)));
    param.elUnits=param.dispUnits(isPowerUnit);
    P_priBal_t(:,find([param.elUnits.isPriBalUnit]))=X_total.Ppr_t.*param.const.P_Pri;
    P_secBalPos_t(:,find([param.elUnits.isSecBalUnit]))=X_total.PsecPos_t.*param.const.P_Sec_up;
    P_secBalNeg_t(:,find([param.elUnits.isSecBalUnit]))=X_total.PsecNeg_t.*param.const.P_Sec_down;    
    elunitnames={param.dispUnits(isPowerUnit).Name param.REUnits.Name};
    thunitnames={param.dispUnits(isHeatUnit).Name};
    % Reorder results for dymola simulation:
    if isfield(param.const, 'reorderResultFile')
        P_priBal_t=P_priBal_t(:,param.const.reorderResultFile);
        P_secBalPos_t=P_secBalPos_t(:,param.const.reorderResultFile);
        P_secBalNeg_t=P_secBalNeg_t(:,param.const.reorderResultFile);
        P_t=P_t(:,param.const.reorderResultFile);
        elunitnames=elunitnames(param.const.reorderResultFile);
    end    
    comments1={['Coupled Unit Commitment Schedule for Generation Park ' scenario ' (nPlants=' num2str(param.const.nu) ', nElDispPlants=' num2str(param.const.ndu-3) ', nDispPlants=' num2str(param.const.ndu-3) ', nDispPlants=' num2str(param.const.ndu-3) '), File created on ', datestr(now, 'dd.mm.yyyy HH:MM')]};
    modelicawrite(strcat(resultPath,'ElectricUnitCommitmentSchedule_',num2str(dt*3600),'s_',scenario,'.txt'),...
        timeseries(P_t, (0:dt*3600:ni*np*rh*dt*3600-dt*3600)'),comments1, 'Units per datacolumn:',sprintf('%s\t', elunitnames{:}));
    smoothRamps(strcat('ElectricUnitCommitmentSchedule_',num2str(dt*3600),'s_',scenario,'.txt'), resultPath);
    modelicawrite(strcat(resultPath,'ThermalUnitCommitmentSchedule_',num2str(dt*3600),'s_',scenario,'.txt'),...
        timeseries(Q_t, (0:dt*3600:ni*np*rh*dt*3600-dt*3600)'),comments1, 'Units per datacolumn:',sprintf('%s\t', thunitnames{:}));
    % prepare comments:
    comments2={['Data Columns 1:' num2str(param.const.nu) ' are Primary Bal Reserves, Columns ' num2str(param.const.nu+1) ':' num2str(2*param.const.nu) ' are Positive Secondary Bal., Columns ' num2str(2*param.const.nu+1) ':' num2str(3*param.const.nu), ' are Negative Secondary Bal.']};
    comments3=['Plants: ' sprintf('%s\t', elunitnames{:})];    
    modelicawrite(strcat(resultPath, 'ReservePowerCommitmentSchedule_',num2str(dt*3600),'s_',scenario,'.txt'),...
        timeseries([P_priBal_t P_secBalPos_t P_secBalNeg_t], (0:dt*3600:ni*np*rh*dt*3600-dt*3600)'), strrep(comments1, 'Unit Commitment Schedule','Reserve Power Commitment Schedule'), comments2);
    writetable(mainResults,strcat('output/OtherResults_', scenario,'.csv'));
    csvwrite(strcat('output/H_t_', scenario,'.csv'), H_t);
    joinResultFiles('./output/','OtherResults*.csv', 'ScenarioResults.xlsx');
end