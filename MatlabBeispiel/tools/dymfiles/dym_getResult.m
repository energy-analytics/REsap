function data = dym_getResult(result, name)
% dym_getResult  get dymola simulation result for a specific variable
%
%   data = dym_getResult(result, name);
%
%   "result" is a structure obtained by executing "dym_loadResult"
%   "name" is the FULL Modelica variable name
%          (if "name" is a number, it is interpreted as the "row" index of
%          the result.name string array, i.e., access via index is also possible)
%   "data" is a data structure containing the desired result data:
%          - For simple variables a column vector is returned.
%          - For arrays a cell array is returned.
%          - For records or sub-models a struct is returned, where each
%            element has the name of the correspond component/variable.
%   The "data" vectors returned are the values of the variables at the
%   time instants defined by the abscissa vector dym_getResult(result,'Time').
%
% Issues:
%   If a struct contains a member whose name start
%   with _... the name is changed to FIX_...
%   since Matlab structs cannot have names starting with _
%
% See also: dym_browseResult, dym_loadResult, dym_simulate
%
% Release Notes:
%    - Nov. 4, 2001, by Martin Otter, DLR:
%      Returned vectors have always the same length as the "Time" vector
%      (previously, a vector with two elements was returned for constants)
%
%    - Sept. 21, 2001, by Hans Olsson, Dynasim:
%      Restructured code
%      Correct string matching for partially matched names
%      Handles multiple matches correctly
%      Code to handle arrays and structs
%      Performance optimization for string matching
%
%    - July, 2000 by Matthijs Langelaar, DLR:
%      Implemented.
%
% Copyright (C) 2000-2006 DLR (Germany) and Dynasim AB (Sweden).
%    All rights reserved.

% find index
if nargin ~= 2
   dym_error(['dym_getResult needs 2 input arguments and not ', num2str(nargin)]);
end
if result.type == 0
   dym_error(['The loaded result data ("', result.fname, '") consists of several data', ...
              ' matrices with different abscissa vectors. This is not yet supported.']);
end

if isnumeric(name)
   data=unpackElement(result,name);

elseif ischar(name)
   [index,typ]=myStrMatch(name,result.name);
   if length(index)==0
      dym_error(['Invalid variable name "', name, '"']);
   end
   data=dymgetInner(name,index,typ,result,result.name(index,:));

else
   dym_error('Second argument is no name string and no name index');
end


function data=dymgetInner(name,index,typ,result,subnames)
% Handles the actual data
% Recursive
switch(typ)
case 0,
   data=unpackElement(result,index);
case 1,
   % Array: More difficult due to array of components.
   i=1;
   while i<=length(index)
      s=subnames(i,length(name)+2:end);
      I=find(s==']');
      s=s(1:I(1)-1);
      newname=[name,'[',s,']'];
      [index2i,typ2]=myStrMatch(newname,subnames);
      index2=index(index2i);
      value=dymgetInner([name,'[',s,']'],index2,typ2,result,subnames(index2i,:));
      eval(['data{',s,'}=value;']);
      i=i+length(index2);
   end
case 2,
   % A struct
   i=1;
   first=1;
   while i<=length(index)
      s=subnames(i,length(name)+2:end);
      I=find(((s=='.')|(s=='[')) & cumsum((s=='(')-(s==')'))==0);
      if ~isempty(I)
         s=s(1:I(1)-1);
      end
      newname=[name,'.',s];
      [index2i,typ2]=myStrMatch(newname,subnames);
      index2=index(index2i);
      val=dymgetInner(newname,index2,typ2,result,subnames(index2i,:));
      if s(1)=='_'
         s=['FIX',s]; % Matlab-struct names cannot start with _
      end
      indi=find(s=='(');
      for indii=indi'
         s(indii)='_';
      end;
      s(s==')'|s==' '|s=='['|s==']'|s==',')=[];
      if first
         data=struct(s,{val});
      else
         data=setfield(data,s,val);
      end
      i=i+length(index2);
      first=0;
   end
end

function data = unpackElement(result,index)
% Scalar case.
% By Matthis Langelaar; modified by Martin Otter
% (note: result.dataInfo(3) and (4) are ignored)
dataInfo   = result.dataInfo(index,:);
datamatrix = dataInfo(1);
if datamatrix == 0
   % Abscissa
   if result.type == 1
      datamatrix = 1;
   else % result.type = 2
      datamatrix = 2;
   end
end
datacol  = abs(dataInfo(2));
datasign = sign(dataInfo(2));
if datamatrix == 1 & result.type == 2
  % Data consists of constant data, expand data to match abscissa vector
    n    = size(result.data{2},1);
    data = (datasign*result.data{1}(1,datacol))*ones(n,1);
else
  data = datasign*result.data{datamatrix}(:,datacol);
end


function [index,typ]=myStrMatch(name,strs)
% Written by Hans Olsson Dynasim.
% strmatch is not sufficient since
% a can match alpha, a.b, a[1]
%
% typ is:
%  0 scalar variable
%  1 array
%  2 model (struct)
index=strmatch(name,strs);
if length(name)==size(strs,2)
   typ=0;
   return;
end
indexOut=zeros(length(index),1);
j=0;
typ=0;
parlevel=0;
for i=1:length(index)
   c=strs(index(i),length(name)+1);
   if c=='('
      parlevel=parlevel+1;
   elseif c==')'
         parlevel=parlevel-1;
   elseif parlevel>0 | isletter(c) | c==',' | c=='_' | (c>='0' & c<='9')
      ;
   else
      j=j+1;
      indexOut(j)=index(i);
      if c=='['
         typ=1;
      elseif c=='.'
         typ=2;
      end
   end
end
index=indexOut(1:j);