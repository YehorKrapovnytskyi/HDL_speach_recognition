%% Initialize filter parameters
B = 16;                           % Coefficient's width
R = 125;                          % Decimation factor
N = 2;                            % Order
M = 1;                            % Diff delay
NFFT = 2 ^ 16;
ff = 0:1/NFFT:1-1/NFFT;

Fs = 2e6;                         % Set sampling rate
ts = 1/Fs;   
Fc = 8000;
Fo = 0.5 ;                        % Normalized cutoff

p = 2e3;                          % Granularity
s = 0.25/p;                       % Step size
fp = [0:s:Fo];                    % Pass band frequency samples
fs = (Fo+s):s:0.5;                % Stop band frequency samples
f = [fp fs] * 2;

%% �alculate CIC filter response
HCIC = abs(sin(pi * M * ff) ./ sin(pi * ff ./ R)) .^ N;   % �alculate CIC frequecy response
HCIC(1) = HCIC(2);                                    
HCICdb = 20 * log10(abs(HCIC));
HCICdb = HCICdb - max(HCICdb);

%% Calculate compensation filter and its idead frequency response
L = 20; 
Mp = ones(1, length(fp));                    % Pass band response; Mp(1)=1
Mp(2:end) = abs(M * R * sin(pi * fp(2:end) / R)./ sin(pi * M * fp(2:end))) .^ N; 
Mf = [Mp zeros(1, length(fs))];
f(end) = 1;
h = fir2(L, f, Mf);                          % Filter length L+1
h = h / max(h);                             % Floating point coefficients
hz = int32(round(h * power(2, B - 1) - 1));  % Fixed point coefficients

%% Calculate FIR filter real frequency response
hFFT_db = 20 * log10(abs(fft(hz, length(HCIC))));
hFFT_db = hFFT_db - max(hFFT_db);
result_response = hFFT_db + HCICdb;
result_response = result_response - max(result_response);

%% Parameters for HDL Simulink model
OVERSAMPLING_FACTOR = 50; % 100 MHz / 50 = 2 MHz
ftest1 = 1e3;
ftest2 = 4e3;
ftest3 = 12e3;
ftest4 = 8e3;
CIC_data_width = 1 + ceil(N * log2(R));
CIC_data_type = fixdt(1, CIC_data_width, 0);
FIR_product_data_type = fixdt(1, 31, 0);
FIR_coeffs_data_type = fixdt(1, 16, 0);
scaling_numerator = 11;
scaling_denominator = 4;
shifts_to_scale = log2(scaling_denominator);










%% Plot filter response                      
figure("name", "CIC filter response with FIR compensation", 'Numbertitle', 'off');
plot(ff, HCICdb, '--', 'LineWidth', 3, 'Color',[0 0 1]); 
hold on;
plot(ff, result_response, '-', 'LineWidth', 3, 'Color',[1 0 0]); 
hold on;
plot(ff, hFFT_db, '--', 'LineWidth', 3, 'Color',[1 1 0]); 
title([{'CIC, Comp. FIR and Result'};{sprintf('Filter Order = %i, Coef. width = %i', L, B)}]);
xlabel ('Freq (\pi x rad / samples)');
ylabel ('Magnitude (dB)');  
legend('CIC filter','Sum Response', 'Comp. FIR','location','northeast');
axis([0 1 -100 5]); 






