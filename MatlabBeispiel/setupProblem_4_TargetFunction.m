%
% >> Target function calculation
c_prod=[param.dispUnits.c_prod];
c_start=[param.dispUnits.c_start];
f=zeros(1,nVar);
% Costfunction for PowerUnit
for i=setdiff(isPowerUnit,union(isCHP,isBTTP))
    if ~isempty(isPowerUnit)
    f(idxP_g(i))=ones(1,np)*c_prod(i)*P_0(i)*param.const.dt;
    end
end
% Costfunction for HeatUnit
for i=setdiff(isHeatUnit,union(isCHP,union(isPowerUser,isBTTP)))
    f(idxQ_g(i))=ones(1,np)*c_prod(i)*Q_0(i)*param.const.dt;
end

% Costfunction for CHP
for i=isCHP
    % Approximation function is: Qfuel= alpha(1) * P + alpha(2) * Q +
    % alpha(3)    
    f(idxP_g(i))=ones(1,np)*c_prod(i)*P_0(i)*param.dispUnits(i).alphaHeatInput(1)*param.const.dt;
    f(idxQ_g(i))=ones(1,np)*c_prod(i)*Q_0(i)*param.dispUnits(i).alphaHeatInput(2)*param.const.dt;
    f(idxZ_g(i))=ones(1,np)*c_prod(i)*param.dispUnits(i).alphaHeatInput(3)*param.const.dt;
end
% Costfuncion for DSS (now its getting real dirty...)
for i=isDSS
    f(idxDeltaPosDSS_g(i))=-.05*P_0(i);
    f(idxDeltaNegDSS_g(i))=-.05*P_0(i);    
end
% Costfunction for BTTP
for i=isBTTP
    f(idxP_g(i))=ones(1,np)*c_prod(i)*P_0(i)*param.const.dt;
end
% Starting Costfunction for StateUnit
for i=isStateUnit
    f(idxZs_g(i))=ones(1,np)*c_start(i)*P_0(i); 
end

f=f*1e-6;
%
% >> Upper and lower bound of solution vector
lb=zeros(nVar, 1);
ub=ones(nVar, 1);
%
% >> Compute indices of real and integer components in solution vector 
realcom=zeros(1, nVarReal*np);
row=1;
%Real Variable for PowerUnits
for i=isPowerUnit
    realcom(row:row+np-1)=idxP_g(i);
    row=row+np;
end
%Real Variable for HeatUnits
for i=isHeatUnit
    realcom(row:row+np-1)=idxQ_g(i);
    row=row+np;
end
for i=isSecBalUnit
    realcom(row:row+2*np-1)=[idxPsecPos_g(i) idxPsecNeg_g(i)];    
    row=row+2*np;
end
for i=isPriBalUnit
    realcom(row:row+np-1)=idxPpr_g(i);
    row=row+np;
end
for i=isDSS
    realcom(row:row+np-1)=idxDeltaPosDSS_g(i);
    realcom(row:row+np-1)=idxDeltaNegDSS_g(i);
    row=row+2*np;
end
intcom=setdiff(1:nVar, realcom);
intcom=sort(intcom);
%
% >> Log at first call
if(param.const.t0); fprintf('%s%.f%s%.f%s\n','>> Preprocessing finished. The optimization problem has ',length(f), ' variables and ', size(Aineq,1)+size(Aeq,1), ' constraints');end;