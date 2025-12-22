function [A_fit, a_fit, B_fit] = CorrelationTime_Fit(data, starting_point,cutoff_time)
% CorrelationTime_Fit 对输入信号 data 计算自相关函数，并用指数衰减函数拟合
%
%   [A_fit, a_fit, B_fit] = CorrelationTime_Fit(data, dt, fontsize)
%
% 输入参数：
%   data     - 输入的时域数据向量
%   dt       - 采样时间间隔，默认 1e-5 s
%   fontsize - 图形中字体大小，默认 12
%
% 输出参数：
%   A_fit    - 拟合参数 A
%   a_fit    - 拟合参数 a（相关时间 τ_c = 1/a_fit）
%   B_fit    - 拟合参数 B

    % 设置默认参数

    data = data(starting_point:end);
    n = length(data);
    data_mean = mean(data);
    dt = 1e-5;

    % 计算自相关函数（full 形式）
    acf_full = xcorr(data - data_mean, data - data_mean);
    
    % 取正时间部分，零滞后位于索引 n
    % Python 中用: acf = acf[len(acf)//2 : len(acf)//2+int(0.125/2/np.pi/dt)]
    M = floor(cutoff_time/dt); % 计算取样点数
    if n + M - 1 > length(acf_full)
        M = length(acf_full) - n + 1; % 若数据不足，则取所有正滞后部分
    end
    acf = acf_full(n : n+M-1);
    acf = acf(2:end);
    
    % 归一化（零滞后处为1）
    acf = acf / acf(1);
    
    % 生成时间轴 tau 对应正滞后，并转换为列向量
    tau = (0:length(acf)-1) * dt;
    tau = tau(:);
    acf = acf(:);
    
    % 定义指数衰减模型函数: A * exp(-a*t) + B
    exp_decay = @(t, A, a, B) A .* exp(-a .* t) + B;
    
    % 初始猜测参数 [A, a, B]
    p0 = [1, 0, 0];
    
    % 定义模型函数用于 lsqcurvefit
    modelFun = @(p, t) exp_decay(t, p(1), p(2), p(3));
    
    % 设置拟合选项
    options = optimset('Display','off');
    
    % 执行非线性拟合
    p_fit = lsqcurvefit(modelFun, p0, tau, acf, [], [], options);
    
    % 提取拟合参数
    A_fit = p_fit(1);
    a_fit = p_fit(2);
    B_fit = p_fit(3);
    tau_c_fit = 1 / a_fit;
    
    % 计算拟合曲线
    acf_fit = exp_decay(tau, A_fit, a_fit, B_fit);
    
    % 绘图
    figure('Position', [100, 100, 600, 400]);
    plot(tau, acf, 'b', 'LineWidth', 1.5); hold on;
    plot(tau, acf_fit, 'r--', 'LineWidth', 1.5);
    xlabel('Time Lag (s)', 'FontSize', 12);
    ylabel('Autocorrelation', 'FontSize', 12);
    legend('Autocorrelation', sprintf('Fit: A*exp(-a*t)+B\n\\tau_c = %.6fs', tau_c_fit), 'Location', 'best');
    title('Autocorrelation Function & Exponential Fit', 'FontSize', 12);
    grid on;
    hold off;
end
