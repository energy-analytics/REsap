%
% >> Preallocate
neq=np...
    +np*nsites...
    +np*length(isPowerUser)...
    +np*length(isBTTP)...
    +np*length(isMustRun)...
    +np*length(isDSS)...
    +length(isDSS)...
    +np*3;
nelA=np*length(union(isPowerUnit,isPowerUser))...
    +np*length(isHeatUnit)...
    +np*2*length(setdiff(isPowerUser, isStorage))...
    +np*length(isMustRun)...
    +np*length(isPriBalUnit)...
    +np*2*length(isSecBalUnit)...
    +length(isDSS);
Aeq=spalloc(neq, param.const.nvar,nelA);
beq=zeros(neq,1);
%
% >> Set up equality matrix
row=1;
for t=1:param.const.np 
    %
    % >> Aeq1: Power Demand has to be covered
    if ~isempty(isPowerUnit)
        for i=isPowerUnit
            Aeq(row, idxP(i,t))=param.dispUnits(i).P_0;
        end
    beq(row)=param.var.P_dem_t(t)-sum(param.var.P_RE_t(t,:), 2);
    row=row+1;
    end
    %
    % >> Aeq2: Heat Demand has to be covered at every generation site
    if ~isempty(isHeatUnit)
        for s=1:nsites
            for i=intersect(isHeatUnit, isDispUnit([param.dispUnits.site]==s))
                Aeq(row,idxQ(i,t))=param.dispUnits(i).Q_0;   
            end
            beq(row)=param.var.Q_dem_t(t)*param.var.LFsite_t(t,s); 
            row=row+1; 
        end
    end
    %>> Aeq3: Electric peak load boiler
    %Q=!-P*epsilon  --> Q + P*epsilon = 0
    for i=setdiff(isPowerUser, isStorage)
        Aeq(row,idxP(i,t))=1*param.dispUnits(i).P_0*param.dispUnits(i).epsilon ;
        Aeq(row, idxQ(i,t))=1*param.dispUnits(i).Q_0;
        row=row+1;
    end
    %>> Aeq4: BTTP Heat and Power generation coupeled for BTTP
    % 0 = P - Q*sigma
    % TODO: This seems redundant to Aeq3!
    for i = isBTTP 
       Aeq(row, idxP(i,t))= param.dispUnits(i).P_0;
       Aeq(row, idxQ(i,t))= -param.dispUnits(i).sigma* param.dispUnits(i).Q_0;
       row=row+1;
    end
    %>> Aeq2: Plants which have to run
    for i=isMustRun
       Aeq(row,idxZ(i,t))=1;   
       beq(row)=1;          
       row=row+1;
    end
    %
    % > Aeq5: Sum of primary reserve allocation
    for i=isPriBalUnit
       Aeq(row, idxPpr(i,t))= 1;
    end
    beq(row)=1;
    row=row+1;   
    %
    % > Aeq6+7: Sum of secondary reserve allocation
    if ~isempty(isSecBalUnit)
        for i=isSecBalUnit
            Aeq(row, idxPsecPos(i,t))= 1;
            Aeq(row+1, idxPsecNeg(i,t))= 1;                
        end     
        beq(row)=1;
        beq(row+1)=1;
        row=row+2;  
    end
end
% balancing can be assigned just once per day
if ~param.const.flexBalancing
    for t=1:param.const.np-1
        for i=isSecBalUnit
            Aeq(row,idxPsecPos(i,t))=1;
            Aeq(row,idxPsecPos(i,t+1))=-1;
            beq(row)=0;
            row=row+1;
            Aeq(row,idxPsecNeg(i,t))=1;
            Aeq(row,idxPsecNeg(i,t+1))=-1;
            beq(row)=0;
            row=row+1;
        end  
        for i=isPriBalUnit
            Aeq(row,idxPpr(i,t))=1;
            Aeq(row,idxPpr(i,t+1))=-1;
            beq(row)=0;
            row=row+1;            
        end          
    end 
end
%
% > Aeq6: DSM Calls have to be balanced at end of run (1 constraint per
% unit)
for i=isDSS
    % sum of P(1:t)=sum of P_L(1:t)         sum_t eta*p = sum_t 1/eta * P_DSSConst_t
    Aeq(row, idxP(i,1:param.const.np ))=eta(i);                      % turning on load is aquivalent to pump operation in storages 
    beq(row)=sum(param.var.P_DSSCons_t(1:param.const.np))/eta(i); % storage is emptied by load    
    row=row+1;
end
pause(0); % possible break point...