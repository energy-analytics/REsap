% Demonstrate usage of dym m-files:
%
%   The Modelica model "DriveLib.Drive1" stored in file "DriveLib.mo"
%   shall be simulated with Dymola. Copy this file in your "current directory"
%   where Matlab is running.
%
%   Before starting this m-file, make sure that the "dym" directory
%   is part of the Matlab path.
%
% Copyright (C) 2000-2006 DLR (Germany).
%    All rights reserved.

%
% Translate model
  clear all;
  model = 'DriveLib.Drive1';
  dym_translate(model);

% Define simulation experiment and perform simulation
  simulator.model               = model;
  simulator.experiment.StopTime = 1;
  simulator.initial(1).name     = 'controller.Ti';   % modify parameter value
  simulator.initial(1).start    = 0.55;
  result = dym_simulate(simulator);

% Open window to interactively browse the results
  dym_browseResult(result);

% Plot one variable in a Matlab plot window
  t = dym_getResult(result,'Time');
  w = dym_getResult(result,'load.w');
  plot(t,w);
  title([ simulator.initial(1).name, ' = ', num2str( simulator.initial(1).start )]);

% Linearize model around initial point
  simulator.action = 2;
  simulator.LTI    = 0;
  result = dym_simulate(simulator);
  eigenValues = eig(result.A);
  figure(2)
  plot(real(eigenValues), imag(eigenValues), '*');
  title('Eigenvalues at initial configuration');
  grid on;


