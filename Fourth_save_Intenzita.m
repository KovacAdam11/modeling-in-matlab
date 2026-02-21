%% save_Intenzita.m — uloží INTENZITU do results/variable_Intenzita.mat
clear; clc;
file  = 'UDAJE_Praha_Legerova ulica.xlsx';
sheet = 'Doprava (R203005) (2)';
if ~exist('results','dir'), mkdir results; end

T = readtable(file,'Sheet',sheet,'PreserveVariableNames',true);
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
vn = string(T.Properties.VariableNames); lv = lower(vn);

cI = vn(contains(lv,'intenzita'));   % 'Intenzita vozidel' -> Intenzita_vozidel
if isempty(cI), error('Nenašiel som stĺpec s "intenzita". Názvy: %s', strjoin(vn,', ')); end

x = T.(cI(1)); 
if ~isnumeric(x), x = str2double(string(x)); end
Intenzita = double(x(:));

save('results/variable_Intenzita.mat','Intenzita','-v7.3');
disp('✅ Uložené: results/variable_Intenzita.mat');
