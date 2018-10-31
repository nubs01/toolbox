function remoteVerifyStates(animID,day,epoch)

    % Create state validation data, save and pull 
    systemCmd = sprintf('source ~/.zshrc;getStateDat %s %i %i',animID,day,epoch);
    disp(systemCmd)
    system(systemCmd,'-echo')


