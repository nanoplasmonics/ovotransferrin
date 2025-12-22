function [freq,psd] = Lorentzian4(data, freq_delete, fc_guessing)
% Lorentzian 拟合（log10 残差）+ 白噪声底 C
% 模型：S(f) = A./(f.^2 + fc.^2) + C
% 输入：
%   data         : 时域数据
%   freq_delete  : 拟合前删除的低频阈值(Hz)，例如 10（删掉 <10 Hz 的点）
%   fc_guessing  : fc 初值（如 1e3）
%
% 输出：
%   A, fc, C, k  : 拟合参数（C 为白噪声底，k 为 log-log 斜率）

if nargin < 3, fc_guessing = 10; end

%% 采样参数
dt = 1e-5;              % 采样时间间隔 (s)
fs = 1/dt;              % 采样率 (Hz)
data = detrend(data);
n = length(data);

%% FFT -> periodogram (与你原来一致)
X = fft(data);
half_n   = floor(n/2);
X_half   = X(1:half_n);
psd_full = (1/(n*dt)) * (abs(X_half)).^2;    % V^2/Hz
df   = fs/n;
freq = (0:half_n-1) * df;

% 仅保留前 10000 个点并去掉直流
start_idx = 2;
end_idx   = min(10000000, length(freq));
freq      = freq(start_idx:end_idx);
psd       = psd_full(start_idx:end_idx);

%% 删除低频点
num_delete = floor(freq_delete / df);
idx = (num_delete+1):numel(freq);
x_fit = freq(idx);   x_fit = x_fit(:);
y_fit = psd(idx);    y_fit = y_fit(:);
y_fit = max(y_fit, realmin('double'));  % 防止 log(0)

%% 模型：Lorentzian + 常数底噪
model = @(p, f) p(1) ./ (f.^2 + p(2).^2) + p(3);   % p=[A, fc, C]

%% 初值与边界（尽量保守、可收敛）
hi_tail = max(10, round(numel(y_fit)/10));
C0 = median(y_fit(end-hi_tail+1:end));
lo_head = max(10, round(numel(y_fit)/10));
y0 = median(y_fit(1:lo_head));
fc0 = max(fc_guessing, 1);
A0  = max((y0 - C0), 0) * fc0^2;

p0 = [max(A0, eps), fc0, max(C0, eps)];
lb = [0, 1e-12, 0];
ub = [Inf, fs/2,  Inf];

%% 在 log10 尺度上拟合
fun = @(p) log10(model(p, x_fit)) - log10(y_fit);
opts = optimoptions('lsqnonlin','Display','off','MaxFunctionEvaluations',2e4,'MaxIterations',1e3);
p_fit = lsqnonlin(fun, p0, lb, ub, opts);

A  = p_fit(1);
fc = p_fit(2);
C  = p_fit(3);

%% ===== 新增部分：log-log 斜率计算 =====
% 选取中高频区 (避开低频拐点和高频噪声)
f_sel = x_fit;
P_sel = y_fit;
% 仅对 fc 以上部分拟合幂律斜率
idx_slope = (f_sel > fc);
if sum(idx_slope) > 5
    p_line = polyfit(log10(f_sel(idx_slope)), log10(P_sel(idx_slope)), 1);
    k = p_line(1);   % slope
else
    k = NaN; % 如果点太少无法拟合
end

% 绘图（保持原样）
figure;
loglog(freq, psd, '-', 'MarkerSize', 2.5, 'Color', [0.1 0.3 0.9]); hold on;
loglog(freq, model(p_fit, freq(:)), 'r-', 'LineWidth', 1.6);
grid on;
xlabel('Frequency (Hz)');
ylabel('Power Spectral Density (V^2/Hz)');
title(sprintf('Lorentzian Fit (log10):  fc = %.2f Hz', fc));
legend('Original PSD', 'Lorentzian + floor fit', 'Location', 'best');
hold on;




end
