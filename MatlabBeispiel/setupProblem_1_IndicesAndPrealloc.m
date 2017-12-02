%   Solution vector is: [P, Q, z, zs, w, Ppr, PsecPos, PsecNeg, DPdssPos
%   ,DPdssNeg]
%
% >> Compute index sets & Short cut notation for frequently used parmeters
IndexSetsandShortCut; 
%
% >> Utility functions for finding the right indices
element = @(x, varargin) x(varargin{:});                                    % return element varargin of array x
getIdx=@(g,set)isDispUnit(set==g);                                          % returns the position of a generator g in a specific subset (try: getIdx(6,isOperatingStateAware))
%
idxP_g=@(g)getIdx(g,(union(isPowerUnit,isPowerUser))):nVarp:nVar;                                                    % return all power indices of generator g
idxQ_g=@(g)nel+getIdx(g,isHeatUnit):nVarp:nVar;
idxZ_g=@(g)nel+nheat+getIdx(g,isStateUnit):nVarp:np*nVarp;                        % return all operating state indices of generator g
idxZs_g=@(g)nel+nheat+nstate+getIdx(g,isStateUnit):nVarp:np*nVarp;    % return all startup state indices of generator g
idxW_g=@(g)(nel+nheat+2*nstate+getIdx(g,isStorage)):nVarp:np*nVarp;   % return all generating indices of storage g
idxPpr_g=@(g)nel+nheat+2*nstate+nsu+...
    getIdx(g,isPriBalUnit):nVarp:np*nVarp;                                  % return all primary power indices of generator g
idxPsecPos_g=@(g)nel+nheat+2*nstate+nsu+...
    npribalu+getIdx(g,isSecBalUnit):nVarp:np*nVarp;             % return all positive secondary power indices of generator g
idxPsecNeg_g=@(g)nel+nheat+2*nstate+nsu+...
    npribalu+nsecbalu+ ...
    getIdx(g,isSecBalUnit):nVarp:np*nVarp;                                  % return all negative secondary power indices of generator g
% difference approach for last two:
idxDeltaPosDSS_g=@(g)nVarp-2+g:nVarp:np*nVarp;
idxDeltaNegDSS_g=@(g)nVarp-1+g:nVarp:np*nVarp;
%
idxP=@(g,t)element(idxP_g(g),t);                                            % return the power index for generator g in timestep t
idxQ=@(g,t)element(idxQ_g(g),t);
idxZ=@(g,t)element(idxZ_g(g),t);                                            % return the power state index for generator g in timestep t
idxZs=@(g,t)element(idxZs_g(g),t);                                          % return the startup state index for generator g in timestep t
idxW=@(g,t)element(idxW_g(g),t);                                            % return the  generating/consuming index for storage g in timestep t
idxPpr=@(g,t)element(idxPpr_g(g),t);
idxPsecPos=@(g,t)element(idxPsecPos_g(g),t);
idxPsecNeg=@(g,t)element(idxPsecNeg_g(g),t);
idxDeltaPosDSS=@(g,t)element(idxDeltaPosDSS_g(g),t);
idxDeltaNegDSS=@(g,t)element(idxDeltaNegDSS_g(g),t);
%
param.functions.idxP=idxP;
param.functions.idxZ=idxZ;
param.functions.idxZs=idxZs;
param.functions.idxW=idxW;
param.functions.idxPpr=idxPpr;
param.functions.idxPsecPos=idxPsecPos;
param.functions.idxPsecNeg=idxPsecNeg;