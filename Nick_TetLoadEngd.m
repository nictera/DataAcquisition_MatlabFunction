function [t,wv] = Nick_TetLoadEngd(filename,records_to_get,record_units)
%form:  [t,wv] = loadforclustunpkc(filename,records_to_get,record_units)
%
%these data are for export to mclust for cluster analysis

% this file must be updated in matlab_functions/tetrodeanalysis &
% matlab_functions\MClust-3.5\MClust\LoadingEngines\Nick_TetLoadEng


%fs=22050;



%look for mat file containing all t's and wv's in current directory
x=which('twv.mat');

if isempty(x) %mat file has not been created from binary files
    sprintf('Converting binary files to handy mat file...')
    fn=FindFiles('filestats');
    fn=fn{1};
    load(fn)
    
    fsep=find(fn==filesep);
    fn=fn(fsep(length(fsep)):length(fn));
    s=find(fn=='s');
    trodenum=fn(s(2)+1:length(fn)-4);

    
    totspks=sizetimes;
    tottime=triallen;
    %get binary file names
    filename
    timefile=['t'  filename(5:length(filename)-4) '-' trodenum];%this is a binary file
    wvfile=['wv'  filename(5:length(filename)-4) '-' trodenum];%this is a binary file
    wavsize=cutlen*4;

    %get tt (all t's) from binary file
    fidt=fopen(timefile,'r');
    tt=fread(fidt,inf,'uint32');
    st=fclose(fidt);
    %get wvt (all wv's) from binary file
    wvt=[];
    fidwv=fopen(wvfile,'r');
    sprintf('Getting waveforms...')
    %initialize wvt matrix
    %to 4*length(tt) rows and cutlen columns to speed process
    wvt=zeros(4*length(tt),cutlen);
    for i=1:totspks
        if rem(i,1000)==0
                sprintf(['Percent done: ' num2str((i/totspks)*100)])
        end;
        wave=fread(fidwv,wavsize,'double');
        wave=reshape(wave,4,cutlen);
        wvt(((i-1)*4)+1:((i-1)*4)+4,:)=wave;
    end;
    wvt=reshape(wvt,[4 size(wvt,1)/4 cutlen]);
    wvt = permute(wvt,[2 1 3]);
% st=fclose(fidt);
 st=fclose(fidwv);

    % save the data
    save twv tt wvt totspks
%else%data have not yet been loaded, global vars initialized to empty set
   
end;

 load twv tt wvt totspks
 
 if ~exist('totspks','var')
     totspks=length(tt);
     save twv tt wvt totspks
 end;
%%
if exist('records_to_get')==0
    %then output only t
    t=tt;
    wv=[];
else

    rg=records_to_get;


    %********************************************************************************************
    %now sort out records_to_get,record_units
    %records_to_get = a range of values
    %record_units = a flag taking one of 5 cases
    %   1. timestamp list
    %   2. record number list
    %   3. range of timestamps (2 elements: start and end)
    %   4. range of records (2 elements: start and end)
    %   5. count of spikes (records_to_get = [])


    if record_units==1

        t=[];
        wv=[];
        %find spikes with given timestamps
        for i=1:length(rg)
            f=find(tt==rg(i));
            t=[t; tt(f)];
            wv=[wv; wvt(f,:,:)];
        end;


        %********************************************

    elseif record_units==2
        %find spikes by index
        
        x=find(rg>max(tt));
        if ~isempty(x)
        sprintf(num2str(max(rg)));
        sprintf(num2str(x(1)));
        end;
        t=tt(rg);
        wv=wvt(rg,:,:);

        %********************************************

    elseif record_units==3
        %find range of spike timestamps
        t=tt(tt==rg(1):tt==rg(2));
        wv=wvt(tt==rg(1):tt==rg(2),:,:);


        %********************************************[

    elseif record_units==4
        %find range of spike indices


        t=tt(rg(1):rg(2));
        wv=wvt(rg(1):rg(2),:,:);
        %********************************************
    elseif record_units==5
        %output is total spike number
        t=totspks;
        wv=[];


    end;
end;

%for MClust waveforms.
wv=wv*10000;

% size(t)
% size(wv)