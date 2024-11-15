clear all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
fc = 77e9;  % Frequency of operation = 77GHz
range_max = 200; % Max Range = 200m
vel_max   = 100; % Max Velocity = 100 m/s
res_range = 1;   % Range Resolution = 1m
%%%%%%%%%%%%%%%%%%%%%%%%%%%

c = 3e8; %speed of light = 3e8

% define the target's initial position and velocity. Note : Velocity
% remains constant
Range_target = 120;
Vel_target = 40; 

%% FMCW Waveform Generation

% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.
B      = c/(2*res_range);        % Bandwidth
Tchirp = 5.5 * (2* range_max/c);   % Chirp Time
slope  = B / Tchirp;             % Slope

%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx  =zeros(1,length(t));  % transmitted signal
Rx  =zeros(1,length(t));  % received signal
Mix = zeros(1,length(t)); % beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));

% Update the Range of the Target for constant velocity. 
r_t = Range_target + t(i)*Vel_target;
td = 2 * r_t./c;
% Update the transmitted and received signal. 
Tx = cos(2*pi*(fc*t + 0.5*(slope*(t.^2))));
Rx = cos(2*pi*(fc*(t - td) + 0.5*(slope*((t - td).^2))));
%Now by mixing the Transmit and Receive generate the beat signal
Mix = Tx .* Rx;


%% RANGE MEASUREMENT

%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.
Mix_reshaped = reshape(Mix,[Nr, Nd]);


%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.
fft1D = fft(Mix_reshaped,Nr); 


% Take the absolute value of FFT output
fft1D = abs(fft1D);
fft1D= fft1D./max(fft1D);

% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
final_fft1D = fft1D(1:Nr/2+1);

%plotting the range
figure ('Name','Range from First FFT')
plot(final_fft1D)
title('FFT First');
xlabel('Range');
ylabel('Normalized Magnitude'); 
axis ([0 200 0 1]);



%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure,surf(doppler_axis,range_axis,RDM);

figure ('Name','surface plot of FFT2')
surf(doppler_axis,range_axis,RDM);
title('FFT2 surface plot')
xlabel('Speed')
ylabel('Range')
zlabel('Magnitude')
%% CFAR implementation

%Slide Window through the complete Range Doppler Map

%Select the number of Training Cells in both the dimensions.
Tr = 10;
Tc = 7;


%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gc = 4;
Gr = 4;

% offset the threshold by SNR value in dB
offset = 1.7;

%Create a vector to store noise_level for each iteration on training cells
noise_level = zeros(1,1);


% *%TODO* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.


   % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
   % CFAR

RDM = RDM/max(max(RDM));
[row, col] = size(RDM);
Cell_Under_Test = zeros(row,col);

%# Vectorized form
%# Use conv2 to do the averaging
%# Define mask where guard bands + centre is set to 0
%# Divide by the total number of non-zero elements
mask = ones(2  *Tr + 2*  Gr + 1, 2  *Td + 2*  Gd + 1);
centre_coord = [Tr + Gr + 1, Td + Gd + 1];
mask(centre_coord(1) - Gr : centre_coord(1) + Gr, centre_coord(2) - Gd : centre_coord(2) + Gd) = 0;
mask = mask / sum(mask(:));

%# Convolve, then convert back to dB to add the offset
%# The convolution defines the threshold
threshold = conv2(db2pow(RDM), mask, 'same');
threshold = pow2db(threshold) + offset;


% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 
[m,n] = size(RDM);
for t=1:m
    for k=1:n
        if(RDM(t,k)~=0 && RDM(t,k)~=1)
            RDM(t,k) = 0;
        end
    end
end



%display the CFAR output using the Surf function like we did for Range
%Doppler Response output.
figure,surf(doppler_axis,range_axis, RDM);
colorbar;
title('2D CFAR');
xlabel('Doppler Velocity');
ylabel('Range');
zlabel('Magnitude (Normalized)');


 
 
