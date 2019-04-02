clear
clc

load e_orig.mat

stim_dir = fullfile(pwd,'stim');
subj_dir = gdir(stim_dir,'.*');
csv_file = cellstr(char(gfile(subj_dir,'(Run_\d+.csv$)|(Generalization.csv$)')));

for i = 1:length(csv_file)
    
    t = importfile(csv_file{i});
    t(1,:) = []; % reject first line
    
    name = cellstr(t(:,1));
    name_idx = ~cellfun(@isempty,regexp(name,'onset'));
    name = name(name_idx);
    name = regexprep(name,'onset_','');
    
    
    t(:,1) = [];
    t = cell2mat(t(name_idx,:));
    
    names     = cell(0,1);
    onsets    = cell(0,1);
    durations = cell(0,1);
    
    [pathstr, fname, ~] = fileparts(csv_file{i});
    
    ser = e.getSerie([fname '$'],'name');
%     pth = ser.getVolume('^f').path(1,:);
    
%     tok = regexp(pth,'f(\d+)_','tokens');
%     nrVolumes = str2double(tok{1}{1});
    
    cond = 0;
    for n = 1 : length(name)
        
        line = t(n,:);
        nans = isnan(line);
        if sum(nans) == size(t,2)
            continue
        else
            cond = cond+1;
        end
        
        names{cond} = char(name{n});
        
        onsets{cond} = t(n,:);
        onsets{cond} = onsets{cond}(~nans);
        
        durations{cond} = zeros(size(onsets{cond}));
        
    end
    
%     plotSPMnod(names,onsets,durations)
    save(fullfile(pathstr,fname),'names','onsets','durations')
    
end
