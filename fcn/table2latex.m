function table2latex(tbl, filename, caption, label)
% Export a MATLAB table to LaTeX with minimal spacing using tabularx

if nargin < 3, caption = 'Summary statistics table.'; end
if nargin < 4, label = 'tab:summary'; end

fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file: %s', filename);
end

% Write preamble to reduce vertical space
fprintf(fid, '\\renewcommand{\\arraystretch}{1.0}\n');
fprintf(fid, '\\setlength{\\tabcolsep}{6pt}\n');
fprintf(fid, '\\captionsetup[table]{skip=4pt}\n');

% Headers
headers = tbl.Properties.VariableNames;
numCols = numel(headers);
headersFormatted = headers;
headersFormatted = strrep(headersFormatted, 'kr', '$k_r$');
headersFormatted = strrep(headersFormatted, 'v0', '$v_0$');
headersFormatted = strrep(headersFormatted, 'TotalEvents', 'Total Events');
headersFormatted = strrep(headersFormatted, 'Collisions', 'Collisions');
headersFormatted = strrep(headersFormatted, 'PercentCollision', 'Collision Rate (\%)');
headersFormatted = strrep(headersFormatted, 'CollisionsPer100k', 'Per 100,000 Events');
% Begin table block
fprintf(fid, '\\begin{table}[thbp]\n\\centering\n');
fprintf(fid, '\\caption{%s}\n', caption);
fprintf(fid, '\\label{%s}\n', label);
fprintf(fid, '\\renewcommand{\\arraystretch}{1.2}\n');
fprintf(fid, '\\setlength{\\tabcolsep}{8pt}\n');  % Increase column padding
fprintf(fid, '\\begin{tabularx}{\\textwidth}{>{\\centering\\arraybackslash}X >{\\centering\\arraybackslash}X c c >{\\centering\\arraybackslash}X c}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, '%s \\\\\n', strjoin(headersFormatted, ' & '));
fprintf(fid, '\\midrule\n');
% Write each row
for i = 1:height(tbl)
    row = tbl(i, :);
    vals = strings(1, numCols);
    for j = 1:numCols
        val = row{1, j};
        if isnumeric(val)
            if isnan(val)
                vals(j) = '---';
            elseif val == 0
                vals(j) = '0';
            elseif abs(val) < 1
                vals(j) = sprintf('%.4f', val);
            else
                vals(j) = sprintf('%.0f', val);
            end
        else
            vals(j) = string(val);
        end
    end
    fprintf(fid, '%s \\\\\n', strjoin(vals, ' & '));
end

fprintf(fid, '\\bottomrule\n\\end{tabularx}\n\\vspace{-1.0em}\n\\end{table}\n');
fclose(fid);
end