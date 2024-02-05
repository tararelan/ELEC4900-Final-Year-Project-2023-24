function area = LaserArea()
    A = imread('laser spot.jpg');
    
    radii = imfindcircles(A, [1 30]);
    radii = radii(:);
    
    radius = 2 * radii;
    area = pi * (radius^2);
end