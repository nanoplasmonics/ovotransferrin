clc;
clear;
close all;

%% Parameter setting
addpath('Functions');
fs = 1e5;
file_name = 'Data_15_info.mat';
path = '../Data/Iron_free_no_peg_transition';

%% Load data
data_info = load_data(path, file_name);
idx = data_info(:,1);
data = data_info(:,2);

plot_filted2(data,10,1e5);
data_temp = select(data,20,30);
plot_filted2(data_temp,10,1e5);
sigma_psf = std(data_temp)*1;
mean(data)
%% PDF calculation settigns
lsb = 0.002441;
num_bins = 100;
padded_length = 128;

%% Dithering
data_dithered = data + (rand(size(data)) - 0.5) * lsb;

%% PDF calculation
[counts, binEdges] = histcounts(data_dithered, num_bins, 'Normalization', 'probability');
p_V = zeros(1, padded_length);
start_idx = floor((padded_length - num_bins) / 2) + 1;
p_V(start_idx : start_idx + num_bins - 1) = counts;

binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
figure;
bar(binCenters, counts, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'none');
xlabel('APD Voltage (V)');
ylabel('Probability Density');
title('Observed PDF (p(V)) with Dithering');
grid on;

%% Deconvolution
dv = binEdges(2) - binEdges(1);
fprintf('Current PSF Sigma: %.4f V\n', sigma_psf);
v_axis_deconv = (-(padded_length/2) : (padded_length/2 - 1)) * dv;

psf = exp(-v_axis_deconv.^2 / (2 * sigma_psf^2));
psf = psf / sum(psf);

p_V_deconv = deconvlucy(p_V, psf, 31);

figure;
subplot(2,1,1);
bar(binCenters, counts, 'FaceColor', [0.7 0.7 0.7]);
title('Observed PDF (p(V))');
subplot(2,1,2);
% 注意：deconvlucy 后的结果需要与 binCenters 的长度匹配绘图
% 这里可以用补零后的索引，也可以映射回电压
bar(p_V_deconv, 'FaceColor', [0.2 0.5 0.8]); 
title('Deconvolved PDF (True State Distribution)');

%% 第三步：计算 Energy Landscape

% 1. 重新定义物理坐标轴 (确保长度与 p_V_deconv 一致，如 128 或 256)
dv = binEdges(2) - binEdges(1); 
% 计算起始电压：将原始 binCenters 居中对齐到补零后的长度中
offset = floor((padded_length - num_bins) / 2);
v_start = binEdges(1) - offset * dv + dv/2;
v_full_axis = (0:padded_length-1) * dv + v_start;

% 2. 计算原始自由能 (kBT 单位)
% 归一化解卷积后的 PDF
P_norm = p_V_deconv / sum(p_V_deconv);
U_raw = -log(P_norm + eps); % 加上 eps 避免 log(0)
U_raw = U_raw - min(U_raw); % 将全局最低点设为 0

% 3. 过滤"天花板" (只保留能量小于 15 kBT 的有效区域)
% 这样可以剪掉那些直上直下的断崖线条
mask = U_raw < 15; 
v_valid = v_full_axis(mask);
u_valid = U_raw(mask);

% 4. 样条插值平滑 (让 Conalbumin 的三个能级谷底更丝滑)
% 将稀疏的点插值为 500 个点
v_fine = linspace(min(v_valid), max(v_valid), 500);
u_fine = spline(v_valid, u_valid, v_fine);

% 5. 绘图
figure('Color', 'w', 'Name', 'Conalbumin Energy Landscape');
plot(v_fine, u_fine, 'k-', 'LineWidth', 2); % 绘制平滑后的能量景观
hold on;

% 自动寻找并标注三个能量谷 (Wells)
[well_energies, locs] = findpeaks(-u_fine); 
plot(v_fine(locs), -well_energies, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

xlabel('Reaction Coordinate: APD Voltage (V)');
ylabel('Free Energy (k_B T)');
title('Energy Landscape of Conalbumin (Smooth)');
grid on;
set(gca, 'FontSize', 12);
el_info = [v_fine;u_fine];
file_name_s = strcat('../Data/energy_landscape_info/',file_name(1:end-4),'_elinfo.mat');
save(file_name_s,"el_info");

% 输出检测到的三个状态的能量差
if length(locs) >= 3
    fprintf('检测到三个状态！\n');
    fprintf('状态 1 & 2 能量差 (dG12): %.2f kBT\n', u_fine(locs(2)) - u_fine(locs(1)));
    fprintf('状态 2 & 3 能量差 (dG23): %.2f kBT\n', u_fine(locs(3)) - u_fine(locs(2)));
end
if length(locs) == 2
    fprintf('检测到2个状态！\n');
    fprintf('状态 2 & 3 能量差 (dG12): %.2f kBT\n', u_fine(locs(2)) - u_fine(locs(1)));
end