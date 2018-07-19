function h = simpleSigStar(X,Y,StDev,P)
% Works for plotting significance bars over time data plots
% X must be an nx2 array with start and end times of each window, and P
% must be an array with P-values corresponding to each window in X. Y and
% StDev must be the same size, but they do not have to match X & P. Y is
% just used to decided the height of the sig bars, so can also just be the
% max Y value of the data


% Check hold status
switch ishold
    case 0
        hs = 'off';
        clf;
    case 1
        hs = 'on';
end

topPos = 1.005*max(Y+StDev);
yPos = 1.01*max(Y+StDev);

s1 = [];
s2 = [];
s3 = [];
sigVec = zeros(1,numel(X));
lines = {};
curLin = [0 0 0];

for i=1:size(X,1),
    s = 0;
    if P(i) <=0.05
        s = 1;
    end
    if P(i) <= 0.01;
        s = 2;
    end
    if P(i) <= 0.001;
        s = 3;
    end
    sigVec(i) = s;
    if s>0
        if i==1
            curLin = [X(i,1) 0 s];
        elseif sigVec(i) ~= sigVec(i-1)
            if sigVec(i-1)~=0
                curLin(2) = X(i-1,2);
                lines{end+1} = curLin;
            end
            curLin = [X(i,1) 0 s];
        elseif i==size(X,1)
            curLin(2) = X(i,2);
            lines{end+1} = curLin;
        end
    elseif i>1 && sigVec(i-1)~=0
        curLin(2) = X(i-1,2);
        lines{end+1} = curLin;
        curLin = [0 0 0];
    end
end

%% Merge all overlapping lines with same significance level
newLines = lines;
rmv = [];
for i=2:numel(lines),
    L = lines{i};
    other = 1:i-1;
    other = setdiff(other,rmv);
    Overlap = cellfun(@(x) (L(1)<=x(2) && L(2)>=x(1)),newLines(other));
    if ~any(Overlap)
        continue;
    end
    Overlap = other(Overlap);
    for j=1:numel(Overlap),
        O = lines{Overlap(j)};
        if O(3)==L(3)
            rmv = [rmv Overlap(j)];
            nL = [min([L(1) O(1)]) max([L(2) O(2)]) L(3)];
            newLines{i} = nL;
        end
    end
end
newLines(rmv) = [];
a = cellfun(@(x) x(1),newLines);
[~,idx] = sort(a);
lines = newLines(idx);

%% Set stack level of overlapping lines
levels = ones(1,numel(lines));
posLevels = 1:numel(lines);
for i=2:numel(lines)
    L = lines{i};
    other = 1:i-1;
    pC = cellfun(@(x) (L(1)<=x(2) && L(2)>=x(1)),lines(other));
    if ~any(pC)
        continue;
    end
    pL = levels(other(pC));
    posL = setdiff(posLevels,pL);
    levels(i) = min(posL);
end

maxY = yPos;
for i=1:numel(lines),
    L = lines{i};
    yP = (1+levels(i)*0.15)*yPos;
    hold on
    plot([L(1) L(1)],[0.95*yP yP],'k-')
    plot([L(1) L(2)],[yP yP],'k-')
    tPos = L(1)+(L(2)-L(1))/2;
    stars = repmat('*',1,L(3));
    plot([L(2) L(2)],[yP 0.95*yP],'k-')
    text(tPos,1.05*yP,stars,'FontSize',14)
    if maxY<1.05*yP
        maxY = 1.05*yP;
    end
end
yl = get(gca,'YLim');
yl(2) = 1.05*maxY;
set(gca,'ylim',yl)
hold(hs)
