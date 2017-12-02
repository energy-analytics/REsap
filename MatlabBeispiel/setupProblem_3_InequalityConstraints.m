%
% >> Preallocate
nrowbalancing=2*length(union(isPriBalUnit, isSecBalUnit));
nelbalancing=6*length(setxor(isPriBalUnit, isSecBalUnit))...
    +8*length(intersect(isPriBalUnit, isSecBalUnit))...
    +4*length(intersect(isSecBalUnit, union(isDSS, isPowerUser)));
acogen=0;
for i=isCHP
    acogen=acogen+size(param.dispUnits(i).a,1);
end
nineq=np*(...
    2*length(setdiff(union(isVarPowLim,isFixLoadCur),isStateUnit))...
    +2*length(intersect(isStateUnit,isPowerUnit))...
    +3*length(isV2G)...
    +nrowbalancing...
    +4*length(isStorage)...
    +2*length(isDSS)...
    +1 ...
    +2*acogen)...
    +(np-1)*(3*length(isStateUnit)+2*length(isImport));
nelineq=np*(...
    2*length(setdiff(union(isVarPowLim,isFixLoadCur),isStateUnit))...
    +4*length(intersect(isStateUnit,isPowerUnit))...
    +3*length(isV2G)...
    +nelbalancing...
    +8*length(isStorage)...
    +2*length(isDSS)...
    +length(intersect(isSynchronizedUnit, isStateUnit))...
    +6*acogen)...
    +(np-1)*(9*length(isStateUnit)+4*length(isImport));
Aineq=spalloc(nineq, param.const.nvar, nelineq);%zeros(nineq, param.const.nvar);
bineq=zeros(nineq,1);
row=1;
%
% >> Constraints in every timestep
for t=1:np 
    %fprintf('%s %f %s %f\n','Starting with inequality constraints at timestep',t, 'and row', row)
    if ~isempty(isVarPowLim) 
        p_min(isVarPowLim)=ones(1, length(isVarPowLim)).*param.var.p_min_t(t,:);%#ok<SAGROW>
        p_max(isVarPowLim)=ones(1, length(isVarPowLim)).*param.var.p_max_t(t,:);%#ok<SAGROW>
    end
    if ~isempty(isFixLoadCur)
        p_min(isFixLoadCur)=ones(1, length(isFixLoadCur)).*param.var.p_t(t,:);%#ok<SAGROW>
        p_max(isFixLoadCur)=ones(1, length(isFixLoadCur)).*param.var.p_t(t,:);%#ok<SAGROW>
    end
    %
    % >>Variable Power Limits Unit (e.g. biomass or cogeneration units in
    % decoupled simulation)
    for i=setdiff(union(isVarPowLim,isFixLoadCur),isStateUnit)                                                       % Micro CHP has no state since it represents a large no. of plants (always on)
        % 1. Max Power constraint: P <= Pmax        
        Aineq(row, idxP(i,t))=1;
        bineq(row)=p_max(i);
        row = row+1;
        % 2. Min Power constraint: P >= Pmin
        Aineq(row, idxP(i,t))=-1;
        bineq(row)=-p_min(i);
        row = row+1;        
    end    
    %>>StateUnit
    for i=intersect(isStateUnit,isPowerUnit)
        % Maximum power constraint: P-z*Pmax <= 0
        Aineq(row, idxP(i,t))=1;
        Aineq(row, idxZ(i,t))=-p_max(i);
        row=row+1;
        % Minimum power constraint: -P + z*Pmin <= 0
        Aineq(row, idxP(i,t))=-1;
        Aineq(row, idxZ(i,t))=p_min(i);
        row=row+1; 
    end
    % 
    % Vehicle 2 grid constraints: Pmax is dependent on number of grid    
    % connected vehicles which is modeled by time dependent probability
    % function
    for i=isV2G
        Aineq(row, idxP(i, t))=1;
        bineq(row)=param.var.v2g_p_Grid(t);
        row=row+1; 
    end
    %
    % > Primary reserve; unit band widths
    for i=isPriBalUnit
        Aineq(row,idxPpr(i,t))=param.const.P_Pri/P_0(i);
        bineq(row)=param.const.P_Pri_Bandwidth;
        row=row+1;
    end
    %
    % > Secondary reserve; unit band widths (5 min * maximum gradient)
    for i=isSecBalUnit
        if ~(ismember(i, isCurt) || ismember(i,isDSS))
        Aineq(row,idxPsecPos(i,t))=param.const.P_Sec_up/P_0(i);
        bineq(row)=param.const.deltat_Sec*p_grad_max(i);
        row=row+1;
        Aineq(row,idxPsecNeg(i,t))=param.const.P_Sec_down/P_0(i);
        bineq(row)=param.const.deltat_Sec*p_grad_max(i);
        row=row+1;
        elseif ismember(i,isCurt)
        % P_sec_pos_RE < P_curt
        Aineq(row,idxPsecPos(i,t))=param.const.P_Sec_up;
        Aineq(row,idxP(i,t))=P_0(i);
        bineq(row)=0;
        row=row+1;
        % P_sec_neg_RE < P_RE
        Aineq(row,idxPsecNeg(i,t))=param.const.P_Sec_down;
        bineq(row)=sum(param.var.P_RE_t(t,:), 2);
        row=row+1;
        end
    end
    %
    % > Primary and secondary reserve   
    for i=union(isPriBalUnit, isSecBalUnit)
        if ismember(i, isStateUnit)                                         % state units, e.g. thermal plants
            % Upwards
            Aineq(row, idxP(i,t))= 1;
            Aineq(row, idxZ(i,t))= -p_max(i);
            if ismember(i, isPriBalUnit)
                Aineq(row, idxPpr(i,t))= param.const.P_Pri/P_0(i);
            end
            if ismember(i,isSecBalUnit)
              Aineq(row, idxPsecPos(i,t))= param.const.P_Sec_up/P_0(i);
            end
            row=row+1;
            % Downwards:
            Aineq(row, idxP(i,t))= -1;
            Aineq(row, idxZ(i,t))= p_min(i);
            if ismember(i, isPriBalUnit)
               Aineq(row, idxPpr(i,t))= param.const.P_Pri/P_0(i);
            end
            if ismember(i,isSecBalUnit)
              Aineq(row, idxPsecNeg(i,t))= param.const.P_Sec_down/P_0(i);
            end
            row=row+1;            
        elseif ismember(i, isStorage)                                       % storage units, e.g. pump storage
            % Upwards:
            % p + p_pr * P_pri / P_0 <= p_max
            Aineq(row, idxP(i,t))= 1;
            Aineq(row, idxP(i+1,t))= 1; % hier stand vorher -1
            if ismember(i, isPriBalUnit)
                Aineq(row, idxPpr(i,t))= param.const.P_Pri/P_0(i);
            end
            if ismember(i,isSecBalUnit)
                Aineq(row, idxPsecPos(i,t)) = param.const.P_Sec_up/P_0(i);
            end            
            bineq(row)=p_max(i);            
            row=row+1;
            % Downwards:
            % p - p_pr * P_pri / P_0 >= 0        
            Aineq(row, idxP(i,t))= 1; % hier stand vorher -1
            Aineq(row, idxP(i+1,t))= 1;
            if ismember(i, isPriBalUnit)
                Aineq(row, idxPpr(i,t))= param.const.P_Pri/P_0(i);
            end
            if ismember(i,isSecBalUnit)
                Aineq(row, idxPsecNeg(i,t)) = param.const.P_Sec_down/P_0(i);
            end            
            bineq(row)=p_max(i+1);            
            row=row+1;
        elseif ismember(i, union(isPowerUser,isDSS))    
             % p_sec_up <= p_is
            Aineq(row, idxP(i,t))= -1;
            Aineq(row, idxPsecPos(i,t))= -param.const.P_Sec_up/P_0(i);
            bineq(row)=0;
            row=row+1;
            %         
            % p_sec_down <= p_0 - p_is
            Aineq(row, idxP(i,t))= 1;
            Aineq(row, idxPsecNeg(i,t))= -param.const.P_Sec_down/P_0(i);
            bineq(row)=p_max(i);
            row=row+1;
        elseif ismember(i,isVarPowLim) % e.g. biomass (no storage, no state, no user)
            % p + p_sec_up * P_sec_up / P_0 <= p_max
            Aineq(row, idxP(i,t))= 1;
            Aineq(row, idxPsecPos(i,t))= param.const.P_Sec_up/P_0(i);
            bineq(row)=p_max(i);
            row=row+1;
            %         
            % p - p_down * P_sec_down / P_0 >= 0    
            Aineq(row, idxP(i,t))= -1;
            Aineq(row, idxPsecNeg(i,t))= param.const.P_Sec_down/P_0(i);
            bineq(row)=0;
            row=row+1; 
        elseif ~ismember(i, isCurt)
            error('Unexpected type of balancing provider defined, please check scenario and code again (DSS is not yet implemented properly)')           
        end
    end
    %
    %>> Storage constraints
    %   Power Storage
    for i=setdiff(isStorage,isHeatUnit)
        % > Pgen <= w*Pgenmax   (If generating (w=1) Pgen < w*Pgenmax else Pgen=0)
        Aineq(row, idxP(i, t))=1;
        Aineq(row, idxW(i, t))=-p_max(i);        
        row=row+1;
        % > Pcons <= (1-w)Pconsmax  (If consuming (w=0) Pgen =0 and Pcons < Pconsmax)
        Aineq(row, idxP(i+1, t))=1;
        Aineq(row, idxW(i,t))=p_max(i+1);
        bineq(row)=p_max(i+1);
        row=row+1;                
        % > Maximum charge constraint
        Aineq(row, idxP(i,1:t))=-1/eta(i)*k_add(i)*param.const.dt;     % turbine operation 
        Aineq(row, idxP(i+1,1:t))=-eta(i+1)*P_0(i+1)/P_0(i)*param.const.dt;          % pump operation
        bineq(row)=e_max(i)-e_start(i);     
        row=row+1;
        % > Minimum charge constraint
        Aineq(row, idxP(i,1:t))=1/eta(i)*param.const.dt*k_add(i);         % turbine operation 
        Aineq(row, idxP(i+1,1:t))=eta(i+1)*P_0(i+1)/P_0(i)*param.const.dt;        % pump operation
        bineq(row)= e_start(i)-e_min(i);             
        row=row+1;
    end
    % Heat Storage
	for i=setdiff(isStorage,isPowerUnit)
        % > Qout <= w   (If generating (w=1) Qout <= 1 else Qout<=0)
        Aineq(row, idxQ(i, t))=1;
        Aineq(row, idxW(i, t))=-1;        
        row=row+1;
        % > Qin <= (1-w)  (If consuming (w=0) Qin <= 1 else Qin<=0)
        Aineq(row, idxQ(i+1, t))=1;
        Aineq(row, idxW(i,t))=1;
        bineq(row)=1;
        row=row+1;                
        % > Maximum charge constraint
        Aineq(row, idxQ(i,1:t))=-1/eta(i)*param.const.dt;     % turbine operation 
        Aineq(row, idxQ(i+1,1:t))=-eta(i+1)*Q_0(i+1)/Q_0(i)*param.const.dt;          % pump operation
        bineq(row)=e_max(i)-e_start(i);     
        row=row+1;
        % > Minimum charge constraint
        Aineq(row, idxQ(i,1:t))=1/eta(i)*param.const.dt;         % turbine operation 
        Aineq(row, idxQ(i+1,1:t))=eta(i+1)*Q_0(i+1)/Q_0(i)*param.const.dt;        % pump operation
        bineq(row)= e_start(i)-e_min(i);             
        row=row+1;
    end
    %
    % > Vehicle to grid (V2G) storage capacity constraints
    for i=isV2G
        % > Maximum charge constraint
        Aineq(row, idxP(i, 1:t))=param.const.dt;
        bineq(row)=e_max(i)*param.var.v2g_p_Grid(t) - e_start(i)*param.var.v2g_p_Grid(24/param.const.dt);
        row=row+1;
        % > Minimum charge constraint
        Aineq(row, idxP(i,1:t))=-param.const.dt;
        bineq(row)= -(e_min(i)*param.var.v2g_p_Grid(t) - e_start(i)*param.var.v2g_p_Grid(24/param.const.dt));
        row=row+1;
    end    
    %
    % > Demand side storage (DSS) constraints
    for i=isDSS
        % > Maximum charge constraint        
        Aineq(row, idxP(i,1:t))=eta(i)*param.const.dt;                      % turning on load is aquivalent to pump operation in storages 
        bineq(row)=e_max(i)-e_start(i)+sum(param.var.P_DSSCons_t(1:t))/eta(i)*param.const.dt; % storage is emptied by load    
        row=row+1;
        % > Minimum charge constraint
        Aineq(row, idxP(i,1:t))=-eta(i)*param.const.dt;        
        bineq(row)= e_start(i)-e_min(i)-sum(param.var.P_DSSCons_t(1:t))/eta(i)*param.const.dt;
        row=row+1;        
        %
        % Assignment of helper variable for difference between original and
        % optimized load
       Aineq(row, idxDeltaPosDSS(i,t))=-1;
       Aineq(row, idxP(i,t))=1;
       bineq(row)=param.var.P_DSSCons_t(t);
       row=row+1;
       Aineq(row, idxDeltaNegDSS(i,t))=-1;
       Aineq(row, idxP(i,t))=-1;
       bineq(row)=-param.var.P_DSSCons_t(t);
       row=row+1;        
    end   
%     %
    % > Grid Time constant constraint: sum z*P0*Tgen / Plast >= Tmin 
    % Tmin = 10 - Pwi/0,2% * s
    % z*P0*Tgen >= Tmin * Plast - PTstateless
    % z*P0*Tgen >= (Tminohne - Pwindinertia) * Plast - PTstateless
    % -z*P0*Tgen <= (Tminohne - Pwindinertia) * -Plast + PTstateless
    % P0*Tgen|stateless
    Aineq(row,:)=0;
    if ~isempty(isSynchronizedUnit)
        for i=intersect(isSynchronizedUnit, isStateUnit)
            Aineq(row, idxZ(i,t))=-P_0(i)*param.dispUnits(i).T_gen;
        end
        for i=setdiff(isSynchronizedUnit, isStateUnit)
            Aineq(row, idxP(i,t))=-param.dispUnits(i).P_0*param.dispUnits(i).T_gen;
            if ismember(i, isStorage)
                Aineq(row, idxP(i+1,t))=param.dispUnits(i+1).P_0*param.dispUnits(i-1).T_gen;
            end
        end
    end
    bineq(row)=-param.var.P_dem_t(t) * (param.const.T_N_min ... 
        + param.const.Pwindinertia*sum(param.var.P_RE_t(t,end-1:end)))...
        + param.const.PT_gen_stateless;
    row=row+1;
    %
    % >> Flexible sigma for CHP, Heat and Power generation coupled
    for i=isCHP
        for n=1:length(param.dispUnits(i).a(:,1))
            % > Min Power constraint
            % a*q - p + b*z <= 0  a-> Steigung; b-> Schnitt mit y-Achse
            % <=> p >= b*z + a*q
            Aineq(row,idxQ(i,t))=param.dispUnits(i).a(n,1)*param.dispUnits(i).Q_0;
            Aineq(row, idxP(i,t))=(-1)*param.dispUnits(i).P_0;
            Aineq(row, idxZ(i,t))=param.dispUnits(i).b(n,1);
            row=row+1;
            
            % > Max Power constraint
            % -a*q + p - b*z <= 0  a-> Steigung; b-> Schnitt mit y-Achse
            % <=> p <= b*z + a*q
            Aineq(row,idxQ(i,t))=(-1)*param.dispUnits(i).a(n,2)*param.dispUnits(i).Q_0;
            Aineq(row, idxP(i,t))=param.dispUnits(i).P_0;
            Aineq(row, idxZ(i,t))=(-1)*param.dispUnits(i).b(n,2);
            row=row+1;
        end  
    end
end 
% >> Start-up variables and gradients (only in np-1 timesteps)
for t=1:np-1

    % first check if max power in next step is time dependent
    if ~isempty(isVarPowLim)
        p_max_tp1(isVarPowLim)=ones(1, length(isVarPowLim)).*param.var.p_max_t(t+1,:);%#ok<SAGROW>
    end;
    if ~isempty(isFixLoadCur)
        p_max(isFixLoadCur)=ones(1, length(isFixLoadCur)).*param.var.p_t(t+1,:);%#ok<SAGROW>
    end;

    for i=isStateUnit       
        % 1: Relation between z and zs
        Aineq(row, idxZ(i,t))=-1;
        Aineq(row, idxZ(i,t+1))=1;
        Aineq(row, idxZs(i,t))=-1;
        row=row+1;        
        % 2: Maximum positive power gradient: 
        % P_t+1 - P_t - Pgradmax * z_t+1 * dt + Pmax_t+1 * z_t+1 <= Pmax_t+1
        Aineq(row, idxP(i,t+1))=1;
        Aineq(row, idxP(i,t))=-1;
        Aineq(row, idxZ(i,t+1))=-p_grad_max(i)*param.const.dt+p_max_tp1(i);
        bineq(row)=p_max_tp1(i);
        row=row+1; 
        % 3: Maximum negative power gradient:
        %       P_t - P_t+1 - Pgradmax * z_t * dt + Pmax_t+1 * z_t <= Pmax_t+1        
        Aineq(row, idxP(i,t))=1;
        Aineq(row, idxP(i,t+1))=-1;
        Aineq(row, idxZ(i,t))=-p_grad_max(i)*param.const.dt+p_max_tp1(i) ;
        bineq(row)=p_max_tp1(i);
        row=row+1;         
    end
end
for i=isImport
    for t=1:np
        if t==1 
            % Positive gradient:
            Aineq(row, idxP(i,t))=1;
            bineq(row)=p_grad_max(i)*param.const.dt+param.dispUnits(i).p_init;
            row=row+1;
            % Negative gradient.
            Aineq(row, idxP(i,t))=-1;
            bineq(row)=p_grad_max(i)*param.const.dt-param.dispUnits(i).p_init;
            row=row+1;        
        else
            % Positive gradient:
            Aineq(row, idxP(i,t))=1;
            Aineq(row, idxP(i,t-1))=-1;
            bineq(row)=p_grad_max(i)*param.const.dt;
            row=row+1;
            % Negative gradient.
            Aineq(row, idxP(i,t))=-1;
            Aineq(row, idxP(i,t-1))=1;
            bineq(row)=p_grad_max(i)*param.const.dt;
            row=row+1;        
        end
    end
end
pause(0);