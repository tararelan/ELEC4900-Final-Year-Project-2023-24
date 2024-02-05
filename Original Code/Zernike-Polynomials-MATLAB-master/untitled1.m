i2=imread('lena.jpg'); % read the file
figure(3); imshow(i2); % display the image
h1=ones(1,10)/10; % impulse response (1‐by‐10, 1‐D filter)
y1=conv2(h1, h1, i2, 'same'); % perform 2‐D convolution using 1‐D filter
figure(4); imshow(y1); % map values into [0:255] before showing the figure
h2=ones(10,10)/100; % impulse response (10‐by‐10, 2‐D filter)
y2=conv2(i2, h2, 'same'); % perform 2‐D convolution using 2‐D filter
figure(5); imshow(uint8(y2)); % map values into [0:255] before showing the figure
soundsc