function varargout = daq6(varargin)
%
%This function needs matlab 32-bit and matlab Data Acquisition Toolbox.
%It assumes 32-bit windows.
%
%This function needs a National Instruments data acquisition card and Nidaqmx to run:
%
%NI Card: PCI-6251
%
% DAQ6 M-file for daq6.fig
%      DAQ6, by itself, creates a new DAQ6 or raises the existing
%      singleton*.
%
%      H = DAQ6 returns the handle to a new DAQ6 or the handle to
%      the existing singleton*.
%
%      DAQ6('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DAQ6.M with the given input arguments.
%
%      DAQ6('Property','Value',...) creates a new DAQ6 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before daq6_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to daq6_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help daq6

% Last Modified by Teresa A. Nick - GUIDE v2.5 01-Dec-2010 16:13:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @daq6_OpeningFcn, ...
    'gui_OutputFcn',  @daq6_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before daq6 is made visible.
function daq6_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to daq6 (see VARARGIN)

% Choose default command line output for daq6
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes daq6 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

format short g
format compact
clc


%% --- Outputs from this function are returned to the command line.
function varargout = daq6_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ReferenceChannel_Callback(hObject, eventdata, handles)
% hObject    handle to ReferenceChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ReferenceChannel as text
%        str2double(get(hObject,'String')) returns contents of ReferenceChannel as a double


% --- Executes during object creation, after setting all properties.
function ReferenceChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ReferenceChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% --- Executes on button press in StartAcquisition.
function StartAcquisition_Callback(hObject, eventdata, handles)
% hObject    handle to StartAcquisition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


set(handles.Chatt,'String','Hello there.')

%set sampling rate
fs=22050;

%initalize
alreadystopped=0;


%check whether button on or off
stopstart=get(handles.StartAcquisition,'Background');
stopp=stopstart(1);%red will have stop==1

if stopp==0%if it's green, change it to red and start playback
    %change button to red
    set(handles.StartAcquisition,'String','StopAcquisition')
    set(handles.StartAcquisition,'Background',[1 0 0])
    if ~exist('c:/TetrodeData')
        mkdir('c:/TetrodeData');
    end;
    cd c:/TetrodeData




    %start info file
    nw=now;
    DaqStart=nw;
    nw=num2str(nw);

    %remove decimal place
    f=find(nw=='.');
    nw(f)=[];

    infofile=['c:\TetrodeData\info' nw];
    set(handles.InfoFile,'String',infofile);
    Reference=NaN;
    save(infofile,'DaqStart','Reference');

    % set up analog inputs
    ain=analoginput('nidaq','Dev1');

    set(ain,'TriggerType','Manual')

    set(ain,'SampleRate',fs);
    set(ain,'LoggingMode','Disk')
    set(ain,'LogFileName',['data' nw '.txt'])

    niinfo=daqhwinfo(ain);
    niinfo.InputRanges;

    set(ain,'InputType','SingleEnded')

    soundchannel=0;
    %first channel is sound
    snd=addchannel(ain,soundchannel);

    tets=addchannel(ain,1:15);

    ain.Channel.InputRange=[-1 1];

    %collect data
    set(ain,'SamplesPerTrigger',120*60*fs);%acquire for 120 min max
    set(ain,'TriggerDelayUnits','Samples')


    start(ain)
    trigger(ain)
    %[data,time]=getdata(ain);
    lenrec = get(ain,'SamplesPerTrigger');
    for i=1:floor(lenrec/20)
        if alreadystopped==0
            pause(10)
            %
            %check if button press every 10 sec
            %check whether button on or off
            stopstart=get(handles.StartAcquisition,'Background');
            stopp=stopstart(1);%red will have stop==1

            if stopp==0
                DaqStop=now;
                save(infofile,'DaqStop','soundchannel','-append');
                stop(ain)
                alreadystopped=1;
                set(handles.Chatt,'String','I''ve stopped acquiring data.')
                delete(ain)
                clear ain
                pause(10)
                set(handles.Chatt,'String','Chat Box')

            end;
        end;
    end;

    if alreadystopped==0
        delete(ain)
        clear ain
    end;

else
    %change button to green
    set(handles.StartAcquisition,'String','StartAcquisition')
    set(handles.StartAcquisition,'Background',[0 1 0])
    set(handles.Chatt,'String','Give me up to 20 seconds to let this trial finish.')
end;

%% --- Executes on button press in StartPlayback.
function StartPlayback_Callback(hObject, eventdata, handles)
% hObject    handle to StartPlayback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%check to see if reference channel assigned
set(handles.TrialNumber,'String','15');
alreadystopped=0;

%define params

triallen=str2num(get(handles.TrialDuration,'String'));%sec
if triallen<8%changed from 10 to 8 TAN 5/14/2010
    set(handles.Chatt,'String','Trial duration must be at least 8.');
    triallen=8;
    set(handles.TrialDuration,'String','8');
end;
pre=4;%pre time 4 sec

trialnum=str2num(get(handles.TrialNumber,'String'));

%check whether button on or off
stopstart=get(handles.StartPlayback,'Background');
stopp=stopstart(1);%red will have stop==1

if stopp==0%if it's green, change it to red and start playback
    %change button to red
    set(handles.StartPlayback,'String','StopPlayback')
    set(handles.StartPlayback,'Background',[1 0 0])

    %save start time in info file
    infofile=get(handles.InfoFile,'String');
    load(infofile);
    if exist('StimStart','var')==0
        StimStart{1}=now;
        PRE{1}=pre;
        TRIALLEN{1}=triallen;
        save(infofile,'-append','StimStart','PRE','TRIALLEN');
    else
        PRE{length(PRE)+1}=pre;
        TRIALLEN{length(TRIALLEN)+1}=triallen;
        StimStart{length(StimStart)+1}=now;
        save(infofile,'-append','StimStart','PRE','TRIALLEN');
    end;
    stimordercnt=length(StimStart);
    stoplen=length(StimStart);
%     chattt='I think this is playback session %d\n.',length(StimStart)
%         set(handles.Chatt,'String','I think this is playback session %d\n.',length(StimStart))

    % set up analog output
    ao=analogoutput('nidaq','Dev1');
    %outinfo=daqhwinfo(ao)
    aoch1=addchannel(ao,0);

    set(ao,'SampleRate',44100);
    set(ao,'TriggerType', 'Manual');
    ActualRate=get(ao,'SampleRate');

    %get files for playback
    cd c:\playback
    dfiles=dir;
    files=[];
    for i=1:length(dfiles)
        f=findstr(dfiles(i).name,'wav');
        if ~isempty(f)
            files=[files i];
        end;
    end;
    files=dfiles(files);
    origfiles=files;

    %check to see if info file already contained StimOrder
    if exist('StimOrder','var')==0
        StimOrder{1}=[];
    else
        StimOrder{stimordercnt}=[];
    end;

    for j=1:trialnum
        if j==1 || stopp==1
            set(handles.Numberoftrials,'String',num2str(j))
            %randomize
            [r] = randintwithoutreplace(1,length(origfiles),[1 length(origfiles)]);
            files=origfiles(r);

            for i=1:length(files)
                %check whether button on or off
                stopstart=get(handles.StartPlayback,'Background');
                stopp=stopstart(1);%red will have stop==1

                if stopp==1
                    file=wavread(files(i).name);

                    %keep track of playback stimulus order
                    StimOrder{stimordercnt}=strvcat(StimOrder{stimordercnt},files(i).name);
                    save(infofile,'-append','StimOrder');

                    set(handles.Stimulus,'String',files(i).name(1:length(files(i).name)-4))
                    %4-sec pre
                    pause(pre)

                    putdata(ao,file);

                    %start,issue a manual trigger,wait for object to stop running
                    start(ao)
                    trigger(ao)
                    %wait(ao,10);

                    pause(triallen-pre)
                    stop(ao)
                else%stopplayback button has been pressed
                    if alreadystopped==0
                        stop(ao)
                        %clean up ao
                        delete(ao)
                        clear ao
                        alreadystopped=1;
                    end;

                end;
            end;
        end;
    end;%end of trialnum for loop
    if alreadystopped==0
        stop(ao)
        %clean up ao
        delete(ao)
        clear ao
        alreadystopped=1;
        %change button to green
        set(handles.StartPlayback,'String','StartPlayback')
        set(handles.StartPlayback,'Background',[0 1 0])
    end;
else
    %change button to green
    set(handles.StartPlayback,'String','StartPlayback')
    set(handles.StartPlayback,'Background',[0 1 0])
    %     %give stimulus time to finish
    %     triallen=str2num(get(handles.TrialDuration,'String'));%sec
    %     if triallen<10
    %         triallen=10;
    %         set(handles.TrialDuration,'String','10');
    %     end;
    %    set(handles.Chatt,'String',['Give me ' num2str(triallen) 'seconds to wrap this up.']);
    %     pause(triallen)
end;%end of if green/red statement

    %save stop time in info file
    infofile=get(handles.InfoFile,'String');
    load(infofile)
    if exist('StimStop','var')==0
        StimStop{1}=now;
        NumTrials{1}=handles.Numberoftrials;
        save(infofile,'-append','StimStop','NumTrials');
    else
        StimStop{stoplen}=now;
        NumTrials{length(NumTrials)+1}=handles.Numberoftrials;
        save(infofile,'-append','StimStop','NumTrials');
    end;





% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in TestPlayback.
function TestPlayback_Callback(hObject, eventdata, handles)
% hObject    handle to TestPlayback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% set up analog output

ao=analogoutput('nidaq','Dev1');

outinfo=daqhwinfo(ao);

aoch1=addchannel(ao,0);


duration = 0.5;
x=1:(duration*44100);
set(ao,'SampleRate',44100);
set(ao,'TriggerType', 'Manual')
ActualRate=get(ao,'SampleRate');
len=ActualRate*duration;
data=sin(x+2*pi);
min(data)
max(data)
figure
%plot(data,'k.')
specgram(data,[],44100)
putdata(ao,data');

%start,issue a manual trigger,wait for object to stop running
start(ao)
trigger(ao)
wait(ao,2);

delete(ao)
clear ao









function TrialDuration_Callback(hObject, eventdata, handles)
% hObject    handle to TrialDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TrialDuration as text
%        str2double(get(hObject,'String')) returns contents of TrialDuration as a double


% --- Executes during object creation, after setting all properties.
function TrialDuration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrialDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function TrialNumber_Callback(hObject, eventdata, handles)
% hObject    handle to TrialNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TrialNumber as text
%        str2double(get(hObject,'String')) returns contents of TrialNumber as a double


% --- Executes during object creation, after setting all properties.
function TrialNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrialNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in StartBatch.
function StartBatch_Callback(hObject, eventdata, handles)
% hObject    handle to StartBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%set number of trials
set(handles.TrialNumber,'String','35');
alreadystopped=0;

%define params

triallen=str2num(get(handles.TrialDuration,'String'));%sec
if triallen<8%changed from 10 to 8 TAN 5/14/2010
    set(handles.Chatt,'String','Trial duration must be at least 8.');
    triallen=8;
    set(handles.TrialDuration,'String','8');
end;
pre=4;%pre time 4 sec

trialnum=str2num(get(handles.TrialNumber,'String'));

%check whether button on or off
stopstart=get(handles.StartBatch,'Background');%changed for StartBatch
stopp=stopstart(1);%red will have stop==1

if stopp==0%if it's green, change it to red and start playback
    %change button to red
    set(handles.StartBatch,'String','StopBatch')%changed for StartBatch
    set(handles.StartBatch,'Background',[1 0 0])%changed for StartBatch

    %save start time in info file
    infofile=get(handles.InfoFile,'String');
    load(infofile);
    if exist('StimStart','var')==0
        StimStart{1}=now;
        PRE{1}=pre;
        TRIALLEN{1}=triallen;
        save(infofile,'-append','StimStart','PRE','TRIALLEN');
    else
        PRE{length(PRE)+1}=pre;
        TRIALLEN{length(TRIALLEN)+1}=triallen;
        StimStart{length(StimStart)+1}=now;
        save(infofile,'-append','StimStart','PRE','TRIALLEN');
    end;
    stimordercnt=length(StimStart);
    stoplen=length(StimStart);
%     chattt='I think this is playback session %d\n.',length(StimStart)
%         set(handles.Chatt,'String','I think this is playback session %d\n.',length(StimStart))

    % set up analog output
    ao=analogoutput('nidaq','Dev1');
    %outinfo=daqhwinfo(ao)
    aoch1=addchannel(ao,0);

    set(ao,'SampleRate',44100);
    set(ao,'TriggerType', 'Manual');
    ActualRate=get(ao,'SampleRate');

    %get files for playback
    cd c:\playback
    dfiles=dir;
    files=[];
    for i=1:length(dfiles)
        f=findstr(dfiles(i).name,'wav');
        if ~isempty(f)
            files=[files i];
        end;
    end;
    files=dfiles(files);
    origfiles=files;

    %check to see if info file already contained StimOrder
    if exist('StimOrder','var')==0
        StimOrder{1}=[];
    else
        StimOrder{stimordercnt}=[];
    end;

    %%%%%%%%%%%%StartBatch different from Start Playback Interleaved starting here:
     %randomize
        [r] = randintwithoutreplace(1,length(origfiles),[1 length(origfiles)]);
        files=origfiles(r);
    for i=1:length(files)
     
        for j=1:trialnum
                if i~=1 && j==1
                       %wait 15 seconds between playback types
                       set(handles.Chatt,'String','Waiting 15 sec between batch playbacks.');
                       pause(15)
                       set(handles.Chatt,'String','Beauty is Truth and Truth, Beauty');
                end;
                set(handles.Numberoftrials,'String',num2str(j))
                    %check whether button on or off
                    stopstart=get(handles.StartBatch,'Background');
                    stopp=stopstart(1);%red will have stop==1
                    if stopp==1
                        
                        file=wavread(files(i).name);

                        %keep track of playback stimulus order
                        StimOrder{stimordercnt}=strvcat(StimOrder{stimordercnt},files(i).name);
                        save(infofile,'-append','StimOrder');

                        set(handles.Stimulus,'String',files(i).name(1:length(files(i).name)-4))
                        %4-sec pre
                        pause(pre)

                        putdata(ao,file);

                        %start,issue a manual trigger,wait for object to stop running
                        start(ao)
                        trigger(ao)
                        %wait(ao,10);

                        pause(triallen-pre)
                        stop(ao)
                    else%stopplayback button has been pressed
                        if alreadystopped==0
                            stop(ao)
                            %clean up ao
                            delete(ao)
                            clear ao
                            alreadystopped=1;
                        end;

                    end;
        end;%end of trialnum for loop
    end;%end files for loop
    if alreadystopped==0
        stop(ao)
        %clean up ao
        delete(ao)
        clear ao
        alreadystopped=1;
        %change button to green
        set(handles.StartBatch,'String','StartBatch')
        set(handles.StartBatch,'Background',[0 1 0])
    end;
else
    %change button to green
    set(handles.StartBatch,'String','StartBatch')
    set(handles.StartBatch,'Background',[0 1 0])
    %     %give stimulus time to finish
    %     triallen=str2num(get(handles.TrialDuration,'String'));%sec
    %     if triallen<10
    %         triallen=10;
    %         set(handles.TrialDuration,'String','10');
    %     end;
    %    set(handles.Chatt,'String',['Give me ' num2str(triallen) 'seconds to wrap this up.']);
    %     pause(triallen)
end;%end of if green/red statement

    %save stop time in info file
    infofile=get(handles.InfoFile,'String');
    load(infofile)
    if exist('StimStop','var')==0
        StimStop{1}=now;
        NumTrials{1}=handles.Numberoftrials;
        save(infofile,'-append','StimStop','NumTrials');
    else
        StimStop{stoplen}=now;
        NumTrials{length(NumTrials)+1}=handles.Numberoftrials;
        save(infofile,'-append','StimStop','NumTrials');
    end;




function aStimNum_Callback(hObject, eventdata, handles)
% hObject    handle to aStimNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aStimNum as text
%        str2double(get(hObject,'String')) returns contents of aStimNum as a double


% --- Executes during object creation, after setting all properties.
function aStimNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aStimNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bStimNum_Callback(hObject, eventdata, handles)
% hObject    handle to bStimNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bStimNum as text
%        str2double(get(hObject,'String')) returns contents of bStimNum as a double


% --- Executes during object creation, after setting all properties.
function bStimNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bStimNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Startaba.
function Startaba_Callback(hObject, eventdata, handles)
% hObject    handle to Startaba (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

anum=str2num(get(handles.aStimNum,'String'));
bnum=str2num(get(handles.bStimNum,'String'));

alreadystopped=0;

%define params

triallen=str2num(get(handles.TrialDuration,'String'));%sec
if triallen<8%changed from 10 to 8 TAN 5/14/2010
    set(handles.Chatt,'String','Trial duration must be at least 8.');
    triallen=8;
    set(handles.TrialDuration,'String','8');
end;
pre=4;%pre time 4 sec

trialnum=str2num(get(handles.TrialNumber,'String'));

%check whether button on or off
stopstart=get(handles.Startaba,'Background');%changed for StartBatch
stopp=stopstart(1);%red will have stop==1

if stopp==0%if it's green, change it to red and start playback
    %change button to red
    set(handles.Startaba,'String','Stopaba')%changed for StartBatch
    set(handles.Startaba,'Background',[1 0 0])%changed for StartBatch

    %save start time in info file
    infofile=get(handles.InfoFile,'String');
    load(infofile);
    if exist('StimStart','var')==0
        StimStart{1}=now;
        PRE{1}=pre;
        TRIALLEN{1}=triallen;
        save(infofile,'-append','StimStart','PRE','TRIALLEN');
    else
        PRE{length(PRE)+1}=pre;
        TRIALLEN{length(TRIALLEN)+1}=triallen;
        StimStart{length(StimStart)+1}=now;
        save(infofile,'-append','StimStart','PRE','TRIALLEN');
    end;
    stimordercnt=length(StimStart);
    stoplen=length(StimStart);
%     chattt='I think this is playback session %d\n.',length(StimStart)
%         set(handles.Chatt,'String','I think this is playback session %d\n.',length(StimStart))

    % set up analog output
    ao=analogoutput('nidaq','Dev1');
    %outinfo=daqhwinfo(ao)
    aoch1=addchannel(ao,0);

    set(ao,'SampleRate',44100);
    set(ao,'TriggerType', 'Manual');
    ActualRate=get(ao,'SampleRate');

    %get files for playback
    cd c:\playback
    dfiles=dir;
    files=[];
    for i=1:length(dfiles)
        f=findstr(dfiles(i).name,'wav');
        g=findstr(dfiles(i).name,'a');
        if ~isempty(f) && ~isempty(g) && g(1)==1
            afile=i;
        elseif ~isempty(f)
            files=[files i];
        end;
    end;
    afile=dfiles(afile);
    afile=afile(1).name;
    files=dfiles(files);
    origfiles=files;
    bfile=files(1).name;

    %check to see if info file already contained StimOrder
    if exist('StimOrder','var')==0
        StimOrder{1}=[];
    else
        StimOrder{stimordercnt}=[];
    end;

    %%%%%%%%%%%%Startaba unique
    
    %first playback a stimulus
    set(handles.Chatt,'String','First ''a'' stimulus.');
    file=wavread(afile);
    for j=1:anum
        set(handles.Numberoftrials,'String',num2str(j))
                    %check whether button on or off
                    stopstart=get(handles.Startaba,'Background');
                    stopp=stopstart(1);%red will have stop==1
                    if stopp==1                     
                        %keep track of playback stimulus order
                        StimOrder{stimordercnt}=strvcat(StimOrder{stimordercnt},afile);
                        save(infofile,'-append','StimOrder');

                        set(handles.Stimulus,'String',afile(1:length(afile)-4))
                        %4-sec pre
                        pause(pre)

                        putdata(ao,file);

                        %start,issue a manual trigger,wait for object to stop running
                        start(ao)
                        trigger(ao)
                        %wait(ao,10);

                        pause(triallen-pre)
                        stop(ao)
                    else%stopplayback button has been pressed
                        if alreadystopped==0
                            stop(ao)
                            %clean up ao
                            delete(ao)
                            clear ao
                            alreadystopped=1;
                        end;

                    end;
                    
    end;%end of first anum for loop
                   
     %playback 'b' stimulus
     set(handles.Chatt,'String','''b'' stimulus.');
      file=wavread(bfile);
    for j=1:bnum
        set(handles.Numberoftrials,'String',num2str(j))
                    %check whether button on or off
                    stopstart=get(handles.Startaba,'Background');
                    stopp=stopstart(1);%red will have stop==1
                    if stopp==1
                        %keep track of playback stimulus order
                        StimOrder{stimordercnt}=strvcat(StimOrder{stimordercnt},bfile);
                        save(infofile,'-append','StimOrder');

                        set(handles.Stimulus,'String',bfile(1:length(bfile)-4))
                        %4-sec pre
                        pause(pre)

                        putdata(ao,file);

                        %start,issue a manual trigger,wait for object to stop running
                        start(ao)
                        trigger(ao)
                        %wait(ao,10);

                        pause(triallen-pre)
                        stop(ao)
                    else%stopplayback button has been pressed
                        if alreadystopped==0
                            stop(ao)
                            %clean up ao
                            delete(ao)
                            clear ao
                            alreadystopped=1;
                        end;

                    end;
                   
    end;%end of bnum for loop
            
      %second playback 'a' stimulus
      set(handles.Chatt,'String','Second ''a'' stimulus.');
      file=wavread(afile);
    for j=1:anum
        set(handles.Numberoftrials,'String',num2str(j))
                    %check whether button on or off
                    stopstart=get(handles.Startaba,'Background');
                    stopp=stopstart(1);%red will have stop==1
                    if stopp==1
                        %keep track of playback stimulus order
                        StimOrder{stimordercnt}=strvcat(StimOrder{stimordercnt},afile);
                        save(infofile,'-append','StimOrder');

                        set(handles.Stimulus,'String',afile(1:length(afile)-4))
                        %4-sec pre
                        pause(pre)

                        putdata(ao,file);

                        %start,issue a manual trigger,wait for object to stop running
                        start(ao)
                        trigger(ao)
                        %wait(ao,10);

                        pause(triallen-pre)
                        stop(ao)
                    else%stopplayback button has been pressed
                        if alreadystopped==0
                            stop(ao)
                            %clean up ao
                            delete(ao)
                            clear ao
                            alreadystopped=1;
                        end;

                    end;
                   
    end;%end of second anum for loop
  
    if alreadystopped==0
                        stop(ao)
                        %clean up ao
                        delete(ao)
                        clear ao
                        alreadystopped=1;
                        %change button to green
                        set(handles.Startaba,'String','Startaba')
                        set(handles.Startaba,'Background',[0 1 0])
     end;

    set(handles.Chatt,'String','Wrapping up aba');
    %%%%%% same 'ol
else
    %change button to green
    set(handles.Startaba,'String','Startaba')
    set(handles.Startaba,'Background',[0 1 0])
    %     %give stimulus time to finish
    %     triallen=str2num(get(handles.TrialDuration,'String'));%sec
    %     if triallen<10
    %         triallen=10;
    %         set(handles.TrialDuration,'String','10');
    %     end;
    %    set(handles.Chatt,'String',['Give me ' num2str(triallen) 'seconds to wrap this up.']);
    %     pause(triallen)
end;%end of if green/red statement

    %save stop time in info file
    infofile=get(handles.InfoFile,'String');
    load(infofile)
    if exist('StimStop','var')==0
        StimStop{1}=now;
        NumTrials{1}=handles.Numberoftrials;
        save(infofile,'-append','StimStop','NumTrials');
    else
        StimStop{stoplen}=now;
        NumTrials{length(NumTrials)+1}=handles.Numberoftrials;
        save(infofile,'-append','StimStop','NumTrials');
    end;



% --- Executes during object creation, after setting all properties.
function StartBatch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StartBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


