% run the theta instantaneous frequency extraction for diff sessions

%% set dir and run the prelim data check to choose analysis channel

dir='C:\Data\M09-2015-07-28_remapping1';
channels=17:32;

prelim_data_check(dir,channels);
%% set channel
channel='17';

%% Load LFP
cd(dir);
cfg=[];
cfg.fc = {['CSC' num2str(channel) '.ncs']};
csc = LoadCSC(cfg);
%% run stuffs
[~,all_ivs] = restrict_to_theta(dir,channel);

[smooth_ifrq] = get_ifrq(csc);

%% Restrict the frequency infos and create a special var
% This could be used if I am interested in only looking @ high theta bits


% % Select the theta bits
% ifrq_restrict.theta=restrict(smooth_ifrq,all_ivs.theta);
% % Now select the running bits in the new theta restricted data
% ifrq_restrict.theta=restrict(ifrq_restrict.theta,all_ivs.running);

%% Now restrict by session IVs
ifrq_restrict.rest1=restrict(smooth_ifrq,all_ivs.rest1);
ifrq_restrict.rest1.name='rest1';
ifrq_restrict.trackA_nov=restrict(smooth_ifrq,all_ivs.trackA_nov);
ifrq_restrict.trackA_nov.name='trackA_nov';
ifrq_restrict.rest2=restrict(smooth_ifrq,all_ivs.rest2);
ifrq_restrict.rest2.name='rest2';
ifrq_restrict.trackB_nov=restrict(smooth_ifrq,all_ivs.trackB_nov);
ifrq_restrict.trackB_nov.name='trackB_nov';
ifrq_restrict.rest3=restrict(smooth_ifrq,all_ivs.rest3);
ifrq_restrict.rest3.name='rest3';
ifrq_restrict.trackA_fam=restrict(smooth_ifrq,all_ivs.trackA_fam);
ifrq_restrict.trackA_fam.name='trackA_fam';
ifrq_restrict.rest4=restrict(smooth_ifrq,all_ivs.rest4);
ifrq_restrict.rest4.name='rest4';


%% Get means and stds
[all_sess] = mean_ifrq('all',ifrq_restrict);
all_sess.cfg.SessionID=csc.cfg.SessionID;