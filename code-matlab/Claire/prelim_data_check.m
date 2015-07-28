function [csc,vid] = prelim_data_check(dir)
% Runs a preliminary check on all the data. Takes data directory (dir) as input and spits out a
% figure showing raw LFPs, PSDs and tracking info.
%
% Please unzip video before running and load the nsb/fieldtrip/mclust
% toolboxes
%
% CW July 2015

%% Load LFP
cd(dir);
cfg=[];
csc = cell(32,1);
for channel=17:32
    cfg.fc = {['CSC' num2str(channel) '.ncs']};
    csc{channel} = LoadCSC(cfg);
end

%% Load video - I just changed this to load into a structure (CW)
[vid.Timestamps, vid.X, vid.Y, vid.Angles, vid.Targets, vid.Points, vid.Header] = Nlx2MatVT('VT1.nvt', [1 1 1 1 1 1], 1, 1, [] );



%% Plot video
vidlfpfig=figure('units','normalized','outerposition',[0 0 1 1]);

keep_idx=(vid.X~=0&vid.Y~=0); %keep only points where position not (0,0)
%set(fh,'Color',[0 0 0]);
subplot(1,2,1)
plot(vid.X(keep_idx),vid.Y(keep_idx),'.','Color','k','MarkerSize',1); axis off;
title('Video tracking')

%% Plot LFP and show only a 2s window from the middle of the recording 

% Goes into same fig as video

subplot(1,2,2)
start_idx=length(csc{17}.tvec)/2-2000; % get 1s before halfway through recording...
end_idx=length(csc{17}.tvec)/2+2000; % get 1s after...
hold on;
legendtext=cell(16,1);

% Plot raw LFPs for all channels
for channel=17:32
    plot(csc{channel}.tvec(start_idx-2000:end_idx+2000),csc{channel}.data(start_idx-2000:end_idx+2000)+channel*0.001);
    legendtext{channel-16}=['Ch ' num2str(channel)];
end
legend(legendtext);
xlim([csc{17}.tvec(start_idx) csc{17}.tvec(end_idx)]) % set the xlim to the cut out bit
set(gca,'Ytick',[])
title('Raw LFP')

suptitle(strrep(csc{17}.cfg.SessionID,'_','-'))

%% Create PSDs as separate subplots
psdfig=figure('units','normalized','outerposition',[0 0 1 1]);
Fs=csc{17}.cfg.hdr{1,1}.SamplingFrequency; % this should be the same for everything
wSize = 8092/2; % define window size
hold on;
for channel=17:32
    subplot(4,4,channel-16); %if we end up using ch1-16 change this
    [Pxx,F] = pwelch(csc{channel}.data,hamming(wSize),0,wSize,Fs); % use welch method to get power spectrum thing
    plot(F,10*log10(Pxx));
    ax(channel-16)=gca;
    title(['Ch ' num2str(channel)])
    xlim([0 150]);
end

linkaxes(ax);
suptitle([strrep(csc{17}.cfg.SessionID,'_','-') ' PSD'])
xlabel('Frequency (Hz)'); ylabel('Power (dB)');
end

