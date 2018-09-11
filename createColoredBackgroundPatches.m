function out = createColoredBackgroundPatches(patchX,patchVals,patchColors,varargin)
g = groot;
if isempty(g.Children)
    out = [];
    return;
end
XL = get(gca,'xlim');
YL = get(gca,'ylim');
out = [];
for k=1:size(patchX,1)
    if patchVals(k)==0
        continue;
    end
    X = patchX(k,1)*[1 0 0 1];
    X = X+patchX(k,2)*[0 1 1 0];
    Y = [YL(1) YL(1) YL(2) YL(2)];
    h = patch(X,Y,patchColors(patchVals(k),:),'FaceAlpha',.3,'EdgeColor','none');
    out = [out h];
end

% Set patches to background
ph = get(gca,'Children');
pIdx = arrayfun(@(x) any(out==x),ph);
pI = find(pIdx);
lI = find(~pIdx);
set(gca,'Children',ph([lI;pI]))
%uistack(out,'bottom')
