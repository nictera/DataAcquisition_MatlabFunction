function tetclustho(filename,timerange,tets)
%form:  tetclustho(filename,timerange,tets)
%
%example:  tetclustho('data7332687782.txt',[1 35],4)
%
%This function requires the matlab Signal Processing Toolbox
%
%This function analyzes data from 4-tetrode array.
%channel 0 = sound
%tetrodes 1-3 are tetrodes, tetrode 4 is actually a triode due to bandwidth
%limitations.
%
%Data are subject to original strict Redish criteria: Lratio<0.05,
%Isolation Distance >16
%
%8-bit waveforms are used (for old LabView data sampled at 44100,
%experimentally determined ideal was 16-bit, but these new data are sampled
%at 22050)
%
%filename is data* filename
%
%timerange in seconds
%
%tetclustho.m has 300-10000Hz filter for waveform data, filter order of 200, and many fewer
%comments; hi
%
%tetclustho now determines threshold by taking midpoint of time range +/-
%50 seconds to avoid stimulation artifact contamination in calculation
%% initialize parameters

clc
format compact
format short g
close all
infofilename=['info' filename(5:length(filename)-4)];%this is a mat file
d=cd;
fn=filename;
filename=[d filesep filename]
infofilename=[d filesep infofilename]

datadir=cd;

if exist('tets')==0
    tets=1:4
end;
if isempty(tets)
    tets=1:4
end;

%%  read Daq

%get actual trial duration and sampling rate from daq file
DAQINFO = daqread(filename, 'info');
totsamples = DAQINFO.ObjInfo.SamplesAcquired;
fs=DAQINFO.ObjInfo.SampleRate;%actual sampling rate may vary from 22050 due to computer speed issues

if ~exist('timerange','var') || isempty(timerange)
    timerange=[0 floor(totsamples/fs)]; %see below: if isempty(timerange), then all data are analyzed
elseif length(timerange)==1
    timerange=[timerange floor(totsamples/fs)];
    
end;

%initialize length of spikes that go to klustakwik
cutlen=22;%was 8

%initialize length of spikes that are saved for duration etc analysis
savlen=64;%32 ->64 TAN 10/21/09
% Making this too large will cause antidromic spikes to be lost.
artwin=.010*fs;
artwin2=.003*fs;

%these define where peak is relative to rest of waveform
pre=ceil(cutlen/3);
post=floor(cutlen/3*2)-1;
savpre=16;%pre -> 16 TAN 10/21/09
savpost=savlen-(savpre+1);

%define tetrodes (per Steve Kerrigan 8/17/07 for 16-ch AM Systems amp with NeuroNexus probe)
tet(1,:)=[6 3 1 2];
tet(2,:)=[5 4 7 8];
tet(3,:)=[9 10 13 12];
tet(4,:)=[15 14 11 11];%need 4 channels so klustakwik doesn't choke

%********** need to add one to switch AMSystems values to NI
%values*********
tet=tet+1;

tet=tet(tets,:);

%load info file
load(infofilename)

%% make bandpass filter (800 - 5000 Hz)
%200-5000->300-10000 TAN 9/16/11
lo=300/floor(fs/2);%changed 800->200 TAN 9/6/2011
hi=10000/floor(fs/2);
bporder=250;%changed from 250 NFD 092011
bpe=fir1(bporder,[lo hi],'bandpass');

%% Do series manipulations for each separate tetrode

keepmedian=[];
dcsubtraction=[];
keepdat={};

for k=1:size(tet,1)
    t=tet(k,:);
    
    cd(datadir)
    close all
    
    tetrodeid=tets(k);
    channels=t;
    
    sprintf([':::::::::::::::::::::::\n Working on tetrode ' num2str(tets(k)) '\n:::::::::::::::::::::::\n'])
    tetdir=['E:\TetrodeAnalysis\dir' fn(5:length(fn)-4) '_CluRun1_Tet' num2str(tets(k))];
    [status,msg] = mkdir(tetdir);
    stop=0;
    if ~isempty(msg)%if directory already exists
        for i=2:100
            if stop==0
                tetdir=['E:\TetrodeAnalysis\dir' fn(5:length(fn)-4) '_CluRun' num2str(i) '_Tet' num2str(tets(k))];
                [s,msg]=mkdir(tetdir);
                sprintf(['Directory exists. Trying to make new directory ' tetdir])
                if isempty(msg)
                    stop=1;
                end;
            end;
        end;
    end;
    
    triallen=totsamples;%triallen in data points
    trialdur=floor(totsamples*fs);%what is this???
    
    
    if timerange(2)>totsamples/fs
        timerange(2)=totsamples/fs;
    end;
    
    %these must be integers
    timerange(1)=floor(timerange(1));
    timerange(2)=floor(timerange(2));
    
    %% get spike threshold
    % calculate 120 second threshold; 60 seconds on either side of middle of
    % timerange
    
    sprintf('Getting spike threshold...')
    
    threshwin=[];
    thr=[];
    thrs{4}=[];
    dthr=[];
    dthrs{4}=[];
    medthrs{4}=[];
    
    
    if ~exist('threshpad','var') || isempty(threshpad)
        threshpad=60; %in seconds; default was 60seconds
    end
    
   %timerange
    
    %Find middle of time range
    midtime=floor(timerange(2)/2);
    
    %Determine threshold window -- midtime +/- threshpad
    threshwin(1)=midtime-threshpad;
    threshwin(2)=midtime+threshpad;
    
    dat=daqread(filename,'Channels',t,'Samples',[floor(threshwin(1)*fs) floor(threshwin(2)*fs)]);
    
    %invert - biggest spikes are usually downward deflecting
    dat=-dat;
    
    % bandpass filter data
    for j=1:4
        dt=dat(:,j);
        udt=dt;
        dt=conv(dt,bpe);%filter
        dt=dt(bporder/2+1:length(dt)-bporder/2);%cut pieces off each end so that length same as original
        keepdat{j}=dt;
        keepmedian(j)=median(keepdat{j})
    end;
    
    plt=0;
    if plt==1 && (j==3 || j==4)
        figure(1)
        clf
        size(dt)
        plot(udt,'k');
        %input('hit enter\n');
        hold on
        plot(keepdat{j},'r');
        %input('hit enter\n');
        pause(10)
    end;
    
    if isequal(size(keepdat),[1 1])
        error('keepdat problem!')
    end
    
    % get median value (DC offset) for each channel.  Single DC offset
    % value for each channel will be subtracted when getting the spike
    % threshold and when finding spike times at TAN's request.
    
     for j=1:4
        sdat=keepdat{:,j};
        median(sdat)
        %subtract median from filtered data.
        %sdat=sdat-dcsubtraction(j);
        medthrs{j}=[medthrs{j}; median(sdat)+4*std(sdat)]; %NFD 4May09 for reanalysis of all data for comp with diaz.
        mthr(j)=median(medthrs{j})
        %dathrs{j}=[dathrs{j}; mean(diff(sdat(:,j)))+10*std(diff(sdat(:,j)))];
        %plot threshold window; indicate threshold
        plt=0
        if plt==1
           if j==4
                figure(2)
                clf
           end;
            subplot(4,1,j)
            plot(sdat,'k')
            axis tight
            plotyline(mthr(j));
            if j==4
                %input('hit enter');
                pause(10)
            end;
        end
    end
    

    %% get spike times
    sizetimes=0;
    
    if timerange(2)-timerange(1) >= 60
        win=60;
    else
        win=floor(timerange(2)/win)*win-win;
    end;
    
    timefile=[tetdir filesep 't'  fn(5:length(fn)-4) '-' num2str(tets(k))];%this is a binary file
    
    %create binary timefile
    fidt=fopen(timefile,'a');
    %st=fclose(fidt);
    
    sprintf('Getting spike times ...')
    
    times=[];
    
    
    for i=timerange(1):win:floor(timerange(2)/win)*win-win% this cuts off the last <1 minute of data e.g. if you have 30.99 minutes, you lose the last 0.99 minute
        
        beg=i;
        ed=i+win;
        
        dat=daqread(filename,'Channels',t,'Samples',[floor(beg*fs)+1 floor(ed*fs)]);
        
        %invert - biggest spikes are usu downward deflecting
        dat=-dat;
        
        
        tm{4}=[];
        for j=1:4
            % bandpass filter data
            dt=dat(:,j);
            dt=conv(dt,bpe);%filter
            
            dt=dt(bporder/2+1:length(dt)-bporder/2);%cut pieces off each end so that length same as original
            dat(:,j)=dt;
            
            %***************find spike times with thresholding*************************************
            
            [tm{j}]=spiketimes_tetd(dat(:,j),mthr(j),cutlen,savlen);
            
        end;
        
        spiketimes=[tm{1} tm{2} tm{3} tm{4}];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% eliminate spikes that are near
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% one another on 2 chs
        
        spiketimes=unique(spiketimes);
        spiketimes=sort(spiketimes);
        tall=spiketimes;
        
        
        %************compare amplitudes that overlap within cutlen--biggest channel gets to designate peak time. (cutlen > savlen)
        spktm=[];
        dup=0;
        
        %*************** spiketimes near artifacts tossed out ***********************
        
        stimcut=100000;
        
        tosst=[];
        for j=1:length(tall)
            f=find(tosst==tall(j));
            if isempty(f)
                skip =0;
                amp1=[];
                amp2=[];
                amp3=[];
                
                %cut out spike time and amplitude windows
                spkwin=tall(j)-pre:tall(j)+post;
                neg=sum(spkwin<=0);%neg should be 0 else go out of frame
                toolong=size(dat,1)-(tall(j)+post);%should be positive or 0
                if neg==0 && toolong>=0
                    amp=[];
                    inds=[];
                    for m=1:4
                        [mx,ind]=max(dat(spkwin,m));
                        if mx<stimcut
                            amp=[amp; mx];
                            inds=[inds;ind];%time index of max value
                        else
                            tosst=[tosst; tall(j)-artwin2:tall(j)+artwin2];
                            skip = 1;
                        end;
                    end;
                    if skip ==0
                        mx=find(amp==max(amp));
                        %limit to lowest electrode index if more than one
                        mx=mx(1);
                        spktm=[spktm spkwin(inds(mx))];
                        tosst=[tosst; spkwin(inds(mx))-pre:spkwin(inds(mx))+post];%TAN 11/20/09 toss spikes on different wires that overlap in time
                    end;
                end;
            end;
        end;
        
        %convert spktm to absolute spktm from 10-sec window spiketime
        spktm=spktm + (i*fs);
        spktm=spktm';
        
        spktm=unique(spktm);
        
        
        %get rid of spike times near ends*********************
        %since absolute spike times, these will only get rid of stuff on first and last
        %analysis windows
        f=find(spktm<=savpre);
        spktm(f)=[];
        f=find(spktm>=floor(timerange(2)*fs)-savpost);
        spktm(f)=[];
        
        
        
        %add spike times to timefile
        count=fwrite(fidt,spktm,'uint32');
        
        
        sizetimes=sizetimes + size(spktm,1);
        sprintf(['Total number of spikes: ' num2str(sizetimes)])
        
        %sprintf(['Maximum spike time: ' num2str(max(spktm)/fs)])
        
        sprintf(['Percent done: ' num2str((ed/timerange(2))*100)])
        
        
        
        %plt=1 to show all time stamps relative to trodes
        plt=0;
        if plt==1
            
            %fidt=fopen(timefile,'r');
            %all=fread(fidt,inf,'uint32');
            %st=fclose(fidt);
            
            figure(3)
            clf
            ax(1) = subplot(5,1,1);
            % f=find(all>=floor(timerange(1)*fs) & all<=floor(timerange(2)*fs));
            % all=all(f)-floor(timerange(1)*fs)+1;
            z=zeros(size(dat,2),1);
            z(spktm)=1;
            stem(z,'r');
            axis tight
            %dat=daqread(filename,'Channels',t,'Samples',[floor(timerange(1)*fs) floor(timerange(2)*fs)]);%[all(1) all(length(all))]);
            
            for i=1:4
                cnt=i+1;
                ax(cnt) = subplot(5,1,i+1);
                plot(dat(:,i),'k')
                axis tight
            end;
            linkaxes(ax,'x')
            input('Hit enter to continue.')
        end;
    end;
    st=fclose(fidt);
    
    %% get spike waveforms
    sprintf('Getting spike waveforms...')
    
    wvfile=[tetdir filesep 'wv'  fn(5:length(fn)-4) '-' num2str(tets(k))];%this is a binary file
    swvfile=[tetdir filesep 'swv'  fn(5:length(fn)-4) '-' num2str(tets(k))];%this is a binary file
    %create binary waveform files
    fidwv=fopen(wvfile,'a');
    fidswv=fopen(swvfile,'a');
    
    
    fidt=fopen(timefile,'r');
    
    numspks=100000;
    
    for i=1:floor(sizetimes/numspks)%for every numspks spike times
        
        if rem(i,10)==0
            sprintf('%d %% done',round(100*i/floor(sizetimes/numspks)))
        end;
        
        %initialize zero matrices
        wv(1:4,1:cutlen)=0;
        swv(1:4,1:savlen)=0;
        
        %read spike time
        %  all=fread(fidt,inf,'uint32')
        stime=fread(fidt,numspks,'uint32');
        
        
        %load raw data
        % wvdat=daqread(filename,'Channels',t,'Samples',[stime-pre stime+post]);
        spikesplus = daqread(filename,'Channels',t,'Samples',[stime(1)-savpre stime(length(stime))+savpost]);%this is for entire
        
        %FILTER TAN 9/6/2011*********************
        for j=1:4
            dt=conv(spikesplus(:,j),bpe);%filter
            dt=dt(bporder/2+1:length(dt)-bporder/2);%cut pieces off each end so that length same as original
            %subtract median to get rid of offsets
            dt=dt-median(dt);
            spikesplus(:,j)=dt;
        end;
        
        
        %now reset spiketimes so that they match the shortened
        %continously captured vector (the first element index was
        stime=stime-stime(1)+savpre+1;
        
        
        sprintf('cutting out spikes from continuous recording...')
        
        for m=1:length(stime)
            if stime(m)+savpost<=length(spikesplus) && stime(m)-savpre > 0  %stime(m)-savpre>=1
                swvdat=spikesplus(stime(m)-savpre:stime(m)+savpost,:);
                wvdat=swvdat(savpre-pre+1:savpre-pre+cutlen,:);
                
                for j=1:3
                    wv(j,:)=wvdat(:,j);
                    swv(j,:)=swvdat(:,j);
                    
                end;
                if tets(k)~=4
                    wv(4,:)=wvdat(:,4);
                    swv(4,:)=swvdat(:,4);
                end;
                
                
                count=fwrite(fidwv,wv,'double');%count is 48 for each (4*cutlen)
                count=fwrite(fidswv,swv,'double');%count is ** for each (4*savlen)
            end;
        end;
        
        stime=[];
        plt=0;
        if plt==1
            figure(1)
            for m=1:4
                subplot(4,1,m)
                hold on
                plot(swv(m,:),'k')
            end;
            input('hit enter')
        end;
        
    end;%end of for loop for sets of numspks spiketimes
    
    %now deal with left over spikes at end of spiketimes (the bit
    %after taking all the 1000-spike chunks)
    stime=fread(fidt,inf,'uint32');
    
    spikesplus = daqread(filename,'Channels',t,'Samples',[stime(1)-savpre stime(length(stime))+savpost]);
    
    %FILTER TAN 9/6/2011*********************
    for j=1:4
        udt=spikesplus(:,j);
        dt=conv(spikesplus(:,j),bpe);%filter
        dt=dt(bporder/2+1:length(dt)-bporder/2);%cut pieces off each end so that length same as original
        %subtract median to get rid of offsets
        dt=dt-median(dt);
        spikesplus(:,j)=dt;
        plt=0;
        if plt==1 && (j==1 || j==2)
            figure(1)
            clf
            size(dt)
            plot(udt,'k');
            input('hit enter\n');
            hold on
            plot(dt,'r');
            input('hit enter\n');
        end;
    end;
    
    
    stime=stime-stime(1)+savpre+1;
    sprintf('cutting out spikes from continuous recording for last few spikes...')
    size(stime)
    for m=1:length(stime)
        
        if stime(m)+savpost<=length(spikesplus) && stime(m)-savpre > 0
            swvdat=spikesplus(stime(m)-savpre:stime(m)+savpost,:);
            wvdat=swvdat(savpre-pre-1:savpre-pre+cutlen-2,:);%changed TAN 10/21/09
            % size(wvdat)
            
            for j=1:3
                wv(j,:)=wvdat(:,j);
                swv(j,:)=swvdat(:,j);
                
            end;
            if tets(k)~=4
                wv(4,:)=wvdat(:,4);
                swv(4,:)=swvdat(:,4);
            end;
            
            
            count=fwrite(fidwv,wv,'double');%count is 32 for each (4*8)
            count=fwrite(fidswv,swv,'double');%count is * for each (4*28)
        end;
    end;
    
    
    st=fclose(fidt);
    st=fclose(fidwv);
    st=fclose(fidswv);
    
    %% cluster
    sprintf('Clustering data ...')
    
    cd(tetdir)
    
    filename=fn;
    save(['filestats' num2str(tetrodeid)],'sizetimes','timerange','triallen','trialdur','filename','tetrodeid','channels','datadir','cutlen','savlen','fs','mthr','spktm')
    
    %run KlustaKwik/mclust subprograms
    runclustbatchtn_tetc(tetrodeid)
    
    
end;
