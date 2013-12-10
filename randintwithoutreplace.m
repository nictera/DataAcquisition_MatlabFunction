function [r] = randintwithoutreplace(n,rg)
%This is not the Matlab randint!
%Written by Teresa Nick 03-07-04
%rg in form [min max]

r=rand(1,n*1000);
out=rg(1,1)+round((rg(1,2)-rg(1,1))*r);

%get rid of repeats
r=[];
for i=1:n*1000
    if length(r)<n
    if isempty(find(r==out(i)))
    
        r=[r; out(i)];

    end;
    end;
end;
