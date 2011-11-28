function showex(ipAddress)
% function showex(ipAddress)
%
% main Ex function
%
% ipAddress: the IP address of the remote Ex machine
%
%

global u;
global objects;

if nargin == 0
    ipAddress = '192.168.1.11';
end

Screen('Preference', 'SkipSyncTests', 0);

gam = load('photometervals.txt');
vals = makeGammaTable(gam(:,1),gam(:,2));
Screen('LoadNormalizedGammaTable', 0, vals);

delete(instrfind)
u = udp(ipAddress,'RemotePort',8844,'LocalPort',8866);
fopen(u);

% specifies size and location of photodiode square:
% upper left of screen, 50 x 50 pixels
diodeLoc = [0 0 50 50];

% bottom right of screen, 65 x 65 pixels
%diodeLoc = [960 704 1024 768];

AssertOpenGL;

queueing = 0;

screens = Screen('Screens');
screenNumber = max(screens);

white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
gray = (white+black)/2;
if round(gray) == white;
    gray = black;
end
inc = white-gray;
bgColor = gray;

[w screenRect] = Screen('OpenWindow',screenNumber,gray);
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

midScreen = screenRect(3:4)/2;

Screen(w,'FillRect',black,diodeLoc);
Screen('Flip',w);

ifi = Screen('GetFlipInterval',w);

objects = cell(20,1);
visible = zeros(20,1);
visibleQueue = zeros(20,1);

diodeVal = 0;
diodeObj = 1;

screenCleared = 1;

while(1)
    % received network message
    if get(u,'BytesAvailable') > 0
        [s1 s] = strtok(fgetl(u));
                
        %debugging
        %disp(s1);

        switch s1
            case 'set' 
                [objID withoutID] = strtok(s);
                objID = str2double(objID);
                [objType args] = strtok(withoutID);
                
                % types:
                %   (1) oval
                %   (2) movie
                %   (3) grating
                switch objType
                    case 'oval'
                       a = sscanf(args,'%i %i %i %i %i %i %i');
                        % arguments: (1) frameCount
                        %            (2) x position
                        %            (3) y position
                        %            (4) radius
                        %            (5) color, R
                        %            (6) color, G
                        %            (7) color, B
                        obj = struct('type',1,'frame',0,'fc',a(1),'x',a(2), ...
                            'y',a(3),'rad',a(4),'col',a(5:7));
                        objects{objID} = obj;
                    case 'fef_dots'
                       a = sscanf(args,'%i %i %i %i %i %i %i %i %i %i %i %i');

                        % arguments: (1) frameCount
                        %            (2) random seed
                        %            (3) number of dots per frame
                        %            (4) dot size
                        %            (5) dwell
                        %            (6) center x
                        %            (7) center y
                        %            (8) x radius
                        %            (9) y radius
                        %            (10) color, R
                        %            (11) color, G
                        %            (12) color, B
                        
                        frameCount = a(1);
                        seed = a(2);
                        numDots = a(3);
                        dotRad = a(4);
                        dwell = a(5);
                        
                        xMin = (a(6) - a(8));
                        xMax = (a(6) + a(8));
                        yMin = (a(7) - a(9));
                        yMax = (a(7) + a(9));
                        
                        dotPositions = zeros(4,numDots,ceil(frameCount/dwell));
                        
                        r = RandStream.create('mrg32k3a','seed',seed);

                        % loop over number of frames
                        for i = 1:size(dotPositions,3)
                            xPos = randi(r,xMax-xMin+1,numDots,1)+xMin-1;
                            yPos = randi(r,yMax-yMin+1,numDots,1)+yMin-1;
                            
                            %%%%%% begin scalediam function %%%%%%
                            % xPos, yPos and dotRad were in
                            % units of degrees - is this necessary?
                            E = sqrt((xPos./ppd).^2 + (yPos./ppd).^2);
                            X = log10(E) - 1.5;
                            equality = 0.8124 + (0.5324 .* X) + (0.0648 * X.^2) + (0.0788 * X.^3);
                            N = 10.^equality;
                            M = 1.0 ./ N;
                            alldotRad = sqrt(((dotRad./ppd)^2)./M); % dot radii
                            alldotRad = alldotRad .* ppd;
                            %%%%%% end scalediam function %%%%%%
                            
                            dotPositions(1,:,i) = xPos - alldotRad;
                            dotPositions(2,:,i) = yPos - alldotRad;
                            dotPositions(3,:,i) = xPos + alldotRad;
                            dotPositions(4,:,i) = yPos + alldotRad;
                        end
                        
%                         for i = 1:size(dotPositions,3)
%                             for j = 1:numDots
%                                 xPos = randi(r,xMax-xMin+1,1)+xMin-1;
%                                 yPos = randi(r,yMax-yMin+1,1)+yMin-1;
% 
%                                 % MATT change this to a function call
%                                 dotRad = 10;
%                                 
%                                 dotPositions(1,j,i) = xPos - dotRad;
%                                 dotPositions(2,j,i) = yPos - dotRad;
%                                 dotPositions(3,j,i) = xPos + dotRad;
%                                 dotPositions(4,j,i) = yPos + dotRad;                                                                
%                             end
%                         end
%                         
                        dotPositions([1 3],:,:) = dotPositions([1 3],:,:) + midScreen(1);
                        dotPositions([2 4],:,:) = dotPositions([2 4],:,:) + midScreen(2);
                        
                        obj = struct('type',30,'frame',0,'fc',frameCount,'dp',dotPositions, ... 
                            'color',a(10:12),'dwell',a(5));
                        objects{objID} = obj;

                    case 'blank'
                        a = sscanf(args,'%i');
                        % arguments: (1) frameCount
                        obj = struct('type',99,'frame',0,'fc',a(1));
                        objects{objID} = obj;
                        
                    case 'grating'
                        a = sscanf(args,'%i %f %f %f %f %i %i %i %f');

                        % arguments: (1) frameCount
                        %            (2) angle
                        %            (3) initial phase
                        %            (4) frequency
                        %            (5) cycles per second
                        %            (6) x position
                        %            (7) y position
                        %            (8) aperture size
                        %            (9) contrast (0.0-1.0)
                        
                        angle = mod(180-a(2),360);
                        f = a(4);
                        cps = a(5);
                        xCenter = a(6);
                        yCenter = a(7);               
                        rad= a(8); % Size of the grating image. Needs to be a power of two.
                        contrast = a(9);
                        
                        % Calculate parameters of the grating:
                        ppc=ceil(1/f);  % pixels/cycle    
                        fr=f*2*pi;
                        visibleSize=2*rad+1;

                        phase = a(3)/360*ppc;

                        % Create one single static grating image:
                        x=meshgrid(-rad:rad + ppc, -rad:rad);
                        grating = gray + (inc*cos(fr*x))*contrast;
    
                        % Store grating in texture: Set the 'enforcepot' flag to 1 to signal
                        % Psychtoolbox that we want a special scrollable power-of-two texture:
                        gratingTex=Screen('MakeTexture', w, grating);

                        % Create a single gaussian transparency mask and store it to a texture:
                        mask=ones(2*rad+1, 2*rad+1, 2) * mean(bgColor);
                        [x,y]=meshgrid(-1*rad:1*rad,-1*rad:1*rad);

                        mask(:, :, 2)=white * (sqrt(x.^2+y.^2) > rad);
                    
                        maskTex=Screen('MakeTexture', w, mask);

                        shift = cps * ppc * ifi;

                        dstRect=[0 0 visibleSize visibleSize];
                        dstRect=CenterRect(dstRect, screenRect) + [xCenter yCenter xCenter yCenter];

                        
                        obj = struct('type',10,'frame',0,'fc',a(1), ...
                            'angle',angle, 'phase',phase, 'shift', shift, ...
                            'size',visibleSize, 'x',xCenter,'y',yCenter, ...
                            'grating',gratingTex, 'mask',maskTex, ...
                            'ppc',ppc, 'dstRect',dstRect);
                        
                        objects{objID} = obj;
                    case 'movie'
                        [fileName argsRest] = strtok(args);
                        a = sscanf(argsRest,'%i %i %i %i %i');
                        
                        % arguments: (1) frameCount
                        %            (2) dwell
                        %            (3) start frame
                        %            (4) x position
                        %            (5) y position
                        
                        dwell = a(2);
                        startFrame = a(3);
                        xCenter = a(4);
                        yCenter = a(5);

                        vars = load(fileName);
                        
                        movieSize = size(vars.mov{1});
                        dstRect=[0 0 movieSize-1];
                        dstRect=CenterRect(dstRect, screenRect) + [xCenter yCenter xCenter yCenter];
                        srcRect=[0 0 movieSize-1];
    
                        obj = struct('type',20,'frame',0,'fc',a(1), ...
                            'startFrame',startFrame, 'dwell',dwell, ...
                            'srcRect',srcRect, 'dstRect',dstRect);
                        
                        obj.mov = vars.mov;
                        
                        objects{objID} = obj;
                        
                end
        
            case 'obj_on'
                % arguments: (1-n) objects ids to make visible
                args = textscan(s,'%n');
                if queueing
                    visibleQueue(args{1}) = 1;
                else
                    visible(args{1}) = 1;
                end                
            case 'obj_off'
                % arguments: (1-n) objects ids to make visible
                args = textscan(s,'%n');
                if queueing
                    visibleQueue(args{1}) = 0;
                else
                    visible(args{1}) = 0;
                end        
            case 'all_on'
                % arguments: none
                if queueing                    
                    visibleQueue(~cellfun(@isempty,objects)) = 1;
                else
                    visible(~cellfun(@isempty,objects)) = 1;
                end
            case 'rem_all'
                % arguments: none
                for i = 1:length(objects)
                    if ~isempty(objects{i})
                        cleanUpObj(objects{i});
                    end
                end
                objects = cell(20,1);          
                visible(:) = 0;
                queueing = 0;
                
            case 'all_off'
                % arguments: none
                if queueing                    
                    visibleQueue(:) = 0;
                else
                    visible(:) = 0;
                end
                
            case 'queue_begin'    
                % arguments: none
                queueing = 1;
                visibleQueue = visible;
                
            case 'queue_end'
                % arguments: none
                queueing = 0;
                visible = visibleQueue;
                
            case 'bg_color'
                % arguments: 3 numbers indicating the background color
                args = textscan(s,'%n');
                bgColor = args{1};
                Screen(w,'FillRect',bgColor);
                Screen('Flip',w);
                
            case 'diode'
                % arguments: object ID to tie the diode square to
                diodeObj = str2double(s);
                
            case 'framerate'
                s1 = Screen('GetFlipInterval',w);

            case 'resolution'
                res = Screen('Resolution',w);
                s1 = [num2str(res.width),' ',num2str(res.height),' ',num2str(res.pixelSize),' ',num2str(res.hz)];
                
            case 'screen'
                args = textscan(s,'%n');
                scrd = args{1}(1);       % screen distance in cm
                pixpercm = args{1}(2);   % pixels per cm
                ppd = tan(degtorad(1)) * scrd * pixpercm; % pixels per degree
        end
        
        fprintf(u,s1);
    end
    
    vis = find(visible);
    
    % display section
    if ~isempty(vis)
        for i = length(vis):-1:1
            v = vis(i);
            o = objects{v};
            
            switch o.type
                case 1 % oval                    
                    targetPos = [midScreen + [o.x o.y] - o.rad, ... 
                        midScreen + [o.x o.y] + o.rad];            
                    Screen(w,'FillOval',o.col,targetPos);
                    
                case 10 % grating
                    xOffset = mod(o.frame*o.shift+o.phase,o.ppc);
                    srcRect = [xOffset 0 xOffset + o.size o.size];

                    Screen('DrawTexture',w,o.grating,srcRect,o.dstRect,o.angle);
                    Screen('DrawTexture',w,o.mask,[0 0 o.size o.size],o.dstRect,o.angle);   
                    
                case 20 % movie
                    frameNum = floor(o.frame/o.dwell) + o.startFrame;
                               
                    if frameNum > length(o.mov)
                        frameNum = mod(frameNum-1,length(o.mov))+1;
                    end
                    
                    tex=Screen('MakeTexture', w, o.mov{frameNum});
                    Screen('DrawTexture', w, tex,o.srcRect,o.dstRect);
                    Screen('Close',tex);
                
                case 30 % dots
                    Screen(w,'FillRect',o.color,o.dp(:,:,1+floor(o.frame/o.dwell)));                
                    
                case 99 % blank
                    
            end
            
            if o.frame+1 == o.fc
                visible(v) = 0;
                cleanUpObj(o);
                objects{v} = [];
%                diodeVal = 255;
                fprintf(u,'done %i',v);
            else
                objects{v}.frame = o.frame+1;
            end
        end
    end
    
    if visible(diodeObj)   
        switch diodeVal
            case 0
                diodeVal = 255;
            case 255
                diodeVal = 1;
            otherwise
                diodeVal = mod(diodeVal + 128,256);
        end
    else
        switch diodeVal
            case 255
                diodeVal = 0;
            case 0 
                diodeVal = 0;
            otherwise
                diodeVal = 255;
        end            
    end
    
    if sum(visible) > 0
        Screen(w,'FillRect',diodeVal * [1 1 1],diodeLoc);        
        Screen('Flip',w); 
        screenCleared = 0;
    else
        if ~screenCleared
            Screen(w,'FillRect',diodeVal * [1 1 1],diodeLoc);        
            Screen('Flip',w);   
            
            if diodeVal == 0
                screenCleared = 1;
            end
        end
    end
       
    % check for keyboard input
    if KbCheck
        c = GetChar;
        if c == 'x'
            break;     
        end
    end
end

sca

end

function cleanUpObj(o)
    switch o.type
        case 10
            Screen('Close',o.grating);
            Screen('Close',o.mask);            
    end
end

