% color image denoising for dehazing
% clear; clc;
addpath('utilities');
imageSets     = {'123_CEDH','At_DH','AtJ_DH'}; %%% testing dataset

folderTest    = 'testsets';
folderModel   = 'models';
folderResult  = 'results';
taskTestCur   = 'DH-IRCNN';
if ~exist(folderResult,'file')
    mkdir(folderResult);
end

setTestCur    = imageSets{1};
imageSigmaS   = [15];
modelSigmaS   = [15];
showResult    = 1;
saveResult    = 1;
useGPU        = 0;
pauseTime     = 1;

%%% folder to store results
folderResultCur = fullfile(folderResult, [taskTestCur,'_',setTestCur]);
if ~exist(folderResultCur,'file')
    mkdir(folderResultCur);
end

%%% read images
ext         =  {'*.jpg','*.png','*.bmp'};
filePaths   =  [];
folderTestCur = fullfile(folderTest,setTestCur);
for i = 1 : length(ext)
    filePaths = cat(1,filePaths, dir(fullfile(folderTestCur,ext{i})));
end

load(fullfile(folderModel,'modelcolor.mat'));

for i = 1:length(modelSigmaS)
    
    disp([i,length(modelSigmaS)]);
    net = loadmodel(modelSigmaS(i),CNNdenoiser);
    net = vl_simplenn_tidy(net);
    % for i = 1:size(net.layers,2)
    %     net.layers{i}.precious = 1;
    % end
    %%% move to gpu
    if useGPU
        net = vl_simplenn_move(net, 'gpu');
    end
    
    for j = 1:length(filePaths)
        
        %%% read images
        label = imread(fullfile(folderTestCur,filePaths(j).name));
        [~,imageName,extCur] = fileparts(filePaths(j).name);
        label = im2double(label);
        %         randn('seed',0);
        input = single(label);
        
        %%% convert to GPU
        if useGPU
            input = gpuArray(input);
        end
        res    = vl_simplenn(net,input,[],[],'conserveMemory',true,'mode','test');
        output = input - res(end).x;
        
        %%% convert to CPU
        if useGPU
            output = gather(output);
            input  = gather(input);
        end
        if saveResult
%             imwrite(im2uint8(output),fullfile(folderResultCur,[imageName,'_',num2str(imageSigmaS(i)),'_',num2str(modelSigmaS(i)),'.png']));
            imwrite(im2uint8(output),fullfile(folderResultCur,[imageName,'.png']));
        end
    end
end



