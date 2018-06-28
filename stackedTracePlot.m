function out = stackedTracePlot(X,Y,highlightIdx)
    % Plots the rows of Y in their own row of the plot and highlight the
    % regions denoted by highlightIdx in red

    % determine Y range of each row
    rng = range(Y,2);
    maxRng = max(rng);

    % remove means from each row
    Y2 = Y-mean(Y,2);

    % Plot each row in black and higlights in red
    out = figure();
    hold on
    for l=1:size(Y,1)
        plot(X,Y2(l,:)+(l-1)*maxRng,'k','LineWidth',2)
        for k=1:size(highlightIdx,1)
            a = highlightIdx(k,1);
            b = highlightIdx(k,2);
            plot(X(a:b),Y2(l,a:b)+(l-1)*maxRng,'r','LineWidth',2)
        end
    end
