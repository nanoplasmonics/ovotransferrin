function [A, fc] = Lorentzian(data, freq_delete, fc_guessing)

    if nargin < 3
        fc_guessing = 10;
    end
    %% 基本参数设置
    dt = 1e-5;           % 采样时间间隔 (秒)
    fs = 1/dt;           % 采样率
    n = length(data);    % 数据长度

    %% 计算 FFT 和 PSD
    X = fft(data);
    half_n = floor(n/2);
    X_half = X(1:half_n);
    data_psd = (1/(n*dt)) * (abs(X_half)).^2;  % PSD (单位 V^2/Hz)

    % 构造频率轴
    freq_resol = fs/n;                 % 频率分辨率
    freq = (0:half_n-1) * freq_resol;    % 频率向量

    % 去除直流分量并仅保留前 10000 个点（若数据足够长）
    start_idx = 2;
    end_idx = min(10000, length(freq));
    freq = freq(start_idx:end_idx);
    data_psd = data_psd(start_idx:end_idx);

    %% 删除低频数据点
    num_delete = floor(freq_delete / freq_resol);
    x_fit = freq(num_delete+1:end);
    y_fit = data_psd(num_delete+1:end);

    % 将 x_fit 和 y_fit 转换为列向量以确保维度匹配
    x_fit = x_fit(:);
    y_fit = y_fit(:);

    %% 定义 Lorentzian 模型
    % Lorentzian 模型: L(x) = A/(x^2 + fc^2)
    lorentzian = @(p, x) p(1) ./ (x.^2 + p(2)^2);

    %% 初始参数猜测
    p0 = [max(y_fit)*(mean(x_fit)^2+1), fc_guessing];  % 让fc从10 Hz开始猜;  % p0 = [A0, fc0]

    %% 拟合
    options = optimset('Display','off');
    lb = [0, 0];  % 下界：A > 0, fc > 0
    p_fit = lsqcurvefit(lorentzian, p0, x_fit, y_fit, lb, [], options);
    A = p_fit(1);
    fc = abs(p_fit(2));  % 确保 fc 为正

    %% 绘制 PSD 和拟合曲线
    figure;
    loglog(freq, data_psd, '.', 'MarkerSize', 2.5, 'Color', 'b'); hold on;
    % 使用列向量 freq(:) 以确保维度匹配
    loglog(freq, lorentzian(p_fit, freq(:)), 'r-', 'LineWidth', 1.5);
    hold off;
    xlabel('Frequency (Hz)', 'FontSize', 12);
    ylabel('Power Spectral Density (V^2/Hz)', 'FontSize', 12);
    title(sprintf('Lorentzian Fit, Corner Frequency: %.2f Hz', fc));
    legend('Original PSD', 'Lorentzian Fit', 'Location', 'Best');
    grid on;
end
