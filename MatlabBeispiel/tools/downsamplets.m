function y=downsamplets(x, N)
% Author: Pascal Dubucq, 2015
%
% DOWNSAMPLETS Downsamples a timeseries object using every N th sample and
% linear interpolation and returns the result as a timeseries
%
% x is the original timeseries object
%
% N is the downsampling factor
%
% [y] = downsamplets(x,N) is the downsampled timeseries
%
% See also TIMESERIES, INTERP1
%
y=timeseries(interp1(x.time, x.data, x.time(1:N:end)), x.time(1:N:end));

