function varargout = imRAG(img, varargin)
%% Initialisations

% size of image
dim = size(img);

% number of dimensions
nd = length(dim);

% Number of background pixels or voxels between two regions
% gap = 0 -> regions are contiguous
% gap = 1 -> there is a 1-pixel large line or surface between two adjacent
% 	pixels, for example the result of a watershed
gap = 1;
if ~isempty(varargin) && isnumeric(varargin{1})
    gap = varargin{1};
end
shift = gap + 1;

% flag indicating whether edge indices should be computed
computeEdgeInds = nargout > 2;
if computeEdgeInds && gap ~= 1
    error('imRAG:wrongGapValue', ...
        'Edge indices can only be computed for gap equal to 1');
end


if nd == 2
    %% First direction of 2D image
    
    % identify transitions
    [i1, i2] = find(img(1:end-shift,:) ~= img((shift+1):end, :));
    
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2));
	val2 = img(sub2ind(dim, i1+shift, i2));

    % keep only changes not involving background, ordered such that n1 < n2
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = sort([val1(inds) val2(inds)], 2);

    % keep array of positions as linear indices
    if computeEdgeInds
        posD1 = sub2ind(dim, i1(inds)+1, i2(inds));
    end
    
    
    %% Second direction of 2D image
    
    % identify transitions
    [i1, i2] = find(img(:, 1:end-shift) ~= img(:, (shift+1):end));
    
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2));
	val2 = img(sub2ind(dim, i1, i2+shift));
    
    % keep only changes not involving background, ordered such that n1 < n2
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = [edges ; sort([val1(inds) val2(inds)], 2)];
    
    if computeEdgeInds
        % keep array of positions as linear indices
        posD2 = sub2ind(dim, i1(inds), i2(inds)+1);
        posList = [posD1 ; posD2];
    end
    
elseif nd == 3
    %% First direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[shift 0 0], ...
        find(img(1:end-shift,:,:) ~= img((shift+1):end,:,:)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
	val2 = img(sub2ind(dim, i1+shift, i2, i3));

    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = unique(sort([val1(inds) val2(inds)], 2), 'rows');
	
    if computeEdgeInds
        % keep array of positions as linear indices
        posD1 = sub2ind(dim, i1(inds)+1, i2(inds), i3(inds));
    end
    
    
    %% Second direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[0 shift 0], ...
        find(img(:,1:end-shift,:) ~= img(:,(shift+1):end,:)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
	val2 = img(sub2ind(dim, i1, i2+shift, i3));

    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = [edges; unique(sort([val1(inds) val2(inds)], 2), 'rows')];

    if computeEdgeInds
        % keep array of positions as linear indices
        posD2 = sub2ind(dim, i1(inds), i2(inds)+1, i3(inds));
    end
    
    %% Third direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[0 0 shift], ...
        find(img(:,:,1:end-shift) ~= img(:,:,(shift+1):end)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
    val2 = img(sub2ind(dim, i1, i2, i3+shift));
    
    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = [edges; unique(sort([val1(inds) val2(inds)], 2), 'rows')];
    
    if computeEdgeInds
        % keep array of positions as linear indices
        posD3 = sub2ind(dim, i1(inds), i2(inds), i3(inds)+1);
        posList = [posD1 ; posD2 ; posD3];
    end
end


% remove double edges, keeping in indsC indices of merged edge for each
% original edge
[edges, indsA, indsC] = unique(edges, 'rows'); %#ok<ASGLU>

if computeEdgeInds
    nEdges = size(edges, 1);
    edgeInds = cell(nEdges, 1);
    for iEdge = 1:nEdges
        inds = indsC == iEdge;
        edgeInds{iEdge} = unique(posList(inds));
    end
end

%% Output processing

if nargout <= 1
    varargout{1} = edges;
    
else
    % Also compute region centroids
    N = max(img(:));
    points = zeros(N, nd);
    labels = unique(img);
    labels(labels==0) = [];
    
    if nd == 2
        % compute 2D centroids
        for i = 1:length(labels)
            label = labels(i);
            [iy, ix] = ind2sub(dim, find(img==label));
            points(label, 1) = mean(ix);
            points(label, 2) = mean(iy);
        end
    else
        % compute 3D centroids
        for i = 1:length(labels)
            label = labels(i);
            [iy, ix, iz] = ind2sub(dim, find(img==label));
            points(label, 1) = mean(ix);
            points(label, 2) = mean(iy);
            points(label, 3) = mean(iz);
        end
    end
    
    % setup output arguments
    varargout{1} = points;
    varargout{2} = edges;
    
    % eventually returns the position of edges as third output argument
    if nargout > 2
        varargout{3} = edgeInds;
    end
end