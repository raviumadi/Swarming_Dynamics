function table2latex_stats(tbl, filename, caption, label)
% Export a MATLAB table to LaTeX using tabularx and booktabs with \scriptsize

if nargin < 3, caption = 'Swarm simulation statistics.'; end
if nargin < 4, label = 'tab:swarm_stats'; end

fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file: %s', filename);
end

headers = tbl.Properties.VariableNames;
nCols = numel(headers);

% Column format: 1st two columns left aligned, rest right aligned
colFormat = ['ll', repmat('r', 1, nCols - 2)];
formatSpec = ['\\begin{tabularx}{\\textwidth}{', colFormat, '}\n'];

% Write LaTeX table preamble
fprintf(fid, '\\renewcommand{\\arraystretch}{1.0}\n');
fprintf(fid, '\\setlength{\\tabcolsep}{4pt}\n');
fprintf(fid, '\\begin{table}[htbp]\n');
fprintf(fid, '\\centering\n\\scriptsize\n');
fprintf(fid, '\\caption{%s}\n', caption);
fprintf(fid, '\\label{%s}\n', label);
fprintf(fid, formatSpec);
fprintf(fid, '\\toprule\n');

% Format headers
headersFormatted = strrep(headers, 'kr', '$k_r$');
headersFormatted = strrep(headersFormatted, 'v0', '$v_0$');
headersFormatted = strrep(headersFormatted, 'call_duration_', 'CD\_');
headersFormatted = strrep(headersFormatted, 'call_rate_', 'CR\_');
headersFormatted = strrep(headersFormatted, 'velocity_', 'V\_');
headersFormatted = strrep(headersFormatted, 'inter_dist_', 'D\_');

fprintf(fid, '%s \\\\\n', strjoin(headersFormatted, ' & '));
fprintf(fid, '\\midrule\n');

% Write data rows
for i = 1:height(tbl)
    row = tbl(i, :);
    rowStrs = strings(1, nCols);
    for j = 1:nCols
        val = row{1, j};
        if isnumeric(val)
            if isnan(val)
                rowStrs(j) = '---';
            elseif abs(val) < 1
                rowStrs(j) = sprintf('%.3f', val);
            else
                rowStrs(j) = sprintf('%.1f', val);
            end
        else
            rowStrs(j) = string(val);
        end
    end
    fprintf(fid, '%s \\\\\n', strjoin(rowStrs, ' & '));
end

fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabularx}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);
end