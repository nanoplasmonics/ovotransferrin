function data_selected = select(data, start_time, stop_time)
    sampling_fs = 100000;
    start_p = round(start_time * sampling_fs);
    stop_p = round(stop_time * sampling_fs);
    data_selected = data(start_p+1:stop_p);
end


