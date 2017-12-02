%----------------------------------------------------------------------
% Einsatzoptimierung eines Kraftwerks- und Speicherparks
% ----------------------------------------------------------------------
%
%% > Program initialisation
%addpath('c:\Program Files\IBM\ILOG\CPLEX_Studio1263\cplex\matlab\x64_win64\')
addpath('tools')
clc;close all;clear variables;%delete('output/*')                            % clear workspace
set(0,'DefaultFigureWindowStyle','docked');                                % plot windows shown in docked mode (default: normal)
tstart=cputime; tnote=tstart; startTS=datestr(now, 'dd_mm_yyyy_at_HH_MM');  % Timestamp at startup
resultPath='./output/';
useCplex=0; 
%e
%% > Workflow and simulation parameters
logconsole=0;logresults=1;plotfigures=0;saveResultFiles=1;shutDownAfterSim=0;              % Workflow parameters (1=true, 0=false)
ni=7;np=24;rh=1;t0=1;dt=1;                                                      % Simulation parameters (not scenario dependent)    
options = optimoptions('intlinprog',  ...
    'TolGapRel', 2e-5,'MaxTime', 3*3600);   %for standart -2 for real -5                                                 % solver parameters
%cplex_options=cplexoptimset('mip.tolerances.mipgap', 0);
scenarios={...
%'KWK35PR25','KWK35PR50','KWK35PR75','KWK35PR100'
%'KWK50'
%'REF35','HPS35','OPT35', 
'OPT35WP50'...
'KWK25'
%'HPS35', 'HPS50'
%'REF50','HPS50','OPT50', 'PTHSTOR50'
%'REF35PR25','REF35PR50', 'REF35PR75','REF35PR100',...
%'OPT35PR25','OPT35PR50', 'OPT35PR75','OPT35PR100',...
%'REF35psp25','REF35psp50', 'REF35psp75','REF35psp100'...
};
%
%% > Write diary
if logconsole; diary(['output/ZEP_' startTS '.log']); end;                    %#ok<UNRCH> % write diary (console output to file)
%
%% > Loop over simulation scenarios
for ns=1:length(scenarios)
    scenario=scenarios{ns};
    fprintf('%s\n', ['>> Starting simulation for scenario '...             % log simulation start 
        scenario ' at ' datestr(now) '...']);  
    %
    % > Initialize scenario
    [param, globalts]=initScenario(t0, np, ni, rh, dt, scenario,...                % initialize parameter record for this scenario
        saveResultFiles);
    %
    % > Initialize result sets
    X_total.P_t=zeros(np*ni*rh, param.const.nel_p + param.const.nel_u);    
    X_total.Q_t=zeros(np*ni*rh, param.const.nheat_p + param.const.nheat_u);
    [X_total.zs_t, X_total.z_t]=deal(zeros(np*ni*rh,param.const.nstate));
    X_total.w_t=zeros(np*ni*rh, param.const.nsu);
    X_total.Ppr_t=zeros(np*ni*rh, param.const.npribalu);
    [X_total.PsecPos_t,X_total.PsecNeg_t]=deal(zeros(np*ni*rh, param.const.nsecbalu));
    X_total.row=1;
    %
    % > Time iteration
    for tp=1:ni   
        %
        % > Setup MILP optimization problem
        [f, intcom, Aineq,bineq,Aeq,beq,lb,ub, param]=setupProblem(param);
        %
        % > Call solver
        fprintf('%s%.f%s%.f%s%s%s\n', '>> Calling intlinprog for timeperiod ', param.const.t0, ' to ', param.const.tend, ' (Scenario: ',scenario,')...');
        if useCplex
            ctype=num2str(zeros(param.const.nvar,1));
            ctype(intcom)='B';
            ctype(setdiff(1:param.const.nvar, intcom))='C';            
            [X_step,totalcost,exitflag,output]=cplexmilp(f, Aineq,bineq,Aeq,beq,[], [], [], lb,ub, ctype', [], cplex_options);        
        else        
            [X_step,totalcost,exitflag,output]=intlinprog(f, intcom, Aineq,bineq,Aeq,beq,lb,ub,options);
        end
        fprintf('%s%.f%s%.f%s%.1f%s%s%s\n','>> Optimization in outer period ',tp,' returned exit code ', exitflag, ' after CPU time of ', cputime-tstart,' s (Scenario: ',scenario,')');
        if exitflag~=1 && exitflag~=2 && exitflag~=5; 
            continue; 
        end; %error(output); end;
        %
        % > Prepare next iteration step
        X_total=saveIterationResults(X_step, X_total, param);
        if tp==ni; break;end;
        param=updateParameters(param, globalts, param.const.t0+np*rh, np, X_total.e_tp_end, X_total.p_end);
    end;
        fprintf('\n%s%.1f%s\n','>> Finished simulation after CPU time of ', (cputime-tstart),' seconds.');diary off;
        % Post Processing and first sight validation
        processResults
end
if shutDownAfterSim; 
%%    copyfile('output/*', 'D:/Dropbox/Austausch/tmp');
pause(1200);system('shutdown -s'); 
end; %#ok<UNRCH>