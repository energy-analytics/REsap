function modelicaVectorWrite(A, varargin)
% Author: Pascal Dubucq, 2016
%
% MODELICAVECTORWRITE(A, FILENAME)  
%
% Prints matrix A in correct modelica vector syntax to console. 
% If FILENAME is specified (optional), output will be written to file.
fmtText=sprintf(['%f' repmat(',%f',1,size(A,2)-1) ';\n'], A');
fmtText=['[' fmtText];
fmtText(end-1)=']';
fmtText(end)=';';
if ~isempty(varargin)
    assert(length(varargin)<2, 'Error: Only two arguments expected!');
    try
    %
    % Open fie
    filename=varargin{1};
    fid=fopen(filename);assert(fid>0, ['File ''' filename ''' not found.']);
    fprintf(fid, fmtText);
    fclose(fid);
    catch me   
        if fid>0
        fclose(fid);
        end
        rethrow(me);
    end
    fprintf('Data successfully written in modelica conform table format to file %s \n', filename);
    else
    fprintf('\n%s\n\n', fmtText);
end