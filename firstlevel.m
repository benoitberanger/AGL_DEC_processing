clear
clc

load e_stim.mat

model_name = 'model_basic';


%% Prepare paths and regexp

par.display=0;
par.run=1;
par.verbose = 2;


%% dirs & files

stim_dir = fullfile(pwd,'stim');
% subj_dir = gdir(stim_dir,'.*');

for subj = 1 : length(e)
    SERIE = e(subj).getSerie('run');
    for ser = 1 : length(SERIE)
        res = strsplit( SERIE(ser).name , '_');
        target = res{end};
        if ~strcmp(target,'Generalization')
            SERIE(ser).addStim(stim_dir,[ 'Run_' target '.mat'],'s')
        else
            SERIE(ser).addStim(stim_dir,'Generalization.mat','s')
        end
    end
    
end

mat_file = e.getStim.toJob(1);
func_dir = e.getSerie('run').toJob;
for i = 1 : length(func_dir)
    func_dir{i}(cellfun(@isempty,func_dir{i})) = [];
    mat_file{i} = char(mat_file{i}(~cellfun(@isempty,mat_file{i})));
end
    
dirStats = e.mkdir(model_name);


%% Specify

par.TR = 1.3;
par.rp = 0;
% par.rp_regex = 'multiple_regressors.txt';
par.file_reg  = 'wS\d'; %le nom generique du volume pour les fonctionel
par.mask_thr = 0.1;
job_first_level_specify(func_dir,dirStats,mat_file,par);


%% Estimate

fspm = e.addModel(model_name,model_name);
save('e_stim','e') % work on this one

job_first_level_estimate(fspm,par);


%% Contrast : definition

for f = 1 : length(fspm)

conditions = {
    'training_rl_incorrect'
    'training_rl_correct'
    'training_feedback_rl_incorrect'
    'training_feedback_rl_correct'
    'training_supervised_incorrect'
    'training_supervised_correct'
    'test_rl_incorrect'
    'test_rl_correct'
    'test_supervised_incorrect'
    'test_supervised_correct'
    'generalization_rl_incorrect'
    'generalization_rl_correct'
    'generalization_supervised_incorrect'
    'generalization_supervised_correct'
    };

vector = cell(size(conditions));
for cond = 1 : length(conditions)
    for run = 1 : size(mat_file{f},1)
        S = load(deblank(mat_file{f}(run,:)));
        res = strcmp(conditions{cond},S.names);
        vector{cond} = [vector{cond} res];
        if par.rp
            vector{cond} = [vector{cond} [0 0 0 0 0 0]];
        end
    end
end

v = cell2struct(vector,conditions); % <===

contrast_T.names = conditions';
contrast_T.names = horzcat(contrast_T.names,...
    {
    'training_rl_incorrect - training_rl_correct'
    'training_rl_correct   - training_rl_incorrect'
    'training_supervised_incorrect - training_supervised_correct'
    'training_supervised_correct   - training_supervised_incorrect'
    }');

contrast_T.values = vector';
contrast_T.values = horzcat(contrast_T.values,...
    {
    v.training_rl_incorrect - v.training_rl_correct
    v.training_rl_correct   - v.training_rl_incorrect
    v.training_supervised_incorrect - v.training_supervised_correct
    v.training_supervised_correct   - v.training_supervised_incorrect
    }');

contrast_T.types = cat(1,repmat({'T'},[1 length(contrast_T.names)]));

contrast_F.names = {
    
'F-all'

}';

contrast_F.values = {
    
cell2mat(vector)

}';


contrast_F.types = cat(1,repmat({'F'},[1 length(contrast_F.names)]));

contrast.names = [contrast_F.names,contrast_T.names];
contrast.values = [contrast_F.values,contrast_T.values];
contrast.types = [contrast_F.types,contrast_T.types];


%% Contrast : write

par.run = 1;
par.report = 0;

par.sessrep = 'none';

par.delete_previous = 1;

job_first_level_contrast(fspm(f),contrast,par);


end


%% Display

% e.getModel(model_name).show
