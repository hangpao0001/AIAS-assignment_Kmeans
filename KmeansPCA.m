close all
clc
clear

path = 'C:\Users\Administrator\Desktop\AI 19 to 20\Deep learning\assignment\Assignment data\data\';
cd (path)
imgDir = '\images\test\';
gtDir = '\groundTruth\test\';
D= dir(fullfile([path imgDir],'*.jpg'));
tic;
% here we use only a few images for demonstration
for i =65:66 %numel(D)
 IMG = imread ([path imgDir D(i).name(1:end-4) '.jpg']);
 Igray = rgb2gray(IMG);
 figure, imshow(IMG);
 title([D(i).name(1:end-4) '.jpg'])
 I=double(IMG);
 X = reshape(I,size(I,1)*size(I,2),3);
 coeff = pca(X);
 Itransformed = X*coeff;
 Ipc = reshape(Itransformed,size(I,1),size(I,2),3);
 Ipca = single(Ipc);
 figure, imshow(Ipca,[]);
 title(['PCA of ' D(i).name(1:end-4) '.jpg'])
 figure ('name', ['Image segmentation for ' D(i).name(1:end-4) '.jpg'])
 for k=3:4
 L = imsegkmeans(Ipca,k);
 Rlabel=RegionMerging(Igray,L,1000,k);
 SEG = label2rgb(Rlabel);
 subplot(1,2,k-2)
 imshow(SEG)
 title(num2str(k))
 end
end
toc;

tic;
% again, we use only a few images for demonstration
for i =65:66 %numel(D)
 GT = load([path gtDir D(i).name(1:end-4) '.mat']);
 % plotting preparations, assuming max 6 segmentations, frequently there
 % are 5
 figure ('name', ['Ground truth for ' D(i).name(1:end-4) '.jpg']) 
 for k=1:length(GT.groundTruth)
 segments = double(GT.groundTruth{k}.Segmentation);
 subplot(2,3,k)
 imagesc(segments)
 title(num2str(k))
 end
end
toc;