function [EV,p0,p1] = SurfCrossSection(dataRoot,subMark,str,key)
%UNTITLED Summary of this function goes here
%% head shell surface mesh
[XYZmark,XYZvalue,dof] = str2XYZ(str);
[node,~,simNIBS_face] = MeshfromSimnibs(dataRoot,subMark);
%% 4 point cross section plane
p0 = floor(min(node)-5);
p1 = ceil(max(node)+5);
switch XYZmark
    case 1 %x
        pt4 = [ones(4,1)*XYZvalue,[p0([2,3]);p1([2,3]);p0(2),p1(3);p1(2),p0(3)]];
    case 2 %y
        pt4 = [[p0(1);p1(1);p0(1);p1(1)],ones(4,1)*XYZvalue,[p0(3);p1(3);p1(3);p0(3)]];
    case 3 %z
        pt4 = [[p0([1,2]);p1([1,2]);p0(1),p1(2);p1(1),p0(2)],ones(4,1)*XYZvalue];
end
TR4 = triangulation([1,2,3;1,4,2],pt4);
%% 
face = cell(length(key),1);
TR = cell(length(key),1);
EV = cell(length(key),1);
for i = 1:length(key)
    face{i} = double(simNIBS_face(simNIBS_face(:,4)==key(i),1:3));
    TR{i} = simpleTR(triangulation(face{i},node));
    [EV{i}.Edge,EV{i}.Points]= OneContour(TR4,TR{i});
end


