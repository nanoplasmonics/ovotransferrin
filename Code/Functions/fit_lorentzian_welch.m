function [A, fc, S0, f, Pxx, Pfit] = fit_lorentzian_welch(data, fs, fc_guess)
% 更稳健的 Lorentzian 拟合：S(f) = S0 + A./(1+(f./fc).^2)
% 输入：data（列向量），fs 采样率，fc_guess 初值（可选）
    if nargin < 3, fc_guess = 100; end        % 先给个大概的初值
    data = data(:) - mean(data);               % 去均值/漂移
    % --- 1) Welch 平均得到 PSD（V^2/Hz）
    nseg   = round(min( max(2^nextpow2(fs/2), 1024), 16384 ));
    nover  = round(nseg/2);
    nfft   = max(2^nextpow2(nseg), nseg);
    win    = hanning(nseg);
    [Pxx,f] = pwelch(data, win, nover, nfft, fs, 'onesided');  % 列向量
    
    % --- 2) 选取可信频段（按需修改）
    fmin = max(1, 0.1);        % 避开极低频漂移
    fmax = fs/4;               % 留出裕量，不用太接近 Nyquist
    mask = (f>=fmin) & (f<=fmax);
    f = f(mask); Pxx = Pxx(mask);
    
    % --- 3) 初值：用高频端的中位数估 S0
    tail_mask = f > (0.7*max(f));
    S0_0 = median(Pxx(tail_mask));
    A0   = max(Pxx) - S0_0;    % 粗略
    p0   = [max(S0_0,eps), max(A0,eps), max(fc_guess, 1e-3)]; % [S0, A, fc]
    lb   = [0, 0, 0];
    
    % --- 4) 在对数域拟合，鲁棒且避免负值
    model = @(p, x) p(1) + p(2)./(1 + (x./p(3)).^2);
    errfun = @(p) log10(model(p,f)) - log10(Pxx);
    options = optimset('Display','off');
    p = lsqnonlin(errfun, p0, lb, [], options);   % 需要 Optimization Toolbox
    
    S0 = p(1); A = p(2); fc = p(3);
    Pfit = model(p, f);

    % --- 5) 画图（对数坐标）
    figure; loglog(f, Pxx, '.', 'MarkerSize', 3); hold on;
    loglog(f, Pfit, 'r-', 'LineWidth', 1.5);
    grid on; xlabel('Frequency (Hz)'); ylabel('PSD (V^2/Hz)');
    title(sprintf('Lorentzian fit: f_c = %.2f Hz, S_0 = %.3g', fc, S0));
    legend('Welch PSD','Fit','Location','best');
end
