clear
clc

% do_delete(fullfile(pwd,'nii'),0);
% r_copy_suj(gdir('/network/lustre/iss01/cenir/raw/irm/nifti_raw/PRISMA_AGL_DEC','.*'),fullfile(pwd,'nii'));

main_dir = fullfile('/network/lustre/iss01/cenir/analyse/irm/users/benoit.beranger/AGL_DEC','nii');
e = exam(main_dir,'AGL_DEC');
e = e.getExam('2019_03_07');

% Func : RestingStage - multi-echo + multi-band EPI
e.addSerie('Run_1$'         ,'run_1',1)
e.addSerie('Run_2$'         ,'run_2',1)
e.addSerie('Run_3$'         ,'run_3',1)
e.addSerie('Run_4$'         ,'run_4',1)
e.addSerie('Generalization$','run_generalization',1)
e.addVolume('run','^f','f',3)

% Anat : 3DT1 mp2rage - use INV1 for coregistration
e.addSerie('3DT1_1iso_NSel_S192_p2$','anat',1)
e.addVolume('anat','^s_S\d{2}_3DT1_1iso_NSel_S192_p2.nii','s',1)

e.reorderSeries('name');

dir_func = e.getSerie('run') .toJob;
dir_anat = e.getSerie('anat').toJob(0);

% job_meica_afni
par.run = 1;
par.fake = 0;
par.redo = 0;
par.verbose = 2;
par.MNI = 0; % no warp
par.report = 0;


%% Use 1 job per CPU

par.sge=0;
par.nrCPU = 0;
% par.pct = 0;
% if par.pct
%     p = gcp('nocreate'); % If no pool, do not create new one.
%     if isempty(p)
%         parpool;
%     end
% end
% 
% 
% %%
% tic
% job_meica_afni(dir_func, dir_anat, par);
% toc

% return


%%

% e.addSerie('meica','meica',1)
% e.addVolume('anat','anat_ns','ns',1)
e.addVolume('run','^S\d{2}_.*_T1c_medn' ,'T1c_medn' ,1)
e.addVolume('run','^S\d{2}_.*_tsoc_nogs','tsoc_nogs',1)

% [ec, ei] = e.removeIncomplete;
% 
% e.addVolume('anat','anat_ns','ns',1)
% e.addVolume('run','T1c_medn','T1c_medn',1)


%% segment

% Retrocompatibility for SPM:Spatial:Segment options
par.GM        = [1 0 1 0]; % warped_space_Unmodulated(wp*) / warped_space_modulated(mwp*) / native_space(p*) / native_space_dartel_import(rp*)
par.WM        = [1 0 1 0];
par.CSF       = [1 0 1 0];
par.bias      = [1 1 0] ;  % native normalize dartel     [0 1]; % bias field / bias corrected image
par.warp      = [1 1]; % warp field native->template / warp field native<-template

par.jacobian  = 0;         % write jacobian determinant in normalize space
par.doROI     = 0;
par.doSurface = 0;
par.subfolder = 0; % all results in the same subfolder

fanat = e.getSerie('anat').getVolume('^s');
fanat.unzip
par.run=1;
par.sge=0;
job_do_segmentCAT12(fanat,par);


%% Normalize

fy    = e.getSerie('anat').getVolume('^y_s');
ffunc = e.getSerie('run' ).getVolume('^tsoc_nogs');
% ffunc = e.getSerie('run' ).getVolume('^T1c_medn');
ffunc.unzip

par.run=1;
par.sge=0;
par.display=0;
par.auto_add_obj=0;
job_apply_normalize(fy,ffunc, par)
e.addVolume('run','^wS\d','wtsoc_nogs',1)

save e_orig e
save e_stim e

