function data = load_data(path,file_name)

    data = load(fullfile(path,file_name)).data;
    data = table2array(data);
    
end

