t = (1/16:1/8:(1+1/8))'*2*pi;
x = sin(t);
y = cos(t);
h_line= plot(x,y,'k-')
%%
hatch(h_line,[90 80 0.01],'r')
