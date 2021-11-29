datapath = 'C:\Users\psylab706\Documents\simnibs_examples';
subname = 'ernie';
tdcs_lf = sim_struct('TDCSLEADFIELD');
% Head mesh
tdcs_lf.fnamehead = fullfile(datapath,subname,[subname '.msh']);
% Output directory
tdcs_lf.pathfem = fullfile(datapath,subname,'leadfieldAll');
tdcs_lf.map_to_surf = false;
tdcs_lf.tissues = 1:6;%gray matter
run_simnibs(tdcs_lf);
%%

