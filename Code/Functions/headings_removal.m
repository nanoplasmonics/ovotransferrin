function headings_removal(input_folder, output_folder)
    % 创建输出文件夹（如果不存在）
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    % 获取所有 .txt 文件
    files = dir(fullfile(input_folder, '*.txt'));

    for i = 1:length(files)
        % 跳过隐藏文件或系统文件（如 . 或 .. 开头的）
        if startsWith(files(i).name, '.')
            continue;
        end

        % 读取文件内容
        filename = fullfile(input_folder, files(i).name);
        fid = fopen(filename, 'r');
        lines = {};
        while ~feof(fid)
            lines{end+1} = fgetl(fid); %#ok<AGROW>
        end
        fclose(fid);

        % 查找数据开始的行（'AI Channel 0'之后）
        data_start_idx = find(contains(lines, 'AI Channel 0'), 1, 'first') + 1;

        % 如果没找到，也跳过
        if isempty(data_start_idx)
            warning('文件 %s 中未找到 "AI Channel 0"，已跳过。', files(i).name);
            continue;
        end

        % 提取纯数据行
        data_lines = lines(data_start_idx:end);

        % 写入新文件
        output_filename = fullfile(output_folder, files(i).name);
        fid = fopen(output_filename, 'w');
        for j = 1:length(data_lines)
            fprintf(fid, '%s\n', data_lines{j});
        end
        fclose(fid);
    end

    disp('所有文件处理完成！');
end
