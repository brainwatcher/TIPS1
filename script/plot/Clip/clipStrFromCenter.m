function clipStr = clipStrFromCenter(dataRoot,subMark,center,varargin)
%CLIPSTRFROMCENTER Summary of this function goes here
%   Detailed explanation goes here
if nargin==3
    XYZmark = 1:3;
elseif nargin==4
    XYZmark = varargin{1};
else
    error('Not correct input!');
end
m2mPath = fullfile(dataRoot,subMark, ['m2m_' subMark]);
center_sub = mni2subject_coords(center, m2mPath);
clipStr = cell(length(XYZmark),1);
for i = 1:length(XYZmark)
    clipStrPost = num2str(round(center_sub(XYZmark(i))));
    switch XYZmark(i)
        case 1
            clipStrPre = 'x=';
        case 2
            clipStrPre = 'y=';
        case 3
            clipStrPre = 'z=';
    end
    clipStr{i} = [clipStrPre clipStrPost];
end

