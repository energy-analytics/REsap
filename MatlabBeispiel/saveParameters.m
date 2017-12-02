function saveParameters(file, param)
if ~exist('output','dir'); 
    mkdir('output');
end;
writetable(struct2table(param.dispUnits), 'output/disp.txt');
writetable(struct2table(param.REUnits), 'output/re.txt');
writetable(struct2table(param.const), 'output/const.txt');
zip(file, { 'output/disp.txt', 'output/re.txt', 'output/const.txt'});
delete('output/disp.txt','output/re.txt','output/const.txt')