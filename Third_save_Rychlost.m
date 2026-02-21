%% save_Rychlost.m — uloží RÝCHLOSŤ do results/variable_Rychlost.mat
clear; clc;
file  = 'UDAJE_Praha_Legerova ulica.xlsx';
sheet = 'Doprava (R203005) (2)';
if ~exist('results','dir'), mkdir results; end

T = readtable(file,'Sheet',sheet,'PreserveVariableNames',true);
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
vn = string(T.Properties.VariableNames); lv = lower(vn);

% 'průměrná rychlost' -> po makeValidName býva niečo s 'rych'
cR = vn(contains(lv,'rych') | contains(lv,'speed'));
if isempty(cR), error('Nenašiel som stĺpec s "rych"/"speed". Názvy: %s', strjoin(vn,', ')); end

x = T.(cR(1));
if ~isnumeric(x), x = str2double(string(x)); end
Rychlost = double(x(:));

save('results/variable_Rychlost.mat','Rychlost','-v7.3');
disp('✅ Uložené: results/variable_Rychlost.mat');
