function genVideo (param, outputFileName)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get size of reconstructed volumes

fmt = [param.inputFilePath1 param.fpattern];
f = sprintf(fmt,param.m);
LFM1_movieSize = get_size (f);
disp(['Data size :  ' num2str(LFM1_movieSize(1)) ' x ' num2str(LFM1_movieSize(2))...
    ' x ' num2str(LFM1_movieSize(3)) ]);

fmt = [param.inputFilePath2 param.fpattern];
f = sprintf(fmt,param.m);
LFM2_movieSize = get_size (f);
disp(['Data size :  ' num2str(LFM2_movieSize(1)) ' x ' num2str(LFM2_movieSize(2))...
    ' x ' num2str(LFM2_movieSize(3)) ]);

fmt = [param.savePath param.fpattern(1:end-4) '_*.mat'];
f = sprintf(fmt,param.m);
hits = dir(f);
if isempty(hits)
    disp('WTF?');
    fprintf('%s\n',f);
    keyboard
end
hit = [hits(1).folder '/' hits(1).name];
DLFM_movieSize = get_size (hit);
disp(['Data size :  ' num2str(DLFM_movieSize(1)) ' x ' num2str(DLFM_movieSize(2))...
    ' x ' num2str(DLFM_movieSize(3)) ]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nnum = 15;

useInterpolation = true;
GPUinterp = false;
% zExpandRatio = 8;
zExpandRatio = round(4 / 0.323);
zExpandRatioDLFM = zExpandRatio / 8;
moviePixelVert = 1000;

%videoRange = 1:length(LFM1_Files);

gapMIP = 20;  % size of gap in units of pixels
gapVal = 200; % value of gap pixels
gapMETA = 200;
showVideo = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h1 = figure('Visible','on');
iptsetpref('ImshowBorder','tight');

k = 1;
for t=[param.m:param.n]
    tic;

    fmt = [param.inputFilePath1 param.fpattern];
    f = sprintf(fmt,t);
    LFM1 = loadFile(f);

    fmt = [param.inputFilePath2 param.fpattern];
    f = sprintf(fmt,t);
    LFM2 = loadFile(f);

    fmt = [param.savePath param.fpattern(1:end-4) '_*.mat'];
    f = sprintf(fmt,t);
    hits = dir(f);
    if isempty(hits)
        disp('WTF?');
        fprintf('%s\n',f);
        keyboard
    end
    hit = [hits(1).folder '/' hits(1).name];
    DLFM = loadFile(hit);

    imshowMIPorth(LFM1, LFM2, DLFM, zExpandRatio, zExpandRatioDLFM, gapVal, gapMIP, gapMETA, moviePixelVert);
    VideoMIP(k) = getframe(h1);
    ttime = toc;
    disp(['Redering frame ' num2str(k) ' | ' num2str(param.n-param.m+1) ', took ' num2str(ttime) ' secs']);
    k = k + 1;
end

fprintf('\n\nSaving output file %s.avi\n\n',outputFileName);
v = VideoWriter(outputFileName,'Uncompressed AVI');
open(v);
writeVideo(v,VideoMIP);
close(v);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function out = loadFile (f)
fprintf('Loading file %s\n',f);
load(f);
if exist('Xvolume') == 1
    out = Xvolume;
elseif exist('XguessSAVE1') == 1
    out = XguessSAVE1;
else
    disp('WTF?');
    whos
    keyboard
end
end

function out = get_size (f)
fprintf('Loading file %s\n',f);
load(f);
if exist('Xvolume') == 1
    out = size(Xvolume);
    clear Xvolume;
elseif exist('XguessSAVE1') == 1
    out = size(XguessSAVE1);
    clear XguessSAVE1;
else
    disp('WTF?');
    whos
    keyboard
end
end



function IMGout = imshowMIPorth(LFM1, LFM2, DLFM, zExpansionFactor, zExpansionFactorDLFM, gapVal, gapMIP, gapMETA, moviePixelVert)
[xsize1, ysize1] = get_MIPsize (LFM1, zExpansionFactor, gapMIP);
[xsize2, ysize2] = get_MIPsize (LFM2, zExpansionFactor, gapMIP);
[xsize3, ysize3] = get_MIPsize (DLFM, zExpansionFactorDLFM, gapMIP);
x = (xsize1 + gapMETA) + (xsize2 + gapMETA) + xsize3;
%y = max( [ ysize1 ysize2 ysize3] );

IMGout = gapVal*ones(moviePixelVert, x, 'uint16');

origin = 1;
s = size(LFM1);
IMGout = metaMIPs(LFM1, s(2), s(1), zExpansionFactor*s(3), gapMIP, origin, IMGout);
origin = (xsize1 + gapMETA) + 1;
s = size(LFM2);
IMGout = metaMIPs(LFM2, s(2), s(1), zExpansionFactor*s(3), gapMIP, origin, IMGout);
origin = (xsize1 + gapMETA) + (xsize2 + gapMETA) + 1;
s = size(DLFM);
IMGout = metaMIPs(DLFM, s(2), s(1), zExpansionFactorDLFM*s(3), gapMIP, origin, IMGout);

imshow(IMGout);

end


function [xsize,ysize] = get_MIPsize (LFM, zExpansionFactor, gapMIP)
s = size(LFM);
xsize = s(2) + zExpansionFactor*s(3) + gapMIP;
ysize = s(1) + zExpansionFactor*s(3) + gapMIP;
end



function IMGout = metaMIPs(LFM, sizex, sizey, sizez, gapMIP, origin, IMGout)

if ~isa(LFM,'uint16')
    disp('Warning input data is not 16 bit.');
    keyboard
end
IMGin1 =           squeeze(max(LFM,[],3));
IMGin2 = imresize( squeeze(max(LFM,[],1)), [sizex sizez ]);
IMGin3 = imresize( squeeze(max(LFM,[],2)), [sizey sizez ]);

xsize = sizex + sizez + gapMIP;
ysize = sizey + sizez + gapMIP;

IMGout( (1:sizey), ((origin-1)+1:(origin-1)+sizex) ) = IMGin1;
IMGout( (1:sizey), ((origin-1)+sizex+gapMIP+1:(origin-1)+xsize) ) = IMGin3;
IMGout( (sizey+gapMIP+1:ysize), ((origin-1)+1:(origin-1)+sizex) ) = IMGin2';

end



% function IMGout = combineMIPs(IMGin1, IMGin2, IMGin3, sizex, sizey, sizez, gapVal, gapMIP)
% 
% xsize = sizex + sizez + gapMIP;
% ysize = sizey + sizez + gapMIP;
% 
% IMGout = gapVal*ones(ysize, xsize, 'uint16');
% 
% IMGout( (1:sizey), (1:sizex) ) = IMGin1;
% IMGout( (1:sizey), (sizex+gapMIP+1:xsize) ) = IMGin3;
% IMGout( (sizey+gapMIP+1:ysize), (1:sizex) ) = IMGin2';
% end
