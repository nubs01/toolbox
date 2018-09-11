function out = getOverlapIndices(A,B)
% with A and B being 2 column matrices of start and end times, this returns
% the rows of A that start, end or fully contain any row of B
out = [];
for k=1:size(A,1)
    if any(A(k,1)>=B(:,1) & A(k,1)<=B(:,2)) || any(A(k,2)>=B(:,1) & A(k,2)<=B(:,2)) || any(A(k,1)<=B(:,1) & A(k,2)>=B(:,2))
        out = [out;k];
    end
end