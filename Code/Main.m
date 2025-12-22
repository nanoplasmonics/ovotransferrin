%% Main function
clc
clear
close all
addpath('Functions');

data_path = 'Set_5_converted';
file_name = 'Data_2.mat';
data = load_data(data_path,file_name);
%plot_filted_abs(data); 
plot_filted(data); 


start_time = input('Input a starting time (s):');
stop_time = input('Input a stop time (s):');
data = select(data,start_time,stop_time);
%data = detrend(data);
%plot_filted(data); 
%plot_filted_PDF(data, 70); 

% [~,fc,~ ] = Lorentzian2(data,0,30);
%[~,fc,~,k ] = Lorentzian3(data,0,30);
[freq_1,psd_1] = Lorentzian3(data,0,30);
mean(data)
% disp(strcat('Coner frequency calculate by Lorentzian: ',num2str(fc)));

% disp(strcat('PSD slope calculate by Lorentzian: ',num2str(k)));
% 
% tau = CorrelationTime(data,0.008);
% disp(strcat('Concer frequency calculated by 1/e of correlation time: ', num2str(1/2/pi/tau)));
% 
% [A,a,b ] = CorrelationTime_Fit(data,2,0.1);
% disp(strcat('Concer frequenct calculated by correlation time fitting: ', num2str(a/2/pi)))

