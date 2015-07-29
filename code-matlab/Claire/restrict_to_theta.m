function [csc_restricted,evt] = restrict_to_theta(dir,channel)
% Remember to  select channel for analysis using PSDs
%
% Takes the data directory (dir) and the channel you want to analyse
% (channel) as input
%
% Outputs csc_restricted and the 'start recording' and 'stop recording'
% events in an interval format (evt) which can be used to cut into rest,
% track A, track B sessions later 
% 
%
% Theta threshold is set manually by the user as the theta z-score (which
% you threshold to choose the high theta times) is determined by the
% mean theta in a recording, which might be higher or lower depending on
% your mouse (and then you need to lower or raise your threshold
% accordingly)
%
% Movement threshold is set within the fn to 12 but if this doesn't seem
% sensible feel free to change...


%% testing cell
% 
dir='C:\Data\M14-2015-07-27_remapping1';
channel=17;

%% Load LFP
cd(dir);
cfg=[];
cfg.fc = {['CSC' num2str(channel) '.ncs']};
csc = LoadCSC(cfg);

%% Load video
pos=LoadPos([]);

%% Find chunks with only good theta

close all

% filter to theta freqs
cfg=[];
cfg.type = 'cheby1';
cfg.order = 3; % filter order;
cfg.display_filter = 0; % show output of fvtool on filter
cfg.bandtype = 'bandpass'; % 'highpass', 'lowpass'
cfg.R = 0.25; % passband ripple (in dB) for Chebyshev filters only
cfg.f = [7 10]; %filter range to use (in Hz)

% testing please ignore
% Wn = cfg.f ./ (Fs/2);
% [b,a] = cheby1(cfg.order,cfg.R,Wn);
% fvtool(b,a);

csc_filt = FilterLFP(cfg,csc);

% apply hilbert transform and square to get theta power
theta_pwr=LFPpower([],csc_filt);

% Convolve with gaussian
stdev_size=1; % size of sd in seconds
Fs = csc.cfg.hdr{1}.SamplingFrequency;
gauss_window=gausskernel(stdev_size.*5.*Fs,stdev_size.*Fs); % Create Gaussian

% set up conv_theta_pwr to have the same fields as theta_pwr
conv_theta_pwr=theta_pwr;

% change the data bit of conv_theta_pwr
conv_theta_pwr.data=conv(theta_pwr.data,gauss_window,'same');
theta_pwr_z = zscore_tsd(conv_theta_pwr);

% Plot raw LFP and z-scored theta, get threshold as user input
hold on;plot(csc.tvec,rescale(csc.data,3,4)); plot(theta_pwr_z.tvec,theta_pwr_z.data);
legend('raw LFP','z-scored theta power');
msgbox('Look at the LFP and theta power and press any button to continue when you are satisfied')
pause;
close gcf
thresh=input('Where should the threshold be?: ');

if or(~isnumeric(thresh),length(thresh)>1)
    error('Input must be a single number')
end

% Threshold (this automatically z scores too
cfg=[];
cfg.method = 'zscore';
cfg.threshold = thresh;
cfg.dcn =  '>'; % '<', '>'
cfg.merge_thr = 2; % merge events closer than this
cfg.minlen = 1; % minimum interval length

theta_iv=TSDtoIV(cfg,conv_theta_pwr);
% subplot(2,1,1)
% PlotTSDfromIV([],theta_iv,csc);
% ax(1)=gca;
% title('Detected theta in raw LFP')
% subplot(2,1,2); hold on;
% plot(theta_pwr_z.tvec,theta_pwr_z.data);
% plot([theta_pwr_z.tvec(1) theta_pwr_z.tvec(end)],[thresh thresh],'LineWidth',2)
% ax(2)=gca;
% ('Z-scored theta power');
% linkaxes(ax,'x')

%% Find chunks with running

% Get distance travelled between each sample
spd = getLinSpd([],pos);

% plot(spd.tvec,spd.data,'.');hold on;plot(spd_filt.tvec,spd_filt.data,'.');

% Remove weirdly high values
cfg=[];
cfg.method = 'raw';
cfg.threshold = 150;
cfg.dcn =  '<'; % '<', '>'
cfg.merge_thr = 0.01; % merge events closer than this
cfg.minlen = 0.01; % minimum interval length

spd_iv=TSDtoIV(cfg,spd);
spd=restrict(spd,spd_iv);

spd_thresh=12;

% Select only true running (please change the thresholds if you want to..)
cfg=[];
cfg.method = 'raw';
cfg.threshold = spd_thresh;
cfg.dcn =  '>'; % '<', '>'
cfg.merge_thr = 0.3; % merge events closer than this
cfg.minlen = 0.5; % minimum interval length
run_spd_iv=TSDtoIV(cfg,spd);
run_spd=restrict(spd,run_spd_iv);
% 
% figure;
% PlotTSDfromIV([],run_spd_iv,spd);
% title('Detected running times in speed')

%% TODO Find chunks w gamma (maybe?)


%% get session start and end ivs

cfg = [];
cfg.eventList = {'Starting Recording','Stopping Recording'};
evt = LoadEvents(cfg);

%Put in iv format

evt.tstart=evt.t{1}';
evt.tend=evt.t{2}';

%% Restrict using running and theta ivs and plot outcome

% Select the theta bits
csc_restricted=restrict(csc,theta_iv);
% Now select the running bits
csc_restricted=restrict(csc_restricted,run_spd_iv);

csc_for_plot=csc;
csc_for_plot.data=rescale(csc.data,3,5);

figure;
subplot(3,1,1)
PlotTSDfromIV([],theta_iv,csc_for_plot);
title('Detected theta in raw LFP and z-scored theta power')
hold on;
plot(theta_pwr_z.tvec,theta_pwr_z.data,'Color',[ 0.4940    0.1840    0.5560]);
plot([theta_pwr_z.tvec(1) theta_pwr_z.tvec(end)],[thresh thresh],'LineWidth',2,'Color',[0.8500    0.3250    0.0980])
ax(1)=gca;
subplot(3,1,2)
PlotTSDfromIV([],run_spd_iv,spd);
title('Detected running times in speed')
ax(2)=gca;
subplot(3,1,3)
plot(csc_restricted.tvec,csc_restricted.data);
hold on;
% put little arrows to mark session start and end
plot(evt.tstart,0,'>g');
plot(evt.tend,0,'<g');
ax(3)=gca;
title('restricted lfp and session markers')

linkaxes(ax,'x')

end

