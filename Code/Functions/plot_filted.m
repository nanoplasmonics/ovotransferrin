function filtered_data = plot_filted(data, cutoff, sampling_fs, order)
    % 设置默认值
    if nargin < 4
        order = 4; % 默认滤波器阶数
    end
    if nargin < 3
        sampling_fs = 1000000; % 采样频率
    end
    if nargin < 2
        cutoff = 50; % 默认截止频率
    end
    
    % 计算时间轴
    time_step = 1 / sampling_fs;  % 采样时间间隔
    num_data = length(data);
    time_variable = (0:num_data-1) * time_step; % 时间轴

    % 低通滤波
    filtered_data = lowpass_filter(data, cutoff, sampling_fs, order);

    % 绘图
    figure;
    d = plot(time_variable, data, 'Color', [0.7, 0.75, 0.9], 'LineWidth', 1, 'LineStyle', '-'); hold on;
    f = plot(time_variable, filtered_data, 'Color', [0, 0.2, 0.8], 'LineWidth', 1, 'LineStyle', '-');
    xlabel('Time (s)'),
    ylabel('APD Voltage (V)');
    grid off;
    
    % 设置 Y 轴范围
    ymin = min(data) - (max(data) - min(data));
    ymax = max(data) + (max(data) - min(data));
    ylim([ymin, ymax]);

    title('Filtered Signal');
    grid on;
end

function y = lowpass_filter(data, cutoff, fs, order)
    % 设计 Butterworth 低通滤波器
    nyq = 0.5 * fs;  % 计算 Nyquist 频率
    normal_cutoff = cutoff / nyq; % 归一化截止频率
    [b, a] = butter(order, normal_cutoff, 'low'); % 设计滤波器
    y = filtfilt(b, a, data); % 使用 filtfilt 进行零相位滤波
end