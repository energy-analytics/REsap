function result = dym_loadResult(matfile)
% dym_loadResult - load dymola simulation result into Matlab workspace
%
%   result = dym_loadResult;        loads data from 'dsres.mat' or opens
%                                   a pop-up dialog box if not present.
%   result = dym_loadResult(file);  loads data from '<file>' or from '<file>.mat'.
%   result = dym_loadResult('*');   opens a pop-up dialog box.
%
% If the pop-up dialog box is canceled, no error message is printed and
% "result=[]" is returned.
%
% Usually, the result of "dym_loadResult" is used as input to the
% following utility functions:
%
% - With "dym_browseResult(result)" the data can be interactively plotted.
%
% - With "dym_getResult(result, ModelicaName)" the data of a particular
%   variable or substructure can be retrieved, given the corresponding
%   Modelica name used in the Modelica model.
%
% The details of the "result" structure are documented within the m-file.
%
% Only the Dymola simulation result data format version 1.1 is supported,
% that is compatible with Dymola 3.1 and higher.
%
% See also: dym_browseResult, dym_getResult, dym_simulate
%
% Release Notes:
%   - Nov. 5 2003: K. Schnepper
%                  Remove code to lower filenames (unecessary on
%                  Windows and harmful on UNIX
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.
%-----------------------------------------------------------------------------
% "result" is a Matlab STRUCT-variable containing the following fields:
%    .fname        the filename of the loaded data
%    .pname        the pathname of the loaded data
%    .nnames       the number of variable names
%    .ndatamat     the number of data matrices
%    .type         = 0: "result" has general structure
%                  = 1: "result" has 1 data matrix.
%                  = 2: "result" has 2 data matrices with the following structure:
%                       - data{1} has two rows and contains the values of constant
%                         variables. With the exception of the abscissa, the two rows
%                         are identical. The abscissa vector consists of the first
%                         and last time instant.
%                       - data{2} contains the result of the time-varying variables.
%                  The information of ".type" is used in "dym_getResult" to
%                  built-up a common abscissa vector in an efficient way.
%    .name         the names of the variables (each row a name)
%    .description  the descriptions of the variables (each row a description)
%    .units        the units of the variables (each row a unit)
%                  (in the current version, the units are deduced from the
%                   description texts as the rightmost characters with "[...]").
%    .dataInfo     the dataInfo-array
%                   (i,1) =  j: name i data is stored in matrix "data_j".
%                   (i,2) =  k: name i data is stored in column abs(k) of matrix
%                               data_j with sign(k) used as sign.
%                   (i,3) =  0: Linear interpolation of the column data
%                   (i,4) = -1: name i is not defined outside of the defined
%                               time range
%                         =  0: Keep first/last value outside of time range
%                         =  1: Linear interpolation through first/last two
%                               points outside of time range.
%    .data{:}      Cell-array of data-matrices (length(.data) = .ndatamat).
%                  The abscissa of matrix data{:} is defined by:
%                     name(1,:)        : Name of the abscissa (usually: name = "Time")
%                     dataInfo(1,1) = 0: Always the case (signals that this is the abscissa)
%                     dataInfo(1,2) = k: Abscissa is stored in .data{k} (usually: k=1)
%                  This special rule for the abscissa is necessary, since otherwise
%                  the abscissa name has to be repeated in "name" and the names in
%                  "name" would be no longer unique.
%
% More complete example of the data structure:
%
%  .name = ['Time    '
%           'motor1.q'
%           'motor2.q'
%           'motor3.q']
%
%  .dataInfo = [0  1  0 -1    % Time
%               1  2  0  1    % motor1.q
%               2  2  0  1    % motor2.q
%               1  3  0  1]   % motor3.q
%
%           % Time  motor1.q  motor3.q
%  .data{1} = [0       0         -1
%              0.1     1         -2
%              0.2     2         -3
%              0.2    -2          0
%              0.5    -1          1
%              0.5     1          1
%              1       0          2]
%
%           % Time  motor2.q
%  .data{2} = [0        0
%              0        1
%              0.2      2
%              0.4      1
%              0.4     -1
%              1.0      0]

% determine file name
  result = [];
  useDialogBox = 0;
  if ~nargin,
     file = 'dsres.mat';
     if ~dym_existFile('dsres.mat')
        useDialogBox = 1;
     end
  end

  if useDialogBox | strcmp('*', matfile)
     [file, dirName] = uigetfile('*.mat', 'Open a Dymola simulation result file');
     if file==0
        result = [];
        return;
     end
     cd(dirName);
  else
     ii = findstr(matfile,'.');
     if isempty(ii)
        file = [matfile,'.mat'];
     else
        file = matfile;
     end

     if ~dym_existFile(file)
         dym_error( sprintf( ['"', file, '" does not exist in \n   %s'], pwd) );
     end
  end

% load data
  load(file);

% read Aclass variable
  matlabVersion = version;
  if exist('Aclass') ~= 1
     if matlabVersion(1,1)=='4'
        if exist('class') ~= 1
          dym_error( ['no trajectory on file "' file '" ("Aclass" is missing).'])
        else
           Aclass = class;
        end
     else
       dym_error( ['no trajectory on file "' file '" ("Aclass" is missing).'])
     end
  end

% check whether file has correct class name
  classReq = 'Atrajectory';
  ncol1 = size(classReq,2);
  [nrow2,ncol2] = size(Aclass);
  if ncol1 < ncol2
     classReq = [ classReq, blanks(ncol2-ncol1) ];
  elseif ncol1 > ncol2
     Aclass = [ Aclass, blanks(ncol1-ncol2) ];
     ncol2  = size(Aclass, 2);
  end
  if nrow2 < 2 then
     dym_error( [ 'file "' file '" is not of class ' classReq ] )
  elseif Aclass(1,:) ~= classReq(1,:)
     dym_error( [ 'file "' file '" is not of class ' classReq ] )
  end

% Check version number
  if ['1.0'] == Aclass(2,1:3)
     vers = 0;
  elseif ['1.1'] == Aclass(2,1:3)
     vers = 1;
  else
    dym_error( [ 'file "' file '" has wrong version number ' Aclass(2,:) ] )
  end

% Determine whether matrices have to be transposed
  if nrow2 < 4
     trans = 0;
  elseif Aclass(4,1:8) == ['binTrans']
     trans = 1;
  else
     trans = 0;
  end

  result.fname = file;
  result.pname = pwd;
  result.nnames  =0;
  result.ndatamat=0;
  result.type    =0;

% Action according to version number
  if vers == 0
     % Refuse (not implemented because no data format information available)
       dym_error( [ 'file "' file '" has wrong version number (version 1.1 required)'] )
  else
     % Check existance of name and dataInfo matrix
       if exist('name') ~= 1
         dym_error( ['no traj. on file "' file '" (matrix "name" missing).'])
       elseif exist('dataInfo') ~= 1
         dym_error( ['no traj. on file "' file '" ("dataInfo" missing).'] )
       end

     % Copy name
       if trans == 0
          result.name        = name;
          result.description = description;
          %result.units       = getUnits(result.description);
          result.dataInfo    = dataInfo;
       else
          result.name        = name';
          result.description = description';
          %result.units       = getUnits(result.description);
          result.dataInfo    = dataInfo';
       end
       result.nnames   = size(result.name,1);
       result.ndatamat = max(result.dataInfo(:,1));

     % Store matrices data_i
       for i=1:result.ndatamat
          % Determine matrix name
            if trans == 0
               eval( ['result.data{' int2str(i) '} = data_' int2str(i) ';'] );
            else
               eval( ['result.data{' int2str(i) '} = data_' int2str(i) ''';'] );
            end
       end
  end

% Determine type of result structure
  if result.ndatamat == 1
     result.type = 1;
  elseif result.ndatamat == 2
     % check whether result.data_1 contains only constant data
     nrow = size(result.data{1}, 1);
     if nrow == 1
        result.type = 2;
     elseif nrow == 2
        n = size(result.data{1},2); % number of columns
        i = result.dataInfo(1,2);  % column of abscissa
        if i == 1
           if result.data{1}(1,2:n) == result.data{1}(2,2:n), result.type = 2; end
        elseif i == n
           if result.data{1}(1,1:n-1) == result.data{1}(2,1:n-1), result.type = 2; end
        else
           if result.data{1}(1,1:i-1) == result.data{1}(2,1:i-1) & ...
              result.data{1}(1,i+1:n) == result.data{1}(2,i+1:n)
              result.type = 2;
           end
        end
     end
  end

% print info message
  if file(1,1) == '/' | file(1,1) == '\' | file(1,2) == ':'
     dym_disp( [ '> ', file, ' loaded.' ] )
  else
     machine = computer;
     if machine(1,1:2) == 'PC'
%        dym_disp( [ '> ', lower(pwd), '\', lower(file), ' loaded.'] )
        dym_disp( [ '> ', pwd, '\', file, ' loaded.'] )
     else
        dym_disp( [ '> ', pwd, '/', file, ' loaded.' ] )
     end
  end