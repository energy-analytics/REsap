function initial = dym_getInitial(model)
% dym_getInitial - get initial values of the model
%
% initial = dym_getInitial(model) returns the names and values
% of all variables for which initial values can be given
% (usually parameters and states).
% <model> is the Modelica model name and it is assumed that a file
% <model>.exe exists (generated, e.g., with dym_translate).
%
% "initial" is a struct-vector with the following elements:
%   initial(i).name         Full Modelica name of variable
%             .start        Start value of variable
%             .description  Description text of variable
%             .category     = 1: parameter
%                           = 2: state
%                           = 3: state derivative
%                           = 4: output
%                           = 5: input
%                           = 6: auxiliary variable
%
% In this version only initial values for parameters and states
% (category = 1 or 2) are returned.
%
% In the future, all the other Modelica attributes will be provided
% (nominal, fixed, min, max, unit, displayUnit, quantity)
% as well as the type (Real, Integer, Boolean, String)
%
% See also: dym_translate, dym_simulate, dym_browseResult
%
% Release Notes:
%
%    - October 24, 2003 by Klaus Schnepper, DLR:
%      Remove Windows specifics and make operable on UNIX
%
% Copyright (C) 2000-2006 DLR (Germany) and Dynasim AB (Sweden).
%    All rights reserved.

% Check for a Windows PC system
  PC = ispc;

% Name of model executable and of model info file
  if PC
    modelExe  = [model, '.exe'];
    nullDevice = 'nul';
  else
    modelExe  = model;
    nullDevice = '/dev/null';
  end
  modelInfo = [model, '_info.mat'];

% Check whether Modelica model executable is in current directory
  if ~dym_existFile( modelExe )
     errstr{1} = ['File "', modelExe, '" unknown in directory:'];
     errstr{2} = pwd;
     dym_error(errstr);
  end

% Generate info (independent of operating system)
  command = [ '!', modelExe, ' -ib ', modelInfo ' > ',nullDevice ];
  eval(command);


% Read information
  minfo = load(modelInfo);

% Check whether expected variable names are present
  checkName(minfo, 'initialName'       , modelExe);
  checkName(minfo, 'initialValue'      , modelExe);
  checkName(minfo, 'initialDescription', modelExe);

% Return information
  indices = find( minfo.initialValue(:,5)==1 | minfo.initialValue(:,5)==2 );
  n = length(indices);
  initial(n).name = '.';   % allocate storage
  for i = 1:n
     initial(i).name        = deblank( minfo.initialName       (indices(i),:) );
     initial(i).start       =          minfo.initialValue      (indices(i),2);
     initial(i).description = deblank( minfo.initialDescription(indices(i),:) );
     initial(i).category    =          minfo.initialValue      (indices(i),5);
  end;

% Delete generated files
  dym_deleteFiles( {'dslog.txt', 'status', 'success', modelInfo} );


function checkName(variables, name, modelExe)
% Check whether "name" is part of structure "variables".
% If not, an error message is printed that modelExe does
% not supply the necessary information
if ~isfield(variables, name);
   dym_error(['Array "', name, '" could not be inquired from "', modelExe,'".'] );
end

