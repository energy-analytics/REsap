function smoothRamps(filename, filepath)
orig=modelicaread(strcat(filepath, filename));
Nres=2+(length(orig.time)-2)*2;
newdat=zeros(Nres,size(orig.data, 2));
newtime=zeros(Nres, 1);
newdat([1,end],:)=orig.data([1,end],:);
newtime([1,end])=orig.time([1,end]);
%
DT=5*60;
j=2;
for i=2:length(newtime)-1
    if ~mod(i,2)
        newtime(i)=orig.time(j)-DT;
        newdat(i,:)=orig.data(j-1,:);
    else
        newtime(i)=orig.time(j)+DT;
        newdat(i,:)=orig.data(j,:);
        j=j+1;    
    end    
end
result=timeseries(newdat, newtime);
result.DataInfo.UserData=orig.DataInfo.UserData;
modelicawrite(strcat(filepath, strrep(filename, 's_','s_smoothed_')),result);