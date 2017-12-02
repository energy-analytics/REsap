function [dfUnits, dfExtraparams]=compareScenarios(name1, name2)
[units1, extraparams1]=getScenarioDefinition(name1,0);
[units2, extraparams2]=getScenarioDefinition(name2,0);
[dfUnits, ~, ~, ~] =comp_struct_old(orderfields(units1),orderfields(units2),0);
[dfExtraparams, ~, ~, ~] =comp_struct_old(orderfields(extraparams1),orderfields(extraparams2),0);
clc;
disp(['>> Compared scenarios: ' name1 ' and ' name2])
disp('Differences in Units:')
disp(dfUnits)
disp('Differences in Extraparams:')
disp(dfExtraparams)

