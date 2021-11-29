function SIMNIBS_LF_tri(dataRoot,subMark)
tdcs_lf = sim_struct('TDCSLEADFIELD');
% Head mesh
tdcs_lf.fnamehead = fullfile(dataRoot,[subMark '.msh']);
% Output directory
tdcs_lf.pathfem = fullfile(dataRoot,'leadfield');
run_simnibs(tdcs_lf)
