function T = extractCollisionEventsFromLog(filename)
    fileLines = readlines(filename);

    collisionEvents = struct('bat1', {}, 'bat2', {}, 'time', {}, 'Tb', {}, ...
                             'TTC', {}, 'kr', {}, 'v0', {}, 'delta', {}, ...
                             'events_in_run', {});

    tempEvents = [];
    kr = NaN; v0 = NaN;

    for i = 1:length(fileLines)
        line = strtrim(fileLines(i));

        % Parse [kr=.. v0=..] sim_tag
        sim_match = regexp(line, '\[kr=(\d+)\s+v0=(\d+)\]', 'tokens');
        if ~isempty(sim_match)
            kr = str2double(sim_match{1}{1});
            v0 = str2double(sim_match{1}{2});
        end

        % Collision line
        if contains(line, '*** COLLISION RISK:')
            tokens = regexp(line, ...
                'bats (\d+)-(\d+) at t=([\d\.]+) Tb=([\d\.]+) TTC=([\d\.]+)', ...
                'tokens');
            if ~isempty(tokens)
                tok = tokens{1};
                evt.bat1 = str2double(tok{1});
                evt.bat2 = str2double(tok{2});
                evt.time = str2double(tok{3});
                evt.Tb = str2double(tok{4});
                evt.TTC = str2double(tok{5});
                evt.kr = kr;
                evt.v0 = v0;
                evt.delta = evt.Tb - evt.TTC;
                evt.events_in_run = NaN;
                tempEvents = [tempEvents, evt];
            end
        end

        % Final line for this run
        if contains(line, 'Simulation done:')
            ev_match = regexp(line, 'total events: (\d+)', 'tokens');
            if ~isempty(ev_match)
                totalEvents = str2double(ev_match{1});
                for j = 1:length(tempEvents)
                    tempEvents(j).events_in_run = totalEvents;
                end
                collisionEvents = [collisionEvents, tempEvents]; %#ok<AGROW>
                tempEvents = [];
            end
        end
    end

    T = struct2table(collisionEvents);
end