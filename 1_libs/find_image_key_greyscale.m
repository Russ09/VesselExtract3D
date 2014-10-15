function [maxtab, Nfilt, N, X] = find_image_key_greyscale(img)

% Find the key peaks in the image
%
%

[N, X] = hist(img(:), 255);

%removing hist outliers
Nfilt = medfilt1(N, 3);
%smoothing hist
Nfilt = conv(Nfilt, [1,1,1,1,1]', 'same');
%normalising
Nfilt = Nfilt / max(Nfilt(:));

% finding peaks of the hist
[maxtab, mintab] = peakdet(Nfilt, 0.01, X);

