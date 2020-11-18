%Motion tracking using change in r, g and b channels of webcam image
%Buttons Red, Green and Blue control which colour channel is being used to
%detect motion.
%Slider controls threshold for detection.

clear cam
close all
cam = webcam;

thresholdMax = 10;
timeResolution = .04; %Seconds
objectLimit = 50; %Minimum points to count as an object
objectDistance = 20; %Minimum object separation distance

global col redMap greenMap blueMap run coord fig1 fig2 fig3 xSize ySize snap objects objColors imgMarked img thisColor;
run = true;
snap = false;
redMap = [0 : 0.01 : 1; zeros(2, 101)]';
greenMap = [zeros(1, 101); 0 : 0.01 : 1; zeros(1, 101)]';
blueMap = [zeros(2, 101); 0 : 0.01 : 1]';
col = 1;
map = redMap;

%Setup figures and UI
fig = figure(1);
set(fig, 'Position', [100 50 1160 550])
set(fig, 'ButtonDownFcn', @(src,~) disp('You clicked the figure'))
button1r = uicontrol('Position', [20 20 60 20]);
button1r.String = 'Red';
button1r.Callback = @setMap;

button1g = uicontrol('Position', [100 20 60 20]);
button1g.String = 'Green';
button1g.Callback = @setMap;

button1b = uicontrol('Position', [180 20 60 20]);
button1b.String = 'Blue';
button1b.Callback = @setMap;

buttonExit = uicontrol('Position', [260 20 60 20]);
buttonExit.String = 'Exit';
buttonExit.Callback = @quitFunction;

sliderThreshold = uicontrol('Style', 'slider', 'Position', [340 20 100 20]);
sliderThreshold.Value = 0.7;

sliderLabel = uicontrol('Style', 'text', 'Position', [340 40 100 18]);
sliderLabel.String = 'Detection threshold:';

%Image
fig1 = axes;
set(fig1, 'Position', [.05 .15 .60 .80])
set(fig1, 'PickableParts', 'none')

img = snapshot(cam);
im = image(fig1, img);
set(fig1, 'XTick', [], 'YTick', [])

%Movement map
fig2 = axes;
set(fig2, 'Position', [.70 .10 .25 .40])
set(fig2, 'PickableParts', 'none')
colormap(map)

%Density plot
fig3 = axes;
set(fig3, 'Position', [.70 .55 .25 .40], 'PickableParts', 'none')

oldData = double(flip(img(:,:,col)));
[ySize, xSize] = size(oldData);
axis(fig2, [0 xSize 0 ySize])

set(im, 'ButtonDownFcn', @getCoord)

%Preallocation
imgMarked = [];
newData = [];
comp = [];
s = pcolor(fig2, zeros(size(img, 1, 2)));
s.EdgeColor = 'none';
set(s, 'PickableParts', 'none')
%axis([0 size(oldData, 2) 0 size(oldData, 1)])
row = [];
column = [];
a = [];
b = [];
coord = [0, 0];
angles = [];
distances = [];
ddist = [];
cuts = [];
objInd = [];
objSizes = [];
objects = myObject;
xBand = myObject;
numObjs = 0;
xcuts = [];
dx = [];
xInd = [];
xIndAboveSizeLimit = [];
ycuts = [];
dy = [];
yInd = [];
yIndAboveSizeLimit = [];

mi1 = [];
mi2 = [];
mi3 = [];

order = [];
thisColor = [1 0.5+0.5*rand 0.5+0.5*rand]';
thisColor = thisColor(randperm(3));
pl = plot(fig3, 0, 0, 'o', 'Color', thisColor);
axis(fig3, [0 640 0 360])
objColors = [];
[aMesh, bMesh] = meshgrid(1:xSize, 1:ySize);
indVec = [];
markIndex = [];

p = patch(fig1, 'XData', [0 0], 'YData', [0 0], 'FaceColor', 'none', 'EdgeColor', thisColor', 'LineWidth', 3);

%Timing variables
loopTime = 0;
t = 0;

while (run)
    t = tic;
    
    imgMarked = img;

    img = snapshot(cam);

    %Compare old and new frame
    newData = double(flip(img(:,:,col)));
    comp = abs(newData - oldData);
    compMean = mean(mean(comp));    
    
    oldData = newData;

    %Find pixels that have changed
    [b, a] = find(comp > compMean * thresholdMax * sliderThreshold.Value); 
    
    if length(a) >= 1

        s.CData = comp; %Update r/g/b-channel visual

        %Additional information about points, angles and distances from
        %(0, 0), currently unused
        angles = atan2(a, b);
        angles(angles < 0) = angles(angles < 0) + 2*pi;
        distances = (a.^2 + b.^2).^(1/2);

        %Separate registered moving points into objects
        [x, order] = sort(a);
        y = b(order);
        angles = angles(order);
        distances = distances(order);

        dx = x(2:end) - x(1:end-1);
        xcuts = find(dx > objectDistance);
        xInd = [[1; xcuts + 1], [xcuts; size(x, 1)]]; %Row n is object n start and end index
        xIndAboveSizeLimit = find(xInd(:, 2) - xInd(:, 1) > objectLimit); %Find objects in xInd above object size limit
        numx = length(xIndAboveSizeLimit);

        objNumber = 1;

        for i = 1 : numx

            xBand(i).x = x(xInd(xIndAboveSizeLimit(i), 1) : xInd(xIndAboveSizeLimit(i), 2));
            xBand(i).y = y(xInd(xIndAboveSizeLimit(i), 1) : xInd(xIndAboveSizeLimit(i), 2));
            xBand(i).angle = angles(xInd(xIndAboveSizeLimit(i), 1) : xInd(xIndAboveSizeLimit(i), 2));
            xBand(i).distance = distances(xInd(xIndAboveSizeLimit(i), 1) : xInd(xIndAboveSizeLimit(i), 2));

            [xBand(i).y, order] = sort(xBand(i).y);
            xBand(i).x = xBand(i).x(order);
            xBand(i).angle = xBand(i).angle(order);
            xBand(i).distance = xBand(i).distance(order);

            dy = xBand(i).y(2:end) - xBand(i).y(1:end-1);
            ycuts = find(dy > objectDistance);
            yInd = [[1; ycuts + 1], [ycuts; size(xBand(i).y, 1)]];
            yIndAboveSizeLimit = find(yInd(:, 2) - yInd(:, 1) > objectLimit);
            numy = length(yIndAboveSizeLimit);

            for j = 1 : numy
                objects(objNumber).x = xBand(i).x(yInd(yIndAboveSizeLimit(j), 1) : yInd(yIndAboveSizeLimit(j), 2));
                objects(objNumber).y = xBand(i).y(yInd(yIndAboveSizeLimit(j), 1) : yInd(yIndAboveSizeLimit(j), 2));
                objects(objNumber).angle = xBand(i).angle(yInd(yIndAboveSizeLimit(j), 1) : yInd(yIndAboveSizeLimit(j), 2));
                objects(objNumber).distance = xBand(i).distance(yInd(yIndAboveSizeLimit(j), 1) : yInd(yIndAboveSizeLimit(j), 2));
                if size(thisColor, 2) < objNumber
                    thisColor(1:3, objNumber) = [1 0.5+0.5*rand 0.5+0.5*rand];
                    thisColor(1:3, objNumber) = thisColor(randperm(3), objNumber);
                end
                objNumber = objNumber + 1;
            end
        end

        numObjs = objNumber - 1;

        if ~isempty(objects)

            for i = 1 : numObjs
                %Mark center of object
                markColor(i);
                
                if length(p) < i
                    hold on
                    p(i) = patch(fig1, 'XData', [0 0 0], 'YData', [0 0 0], 'EdgeColor', thisColor(1:3, i), 'FaceColor', 'none', 'LineWidth', 3);
                    hold off
                end
                hold on
                set(p(i), 'Visible', 'on')
                p(i).XData = [min(objects(i).x), min(objects(i).x), ...
                    max(objects(i).x), max(objects(i).x)];
                p(i).YData = [ySize - min(objects(i).y), ySize - max(objects(i).y), ...
                    ySize - max(objects(i).y), ySize - min(objects(i).y)];
                hold off
                %Color in all movement in image movement
%                         indVec = objects(i).x * 1000 + objects(i).y;
%                         markIndex = flip(ismember(aMesh * 1000 + bMesh, indVec));
%                         mi1 = imgMarked(:, :, 1);
%                         mi2 = imgMarked(:, :, 2);
%                         mi3 = imgMarked(:, :, 3);
%                         mi1(markIndex) = floor(255 * thisColor(1, i));
%                         mi2(markIndex) = floor(255 * thisColor(2, i));
%                         mi3(markIndex) = floor(255 * thisColor(3, i));
%                         imgMarked = cat(3, mi1, mi2, mi3);

                if i > size(pl, 2)
                    hold on
                    pl(i) = plot(fig3, objects(i).angle, objects(i).distance, 'o', 'Color', thisColor(:, i));
                    axis([0 640 0 360])
                    hold off
                else
                    set(pl(i), 'Visible', 'on');
                    pl(i).XData = objects(i).x;
                    pl(i).YData = objects(i).y;
                end
            end
            set(p(numObjs + 1 : end), 'Visible', 'off')

            if size(pl, 2) > numObjs
                set(pl(numObjs + 1 : end), 'Visible', 'off');
            end

        end

        im.CData = imgMarked;
        %uistack(im, 'bottom')
    end

    loopTime = toc(t);
    pause(max(timeResolution - loopTime, 0))
    
end

function quitFunction(~, ~)
    global run;
    disp('Stopping loop')
    run = false;
end

function setMap(src, ~)
    global col redMap greenMap blueMap fig2;
    colIn = src.String;
    switch colIn
        case 'Red'
            col = 1;
            fig2.Colormap = redMap;
        case 'Green'
            col = 2;
            fig2.Colormap = greenMap;
        case 'Blue'
            col = 3;
            fig2.Colormap = blueMap;
    end
end

function getCoord(~, ~)
    global coord fig1 ySize;
    gotCoord = get(fig1, 'CurrentPoint');
    coord = floor([gotCoord(1, 1), ySize - gotCoord(1, 2)]);
end

function avgColor = markColor(thisObj)
	global objects imgMarked img xSize ySize thisColor;
    avgColor = zeros(1, 3);
    numPoints = 0;
    row = ySize - floor(mean(objects(thisObj).y(objects(thisObj).y > 0)));
    column = floor(mean(objects(thisObj).x(objects(thisObj).x > 0)));
    
    %Mark center of object
    for i = -10 : 10
        if (row + i < ySize) && (row + i > 0)
            for c = 1 : 3
                if (column + i < xSize) && (column + i > 0)
                    imgMarked(row + i, column + i, c) = 255 * thisColor(c, thisObj);
                end
                if (column - i < xSize) && (column - i > 0)
                    imgMarked(row + i, column - i, c) = 255 * thisColor(c, thisObj);
                end
            end
            
            %Check average color around center of object
            for j = -10 : 10
                if (column + j < xSize) && (column + j > 0)
                    numPoints = numPoints + 1;
                    for c = 1 : 3
                        avgColor(c) = avgColor(c) + img(row + i, column + j, c);
                    end
                end
            end
        end
    end
    avgColor = avgColor ./ numPoints;
end