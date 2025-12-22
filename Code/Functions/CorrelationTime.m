function tau_1e = CorrelationTime(data, cutoff_time)
    % 默认参数
    if nargin < 2
        cutoff_time = 0.125;
    end

    dt = 0.00001;
    n = length(data);

    % 计算自相关函数（ACF）
    data_mean = mean(data);
    acf = xcorr(data - data_mean, 'unbiased');  % 计算 ACF
    acf = acf(n:end);  % 取正时间部分
    
    % 只取前 int(0.125/2/pi/dt) 个点（相当于 Python 代码的索引）
    max_lag = round(cutoff_time/dt); 
    acf = acf(1:max_lag);

    % 归一化
    acf = acf / acf(1);

    % 计算 1/e 阈值
    threshold = (1 / exp(1)) * acf(2);  
    tau = (0:length(acf)-1) * dt;

    % 找到 ACF 首次小于 1/e 的时间点
    idx = find(acf < threshold, 1, 'first');
    if isempty(idx)
        tau_1e = NaN;  % 如果没有找到，返回 NaN
    else
        tau_1e = tau(idx);
    end

    % 绘图
    figure;
    plot(tau, acf, 'b', 'LineWidth', 1.5); hold on;
    yline(threshold, 'g--', 'LineWidth', 1.2); % 1/e 水平线
    xline(tau_1e, 'r--', 'LineWidth', 1.2); % 相关时间竖线
    text(tau_1e, 0.2, sprintf('\\tau_c = %.6f s', tau_1e), 'Color', 'r', 'FontSize', 12);

    xlabel('Time Lag (s)', 'FontSize', 12);
    ylabel('Autocorrelation', 'FontSize', 12);
    title('Autocorrelation Function & Correlation Time (1/e)', 'FontSize', 12);
    legend('Autocorrelation', '1/e Level', 'Correlation Time');
    grid on;
    hold off;
end
