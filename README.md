steps: 
1. Modify the "compileTI.m" file with the correct cuda path. 
2. Copy the leadfield data in the data folder with the same format as samples.
3. Run "first.m" to compile and addpath

Time profile:

(NVIDIA GeForce RTX 2060 SUPER)

ROI phase: 16.9s

Cortex phase: 48.7s

Parallel reduction decrease the method time comsumption by nealy 30%