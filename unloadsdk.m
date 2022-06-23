s = whos; 
% find the objects with the type 'ClassName' from the workspace:
matches= strcmp({s.class}, 'Nd2Reader');
myVariables = {s(matches).name};
for i = 1:length(myVariables)
    clear(myVariables{i});
end
clear s matches myVariables;
unloadlibrary('nd2readsdk');