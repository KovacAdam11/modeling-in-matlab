%% save_Datum.m — uloží DATE (DD.MM.RRRR) do results/variable_Datum.mat
clear; clc;
file  = 'UDAJE_Praha_Legerova ulica.xlsx';
sheet = 'Doprava (R203005) (2)';
if ~exist('results','dir'), mkdir results; end

% Načítaj a znormalizuj názvy
T = readtable(file,'Sheet',sheet,'PreserveVariableNames',true);
T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
vn = string(T.Properties.VariableNames); lv = lower(vn);

% Nájdime kandidátov
cDate  = vn(contains(lv,'start_time') & contains(lv,'date'));   % rok alebo full datetime
cMonth = vn(contains(lv,'start_time') & contains(lv,'month'));  % mesiac
cDay   = vn(contains(lv,'start_time') & contains(lv,'day'));    % deň

n = height(T); Y = []; M = []; D = [];

if ~isempty(cDate)
    x = T.(cDate(1));
    if isdatetime(x)
        Y = year(x); M = month(x); D = day(x);
    else
        if ~isnumeric(x), x = str2double(string(x)); end
        Y = x;             % býva to rok
    end
end
if isempty(M) && ~isempty(cMonth)
    x = T.(cMonth(1)); if ~isnumeric(x), x = str2double(string(x)); end; M = x;
end
if isempty(D) && ~isempty(cDay)
    x = T.(cDay(1));   if ~isnumeric(x), x = str2double(string(x)); end; D = x;
end

% Fallbacky
if isempty(Y), Y = repmat(2020,n,1); end
if isempty(M), M = ones(n,1);        end
if isempty(D), D = ones(n,1);        end

Datum = datetime(Y(:), M(:), D(:), 'Format','dd.MM.yyyy');
save('results/variable_Datum.mat','Datum','-v7.3');
disp('✅ Uložené: results/variable_Datum.mat');
