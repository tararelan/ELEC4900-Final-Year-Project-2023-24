% Laser area (A_las)
laser_area = LaserArea();

Young = zeros(2, length(tracks));

for i = 1:length(tracks)
    track = tracks(i);

    if isinf(track.speed)
        continue;
    elseif isempty(track.speed)
        continue;
    end


    %% Area
    % Cell area (A_cell)
    temp = max(track.diameterY);
    y_max = double(temp(1)) / 2;
    i_y_max = track.maxChangeIdY;
    x_max = double(track.diameterX(i_y_max)) / 2;
    cell_area = double(pi * y_max * x_max);
    % Final area (A)
    area = double(cell_area - laser_area);

    %% Force
    % Viscosity
    viscosity = double(1);
    % Radius
    radius = double((y_max + x_max) / 2);
    % Velocity 5ul/hr - convert to m^3/s
    velocity = double(5);
    % Force = 6*pi*viscosity*radius*velocity
    force = double(6*pi*viscosity*radius*velocity);

    numer = force / area;

    %% Change in radius
    y_0 = double(track.diameterY(1)) / 2;
    delta_y = y_max - y_0;

    x_0 = double(track.diameterX(1)) / 2;
    delta_x = x_max - x_0;

    denom = delta_y / y_0;

    if denom <= 0 || numer <= 0
        continue
    end

    %% Young's Modulus
    E = numer / denom;
    track.Youngs = E;

    Young(:, i) = [track.id; E];
end

Young = Young(:, any(Young))';