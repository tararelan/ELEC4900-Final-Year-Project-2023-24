x=linspace(-1,1,100);
        y=linspace(1,-1,100);
        [x,y] = meshgrid(x,y);
        z = x.^2+y.^3;
        figure;
        imshow(elliptical_crop(z, 1));
        title('z(x,y)');
