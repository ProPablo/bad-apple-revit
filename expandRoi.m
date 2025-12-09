function [outroi] = expandRoi(inroi,opts)
%EXPANDROI Summary of this function goes here
%   Detailed explanation goes here
arguments
inroi
opts.numAdditionalPixels (1,1) {mustBePositive} = 5
end

numAdditionalPixels = opts.numAdditionalPixels;
outroi = inroi;

outroi(:,1:2) = outroi(:,1:2) - numAdditionalPixels;
outroi(:,3:4) = outroi(:,3:4) + 2*numAdditionalPixels;

end

