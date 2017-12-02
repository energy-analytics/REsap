function [units, extraparams]=getScenarioDefinition(scenario, muck)
% While developing new scenarios run: clc;disp(struct2table(getTypeDefinition))
typeparams = getTypeDefinition();
% 
% >> Balancing reserve constraints
extraparams.P_Pri=11;                                                       % Primary reserve demand (=3000 MW * 12,872 TWh / 3383,128 TWh )
extraparams.P_Pri_Bandwidth=0.05;                                           % Primary balance providers can provide 5% of their nominal power (with fast enough ramping for pribal)
extraparams.P_Sec_up=57;                                                    % Upspinning secondary reserve demand (sqrt(10*2012+150^2)-150)
extraparams.P_Sec_down=57;                                                  % Downspinning secondary reserve demand 
extraparams.t_Sec_react=5/60;                                               % Time in h for secondary balancing units to react (Pmax_sec = 5 minutes * maximum unit gradient)
extraparams.flexBalancing=0;
extraparams.T_N_min=0.5*10;                                                 % Minimum grid time constant, i.e. Maximum nonsynchronous penetration of 50% times Grid time constant of 10s (todays value)
extraparams.Pwindinertia=0;                                                 % 200kW/1.5MW/150GW/(0,2%)(set to zero to deactivate wind inertia potentials)
datapath='../../../../../transient_library\TransiEnt\Tables\electricity\';
extraparams.filename_electricLoad=strcat(datapath,'ElectricityDemandHH_900s_01.01.20120-01.01.20130.txt');
extraparams.filename_heatLoad='HeatDemandHHVattenfall_2012.txt';
extraparams.filename_LFsite='LoadFactor4SitesHHVattenfall_2012.txt';
extraparams.filename_ROWProfile=strcat(datapath, 'RunOfWaterPlant_normalized_1J_2012.txt');
extraparams.filename_PVProfile=strcat(datapath, 'REProfiles/Solar2015_Gesamt_900s.txt');
extraparams.filename_WindProfile=strcat(datapath, 'REProfiles/Wind2015_Tennet_Onshore_900s.txt');
extraparams.filenameWindOffshore=strcat(datapath, 'REProfiles/Wind2015_Tennet_Offshore_900s.txt');
extraparams.forceFullLoadHours=0;                                           % [ROW/PV/On/Off] Set to 0 to use the RE production files as they are (no manipulation of full load hours)
%
% Default scenario:
names={'NUK' 'BK', 'WT', 'GuDTS' 'WW1', 'WW2','SKEL', 'GuD' 'GT1' 'GT2' 'GT3' 'OIL','OILGT' 'GAR','BM','PS_T', 'PS_P', 'ROW','PV','Onshore','Offshore', 'Curtailment', 'Import'};
types=[1,2,3,7,4,5,6,7,8,8,8,9,10,11,12,13,14,25,25,25,25,26,27];    
%clc;disp(array2table(types, 'VariableNames', names))
P_0_12_Default=[254 445 206 125 151 138 39 322 60 60 0 58 26 33 133 131 -131 90 677 634 6 -2.5e3 2.5e3];    
P_0_35_Default=[0 191 206 125 470 0 24 77 60 60 60 17 0 33 196 260 -260 86 1225 1816 378 -6e3 6e3];    
types_35_Default=types; types_35_Default(5)=29;
P_0_22_Default=interp1([12;35], [P_0_12_Default;P_0_35_Default], 22); P_0_22_Default(1)=0; % linear interpolated between 12 and 35 but without nuclear
P_0_50_Default=[0 191 206 125 470 0 24 77 60 60 60 17 0 33 227 260 -260 86 1378 2582 639 -8e3 8e3];    
% Default is uncoupled simulation:
Q_0=nan(size(types));
e_start=nan(size(types));
sites=nan(size(types));
isSecBalUnit=nan(size(types));
%
% >> Szenario Definition
variants=linspace(0.7,1.3,7);
switch scenario
    case 'REF12' 
        extraparams.forceFullLoadHours=[5010 825 1490 2400];  
        P_0=P_0_12_Default;
    case 'REF35' 
        P_0=P_0_35_Default;
    case 'REF50' 
        P_0=P_0_50_Default;        
    case 'REF15'
       P_0=round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2015));
    case 'REF20'
       P_0=round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2020));
    case 'REF25'
       P_0=round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2025));
    case 'REF30'
       P_0=round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2030));
    case 'REF40'
       P_0=round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2040));
    case 'REF45'
       P_0=round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2045));                
    case 'REF35PR25' 
        P_0=P_0_35_Default;            
        types=types_35_Default;
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.25;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.25;          
    case 'REF35PR50' 
        P_0=P_0_35_Default;            
        types=types_35_Default;
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.5;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.5;  
     case 'REF35PR75' 
        P_0=P_0_35_Default;            
        types=types_35_Default;
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.75;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.75;         
    case 'REF35PR100' 
        P_0=P_0_35_Default;            
        types=types_35_Default;
        extraparams.P_Sec_up=extraparams.P_Sec_up*2;
        extraparams.P_Sec_down=extraparams.P_Sec_down*2;          
    case 'REF35psp25' 
        P_0=P_0_35_Default;    
        P_0(16:17)=P_0(16:17)*1.25;            
        types=types_35_Default;
    case 'REF35psp50' 
        P_0=P_0_35_Default;    
        P_0(16:17)=P_0(16:17)*1.5;            
        types=types_35_Default;
    case 'REF35psp75' 
        P_0=P_0_35_Default;    
        P_0(16:17)=P_0(16:17)*1.75;            
        types=types_35_Default;
    case 'REF35psp100' 
        P_0=P_0_35_Default;    
        P_0(16:17)=P_0(16:17)*2;            
        types=types_35_Default;        
    case 'REF35psp1700' 
        P_0=P_0_35_Default;    
        P_0(16:17)=P_0(16:17)*17;            
        types=types_35_Default;                
    case 'REF50PR100' 
        extraparams.P_Sec_up=extraparams.P_Sec_up*2;
        extraparams.P_Sec_down=extraparams.P_Sec_down*2; 
        P_0=P_0_50_Default;            
        types=types_35_Default;
    case 'REF50psp25' 
        P_0=P_0_50_Default;    
        P_0(16:17)=P_0(16:17)*1.25;            
        types=types_35_Default;
    case 'REF50psp50' 
        P_0=P_0_50_Default;    
        P_0(16:17)=P_0(16:17)*1.5;            
        types=types_35_Default;
    case 'REF50psp75' 
        P_0=P_0_50_Default;    
        P_0(16:17)=P_0(16:17)*1.75;            
        types=types_35_Default;
    case 'REF50psp100' 
        P_0=P_0_50_Default;    
        P_0(16:17)=P_0(16:17)*2;            
        types=types_35_Default;        
    case 'OPT35b' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:},'GuDExtra1','GuDExtra2'}; % add heat units and dsm option
        types=[28,20,19,19,19,types, 7, 7];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default 750 750];    
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];
    case 'OPT50b' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:},'GuDExtra1','GuDExtra2'}; % add heat units and dsm option
        types=[28,20,19,19,19,types, 7, 7];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_50_Default 750 750];    
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];        
    case 'OPT30' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2030))];
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];  
    case 'OPT35' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];   
    case 'OPT35c' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps_justHP.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];         
    case 'OPT40' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2040))];
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];        
    case 'OPT45' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2045))];
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];      
    case 'OPT35WP50' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063*.5 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];          
    case 'OPT35WP75' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063*.5 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps_shifted.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];                  
 % ------------------------- KWK in allen Jahre ------------------------------------------------------------------------------------       
    case 'KWK30'
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2030))];
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;        
    case 'KWK35' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;
    case 'KWK40' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2040))];
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;     
    case 'KWK45' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2045))];
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;        
    case 'KWK50' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 P_0_50_Default];    
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;
    case 'KWK35PR25' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.25;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.25;  
    case 'KWK35PR50' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.5;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.5; 
    case 'KWK35PR75' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.75;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.75; 
    case 'KWK35PR100' 
        names={'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:4 7:9])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:4 7:9])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.P_Sec_up=extraparams.P_Sec_up*2;
        extraparams.P_Sec_down=extraparams.P_Sec_down*2;         
    case 'HPS35'
        names={'HPS',names{:}};
        types=[28, types_35_Default]; 
        P_0=[-2063, P_0_35_Default];   
        Q_0=nan(size(P_0));
        isSecBalUnit=nan(size(P_0));
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        e_start=nan(size(types));
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];
    case 'HPS50'
        names={'HPS',names{:}};
        types=[28, types_35_Default]; 
        P_0=[-2063, P_0_50_Default];   
        Q_0=nan(size(P_0));
        isSecBalUnit=nan(size(P_0));
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        e_start=nan(size(types));
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];        
    case 'OPT50' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];
    case 'OPT35PR25' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];  
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.25;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.25;        
    case 'OPT35PR50' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];   
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.5;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.5;            
    case 'OPT35PR75' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];   
        extraparams.P_Sec_up=extraparams.P_Sec_up*1.75;
        extraparams.P_Sec_down=extraparams.P_Sec_down*1.75;    
    case 'OPT35PR100' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1]; 
        extraparams.P_Sec_up=extraparams.P_Sec_up*2;
        extraparams.P_Sec_down=extraparams.P_Sec_down*2;    
% --------------------------------------------------------------------------------------------------------------------------------------------------        
    case 'PTH35' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];  
    case 'PTH35p25' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*1.25 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*1.25 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];     
    case 'PTH35p50' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*1.5 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*1.5 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];      
    case 'PTH35p75' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*1.75 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*1.75 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];
    case 'PTH35p100' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*2 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*2 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];                          
% --------------------------------------------------------------------------------------------------------------------------------------------------        
    case 'PTHSTOR30'
        pthscale=1;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2030))];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];  
    case 'PTHSTOR35'
        pthscale=1;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];  
    case 'PTHSTOR40'
        pthscale=1;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2040))];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];  
    case 'PTHSTOR45'
        pthscale=1;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 round(interp1([2012;2022;2035;2050], [P_0_12_Default;P_0_22_Default;P_0_35_Default;P_0_50_Default], 2045))];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];          
    case 'PTHSTOR35p25' 
        pthscale=1.25;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:8 11:13])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];    
    case 'PTHSTOR35p50'
        pthscale=1.5;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:8 11:13])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1]; 
    case 'PTHSTOR35p75'
        pthscale=1.75;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:8 11:13])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1]; 
    case 'PTHSTOR35p100'
        pthscale=2;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthscale 0 0 0 0 0 0 P_0_35_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthscale 100*pthscale -100*pthscale 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:8 11:13])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1;isSecBalUnit(find(types==12))=1;  
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];       
    case 'PTHSTOR35p400' 
        names=[{'HPS','P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*4 0 0 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:8 11:13])=[100*4 100*4 -100*4 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:8 11:13])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];          
% --------------------------------------------------------------------------------------------------------------------------------------------------
    case 'OPT35psp25' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0_35_Default(16:17)=P_0_35_Default(16:17)*1.25;           
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];    
    case 'OPT35psp50' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0_35_Default(16:17)=P_0_35_Default(16:17)*1.5;           
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];       
    case 'OPT35psp75' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0_35_Default(16:17)=P_0_35_Default(16:17)*1.75;           
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];       
    case 'OPT35psp100' 
        names={'HPS','MVB','HWHafen','SpiVoWedel','SpiVoTiefstack',names{:}}; % add heat units and dsm option
        types=[28,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0_35_Default(16:17)=P_0_35_Default(16:17)*2;           
        P_0=[-2063 0 0 0 0 P_0_35_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:5 8:10])=[115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:5 8:10])=[1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;isSecBalUnit(find(types==12))=1;
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];          
% --------------------------------------------------------------------------------------------------------------------------------------------------        
    case 'PTH50' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];  
    case 'PTH50p25' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*1.25 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*1.25 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];     
    case 'PTH50p50' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*1.5 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*1.5 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];      
    case 'PTH50p75' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*1.75 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*1.75 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];
    case 'PTH50p100' 
        names=[{'HPS','P2H', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*2 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:6 9:11])=[100*2 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:6 9:11])=[2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];                          
% --------------------------------------------------------------------------------------------------------------------------------------------------        
    case 'PTHSTOR50'
        pthstor=1;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthstor 0 0 0 0 0 0 P_0_50_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthstor 100*pthstor -100*pthstor 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];   
    case 'PTHSTOR50p25'
        pthstor=1.25;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthstor 0 0 0 0 0 0 P_0_50_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthstor 100*pthstor -100*pthstor 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];   
    case 'PTHSTOR50p50'
        pthstor=1.5;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthstor 0 0 0 0 0 0 P_0_50_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthstor 100*pthstor -100*pthstor 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1]; 
    case 'PTHSTOR50p75'
        pthstor=1.75;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthstor 0 0 0 0 0 0 P_0_50_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthstor 100*pthstor -100*pthstor 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1];  
    case 'PTHSTOR50p100'
        pthstor=2;
        names=[{'P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-101*pthstor 0 0 0 0 0 0 P_0_50_Default];    
        Q_0=nan(size(P_0));Q_0([1:7 10:12])=[100*pthstor 100*pthstor -100*pthstor 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([1:7 10:12])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[2:length(P_0(P_0~=0)), 1]; 
    case 'PTHSTOR50p400' 
        names=[{'HPS','P2H','HeatStorOut','HeatStorIn', 'MVB','HWHafen','SpiVoWedel','SpiVoTiefstack'},names]; % add heat units and dsm option
        types=[28,21,23, 24, 20,19,19,19,types];                                      
        types(find(strcmp(names, 'WT')))=15;
        types(find(strcmp(names, 'WW1')))=16;
        names{find(strcmp(names, 'WW1'))}='GuDW';
        types(find(strcmp(names, 'GuDTS')))=16;
        P_0=[-2063 -101*4 0 0 0 0 0 0 P_0_50_Default];    
        extraparams.dss{1}.p_load={'p_load_hps.txt'}; 
        Q_0=nan(size(P_0));Q_0([2:8 11:13])=[100*4 100*4 -100*4 115 340 180 320 290 180 220];
        sites=nan(size(Q_0));sites([2:8 11:13])=[2 2 2 1 3 2 1 1 1 2];              % Sites: 1=East, 2=West, 3=Hafen, 4=WUW        
        e_start=nan(size(types));
        extraparams.flexBalancing=1;
        extraparams.P_Pri=0; 
        extraparams.Pwindinertia=0.2/1.5/150e3/2e-3;                    
        isSecBalUnit=nan(size(P_0));isSecBalUnit(find(types==26))=1; isSecBalUnit(1)=1;isSecBalUnit(find(types==12))=1;    
        extraparams.reorderResultFile=[3:length(P_0(P_0~=0)), 1, 2];         
% --------------------------------------------------------------------------------------------------------------------------------------------------        		
        
    case 'REF12' 
        extraparams.forceFullLoadHours=[5010 825 1490 2400];  
        P_0=P_0_12_Default;    
    case 'VALID' 
        extraparams.forceFullLoadHours=[5010 799 1630 2490];  
        P_0=P_0_12_Default;            
    case 'VALIDOLD'
        names={'NUK' 'BK' 'SK_KWK' 'SK_El' 'GuD_KWK' 'GuD_El' 'GT' 'BM' 'PS_T' 'PS_P' 'LW' 'PV' 'Onshore' 'Offshore'};
        types=[1 2 4 6 5 7 8 12 13 14 25 25 25 25];
        P_0=[297 521 624*.1 .9*624 543/3 2*543/3 121 140 157 -157 108 814 762 7];      
        extraparams.forceFullLoadHours=[5010 825 1490 2400]; 
        % Default is uncoupled simulation:
        Q_0=nan(size(types));
        e_start=nan(size(types));
        sites=nan(size(types));
        isSecBalUnit=nan(size(types));
        % update cost parameters
%         c_prod_new=[10.9 20.9 29 29 29 29 39.2 58.3 5 0 0 0 0 0 -10e3 0 0];
%         for i=1:length(typeparams)
%             typeparams(i).c_prod=c_prod_new(i);
%         end
    otherwise 
        error(['Scenario ' scenario ' undefined']);
end
%
assert(length(types)==length(names), ['Number of types (' num2str(length(types)) ') not equal to number of names (' num2str(length(names)) ') in scenario ' scenario '.']);
assert(length(types)==length(P_0), ['Number of types (' num2str(length(types)) ') not equal to length of installed electricity power vector (' num2str(length(P_0)) ') in scenario ' scenario '.']);
assert(length(types)==length(Q_0), ['Number of types (' num2str(length(types)) ') not equal to length of installed Heat power vector (' num2str(length(Q_0)) ') in scenario ' scenario '.']);
sortOutIdx=intersect(find(P_0==0),find(isnan(Q_0)));
types(sortOutIdx)=[]; 
names(sortOutIdx)=[];
e_start(sortOutIdx)=[];
isSecBalUnit(sortOutIdx)=[];
Q_0(sortOutIdx)=[];
P_0(sortOutIdx)=[];
sites(sortOutIdx)=[];
if ~isempty(intersect(find(P_0==0),find(isnan(Q_0)))); warning(sprintf('%s %.f %s\n','Warning: Removed unit(s) ',intersect(find(P_0==0),find(isnan(Q_0))), ' since P_0=0 and Q_0=nan'));end;
% allow that sites are not defined
if ~sum(~isnan(Q_0))
    sites=nan(size(P_0));
end
if ~exist('sites', 'var')
    error('Site vector must be defined');
end
units=typeparams(types);
for i=1:length(units); 
    units(i).Name=names{i}; 
    units(i).Q_0=Q_0(i);
    units(i).P_0=P_0(i); 
    if ~isnan(e_start(i))
        units(i).e_start=e_start(i);
    end
    units(i).site=sites(i);
    if exist('c_prod','var') && ~isnan(c_prod(i))
        units(i).c_prod=c_prod(i);
    end
    if exist('e_max','var') && ~isnan(e_max(i))
    units(i).e_max=e_max(i);
    end    
    if exist('isSecBalUnit','var') && ~isnan(isSecBalUnit(i))
    units(i).isSecBalUnit=isSecBalUnit(i);
    end      
end;
% check storage parameters
for s=find([units.isStorage])
    assert(~isnan(units(s).e_max), sprintf('%s%.0f%s','Scenario Error: Storage with index ',s,' has no maximum energy level (e_max) defined'));
    assert(~isnan(units(s).e_start), sprintf('%s%.0f%s','Scenario Error: Storage with index ',s,' has no initial energy level (e_start) defined'));
    assert(units(s).e_start>=units(s).e_min,sprintf('%s %.f %s%.f%s%.f%s','>> Scenario Error: Start value of storage',s,'(',e_start(s),') below minimum level(',units(s).e_min,')'));
end
% check chp parameters
for i=find([units.isCHP])
    assert(~isnan(units(i).Q_0),sprintf('%s %.f %s','>> Sceneario Error: CHP unit',i,'has no rated thermal power defined'));    
    assert(~isnan(units(i).P_0),sprintf('%s %.f %s','>> Sceneario Error: CHP unit',i,'has no rated electric power defined'));
end
% save file names of dss units
idss=1;
for dss=find([units.isDSS])
    extraparams.dss{1}(idss).e_max=units(dss).e_max;
    extraparams.dss{1}(idss).e_start=units(dss).e_start;
    units(dss).e_max=nan; units(dss).e_start=nan;idss=idss+1;
end
% check heating network parameters
nsitesdef=size(get(modelicaread(strcat('input/', extraparams.filename_LFsite)), 'Data'),2);
if nsitesdef~=max(sites)
    warning(strcat(num2str(nsitesdef),' sites defined in file (', extraparams.filename_LFsite, '). There are sites in the scenario without heating plants (plants defined at:', num2str(unique(sites(~isnan(sites)))),').'));
end
% Hack 2012
if strcmp(scenario, 'REF12')
    for u=1:length(units)
        if strcmp(units(u).p_min_t, 'WT_pmin_2035.txt')
            units(u).p_min_t = 'WT_pmin_2012.txt';
            units(u).p_max_t = 'WT_pmax_2012.txt';
        end
    end
end
% display
if ~exist('muck','var')
    fprintf('%s\n\n','>> Successfully defined properties of generation park:');
    if length(units)>1 
    disp(struct2table(units, 'RowNames', cellfun(@num2str, num2cell(1:length(units)), 'UniformOutput',false))); 
    else
        disp(units(1));
    end
end
end