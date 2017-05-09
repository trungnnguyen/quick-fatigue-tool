function C = circle(mark, varargin)
%CIRCLE    QFT function to calculate Mohr's circle.
%   This function calculates Mohr's circle based on user-defined
%   parameters.
%   
%   CIRCLE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also mohrsCircle.
%
%   Reference section in Quick Fatigue Tool User Guide
%      A3.5 Mohr's circle solver
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
x = varargin{1};
y = varargin{2};
r = varargin{3};
ang = 0:0.01:2*pi;
xp = r*cos(ang);
yp = r*sin(ang);
if strcmp('x1',mark)
    C = plot(x + xp, y + yp, 'r-','LineWidth', 2);
elseif strcmp('x2', mark)
    C = plot(x + xp, y + yp, 'g-','LineWidth', 2);
elseif strcmp('x3', mark)
    C = plot(x + xp, y + yp, 'b-', 'LineWidth', 2);
end
%axis([min(x+xp) max(x+xp) min(y+yp) max(y+yp)])
end