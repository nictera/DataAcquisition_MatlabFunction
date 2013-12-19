function plotyline(y,xax,color)
%form:
%
hold on
if exist('color','var')==0
    color='y';
end;
if ~exist('xax','var') || isempty(xax)
    v=axis;
    xax=v(1:2);
end;


c=[color '-'];

y=[y y];

plot(xax,y,c,'LineWidth',2)