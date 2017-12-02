function dym_disp(obj)
% dym_disp - same as disp, but output can be switched off
%
% dym_disp(obj) calls disp(obj), if output switch is set ON,
%               otherwise, the call is ignored.
% dym_disp(0)   switch subsequent output of dym_disp OFF
% dym_disp(1)   switch subsequent output of dym_disp ON  (default)
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.

persistent ON;
if isempty(ON), ON = logical(1); end;

if isnumeric(obj) & length(obj) == 1
   ON = logical(obj);
elseif ON
   disp(obj);
end
