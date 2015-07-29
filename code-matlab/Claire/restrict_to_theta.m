function [csc_restricted,evt = restrict_to_theta(dir,channel)
% Remember to  select channel for analysis using PSDs
% Spits out csc_restricted and the evts which can be used to cut into
% sessions
% more info to come later...
% still need to generalise a bit and maybe think about other input args

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
pause;
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

figure;
plot(spd.tvec,spd.data);
pause;
spd_thresh=input('Where should the threshold be?: '); %threshold over which the mouse counts as running
close gcf

if or(~isnumeric(thresh),length(thresh)>1)
    error('Input must be a single number')
end
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

%% TODO Restrict using running and theta ivs

% Select the theta bits
csc_restricted=restrict(csc,theta_iv);
% Now select the running bits
csc_restricted=restrict(csc_restricted,run_spd_iv);

figure;
subplot(3,1,1)
PlotTSDfromIV([],theta_iv,csc);
title('Detected theta in raw LFP')
ax(1)=gca;
subplot(3,1,2)
PlotTSDfromIV([],run_spd_iv,spd);
title('Detected running times in speed')
ax(2)=gca;
subplot(3,1,3)
plot(csc_restricted.tvec,csc_restricted.data);
title('restricted lfp')

linkaxes(ax,'x')

%% TODO cut into trials

cfg = [];
cfg.eventList = {'Starting Recording','Stopping Recording'};
evt = LoadEvents(cfg);



end

