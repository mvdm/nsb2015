function [csc,theta_evts] = restrict_to_theta(dir,channel)
% Remember to  select channel for analysis using PSDs
% Spits out csc and the theta_evts which can then be used as input into
% restrict.
% more info to come later...

%% testing cell

dir='C:\Data\M14-2015-07-27_remapping1';
channel=17;

%% Load LFP
cd(dir);
cfg=[];
cfg.fc = {['CSC' num2str(channel) '.ncs']};
csc = LoadCSC(cfg);

%% Load video
[vid.Timestamps, vid.X, vid.Y, vid.Angles, vid.Targets, vid.Points, vid.Header] = Nlx2MatVT('VT1.nvt', [1 1 1 1 1 1], 1, 1, [] );

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

theta_evts=TSDtoIV(cfg,conv_theta_pwr);
subplot(2,1,1)
PlotTSDfromIV([],theta_evts,csc);
ax(1)=gca;
title('Detected theta events in raw LFP')
subplot(2,1,2); hold on;
plot(theta_pwr_z.tvec,theta_pwr_z.data);
plot([theta_pwr_z.tvec(1) theta_pwr_z.tvec(end)],[thresh thresh],'LineWidth',2)
ax(2)=gca;
('Z-scored theta power');
linkaxes(ax,'x')

%% TODO Find chunks with running
% this isn't ready yet
% keep_idx=(vid.X~=0&vid.Y~=0); % Remove bad points
% 
% % Get distance in x and y
% X_change=diff(vid.X(keep_idx));

%% TODO Find chunks w gamma (maybe?)

%% TODO Restrict

end

