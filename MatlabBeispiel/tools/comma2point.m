function    comma2point( filename )
% Author: Pascal Dubucq, 2014
%
% COMMA2POINT  Replaces all occurences of comma (",") with point (".") in a specified text-file.
% Note that the file is overwritten, which is the price for high speed.
%
% FILENAME The fully qualified path to the file to be processed.
%
file    = memmapfile( filename, 'writable', true );
comma   = uint8(',');
point   = uint8('.');
file.Data( transpose( file.Data==comma) ) = point;       
end
