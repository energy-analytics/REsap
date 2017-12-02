function gpi(filepath, t, method)
% Author: Pascal Dubucq, 2014
%
% GPI Gets the initial Power (P_i) from a unit commitment schedule
% scpecified by filepath at time instant t. The result is copied to the
% clipboard and can than be pasted into a modelica model.
%
% FILEPATH is the target filename of the unit commitment schedule (may be relative or absolute). 
%
% T is the time instant where the initial power is used (start of
% simulation)
%
% METHOD is the interpolation method. use method 'previous' if Modelica Simulation is set to 'constantSegments'
% or 'linear' if Modelica Simulation is set to linear
%
%
% See also INTERP1, MODELICAREAD, CLIPBOARD
%
sched=modelicaread(filepath);
if strcmp(method, 'max')
    prev=interp1(sched.time, sched.data*1e6, t,'previous');
    next=interp1(sched.time, sched.data*1e6, t,'next');
    clipboard('copy', strrep(strcat('{', sprintf('%.2f,', max([prev;next], [], 1)), '}'), ',}','}'));
else
    if nargin>2
        clipboard('copy', strrep(strcat('{',sprintf('%.2f,', interp1(sched.time, sched.data*1e6, t,method)),'}'),',}','}'));
    else
        clipboard('copy', strrep(strcat('{',sprintf('%.2f,', interp1(sched.time, sched.data*1e6, t,'previous')),'}'),',}','}'));
    end
end

