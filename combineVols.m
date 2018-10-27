function out = combineVols (LFM1, LFM2, param)
out = zeros(size(LFM2),'uint16');
% chunk LFM2 in third (z) dimension
% full frame in first (y) and second (x) dimensions
M = 20; % number of chunks
s = size(LFM2);
N = ceil(s(3)/M); % number of voxels/frames per chunk
F = s(1)*s(2); % number of voxels per frame
fprintf('\n');
% for each chunk in LFM2
for i = 1:M
    %disp(sprintf('chunk %d of %d',i,M));
    % calculate index range
    zind = [(i-1)*N+1  i*N];
    if zind(2)>s(3)
        zind(2) = s(3);
    end
    linind = [(i-1)*N*F+1  i*N*F];
    if linind(1)>numel(LFM2)
        disp('LFM2 is complete!');
        break;
    end
    if linind(2)>numel(LFM2)
        linind(2) = numel(LFM2);
    end
    fprintf('chunk %2d of %2d, z index %3d to %3d, linear index %12d to %12d\n',i,M, zind(1),zind(2),linind(1),linind(2));
    % for each voxel in chunk in LFM2, extract position to final_pos2
    %disp('Init_pos');
    final_pos2 = init_pos([linind(1):linind(2)]', LFM2, param);
    % for each position in final_pos2, apply rot and translation
    %disp('Translate');
    tmp = translate (final_pos2, -param.centroid);
    %disp('Rotate');
    tmp = rotate (tmp, param.rot); % CHECK
    %disp('Translate');
    final_pos2 = translate (tmp, param.trans); 
    % for each voxel in LFM1, find positions in final_pos2 and combine and normalize
    %disp('combine');
    out(linind(1):linind(2)) = combine (LFM1, LFM2, final_pos2, linind, param);
end
if ~param.rapid
    outFile = sprintf('%s_%s.tif',param.timestamp,param.myfunc_combine);
%     if length(param.myfunc)>4 && strcmp(param.myfunc(end-3:end),'norm')
%         m = max(max(max(out)));
%         out = uint16( single(out)*2^16/single(m) );
%     end
    save_vol( out, param.savePath, outFile);
end

XguessSAVE1 = out;
outFile = sprintf('%s%s_%s.mat',param.savePath,param.timestamp,param.myfunc_combine);
fprintf('Saving combined volume to %s.\n',outFile);
save(outFile,'XguessSAVE1','-v7.3');
end