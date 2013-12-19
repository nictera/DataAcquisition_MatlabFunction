function [newt] = spiketimes_tetd(x,thr,cutlen,savlen)
%form:  [t] = spiketimesc(x,thr)
%
%note: this function only considers upward and downward deflecting spikes.  It is for use with loadwavforclust...
%size(x)

pre=ceil(cutlen/3);
post=floor(cutlen/3*2)-1;
savpre=pre;
savpost=savlen-(savpre+1);



%% now do same thing with derivative

%d=diff(x);
%dnewt=[];

newt=[];

%threshold to get spikes (ie, 00001200020010100)
s=floor(x/thr);

%make list of timestamps where spike above threshold
t=find(s>0);

%% go through all start spike times, find max from start to savlen

exclude=[];


%get rid of spikes that are at the ends
f=find(t<=savpre+1);
t(f)=[];
f=find(t>length(x)-(savpost+1));
t(f)=[];


for j=1:length(t)
    start=t(j)-pre;
    f=find(start==exclude);
    if isempty(f)
            %cut out bit of x
            temp=x(start:start+cutlen-1);
            %find the peak
            tmax=find(temp==max(temp));
            %check and make sure the max is not at the end of the segment
            if isempty(find(tmax>cutlen-1))
                tmax=tmax(1);
                %have to add to start to make absolute time
                tmax=start+tmax;
                newt=[newt tmax];
                exclude=[exclude start:start+cutlen-1];
            end;
    end;
end;



%% plot
plt=0;
if plt==1
    thr
    max(x)
    figure(1)
    clf
    ax(1) = subplot(3,1,1)
    plot(x,'k')
    axis tight
    v=axis;
     ax(2) = subplot(3,1,2)
     z=zeros(size(x));
    z(t)=1;
    plot(z,'r')
    axis tight
    q=axis;
    axis([v(1) v(2) 0 1.1])
     ax(3) = subplot(3,1,3)
     z=zeros(size(x));
    z(newt)=1;
    plot(z,'r')
    axis tight
    q=axis;
    axis([v(1) v(2) 0 1.1])
    linkaxes(ax,'x')
    input('Hit enter to move to next')
end;
