function result = dym_simulate(simInput)
% dym_simulate - Perform time simulation of or linearize a Dymola model and load result
%
% result = dym_simulate(simInput) performs a time simulation of a Dymola
% model, stores the result on file and loads this result into structure
% "result" with "dym_load". The executable defined in "simInput" (see below)
% must exist (e.g. generated with dym_translate). It contains the model to
% be simulated. All simulation parameters can be provided when calling
% this function. The loaded results "result" can be accessed and plotted via
% "dym_browseResults" and "dym_getResults".
%
% When "simInput.action = 2" is set, the model is linearized after
% initialization and the linearized model is returned either as
% LTI object or as a structure (depending on "simInput.LTI").
%
% The input argument "simInput" has the following structure
% (Note, that if a parameter is not provided, the indicated default value is used):
%
% simInput.model          Name of the model to be simulated.
%                         It is assumed that an executable "<model>.exe" exists
%                         (e.g. generated with dym_translate).
%                         Log-output is stored in file <model>_log.txt.
% simInput.action = 1     Simulate (default)
%                 = 2     Initialize model and linearize after initialization
% simInput.LTI    = 1     If 1, return a linearized system as LTI object.
%                         If 0, return the result as structure:
%                            result.A
%                            result.B
%                            result.C
%                            result.D
%                            result.InputName    // cell array of strings
%                            result.OutputName
%                            result.StateName
% simInput.experiment     Experiment parameters:
%   .StartTime   =0       Time at which integration starts
%                         (and linearization and trimming time)
%   .StopTime    =1       Time at which integration stops
%   .Increment   =0       Communication step size, if > 0
%   .nInterval   =500     Number of communication intervals, if > 0
%                         (EITHER Increment or nInterval can be provided)
%   .Tolerance   =1.e-4   Relative precision of signals for simulation,
%                         linearization and trimming
%   .MaxFixedStep=0       Maximum step size of fixed step size integrators, if > 0.0
%   .Algorithm   ='dassl' Integration algorithm. Possible values:
%                                    | model|       |        | dense | state |
%                          Algorithm | typ  | stiff | order  | output| event |
%                          ----------+------+-------+--------+-------+-------+
%                          deabm     |  ode |   no  |  1-12  |  yes  |   no  |
%                          lsode1    |  ode |   no  |  1-12  |  yes  |   no  |
%                          lsode2    |  ode |  yes  |  1-5   |  yes  |   no  |
%                          lsodar    |  ode |  both |1-12,1-5|  yes  |  yes  |
%                          dopri5    |  ode |   no  |   5    |   no  |   no  |
%                          dopri8    |  ode |   no  |   8    |   no  |   no  |
%                          grk4t     |  ode |  yes  |   4    |   no  |   no  |
%                          dassl     |  dae |  yes  |  1-5   |  yes  |  yes  |
%                          odassl    | hdae |  yes  |  1-5   |  yes  |  yes  |
%                          mexx      | hdae |   no  |  2-24  |   no  |   no  |
%                          euler     |  ode |   no  |   1    |   no  |  yes  |
%                          rkfix2    |  ode |   no  |   2    |   no  |  yes  |
%                          rkfix3    |  ode |   no  |   3    |   no  |  yes  |
%                          rkfix4    |  ode |   no  |   4    |   no  |  yes  |
%                          ----------+------+-------+--------+-------+-------+
%                          euler and rkfix have fixed stepsize.
%                            ode : ordinary differential equation solver
%                            dae : differential algebraic equation solver
%                            hdae: higher index differential algebraic equation solver
%
% simInput.settings       Parameters defining the result output:
%   .lprec=0              0/1 do not/store result data in double
%   .lx=1                 0/1 do not/store x  (state variables)
%   .lxd=1                0/1 do not/store xd (derivative of states)
%   .lu=0                 0/1 do not/store u  (input     signals)
%   .ly=1                 0/1 do not/store y  (output    signals)
%   .lz=0                 0/1 do not/store z  (indicator signals)
%   .lw=1                 0/1 do not/store w  (auxiliary signals)
%   .la=1                 0/1 do not/store a  (alias     signals)
%   .lperf=0              0/1 do not/store performance indicators
%   .levent=0             0/1 do not/store event point
%   .lres=1               0/1 do not/store results on result file
%   .lshare=0             0/1 do not/store info data for shared memory on dsshare.txt
%   .lform=1              0/1 ASCII/Matlab-binary storage format of results
%                         (for simulation/linearization; not for trimming)
%
% simInput.initial(i)     struct vector of variables for which initial values or
%                         parameters shall be set.
%   .name                 Full Modelica name of variable.
%   .start                Initial or parameter value.
%                         Use "dym_getInitial" to get default initial and parameter values
%
% simInput.method         Method tuning parameters:
%   .grid=1               Type of communication time grid, defined by
%                           = 1: equidistant points ("Increment/nInterval")
%                           = 2: vector of grid points ("tgrid")
%                           = 3: variable step integrator (automatically)
%                           = 4: model (call of "increment" in Dymola, e.g.
%                                  incr=Time > 2 then 0 else 0.1
%                                   dummy=increment(incr))
%                           = 5: hardware clock (functions "udstimerXXX")
%                           grid = 1,3 is stopped by "StopTime"
%                           grid = 2   is stopped by "tgrid(last)"
%                           grid = 4   runs forever (stopped by model)
%                           grid = 5   runs forever (stopped by udstimerRun)
%   .nt=1                 Use every NT time instant, if grid = 3
%   .dense=3              1/2/3 restart/step/interpolate GRID points
%   .evgrid=1             0/1 do not/save event points in comm. time grid
%   .evu=1                0/1 U-discontinuity does not/trigger events
%   .evuord=0             U-discontinuity order to consider (0,1,...)
%   .error=0              0/1/2 One message/warning/error messages
%   .jac=0                0/1 Compute jacobian numerically/by BLOCKJ
%   .xd0c=0               0/1 Compute/set initial values xd0
%   .f3=0                 0/1 Ignore/use F3 of HDAE (= index 1)
%   .f4=0                 0/1 Ignore/use F4 of HDAE (= index 2)
%   .f5=0                 0/1 Ignore/use F5 of HDAE (= invar.)
%   .debug=0              0/1 do not/print debug information
%   .pdebug=100           priority of debug information (1...100)
%   .fmax=0               Maximum number of evaluations of BLOCKF, if > 0
%   .ordmax=0             Maximum allowed integration order, if > 0
%   .hmax=0               Maximum absolute stepsize, if > 0
%   .hmin=0               Minimum absolute stepsize, if > 0 (use with care!)
%   .h0=0                 Stepsize to be attempted on first step, if > 0
%   .teps=1.e-14          Bound to check, if 2 equal time instants
%   .eveps=1.e-10         Hysteresis epsilon at event points
%   .eviter=20            Maximum number of event iterations
%   .delaym=1.e-6         Minimum time increment in delay buffers
%   .fexcep=1             0/1 floating exception crashes/stops simulator
%   .tscale=1             clock-time = tscale*simulation-time, if grid = 5
%                                    > 1: simulation too slow
%                                    = 1: simulation-time = real-time
%                                    < 1: simulation too fast
%   .shared=1             type of process communication, if grid = 5
%                         = 0: no communication,(single process without clock)
%                         = 1: no communication (single process with clock)
%                         = 2: shared memory (multiple processes with clock)
%   .memkey=2473          key to be used for shared memory, if shared = 2
%
% On PC, a DOS window is opened as icon which is closed after
% termination of the simulator. All simulator messages, including error
% messages, are stored in file "<model>_log.txt". Error messages from
% this file are shown in an error dialog box, after the simulation
% is terminated.
%
% See also: dym_translate, dym_getInitial, dym_browseResult
%
% Release Notes:
%    - November 18, 2004 by K. Schnepper, DLR:
%      Disable error/warning dialogs for cases without display
%
%    - July 19, 2004 by Martin Otter, DLR:
%      Optional linearization added
%
%    - October 24, 2003 by Klaus Schnepper, DLR:
%      Remove Windows specifics and make operable on UNIX
%
%    - Nov. 4, 2001 by Martin Otter, DLR:
%      Initial value are given in a struct array
%
%    - April 1, 2001 by Martin Otter, DLR:
%      Implemented based on m-file dymosim.m
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.


% Initialize output (in case of error)
  result = [];

% ... check for PC-System
  PC = ispc;

% Define files
  if PC
    simulator  = [simInput.model, '.exe'];
    nullDevice = 'nul';
    pathSep = '\';
    pathSep2 = '/';
  else
    simulator        =['./',simInput.model];
    nullDevice = '/dev/null';
    pathSep = '/';
    pathSep2 = '\';
  end

%   simulator_input  = [simInput.model, '_input.mat'];
%   simulator_result = [simInput.model, '_result.mat'];
%   simulator_log    = [simInput.model, '_log.txt'];

  jj1 = findstr(simInput.model,pathSep);
  jj2 = findstr(simInput.model,pathSep2);
  if isempty(jj1) && isempty(jj2)
      modelName = simInput.model;
  else
      if isempty(jj2)
          jj = jj1;
      elseif isempty(jj1)
          jj = jj2;
      else
          if jj1(end) > jj2(end)
              jj = jj1;
	  else
              jj = jj2;
          end
      end
      modelName = simInput.model(jj(end)+1:end);
  end

  simulator_input  = [modelName, '_input.mat'];
  simulator_result = [modelName, '_result.mat'];
  simulator_log    = [modelName, '_log.txt'];
  simulator_status = 'status';

% Print info message
  if ~isfield(simInput, 'action') | simInput.action == 1
     dym_disp( ['... Prepare simulation run with executable "', simulator, '"'] );
     action = 1;
  elseif simInput.action == 2
     dym_disp( ['... Prepare linearization run with executable "', simulator, '"'] );
     action = 2;
  else
     dym_error( ['simInput.action ( = ', num2str(simInput.action), ') must be 1 or 2'] );
  end;
  dym_disp(['... for model "', modelName, '"']);

% Delete old files
  dym_deleteFiles( {simulator_input, simulator_result, ...
                    simulator_log  , simulator_status} );

% Check most import input arguments
  if isfield(simInput, 'initial')
     nInitial = length(simInput.initial);
     if nInitial > 0
        if ~isfield(simInput.initial, 'name')
           dym_error('simInput.initial is provided, but without "name" element');
        end
        if ~isfield(simInput.initial, 'start')
           dym_error('simInput.initial is provided, but without "start" element');
        end
     end
  else
     nInitial = 0;
  end

% Set default structure for dsin.txt file
  Algorithm = {'deabm', 'lsode1', 'lsode2', 'lsodar', 'dopri5', 'dopri8', 'grk4t', ...
               'dassl', 'odassl', 'mexx'  , 'euler' , 'rkfix2', 'rkfix3', 'rkfix4'};
  experiment.StartTime   =0;
  experiment.StopTime    =1;
  experiment.Increment   =0;
  experiment.nInterval   =500;
  experiment.Tolerance   =1.e-4;
  experiment.MaxFixedStep=0;
  experiment.Algorithm   =findIndex('dassl', Algorithm);

  settings.lprec =0;
  settings.lx    =1;
  settings.lxd   =1;
  settings.lu    =0;
  settings.ly    =1;
  settings.lz    =0;
  settings.lw    =1;
  settings.la    =1;
  settings.lperf =0;
  settings.levent=0;
  settings.lres  =1;
  settings.lshare=0;
  settings.lform =1;

  method.grid=1;
  method.nt=1;
  method.dense=3;
  method.evgrid=1;
  method.evu=1;
  method.evuord=0;
  method.error=0;
  method.jac=0;
  method.xd0c=0;
  method.f3=0;
  method.f4=0;
  method.f5=0;
  method.debug=0;
  method.pdebug=100;
  method.fmax=0;
  method.ordmax=0;
  method.hmax=0;
  method.hmin=0;
  method.h0=0;
  method.teps=1.e-14;
  method.eveps=1.e-10;
  method.eviter=20;
  method.delaym=1.e-6;
  method.fexcep=1;
  method.tscale=1;
  method.shared=1;
  method.memkey=2473;

% Update default structure with input arguments
  if isfield(simInput, 'experiment') & isfield(simInput.experiment, 'Algorithm')
     temp = simInput.experiment;
     temp.Algorithm = findIndex(temp.Algorithm, Algorithm);
     experiment = update(experiment, temp);
  else
     experiment = update(experiment, 'experiment', simInput);
  end
  settings = update(settings, 'settings', simInput);
  method   = update(method  , 'method' , simInput);
  if nInitial > 0
     initialName  = char(simInput.initial.name);
     initialValue = [ -ones(nInitial,1), zeros(nInitial,3), -ones(nInitial,2) ];
     for i = 1:nInitial
        initialValue(i,2) = simInput.initial(i).start;
     end
  end
  Aclass = [ 'Adymosim                   '
             '1.4                        '
             'Generated by dym_simulate.m' ];


% Save data on simulator input file
% (save has to be called as function, in order to guarantee that the
% matrices are written in the given order. The standard way of save
% saves the matrices usually in a different order as provided.
% However, dymosim requires that Aclass is the first matrix on file).
  save(simulator_input, 'Aclass'      ,'-v4');
  save(simulator_input, 'experiment'  ,'-v4', '-append');
  save(simulator_input, 'method'      ,'-v4', '-append');
  save(simulator_input, 'settings'    ,'-v4', '-append');
  if nInitial > 0
     save(simulator_input, 'initialName' ,'-v4', '-append');
     save(simulator_input, 'initialValue','-v4', '-append');
  end

% Run simulator
  if ~dym_existFile(simulator)
     str{1} = ['"', simulator, '" does not exist in directory'];
     str{2} = ['       ', pwd];
     str{3} = 'Not possible to simulate.';
     dym_error(str);
  end

  dym_disp( ['... Simulator "', simulator, '" started.'] );
%%  str = ['! ', simulator, ' -w ', simulator_log, ' ', ...
%%         simulator_input, ' ', simulator_result, ' > ',nullDevice ];
  if action == 1
     str = [simulator, ' -w ', simulator_log, ' ', ...
            simulator_input, ' ', simulator_result, ' > ',nullDevice ];
  elseif action == 2
     str = [simulator, ' -l -w ', simulator_log, ' ', ...
            simulator_input, ' ', simulator_result, ' > ',nullDevice ];
  else
     dym_error('Error 1 that should not occcur in dym_simulate');
  end
  ret_status=eval('system(str)');


% Read log file and show warnings messages about unknown parameter names
% (It is necessary to first check that simulator_log is in the
% current directory, because "fopen" of Matlab searches in the Matlab
% path, if the file to be opened is not in the current directory.
% As a result, a wrong log file could be opened, if for some reason
% no log-file is available in the current directory).
  if dym_existFile(simulator_log)
     fid = fopen(simulator_log, 'rt');  % open for read in text mode
     if fid ~= -1
        % read lines until simulation starts
        i = 0;
        while 1
           line = fgetl(fid);
           if ~isstr(line), break, end
           if ~isempty( findstr(line, 'Integration started') ), break, end
           if ~isempty( findstr(line, 'ignored') )
              i = i+1;
              log_messages{i} = line;
           end
        end
        fclose(fid);
        if i > 0
           % Print warning message
           if (get(0,'ScreenDepth') ~= 0)
               h = warndlg(log_messages, 'Warning messages from simulator');
               uiwait(h);
           else
               disp(['Warning messages from simulator';char(log_messages)]);
           end
        end
     end
  end

% Print error message, if simulation was not successful

  if ret_status ~= 0
      simulation_failed = 1;
  else
      simulation_failed = 0;
  end
  if PC && ~simulation_failed
      if isOnFile('status', 'failed')
          simulation_failed = 1;
      else
          simulation_failed = 0;
      end
  end

  if simulation_failed | ~dym_existFile(simulator_result)
     wd  = pwd;
     errstr{1} = ['Simulation with "', simulator, ...
                  '" failed (message deduced from: ', ...
                  '"', wd, pathSep, simulator_log, '"):'];
     errstr{2} = ' ';

     if dym_existFile(simulator_log)
        % Get error message from simulator_log file
        fid = fopen(simulator_log, 'rt');  % open for read in text mode
        if fid ~= -1
           % read lines until error starts
           i = 2;
           error_found = 0;
           while 1
              line = fgetl(fid);
              if ~isstr(line), break, end
              if ~error_found
                 if ~isempty( findstr(line, 'error') ), error_found = 1; end
                 if ~isempty( findstr(line, 'Error') ), error_found = 1; end
              end
              if error_found & i < 20
                 i = i+1;
                 errstr{i} = line;
              end
           end
           fclose(fid);
        end
     end
     dym_error(errstr);
  end

% Read result file
  if action == 1
     result = dym_loadResult(simulator_result);
  elseif action == 2
     if isfield(simInput, 'LTI')
        LTI = simInput.LTI;
     else
        LTI = 1;
     end;
     result = dym_loadLinearization(LTI,simulator_result);
  else
     dym_error('Error 2 that should not occcur in dym_simulate');
  end


% Remove auxiliary files
  dym_deleteFiles( {'dsfinal.txt', 'dslog.txt', 'status', 'success', 'failure'} );


%-----------------------------------------------------------------------------
% internal functions
%-----------------------------------------------------------------------------

function exp1_num = update(exp1, exp2_name, simInput);
% Update the exp1 structure with the values from the structure
% simInput.<exp2_name>, if this structure exists.
% Afterwards transform the exp1 structure into the numeric
% vector exp1_num and return this vector
%
% If "simInput" is missing, exp2_name is already the desired structure

  if nargin > 2
     if isfield(simInput, exp2_name)
       % exp2_name exists in simInput -> update exp1
         exp2   = getfield(simInput, exp2_name);
         names2 = fieldnames(exp2);
         for i=1:length(names2)
            if isfield(exp1, names2{i})
               exp1 = setfield(exp1, names2{i}, getfield(exp2, names2{i}));
            else
               errstr{1} = ['Field-name "', names2{i}, '" of structure "', exp2_name, ...
                            '" is unknown.'];
               dym_error(errstr);
            end
         end
     end
  else
     names2 = fieldnames(exp2_name);
     for i=1:length(names2)
        if isfield(exp1, names2{i})
           exp1 = setfield(exp1, names2{i}, getfield(exp2_name, names2{i}));
        else
           errstr{1} = ['Field-name "', names2{i}, '" is unknown.'];
           dym_error(errstr);
        end
     end
  end

% Transform exp1 into a numeric vector
  exp1_cell = struct2cell( exp1 );
  exp1_num  = cat(1, exp1_cell{:} );



function k = findIndex(name, nameList)
% Find "name" in nameList (a cell-vector of names)
   cmp = strcmp(name,nameList);
   k   = find(cmp);

   if length(k)~=1
      dym_error(['Internal error: "', name, '" is an unknown name.']);
   end
