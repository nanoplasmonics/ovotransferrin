function plot_filted_PDF(data, bins, cutoff, sampling_fs, order)
    % 设置默认值
    if nargin < 5
        order = 4; % 默认滤波器阶数
    end
    if nargin < 4
        sampling_fs = 100000; % 采样频率
    end
    if nargin < 3
        cutoff = 10; % 默认截止频率
    end
    
    % 计算时间轴
    time_step = 1 / sampling_fs;  % 采样时间间隔
    num_data = length(data);
    time_variable = (0:num_data-1) * time_step; % 时间轴

    % 低通滤波
    filtered_data = lowpass_filter(data, cutoff, sampling_fs, order);

    %  %% multiple histogram at once
    %% ====== Multi-bin Gaussian Fit Comparison ======
    % x = data - mean(data);  % zero-mean the data
    % bin_list = 20:5:100;       % bins = [40, 43, 46, ..., 70]
    % n_bins = numel(bin_list);
    % figure('Color','w');
    % tiledlayout(2,5,'Padding','compact','TileSpacing','compact');
    % ncols = ceil(sqrt(n_bins));
    % nrows = ceil(n_bins / ncols);
    % tiledlayout(nrows, ncols, 'Padding','compact','TileSpacing','compact');
    % for i = 1:n_bins
    %     bins = bin_list(i);
    %     nexttile;
    %     % --- Histogram (PDF normalization) ---
    %     histogram(x, bins, 'Normalization', 'pdf', ...
    %         'FaceAlpha', 0.6, 'EdgeColor', 'none');
    %     hold on;
    %     % --- Gaussian fit ---
    %     mu = mean(x);
    %     sigma = std(x);
    %     x_fit = linspace(min(x), max(x), 7000);
    %     y_fit = (1/(sigma*sqrt(2*pi))) * exp(-(x_fit-mu).^2/(2*sigma^2));
    %     plot(x_fit, y_fit, 'r-', 'LineWidth', 1.5);
    %     % --- Formatting ---
    %     grid on; box on;
    %     title(sprintf('%d bins', bins));
    %     xlabel('Signal amplitude (V)');
    %     ylabel('Probability density');
    %     % legend('Histogram','Gaussian fit','Location','northeast');
    %     xlim([min(x), max(x)]);
    %     ylim auto;
    % end
    % sgtitle('Histogram with Gaussian Fit | Bin count comparison (40→70, step 3)');
    % set(gcf,'Units','centimeters','Position',[2 2 30 12]);
    


    % PDF
    % x = data;
    % figure;
    % subplot(2,1,1);
    % histogram(x, bins , 'Normalization', 'pdf');
    % hold on;
    % mu = mean(x);
    % sigma = std(x);
    % x_fit = linspace(min(x), max(x), 7000);
    % y_fit = (1/(sigma*sqrt(2*pi))) * exp(-(x_fit-mu).^2/(2*sigma^2));
    % plot(x_fit, y_fit, 'r-', 'LineWidth', 0.9);
    % xlabel('Detrend sigmented signal amplitude (V)');
    % ylabel('Probability density');
    % title('Histogram with Gaussian Fit');
    % legend('Histogram','Gaussian fit');
    % grid on;
    % hold off;

    % 绘制 histogram
    x = data;
    figure; 
    subplot(2,1,1);
    histogram(x, bins, 'Normalization', 'pdf', 'FaceColor', [0.3 0.5 0.8], 'EdgeColor', 'none');
    hold on;

    % 双峰高斯混合拟合（GMM）
    gm = fitgmdist(x, 2);   % <-- 两个 state

    % 生成平滑曲线
    xx = linspace(min(x), max(x), 2000)';
    yy = pdf(gm, xx);

    % 绘制 GMM 拟合曲线
    plot(xx, yy, 'r-', 'LineWidth', 2);

    % 绘制每个单独 state 的 Gaussian 曲线
    mu1 = gm.mu(1);  s1 = sqrt(gm.Sigma(1));
    mu2 = gm.mu(2);  s2 = sqrt(gm.Sigma(2));

    yy1 = gm.ComponentProportion(1) * normpdf(xx, mu1, s1);
    yy2 = gm.ComponentProportion(2) * normpdf(xx, mu2, s2);

    plot(xx, yy1, 'k--', 'LineWidth', 1.5);
    plot(xx, yy2, 'k--', 'LineWidth', 1.5);

    title('Two-State PDF with Gaussian Mixture Fit');
    xlabel('Voltage (V)');
    ylabel('PDF');
    grid on;
    legend('Histogram','GMM total fit','State 1','State 2');
    hold off;

    % % --- compute R² goodness of fit ---
    % [counts, edges] = histcounts(x, 36, 'Normalization','pdf');
    % centers = edges(1:end-1) + diff(edges)/2;
    % y_gauss = (1/(sigma*sqrt(2*pi))) * exp(-(centers-mu).^2/(2*sigma^2));
    %
    % SStot = sum( (counts - mean(counts)).^2 );
    % SSres = sum( (counts - y_gauss).^2 );
    % R2 = 1 - SSres/SStot;
    %
    % fprintf('R² goodness-of-fit = %.4f\n', R2);
    % % %% statistics test
    % % x = x(~isnan(x));         % remove NaNs if any
    % %
    % % % --- Kolmogorov–Smirnov normality test ---
    % % [h, p] = kstest((x - mean(x))/std(x));
    % %
    % % fprintf('Kolmogorov–Smirnov test: h = %d,  p = %.4f\n', h, p);
    % %
    % %
    % %
    %% multiple histogram at once
    
    % 绘图
    %figure;
    subplot(2,1,2);
    plot(time_variable, data, 'Color', [0, 0, 1, 0.1], 'LineWidth', 1, 'LineStyle', '-'); hold on;
    plot(time_variable, filtered_data, 'Color', [0, 0, 1, 1], 'LineWidth', 1, 'LineStyle', '-');
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

