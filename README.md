# Motion tracking using a webcam

Work-in-progress motion tracking project. Challenge to myself to avoid for loops and keep runtime low.

Uses Matlab to find changing pixels in the r, g and b channels of the webcam feed. Calculates which pixels are likely to belong to the same moving object.

The current version can separate objects with relatively good precision, but is bad at picking out objects moving against similarly-coloured backgrounds.
