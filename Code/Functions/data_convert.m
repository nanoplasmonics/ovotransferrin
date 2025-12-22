function data_convert(input_folder, output_folder)
    % Checking is there a real input folder
    if ~isfolder(input_folder)
        error('The input folder does not exist: %s', input_folder);
    end
    
    % Checking is there a existing outpu folder, if not generate one
    if ~isfolder(output_folder)
        mkdir(output_folder);
    end

    txt_files = dir(fullfile(input_folder,'*.txt'));
    disp(txt_files)
    for i = 1:length(txt_files)
        txt_file_path = fullfile(input_folder,txt_files(i).name);
        data = readtable(txt_file_path,'VariableNamingRule', 'preserve');

        [~, filename, ~] = fileparts(txt_files(i).name);
        mat_file_path = fullfile(output_folder,strcat(filename,'.mat'));

        save(mat_file_path,'data');
        fprintf('Coverted: %s -> %s\n', txt_files(i).name, mat_file_path);
    end
end

