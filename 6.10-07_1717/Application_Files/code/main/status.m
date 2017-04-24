function [reported, x] = status(fid_status, analysedNodes, node, N2, nodalDamage, mainID, subID,...
        reported, x0, x)
%status    QFT function for status file.
%   This function contains code to write information to the status (.sta)
%   file.
%   
%   status is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    %% REPORT PROGRESS
    currentTime = toc;
    if analysedNodes == 1.0 || analysedNodes == N2
        hrs = floor(currentTime/3600);
        mins = floor((currentTime - (3600*hrs))/60);
        secs = currentTime - (hrs*3600) - (mins*60);
        
        percent = round(100*(analysedNodes/N2));
        
        if mins < 10.0
            fprintf(fid_status, '%.0f%%          %.3e    %.0f.%.0f     %.0f/%.0f       %.0f:0%.0f:%.3f\r\n',...
                percent, (1.0/nodalDamage(node)), mainID(node),...
                subID(node), analysedNodes, N2, hrs, mins, secs);
        else
            fprintf(fid_status, '%.0f%%          %.3e    %.0f.%.0f     %.0f/%.0f       %.0f:%.0f:%.3f\r\n',...
                percent, (1.0/nodalDamage(node)), mainID(node),...
                subID(node), analysedNodes, N2, hrs, mins, secs);
        end
    elseif (currentTime - x > 0.0) && (reported == 0.0)
        hrs = floor(currentTime/3600);
        mins = floor((currentTime - (3600*hrs))/60);
        secs = currentTime - (hrs*3600) - (mins*60);
        
        percent = round(100*(analysedNodes/N2));
        if mins < 10.0
            fprintf(fid_status, '%.0f%%          %.3e    %.0f.%.0f   %.0f/%.0f     %.0f:0%.0f:%.3f\r\n',...
                percent, (1.0/nodalDamage(node)), mainID(node),...
                subID(node), analysedNodes, N2, hrs, mins, secs);
        else
            fprintf(fid_status, '%.0f%%          %.3e    %.0f.%.0f   %.0f/%.0f     %.0f:%.0f:%.3f\r\n',...
                percent, (1.0/nodalDamage(node)), mainID(node),...
                subID(node), analysedNodes, N2, hrs, mins, secs);
        end
        
        reported = 1.0;
        x = x + x0;
    else
        reported = 0.0;
    end
end