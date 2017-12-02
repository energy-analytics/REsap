function status=mydymolahack(command, value)
% Executes a command optionally followed by a value in Dymola.
% Dymola is started if not already running.

% Version 1.0, 1997-11-14

%    Copyright (C) 1997-2001 Dynasim AB.
%    All rights reserved.

  global DymolaChannel
  if isempty(DymolaChannel),
    DymolaChannel = ddeinit('dymola', ' ');
  end   
%  if DymolaChannel == 0,
%    ! Dymola
%    DymolaChannel = ddeinit('dymola', ' ');
%  end
  
  if nargin == 1, 
    status = ddeexec(DymolaChannel, command, '', 1000000);
  elseif nargin == 2,
    status = ddeexec(DymolaChannel, [command, num2str(value)], '', 1000000);
  end

%  ddeterm(DymolaChannel);

  if status == 0,
    error('Dymola is not responding.');
  end
