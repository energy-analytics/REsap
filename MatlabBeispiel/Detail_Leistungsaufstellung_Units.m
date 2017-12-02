%Detail Auflistung Kennzahlen Units

UnitResults.P=sum(X_total.P_t(:,1:length(isPowerUnit)));
UnitResults.Q=sum(X_total.Q_t);
UnitResults.zs=sum(X_total.zs_t);

%PowerUnits
for i=isPowerUnit
    iPowerUnit=isDispUnit(isPowerUnit==i);
    PowerUnitResults(iPowerUnit).Name=param.dispUnits(i).Name;
    PowerUnitResults(iPowerUnit).c_Prod=param.dispUnits(i).c_prod;
    PowerUnitResults(iPowerUnit).kum_P=UnitResults.P(iPowerUnit);
    PowerUnitResults(iPowerUnit).kum_p_Cost=UnitResults.P(iPowerUnit)*param.dispUnits(i).c_prod;
    if find(i==isStateUnit)
        iStateUnit=isDispUnit(isStateUnit==i);
        PowerUnitResults(iPowerUnit).kum_zs=UnitResults.zs(iStateUnit);
        PowerUnitResults(iPowerUnit).c_start=param.dispUnits(i).c_start;
        PowerUnitResults(iPowerUnit).kum_zs_Cost=UnitResults.zs(iStateUnit)*param.dispUnits(i).c_start;
        PowerUnitResults(iPowerUnit).total_cost=PowerUnitResults(iPowerUnit).kum_p_Cost+PowerUnitResults(iPowerUnit).kum_zs_Cost;
    else
        PowerUnitResults(iPowerUnit).kum_zs=[nan];
        PowerUnitResults(iPowerUnit).c_start=[nan];
        PowerUnitResults(iPowerUnit).kum_zs_Cost=[nan];
        PowerUnitResults(iPowerUnit).total_cost=PowerUnitResults(iPowerUnit).kum_p_Cost;
    end
end
%HeatUnits
if isHeatUnit~=0
    for i=isHeatUnit
        iHeatUnit=isDispUnit(isHeatUnit==i);
        HeatUnitResults(iHeatUnit).Name=param.dispUnits(i).Name;
        HeatUnitResults(iHeatUnit).c_prod=param.dispUnits(i).c_prod;
        HeatUnitResults(iHeatUnit).kum_Q=UnitResults.Q(iHeatUnit);
        HeatUnitResults(iHeatUnit).kum_Q_Cost=UnitResults.Q(iHeatUnit)*param.dispUnits(i).c_prod;
    end
end
disp(struct2table(PowerUnitResults));
if isHeatUnit~=0;disp(struct2table(HeatUnitResults));end
disp(sprintf('Total Cost // Power: %d' , sum([PowerUnitResults.total_cost]))); 
if isHeatUnit~=0;disp(sprintf('Total Cost // Heat: %d' , sum([HeatUnitResults.kum_Q_Cost])));end
if isHeatUnit~=0;disp(sprintf('Total Cost // All: %d' , sum([HeatUnitResults.kum_Q_Cost PowerUnitResults.total_cost])));end