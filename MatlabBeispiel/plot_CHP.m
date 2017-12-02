%Funktionen der Max und Min P/Q Diagramme für CHP
for i=isCHP
    figure;
    PQbdry=get(modelicaread(strcat('input/',param.dispUnits(i).p_q)), 'Data');
    % support for normalized diagrams:
    if ~isempty(strfind(param.dispUnits(i).p_q,'norm.txt'))
        PQbdry(:,1)=PQbdry(:,1)*param.dispUnits(i).Q_0*1e6;
        PQbdry(:,2:3)=PQbdry(:,2:3)*param.dispUnits(i).P_0*1e6;
    end       
    PQbdry=PQbdry*1e-6;
    plot(PQbdry(:,1), PQbdry(:,2),'k'); hold on;
    plot(PQbdry(:,1),PQbdry(:,3),'k');
    plot(param.dispUnits(i).Q_0*ones(1,2), PQbdry(end,[2 3]),'k')
    hold on
    iP=find(isPowerUnit==i);
    iQ=find(isHeatUnit==i);
    ylim([0 10+max(PQbdry(:,2))])
    plot(X_total.Q_t(:,iQ),X_total.P_t(:,iP), '*r');
    title(strcat('P-Q-Diagramm CHP:', param.dispUnits(i).Name));
    %
    % To be sure plot the constraints that intlinprog sees:
    qs=get(gca,'Xlim');
    for p=1:size(param.dispUnits(i).a, 1)
        plot(qs, param.dispUnits(i).b(p,1) + param.dispUnits(i).a(p,1) * qs, '--','Color',.7*ones(1,3));
        plot(qs, param.dispUnits(i).b(p,2) + param.dispUnits(i).a(p,2) * qs, '--','Color',.7*ones(1,3));
    end
    plot(PQbdry(:,1), PQbdry(:,2),'k'); hold on;
    plot(PQbdry(:,1),PQbdry(:,3),'k');
    
end
