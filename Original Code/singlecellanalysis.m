[A20, A40, A1_1, A2_2, A11, A22, A00, A3_1, A31, cell1, Icropped] = displayValidFrame(trappedCells, 619, '1d 15ulhr(proccessed).avi');
A20_40 = A40./A20;
figure(1);
% subplot(211);
x = 1:length(A20_40);
plot(x, A20_40); ylim([-0.5, 2]); title('A40/A20 for a trapped distorted cell'); ylabel('A40/A20'); xlabel('frame(×0.33s)');
% subplot(212);
% plot(x, abs(A1_1./A11.*A20./A40)); 


function [A20, A40, A1_1, A2_2, A11, A22, A00, A3_1, A31, cell, Icropped] = displayValidFrame(trappedCells, id, filename)
    reader = VideoReader(filename);
    cell = trappedCells([trappedCells(:).id] == id);
    cell.validFrame = logical(cell.validFrame);
    validBbox = cell.bbox(cell.validFrame, :);
    validFrame = cell.startFrame:cell.startFrame + length(cell.validFrame) - 1;
    validFrame = validFrame(cell.validFrame);
    A20=[]; A40=[]; A1_1=[]; A2_2=[]; A11=[]; A00 = []; A22 = []; A3_1 = []; A31 = [];
    for i = 1:size(validBbox, 1)
        frame = read(reader, validFrame(i));
        Icropped = rgb2gray(imcrop(frame, [validBbox(i,1)-10, validBbox(i,2)-10, validBbox(i,3)+20, validBbox(i,4)+20]));
%         Icropped = wiener2(Icropped, [3, 3]);
%         Icropped = histeq(Icropped);
%         Icropped = wiener2(Icropped, [3, 3]);
%         inverter = ones(size(Icropped, 1), size(Icropped, 2))*255;
%         Icropped = uint8(inverter) - Icropped;
        Icropped = fftdenoise(Icropped);
        Icropped = double(Icropped)./255;
        Icropped = 1 - Icropped;
        Icropped = elliptical_crop(Icropped, 1);
        
    
        A20 = cat(1, A20, zernike_moments(double(Icropped), [2, 0]));
        A40 = cat(1, A40, zernike_moments(double(Icropped), [4, 0]));
        A1_1 = cat(1, A1_1, zernike_moments(double(Icropped), [1, -1]));
        A2_2 = cat(1, A2_2, zernike_moments(double(Icropped), [2, -2]));
        A11 = cat(1, A11, zernike_moments(double(Icropped), [1, 1]));
        A00 = cat(1, A00, zernike_moments(double(Icropped), [0, 0]));
        A22 = cat(1, A22, zernike_moments(double(Icropped), [2, 2]));
        A3_1 = cat(1, A3_1, zernike_moments(double(Icropped), [3, -1]));
        A31 = cat(1, A31, zernike_moments(double(Icropped), [3, 1]));

        if i == 30
            figure(3);
            imshow(Icropped);
        end
    end

    function outim = fftdenoise(inputim)
%         inputim = histeq(inputim);
        FFT = fft2(inputim);

        FS = abs(fftshift(FFT));
%         S = log(1+FS);
%         figure(1);
%         imshow(S,[]);
        [h,w] = size(FS);
        FS(1:uint8(h/2) - 6, :) = 0;
        FS(uint8(h/2)+6:1, :) = 0;
        FS(:, 1:uint8(w/2)-6) = 0;
        FS(:, uint8(w/2)+6:w) = 0;
%         figure(2);
%         imshow(log(1+FS), []);

        aaa = ifftshift(FS);
        bbb = aaa.*cos(angle(FFT)) + aaa.*sin(angle(FFT)).*1i;
        fr = abs(ifft2(bbb));
        outim = im2uint8(mat2gray(fr));
        % ret = histeq(outim);
%         figure(3);imshow(outim);
    end
end