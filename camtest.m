clear cam
close all
cam = webcam;

thresholdMax = 10;
timeResolution = .04; %Seconds
objectLimit = 20; %Minimum points to count as an object
objectDistance = 20; %Minimum object separation distance

global col redMap greenMap blueMap run coord fig1 fig2 fig3 xSize ySize snap buttonSnap objects objColors imgMarked img thisColor;
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

buttonSnap = uicontrol('Position', [460 20 60 20]);
buttonSnap.String = 'Multiple';
buttonSnap.Callback = @takeSnap;

%Image
fig1 = axes;
set(fig1, 'Position', [.05 .15 .60 .80])
%fig1 = gca;
set(fig1, 'PickableParts', 'none')

img = snapshot(cam);
im = image(fig1, img);

%Movement map
fig2 = axes;
set(fig2, 'Position', [.70 .10 .25 .40])
%set(axes, 'Position', [.70 .05 .25 .40])
%fig2 = gca;
set(fig2, 'PickableParts', 'none')
colormap(map)

%Density plot
fig3 = axes;
set(fig3, 'Position', [.70 .55 .25 .40])
set(fig3, 'PickableParts', 'none')

oldData = double(flip(img(:,:,col)));
axis(fig2, [0 size(oldData, 2) 0 size(oldData, 1)])

set(im, 'ButtonDownFcn', @getCoord)

%Preallocation
imgMarked = [];
newData = [];
comp = [];
s = pcolor(fig2, zeros(size(img, 1, 2)));
s.EdgeColor = 'none';
set(s, 'PickableParts', 'none')
axis([0 size(oldData, 2) 0 size(oldData, 1)])
row = [];
column = [];
a = [];
b = [];
[ySize, xSize] = size(oldData);
coord = [0, 0];
density = zeros(2, ceil(sqrt(xSize^2 + ySize^2)));
angles = [];
distances = [];
ddist = [];
cuts = [];
objInd = [];
objSizes = [];
objects = myObject;
numObjs = [];

mi1 = [];
mi2 = [];
mi3 = []

order = [];
thisColor = [rand rand rand]';
pl = plot(fig3, 0, 0, 'o', 'Color', thisColor);
dAx = gca;
dAx.XLim = [0 2 * pi];
dAx.YLim = [0 ceil(sqrt(xSize^2 + ySize^2))];
axis manual
obj = 1;
moreObjects = true;
objColors = [];
[aMesh, bMesh] = meshgrid(1:xSize, 1:ySize);
indVec = [];
markIndex = [];

%Timing variables
minTime = [inf inf inf inf inf inf];
avgTime = [0 0 0 0 0 0];
maxTime = [0 0 0 0 0 0];
time = 0;
timeIndex = 0;


while (run)
    timeIndex = timeIndex + 1;
    
    imgMarked = img;

    img = snapshot(cam);

    %Compare old and new frame
    tic
    newData = double(flip(img(:,:,col)));
    comp = abs(newData - oldData);
    compMean = mean(mean(comp));
    time = toc;
    minTime(1) = min(minTime(1), time);
    avgTime(1) = (avgTime(1) * (timeIndex - 1) + time) / timeIndex;
    maxTime(1) = max(maxTime(1), time);
    
    
    oldData = newData;

    %Find pixels that have changed
    tic
    [b, a] = find(comp > compMean * thresholdMax * sliderThreshold.Value); 
    time = toc;
    minTime(2) = min(minTime(2), time);
    avgTime(2) = (avgTime(2) * (timeIndex - 1) + time) / timeIndex;
    maxTime(2) = max(maxTime(2), time);
    
    switch snap
        case false
            
            %Update movement display
            s.CData = comp;
            
            %Mark center of change in image
            row = size(comp, 1) - int16(mean(b)) + 1;
            column = int16(mean(a));
            if row < 11
                row = 11;
            else if row > size(comp, 1) - 11
                    row = size(comp, 1) - 11;
                end
            end
            if column < 11
                column = 11;
            else if column > size(comp, 2) - 11
                    column = size(comp, 2) - 11;
                end
            end
            
            for i = -10 : 10
                for c = 1 : 2
                    imgMarked(row + i, column + i, c) = 255;
                    imgMarked(row + i, column - i, c) = 255;
                end
            end

            %Update density plot
            density(:, :) = 0;
            for j = 1 : size(b)
                %dist = ceil(sqrt((b(j) - coord(1))^2 + (a(j) - coord(2))^2));
                if (a(j) - coord(1) ~= 0) && (b(j) - coord(2) ~= 0)
                    angle = atan2(a(j) - coord(1), b(j) - coord(2));
                    if angle < 0
                        angle = angle + 2*pi;
                    end
                    dist = ceil(sqrt((a(j) - coord(1))^2 + (b(j) - coord(2))^2));
                    density(1, j) = angle;
                    density(2, j) = dist;
                end
                %density(angIndex + 1) = density(angIndex + 1) + 1;
            end
            pl(1).XData = density(1, :);
            pl(1).YData = density(2, :);

            im.CData = imgMarked;

            pause(timeResolution)
        
        case true
            
            if length(a) >= 1
                
                s.CData = comp;
                
                %Update density plot as seen from (0, 0)
                tic
                angles = atan2(a, b);
                angles(angles < 0) = angles(angles < 0) + 2*pi;
                distances = (a.^2 + b.^2).^(1/2);
                time = toc;
                minTime(3) = min(minTime(3), time);
                avgTime(3) = (avgTime(3) * (timeIndex - 1) + time) / timeIndex;
                maxTime(3) = max(maxTime(3), time);
                
                %Separate into objects
                tic
                [distances, order] = sort(distances);
                points = [a(order), b(order), angles(order), distances]; %x y angle distance
                time = toc;
                minTime(4) = min(minTime(4), time);
                avgTime(4) = (avgTime(4) * (timeIndex - 1) + time) / timeIndex;
                maxTime(4) = max(maxTime(4), time);
                
                tic
                ddist = distances(2:end) - distances(1:end-1);
                cuts = find(ddist > objectDistance);
                objInd = [[1; cuts + 1], [cuts; size(distances, 1)]]; %Row n is object n start and end index
                objSizes = find(objInd(:, 2) - objInd(:, 1) > objectLimit);
                numObjs = length(objSizes);
                for i = 1 : numObjs
                    objects(i).x = a(objInd(objSizes(i), 1) : objInd(objSizes(i), 2));
                    objects(i).y = b(objInd(objSizes(i), 1) : objInd(objSizes(i), 2));
                    objects(i).angle = angles(objInd(objSizes(i), 1) : objInd(objSizes(i), 2));
                    objects(i).distance = distances(objInd(objSizes(i), 1) : objInd(objSizes(i), 2));
                    if size(thisColor, 2) < i
                        thisColor(1:3, i) = 0.5 + 0.5 * [rand rand rand];
                    end
                end
                
                time = toc;
                minTime(5) = min(minTime(5), time);
                avgTime(5) = (avgTime(5) * (timeIndex - 1) + time) / timeIndex;
                maxTime(5) = max(maxTime(5), time);
                
                obj = length(objSizes);
                
                tic
                if ~isempty(objects)
                    
                    for i = 1 : obj
%                       Color in movement
                        indVec = objects(i).x * 1000 + objects(i).y;
                        markIndex = flip(ismember(aMesh * 1000 + bMesh, indVec));
                        mi1 = imgMarked(:, :, 1);
                        mi2 = imgMarked(:, :, 2);
                        mi3 = imgMarked(:, :, 3);
                        mi1(markIndex) = floor(255 * thisColor(1, i));
                        mi2(markIndex) = floor(255 * thisColor(2, i));
                        mi3(markIndex) = floor(255 * thisColor(3, i));
                        imgMarked = cat(3, mi1, mi2, mi3);
                        if i > size(pl, 2)
                            hold on
                            pl(i) = plot(fig3, objects(i).angle, objects(i).distance, 'o', 'Color', thisColor(:, i));
                            axis([0 2*pi 0 sqrt(xSize^2 + ySize^2)])
                            hold off
                        else
                            pl(i).XData = objects(i).angle;
                            pl(i).YData = objects(i).distance;
                        end
                    end
                    if size(pl, 2) > obj
                        for i = obj + 1 : size(pl, 2)
                            pl(i).XData = [];
                            pl(i).YData = [];
                        end
                    end


                    %Mark centers of objects
                    for o = 1 : obj
                        markColor(o);
                    end
                end
                time = toc;
                minTime(6) = min(minTime(6), time);
                avgTime(6) = (avgTime(6) * (timeIndex - 1) + time) / timeIndex;
                maxTime(6) = max(maxTime(6), time);
                
                im.CData = imgMarked;
            end

            pause(timeResolution)
            objects = [];
    end
    
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

function takeSnap(~, ~)
    global snap buttonSnap;
    snap = ~snap;
    if snap
        buttonSnap.String = 'Single';
    else
        buttonSnap.String = 'Multiple';
    end
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