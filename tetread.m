function varargout = tetread(varargin)
% TETREAD M-file for tetread.fig
%      TETREAD, by itself, creates a new TETREAD or raises the existing
%      singleton*.
%
%      H = TETREAD returns the handle to a new TETREAD or the handle to
%      the existing singleton*.
%
%      TETREAD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TETREAD.M with the given input arguments.
%
%      TETREAD('Property','Value',...) creates a new TETREAD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before tetread_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to tetread_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help tetread

% Last Modified by GUIDE v2.5 13-Aug-2007 18:11:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @tetread_OpeningFcn, ...
                   'gui_OutputFcn',  @tetread_OutputFcn, ...
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




% --- Executes just before tetread is made visible.
function tetread_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to tetread (see VARARGIN)

% Choose default command line output for tetread
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes tetread wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%%

%cd c:/TetrodeData/092707

%sampling rate from daq5
    set(handles.fs,'Value',22050);


%initialize channels
    set(handles.chs,'Value',[0 6 3 1 2]);


%initialize directory listbox
dfiles=dir;
files=[];

for i=1:length(dfiles)
    if findstr(dfiles(i).name,'txt')
        files=strvcat(files,dfiles(i).name);
    end;
end;

handles.filenames=files;

set(handles.Directory,'String',handles.filenames,'Value',1)



% --- Outputs from this function are returned to the command line.
function varargout = tetread_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in plot1.
function plot1_Callback(hObject, eventdata, handles)
% hObject    handle to plot1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot1

    set(handles.chs,'Value',[0 6 3 1 2]);


% --- Executes on button press in plot2.
function plot2_Callback(hObject, eventdata, handles)
% hObject    handle to plot2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot2

    set(handles.chs,'Value',[0 5 4 7 8]);


% --- Executes on button press in plot3.
function plot3_Callback(hObject, eventdata, handles)
% hObject    handle to plot3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot3

    set(handles.chs,'Value',[0 9 10 13 12]);



% --- Executes on button press in plot4.
function plot4_Callback(hObject, eventdata, handles)
% hObject    handle to plot4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot4

set(handles.chs,'Value',[0 15 14 11]);  


sprintf('One of the channels from the 4th tetrode was discarded due to bandwidth limitations (16 chs).')


% --- Executes on button press in plotexecute.
function plotexecute_Callback(hObject, eventdata, handles)
% hObject    handle to plotexecute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plotexecute

file_index = get(handles.Directory,'Value');
filenames=get(handles.Directory,'String');
filename=filenames(file_index,:);
%get trial duration in seconds
filename=deblank(filename);
infofilename=['info' filename(5:length(filename)-4)]%this is a mat file
load(infofilename)
dif=datevec(DaqStop)-datevec(DaqStart);
trialdur=dif(4)*60*60 + dif(5)*60 + dif(6);
set(handles.chat,'String',['The trial duration is ' num2str(trialdur) '.']);

%get channels,plotduration and sampling rate
        c=get(handles.chs,'Value');
        %add 1 to channels because AM amp is 0-15 and NI is 1-16
        c=c+1;
        sr=get(handles.fs,'Value');
        plotdur=get(handles.plotlen,'String');
        plotdur=str2num(plotdur);

%get start time
    start=get(handles.Plot1Frame,'String');
    start=str2num(start);



if get(handles.PlotAll,'Value') == 1
   
    for i=1:floor(trialdur/plotdur)
        g=get(handles.StopToggle,'Value');
        figure(1)
        clf
        if g==0
        beg=(i-1)*plotdur;
        ed=i*plotdur;
        if beg==0
            dat=daqread(filename,'Channels',c,'Samples',[1 round(ed*sr)]);
        else
            dat=daqread(filename,'Channels',c,'Samples',[round(beg*sr)+1 round(ed*sr)]);
        end;
        subplot(length(c),1,1)
        specgram(dat(:,1),[],sr)
        v=axis;
        axis([v(1) v(2) 500 10000])
        for j=1:length(c)-1
        subplot(length(c),1,j+1)
        plot(dat(:,j+1),'k')
        axis tight
        axis off
        end;
        pause(3)
        else
            set(handles.PauseToggle,'Value',0);
        end;
    end;
                set(handles.StopToggle,'Value',0);
                set(handles.plotexecute,'Value',0);
    
elseif get(handles.Plot5Rand,'Value') ==1
    
    numsegs=floor(trialdur/plotdur);
    
    r=randintwithoutreplace(5,[1 numsegs]);
    
    for i=1:length(r)
        g=get(handles.StopToggle,'Value');
        figure(1)
        clf
        if g==0
        beg=(r(i)-1)*plotdur;
        ed=r(i)*plotdur;
        if beg==0
            dat=daqread(filename,'Channels',c,'Samples',[1 round(ed*sr)]);
        else
            dat=daqread(filename,'Channels',c,'Samples',[round(beg*sr)+1 round(ed*sr)]);
        end;
        subplot(length(c),1,1)
        specgram(dat(:,1),[],sr)
        v=axis;
        axis([v(1) v(2) 500 10000])
        for j=1:length(c)-1
        subplot(length(c),1,j+1)
        plot(dat(:,j+1),'k')
        axis tight
        axis off
        end;
        pause(3)
        else
            set(handles.PauseToggle,'Value',0);
        end;
    end;
                set(handles.StopToggle,'Value',0);
                set(handles.plotexecute,'Value',0);
    

elseif get(handles.Plot1Frame,'Value') ==1
    figure(1)
        clf
    beg=get(handles.StartPlot,'String');
    beg=str2num(beg);
    ed=beg+plotdur;
    
            dat=daqread(filename,'Channels',c,'Samples',[round(beg*sr)+1 round(ed*sr)]);
        subplot(length(c),1,1)
        specgram(dat(:,1),[],sr)
        v=axis;
        axis([v(1) v(2) 500 10000])
        for j=1:length(c)-1
        subplot(length(c),1,j+1)
        plot(dat(:,j+1),'k')
        axis tight
        axis off
        end;
            
              set(handles.PauseToggle,'Value',0);
                set(handles.StopToggle,'Value',0);
                set(handles.plotexecute,'Value',0);
    
elseif get(handles.PlotMultFrames,'Value') ==1

    figure(1)
        clf
    beg1=get(handles.StartPlot,'String');
    beg1=str2num(beg1);
    
    
     for i=beg1:floor((trialdur-beg1)/plotdur)
        g=get(handles.StopToggle,'Value');
        figure(1)
        clf
        if g==0
        beg=(i-1)*plotdur;
        ed=i*plotdur;
        if beg==0
            dat=daqread(filename,'Channels',c,'Samples',[1 round(ed*sr)]);
        else
            dat=daqread(filename,'Channels',c,'Samples',[round(beg*sr)+1 round(ed*sr)]);
        end;
        subplot(length(c),1,1)
        specgram(dat(:,1),[],sr)
        v=axis;
        axis([v(1) v(2) 500 10000])
        for j=1:length(c)-1
        subplot(length(c),1,j+1)
        plot(dat(:,j+1),'k')
        axis tight
        axis off
        end;
        pause(3)
        else
            set(handles.PauseToggle,'Value',0);
        end;
    end;
                set(handles.StopToggle,'Value',0);
                set(handles.plotexecute,'Value',0);
end;


 

% --- Executes on button press in PauseToggle.
function PauseToggle_Callback(hObject, eventdata, handles)
% hObject    handle to PauseToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PauseToggle

g=get(handles.PauseToggle,'Value');
if g==1
    pause(20)
    set(handles.PauseToggle,'Value',0);
end;
    
  

% --- Executes on button press in StopToggle.
function StopToggle_Callback(hObject, eventdata, handles)
% hObject    handle to StopToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of StopToggle

    

% --- Executes on button press in PlotAll.
function PlotAll_Callback(hObject, eventdata, handles)
% hObject    handle to PlotAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotAll




% --- Executes on selection change in Directory.
function Directory_Callback(hObject, eventdata, handles)
% hObject    handle to Directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Directory contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Directory



% --- Executes during object creation, after setting all properties.
function Directory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plotlen_Callback(hObject, eventdata, handles)
% hObject    handle to plotlen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plotlen as text
%        str2double(get(hObject,'String')) returns contents of plotlen as a double


% --- Executes during object creation, after setting all properties.
function plotlen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotlen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StartPlot_Callback(hObject, eventdata, handles)
% hObject    handle to StartPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StartPlot as text
%        str2double(get(hObject,'String')) returns contents of StartPlot as a double


% --- Executes during object creation, after setting all properties.
function StartPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StartPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on plotlen and no controls selected.
function plotlen_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to plotlen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


