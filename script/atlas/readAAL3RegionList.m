function RegionList = readAAL3RegionList(AAL3Dir)
%READAAL3REGIONLIST Summary of this function goes here
%   Detailed explanation goes here
xmlFile = fullfile(AAL3Dir,'AAL3v1_1mm.xml');
a = xmlread(xmlFile);
end

