%% save_Cas.m — uloží CAS (HH:MM:SS) podľa START_TIME_hour_1 do results/variable_Cas.mat
clear; clc;
file  = 'UDAJE_Praha_Legerova ulica.xlsx';
sheet = 'Doprava (R203005) (2)';
if ~exist('results','dir'), mkdir results; end

T = readtable(file,'Sheet',sheet,'PreserveVariableNames',true);
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
vn = string(T.Properties.VariableNames); lv = lower(vn);

% preferuj presne *_hour_1
cH1 = vn(contains(lv,'start_time') & contains(lv,'hour_1'));
if isempty(cH1)
    % záložný pokus: premenná s "hour" a ".1" v pôvodnom mene
    cH1 = vn(contains(lv,'hour_1') | (contains(lv,'hour') & contains(lv,'1')));
end
if isempty(cH1)
    error('Nenašiel som stĺpec START_TIME_hour_1. Názvy: %s', strjoin(vn,', '));
end

x = T.(cH1(1));
n = height(T);

% robustná konverzia na duration vektor
if isdatetime(x)
    Cas = timeofday(x);
elseif isduration(x)
    Cas = x;
elseif iscellstr(x) || isstring(x)
    s = string(x);
    try
        Cas = duration(s,"InputFormat","hh:mm:ss");
    catch
        try
            Cas = duration(s,"InputFormat","hh:mm");
        catch
            num = str2double(s);
            Cas = localNumToDurationVec(num);
        end
    end
elseif isnumeric(x)
    Cas = localNumToDurationVec(double(x));
else
    Cas = duration(zeros(n,1),0,0);
end
Cas = reshape(Cas,[],1); Cas.Format = 'hh:mm:ss';

save('results/variable_Cas.mat','Cas','-v7.3');
disp('✅ Uložené: results/variable_Cas.mat');

% --- pomocná funkcia ---
function d = localNumToDurationVec(num)
    num = double(num(:));
    d = duration(zeros(numel(num),1),0,0);
    maskHHMMSS = num > 10000 & num < 240000;
    if any(maskHHMMSS)
        v = num(maskHHMMSS);
        hh = floor(v/10000);
        mm = floor((v - hh*10000)/100);
        ss = round(v - hh*10000 - mm*100);
        d(maskHHMMSS) = hours(hh)+minutes(mm)+seconds(ss);
    end
    maskDecH = ~maskHHMMSS & num>=0 & num<=24;
    if any(maskDecH)
        v = num(maskDecH);
        hh = floor(v);
        mm = floor((v - hh)*60);
        ss = round(((v - hh)*60 - mm)*60);
        d(maskDecH) = hours(hh)+minutes(mm)+seconds(ss);
    end
    maskMin = ~maskHHMMSS & ~maskDecH & num>=0 & num<=1440;
    if any(maskMin)
        d(maskMin) = minutes(num(maskMin));
    end
    d.Format = 'hh:mm:ss';
end
