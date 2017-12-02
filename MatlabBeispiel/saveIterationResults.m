function X_total = saveIterationResults(X_step, X_total, param)
%
% Short cut notation
IndexSetsandShortCut;
row=X_total.row;
dt=param.const.dt;
np=param.const.np;
rh=param.const.rh;
ndu=param.const.ndu;
nsu=param.const.nsu;
nstate=param.const.nstate;
npribalu=param.const.npribalu;
nsecbalu=param.const.nsecbalu;
nel_p=param.const.nel_p;
nel_u=param.const.nel_u;
nel=nel_p+nel_u;
nheat_p=param.const.nheat_p;
nheat_u=param.const.nheat_u;
nheat=nheat_p+nheat_u;
nREu=param.const.nREu;
P_0=[param.dispUnits.P_0];
Q_0=[param.dispUnits.Q_0];
e_start_t=[param.dispUnits.e_start_t];
isDispUnit=1:ndu;
getIdx=@(g,set)isDispUnit(set==g);                   
isStorage=find([param.dispUnits.isStorage]);
isHeatProducer=find([param.dispUnits.isHeatProducer]);
isHeatUser=find([param.dispUnits.isHeatUser]);
isPowerProducer=find([param.dispUnits.isPowerProducer]);
isPowerUser=find([param.dispUnits.isPowerUser]);
%
% Reshape solution vector
x_tp=reshape(X_step, [param.const.nvarp np]);
x_tp=x_tp(:,1:np*rh);
p_tp=x_tp(1:nel, :)';
q_tp=x_tp(nel+1:nel+nheat, :)';
% Storage levels:
X_total.e_tp_end=zeros(1, ndu);
for i=isStorage;
    if ismember(i,isPowerUnit)
        ips=getIdx(i, isPowerUnit);
        P_storage_prod=-p_tp(:,ips)*P_0(i)/eta(i)-p_tp(:,ips+1)*P_0(i+1)*eta(i+1);
        X_total.e_tp_end(i)=(e_start_t(i)*P_0(i)+sum(P_storage_prod)*dt)/P_0(i);
    elseif ismember(i,isHeatUnit)
        ihs=getIdx(i, isHeatUnit);
        Q_storage_prod=-q_tp(:,ihs)*Q_0(i)/eta(i)-q_tp(:,ihs+1)*Q_0(i+1)*eta(i+1); 
        X_total.e_tp_end(i)=(e_start_t(i)*Q_0(i)+sum(Q_storage_prod)*dt)/Q_0(i);
    end;
end 
for i=find([param.dispUnits.isDSS]) 
    P_storage_prod=-p_tp(:,i)*P_0(i)+param.var.P_DSSCons_t(1:np*rh,:)*P_0(i);
    X_total.e_tp_end(i)=(-e_start_t(i)*P_0(i)+sum(P_storage_prod)*dt)/P_0(i)*-1; 
end 
for i=find([param.dispUnits.isV2G])
    P_storage_prod=-p_tp(:,i)*P_0(i);
    X_total.e_tp_end(i)=(param.const.v2g_e_cons*P_0(i)-e_start_t(i)*P_0(i)+sum(P_storage_prod)*dt)/P_0(i)*-1; 
end         
if ~isempty(p_tp)   % scenario may be without power units
X_total.P_t(row:row+np*rh-1, 1:nel)=bsxfun(@times, p_tp, P_0(sort([isPowerProducer isPowerUser]))); %disp units
end
if nREu>0   % scenario may be without RE units
X_total.P_t(row:row+np*rh-1, nel+1:nel+nREu)=param.var.P_RE_t(1:np*rh,:);
end
if ~isempty(q_tp) % scenario may be without heat units
X_total.Q_t(row:row+np*rh-1, 1:nheat)=bsxfun(@times, q_tp, Q_0(isHeatUnit)); %disp units    
end
X_total.z_t(row:row+np*rh-1,:)=x_tp(nel+nheat+1:nel+nheat+nstate,:)';
X_total.zs_t(row:row+np*rh-1,:)=x_tp(nel+nheat+nstate+1:nel+nheat+2*nstate,:)';
X_total.w_t(row:row+np*rh-1,:)=x_tp(nel+nheat+2*nstate+1:nel+nheat+2*nstate+nsu,:)';
X_total.Ppr_t(row:row+np*rh-1,:)=x_tp(nel+nheat+2*nstate+nsu+1:nel+nheat+2*nstate+nsu+npribalu,:)';
X_total.PsecPos_t(row:row+np*rh-1,:)=x_tp(nel+nheat+2*nstate+nsu+npribalu+1:nel+nheat+2*nstate+nsu+npribalu+nsecbalu,:)';
X_total.PsecNeg_t(row:row+np*rh-1,:)=x_tp(nel+nheat+2*nstate+nsu+npribalu+nsecbalu+1:nel+nheat+2*nstate+nsu+npribalu+2*nsecbalu,:)';
X_total.row=row+np*rh;
X_total.p_end=nan(1, param.const.ndu);
X_total.p_end([isPowerUser isPowerProducer])=p_tp(end, :);
end