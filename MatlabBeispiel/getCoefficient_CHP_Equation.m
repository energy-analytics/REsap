function [ a,b ] = getCoefficient_CHP_Equation( pq , unit )

n_equ=length(pq(:,1))-1;                                                %Number of min/max equation pairs
a=zeros(n_equ,2);
b=zeros(n_equ,2);
for i=1:n_equ
    x1= pq(i,1);
    x2=pq(i+1,1);
    %%Pmin equation
    y1=pq(i,3);
    y2=pq(i+1,3);
    a(i,1)=(y1-y2)/(x1-x2);
    b(i,1)=1.0e-6*((y2*x1)-(y1*x2))/(x1-x2);
    %Pmax equation
    y1=pq(i,2);
    y2=pq(i+1,2);
    a(i,2)=(y1-y2)/(x1-x2);
    b(i,2)=1.0e-6*((y2*x1)-(y1*x2))/(x1-x2);
end

assert(length(a)==length(b), ['Number of coefficient a (' num2str(length(a)) ') not equal to number of coefficient b (' num2str(length(b)) ') for CHP Unit ' unit '.']);

end

