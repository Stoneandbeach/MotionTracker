Motion tracking using a webcam

Uses Matlab to find changing pixels in the r, g and b channels of the webcam feed. Calculates which pixels are likely to belong to the same moving object.

Currently uses distance from (0, 0) to distinguish between objects. This works for many configurations, but cannot tell apart objects on the same top left-bottom right diagonal.
Next update will also use angular separation to distinguish between objects on those diagonals.
