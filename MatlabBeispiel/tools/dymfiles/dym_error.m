function dym_error(string)
% dym_error - call errordlg (i.e. error with dialog box) and break all m-files
% dym_error(string) calls errordlg(string), i.e., argument "string"
% is directly passed to "errordlg". After "o.k." button is pressed,
% execution continues and all higher level m-files are terminated.
% Should be used in conjunction with "try ... catch ... end" construct
% to catch the error in a higher level m-file and continue execution
% at a defined point in the GUI.
%
%
% Changes:
%  K. Schnepper DLR RM-ER, 19. Nov. 2005:
%                 Remove uiwait call for cases, where there is
%                 no display. Reason: Crashes and unexpected
%                 MATLAB seemingly not responding when there is
%                 no Display on UNIX or -noFigureWindows is used
%                 on Windows. NOTE: The case of Windows
%                 -noFigureWindows cannot be caught with this
%                 fix. Here it would be necessary to avoid the
%                 errordlg completely!
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.

%{
if (get(0,'ScreenDepth') ~= 0)
    % Unly us errordialog when there is a Dsiplay!
    h = errordlg(string);
    uiwait(h);
else
%}
    %disp(char(string));
    %disp('<suppressed error message>');
%end

% error(..) is also called to give indication where the error occured
% if this is desired. However, "string" cannot be given as argument,
% because "string" may be a cell array and cell arrays are not
% allowed for m-file "error".
%error('error (use try ... catch ... end to avoid this message)');
