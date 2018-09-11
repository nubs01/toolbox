function sClasses = twoThreshSchmittTrigger(X,highThresh,lowThresh)
% sClasses = twoThreshSchmittTirgger(X,highThresh,lowThresh)
% will return a vector classifying X as being in a high state (1) or low
% state (-1). A high state starts when X>highThresh and continues until
% X<lowThres. Similarly a low sate starts when X<lowThresh and continues
% until X>highThresh

sClasses = zeros(size(X));
sClasses(X<lowThresh) = -1;
sClasses(X>highThresh)= 1;
a = sClasses==0;
b = 1:numel(X);
sClasses = interp1(b(~a),sClasses(~a),b,'previous');
sClasses(isnan(sClasses)) = 0;
